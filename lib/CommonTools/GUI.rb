#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

# WxRuby has to be loaded correctly in the environment before requiring this file

module CommonTools

  module GUI

    # Initialize the GUI methods in the Kernel namespace
    def self.initializeGUI
      Object.module_eval('include CommonTools::GUI')
    end

    # Display a dialog in modal mode, ensuring it is destroyed afterwards.
    #
    # Parameters:
    # * *iDialogClass* (_class_): Class of the dialog to display
    # * *iParentWindow* (<em>Wx::Window</em>): Parent window
    # * *iParameters* (...): List of parameters to give the constructor
    # * *CodeBlock*: The code called once the dialog has been displayed and modally closed
    # ** *iModalResult* (_Integer_): Modal result
    # ** *iDialog* (<em>Wx::Dialog</em>): The dialog
    def showModal(iDialogClass, iParentWindow, *iParameters)
      lDialog = iDialogClass.new(iParentWindow, *iParameters)
      lDialog.centre(Wx::CENTRE_ON_SCREEN|Wx::BOTH)
      lModalResult = lDialog.show_modal
      yield(lModalResult, lDialog)
      # If we destroy the window, we get SegFaults during execution when mouse hovers some toolbar icons and moves (except if we disable GC: in this case it works perfectly fine, but consumes tons of memory).
      # If we don't destroy, we get ObjectPreviouslyDeleted exceptions on exit.
      # So the least harmful is to destroy it without GC.
      # TODO: Find a good solution
      lDialog.destroy
    end

    # Get a bitmap from a given URL
    #
    # Parameters:
    # * *iURL* (_String_): Bitmap's URL
    # Return:
    # * <em>Wx::Bitmap</em>: The corresponding bitmap, or nil in case of failure
    def getBitmapFromURL(iURL)
      # First, test if we have the files cache
      getURLContent(iURL, {:LocalFileAccess => true}) do |iLocalFileName|
        rContent = nil
        rError = nil
        begin
          rContent = Wx::Bitmap.new(iLocalFileName)
        rescue Exception
          rError = $!
          rContent = nil
        end
        next rContent, rError
      end
    end

  end

end
