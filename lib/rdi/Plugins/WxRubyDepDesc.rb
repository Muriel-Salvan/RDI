#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  # Give the description of the RubyGems dependency
  # It has been put in this singular file because it is required by many different plugins
  #
  # Return:
  # * <em>map<Symbol,Object></em>: The description
  def self.getWxRubyDepDesc
    return RDI::Model::DependencyDescription.new('WxRuby 2.0.0').addDescription( {
      :Testers => [
        {
          :Type => 'RubyRequires',
          :Content => [ 'wx' ]
        }
      ],
      :Installers => [
        {
          :Type => 'Gem',
          :Content => 'wxruby',
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
