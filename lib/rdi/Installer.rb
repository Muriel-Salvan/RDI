#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

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
    # Parameters::
    # * *iAppRootDir* (_String_): Application's root directory
    # * *iMainInstance* (_Boolean_): Is this instance supposed to be the main one if none was defined before ? [optional = true]
    def initialize(iAppRootDir, iMainInstance = true)
      if ((iMainInstance) and
          (@@MainInstallerInstance == nil))
        @@MainInstallerInstance = self
      end
      @DefaultOptions = {}

      # Set directories
      @RDILibDir = File.dirname(__FILE__)
      @ExtDir = "#{iAppRootDir}/ext/#{RUBY_PLATFORM}"
      # Get OS specific locations
      if (defined?(RUtilAnts::Platform) == nil)
        require 'rUtilAnts/Platform'
      end
      # Initialize all other standard directories
      lOSCode = RUtilAnts::Platform::Manager.new.os
      case lOSCode
      when RUtilAnts::Platform::OS_WINDOWS
        @UserRootDir = "#{ENV['USERPROFILE']}/RDI"
        @SystemDir = "#{ENV['SystemRoot']}/RDI"
      when RUtilAnts::Platform::OS_LINUX, RUtilAnts::Platform::OS_CYGWIN, RUtilAnts::Platform::OS_MACOSX
        @UserRootDir = "#{File.expand_path('~')}/RDI"
        @SystemDir = "/usr/local/RDI"
      else
        log_bug "RDI is not yet compatible with #{lOSCode}. Sorry. Please open a request on http://sourceforge.net/tracker/?group_id=274498&atid=1166451"
        raise RuntimeError, "Incompatible platform: #{lOSCode}"
      end
      require 'tmpdir'
      @TempRootDir = "#{Dir.tmpdir}/RDI"
      @UserDir = "#{@UserRootDir}/#{RUBY_PLATFORM}"
      @TempDir = "#{@TempRootDir}/#{RUBY_PLATFORM}"
      require 'fileutils'
      FileUtils::mkdir_p(@TempDir)

      # Get all possible plugins
      if (defined?(RUtilAnts::Plugins::PluginsManager) == nil)
        require 'rUtilAnts/Plugins'
      end
      @Plugins = RUtilAnts::Plugins::PluginsManager.new
      # Get the RDI root directory for libraries
      # Get all plugins
      @Plugins.parse_plugins_from_dir('ContextModifiers', "#{@RDILibDir}/Plugins/ContextModifiers", 'RDI::ContextModifiers') do |ioPlugin|
        # Cache some attributes
        ioPlugin.LocationSelectorName = ioPlugin.get_location_selector_name
      end
      @Plugins.parse_plugins_from_dir('Installers', "#{@RDILibDir}/Plugins/Installers", 'RDI::Installers') do |ioPlugin|
        ioPlugin.Installer = self
        # Cache some attributes
        ioPlugin.PossibleDestinations = ioPlugin.get_possible_destinations
      end
      @Plugins.parse_plugins_from_dir('Testers', "#{@RDILibDir}/Plugins/Testers", 'RDI::Testers') do |ioPlugin|
        # Cache some attributes
        ioPlugin.AffectingContextModifiers = ioPlugin.get_affecting_context_modifiers
      end
      @Plugins.parse_plugins_from_dir('Views', "#{@RDILibDir}/Plugins/Views", 'RDI::Views')
      @Plugins.parse_plugins_from_dir('ProgressViews', "#{@RDILibDir}/Plugins/ProgressViews", 'RDI::ProgressViews')
      @Plugins.get_plugins_names('Views').each do |iViewName|
        @Plugins.parse_plugins_from_dir("LocationSelectors_#{iViewName}", "#{@RDILibDir}/Plugins/Views/#{iViewName}/LocationSelectors", "RDI::Views::LocationSelectors::#{iViewName}")
      end
    end

    # Set default options for ensuring dependencies.
    # Options not specified in the given ones will not be overriden. To cancel existing values, set them explicitly to nil.
    #
    # Parameters::
    # * *iParameters* (<em>map<Symbol,Object></em>): Additional parameters:
    #   * *:auto_install* (_Integer_): When set to one of the DEST_* constants, RDI installs automatically to a location flagged with this constant, without the need of user choice [optional = nil]
    #   * *:auto_install_location* (_Object_): Used to provide the location to install to, when :auto_install is set to DEST_OTHER only.
    #   * *:possible_context_modifiers* (<em>map<String,list<list< [String,Object] >>></em>): The list of possible context modifiers sets to try, per dependency ID [optional = nil]
    #   * *:preferred_views* (<em>list<String></em>): The list of preferred views [optional = nil]
    def set_default_options(iParameters)
      @DefaultOptions.merge!(iParameters)
    end

    # Get the default location used by a given Installer for a given flavour
    #
    # Parameters::
    # * *iInstallerName* (_String_): Name of the Installer plugin
    # * *iFlavour* (_Integer_): Flavour required
    # Return::
    # * _Object_: Corresponding location, or LocationSelector name in case of DEST_OTHER flavour, or nil if none.
    def get_default_install_location(iInstallerName, iFlavour)
      rLocation = nil

      access_plugin('Installers', iInstallerName) do |iPlugin|
        iPlugin.PossibleDestinations.each do |iDestInfo|
          iDestFlavour, iDestLocation = iDestInfo
          if (iDestFlavour == iFlavour)
            rLocation = iDestLocation
            break
          end
        end
      end

      return rLocation
    end

    # Ensure a given Location for a given ContextModifier
    #
    # Parameters::
    # * *iContextModifierName* (_String_): Name of the context modifier
    # * *iLocation* (_Location_): Location to add
    def ensure_location_in_context(iContextModifierName, iLocation)
      access_plugin('ContextModifiers', iContextModifierName) do |ioPlugin|
        if (!ioPlugin.is_location_in_context?(iLocation))
          log_debug "Add Location #{iLocation} to #{iContextModifierName}."
          ioPlugin.add_location_to_context(iLocation)
        end
      end
    end

    # The main method: ensure that a dependency is accessible
    #
    # Parameters::
    # * *iDepDescList* (<em>list<DependencyDescription></em>): The list of dependencies's description to ensure
    # * *iParameters* (<em>map<Symbol,Object></em>): Additional parameters:
    #   * *:auto_install* (_Integer_): When set to one of the DEST_* constants, RDI installs automatically to a location flagged with this constant, without the need of user choice [optional = nil]
    #   * *:auto_install_location* (_Object_): Used to provide the location to install to, when :auto_install is set to DEST_OTHER only.
    #   * *:possible_context_modifiers* (<em>map<String,list<list< [String,Object] >>></em>): The list of possible context modifiers sets to try, per dependency ID [optional = nil]
    #   * *:preferred_views* (<em>list<String></em>): The list of preferred views [optional = nil]
    #   * *:preferred_progress_views* (<em>list<String></em>): The list of preferred progress views [optional = nil]
    # Return::
    # * _Exception_: The error, or nil in case of success
    # * <em>map<String,list< [String,Object] >></em>: The list of context modifiers that have been applied to resolve the dependencies, per dependency ID (can be inconsistent in case of error)
    # * <em>list<DependencyDescription></em>: The list of dependencies that were deliberately ignored (can be inconsistent in case of error)
    # * <em>list<DependencyDescription></em>: The list of dependencies that could not be resolved (can be inconsistent in case of error)
    def ensure_dependencies(iDepDescList, iParameters = {})
      rError = nil
      rAppliedContextModifiers = {}
      rIgnoredDeps = []
      rUnresolvedDeps = []

      lAutoInstall = @DefaultOptions[:auto_install]
      if (iParameters.has_key?(:auto_install))
        lAutoInstall = iParameters[:auto_install]
      end
      lAutoInstallLocation = @DefaultOptions[:auto_install_location]
      if (iParameters.has_key?(:auto_install_location))
        lAutoInstallLocation = iParameters[:auto_install_location]
      end
      lPossibleContextModifiers = @DefaultOptions[:possible_context_modifiers]
      if (iParameters.has_key?(:possible_context_modifiers))
        lPossibleContextModifiers = iParameters[:possible_context_modifiers]
      end
      lPreferredViews = @DefaultOptions[:preferred_views]
      if (iParameters.has_key?(:preferred_views))
        lPreferredViews = iParameters[:preferred_views]
      end
      lPreferredProgressViews = @DefaultOptions[:preferred_progress_views]
      if (iParameters.has_key?(:preferred_progress_views))
        lPreferredProgressViews = iParameters[:preferred_progress_views]
      end
      # First, test if the dependencies are already accessible
      lDepsToResolve = []
      iDepDescList.each do |iDepDesc|
        if (!test_dependency(iDepDesc))
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
            # Create a progression view
            setupPreferredProgress(lPreferredProgressViews) do |ioProgressView|
              # Be careful, as ioProgressView can be nil if no view was found
              if (ioProgressView != nil)
                ioProgressView.set_range(rDepsUserChoices.size)
              end
              # Parse what was returned by the user choices
              rDepsUserChoices.each do |iDepUserChoice|
                lDepDesc = iDepUserChoice.DepDesc
                lIgnore = false
                if (iDepUserChoice.Locate)
                  if (ioProgressView != nil)
                    ioProgressView.set_title("Locate #{lDepDesc.ID}")
                  end
                  if (lDepDesc.Testers.size == iDepUserChoice.ResolvedTesters.size)
                    # This one was resolved using ContextModifiers.
                    # Apply them.
                    iDepUserChoice.ResolvedTesters.each do |iTesterName, iCMInfo|
                      iCMName, iCMContent = iCMInfo
                      access_plugin('ContextModifiers', iCMName) do |ioPlugin|
                        ioPlugin.add_location_to_context(iCMContent)
                      end
                    end
                    # Remember what we applied
                    rAppliedContextModifiers[lDepDesc.ID] = iDepUserChoice.ResolvedTesters.values
                  else
                    rUnresolvedDeps << lDepDesc
                    lIgnore = true
                  end
                elsif (iDepUserChoice.IdxInstaller != nil)
                  if (ioProgressView != nil)
                    ioProgressView.set_title("Install #{lDepDesc.ID}")
                  end
                  # This one is to be installed
                  # Get the installer plugin
                  lInstallerName, _, _ = lDepDesc.Installers[iDepUserChoice.IdxInstaller]
                  access_plugin('Installers', lInstallerName) do |ioInstallerPlugin|
                    lLocation = nil
                    if (ioInstallerPlugin.PossibleDestinations[iDepUserChoice.IdxDestination][0] == DEST_OTHER)
                      lLocation = iDepUserChoice.OtherLocation
                    else
                      lLocation = ioInstallerPlugin.PossibleDestinations[iDepUserChoice.IdxDestination][1]
                    end
                    lInstallEnv = {}
                    rError = install_dependency(lDepDesc, iDepUserChoice.IdxInstaller, lLocation, lInstallEnv)
                    # Get what has been modified in the context
                    rAppliedContextModifiers[lDepDesc.ID] = lInstallEnv[:ContextModifiers]
                    # If an error occurred, cancel
                    if (rError != nil)
                      break
                    end
                  end
                else
                  if (ioProgressView != nil)
                    ioProgressView.set_title("Ignore #{lDepDesc.ID}")
                  end
                  rIgnoredDeps << lDepDesc
                  lIgnore = true
                end
                if (ioProgressView != nil)
                  ioProgressView.inc_value
                end
                if (!lIgnore)
                  if (ioProgressView != nil)
                    ioProgressView.set_title("Test #{lDepDesc.ID}")
                  end
                  # Test if it was installed correctly
                  if (!test_dependency(lDepDesc))
                    # Still missing
                    rUnresolvedDeps << lDepDesc
                  end
                end
              end
            end
          else
            # Create a progression view
            setupPreferredProgress(lPreferredProgressViews) do |ioProgressView|
              # Be careful, as ioProgressView can be nil if no view was found
              if (ioProgressView != nil)
                ioProgressView.set_range(lMissingDependencies.size)
              end
              lMissingDependencies.each do |iDepDesc|
                if (ioProgressView != nil)
                  ioProgressView.set_title("Installing #{iDepDesc.ID}")
                end
                # Try to find an installer and a location for the lAutoInstall value
                lIdxInstaller = 0
                lLocation = nil
                iDepDesc.Installers.each do |iInstallerInfo|
                  iInstallerName, _, _ = iInstallerInfo
                  access_plugin('Installers', iInstallerName) do |iPlugin|
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
                  rError = install_dependency(iDepDesc, lIdxInstaller, lLocation, lInstallEnv)
                  # Get what has been modified in the context
                  rAppliedContextModifiers[iDepDesc.ID] = lInstallEnv[:ContextModifiers]
                  # Test if it was installed correctly
                  if (!test_dependency(iDepDesc))
                    # Still missing
                    rUnresolvedDeps << iDepDesc
                  end
                end
                if (rError != nil)
                  # An error occurred: cancel
                  break
                end
                if (ioProgressView != nil)
                  ioProgressView.inc_value
                end
              end
            end
          end
        end
      end

      return rError, rAppliedContextModifiers, rIgnoredDeps, rUnresolvedDeps
    end

    # Check if a dependency is ok
    #
    # Parameters::
    # * *iDepDesc* (_DependencyDescription_): The dependency's description
    # Return::
    # * _Boolean_: Is the dependency accessible in our environment ?
    def test_dependency(iDepDesc)
      rSuccess = true

      # Loop among Testers
      iDepDesc.Testers.each do |iTesterInfo|
        iTesterName, iTesterContent = iTesterInfo
        log_debug "Test dependency #{iTesterContent} using #{iTesterName} ..."
        access_plugin('Testers', iTesterName) do |iPlugin|
          rSuccess = iPlugin.is_content_resolved?(iTesterContent)
          if (rSuccess)
            log_debug "Dependency #{iTesterContent} found."
          else
            log_debug "Dependency #{iTesterContent} not found."
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
    # Parameters::
    # * *iDepDesc* (_DependencyDescription_): The dependency's description
    # * *iIdxInstaller* (_Integer_): Index of the installer to use in the description
    # * *iLocation* (_Object_): The location to install to
    # * *ioInstallEnvironment* (<em>map<Symbol,Object></em>): The install environment to fill [optional = {}]
    # Return::
    # * _Exception_: The exception, or nil in case of success
    def install_dependency(iDepDesc, iIdxInstaller, iLocation, ioInstallEnvironment = {})
      rError = nil

      # Get the installer information
      iInstallerName, iInstallerContent, iContextModifiersList = iDepDesc.Installers[iIdxInstaller]
      if (iInstallerName == nil)
        log_bug "Unable to get installer n.#{iIdxInstaller} in description #{iDepDesc.inspect}"
        rError = RuntimeError.new("Unable to get installer n.#{iIdxInstaller} in description #{iDepDesc.inspect}")
      else
        # Install it
        access_plugin('Installers', iInstallerName) do |iPlugin|
          log_debug "Install #{iInstallerContent} in #{iLocation} using #{iInstallerName} ..."
          rError = iPlugin.install_dependency(iInstallerContent, iLocation, ioInstallEnvironment)
          if (rError == nil)
            log_debug "Plugin #{iInstallerContent} installed correctly."
          else
            log_debug "Plugin #{iInstallerContent} installation ended in error: #{rError}."
          end
        end
        if (rError == nil)
          # Apply context modifiers
          ioInstallEnvironment[:InstallLocation] = iLocation
          # Store the context modifiers list in the environment, as it can be useful for further installations of the same dependency
          ioInstallEnvironment[:ContextModifiers] = []
          iContextModifiersList.each do |iContextModifierInfo|
            iContextModifierName, iContextModifierContent = iContextModifierInfo
            access_plugin('ContextModifiers', iContextModifierName) do |iPlugin|
              # Transform the content based on the installation environment
              lContextContent = iPlugin.transform_content_with_install_env(iContextModifierContent, ioInstallEnvironment)
              # Check if this content is already in the context
              if (!iPlugin.is_location_in_context?(lContextContent))
                # We have to add it.
                log_debug "Add #{lContextContent} to context #{iContextModifierName}"
                iPlugin.add_location_to_context(lContextContent)
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
    # Parameters::
    # * *iCategoryName* (_String_): Category of the plugin to access
    # * *iPluginName* (_String_): Name of the plugin to access
    # * *CodeBlock*: The code called when the plugin is found:
    #   * *ioPlugin* (_Object_): The corresponding plugin
    def access_plugin(iCategoryName, iPluginName)
      @Plugins.access_plugin(iCategoryName, iPluginName, :RDIInstaller => self) do |ioPlugin|
        yield(ioPlugin)
      end
    end

    # Get list of plugins for a given category.
    # Used by:
    # * Regression
    #
    # Parameters::
    # * *iCategoryName* (_String_): Category of the plugin to access
    # Return::
    # * <em>list<String></em>: List of plugin names
    def get_plugins_names(iCategoryName)
      return @Plugins.get_plugins_names(iCategoryName)
    end

    # Register a new plugin
    # Used by:
    # * Regression
    #
    # Parameters::
    # * *iCategoryName* (_String_): Category this plugin belongs to
    # * *iPluginName* (_String_): Plugin name
    # * *iFileName* (_String_): File name containing the plugin (can be nil)
    # * *iDesc* (<em>map<Symbol,Object></em>): Plugin's description (can be nil)
    # * *iClassName* (_String_): Name of the plugin class
    # * *iInitCodeBlock* (_Proc_): Code block to call when initializing the real instance (can be nil)
    def register_new_plugin(iCategoryName, iPluginName, iFileName, iDesc, iClassName, iInitCodeBlock)
      @Plugins.register_new_plugin(iCategoryName, iPluginName, iFileName, iDesc, iClassName, iInitCodeBlock)
    end

    # Get the Main instance, if there is one defined, or nil otherwise
    #
    # Return::
    # * _Installer_: The main instance, or nil if none.
    def self.get_main_instance
      return @@MainInstallerInstance
    end

    # == Private API ==

    private

    # The main RDI Installer instance
    #   Installer
    @@MainInstallerInstance = nil

    # Get the missing dependencies after trying previously applied context modifiers
    #
    # Parameters::
    # * *iDepsToResolve* (<em>list<DependencyDescription></em>): The list of dependencies to resolve
    # * *iPossibleContextModifiers* (<em>map<String,list<list< [String,Object] >>></em>): The list of possible context modifiers sets to try, per dependency ID
    # * *ioAppliedContextModifiers* (<em>map<String,list< [String,Object] >></em>): The list of context modifiers that have been applied to resolve the dependencies, per dependency ID
    # Return::
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
              access_plugin('ContextModifiers', iName) do |ioPlugin|
                if (!ioPlugin.is_location_in_context?(iContent))
                  # We try this one.
                  ioPlugin.add_location_to_context(iContent)
                  lAppliedCMs << iContextModifierInfo
                end
              end
            end
            # Now, test if this has resolved the dependency (don't try if nothing changed)
            if (!lAppliedCMs.empty?)
              lDepResolved = test_dependency(iDepDesc)
              # If we found it, it's ok
              if (lDepResolved)
                ioAppliedContextModifiers[iDepDesc.ID] = lAppliedCMs
                break
              else
                # Rollback those context modifications as they were useless
                lAppliedCMs.each do |iContextModifierInfo|
                  iName, iContent = iContextModifierInfo
                  access_plugin('ContextModifiers', iName) do |ioPlugin|
                    ioPlugin.remove_location_from_context(iContent)
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
    # Parameters::
    # * *iMissingDependencies* (<em>list<DependencyDescription></em>): The missing dependencies list
    # * *iPreferredViewsList* (<em>list<String></em>): The list of preferred views (can be nil)
    # Return::
    # * <em>list<DependencyUserChoice></em>: The list of dependencies user choices
    def askUserForMissingDeps(iMissingDependencies, iPreferredViewsList)
      rDependenciesUserChoices = []

      lViewsList = iPreferredViewsList
      if ((iPreferredViewsList == nil) or
          (iPreferredViewsList.empty?))
        # Set all views as being preferred
        lViewsList = @Plugins.get_plugins_names('Views')
      end
      if (lViewsList.empty?)
        log_bug 'No view was accessible among plugins. Please check your Plugin/Views directory.'
      else
        # Now we try to select 1 view that is accessible without any dependency installation
        lPlugin = nil
        lViewsList.each do |iViewName|
          lPlugin, _ = @Plugins.get_plugin_instance('Views', iViewName,
            :OnlyIfExtDepsResolved => true,
            :RDIInstaller => self
          )
          if (lPlugin != nil)
            # Found one
            log_debug "Executing View #{iViewName}"
            break
          end
        end
        if (lPlugin == nil)
          # Now we try to install them
          lViewsList.each do |iViewName|
            lPlugin, _ = @Plugins.get_plugin_instance('Views', iViewName,
              :RDIInstaller => self
            )
            if (lPlugin != nil)
              # Found one
              log_debug "Executing View #{iViewName}"
              break
            end
          end
        end
        if (lPlugin == nil)
          log_bug 'After trying all preferred views, we are still unable to have one.'
        else
          # Call it
          rDependenciesUserChoices = lPlugin.execute(self, iMissingDependencies)
        end
      end

      return rDependenciesUserChoices
    end

    # Setup a progression view based on user preferences.
    # It is possible to specify a list of preferred progress views. If it is the case, RDI will try first views among this list that already have their dependencies accessible, then RDI will try to install the dependencies of the first one. It will use the first view it can.
    # If not specified, RDI will use arbitrary the first progress view it can, and eventualy try to install one.
    #
    # Parameters::
    # * *iPreferredProgressViewsList* (<em>list<String></em>): The list of preferred views (can be nil)
    # * _CodeBlock_: Code to execute once the progress view has been found
    #   * *ioProgressView* (_Object_): The corresponding progress view
    def setupPreferredProgress(iPreferredProgressViewsList)
      lViewsList = iPreferredProgressViewsList
      if ((iPreferredProgressViewsList == nil) or
          (iPreferredProgressViewsList.empty?))
        # Set all views as being preferred
        lViewsList = @Plugins.get_plugins_names('ProgressViews')
      end
      if (lViewsList.empty?)
        log_debug 'No progress view was accessible among plugins. Please check your Plugin/ProgressViews directory. Continuing without progress view.'
      else
        # Now we try to select 1 progress view that is accessible without any dependency installation
        lPlugin = nil
        lViewsList.each do |iViewName|
          lPlugin, _ = @Plugins.get_plugin_instance('ProgressViews', iViewName,
            :OnlyIfExtDepsResolved => true,
            :RDIInstaller => self
          )
          if (lPlugin != nil)
            # Found one
            log_debug "Executing Progress View #{iViewName}"
            break
          end
        end
        if (lPlugin == nil)
          # Now we try to install them
          lViewsList.each do |iViewName|
            lPlugin, _ = @Plugins.get_plugin_instance('ProgressViews', iViewName,
              :RDIInstaller => self
            )
            if (lPlugin != nil)
              # Found one
              log_debug "Executing Progress View #{iViewName}"
              break
            end
          end
        end
        if (lPlugin == nil)
          log_debug 'After trying all preferred progress views, we are still unable to have one. Performing without progression.'
        end
      end
      # Call it
      if (lPlugin == nil)
        yield(nil)
      else
        lPlugin.setup_progress do |ioProgressView|
          yield(ioProgressView)
        end
      end
    end

  end

end
