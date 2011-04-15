#--
# Copyright (c) 2009 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Model

    class Installer

      # The Installer
      #   Installer
      attr_accessor :Installer

      # The list of possible destinations, and the directories they point to
      #   map< Integer, String >
      attr_accessor :PossibleDestinations

    end

  end

end