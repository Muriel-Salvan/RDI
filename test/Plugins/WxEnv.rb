#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Test

    module RDIWx

      # Setup the Wx environment. Here are the constraints to respect:
      # * It is impossible to call main_loop several times (the second times, Wx::Bitmap objects can't recognize image handlers anymore)
      # * It is impossible to unload wx library and reload it (the .so library does not reload constants like Wxruby2::WXWIDGETS_MAJOR_VERSION)
      # * It is impossible to fork the process (does not work on Windows)
      # Therefore the solution found is to use Threads:
      # * Create 1 thread that will run the main_loop
      # * Make the on_init method process a kind of events loop that will be fed by test usecases
      def self.installTestWxEnv
        lWxRubyInstallLocation = "#{Dir.tmpdir}/RDITest/WxRubyTestInstall"
        if (defined?($RDI_Test_WxApp) == nil)
          require 'rdi/Plugins/WxRubyDepDesc'
          RDI::Installer.new(lWxRubyInstallLocation).ensureDependencies(
            [ ::RDI::getWxRubyDepDesc ],
            {
              :AutoInstall => DEST_OTHER,
              :AutoInstallLocation => lWxRubyInstallLocation,
              :PreferredViews => [ 'Text' ]
            } )
          # TODO: Re-enable it when WxRuby will be more stable
          GC.disable
          require 'wx'
          setGUIForDialogs(RUtilAnts::Logging::Logger::GUI_WX)
          # Create the main application
          require 'Plugins/WxEnvApp'
          $RDI_Test_WxApp = TestApp.new
          # Create the thread that will run the application
          Thread.new do
            $RDI_Test_WxApp.main_loop
          end
          # Wait for the thread to be ready
          while (!$RDI_Test_WxApp.Ready)
            sleep(1)
          end
        else
          # It is already loaded.
          # Add the direcotry to the Gem path.
          RDI::Installer.new(lWxRubyInstallLocation).accessPlugin('ContextModifiers', 'GemPath') do |ioPlugin|
            ioPlugin.addLocationToContext(lWxRubyInstallLocation)
          end
        end
      end

    end

  end

end
