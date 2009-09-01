#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module ContextModifiers

    class GemPath

      # To get the complete list of loadable paths through RubyGems:
      # > Gem.all_loaded_paths
      # C:/Program Files/ruby/lib/ruby/gems/1.8/gems/win32-process-0.5.1/lib
      # C:/Program Files/ruby/lib/ruby/gems/1.8/gems/win32-sapi-0.1.3-mswin32/lib
      # C:/Program Files/ruby/lib/ruby/gems/1.8/gems/win32-sound-0.4.0/lib
      # C:/Program Files/ruby/lib/ruby/gems/1.8/gems/windows-pr-0.5.3/lib
      # E:/Documents and Settings/Muriel Salvan/toto/gems/crated-0.2.1/lib
      #
      # Find if a file is accessible
      # > Gem.find_files('crate')
      #
      # To add a new Gems repository:
      # > Gem.path << 'E:/Documents and Settings/Muriel Salvan/toto'
      #
      # To remove a Gems repository:
      # > Gem.clear_paths
      # Then read others than the one we want to remove

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

        lInstallDir = iInstallEnv[:InstallLocation]
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
        return Gem.path.include?(iLocation)
      end

      # Add a given location to the context
      #
      # Parameters:
      # * *iLocation* (_Object_): Location to add
      def addLocationToContext(iLocation)
        # * *iLocation* (_String_): Directory
        Gem.path << iLocation
      end

      # Remove a given location from the context
      #
      # Parameters:
      # * *iLocation* (_Object_): Location to remove
      def removeLocationFromContext(iLocation)
        # * *iLocation* (_String_): Directory
        lLastPaths = Gem.path.clone
        Gem.clear_paths
        lLastPaths.each do |iLastDir|
          if ((iLastDir != iLocation) and
              (!Gem.path.include?(iLastDir)))
            Gem.path << iLastDir
          end
        end
      end

    end

  end

end
