#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'tmpdir'
require 'fileutils'

module RDI

  # Constants reflecting the different installation destinations
  DEST_LOCAL = 0
  DEST_SYSTEM = 1
  DEST_USER = 2
  DEST_TEMP = 3
  DEST_OTHER = 4

  # The main class that performs operations
  class Installer

    # == Public API ==

    # The local ext dir (platform specific, local to the application)
    #   String
    attr_reader :ExtDir

    # The system dir
    #   String
    attr_reader :SystemDir

    # The user dir
    #   String
    attr_reader :UserDir

    # The temporary dir
    #   String
    attr_reader :TempDir

    # The RDI lib dir (useful to parse for files among plugins)
    #   String
    attr_reader :RDILibDir

    # Constructor
    #
    # Parameters:
    # * *iAppRootDir* (_String_): Application's root directory
    # * *iMainInstance* (_Boolean_): Is this instance supposed to be the main one if none was defined before ? [optional = true]
    def initialize(iAppRootDir, iMainInstance = true)
      if ((iMainInstance) and
          (@@MainInstallerInstance == nil))
        @@MainInstallerInstance = self
      end
      @DefaultOptions = {}
      @RDILibDir = File.dirname(__FILE__)
      @ExtDir = "#{iAppRootDir}/ext/#{RUBY_PLATFORM}"
      # Initialize all other standard directories
      case RUBY_PLATFORM
      when 'i386-mswin32'
        @UserRootDir = "#{ENV['USERPROFILE']}/RDI"
        @SystemDir = "#{ENV['SystemRoot']}/RDI"
      when 'i386-linux'
        @UserRootDir = "#{File.expand_path('~')}/RDI"
        @SystemDir = "/usr/local/RDI"
      else
        logBug "RDI is not yet compatible with #{RUBY_PLATFORM}. Sorry. Please open a request on http://sourceforge.net/tracker/?group_id=274498&atid=1166451"
        raise RuntimeError, "Incompatible platform: #{RUBY_PLATFORM}"
      end
      @TempRootDir = "#{Dir.tmpdir}/RDI"
      @UserDir = "#{@UserRootDir}/#{RUBY_PLATFORM}"
      @TempDir = "#{@TempRootDir}/#{RUBY_PLATFORM}"
      FileUtils::mkdir_p(@TempDir)
      # Initialize the plugins manager
      if (defined?(RUtilAnts::Plugins::PluginsManager) == nil)
        require 'rUtilAnts/Plugins'
      end
      @Plugins = RUtilAnts::Plugins::PluginsManager.new
      # Get the RDI root directory for libraries
      # Get all plugins
      @Plugins.parsePluginsFromDir('ContextModifiers', "#{@RDILibDir}/Plugins/ContextModifiers", 'RDI::ContextModifiers') do |ioPlugin|
        # Cache some attributes
        ioPlugin.LocationSelectorName = ioPlugin.getLocationSelectorName
      end
      @Plugins.parsePluginsFromDir('Installers', "#{@RDILibDir}/Plugins/Installers", 'RDI::Installers') do |ioPlugin|
        ioPlugin.Installer = self
        # Cache some attributes
        ioPlugin.PossibleDestinations = ioPlugin.getPossibleDestinations
      end
      @Plugins.parsePluginsFromDir('Testers', "#{@RDILibDir}/Plugins/Testers", 'RDI::Testers') do |ioPlugin|
        # Cache some attributes
        ioPlugin.AffectingContextModifiers = ioPlugin.getAffectingContextModifiers
      end
      @Plugins.parsePluginsFromDir('Views', "#{@RDILibDir}/Plugins/Views", 'RDI::Views')
      @Plugins.getPluginNames('Views').each do |iViewName|
        @Plugins.parsePluginsFromDir("LocationSelectors_#{iViewName}", "#{@RDILibDir}/Plugins/Views/#{iViewName}/LocationSelectors", "RDI::Views::LocationSelectors::#{iViewName}")
      end
    end

    # Set default options for ensuring dependencies
    #
    # Parameters:
    # * *iParameters* (<em>map<Symbol,Object></em>): Additional parameters:
    # ** *:AutoInstall* (_Integer_): When set to one of the DEST_* constants, RDI installs automatically to a location flagged with this constant, without the need of user choice [optional = nil]
    # ** *:AutoInstallLocation* (_Object_): Used to provide the location to install to, when :AutoInstall is set to DEST_OTHER only.
    # ** *:PossibleContextModifiers* (<em>map<String,list<list<[String,Object]>>></em>): The list of possible context modifiers sets to try, per dependency ID [optional = nil]
    # ** *:PreferredViews* (<em>list<String></em>): The list of preferred views [optional = nil]
    def setDefaultOptions(iParameters)
      @DefaultOptions = iParameters
    end

    # The main method: ensure that a dependency is accessible
    #
    # Parameters:
    # * *iDepDescList* (<em>list<DependencyDescription></em>): The list of dependencies's description to ensure
    # * *iParameters* (<em>map<Symbol,Object></em>): Additional parameters:
    # ** *:AutoInstall* (_Integer_): When set to one of the DEST_* constants, RDI installs automatically to a location flagged with this constant, without the need of user choice [optional = nil]
    # ** *:AutoInstallLocation* (_Object_): Used to provide the location to install to, when :AutoInstall is set to DEST_OTHER only.
    # ** *:PossibleContextModifiers* (<em>map<String,list<list<[String,Object]>>></em>): The list of possible context modifiers sets to try, per dependency ID [optional = nil]
    # ** *:PreferredViews* (<em>list<String></em>): The list of preferred views [optional = nil]
    # Return:
    # * _Exception_: The error, or nil in case of success
    # * <em>map<String,list<[String,Object]>></em>: The list of context modifiers that have been applied to resolve the dependencies, per dependency ID (can be inconsistent in case of error)
    # * <em>list<DependencyDescription></em>: The list of dependencies that were deliberately ignored (can be inconsistent in case of error)
    # * <em>list<DependencyDescription></em>: The list of dependencies that could not be resolved (can be inconsistent in case of error)
    def ensureDependencies(iDepDescList, iParameters = {})
      rError = nil
      rAppliedContextModifiers = {}
      rIgnoredDeps = []
      rUnresolvedDeps = []

      lAutoInstall = @DefaultOptions[:AutoInstall]
      if (iParameters.has_key?(:AutoInstall))
        lAutoInstall = iParameters[:AutoInstall]
      end
      lAutoInstallLocation = @DefaultOptions[:AutoInstallLocation]
      if (iParameters.has_key?(:AutoInstallLocation))
        lAutoInstallLocation = iParameters[:AutoInstallLocation]
      end
      lPossibleContextModifiers = @DefaultOptions[:PossibleContextModifiers]
      if (iParameters.has_key?(:PossibleContextModifiers))
        lPossibleContextModifiers = iParameters[:PossibleContextModifiers]
      end
      lPreferredViews = @DefaultOptions[:PreferredViews]
      if (iParameters.has_key?(:PreferredViews))
        lPreferredViews = iParameters[:PreferredViews]
      end
      # First, test if the dependencies are already accessible
      lDepsToResolve = []
      iDepDescList.each do |iDepDesc|
        if (!testDependency(iDepDesc))
          lDepsToResolve << iDepDesc
        end
      end
      if (!lDepsToResolve.empty?)
        # Try resolving those dependencies with additional locations
        lMissingDependencies = []
        # Check if we can try some ContextModifiers that might find the missing dependencies
        if (lPossibleContextModifiers == nil)
          lMissingDependencies = lDepsToResolve
        else
          lMissingDependencies = getMissingDeps(lDepsToResolve, lPossibleContextModifiers, rAppliedContextModifiers)
        end
        if (!lMissingDependencies.empty?)
          # If we ask for auto-installation, go on
          if (lAutoInstall == nil)
            # Ask the user what to do with those missing dependencies
            rDepsUserChoices = askUserForMissingDeps(lMissingDependencies, lPreferredViews)
            # Parse what was returned by the user choices
            rDepsUserChoices.each do |iDepUserChoice|
              lDepDesc = iDepUserChoice.DepDesc
              lIgnore = false
              if (iDepUserChoice.Locate)
                if (lDepDesc.Testers.size == iDepUserChoice.ResolvedTesters.size)
                  # This one was resolved using ContextModifiers.
                  # Apply them.
                  iDepUserChoice.ResolvedTesters.each do |iTesterName, iCMInfo|
                    iCMName, iCMContent = iCMInfo
                    accessPlugin('ContextModifiers', iCMName) do |ioPlugin|
                      ioPlugin.addLocationToContext(iCMContent)
                    end
                  end
                  # Remember what we applied
                  rAppliedContextModifiers[lDepDesc.ID] = iDepUserChoice.ResolvedTesters.values
                else
                  rUnresolvedDeps << lDepDesc
                  lIgnore = true
                end
              elsif (iDepUserChoice.IdxInstaller != nil)
                # This one is to be installed
                # Get the installer plugin
                lInstallerName, lInstallerContent, lContextModifiers = lDepDesc.Installers[iDepUserChoice.IdxInstaller]
                accessPlugin('Installers', lInstallerName) do |ioInstallerPlugin|
                  lLocation = nil
                  if (ioInstallerPlugin.PossibleDestinations[iDepUserChoice.IdxDestination][0] == DEST_OTHER)
                    lLocation = iDepUserChoice.OtherLocation
                  else
                    lLocation = ioInstallerPlugin.PossibleDestinations[iDepUserChoice.IdxDestination][1]
                  end
                  lInstallEnv = {}
                  rError = installDependency(lDepDesc, iDepUserChoice.IdxInstaller, lLocation, lInstallEnv)
                  # Get what has been modified in the context
                  rAppliedContextModifiers[lDepDesc.ID] = lInstallEnv[:ContextModifiers]
                  # If an error occurred, cancel
                  if (rError != nil)
                    break
                  end
                end
              else
                rIgnoredDeps << lDepDesc
                lIgnore = true
              end
              if (!lIgnore)
                # Test if it was installed correctly
                if (!testDependency(lDepDesc))
                  # Still missing
                  rUnresolvedDeps << lDepDesc
                end
              end
            end
          else
            lMissingDependencies.each do |iDepDesc|
              # Try to find an installer and a location for the lAutoInstall value
              lIdxInstaller = 0
              lLocation = nil
              iDepDesc.Installers.each do |iInstallerInfo|
                iInstallerName, iInstallerContent, iContextModifiersList = iInstallerInfo
                accessPlugin('Installers', iInstallerName) do |iPlugin|
                  iPlugin.PossibleDestinations.each do |iDestinationInfo|
                    iLocationFlavour, iLocation = iDestinationInfo
                    if (iLocationFlavour == lAutoInstall)
                      # We found it
                      if (iLocationFlavour == DEST_OTHER)
                        lLocation = lAutoInstallLocation
                      else
                        lLocation = iLocation
                      end
                      break
                    end
                  end
                end
                if (lLocation != nil)
                  break
                end
                lIdxInstaller += 1
              end
              if (lLocation == nil)
                # We were unable to find a correct default location for lAutoInstall
                rError = RuntimeError.new("Unable to find a default location for #{lAutoInstall}.")
              else
                lInstallEnv = {}
                rError = installDependency(iDepDesc, lIdxInstaller, lLocation, lInstallEnv)
                # Get what has been modified in the context
                rAppliedContextModifiers[iDepDesc.ID] = lInstallEnv[:ContextModifiers]
                # Test if it was installed correctly
                if (!testDependency(iDepDesc))
                  # Still missing
                  rUnresolvedDeps << iDepDesc
                end
              end
              if (rError != nil)
                # An error occurred: cancel
                break
              end
            end
          end
        end
      end

      return rError, rAppliedContextModifiers, rIgnoredDeps, rUnresolvedDeps
    end

    # Check if a dependency is ok
    #
    # Parameters:
    # * *iDepDesc* (_DependencyDescription_): The dependency's description
    # Return:
    # * _Boolean_: Is the dependency accessible in our environment ?
    def testDependency(iDepDesc)
      rSuccess = true

      # Loop among Testers
      iDepDesc.Testers.each do |iTesterInfo|
        iTesterName, iTesterContent = iTesterInfo
        accessPlugin('Testers', iTesterName) do |iPlugin|
          logDebug "Test dependency #{iTesterContent} using #{iTesterName} ..."
          rSuccess = iPlugin.isContentResolved?(iTesterContent)
          if (rSuccess)
            logDebug "Dependency #{iTesterContent} found."
          else
            logDebug "Dependency #{iTesterContent} not found."
          end
        end
        if (!rSuccess)
          # This Tester answered false. Give up.
          break
        end
      end

      return rSuccess
    end

    # Install a given dependency on a given destination
    #
    # Parameters:
    # * *iDepDesc* (_DependencyDescription_): The dependency's description
    # * *iIdxInstaller* (_Integer_): Index of the installer to use in the description
    # * *iLocation* (_Object_): The location to install to
    # * *ioInstallEnvironment* (<em>map<Symbol,Object></em>): The install environment to fill [optional = {}]
    # Return:
    # * _Exception_: The exception, or nil in case of success
    def installDependency(iDepDesc, iIdxInstaller, iLocation, ioInstallEnvironment = {})
      rError = nil

      # Get the installer information
      iInstallerName, iInstallerContent, iContextModifiersList = iDepDesc.Installers[iIdxInstaller]
      if (iInstallerName == nil)
        logBug "Unable to get installer n.#{iIdxInstaller} in description #{iDepDesc.inspect}"
        rError = RuntimeError.new("Unable to get installer n.#{iIdxInstaller} in description #{iDepDesc.inspect}")
      else
        # Install it
        accessPlugin('Installers', iInstallerName) do |iPlugin|
          logDebug "Install #{iInstallerContent} in #{iLocation} using #{iInstallerName} ..."
          rError = iPlugin.installDependency(iInstallerContent, iLocation, ioInstallEnvironment)
          if (rError == nil)
            logDebug "Plugin #{iInstallerContent} installed correctly."
          else
            logDebug "Plugin #{iInstallerContent} installation ended in error: #{rError}."
          end
        end
        if (rError == nil)
          # Apply context modifiers
          ioInstallEnvironment[:InstallLocation] = iLocation
          # Store the context modifiers list in the environment, as it can be useful for further installations of the same dependency
          ioInstallEnvironment[:ContextModifiers] = []
          iContextModifiersList.each do |iContextModifierInfo|
            iContextModifierName, iContextModifierContent = iContextModifierInfo
            accessPlugin('ContextModifiers', iContextModifierName) do |iPlugin|
              # Transform the content based on the installation environment
              lContextContent = iPlugin.transformContentWithInstallEnv(iContextModifierContent, ioInstallEnvironment)
              # Check if this content is already in the context
              if (!iPlugin.isLocationInContext?(lContextContent))
                # We have to add it.
                logDebug "Add #{lContextContent} to context #{iContextModifierName}"
                iPlugin.addLocationToContext(lContextContent)
              end
              ioInstallEnvironment[:ContextModifiers] << [ iContextModifierName, lContextContent ]
            end
          end
        end
      end

      return rError
    end

    # Get access to one of RDI's plugins.
    # An exception is thrown if the plugin does not exist.
    # Used by:
    # * Regression
    # * Views
    #
    # Parameters:
    # * *iCategoryName* (_String_): Category of the plugin to access
    # * *iPluginName* (_String_): Name of the plugin to access
    # * *CodeBlock*: The code called when the plugin is found:
    # ** *ioPlugin* (_Object_): The corresponding plugin
    def accessPlugin(iCategoryName, iPluginName)
      @Plugins.accessPlugin(iCategoryName, iPluginName, :RDIInstaller => self) do |ioPlugin|
        yield(ioPlugin)
      end
    end

    # Get list of plugins for a given category.
    # Used by:
    # * Regression
    #
    # Parameters:
    # * *iCategoryName* (_String_): Category of the plugin to access
    # Return:
    # * <em>list<String></em>: List of plugin names
    def getPluginNames(iCategoryName)
      return @Plugins.getPluginNames(iCategoryName)
    end

    # Register a new plugin
    # Used by:
    # * Regression
    #
    # Parameters:
    # * *iCategoryName* (_String_): Category this plugin belongs to
    # * *iPluginName* (_String_): Plugin name
    # * *iFileName* (_String_): File name containing the plugin (can be nil)
    # * *iDesc* (<em>map<Symbol,Object></em>): Plugin's description (can be nil)
    # * *iClassName* (_String_): Name of the plugin class
    # * *iInitCodeBlock* (_Proc_): Code block to call when initializing the real instance (can be nil)
    def registerNewPlugin(iCategoryName, iPluginName, iFileName, iDesc, iClassName, iInitCodeBlock)
      @Plugins.registerNewPlugin(iCategoryName, iPluginName, iFileName, iDesc, iClassName, iInitCodeBlock)
    end

    # Get the Main instance, if there is one defined, or nil otherwise
    #
    # Return:
    # * _Installer_: The main instance, or nil if none.
    def self.getMainInstance
      return @@MainInstallerInstance
    end

    # == Private API ==

    private

    # The main RDI Installer instance
    #   Installer
    @@MainInstallerInstance = nil

    # Get the missing dependencies after trying previously applied context modifiers
    #
    # Parameters:
    # * *iDepsToResolve* (<em>list<DependencyDescription></em>): The list of dependencies to resolve
    # * *iPossibleContextModifiers* (<em>map<String,list<list<[String,Object]>>></em>): The list of possible context modifiers sets to try, per dependency ID
    # * *ioAppliedContextModifiers* (<em>map<String,list<[String,Object]>></em>): The list of context modifiers that have been applied to resolve the dependencies, per dependency ID
    # Return:
    # * <em>list<DependencyDescription></em>: The list of dependencies that are still missing
    def getMissingDeps(iDepsToResolve, iPossibleContextModifiers, ioAppliedContextModifiers)
      rMissingDeps = []

      # We might have some install environments to try
      iDepsToResolve.each do |iDepDesc|
        lDepID = iDepDesc.ID
        lCMListsToTry = iPossibleContextModifiers[lDepID]
        lDepResolved = false
        if (lCMListsToTry != nil)
          # We can try several ones. We want at least 1 of those sets to resolve the dependency.
          lCMListsToTry.each do |iCMSetToTry|
            # Try to add the locations to the context
            lAppliedCMs = []
            iCMSetToTry.each do |iContextModifierInfo|
              iName, iContent = iContextModifierInfo
              accessPlugin('ContextModifiers', iName) do |ioPlugin|
                if (!ioPlugin.isLocationInContext?(iContent))
                  # We try this one.
                  ioPlugin.addLocationToContext(iContent)
                  lAppliedCMs << iContextModifierInfo
                end
              end
            end
            # Now, test if this has resolved the dependency (don't try if nothing changed)
            if (!lAppliedCMs.empty?)
              lDepResolved = testDependency(iDepDesc)
              # If we found it, it's ok
              if (lDepResolved)
                ioAppliedContextModifiers[iDepDesc.ID] = lAppliedCMs
                break
              else
                # Rollback those context modifications as they were useless
                lAppliedCMs.each do |iContextModifierInfo|
                  iName, iContent = iContextModifierInfo
                  accessPlugin('ContextModifiers', iName) do |ioPlugin|
                    ioPlugin.removeLocationFromContext(iContent)
                  end
                end
              end
            end
          end
        end
        # If none of them resolved the dependency, add the dependency to the missing ones
        if (!lDepResolved)
          rMissingDeps << iDepDesc
        end
      end

      return rMissingDeps
    end

    # Ask the user about missing dependencies.
    # This method will use a user interface to know what to do with missing dependencies.
    # For each dependency, choices are:
    # * Install it
    # * Ignore it
    # * Change the context to find it (select directory...)
    # Views are used to ask the user for those.
    # It is possible to specify a list of preferred views. If it is the case, RDI will try first views among this list that already have their dependencies accessible, then RDI will try to install the dependencies of the first one. It will use the first view it can.
    # If not specified, RDI will use arbitrary the first view it can, and eventualy try to install one.
    #
    # Parameters:
    # * *iMissingDependencies* (<em>list<DependencyDescription></em>): The missing dependencies list
    # * *iPreferredViewsList* (<em>list<String></em>): The list of preferred views (can be nil)
    # Return:
    # * <em>list<DependencyUserChoice></em>: The list of dependencies user choices
    def askUserForMissingDeps(iMissingDependencies, iPreferredViewsList)
      rDependenciesUserChoices = []

      lViewsList = iPreferredViewsList
      if ((iPreferredViewsList == nil) or
          (iPreferredViewsList.empty?))
        # Set all views as being preferred
        lViewsList = @Plugins.getPluginNames('Views')
      end
      if (lViewsList.empty?)
        logBug 'No view was accessible among plugins. Please check your Plugin/Views directory.'
      else
        # Now we try to select 1 view that is accessible without any dependency installation
        lPlugin = nil
        lViewsList.each do |iViewName|
          lPlugin, lError = @Plugins.getPluginInstance('Views', iViewName,
            :OnlyIfExtDepsResolved => true,
            :RDIInstaller => self
          )
          if (lPlugin != nil)
            # Found one
            logDebug "Executing View #{iViewName}"
            break
          end
        end
        if (lPlugin == nil)
          # Now we try to install them
          lViewsList.each do |iViewName|
            lPlugin, lError = @Plugins.getPluginInstance('Views', iViewName,
              :RDIInstaller => self
            )
            if (lPlugin != nil)
              # Found one
              logDebug "Executing View #{iViewName}"
              break
            end
          end
        end
        if (lPlugin == nil)
          logBug 'After trying all preferred views, we are still unable to have one.'
        else
          # Call it
          rDependenciesUserChoices = lPlugin.execute(self, iMissingDependencies)
        end
      end

      return rDependenciesUserChoices
    end

  end

end
