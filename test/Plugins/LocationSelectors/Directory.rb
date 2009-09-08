#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Test

    module LocationSelectors

      class Directory < RDITestCase

        include RDITestCase_LocationSelectors

        # Constructor
        def setup
          super
          @LocationSelectorPluginName = 'Directory'
        end

        # Install dependencies
        def installDep_SimpleWxGUI
          require 'Plugins/WxEnv'
          RDI::Test::RDIWx.installTestWxEnv
        end

      end

    end

  end

end
