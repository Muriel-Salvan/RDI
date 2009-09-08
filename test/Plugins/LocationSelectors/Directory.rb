#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'Plugins/WxEnv'

module RDI

  module Test

    module LocationSelectors

      class Directory < RDITestCase

        include RDITestCase_LocationSelectors

        include RDI::Test::RDIWx

        # Constructor
        def setup
          super
          @LocationSelectorPluginName = 'Directory'
        end

        # Install dependencies
        def installDep_SimpleWxGUI
          installTestWxEnv
        end

      end

    end

  end

end
