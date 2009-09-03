#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Views

    class SimpleWxGUI < RDI::Model::View

      # Ask the user about missing dependencies.
      # This method will use a user interface to know what to do with missing dependencies.
      # For each dependency, choices are:
      # * Install it
      # * Ignore it
      # * Change the context to find it (select directory...)
      #
      # Parameters:
      # * *ioInstaller* (_Installer_): The RDI installer
      # * *iMissingDependencies* (<em>list<DependencyDescription></em>): The missing dependencies list
      # Return:
      # * <em>list<DependencyUserChoice></em>: The corresponding user choices
      def execute(ioInstaller, iMissingDependencies)
        # List of corresponding dependencies user choices
        # list< DependencyUserChoice >
        rDependenciesUserChoices = []

        # TODO

        return rDependenciesUserChoices
      end

    end

  end

end
