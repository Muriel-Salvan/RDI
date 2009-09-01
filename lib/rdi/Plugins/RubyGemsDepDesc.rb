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
  def self.getRubyGemsDepDesc
    return RDI::Model::DependencyDescription.new('RubyGems 1.3.5').addDescription( {
      :Testers => [
        {
          :Type => 'RubyRequires',
          :Content => [ 'rubygems' ]
        }
      ],
      :Installers => [
        {
          :Type => 'DownloadAndInstall',
          :Content => [
            'http://rubyforge.org/frs/download.php/60719/rubygems-1.3.5.zip',
            Proc.new do |iInstallLocation|
              next system("ruby -w setup.rb --destdir #{iInstallLocation}")
            end
          ],
          :ContextModifiers => [
            {
              :Type => 'RubyLoadPath',
              :Content => "%INSTALLDIR%/lib/ruby/site_ruby/#{Config::CONFIG['ruby_version']}"
            }
          ]
        }
      ]
    } )
  end

end
