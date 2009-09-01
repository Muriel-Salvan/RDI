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

      # Constructor
      def setup
        @RepositoryDir = File.expand_path("#{File.dirname(__FILE__)}/DependenciesRepository")
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
          @Installer.send(:accessPlugin, 'Testers', @TesterPluginName) do |ioPlugin|
            assert(ioPlugin.respond_to?(:isContentResolved?))
          end
        end
      end

      # Test that the dependency does not exist in an empty project
      def testMissingDep
        setupAppDir do
          @Installer.send(:accessPlugin, 'Testers', @TesterPluginName) do |ioPlugin|
            lContent = getTestContent
            assert_equal(false, ioPlugin.isContentResolved?(lContent))
          end
        end
      end

      # Test that once installed, it detects the dependency as being present
      def testExistingDep
        setupAppDir do
          @Installer.send(:accessPlugin, 'Testers', @TesterPluginName) do |ioPlugin|
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
    #  getOtherLocationChooser
    #  getTestContent
    #  verifyInstalledContent
    #  uninstallTestContent
    #  getOtherLocation
    module RDITestCase_Installers

      # Test that the API is correctly defined
      def testAPI
        setupAppDir do
          @Installer.send(:accessPlugin, 'Installers', @InstallerPluginName) do |ioPlugin|
            assert(ioPlugin.respond_to?(:getPossibleDestinations))
            assert(ioPlugin.respond_to?(:installDependency))
            lDestinations = ioPlugin.getPossibleDestinations
            assert(lDestinations.is_a?(Array))
            lDestinations.each do |iDestination|
              assert(iDestination.is_a?(Array))
              assert(iDestination.size == 2)
              iFlavour, iLocation = iDestination
              assert(iFlavour.is_a?(Fixnum))
              if (iFlavour == DEST_OTHER)
                assert_equal(getOtherLocationChooser, iLocation)
              end
            end
          end
        end
      end

      # Test that installing works correctly
      def testInstallDep
        setupAppDir do
          @Installer.send(:accessPlugin, 'Installers', @InstallerPluginName) do |ioPlugin|
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

    # Module defining methods that test a given Installer
    # The setup of classes including this module should define
    #  @ContextModifierPluginName
    #  getTestLocation
    module RDITestCase_ContextModifiers

      # Test that the API is correctly defined
      def testAPI
        setupAppDir do
          @Installer.send(:accessPlugin, 'ContextModifiers', @ContextModifierPluginName) do |ioPlugin|
            assert(ioPlugin.respond_to?(:transformContentWithInstallEnv))
            assert(ioPlugin.respond_to?(:isLocationInContext?))
            assert(ioPlugin.respond_to?(:addLocationToContext))
            assert(ioPlugin.respond_to?(:removeLocationFromContext))
          end
        end
      end

      # Test missing location
      def testMissingLocation
        setupAppDir do
          @Installer.send(:accessPlugin, 'ContextModifiers', @ContextModifierPluginName) do |ioPlugin|
            lLocation = getTestLocation
            assert_equal(false, ioPlugin.isLocationInContext?(lLocation))
          end
        end
      end

      # Test that adding locations works correctly
      def testAddLocation
        setupAppDir do
          @Installer.send(:accessPlugin, 'ContextModifiers', @ContextModifierPluginName) do |ioPlugin|
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
          @Installer.send(:accessPlugin, 'ContextModifiers', @ContextModifierPluginName) do |ioPlugin|
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

  end

end
