#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
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

        # Ready flag
        #   Boolean
        attr_reader :Ready

        # Constructor
        def initialize
          super
          @Exit = false
          @Ready = false
        end

        # Init
        def on_init
          # Make sure other threads will be called during looping.
          # We have to use this workaround, as WxRuby's threads are different than Ruby's threads
          lThreadsTimer = Wx::Timer.new(self, 42)
          evt_timer(42) do
            Thread.pass
          end
          # Trigger every 100 ms
          lThreadsTimer.start(100)
          while (!@Exit)
            @Ready = true
            sleep(1)
          end
          return false
        end

      end
      
    end

  end

end
