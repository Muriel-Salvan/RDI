#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Views

    class SimpleWxGUI < RDI::Model::View

      # Class for the application
      class TestApp < Wx::App

        # Constructor
        #
        # Parameters:
        # * *ioInstaller* (_Installer_): The installer
        # * *ioDependenciesUserChoices* (<em>list<DependencyUserChoice></em>): The list of dependency user choices
        def initialize(ioInstaller, ioDependenciesUserChoices)
          super()
          @Installer, @DependenciesUserChoices = ioInstaller, ioDependenciesUserChoices
        end

        # Initialize the application
        def on_init
          showModal(DependenciesLoaderDialog, nil, @Installer, @DependenciesUserChoices) do |iModalResult, iDialog|
            # Nothing to do
          end
        end

      end

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
        require 'CommonTools/GUI'
        CommonTools::GUI.initializeGUI
        require 'CommonTools/URLCache'
        CommonTools::URLCache.initializeURLCache
        # Call application
        TestApp.new(ioInstaller, rDependenciesUserChoices).main_loop

        return rDependenciesUserChoices
      end

    end

  end

end
