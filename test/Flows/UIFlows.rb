#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
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

          # Constructor
          def initialize
            super
            @Called = false
            @MissingDependencies = nil
          end

          # Ask the user about missing dependencies.
          # This method will use a user interface to know what to do with missing dependencies.
          # For each dependency, choices are:
          # * Install it
          # * Ignore it
          # * Change the context to find it (select directory...)
          #
          # Parameters:
          # * *ioInstaller* (_Installer_): The RDI installer
          # * *iMissingDependencies* (<em>list<DependencyDescription></em>): The missing dependencies list
          # Return:
          # * <em>list<DependencyUserChoice></em>: The corresponding user choices
          def execute(ioInstaller, iMissingDependencies)
            # List of corresponding dependencies user choices
            # list< DependencyUserChoice >
            rDependenciesUserChoices = []

            @Called = true
            @MissingDependencies = iMissingDependencies

            return rDependenciesUserChoices
          end

          # Called ?
          #   Boolean
          attr_reader :Called

          # Missing dependencies
          #   list<DependencyDescription>
          attr_reader :MissingDependencies

        end

        # Test that we ask correctly for the UI
        def testCallUI
          lCalled = false
          setupAppDir do
            setupRegressionUI('RDI::Test::Flows::UIFlows::RegressionUI') do
              # Call the installer expecting the GUI to appear
              lDesc = getSimpleDesc
              lError, lCMApplied, lIgnoredDeps, lUnresolvedDeps = @Installer.ensureDependencies( [ lDesc ], {
                :PreferredViews => [ 'RegressionUI' ]
              } )
              # Get the plugin back
              @Installer.accessPlugin('Views', 'RegressionUI') do |iPlugin|
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
              lError, lCMApplied, lIgnoredDeps, lUnresolvedDeps = @Installer.ensureDependencies( [ lDesc ], {
                :AutoInstall => DEST_LOCAL
              } )
              # Then try again with UI
              lError, lCMApplied, lIgnoredDeps, lUnresolvedDeps = @Installer.ensureDependencies( [ lDesc ], {
                :PreferredViews => [ 'RegressionUI' ]
              } )
              # Get the plugin back
              @Installer.accessPlugin('Views', 'RegressionUI') do |iPlugin|
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
              lError, lCMApplied, lIgnoredDeps, lUnresolvedDeps = @Installer.ensureDependencies( [ lDesc ], {
                :PossibleContextModifiers => {
                  'DummyBinary' => [
                    [
                      [ 'SystemPath', "#{@RepositoryDir}/Binaries" ]
                    ]
                  ]
                },
                :PreferredViews => [ 'RegressionUI' ]
              } )
              # Get the plugin back
              @Installer.accessPlugin('Views', 'RegressionUI') do |iPlugin|
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
              lError, lCMApplied, lIgnoredDeps, lUnresolvedDeps = @Installer.ensureDependencies( [ lDesc ], {
                :PreferredViews => [ 'RegressionUI' ]
              } )
              # Get the plugin back
              @Installer.accessPlugin('Views', 'RegressionUI') do |iPlugin|
                # Check that it was called correctly
                lCalled = iPlugin.Called
                # Check input parameters were given correctly
                assert_equal([ lDesc ], iPlugin.MissingDependencies)
              end
            end
          end
          assert_equal(true, lCalled)
        end

      end

    end

  end

end