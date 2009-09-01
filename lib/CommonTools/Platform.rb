#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module CommonTools

  module Platform

    # OS constants
    OS_WINDOWS = 0
    OS_LINUX = 1

    # Initialize the platform info
    def self.initializePlatform
      # Require the platform info
      begin
        require "CommonTools/Platforms/#{RUBY_PLATFORM}/PlatformInfo.rb"
      rescue Exception
        logBug "Current platform #{RUBY_PLATFORM} is not supported."
        raise RuntimeError, "Current platform #{RUBY_PLATFORM} is not supported."
      end
      # Create the corresponding object
      $CT_Platform_Info = PlatformInfo.new
      Object.module_eval('include CommonTools::Platform')
    end

  end

end