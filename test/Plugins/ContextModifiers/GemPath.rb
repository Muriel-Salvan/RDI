#--
# Copyright (c) 2009 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Test

    module ContextModifiers

      class GemPath < RDITestCase

        include RDITestCase_ContextModifiers

        # Constructor
        def setup
          super
          @ContextModifierPluginName = 'GemPath'
          # Install Gems if needed
          require 'rdi/Plugins/RubyGemsDepDesc'
          setupAppDir do
            @Installer.ensureDependencies( [
              # RubyGems
              RDI::getRubyGemsDepDesc
            ] )
          end
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
