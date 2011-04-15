#--
# Copyright (c) 2009 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Model

    # Class used to store user decisions associated to a dependency
    class DependencyUserChoice

      # The corresponding dependency's description
      #   DependencyDescription
      attr_reader :DepDesc

      # Ignore flag
      #   Boolean
      attr_reader :Ignore

      # Locate flag
      #   Boolean
      attr_reader :Locate

      # Installer index chosen for this dependency (can be nil if not to be installed)
      #   Integer
      attr_reader :IdxInstaller

      # Destination index chosen for this dependency (can be nil if not to be installed)
      #   Integer
      attr_reader :IdxDestination

      # The resolved testers (indexes), with their respective ContextModifier name and Location used to resolve them
      #   map< Integer, [ String, Object ] >
      attr_reader :ResolvedTesters

      # The other location
      #   Object
      attr_reader :OtherLocation

      # The list of ContextModifiers that could help resolving the Testers
      #   list< String >
      attr_reader :AffectingContextModifiers

      # Constructor
      #
      # Parameters:
      # * *ioInstaller* (_Installer_): RDI's installer used to query plugins
      # * *iViewName* (_String_): Name of the view to use
      # * *iDepDesc* (_DependencyDescription_): The dependency description to handle
      def initialize(ioInstaller, iViewName, iDepDesc)
        @Installer, @ViewName, @DepDesc = ioInstaller, iViewName, iDepDesc
        @Ignore = false
        @Locate = false
        @IdxInstaller = 0
        @IdxDestination = 0
        @ResolvedTesters = {}
        @OtherLocation = nil
        @AffectingContextModifiers = DependencyUserChoice::getAffectingContextModifiers(@Installer, @DepDesc)
      end

      # Compute the list of AffectingContextModifiers
      #
      # Parameters:
      # * *ioInstaller* (_Installer_): The installer
      # * *iDepDesc* (_DependencyDescription_): The dependency description
      # Return:
      # * <em>list<String></em>: The list of ContextModifiers names
      def self.getAffectingContextModifiers(ioInstaller, iDepDesc)
        rAffectingContextModifiers = []

        # Gather the list of affecting ContextModifiers by parsing every Tester.
        iDepDesc.Testers.each do |iTesterInfo|
          iTesterName, iTesterContent = iTesterInfo
          ioInstaller.accessPlugin('Testers', iTesterName) do |iPlugin|
            rAffectingContextModifiers = (rAffectingContextModifiers + iPlugin.AffectingContextModifiers).uniq
          end
        end

        return rAffectingContextModifiers
      end

      # Ask the user to change the context of a given context modifier to resolve this dependency
      #
      # Parameters:
      # * *iCMName* (_String_): Name of the ContextModifier we want to use
      def affectContextModifier(iCMName)
        @Installer.accessPlugin('ContextModifiers', iCMName) do |ioPlugin|
          # Get the name of LocationSelector class to use
          lLocationSelectorName = ioPlugin.LocationSelectorName
          @Installer.accessPlugin("LocationSelectors_#{@ViewName}", lLocationSelectorName) do |iLSPlugin|
            # Get the location from the plugin
            lLocationToTry = iLSPlugin.getNewLocation
            if (lLocationToTry != nil)
              # Try adding this new location if not already there
              if (ioPlugin.isLocationInContext?(lLocationToTry))
                logMsg "Location #{lLocationToTry} is already part of #{iCMName}"
              else
                # Add it
                ioPlugin.addLocationToContext(lLocationToTry)
                # Test Testers that were not already resolved
                lIdxTester = 0
                @DepDesc.Testers.each do |iTesterInfo|
                  if (!@ResolvedTesters.has_key?(lIdxTester))
                    # Test this one
                    iTesterName, iTesterContent = iTesterInfo
                    @Installer.accessPlugin('Testers', iTesterName) do |iTesterPlugin|
                      # Consider it only if it declares iCMName as an AffectingContextModifier
                      if (iTesterPlugin.AffectingContextModifiers.include?(iCMName))
                        if (iTesterPlugin.isContentResolved?(iTesterContent))
                          # Yes, it resolved this one
                          @ResolvedTesters[lIdxTester] = [ iCMName, lLocationToTry ]
                          logMsg "Location #{lLocationToTry} resolves correctly #{iTesterName} - #{iTesterContent}"
                        else
                          logErr "Location #{lLocationToTry} does not resolve #{iTesterName} - #{iTesterContent}"
                        end
                      end
                    end
                  end
                  lIdxTester += 1
                end
                # Remove it
                ioPlugin.removeLocationFromContext(lLocationToTry)
              end
            end
          end
        end
      end

      # Select a different install location for this dependency
      #
      # Parameters:
      # * *iLocationSelectorName* (_String_): The location selector name
      # Return:
      # * _Boolean_: Is the selection valid ?
      def selectOtherInstallLocation(iLocationSelectorName)
        rSuccess = false

        @Installer.accessPlugin("LocationSelectors_#{@ViewName}", iLocationSelectorName) do |iPlugin|
          # Get the location from the plugin
          lInstallLocation = iPlugin.getNewLocation
          if (lInstallLocation != nil)
            @OtherLocation = lInstallLocation
            rSuccess = true
          end
        end

        return rSuccess
      end

      # Set this choice to be "locate it"
      def setLocate
        @Ignore = false
        @Locate = true
        @IdxInstaller = nil
        @IdxDestination = nil
      end

      # Set this choice to be "ignore it"
      def setIgnore
        @Ignore = true
        @Locate = false
        @IdxInstaller = nil
        @IdxDestination = nil
      end

      # Set this choice to be "install it"
      #
      # Parameters:
      # * *iIdxInstaller* (_Integer_): The Installer's index
      # * *iIdxDestination* (_Integer_): The destination's index
      def setInstaller(iIdxInstaller, iIdxDestination)
        @Ignore = false
        @Locate = false
        @IdxInstaller = iIdxInstaller
        @IdxDestination = iIdxDestination
      end

      # Do we equal another user choice ?
      # Used by the regression
      #
      # Parameters:
      # * *iOtherDUC* (_DependencyOtherChoice_): The other one
      # Return:
      # * _Boolean_: Do we equal another user choice ?
      def ==(iOtherDUC)
        return (
          (@DepDesc == iOtherDUC.DepDesc) and
          (@Ignore == iOtherDUC.Ignore) and
          (@Locate == iOtherDUC.Locate) and
          (@IdxInstaller == iOtherDUC.IdxInstaller) and
          (@IdxDestination == iOtherDUC.IdxDestination) and
          (@ResolvedTesters == iOtherDUC.ResolvedTesters) and
          (@OtherLocation == iOtherDUC.OtherLocation)
        )
      end

    end

  end

end
