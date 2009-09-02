#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module ContextModifiers

    class SystemPath < RDI::Model::ContextModifier

      # Get the name of classes that provide selection facility for locations
      #
      # Return:
      # * _String_: The name of the LocationSelector class
      def getLocationSelectorName
        return 'Directory'
      end

      # Transform a given content based on an installation environment.
      # This is called to pass some specific installation parameters to a more generic content (useful for installation directories for example)
      #
      # Parameters:
      # * *iLocation* (_Object_): Location to transform
      # * *iInstallEnv* (<em>map<Symbol,Object></em>): The installation environment that called this context modification
      # Return:
      # * _Object_: The location transformed with the installation environment
      def transformContentWithInstallEnv(iLocation, iInstallEnv)
        rNewLocation = iLocation

        lInstallDir = iInstallEnv[:InstallDir]
        if (lInstallDir != nil)
          rNewLocation = iLocation.gsub(/%INSTALLDIR%/, lInstallDir)
        end

        return rNewLocation
      end

      # Is a given location present in the context ?
      #
      # Parameters:
      # * *iLocation* (_Object_): Location to add
      # Return:
      # * _Boolean_: Is the location already present ?
      def isLocationInContext?(iLocation)
        # * *iLocation* (_String_): Directory
        return $CT_Platform_Info.getSystemExePath.include?(iLocation)
      end

      # Add a given location to the context
      #
      # Parameters:
      # * *iLocation* (_Object_): Location to add
      def addLocationToContext(iLocation)
        # * *iLocation* (_String_): Directory
        $CT_Platform_Info.setSystemExePath($CT_Platform_Info.getSystemExePath + [ iLocation ])
      end

      # Remove a given location from the context
      #
      # Parameters:
      # * *iLocation* (_Object_): Location to remove
      def removeLocationFromContext(iLocation)
        # * *iLocation* (_String_): Directory
        $CT_Platform_Info.setSystemExePath($CT_Platform_Info.getSystemExePath - [ iLocation ])
      end

    end

  end

end
