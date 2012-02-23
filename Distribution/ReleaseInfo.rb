#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

RubyPackager::ReleaseInfo.new.
  author(
    :Name => 'Muriel Salvan',
    :EMail => 'muriel@x-aeon.com',
    :WebPageURL => 'http://murielsalvan.users.sourceforge.net'
  ).
  project(
    :Name => 'RDI: Runtime Dependencies Installer',
    :WebPageURL => 'http://rdi.sourceforge.net/',
    :Summary => 'Library allowing applications to ensure their dependencies at runtime with UI support.',
    :Description => 'RDI is a library that gives your application the ability to install its dependencies at runtime. Perfect for plugins oriented architectures. Many kind of deps: RPMs, DEBs, .so, .dll, RubyGems... Easily extensible to new kinds.',
    :ImageURL => 'http://rdi.sourceforge.net/wiki/images/c/c9/Logo.png',
    :FaviconURL => 'http://rdi.sourceforge.net/wiki/images/2/26/Favicon.png',
    :SVNBrowseURL => 'http://rdi.svn.sourceforge.net/viewvc/rdi/',
    :DevStatus => 'Alpha'
  ).
  addCoreFiles( [
    'lib/**/*'
  ] ).
  addTestFiles( [
    'test/**/*'
  ] ).
  addAdditionalFiles( [
    'README',
    'LICENSE',
    'AUTHORS',
    'Credits',
    'ChangeLog'
  ] ).
  gem(
    :GemName => 'RDI',
    :GemPlatformClassName => 'Gem::Platform::RUBY',
    :RequirePath => 'lib',
    :HasRDoc => true,
    :TestFile => 'test/run.rb',
    :GemDependencies => [
      [ 'rUtilAnts', '>= 0.1' ]
    ]
  ).
  sourceForge(
    :Login => 'murielsalvan',
    :ProjectUnixName => 'rdi'
  ).
  rubyForge(
    :ProjectUnixName => 'rdi'
  )
