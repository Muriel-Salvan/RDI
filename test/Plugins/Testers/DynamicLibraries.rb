#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
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
        # Return::
        # * _Object_: Content of the given Tester to be tested
        def getTestContent
          return [ 'DummyLibrary.so' ]
        end

        # Install the test content
        def installTestContent
          setSystemLibsPath(getSystemLibsPath + [ "#{@RepositoryDir}/Libraries" ])
        end

        # Uninstall the test content
        def uninstallTestContent
          setSystemLibsPath(getSystemLibsPath - [ "#{@RepositoryDir}/Libraries" ])
        end

      end

    end

  end

end
