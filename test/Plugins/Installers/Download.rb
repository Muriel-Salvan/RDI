#--
# Copyright (c) 2009 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'tmpdir'
require 'fileutils'

module RDI

  module Test

    module Installers

      class Download < RDITestCase

        include RDITestCase_Installers

        # Constructor
        def setup
          super
          @InstallerPluginName = 'Download'
        end

        # Get a test content
        #
        # Return:
        # * _Object_: Content of the given Installer to be tested
        def getTestContent
          return "#{@RepositoryDir}/Binaries/DummyBinary"
        end

        # Verify installed content
        #
        # Parameters:
        # * *iLocation* (_Object_): Location where the content should be installed
        # Return:
        # * _Boolean_: Is the content installed in this location ?
        def verifyInstalledContent(iLocation)
          return File.exists?("#{iLocation}/DummyBinary")
        end

        # Uninstall the test content
        #
        # Parameters:
        # * *iLocation* (_Object_): Location where the content should be installed
        def uninstallTestContent(iLocation)
          FileUtils.rm("#{iLocation}/DummyBinary")
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
