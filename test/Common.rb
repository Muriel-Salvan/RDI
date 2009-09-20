#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

# This file is intended to be required by every test case.

require 'RUtilAnts/Logging'
RUtilAnts::Logging::initializeLogging("#{File.dirname(__FILE__)}/../lib", 'http://sourceforge.net/tracker/?group_id=274498&atid=1166448', true)
require 'RUtilAnts/URLAccess'
RUtilAnts::URLAccess::initializeURLAccess
require 'RUtilAnts/Platform'
RUtilAnts::Platform::initializePlatform

require 'tmpdir'
require 'test/unit'
require 'rdi/rdi'
require 'rdi/Model/View'
require 'rdi/Model/LocationSelector'

module RDI

  module Test

    class RDITestCase < ::Test::Unit::TestCase

      # Get a simple description to use in these test cases
      #
      # Return:
      # * <em>RDI::Model::DependencyDescription</em>: The description
      def getSimpleDesc
        return RDI::Model::DependencyDescription.new('DummyBinary').addDescription( {
          :Testers => [
            {
              :Type => 'Binaries',
              :Content => [ 'DummyBinary' ]
            }
          ],
          :Installers => [
            {
              :Type => 'Download',
              :Content => "#{@RepositoryDir}/Binaries/DummyBinary",
              :ContextModifiers => [
                {
                  :Type => 'SystemPath',
                  :Content => '%INSTALLDIR%'
                }
              ]
            }
          ]
        } )
      end

      # Get another simple description to use in these test cases
      #
      # Return:
      # * <em>RDI::Model::DependencyDescription</em>: The description
      def getSimpleDesc2
        return RDI::Model::DependencyDescription.new('DummyLibrary').addDescription( {
          :Testers => [
            {
              :Type => 'DynamicLibraries',
              :Content => [ 'DummyLibrary.so' ]
            }
          ],
          :Installers => [
            {
              :Type => 'Download',
              :Content => "#{@RepositoryDir}/Libraries/DummyLibrary.so",
              :ContextModifiers => [
                {
                  :Type => 'LibraryPath',
                  :Content => '%INSTALLDIR%'
                }
              ]
            }
          ]
        } )
      end

      # Get a simple description using 2 Installers
      #
      # Return:
      # * <em>RDI::Model::DependencyDescription</em>: The description
      def get2InstallersDesc
        return RDI::Model::DependencyDescription.new('DummyBinary2').addDescription( {
          :Testers => [
            {
              :Type => 'Binaries',
              :Content => [ 'DummyBinary' ]
            }
          ],
          :Installers => [
            {
              :Type => 'Download',
              :Content => "#{@RepositoryDir}/Binaries/DummyBinary",
              :ContextModifiers => [
                {
                  :Type => 'SystemPath',
                  :Content => '%INSTALLDIR%'
                }
              ]
            },
            {
              :Type => 'Download',
              :Content => "#{@RepositoryDir}/Binaries/../Binaries/DummyBinary",
              :ContextModifiers => [
                {
                  :Type => 'SystemPath',
                  :Content => '%INSTALLDIR%'
                }
              ]
            }
          ]
        } )
      end

      # Constructor
      def setup
        @RepositoryDir = File.expand_path("#{File.dirname(__FILE__)}/Repository")
        @Installer = nil
        # Silent user interaction of logging
        @MessagesStack = []
        setLogMessagesStack(@MessagesStack)
        @ErrorsStack = []
        setLogErrorsStack(@ErrorsStack)
      end

      # Define a dummy test case to avoid errors during run of this class
      # TODO: Remove this method
      def testDummy_BaseClass
      end

      # Setup an applicative directory and an installer
      #
      # Parameters:
      # * *CodeBlock*: The code called once the application is ready
      def setupAppDir
        # Get an image of the context, as we will put it back after the testing
        lSystemPath = $rUtilAnts_Platform_Info.getSystemExePath.clone
        lLibsPath = $rUtilAnts_Platform_Info.getSystemLibsPath.clone
        lLoadPath = $LOAD_PATH.clone
        lGemsPath = nil
        if (defined?(Gem) != nil)
          lGemsPath = Gem.path.clone
          if (defined?(Gem.clearCache_RDI))
            Gem.clearCache_RDI
          end
        end
        # Create the application root directory for testing
        lAppRootDir = "#{Dir.tmpdir}/RDITest/#{self.class.to_s.gsub(/:/,'_')}"
        # If the application dir exists, clean it first
        if (File.exists?(lAppRootDir))
          FileUtils::rm_rf(lAppRootDir)
        end
        FileUtils::mkdir_p(lAppRootDir)
        # Create the installer
        @Installer = RDI::Installer.new(lAppRootDir)
        # Call the test code
        yield
        @Installer = nil
        # Remove the temporary application root dir
        FileUtils::rm_rf(lAppRootDir)
        # Put back the context
        $rUtilAnts_Platform_Info.setSystemExePath(lSystemPath)
        $rUtilAnts_Platform_Info.setSystemLibsPath(lLibsPath)
        $LOAD_PATH.replace(lLoadPath)
        if (defined?(Gem) != nil)
          Gem.clear_paths
          lGemsPath.each do |iDir|
            if (!Gem.path.include?(iDir))
              Gem.path << iDir
            end
          end
        end
      end

      # Setup a regresion UI before calling some code
      #
      # Parameters:
      # * *iClassName* (_String_): Class name of the View to be used
      # * *iLocationSelectorClassName* (_String_): Class name of the location selector [optional = nil]
      def setupRegressionUI(iClassName, iLocationSelectorClassName = nil)
        # Add a View plugin
        @Installer.registerNewPlugin(
          'Views',
          'RegressionUI',
          nil,
          nil,
          iClassName,
          nil
        )
        # Add the location selector
        if (iLocationSelectorClassName != nil)
          @Installer.registerNewPlugin(
            'LocationSelectors_RegressionUI',
            'Directory',
            nil,
            nil,
            iLocationSelectorClassName,
            nil
          )
        end
        yield
      end

    end

    # Module defining methods that test a given Tester
    # The setup of classes including this module should define
    #  @TesterPluginName
    #  getTestContent
    #  installTestContent
    #  uninstallTestContent
    module RDITestCase_Testers

      # Test that the API is correctly defined
      def testAPI
        setupAppDir do
          @Installer.accessPlugin('Testers', @TesterPluginName) do |ioPlugin|
            assert(ioPlugin.is_a?(RDI::Model::Tester))
            assert(ioPlugin.respond_to?(:isContentResolved?))
            assert(ioPlugin.respond_to?(:getAffectingContextModifiers))
            # Test that returned Affecting Context Modifiers are valid.
            lAvailableCMs = @Installer.getPluginNames('ContextModifiers')
            ioPlugin.getAffectingContextModifiers.each do |iCMName|
              assert_equal(true, lAvailableCMs.include?(iCMName))
            end
          end
        end
      end

      # Test that the dependency does not exist in an empty project
      def testMissingDep
        setupAppDir do
          @Installer.accessPlugin('Testers', @TesterPluginName) do |ioPlugin|
            lContent = getTestContent
            assert_equal(false, ioPlugin.isContentResolved?(lContent))
          end
        end
      end

      # Test that once installed, it detects the dependency as being present
      def testExistingDep
        setupAppDir do
          @Installer.accessPlugin('Testers', @TesterPluginName) do |ioPlugin|
            lContent = getTestContent
            installTestContent
            assert_equal(true, ioPlugin.isContentResolved?(lContent))
            uninstallTestContent
          end
        end
      end

    end

    # Module defining methods that test a given Installer
    # The setup of classes including this module should define
    #  @InstallerPluginName
    #  getTestContent
    #  verifyInstalledContent
    #  uninstallTestContent
    #  getOtherLocation
    module RDITestCase_Installers

      # Test that the API is correctly defined
      def testAPI
        setupAppDir do
          @Installer.accessPlugin('Installers', @InstallerPluginName) do |ioPlugin|
            assert(ioPlugin.is_a?(RDI::Model::Installer))
            assert(ioPlugin.respond_to?(:getPossibleDestinations))
            assert(ioPlugin.respond_to?(:installDependency))
            lDestinations = ioPlugin.getPossibleDestinations
            assert(lDestinations.is_a?(Array))
            assert(lDestinations.size > 0)
            assert(lDestinations[0][0] != DEST_OTHER)
            lDestinations.each do |iDestination|
              assert(iDestination.is_a?(Array))
              assert(iDestination.size == 2)
              iFlavour, iLocation = iDestination
              assert(iFlavour.is_a?(Fixnum))
              if (iFlavour == DEST_OTHER)
                # Check that this selector location name exists for every GUI we have
                assert(iLocation.is_a?(String))
                @Installer.getPluginNames('Views').each do |iViewName|
                  assert(@Installer.getPluginNames("LocationSelectors_#{iViewName}").include?(iLocation))
                end
              end
            end
          end
        end
      end

      # Test that installing works correctly
      def testInstallDep
        setupAppDir do
          @Installer.accessPlugin('Installers', @InstallerPluginName) do |ioPlugin|
            lContent = getTestContent
            # Test installation on every possible location
            ioPlugin.getPossibleDestinations.each do |iDestination|
              iFlavour, iLocation = iDestination
              lLocation = iLocation
              if (iFlavour == DEST_OTHER)
                # Use a temporary location
                lLocation = getOtherLocation
              end
              assert_equal(false, verifyInstalledContent(lLocation))
              # Install the test content
              ioPlugin.installDependency(lContent, lLocation)
              # Verify
              assert_equal(true, verifyInstalledContent(lLocation))
              # Remove
              uninstallTestContent(lLocation)
            end
          end
        end
      end

    end

    # Module defining methods that test a given ContextModifier
    # The setup of classes including this module should define
    #  @ContextModifierPluginName
    #  getTestLocation
    module RDITestCase_ContextModifiers

      # Test that the API is correctly defined
      def testAPI
        setupAppDir do
          @Installer.accessPlugin('ContextModifiers', @ContextModifierPluginName) do |ioPlugin|
            assert(ioPlugin.is_a?(RDI::Model::ContextModifier))
            assert(ioPlugin.respond_to?(:getLocationSelectorName))
            assert(ioPlugin.respond_to?(:transformContentWithInstallEnv))
            assert(ioPlugin.respond_to?(:isLocationInContext?))
            assert(ioPlugin.respond_to?(:addLocationToContext))
            assert(ioPlugin.respond_to?(:removeLocationFromContext))
            # Check that the location selector name exists for every view we have.
            lLocationSelectorName = ioPlugin.getLocationSelectorName
            assert(lLocationSelectorName.is_a?(String))
            @Installer.getPluginNames('Views').each do |iViewName|
              assert(@Installer.getPluginNames("LocationSelectors_#{iViewName}").include?(lLocationSelectorName))
            end
          end
        end
      end

      # Test missing location
      def testMissingLocation
        setupAppDir do
          @Installer.accessPlugin('ContextModifiers', @ContextModifierPluginName) do |ioPlugin|
            lLocation = getTestLocation
            assert_equal(false, ioPlugin.isLocationInContext?(lLocation))
          end
        end
      end

      # Test that adding locations works correctly
      def testAddLocation
        setupAppDir do
          @Installer.accessPlugin('ContextModifiers', @ContextModifierPluginName) do |ioPlugin|
            lLocation = getTestLocation
            assert_equal(false, ioPlugin.isLocationInContext?(lLocation))
            ioPlugin.addLocationToContext(lLocation)
            assert_equal(true, ioPlugin.isLocationInContext?(lLocation))
          end
        end
      end

      # Test that removing locations works correctly
      def testRemoveLocation
        setupAppDir do
          @Installer.accessPlugin('ContextModifiers', @ContextModifierPluginName) do |ioPlugin|
            lLocation = getTestLocation
            assert_equal(false, ioPlugin.isLocationInContext?(lLocation))
            ioPlugin.addLocationToContext(lLocation)
            assert_equal(true, ioPlugin.isLocationInContext?(lLocation))
            ioPlugin.removeLocationFromContext(lLocation)
            assert_equal(false, ioPlugin.isLocationInContext?(lLocation))
          end
        end
      end

    end

    # Module defining methods that test a given View
    # The setup of classes including this module should define
    #  @ViewPluginName
    module RDITestCase_Views

      # Constants, along with the type of object following it
      # Nothing
      ACTION_LOCATE = 0
      # Nothing
      ACTION_IGNORE = 1
      # Integer: Installer's index
      # Integer: Destination's index
      # Object: Install location (if needed - nil otherwise)
      ACTION_INSTALL = 2
      # Nothing
      ACTION_APPLY = 3
      # String: ContextModifier name
      # Object: Location
      ACTION_SELECT_AFFECTING_CONTEXTMODIFIER = 4

      # An action is the triplet
      # [ Integer, String, Object ]
      # [ ActionID, DepID, Parameters ]

      # Test that the API is correctly defined
      def testAPI
        setupAppDir do
          @Installer.accessPlugin('Views', @ViewPluginName) do |ioPlugin|
            assert(ioPlugin.is_a?(RDI::Model::View))
            assert(ioPlugin.respond_to?(:execute))
          end
        end
      end

      # Default implementation for initScenario
      # To be rewritten by each View plugin test suite
      #
      # Parameters:
      # * *ioPlugin* (_Object_): The View plugin
      # * *iScenario* (<em>list<[Integer,String,Object]></em>): The scenario
      # * *iMissingDependencies* (<em>list<DependencyDescription></em>): The missing dependencies list
      def initScenario(ioPlugin, iScenario, iMissingDependencies)
        # Display it to the user for him to perform the actions
        lActionsStr = []
        lIdxAction = 1
        iScenario.each do |iActionInfo|
          iAction, iDepID, iParameters = iActionInfo
          lStr = "[#{iDepID}] - "
          case iAction
          when ACTION_LOCATE
            lStr += 'Choose Locate'
          when ACTION_IGNORE
            lStr += 'Choose Ignore'
          when ACTION_INSTALL
            if (iParameters[2] == nil)
              lStr += "Choose Installer n.#{iParameters[0]}, Destination n.#{iParameters[1]}"
            else
              lStr += "Choose Installer n.#{iParameters[0]}, Destination n.#{iParameters[1]}, Location: #{iParameters[2]}"
            end
          when ACTION_APPLY
            lStr = 'Apply'
          when ACTION_SELECT_AFFECTING_CONTEXTMODIFIER
            lStr += "Choose Locate ContextModifier #{iParameters[0]} using Location: #{iParameters[1]}"
          else
            logBug "Unknown Action: #{iAction}"
          end
          lActionsStr << "#{lIdxAction} - #{lStr}"
          lIdxAction += 1
        end
        # Remove the logging silent mode before displaying
        setLogMessagesStack(nil)
        logMsg "Please perform the following:\n#{lActionsStr.join("\n")}"
      end

      # Default implementation for finalScenario
      # To be rewritten by each View plugin test suite
      #
      # Parameters:
      # * *ioPlugin* (_Object_): The View plugin
      def finalScenario(ioPlugin)
        # Nothing to do
      end

      # Default implementation for executeScenario
      # To be rewritten by each View plugin test suite
      #
      # Parameters:
      # * *ioPlugin* (_Object_): The View plugin
      # * *ioInstaller* (_Installer_): The RDI installer
      # * *iMissingDependencies* (<em>list<DependencyDescription></em>): The missing dependencies list
      # Return:
      # * <em>list<DependencyUserChoice></em>: The corresponding user choices
      def executeScenario(ioPlugin, ioInstaller, iMissingDependencies)
        return ioPlugin.execute(ioInstaller, iMissingDependencies)
      end

      # Setup a fake selector that always return a given value
      #
      # Parameters:
      # * *iSelectorName* (_String_): Name of the selector to modify
      # * *iLocation* (_Object_): Location to always give
      # * _CodeBlock_: The code to be executed once the fake selector is in place
      def setupFakeSelector(iSelectorName, iLocation)
        @Installer.accessPlugin("LocationSelectors_#{@ViewPluginName}", iSelectorName) do |ioLSPlugin|
          # Replace temporarily its getNewLocation method
          ioLSPlugin.class.module_eval('alias :getNewLocation_ORG :getNewLocation')
          # Define the new one
          ioLSPlugin.class.module_eval('
def getNewLocation
  return $RDI_Regression_Location
end
')
          $RDI_Regression_Location = iLocation
          # Use it
          yield
          # Put back the old method
          ioLSPlugin.class.module_eval('
remove_method :getNewLocation
alias :getNewLocation :getNewLocation_ORG
')
        end
      end

      # Get the dependency user choices from a scenario.
      # This is used to then compare if View plugins behave correctly
      #
      # Parameters:
      # * *iMissingDependencies* (<em>list<DependencyDescription></em>): The missing dependencies list
      # * *iScenario* (<em>list<[Integer,String,Object]></em>): The scenario
      # Return:
      # * <em>list<DependencyUserChoice></em>: The corresponding user choices
      def getUserChoicesFromScenario(iMissingDependencies, iScenario)
        rDepsUserChoices = []

        # First, initialize them
        # Create also a map that makes retrieving user choices based on DepID easier
        # map< String, DependencyUserChoice >
        lDepsUserChoicesIndex = {}
        iMissingDependencies.each do |iDepDesc|
          lDepUserChoice = RDI::Model::DependencyUserChoice.new(@Installer, @ViewPluginName, iDepDesc)
          rDepsUserChoices << lDepUserChoice
          lDepsUserChoicesIndex[iDepDesc.ID] = lDepUserChoice
        end
        # Then modify them based on the scenario
        iScenario.each do |iActionInfo|
          iAction, iDepID, iParameters = iActionInfo
          # First, find the correct dependency user choice
          lDepUserChoice = nil
          if (iDepID != nil)
            lDepUserChoice = lDepsUserChoicesIndex[iDepID]
          end
          case iAction
          when ACTION_LOCATE
            lDepUserChoice.setLocate
          when ACTION_IGNORE
            lDepUserChoice.setIgnore
          when ACTION_INSTALL
            lDepUserChoice.setInstaller(iParameters[0], iParameters[1])
            if (iParameters[2] != nil)
              # Make sure the LocationSelector returns iParameters[2]
              # Get the name of the selector
              @Installer.accessPlugin('Installers', lDepUserChoice.DepDesc.Installers[iParameters[0]][0]) do |iInstallPlugin|
                lSelectorName = iInstallPlugin.PossibleDestinations[iParameters[1]][1]
                setupFakeSelector(lSelectorName, iParameters[2]) do
                  lDepUserChoice.selectOtherInstallLocation(lSelectorName)
                end
              end
            end
          when ACTION_APPLY
            break
          when ACTION_SELECT_AFFECTING_CONTEXTMODIFIER
            # Make sure the LocationSelector returns iParameters[1]
            @Installer.accessPlugin('ContextModifiers', iParameters[0]) do |ioCMPlugin|
              # Get the name of LocationSelector class to use
              lLocationSelectorName = ioCMPlugin.LocationSelectorName
              setupFakeSelector(lLocationSelectorName, iParameters[1]) do
                lDepUserChoice.affectContextModifier(iParameters[0])
              end
            end
          else
            logBug "Unknown Action: #{iAction}"
          end
        end

        return rDepsUserChoices
      end

      # Launches a scenario test
      #
      # Parameters:
      # * *iMissingDependencies* (<em>list<DependencyDescription></em>): The missing dependencies list
      # * *iScenario* (<em>list<[Integer,String,Object]></em>): The scenario
      def launchScenario(iMissingDependencies, iScenario)
        setupAppDir do
          lUserChoices = nil
          @Installer.accessPlugin('Views', @ViewPluginName) do |ioPlugin|
            # Create the scenario and prepare it to be run
            initScenario(ioPlugin, iScenario, iMissingDependencies)
            # Execute it
            lUserChoices = executeScenario(ioPlugin, @Installer, iMissingDependencies )
            # Finalize the scenario
            finalScenario(ioPlugin)
            # Check generic parameters from the scenario
            assert_equal(lUserChoices, getUserChoicesFromScenario(iMissingDependencies, iScenario))
          end
        end
      end

      # Test installing everything by default
      def testDefaultInstall
        launchScenario( [ getSimpleDesc ], [
          [ ACTION_APPLY, nil, nil ]
        ] )
      end

      # Test installing everything by default for 2 dependencies
      def testDefaultInstall2Deps
        launchScenario( [ getSimpleDesc, getSimpleDesc2 ], [
          [ ACTION_APPLY, nil, nil ]
        ] )
      end

      # Test ignoring
      def testIgnore
        launchScenario( [ getSimpleDesc ], [
          [ ACTION_IGNORE, 'DummyBinary', nil ],
          [ ACTION_APPLY, nil, nil ]
        ] )
      end

      # Test ignoring 1 of 2 deps
      def testIgnore1Of2Deps
        launchScenario( [ getSimpleDesc, getSimpleDesc2 ], [
          [ ACTION_IGNORE, 'DummyLibrary', nil ],
          [ ACTION_APPLY, nil, nil ]
        ] )
      end

      # Test install to a different location
      def testInstallDest
        launchScenario( [ getSimpleDesc ], [
          [ ACTION_INSTALL, 'DummyBinary', [ 0, 1, nil ] ],
          [ ACTION_APPLY, nil, nil ]
        ] )
      end

      # Test install to a different location 1 of 2 deps
      def testInstallDest1Of2Deps
        launchScenario( [ getSimpleDesc, getSimpleDesc2 ], [
          [ ACTION_INSTALL, 'DummyLibrary', [ 0, 1, nil ] ],
          [ ACTION_APPLY, nil, nil ]
        ] )
      end

      # Test install to another location to be choosen
      def testInstallOtherLocation
        # Get the index of the DEST_OTHER destination
        lIdxDest = 0
        lDesc = getSimpleDesc
        setupAppDir do
          @Installer.accessPlugin('Installers', lDesc.Installers[0][0]) do |iPlugin|
            iPlugin.PossibleDestinations.each do |iDestInfo|
              iFlavour, iLocation = iDestInfo
              if (iFlavour == DEST_OTHER)
                # Found it
                break
              end
              lIdxDest += 1
            end
          end
        end
        launchScenario( [ lDesc ], [
          [ ACTION_INSTALL, 'DummyBinary', [ 0, lIdxDest, 'OtherLocation' ] ],
          [ ACTION_APPLY, nil, nil ]
        ] )
      end

      # Test install to another location to be choosen of 1 of 2 deps
      def testInstallOtherLocation1Of2Deps
        # Get the index of the DEST_OTHER destination
        lIdxDest = 0
        lDesc = getSimpleDesc2
        setupAppDir do
          @Installer.accessPlugin('Installers', lDesc.Installers[0][0]) do |iPlugin|
            iPlugin.PossibleDestinations.each do |iDestInfo|
              iFlavour, iLocation = iDestInfo
              if (iFlavour == DEST_OTHER)
                # Found it
                break
              end
              lIdxDest += 1
            end
          end
        end
        launchScenario( [ getSimpleDesc, lDesc ], [
          [ ACTION_INSTALL, 'DummyLibrary', [ 0, lIdxDest, 'OtherLocation' ] ],
          [ ACTION_APPLY, nil, nil ]
        ] )
      end

      # Test install using another installer
      def testInstallOtherInstaller
        launchScenario( [ get2InstallersDesc ], [
          [ ACTION_INSTALL, 'DummyBinary2', [ 1, 0, nil ] ],
          [ ACTION_APPLY, nil, nil ]
        ] )
      end

      # Test install using another installer for 1 of 2 deps
      def testInstallOtherInstaller1Of2Deps
        launchScenario( [ getSimpleDesc, get2InstallersDesc ], [
          [ ACTION_INSTALL, 'DummyBinary2', [ 1, 0, nil ] ],
          [ ACTION_APPLY, nil, nil ]
        ] )
      end

      # Test locate using a given ContextModifier
      def testLocateWithCM
        launchScenario( [ getSimpleDesc ], [
          [ ACTION_LOCATE, 'DummyBinary', nil ],
          [ ACTION_SELECT_AFFECTING_CONTEXTMODIFIER, 'DummyBinary', [ 'SystemPath', "#{@RepositoryDir}/Binaries" ] ],
          [ ACTION_APPLY, nil, nil ]
        ] )
      end

      # Test locate using a given ContextModifier for 1 of 2 deps
      def testLocateWithCM1Of2Deps
        launchScenario( [ getSimpleDesc, getSimpleDesc2 ], [
          [ ACTION_LOCATE, 'DummyBinary', nil ],
          [ ACTION_SELECT_AFFECTING_CONTEXTMODIFIER, 'DummyBinary', [ 'SystemPath', "#{@RepositoryDir}/Binaries" ] ],
          [ ACTION_APPLY, nil, nil ]
        ] )
      end

      # Test locate using a given ContextModifier with an invalid Location
      def testLocateWithCMBadLocation
        launchScenario( [ getSimpleDesc ], [
          [ ACTION_LOCATE, 'DummyBinary', nil ],
          [ ACTION_SELECT_AFFECTING_CONTEXTMODIFIER, 'DummyBinary', [ 'SystemPath', "#{@RepositoryDir}/BadBinaries" ] ],
          [ ACTION_APPLY, nil, nil ]
        ] )
      end

      # Test locate using a given ContextModifier with an invalid Location for 1 of 2 deps
      def testLocateWithCMBadLocation1Of2Deps
        launchScenario( [ getSimpleDesc, getSimpleDesc2 ], [
          [ ACTION_LOCATE, 'DummyBinary', nil ],
          [ ACTION_SELECT_AFFECTING_CONTEXTMODIFIER, 'DummyBinary', [ 'SystemPath', "#{@RepositoryDir}/BadBinaries" ] ],
          [ ACTION_APPLY, nil, nil ]
        ] )
      end

    end

    # Module defining methods that test a given LocationSelector
    # The setup of classes including this module should define
    #  @LocationSelectorPluginName
    module RDITestCase_LocationSelectors

      # Test that the API is correctly defined
      def testAPI
        setupAppDir do
          # Check that each view defines it
          # Get the list of views
          @Installer.getPluginNames('Views').each do |iViewName|
            # Install the dependencies automatically before calling the plugin (we don't want to ask the user about it)
            lInstallMethod = "installDep_#{iViewName}".to_sym
            if (respond_to?(lInstallMethod))
              send(lInstallMethod)
            end
            @Installer.accessPlugin("LocationSelectors_#{iViewName}", @LocationSelectorPluginName) do |ioPlugin|
              assert(ioPlugin.is_a?(RDI::Model::LocationSelector))
              assert(ioPlugin.respond_to?(:getNewLocation))
            end
          end
        end
      end

    end

  end

end
