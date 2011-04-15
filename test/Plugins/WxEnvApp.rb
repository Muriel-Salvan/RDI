#--
# Copyright (c) 2009 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Test

    module RDIWx

      # The application that will run tests
      class TestApp < Wx::App

        # Exit flag
        #   Boolean
        attr_accessor :Exit

        # Set up some code to execute in this thread
        #   Proc
        attr_accessor :Code

        # Ready flag
        #   Boolean
        attr_reader :Ready

        # Code result
        #   Object
        attr_reader :CodeResult

        # Constructor
        def initialize
          super
          @Exit = false
          @Ready = false
          @Code = nil
          @ExecutingCode = false
          @CodeResult = nil
        end

        # Init
        def on_init
          # Make sure other threads will be called during looping.
          # We have to use this workaround, as WxRuby's threads are different than Ruby's threads
          lThreadsTimer = Wx::Timer.new(self, 42)
          evt_timer(42) do
            @Ready = true
            Thread.pass
            if (@Exit)
              # Stop the timer
              lThreadsTimer.stop
              # Close application
              exit_main_loop
            elsif (@Code != nil)
              if (!@ExecutingCode)
                @ExecutingCode = true
                # Execute the client code
                @CodeResult = @Code.call
                @Code = nil
                @ExecutingCode = false
              end
            end
          end
          # Trigger every 100 ms
          lThreadsTimer.start(100)
          return true
        end

      end
      
    end

  end

end
