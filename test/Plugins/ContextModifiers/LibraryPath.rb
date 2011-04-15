#--
# Copyright (c) 2009 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Test

    module ContextModifiers

      class LibraryPath < RDITestCase

        include RDITestCase_ContextModifiers

        # Constructor
        def setup
          super
          @ContextModifierPluginName = 'LibraryPath'
        end

        # Get a test location
        #
        # Return:
        # * _Object_: Location of the given ContextModifier to be tested
        def getTestLocation
          return 'DummyLocation'
        end

      end

    end

  end

end
