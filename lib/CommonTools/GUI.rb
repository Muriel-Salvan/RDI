#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

# WxRuby has to be loaded correctly in the environment before requiring this file

module CommonTools

  module GUI

    # The class that assigns dynamically images to a given TreeCtrl items
    class ImageListManager

      # Constructor
      #
      # Parameters:
      # * *ioImageList* (<em>Wx::ImageList</em>): The image list this manager will handle
      # * *iWidth* (_Integer_): The images width
      # * *iHeight* (_Integer_): The images height
      def initialize(ioImageList, iWidth, iHeight)
        @ImageList = ioImageList
        # TODO (WxRuby): Get the size directly from ioImageList (get_size does not work)
        @Width = iWidth
        @Height = iHeight
        # The internal map of image IDs => indexes
        # map< Object, Integer >
        @Id2Idx = {}
      end

      # Get the image index for a given image ID
      #
      # Parameters:
      # * *iID* (_Object_): Id of the image
      # * *CodeBlock*: The code that will be called if the image ID is unknown. This code has to return a Wx::Bitmap object, representing the bitmap for the given image ID.
      def getImageIndex(iID)
        if (@Id2Idx[iID] == nil)
          # Bitmap unknown.
          # First create it.
          lBitmap = yield
          # Then check if we need to resize it
          lBitmap = getResizedBitmap(lBitmap, @Width, @Height)
          # Then add it to the image list, and register it
          @Id2Idx[iID] = @ImageList.add(lBitmap)
        end

        return @Id2Idx[iID]
      end

    end

    # Initialize the GUI methods in the Kernel namespace
    def self.initializeGUI
      Object.module_eval('include CommonTools::GUI')
    end

    # Get a bitmap resized to a given size if it differs from it
    #
    # Parameters:
    # * *iBitmap* (<em>Wx::Bitmap</em>): The original bitmap
    # * *iWidth* (_Integer_): The width of the resized bitmap
    # * *iHeight* (_Integer_): The height of the resized bitmap
    # Return:
    # * <em>Wx::Bitmap</em>: The resized bitmap (can be the same object as iBitmap)
    def getResizedBitmap(iBitmap, iWidth, iHeight)
      rResizedBitmap = iBitmap

      if ((iBitmap.width != iWidth) or
          (iBitmap.height != iHeight))
        rResizedBitmap = Wx::Bitmap.new(iBitmap.convert_to_image.scale(iWidth, iHeight))
      end

      return rResizedBitmap
    end

    # Display a dialog in modal mode, ensuring it is destroyed afterwards.
    #
    # Parameters:
    # * *iDialogClass* (_class_): Class of the dialog to display
    # * *iParentWindow* (<em>Wx::Window</em>): Parent window (can be nil)
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
      rBitmap = nil

      # First, test if we have the files cache
      rBitmap, lError = getURLContent(iURL, {:LocalFileAccess => true}) do |iLocalFileName|
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

      return rBitmap
    end

  end

end
