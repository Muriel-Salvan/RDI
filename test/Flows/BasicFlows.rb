#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'fileutils'
require 'tmpdir'

module RDI

  module Test

    module Flows

      class BasicFlows < RDITestCase

        # Test that we can test for a missing dependency
        def testMissingDep
          setupAppDir do
            # Ask the installer to check for this description
            assert_equal(false, @Installer.testDependency(getSimpleDesc))
          end
        end

        # Test that we install dependencies correctly
        def testInstallDep
          setupAppDir do
            # Ask the installer to install this dependency in the local directory
            assert_equal(nil, @Installer.installDependency(getSimpleDesc, 0, @Installer.TempDir))
            assert(File.exists?("#{@Installer.TempDir}/DummyBinary"))
            File.unlink("#{@Installer.TempDir}/DummyBinary")
          end
        end

        # Test that we detect installed dependencies correctly
        def testExistingDep
          setupAppDir do
            # Ask the installer to install this dependency in the local directory
            lDesc = getSimpleDesc
            @Installer.installDependency(lDesc, 0, @Installer.TempDir)
            assert_equal(true, @Installer.testDependency(lDesc))
            File.unlink("#{@Installer.TempDir}/DummyBinary")
          end
        end

        # Test that ensuring dependencies effectively install them if needed
        def testEnsureDep
          setupAppDir do
            lDesc = getSimpleDesc
            lError, lCMApplied, lIgnoredDeps, lUnresolvedDeps = @Installer.ensureDependencies( [ lDesc ], {
              :AutoInstall => DEST_LOCAL
            } )
            assert_equal(nil, lError)
            assert_equal([], lIgnoredDeps)
            assert_equal([], lUnresolvedDeps)
            # Get the corresponding local folder
            lInstallLocation = @Installer.getDefaultInstallLocation(lDesc.Installers[0][0], DEST_LOCAL)
            assert(lInstallLocation != nil)
            assert_equal(true, File.exists?("#{lInstallLocation}/DummyBinary"))
            assert_equal(
              {
                'DummyBinary' => [
                  [ 'SystemPath', lInstallLocation ]
                ]
              },
              lCMApplied
            )
          end
        end

        # Test that ensureDeps also tries already tried context modifiers
        def testEnsureDepWithExistingContextModifier
          setupAppDir do
            lDesc = getSimpleDesc
            lError, lCMApplied, lIgnoredDeps, lUnresolvedDeps = @Installer.ensureDependencies( [ lDesc ], {
              :AutoInstall => DEST_LOCAL,
              :PossibleContextModifiers => {
                'DummyBinary' => [
                  [
                    [ 'SystemPath', "#{@RepositoryDir}/Binaries" ]
                  ]
                ]
              }
            } )
            assert_equal(nil, lError)
            assert_equal([], lIgnoredDeps)
            assert_equal([], lUnresolvedDeps)
            # If RDI has correctly found it, there are 2 things that can prove it:
            # 1. The system path should have "#{@RepositoryDir}/Binaries"
            @Installer.accessPlugin('Testers', 'Binaries') do |iPlugin|
              assert_equal(true, iPlugin.isContentResolved?('DummyBinary'))
            end
            # 2. The dependency should not have been installed
            lInstallLocation = @Installer.getDefaultInstallLocation(lDesc.Installers[0][0], DEST_LOCAL)
            assert(lInstallLocation != nil)
            assert_equal(false, File.exists?("#{lInstallLocation}/DummyBinary"))
            assert_equal(
              {
                'DummyBinary' => [
                  [ 'SystemPath', "#{@RepositoryDir}/Binaries" ]
                ]
              },
              lCMApplied
            )
          end
        end

      end

    end

  end

end