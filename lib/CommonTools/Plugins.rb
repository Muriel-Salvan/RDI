#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module CommonTools

  # Module that defines a generic way to handle plugins:
  # * No pre-load: plugins files are required when needed only
  # * Description files support: plugins files can give a description file, enumerating their dependencies, description...
  # * Support for plugins categories
  # * [If RDI is present]: Try to install dependencies before loading plugin instances
  module Plugins

    # Exception thrown when an unknown plugin is encountered
    class UnknownPluginError < RuntimeError
    end

    # Main class storing info about plugins
    class PluginsManager

      # Constructor
      def initialize
        # Map of plugins, per category
        # map< String, map< String, map< Symbol, Object > > >
        @Plugins = {}
      end

      # Register a new plugin
      #
      # Parameters:
      # * *iCategoryName* (_String_): Category this plugin belongs to
      # * *iPluginName* (_String_): Plugin name
      # * *iFileName* (_String_): File name containing the plugin (can be nil)
      # * *iDesc* (<em>map<Symbol,Object></em>): Plugin's description (can be nil)
      # * *iClassName* (_String_): Name of the plugin class
      # * *iInitCodeBlock* (_Proc_): Code block to call when initializing the real instance (can be nil)
      def registerNewPlugin(iCategoryName, iPluginName, iFileName, iDesc, iClassName, iInitCodeBlock)
        # Complete the description with some metadata
        if (@Plugins[iCategoryName] == nil)
          @Plugins[iCategoryName] = {}
        end
        lDesc = nil
        if (iDesc == nil)
          lDesc = {}
        else
          lDesc = iDesc.clone
        end
        lDesc[:PluginFileName] = iFileName
        lDesc[:PluginInstance] = nil
        lDesc[:PluginClassName] = iClassName
        lDesc[:PluginInitCode] = iInitCodeBlock
        lDesc[:PluginIndex] = @Plugins[iCategoryName].size
        @Plugins[iCategoryName][iPluginName] = lDesc
      end

      # Parse plugins from a given directory
      #
      # Parameters:
      # * *iCategory* (_Object_): Category those plugins will belong to
      # * *iDir* (_String_): Directory to parse for plugins
      # * *iBaseClassNames* (_String_): The base class name of plugins to be instantiated
      # * *iInitCodeBlock* (_CodeBlock_): Code to be executed first time the plugin will be instantiated (can be ommitted):
      # ** *ioPlugin* (_Object_): Plugin instance
      def parsePluginsFromDir(iCategory, iDir, iBaseClassNames, &iInitCodeBlock)
        # Gather descriptions
        # map< String, map >
        lDescriptions = {}
        lDescFiles = Dir.glob("#{iDir}/*.desc.rb")
        lDescFiles.each do |iFileName|
          lPluginName = File.basename(iFileName)[0..-9]
          # Load the description file
          begin
            File.open(iFileName) do |iFile|
              lDesc = eval(iFile.read, nil, iFileName)
              if (lDesc.is_a?(Hash))
                lDescriptions[lPluginName] = lDesc
              else
                logBug "Plugin description #{iFileName} is incorrect. The file should just describe a simple hash map."
              end
            end
          rescue Exception
            logExc $!, "Error while loading file #{iFileName}. Ignoring this description."
          end
        end
        # Now, parse the plugins themselves
        if (@Plugins[iCategory] == nil)
          @Plugins[iCategory] = {}
        end
        (Dir.glob("#{iDir}/*.rb") - lDescFiles).each do |iFileName|
          lPluginName = File.basename(iFileName)[0..-4]
          # Don't load it now, but store it along with its description if it exists
          if (@Plugins[iCategory][lPluginName] == nil)
            # Check if we have a description
            lDesc = lDescriptions[lPluginName]
            registerNewPlugin(
              iCategory,
              lPluginName,
              iFileName,
              lDescriptions[lPluginName],
              "#{iBaseClassNames}::#{lPluginName}",
              iInitCodeBlock
            )
          else
            logErr "Plugin named #{lPluginName} in category #{iCategory} already exists. Please name it differently. Ignoring it from #{iFileName}."
          end
        end
      end

      # Get the named plugin instance
      #
      # Parameters:
      # * *iCategory* (_Object_): Category those plugins will belong to
      # * *iPluginName* (_String_): Plugin name
      # * *iOnlyIfExtDepsResolved* (_Boolean_): Do we return the plugin only if there is no need to install external dependencies ? [optional = false]
      # * *ioRDIInstaller* (<em>RDI::Installer</em>): The RDI installer if available, or nil otherwise [optional = nil]
      # Return:
      # * _Object_: The corresponding plugin, or nil in case of failure
      def getPluginInstance(iCategory, iPluginName, iOnlyIfExtDepsResolved = false, ioRDIInstaller = nil)
        rPlugin = nil

        if (@Plugins[iCategory] == nil)
          logErr "Unknown plugins category #{iCategory}."
        else
          lDesc = @Plugins[iCategory][iPluginName]
          if (lDesc == nil)
            logErr "Unknown plugin #{iPluginName} in category #{iCategory}."
          else
            if (lDesc[:PluginInstance] == nil)
              lSuccess = true
              # If RDI is present, call it to get dependencies first if needed
              if ((ioRDIInstaller != nil) and
                  (lDesc[:Dependencies] != nil))
                if (iOnlyIfExtDepsResolved)
                  lSuccess = false
                else
                  # Load other dependencies
                  lError, lContextModifiers, lIgnored, lUnresolved = ioRDIInstaller.ensureDependencies(lDesc[:Dependencies])
                  lSuccess = ((lError == nil) and
                              (lUnresolved.empty?))
                  if (!lSuccess)
                    logErr "Could not load dependencies for plugin #{iPluginName}."
                  end
                end
              end
              if (lSuccess)
                if (lDesc[:PluginsDependencies] != nil)
                  # Load other plugins
                  lDesc[:PluginsDependencies].each do |iPluginInfo|
                    iPluginCategory, iPluginName = iPluginInfo
                    lSuccess = (getPluginInstance(iPluginCategory, iPluginName, iOnlyIfExtDepsResolved, ioRDIInstaller) != nil)
                    if (!lSuccess)
                      # Don't try further
                      break
                    end
                  end
                end
                # Load the plugin
                begin
                  # If the file name is to be required, do it now
                  if (lDesc[:PluginFileName] != nil)
                    require lDesc[:PluginFileName]
                  end
                  lPlugin = eval("#{lDesc[:PluginClassName]}.new")
                  lDesc[:PluginInstance] = lPlugin
                  # If needed, execute the init code
                  if (lDesc[:PluginInitCode] != nil)
                    lDesc[:PluginInitCode].call(lPlugin)
                  end
                rescue Exception
                  logExc $!, "Error while loading file #{lDesc[:PluginFileName]} and instantiating #{lDesc[:PluginClassName]}. Ignoring this plugin."
                end
              end
            end
            rPlugin = lDesc[:PluginInstance]
          end
        end

        return rPlugin
      end

      # Get the named plugin description
      #
      # Parameters:
      # * *iCategory* (_Object_): Category those plugins will belong to
      # * *iPluginName* (_String_): Plugin name
      # Return:
      # * <em>map<Symbol,Object></em>: The corresponding description, or nil in case of failure
      def getPluginDescription(iCategory, iPluginName)
        rDesc = nil

        if (@Plugins[iCategory] == nil)
          logErr "Unknown plugins category #{iCategory}."
        else
          rDesc = @Plugins[iCategory][iPluginName]
          if (rDesc == nil)
            logErr "Unknown plugin #{iPluginName} in category #{iCategory}."
          end
        end

        return rDesc
      end

      # Give access to a plugin.
      # An exception is thrown if the plugin does not exist.
      #
      # Parameters:
      # * *iCategoryName* (_String_): Category of the plugin to access
      # * *iPluginName* (_String_): Name of the plugin to access
      # * *iOnlyIfExtDepsResolved* (_Boolean_): Do we return the plugin only if there is no need to install external dependencies ? [optional = false]
      # * *ioRDIInstaller* (<em>RDI::Installer</em>): The RDI installer if available, or nil otherwise [optional = nil]
      # * *CodeBlock*: The code called when the plugin is found:
      # ** *ioPlugin* (_Object_): The corresponding plugin
      def accessPlugin(iCategoryName, iPluginName, iOnlyIfExtDepsResolved = false, ioRDIInstaller = false)
        lPlugin = getPluginInstance(iCategoryName, iPluginName, iOnlyIfExtDepsResolved, ioRDIInstaller)
        if (lPlugin == nil)
          raise UnknownPluginError, "Could not get plugin #{iPluginName} in category #{iCategoryName}"
        else
          yield(lPlugin)
        end
      end

      # Clear the registered plugins
      def clearPlugins
        @Plugins = {}
      end

      # Get the list of plugin names of a given category
      #
      # Parameters:
      # * *iCategoryName* (_String_): The category for which we want the plugin names list
      # Return:
      # * <em>list<String></em>: The list of plugin names in this category
      def getPluginNames(iCategoryName)
        rPlugins = []

        if (@Plugins[iCategoryName] != nil)
          rPlugins += @Plugins[iCategoryName].keys
        end

        return rPlugins
      end

    end

    # Initialize a plugins singleton
    def self.initializePlugins
      $CT_Plugins_Manager = PluginsManager.new
      Object.module_eval('include CommonTools::Plugins')
    end

    # Register a new plugin
    #
    # Parameters:
    # * *iCategoryName* (_String_): Category this plugin belongs to
    # * *iPluginName* (_String_): Plugin name
    # * *iFileName* (_String_): File name containing the plugin (can be nil)
    # * *iDesc* (<em>map<Symbol,Object></em>): Plugin's description (can be nil)
    # * *iClassName* (_String_): Name of the plugin class
    # * *iInitCodeBlock* (_Proc_): Code block to call when initializing the real instance (can be nil)
    def registerNewPlugin(iCategoryName, iPluginName, iFileName, iDesc, iClassName, iInitCodeBlock)
      $CT_Plugins_Manager.registerNewPlugin(iCategoryName, iPluginName, iFileName, iDesc, iClassName, iInitCodeBlock)
    end

    # Parse plugins from a given directory
    #
    # Parameters:
    # * *iCategory* (_Object_): Category those plugins will belong to
    # * *iDir* (_String_): Directory to parse for plugins
    # * *iBaseClassNames* (_String_): The base class name of plugins to be instantiated
    def parsePluginsFromDir(iCategory, iDir, iBaseClassNames)
      $CT_Plugins_Manager.parsePluginsFromDir(iCategory, iDir, iBaseClassNames)
    end

    # Get the named plugin instance
    #
    # Parameters:
    # * *iCategory* (_Object_): Category those plugins will belong to
    # * *iPluginName* (_String_): Plugin name
    # * *iOnlyIfExtDepsResolved* (_Boolean_): Do we return the plugin only if there is no need to install external dependencies ? [optional = false]
    # * *ioRDIInstaller* (<em>RDI::Installer</em>): The RDI installer if available, or nil otherwise [optional = nil]
    # Return:
    # * _Object_: The corresponding plugin, or nil in case of failure
    def getPluginInstance(iCategory, iPluginName, iOnlyIfExtDepsResolved = false, ioRDIInstaller = nil)
      return $CT_Plugins_Manager.getPluginInstance(iCategory, iPluginName, iOnlyIfExtDepsResolved, ioRDIInstaller)
    end

    # Get the named plugin description
    #
    # Parameters:
    # * *iCategory* (_Object_): Category those plugins will belong to
    # * *iPluginName* (_String_): Plugin name
    # Return:
    # * <em>map<Symbol,Object></em>: The corresponding description, or nil in case of failure
    def getPluginDescription(iCategory, iPluginName)
      return $CT_Plugins_Manager.getPluginDescription(iCategory, iPluginName)
    end

    # Give access to a plugin.
    # An exception is thrown if the plugin does not exist.
    #
    # Parameters:
    # * *iCategoryName* (_String_): Category of the plugin to access
    # * *iPluginName* (_String_): Name of the plugin to access
    # * *iOnlyIfExtDepsResolved* (_Boolean_): Do we return the plugin only if there is no need to install external dependencies ? [optional = false]
    # * *ioRDIInstaller* (<em>RDI::Installer</em>): The RDI installer if available, or nil otherwise [optional = nil]
    # * *CodeBlock*: The code called when the plugin is found:
    # ** *ioPlugin* (_Object_): The corresponding plugin
    def accessPlugin(iCategoryName, iPluginName, iOnlyIfExtDepsResolved = false, ioRDIInstaller = nil)
      $CT_Plugins_Manager.accessPlugin(iCategoryName, iPluginName, iOnlyIfExtDepsResolved, ioRDIInstaller) do |ioPlugin|
        yield(ioPlugin)
      end
    end

    # Clear the registered plugins
    def clearPlugins
      $CT_Plugins_Manager.clearPlugins
    end

    # Get the list of plugin names of a given category
    #
    # Parameters:
    # * *iCategoryName* (_String_): The category for which we want the plugin names list
    # Return:
    # * <em>list<String></em>: The list of plugin names in this category
    def getPluginNames(iCategoryName)
      return $CT_Plugins_Manager.getPluginNames(iCategoryName)
    end

  end

end
