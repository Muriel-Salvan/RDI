#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

# This file is intended to be required by every test case.

require 'tmpdir'
require 'test/unit'
require 'rdi/rdi.rb'

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

      # Constructor
      def setup
        @RepositoryDir = File.expand_path("#{File.dirname(__FILE__)}/Repository")
        @Installer = nil
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
        lSystemPath = $CT_Platform_Info.getSystemExePath.clone
        lLibsPath = $CT_Platform_Info.getSystemLibsPath.clone
        lLoadPath = $LOAD_PATH.clone
        lGemsPath = nil
        if (defined?(Gem) != nil)
          lGemsPath = Gem.path.clone
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
        $CT_Platform_Info.setSystemExePath(lSystemPath)
        $CT_Platform_Info.setSystemLibsPath(lLibsPath)
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
      def setupRegressionUI(iClassName)
        # Add a View plugin
        @Installer.registerNewPlugin(
          'Views',
          'RegressionUI',
          nil,
          nil,
          iClassName,
          nil
        )
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

      # Test that the API is correctly defined
      def testAPI
        setupAppDir do
          @Installer.accessPlugin('Views', @ViewPluginName) do |ioPlugin|
            assert(ioPlugin.is_a?(RDI::Model::View))
            assert(ioPlugin.respond_to?(:execute))
          end
        end
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
