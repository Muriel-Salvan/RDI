#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Test

    module Testers

      class Binaries < RDITestCase

        include RDITestCase_Testers

        # Constructor
        def setup
          super
          @TesterPluginName = 'Binaries'
        end

        # Get a test content
        #
        # Return:
        # * _Object_: Content of the given Tester to be tested
        def getTestContent
          return [ 'DummyBinary' ]
        end

        # Install the test content
        def installTestContent
          $rUtilAnts_Platform_Info.setSystemExePath($rUtilAnts_Platform_Info.getSystemExePath + [ "#{@RepositoryDir}/Binaries" ])
        end

        # Uninstall the test content
        def uninstallTestContent
          $rUtilAnts_Platform_Info.setSystemExePath($rUtilAnts_Platform_Info.getSystemExePath - [ "#{@RepositoryDir}/Binaries" ])
        end

      end

    end

  end

end
