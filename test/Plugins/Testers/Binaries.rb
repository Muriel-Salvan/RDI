#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
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
        # Return::
        # * _Object_: Content of the given Tester to be tested
        def getTestContent
          return [ 'DummyBinary' ]
        end

        # Install the test content
        def installTestContent
          setSystemExePath(getSystemExePath + [ "#{@RepositoryDir}/Binaries" ])
        end

        # Uninstall the test content
        def uninstallTestContent
          setSystemExePath(getSystemExePath - [ "#{@RepositoryDir}/Binaries" ])
        end

      end

    end

  end

end
