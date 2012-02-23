#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
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
          RDI::Installer.new(lWxRubyInstallLocation).ensure_dependencies(
            [ ::RDI::getWxRubyDepDesc ],
            {
              :auto_install => DEST_OTHER,
              :auto_install_location => lWxRubyInstallLocation,
              :preferred_views => [ 'Text' ]
            } )
          # TODO (wxRuby): Re-enable it when WxRuby will be more stable
          GC.disable
          require 'wx'
          set_gui_for_dialogs(RUtilAnts::Logging::GUI_WX)
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
          # Add the directory to the Gem path.
          RDI::Installer.new(lWxRubyInstallLocation).access_plugin('ContextModifiers', 'GemPath') do |ioPlugin|
            ioPlugin.add_location_to_context(lWxRubyInstallLocation)
          end
        end
      end

      # Execute some code in the same thread that executes the main Wx loop.
      # This should be used to execute any code dealing with the GUI.
      #
      # Parameters::
      # * *&iClientCode* (_CodeBlock_): Client code to be called by the main loop thread:
      #   * _Object_: Return value that will be transferred as the return value of this function
      # Return::
      # * _Object_: The return value of the client code
      def self.executeInWxEnv(&iClientCode)
        rResult = nil

        $RDI_Test_WxApp.Code = iClientCode
        while ($RDI_Test_WxApp.Code != nil)
          # We wait
          sleep(500)
        end
        rResult = $RDI_Test_WxApp.CodeResult

        return rResult
      end

    end

  end

end
