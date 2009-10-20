#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

{
  # Author information
  :Author => 'Muriel Salvan',
  :EMail => 'murielsalvan@users.sourceforge.net',
  :AuthorURL => 'http://murielsalvan.users.sourceforge.net',
  :SFLogin => 'murielsalvan',

  # Project information
  :Name => 'RDI: Runtime Dependencies Installer',
  :Homepage => 'http://rdi.sourceforge.net/',
  :Summary => 'Library allowing applications to ensure their dependencies at runtime with UI support.',
  :Description => 'RDI is a library that gives your application the ability to install its dependencies at runtime. Perfect for plugins oriented architectures. Many kind of deps: RPMs, DEBs, .so, .dll, RubyGems... Easily extensible to new kinds.',
  :ImageURL => 'http://rdi.sourceforge.net/wiki/images/c/c9/Logo.png',
  :FaviconURL => 'http://rdi.sourceforge.net/wiki/images/2/26/Favicon.png',
  :SFUnixName => 'rdi',
  :RubyForgeProjectName => 'rdi',
  :SVNBrowseURL => 'http://rdi.svn.sourceforge.net/viewvc/rdi/',
  :DevStatus => 'Alpha',

  # Gem information
  :GemName => 'RDI',
  :GemPlatformClassName => 'Gem::Platform::RUBY',
  :Files => Dir.glob('{lib,test}/**/*').delete_if do |iFileName|
    ((iFileName == 'CVS') or
     (iFileName == '.svn'))
  end,
  :RequirePath => 'lib',
  :HasRDoc => true,
  :ExtraRDocFiles => [
    'README',
    'TODO',
    'ChangeLog',
    'LICENSE',
    'AUTHORS',
    'Credits'
  ],
  :TestFile => 'test/run.rb',
  :GemDependencies => [
    [ 'rUtilAnts', '>= 0.1' ]
  ]
}
