#--
# Copyright (c) 2009 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  # Give the description of the RubyGems dependency
  # It has been put in this singular file because it is required by many different plugins
  #
  # Return:
  # * <em>map<Symbol,Object></em>: The description
  def self.getWxRubyDepDesc
    lWxRubyGemName = 'wxruby'
    if (RUBY_VERSION.to_f >= 1.9)
      lWxRubyGemName = 'wxruby-ruby19'
    end
    return RDI::Model::DependencyDescription.new('WxRuby').addDescription( {
      :Testers => [
        {
          :Type => 'RubyRequires',
          :Content => [ 'wx' ]
        }
      ],
      :Installers => [
        {
          :Type => 'Gem',
          :Content => lWxRubyGemName,
          :ContextModifiers => [
            {
              :Type => 'GemPath',
              :Content => '%INSTALLDIR%'
            }
          ]
        }
      ]
    } )
  end

end
