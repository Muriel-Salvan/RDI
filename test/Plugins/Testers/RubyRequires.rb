#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Test

    module Testers

      class RubyRequires < RDITestCase

        include RDITestCase_Testers

        # Constructor
        def setup
          super
          @TesterPluginName = 'RubyRequires'
        end

        # Get a test content
        #
        # Return:
        # * _Object_: Content of the given Tester to be tested
        def getTestContent
          return [ 'DummyRubyLib.rb' ]
        end

        # Install the test content
        def installTestContent
          $LOAD_PATH << "#{@RepositoryDir}/RubyLibraries"
        end

        # Uninstall the test content
        def uninstallTestContent
          $LOAD_PATH.delete_if do |iDir|
            (iDir == "#{@RepositoryDir}/RubyLibraries")
          end
        end

      end

    end

  end

end
