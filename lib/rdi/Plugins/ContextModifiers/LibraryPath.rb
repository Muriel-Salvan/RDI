#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'rdi/Model/ContextModifier'

module RDI

  module ContextModifiers

    class LibraryPath < RDI::Model::ContextModifier

      # Get the name of classes that provide selection facility for locations
      #
      # Return::
      # * _String_: The name of the LocationSelector class
      def get_location_selector_name
        return 'Directory'
      end

      # Transform a given content based on an installation environment.
      # This is called to pass some specific installation parameters to a more generic content (useful for installation directories for example)
      #
      # Parameters::
      # * *iLocation* (_Object_): Location to transform
      # * *iInstallEnv* (<em>map<Symbol,Object></em>): The installation environment that called this context modification
      # Return::
      # * _Object_: The location transformed with the installation environment
      def transform_content_with_install_env(iLocation, iInstallEnv)
        rNewLocation = iLocation

        lInstallDir = iInstallEnv[:InstallDir]
        if (lInstallDir != nil)
          rNewLocation = iLocation.gsub(/%INSTALLDIR%/, lInstallDir)
        end

        return rNewLocation
      end

      # Is a given location present in the context ?
      #
      # Parameters::
      # * *iLocation* (_Object_): Location to add
      # Return::
      # * _Boolean_: Is the location already present ?
      def is_location_in_context?(iLocation)
        # * *iLocation* (_String_): Directory
        return getSystemLibsPath.include?(iLocation)
      end

      # Add a given location to the context
      #
      # Parameters::
      # * *iLocation* (_Object_): Location to add
      def add_location_to_context(iLocation)
        # * *iLocation* (_String_): Directory
        setSystemLibsPath(getSystemLibsPath + [ iLocation ])
      end

      # Remove a given location from the context
      #
      # Parameters::
      # * *iLocation* (_Object_): Location to remove
      def remove_location_from_context(iLocation)
        # * *iLocation* (_String_): Directory
        setSystemLibsPath(getSystemLibsPath - [ iLocation ])
      end

    end

  end

end
