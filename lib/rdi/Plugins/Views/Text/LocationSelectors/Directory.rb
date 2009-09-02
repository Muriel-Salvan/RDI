#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Views

    module LocationSelectors

      module Text

        class Directory

          # Give user the choice of a new location
          #
          # Return:
          # * _Object_: A location, or nil if none selected
          def getNewLocation
            rLocation = nil

            puts 'Please enter a directory name (Ctrl-C to cancel):'
            $stdout.write('-Directory-> ')
            begin
              rLocation = $stdin.gets
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