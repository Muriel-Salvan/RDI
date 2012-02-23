#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'fileutils'
require 'tmpdir'

module RDI

  module Test

    module Flows

      class UIFlows < RDITestCase

        # RegressionUI plugin
        class RegressionUI < RDI::Model::View

          # Directory selector
          class Directory < RDI::Model::LocationSelector

            # Were we called ?
            #   Bolean
            attr_reader :Called

            # Directory to return
            #   String
            attr_accessor :Directory

            # Constructor
            def initialize
              super
              @Directory = nil
              @Called = false
            end

            # Give user the choice of a new location
            #
            # Return::
            # * _Object_: A location, or nil if none selected
            def getNewLocation
              @Called = true
              return @Directory
            end

          end

          # Called ?
          #   Boolean
          attr_reader :Called

          # Missing dependencies
          #   list<DependencyDescription>
          attr_reader :MissingDependencies

          # Install location
          #   Object
          attr_reader :InstallLocation

          # Do we ignore the dependencies ?
          #   Boolean
          attr_accessor :Ignore

          # Do we locate this dependency ?
          #   Boolean
          attr_accessor :Locate

          # Do we install to a new location ?
          #   Boolean
          attr_accessor :InstallOtherLocation

          # Constructor
          def initialize
            super
            @Called = false
            @MissingDependencies = nil
            @Ignore = false
            @Locate = false
            @InstallLocation = nil
            @InstallOtherLocation = false
          end

          # Ask the user about missing dependencies.
          # This method will use a user interface to know what to do with missing dependencies.
          # For each dependency, choices are:
          # * Install it
          # * Ignore it
          # * Change the context to find it (select directory...)
          #
          # Parameters::
          # * *ioInstaller* (_Installer_): The RDI installer
          # * *iMissingDependencies* (<em>list<DependencyDescription></em>): The missing dependencies list
          # Return::
          # * <em>list<DependencyUserChoice></em>: The corresponding user choices
          def execute(ioInstaller, iMissingDependencies)
            # List of corresponding dependencies user choices
            # list< DependencyUserChoice >
            rDependenciesUserChoices = []

            @Called = true
            @MissingDependencies = iMissingDependencies
            iMissingDependencies.each do |iDepDesc|
              rDependenciesUserChoices << RDI::Model::DependencyUserChoice.new(ioInstaller, 'RegressionUI', iDepDesc)
            end
            if (@Ignore)
              rDependenciesUserChoices.each do |ioDepUserChoice|
                ioDepUserChoice.set_ignore
              end
            elsif (@Locate)
              rDependenciesUserChoices.each do |ioDepUserChoice|
                ioDepUserChoice.set_locate
                ioDepUserChoice.affect_context_modifier('SystemPath')
              end
            elsif (@InstallOtherLocation)
              # We want to install to another location
              rDependenciesUserChoices.each do |ioDepUserChoice|
                iInstallName, iInstallContent, iContextModifiers = ioDepUserChoice.DepDesc.Installers[0]
                # Read the installer plugin
                ioInstaller.access_plugin('Installers', iInstallName) do |iPlugin|
                  lIdx = 0
                  iPlugin.PossibleDestinations.each do |iDestInfo|
                    iFlavour, iLocation = iDestInfo
                    if (iFlavour == DEST_OTHER)
                      # Found it
                      ioDepUserChoice.set_installer(0, lIdx)
                      ioDepUserChoice.select_other_install_location(iLocation)
                      break
                    end
                    lIdx += 1
                  end
                end
              end
            else
              # We want to install.
              # Make sure we do so in the local destination
              rDependenciesUserChoices.each do |ioDepUserChoice|
                iInstallName, iInstallContent, iContextModifiers = ioDepUserChoice.DepDesc.Installers[0]
                # Read the installer plugin
                ioInstaller.access_plugin('Installers', iInstallName) do |iPlugin|
                  lIdx = 0
                  iPlugin.PossibleDestinations.each do |iDestInfo|
                    iFlavour, iLocation = iDestInfo
                    if (iFlavour == DEST_LOCAL)
                      # Found it
                      ioDepUserChoice.set_installer(0, lIdx)
                      @InstallLocation = iLocation
                      break
                    end
                    lIdx += 1
                  end
                end
              end
            end

            return rDependenciesUserChoices
          end

        end

        # Test that we ask correctly for the UI
        def testCallUI
          lCalled = false
          setupAppDir do
            setupRegressionUI('RDI::Test::Flows::UIFlows::RegressionUI') do
              # Call the installer expecting the GUI to appear
              lDesc = getSimpleDesc
              lError, lCMApplied, lIgnoredDeps, lUnresolvedDeps = @Installer.ensure_dependencies( [ lDesc ], {
                :preferred_views => [ 'RegressionUI' ]
              } )
              # Get the plugin back
              @Installer.access_plugin('Views', 'RegressionUI') do |iPlugin|
                # Check that it was called correctly
                lCalled = iPlugin.Called
              end
            end
          end
          assert_equal(true, lCalled)
        end

        # Test that we don't ask for the UI when dependencies are resolved naturally
        def testNoCallUIWithExistingDeps
          lCalled = false
          setupAppDir do
            setupRegressionUI('RDI::Test::Flows::UIFlows::RegressionUI') do
              # Call the installer expecting the GUI to appear
              lDesc = getSimpleDesc
              # First install the dependency
              lError, lCMApplied, lIgnoredDeps, lUnresolvedDeps = @Installer.ensure_dependencies( [ lDesc ], {
                :auto_install => DEST_LOCAL
              } )
              # Then try again with UI
              lError, lCMApplied, lIgnoredDeps, lUnresolvedDeps = @Installer.ensure_dependencies( [ lDesc ], {
                :preferred_views => [ 'RegressionUI' ]
              } )
              assert_equal(nil, lError)
              assert_equal( {}, lCMApplied )
              assert_equal( [], lIgnoredDeps )
              assert_equal( [], lUnresolvedDeps )
              # Get the plugin back
              @Installer.access_plugin('Views', 'RegressionUI') do |iPlugin|
                # Check that it was called correctly
                lCalled = iPlugin.Called
              end
            end
          end
          assert_equal(false, lCalled)
        end

        # Test that we don't ask for the UI when dependencies are resolved thanks to additional context modifiers
        def testNoCallUIWithResolvedDeps
          lCalled = false
          setupAppDir do
            setupRegressionUI('RDI::Test::Flows::UIFlows::RegressionUI') do
              # Call the installer expecting the GUI to appear
              lDesc = getSimpleDesc
              lError, lCMApplied, lIgnoredDeps, lUnresolvedDeps = @Installer.ensure_dependencies( [ lDesc ], {
                :possible_context_modifiers => {
                  'DummyBinary' => [
                    [
                      [ 'SystemPath', "#{@RepositoryDir}/Binaries" ]
                    ]
                  ]
                },
                :preferred_views => [ 'RegressionUI' ]
              } )
              assert_equal(nil, lError)
              assert_equal( { 'DummyBinary' => [ [ 'SystemPath', "#{@RepositoryDir}/Binaries" ] ] }, lCMApplied )
              assert_equal( [], lIgnoredDeps )
              assert_equal( [], lUnresolvedDeps )
              # Get the plugin back
              @Installer.access_plugin('Views', 'RegressionUI') do |iPlugin|
                # Check that it was called correctly
                lCalled = iPlugin.Called
              end
            end
          end
          assert_equal(false, lCalled)
        end

        # Test that we give correctly missing dependencies to the UI
        def testInputMissingDeps
          lCalled = false
          setupAppDir do
            setupRegressionUI('RDI::Test::Flows::UIFlows::RegressionUI') do
              # Call the installer expecting the GUI to appear
              lDesc = getSimpleDesc
              lError, lCMApplied, lIgnoredDeps, lUnresolvedDeps = @Installer.ensure_dependencies( [ lDesc ], {
                :preferred_views => [ 'RegressionUI' ]
              } )
              assert_equal(nil, lError)
              assert_equal( [], lIgnoredDeps )
              assert_equal( [], lUnresolvedDeps )
              # Get the plugin back
              @Installer.access_plugin('Views', 'RegressionUI') do |iPlugin|
                # Check that it was called correctly
                lCalled = iPlugin.Called
                assert_equal( { 'DummyBinary' => [ [ 'SystemPath', iPlugin.InstallLocation ] ] }, lCMApplied )
                # Check input parameters were given correctly
                assert_equal([ lDesc ], iPlugin.MissingDependencies)
              end
            end
          end
          assert_equal(true, lCalled)
        end

        # Test installing a dependency
        def testInstallDep
          lCalled = false
          setupAppDir do
            setupRegressionUI('RDI::Test::Flows::UIFlows::RegressionUI') do
              # Call the installer expecting the GUI to appear
              lDesc = getSimpleDesc
              lError, lCMApplied, lIgnoredDeps, lUnresolvedDeps = @Installer.ensure_dependencies( [ lDesc ], {
                :preferred_views => [ 'RegressionUI' ]
              } )
              # Check results
              assert_equal(nil, lError)
              assert_equal( [], lIgnoredDeps )
              assert_equal( [], lUnresolvedDeps )
              # Get the plugin back
              @Installer.access_plugin('Views', 'RegressionUI') do |iPlugin|
                # Check that it was called correctly
                lCalled = iPlugin.Called
                # Get the first install destination (this is where it will be installed
                assert_equal( { 'DummyBinary' => [ [ 'SystemPath', iPlugin.InstallLocation ] ] }, lCMApplied )
              end
              # Check that the dependency is resolved
              @Installer.access_plugin('Testers', 'Binaries') do |iPlugin|
                assert_equal(true, iPlugin.is_content_resolved?(['DummyBinary']))
              end
            end
          end
          assert_equal(true, lCalled)
        end

        # Test ignoring a dependency
        def testIgnoreDep
          lCalled = false
          setupAppDir do
            setupRegressionUI('RDI::Test::Flows::UIFlows::RegressionUI') do
              # Tune the UI's behaviour
              @Installer.access_plugin('Views', 'RegressionUI') do |ioPlugin|
                ioPlugin.Ignore = true
              end
              # Call the installer expecting the GUI to appear
              lDesc = getSimpleDesc
              lError, lCMApplied, lIgnoredDeps, lUnresolvedDeps = @Installer.ensure_dependencies( [ lDesc ], {
                :preferred_views => [ 'RegressionUI' ]
              } )
              # Check results
              assert_equal(nil, lError)
              assert_equal( {}, lCMApplied )
              assert_equal( [ lDesc ], lIgnoredDeps )
              assert_equal( [], lUnresolvedDeps )
              # Get the plugin back
              @Installer.access_plugin('Views', 'RegressionUI') do |iPlugin|
                # Check that it was called correctly
                lCalled = iPlugin.Called
              end
              # Check that the dependency is not resolved
              @Installer.access_plugin('Testers', 'Binaries') do |iPlugin|
                assert_equal(false, iPlugin.is_content_resolved?(['DummyBinary']))
              end
            end
          end
          assert_equal(true, lCalled)
        end

        # Test locating a dependency
        def testLocateDep
          lLocatorCalled = false
          lCalled = false
          setupAppDir do
            setupRegressionUI('RDI::Test::Flows::UIFlows::RegressionUI', 'RDI::Test::Flows::UIFlows::RegressionUI::Directory') do
              # Tune the UI's behaviour
              @Installer.access_plugin('Views', 'RegressionUI') do |ioPlugin|
                ioPlugin.Locate = true
              end
              @Installer.access_plugin('LocationSelectors_RegressionUI', 'Directory') do |ioPlugin|
                ioPlugin.Directory = "#{@RepositoryDir}/Binaries"
              end
              # Call the installer expecting the GUI to appear
              lDesc = getSimpleDesc
              lError, lCMApplied, lIgnoredDeps, lUnresolvedDeps = @Installer.ensure_dependencies( [ lDesc ], {
                :preferred_views => [ 'RegressionUI' ]
              } )
              # Check results
              assert_equal(nil, lError)
              assert_equal( { 'DummyBinary' => [ [ 'SystemPath', "#{@RepositoryDir}/Binaries" ] ] }, lCMApplied )
              assert_equal( [], lIgnoredDeps )
              assert_equal( [], lUnresolvedDeps )
              # Get the plugins back
              @Installer.access_plugin('Views', 'RegressionUI') do |iPlugin|
                # Check that it was called correctly
                lCalled = iPlugin.Called
              end
              @Installer.access_plugin('LocationSelectors_RegressionUI', 'Directory') do |iPlugin|
                # Check that it was called correctly
                lLocatorCalled = iPlugin.Called
              end
              # Check that the dependency is resolved
              @Installer.access_plugin('Testers', 'Binaries') do |iPlugin|
                assert_equal(true, iPlugin.is_content_resolved?(['DummyBinary']))
              end
            end
          end
          assert_equal(true, lCalled)
          assert_equal(true, lLocatorCalled)
        end

        # Test locating a dependency we can't resolve
        def testLocateDepError
          lLocatorCalled = false
          lCalled = false
          setupAppDir do
            setupRegressionUI('RDI::Test::Flows::UIFlows::RegressionUI', 'RDI::Test::Flows::UIFlows::RegressionUI::Directory') do
              # Tune the UI's behaviour
              @Installer.access_plugin('Views', 'RegressionUI') do |ioPlugin|
                ioPlugin.Locate = true
              end
              @Installer.access_plugin('LocationSelectors_RegressionUI', 'Directory') do |ioPlugin|
                # We give a wrong directory here
                ioPlugin.Directory = "#{@RepositoryDir}/Libraries"
              end
              # Call the installer expecting the GUI to appear
              lDesc = getSimpleDesc
              lError, lCMApplied, lIgnoredDeps, lUnresolvedDeps = @Installer.ensure_dependencies( [ lDesc ], {
                :preferred_views => [ 'RegressionUI' ]
              } )
              # Check results
              assert_equal(nil, lError)
              assert_equal( {}, lCMApplied )
              assert_equal( [], lIgnoredDeps )
              assert_equal( [ lDesc ], lUnresolvedDeps )
              # Get the plugins back
              @Installer.access_plugin('Views', 'RegressionUI') do |iPlugin|
                # Check that it was called correctly
                lCalled = iPlugin.Called
              end
              @Installer.access_plugin('LocationSelectors_RegressionUI', 'Directory') do |iPlugin|
                # Check that it was called correctly
                lLocatorCalled = iPlugin.Called
              end
              # Check that the dependency is resolved
              @Installer.access_plugin('Testers', 'Binaries') do |iPlugin|
                assert_equal(false, iPlugin.is_content_resolved?(['DummyBinary']))
              end
            end
          end
          assert_equal(true, lCalled)
          assert_equal(true, lLocatorCalled)
        end

        # Test installing in another destination
        def testInstallDepOtherLocation
          lCalled = false
          setupAppDir do
            setupRegressionUI('RDI::Test::Flows::UIFlows::RegressionUI', 'RDI::Test::Flows::UIFlows::RegressionUI::Directory') do
              # Tune the UI
              @Installer.access_plugin('Views', 'RegressionUI') do |ioPlugin|
                ioPlugin.InstallOtherLocation = true
              end
              lInstallDir = "#{@Installer.TempDir}/Regression"
              @Installer.access_plugin('LocationSelectors_RegressionUI', 'Directory') do |ioPlugin|
                # Set the directory where we want to install
                ioPlugin.Directory = lInstallDir
              end
              # Call the installer expecting the GUI to appear
              lDesc = getSimpleDesc
              lError, lCMApplied, lIgnoredDeps, lUnresolvedDeps = @Installer.ensure_dependencies( [ lDesc ], {
                :preferred_views => [ 'RegressionUI' ]
              } )
              # Check results
              assert_equal(nil, lError)
              assert_equal( [], lIgnoredDeps )
              assert_equal( [], lUnresolvedDeps )
              # Get the plugin back
              @Installer.access_plugin('Views', 'RegressionUI') do |iPlugin|
                # Check that it was called correctly
                lCalled = iPlugin.Called
                # Get the first install destination (this is where it will be installed
                assert_equal( { 'DummyBinary' => [ [ 'SystemPath', lInstallDir ] ] }, lCMApplied )
              end
              # Check that the dependency is resolved
              @Installer.access_plugin('Testers', 'Binaries') do |iPlugin|
                assert_equal(true, iPlugin.is_content_resolved?(['DummyBinary']))
              end
            end
          end
          assert_equal(true, lCalled)
        end

      end

    end

  end

end