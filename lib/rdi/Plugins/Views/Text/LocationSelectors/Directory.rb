#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'rdi/Model/LocationSelector'

module RDI

  module Views

    module LocationSelectors

      module Text

        class Directory < RDI::Model::LocationSelector

          # Give user the choice of a new location
          #
          # Return::
          # * _Object_: A location, or nil if none selected
          def getNewLocation
            rLocation = nil

            puts 'Please enter a directory name (Ctrl-C to cancel):'
            $stdout.write('-Directory-> ')
            begin
              rLocation = $stdin.gets.chomp
            rescue Exception
              rLocation = nil
            end

            return rLocation
          end

        end

      end

    end

  end

end
