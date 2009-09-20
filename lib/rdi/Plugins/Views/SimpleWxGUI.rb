#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'rdi/Model/View'

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

        # Initialize the list
        iMissingDependencies.each do |iDepDesc|
          rDependenciesUserChoices << RDI::Model::DependencyUserChoice.new(ioInstaller, 'SimpleWxGUI', iDepDesc)
        end
        # Display the dialog
        require 'rdi/Plugins/Views/SimpleWxGUI/DependenciesLoaderDialog'
        if (defined?(showModal) == nil)
          require 'RUtilAnts/GUI'
          RUtilAnts::GUI.initializeGUI
        end
        if (defined?($rUtilAnts_URLCache) == nil)
          require 'RUtilAnts/URLCache'
          RUtilAnts::URLCache.initializeURLCache
        end
        # If an application is already running, use it
        require 'rdi/Plugins/WxCommon'
        RDI::Views::RDIWx.ensureWxApp do
          showModal(DependenciesLoaderDialog, nil, ioInstaller, rDependenciesUserChoices) do |iModalResult, iDialog|
            # Nothing to do
          end
        end

        return rDependenciesUserChoices
      end

    end

  end

end
