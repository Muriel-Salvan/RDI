#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'rubygems'

# Return the Gem specification
#
# Return::
# * <em>Gem::Specification</em>: The Gem specification
Gem::Specification.new do |iSpec|
  iSpec.name = 'DummyGem'
  iSpec.version = '0.0.1.20090828'
  iSpec.author = 'Muriel Salvan'
  iSpec.email = 'muriel@x-aeon.com'
  iSpec.homepage = 'http://rdi.sourceforge.net/'
  iSpec.platform = Gem::Platform::RUBY
  iSpec.summary = 'A dummy Gem.'
  iSpec.description = 'This Gem is used to test RubyGems functionnality only.'
  iSpec.files = [ 'lib/DummyGemMain.rb' ]
  iSpec.require_path = 'lib'
end
