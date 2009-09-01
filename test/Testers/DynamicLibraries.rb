#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Test

    module Testers

      class DynamicLibraries < RDITestCase

        include RDITestCase_Testers

        # Constructor
        def setup
          super
          @TesterPluginName = 'DynamicLibraries'
        end

        # Get a test content
        #
        # Return:
        # * _Object_: Content of the given Tester to be tested
        def getTestContent
          return [ 'DummyLibrary.so' ]
        end

        # Install the test content
        def installTestContent
          $CT_Platform_Info.setSystemLibsPath($CT_Platform_Info.getSystemLibsPath + [ "#{@RepositoryDir}/Libraries" ])
        end

        # Uninstall the test content
        def uninstallTestContent
          $CT_Platform_Info.setSystemLibsPath($CT_Platform_Info.getSystemLibsPath - [ "#{@RepositoryDir}/Libraries" ])
        end

      end

    end

  end

end
