#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Views

    module LocationSelectors

      module SimpleWxGUI

        class Directory < RDI::Model::LocationSelector

          # Give user the choice of a new location
          #
          # Return:
          # * _Object_: A location, or nil if none selected
          def getNewLocation
            rLocation = nil

            showModal(Wx::DirDialog, nil) do |iModalResult, iDialog|
              if (iModalResult == Wx::ID_OK)
                rLocation = iDialog.path
              end
            end

            return rLocation
          end

        end

      end

    end

  end

end
