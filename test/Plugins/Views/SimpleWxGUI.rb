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
          require 'rdi/Plugins/WxRubyDepDesc.rb'
          RDI::Installer.new(@RepositoryDir).ensureDependencies(
            [ ::RDI::getWxRubyDepDesc ],
            {
              :AutoInstall => DEST_TEMP,
              :PreferredViews => [ 'Text' ]
            } )
          # TODO: Reenable it when WxRuby will be more stable
          GC.disable
          require 'wx'
        end

      end

    end

  end

end
