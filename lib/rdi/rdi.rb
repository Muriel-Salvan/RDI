#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'CommonTools/Logging.rb'
CommonTools::Logging::initializeLogging("#{File.dirname(__FILE__)}/../lib", 'http://sourceforge.net/tracker/?group_id=274498&atid=1166448')
require 'CommonTools/URLAccess.rb'
CommonTools::URLAccess::initializeURLAccess
require 'CommonTools/Platform.rb'
CommonTools::Platform::initializePlatform

require 'rdi/Model/DependencyDescription.rb'
require 'rdi/Model/DependencyUserChoice.rb'
require 'rdi/Model/Installer.rb'
require 'rdi/Model/ContextModifier.rb'
require 'rdi/Model/Tester.rb'
require 'rdi/Model/View.rb'
require 'rdi/Model/LocationSelector.rb'
require 'rdi/Installer.rb'
