#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'rdi/Model/ProgressView'

module RDI

  module ProgressViews

    class SimpleWxGUI < RDI::Model::ProgressView

      # Proxy class that will route calls made by RDI to the corresponding RUtilAnts::GUI::TextProgressDialog
      class SimpleWxGUIProgressDialog < RUtilAnts::GUI::TextProgressDialog

        # Set the title of the operation
        #
        # Parameters:
        # * *iTitle* (_String_): Title of the operation
        def setTitle(iTitle)
          setText(iTitle)
        end

        # Set the range
        #
        # Parameters:
        # * *iRange* (_Integer_): Range to set
        def setRange(iRange)
          super
        end

        # Increment the value
        #
        # Parameters:
        # * *iIncrement* (_Integer_): The increment [optional = 1]
        def incValue(iIncrement = 1)
          super
        end

      end

      # Setup the progress and call the client code to execute inside
      #
      # Parameters:
      # * _CodeBlock_: The code to execute during this progression:
      # ** *ioProgressView* (_Object_): The progress view that will receive notifications of progression (can be nil if no progression view available)
      def setupProgress(&iCodeToExecute)
        showModal(SimpleWxGUIProgressDialog, Wx.get_app.get_top_window, iCodeToExecute, '') do |iModalResult, iDialog|
          # Nothing to do
        end
      end

    end

  end

end
