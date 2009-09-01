#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'fileutils'
require 'tmpdir'

module RDI

  module Test

    module Basic

      class BasicFlows < RDITestCase

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

        # Test that we can test for a missing dependency
        def testMissingDep
          setupAppDir do
            # Ask the installer to check for this description
            assert_equal(false, @Installer.testDependency(getSimpleDesc))
          end
        end

        # Test that we install dependencies correctly
        def testInstallDep_Local
          setupAppDir do
            # Ask the installer to install this dependency in the local directory
            assert_equal(nil, @Installer.installDependency(getSimpleDesc, 0, @Installer.AppRootDir))
            assert(File.exists?("#{@Installer.AppRootDir}/DummyBinary"))
          end
        end

        # Test that we detect installed dependencies correctly
        def testExistingDep
          setupAppDir do
            # Ask the installer to install this dependency in the local directory
            lDesc = getSimpleDesc
            @Installer.installDependency(lDesc, 0, @Installer.AppRootDir)
            assert_equal(true, @Installer.testDependency(lDesc))
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
            iInstallerName, iInstallerContent = lDesc.Installers[0]
            lInstallLocation = nil
            # Use a private method for regression only
            @Installer.send(:accessPlugin, 'Installers', iInstallerName) do |ioPlugin|
              ioPlugin.PossibleDestinations.each do |iDestInfo|
                iDestFlavour, iLocation = iDestInfo
                if (iDestFlavour == DEST_LOCAL)
                  lInstallLocation = iLocation
                  break
                end
              end
            end
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
            @Installer.send(:accessPlugin, 'Testers', 'Binaries') do |iPlugin|
              assert_equal(true, iPlugin.isContentResolved?('DummyBinary'))
            end
            # 2. The dependency should not have been installed
            iInstallerName, iInstallerContent = lDesc.Installers[0]
            lInstallLocation = nil
            # Use a private method for regression only
            @Installer.send(:accessPlugin, 'Installers', iInstallerName) do |ioPlugin|
              ioPlugin.PossibleDestinations.each do |iDestInfo|
                iDestFlavour, iLocation = iDestInfo
                if (iDestFlavour == DEST_LOCAL)
                  lInstallLocation = iLocation
                  break
                end
              end
            end
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