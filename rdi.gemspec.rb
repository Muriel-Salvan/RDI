# RDI Gem specification
#
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'rubygems'

# Return the Gem specification
#
# Return:
# * <em>Gem::Specification</em>: The Gem specification
Gem::Specification.new do |iSpec|
  iSpec.name = 'RDI'
  iSpec.version = '0.0.1.20090910'
  iSpec.author = 'Muriel Salvan'
  iSpec.email = 'murielsalvan@users.sourceforge.net'
  iSpec.homepage = 'http://rdi.sourceforge.net/'
  iSpec.platform = Gem::Platform::RUBY
  iSpec.summary = 'RDI: Runtime Dependencies Installer.'
  iSpec.description = 'RDI gives an application the ability to describe and install its dependencies at runtime, without restart.'
  iSpec.files = Dir.glob('{test,lib}/**/*').delete_if do |iFileName|
    ((iFileName == 'CVS') or
     (iFileName == '.svn'))
  end
  iSpec.require_path = 'lib'
  iSpec.test_file = 'test/run.rb'
  iSpec.has_rdoc = true
  iSpec.extra_rdoc_files = ['README',
                            'TODO',
                            'ChangeLog',
                            'LICENSE',
                            'AUTHORS',
                            'Credits']
end
