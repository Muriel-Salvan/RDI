#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'tmpdir'
require 'fileutils'
require 'CommonTools/Plugins.rb'

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

    # The application root dir
    #   String
    attr_reader :AppRootDir

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

    # Constructor
    #
    # Parameters:
    # * *iAppRootDir* (_String_): Application's root directory
    def initialize(iAppRootDir)
      @AppRootDir = iAppRootDir
      @ExtDir = "#{@AppRootDir}/ext/#{RUBY_PLATFORM}"
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
      @Plugins = CommonTools::Plugins::PluginsManager.new
      # Get the RDI root directory for libraries
      lRDILibDir = File.dirname(__FILE__)
      # Get all plugins
      @Plugins.parsePluginsFromDir('ContextModifiers', "#{lRDILibDir}/Plugins/ContextModifiers", 'RDI::ContextModifiers')
      @Plugins.parsePluginsFromDir('Installers', "#{lRDILibDir}/Plugins/Installers", 'RDI::Installers') do |ioPlugin|
        ioPlugin.Installer = self
        ioPlugin.PossibleDestinations = ioPlugin.getPossibleDestinations
      end
      @Plugins.parsePluginsFromDir('Testers', "#{lRDILibDir}/Plugins/Testers", 'RDI::Testers')
    end

    # The main method: ensure that a dependency is accessible
    #
    # Parameters:
    # * *iDepDescList* (<em>list<DependencyDescription></em>): The list of dependencies's description to ensure
    # * *iParameters* (<em>map<Symbol,Object></em>): Additional parameters:
    # ** *:AutoInstall* (_Integer_): When set to one of the DEST_* constants, RDI installs automatically to a location flagged with this constant, without the need of user choice [optional = nil]
    # ** *:PossibleContextModifiers* (<em>map<String,list<list<[String,Object]>>></em>): The list of possible context modifiers sets to try, per dependency ID
    # Return:
    # * _Exception_: The error, or nil in case of success
    def ensureDependencies(iDepDescList, iParameters = {})
      rError = nil

      lAutoInstall = iParameters[:AutoInstall]
      lPossibleContextModifiers = iParameters[:PossibleContextModifiers]
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
          lMissingDependencies = getMissingDeps(lDepsToResolve, lPossibleContextModifiers)
        end
        # If we ask for auto-installation, go on
        if (lAutoInstall == nil)
          # Ask the user what to do with those missing dependencies
          # TODO
        else
          lMissingDependencies.each do |iDepDesc|
            # Try to find an installer and a location for the lAutoInstall value
            lIdxInstaller = 0
            lLocation = nil
            iDepDesc.Installers.each do |iInstallerInfo|
              iInstallerName, iInstallerContent, iContextModifiersList = iInstallerInfo
              @Plugins.accessPlugin('Installers', iInstallerName) do |iPlugin|
                iPlugin.PossibleDestinations.each do |iDestinationInfo|
                  iLocationType, iLocation = iDestinationInfo
                  if (iLocationType == lAutoInstall)
                    # We found it
                    lLocation = iLocation
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
              rError = installDependency(iDepDesc, lIdxInstaller, lLocation)
            end
            if (rError != nil)
              # An error occurred: cancel
              break
            end
          end
        end
      end

      return rError
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
        @Plugins.accessPlugin('Testers', iTesterName) do |iPlugin|
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
        @Plugins.accessPlugin('Installers', iInstallerName) do |iPlugin|
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
            @Plugins.accessPlugin('ContextModifiers', iContextModifierName) do |iPlugin|
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

    # == Private API ==

    private

    # Get the missing dependencies after trying previously applied context modifiers
    #
    # Parameters:
    # * *iDepsToResolve* (<em>list<DependencyDescription></em>): The list of dependencies to resolve
    # * *iPossibleContextModifiers* (<em>map<String,list<list<[String,Object]>>></em>): The list of possible context modifiers sets to try, per dependency ID
    # Return:
    # * <em>list<DependencyDescription></em>: The list of dependencies that are still missing
    def getMissingDeps(iDepsToResolve, iPossibleContextModifiers)
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
              @Plugins.accessPlugin('ContextModifiers', iName) do |ioPlugin|
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
                break
              else
                # Rollback those context modifications as they were useless
                lAppliedCMs.each do |iContextModifierInfo|
                  iName, iContent = iContextModifierInfo
                  @Plugins.accessPlugin('ContextModifiers', iName) do |ioPlugin|
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

    # == Regression API ==

    # Get access to one of RDI's plugins.
    # An exception is thrown if the plugin does not exist.
    # Used only for regression testing.
    #
    # Parameters:
    # * *iCategoryName* (_String_): Category of the plugin to access
    # * *iPluginName* (_String_): Name of the plugin to access
    # * *CodeBlock*: The code called when the plugin is found:
    # ** *ioPlugin* (_Object_): The corresponding plugin
    def accessPlugin(iCategoryName, iPluginName)
      @Plugins.accessPlugin(iCategoryName, iPluginName) do |ioPlugin|
        yield(ioPlugin)
      end
    end

  end

end
