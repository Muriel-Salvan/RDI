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
