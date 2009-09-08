#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Test

    module Views

      class SimpleWxGUI < RDITestCase

        include RDITestCase_Views

        # Constructor
        def setup
          super
          @ViewPluginName = 'SimpleWxGUI'
          require 'Plugins/WxEnv'
          RDI::Test::RDIWx.installTestWxEnv
        end

      end

    end

  end

end
