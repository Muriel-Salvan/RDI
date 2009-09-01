#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'tmpdir'
require 'fileutils'

module RDI

  module Test

    module Installers

      class Gem < RDITestCase

        include RDITestCase_Installers

        # Constructor
        def setup
          super
          @InstallerPluginName = 'Gem'
          # Install Gems if needed
          require 'rdi/Plugins/RubyGemsDepDesc.rb'
          setupAppDir do
            @Installer.ensureDependencies( [
              # RubyGems
              RDI::getRubyGemsDepDesc
            ] )
          end
        end

        # Get the other location's chooser
        #
        # Return:
        # * _Object_: The other location chooser
        def getOtherLocationChooser
          return 'Directory'
        end

        # Get a test content
        #
        # Return:
        # * _Object_: Content of the given Installer to be tested
        def getTestContent
          return "#{@RepositoryDir}/RubyGems/DummyGem-0.0.1.20090828.gem"
        end

        # Verify installed content
        #
        # Parameters:
        # * *iLocation* (_Object_): Location where the content should be installed
        # Return:
        # * _Boolean_: Is the content installed in this location ?
        def verifyInstalledContent(iLocation)
          return (
            (File.exists?("#{iLocation}/gems/DummyGem-0.0.1.20090828/lib/DummyGemMain.rb")) and
            (File.exists?("#{iLocation}/specifications/DummyGem-0.0.1.20090828.gemspec")) and
            (File.exists?("#{iLocation}/cache/DummyGem-0.0.1.20090828.gem"))
          )
        end

        # Uninstall the test content
        #
        # Parameters:
        # * *iLocation* (_Object_): Location where the content should be installed
        def uninstallTestContent(iLocation)
          FileUtils.rm_rf("#{iLocation}/gems/DummyGem-0.0.1.20090828")
          FileUtils.rm("#{iLocation}/specifications/DummyGem-0.0.1.20090828.gemspec")
          FileUtils.rm("#{iLocation}/cache/DummyGem-0.0.1.20090828.gem")
        end

        # Get a location to be used as the "other" one, chosen by the user
        #
        # Return:
        # * _Object_: The other location
        def getOtherLocation
          return "#{Dir.tmpdir}/RDITest"
        end

      end

    end

  end

end
