#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'wx'

module RDI

  module Views

    module RDIWx

      # Dummy Class that executes code in a Wx application context
      # This is used only if there is no already an existing application
      class DummyApp < Wx::App

        # Constructor
        #
        # Parameters:
        # * *iCodeBlock* (_Proc_): The code to call
        def initialize(iCodeBlock)
          super()
          @CodeBlock = iCodeBlock
        end

        # Initialize the application
        def on_init
          @CodeBlock.call
          return false
        end

      end

      # Get the main Ex application, or nil if none
      #
      # Return:
      # * <em>Wx::App</em>: The application
      def self.getWxMainApp
        rApp = nil

        begin
          rApp = Wx.get_app
        rescue Exception
          rApp = nil
        end

        return rApp
      end

      # Ensure that some given code is run in a Wx::App context
      #
      # Parameters:
      # * _CodeBlock_: To execute in the Wx::App context
      def self.ensureWxApp(&iCodeBlock)
        if (self.getWxMainApp != nil)
          # We are already running
          iCodeBlock.call
        else
          # Call the dummy application
          DummyApp.new(iCodeBlock).main_loop
        end
      end

    end

  end

end
