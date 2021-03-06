#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'rdi/Model/ProgressView'

module RDI

  module ProgressViews

    class Text < RDI::Model::ProgressView

      # Proxy class that will route calls made by RDI to stdout
      class TextProgressDialog

        # Constructor
        def initialize
          @Range = 0
          @Value = 0
        end

        # Set the title of the operation
        #
        # Parameters::
        # * *iTitle* (_String_): Title of the operation
        def set_title(iTitle)
          puts "==== #{iTitle} ... ===="
        end

        # Set the range
        #
        # Parameters::
        # * *iRange* (_Integer_): Range to set
        def set_range(iRange)
          @Range = iRange
        end

        # Increment the value
        #
        # Parameters::
        # * *iIncrement* (_Integer_): The increment [optional = 1]
        def inc_value(iIncrement = 1)
          @Value += iIncrement
          # Display the value
          if (@Range == 0)
            puts '...'
          else
            puts "#{(@Value*100)/@Range} %"
          end
        end

      end

      # Setup the progress and call the client code to execute inside
      #
      # Parameters::
      # * _CodeBlock_: The code to execute during this progression:
      #   * *ioProgressView* (_Object_): The progress view that will receive notifications of progression (can be nil if no progression view available)
      def setup_progress
        yield(TextProgressDialog.new)
      end

    end

  end

end