#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

RubyPackager::ReleaseInfo.new.
  author(
    :name => 'Muriel Salvan',
    :email => 'muriel@x-aeon.com',
    :web_page_url => 'http://murielsalvan.users.sourceforge.net'
  ).
  project(
    :name => 'RDI: Runtime Dependencies Installer',
    :web_page_url => 'http://rdi.sourceforge.net/',
    :summary => 'Library allowing applications to ensure their dependencies at runtime with UI support.',
    :description => 'RDI is a library that gives your application the ability to install its dependencies at runtime. Perfect for plugins oriented architectures. Many kind of deps: RPMs, DEBs, .so, .dll, RubyGems... Easily extensible to new kinds.',
    :image_url => 'http://rdi.sourceforge.net/wiki/images/c/c9/Logo.png',
    :favicon_url => 'http://rdi.sourceforge.net/wiki/images/2/26/Favicon.png',
    :browse_source_url => 'http://rdi.svn.sourceforge.net/viewvc/rdi/',
    :dev_status => 'Alpha'
  ).
  add_core_files( [
    'lib/**/*'
  ] ).
  add_test_files( [
    'test/**/*'
  ] ).
  add_additional_files( [
    'README',
    'LICENSE',
    'AUTHORS',
    'Credits',
    'ChangeLog'
  ] ).
  gem(
    :gem_name => 'RDI',
    :gem_platform_class_name => 'Gem::Platform::RUBY',
    :require_path => 'lib',
    :has_rdoc => true,
    :test_file => 'test/run.rb',
    :gem_dependencies => [
      [ 'rUtilAnts', '>= 0.1' ]
    ]
  ).
  source_forge(
    :login => 'murielsalvan',
    :project_unix_name => 'rdi'
  ).
  ruby_forge(
    :project_unix_name => 'rdi'
  )
