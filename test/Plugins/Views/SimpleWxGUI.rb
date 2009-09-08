#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'Plugins/WxEnv'

module RDI

  module Test

    module Views

      class SimpleWxGUI < RDITestCase

        include RDITestCase_Views

        include RDI::Test::RDIWx

        # Constructor
        def setup
          super
          @ViewPluginName = 'SimpleWxGUI'
          installTestWxEnv
        end

      end

    end

  end

end
