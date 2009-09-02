#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Views

    class Text

      # Class for text UI
      class TextUI

        # Class used to store info associated to a dependency
        class DependencyInfo

          # The current user selection
          #   list< Integer >
          attr_accessor :UserChoice

          # The resolved testers (indexes), with their respective ContextModifier name and Location used to resolve them
          #   map< Integer, [ String, Object ] >
          attr_accessor :ResolvedTesters

          # The other location
          #   Object
          attr_accessor :OtherLocation

          # The list of ContextModifiers that could help resolving the Testers
          #   list< String >
          attr_accessor :AffectingContextModifiers

        end

        # Constructor
        #
        # Parameters:
        # * *iMissingDependencies* (<em>list<DependencyDescription></em>): The missing dependencies list
        # * *ioInstaller* (_Installer_): The RDI installer
        def initialize(iMissingDependencies, ioInstaller)
          @MissingDependencies, @Installer = iMissingDependencies, ioInstaller
          # Map of dependencies info, per dependency ID
          # map< String, DependencyInfo >
          @DependenciesInfo = {}
          # Fill it for the beginning
          @MissingDependencies.each do |iDepDesc|
            lDepInfo = DependencyInfo.new
            lDepInfo.UserChoice = [ 3, 1, 1 ]
            lDepInfo.ResolvedTesters = {}
            lDepInfo.OtherLocation = nil
            lDepInfo.AffectingContextModifiers = {}
            # Gather the list of affecting ContextModifiers by parsing every Tester.
            iDepDesc.Testers.each do |iTesterInfo|
              iTesterName, iTesterContent = iTesterInfo
              @Installer.accessPlugin('Testers', iTesterName) do |iPlugin|
                lDepInfo.AffectingContextModifiers = (lDepInfo.AffectingContextModifiers + iPlugin.AffectingContextModifiers).uniq
              end
            end
            @DependenciesInfo[iDepDesc.ID] = lDepInfo
          end
        end
        
        # Execute the handling of the required dependencies
        #
        # Return:
        # * <em>list<[DependencyDescription,Integer,Object]></em>: The list of dependencies to install, along with the index of installer and their respective install location
        # * <em>list<DependencyDescription></em>: The list of dependencies that the user chose to ignore deliberately
        # * <em>map<String,list<[String,Object]>></em>: The list of context modifiers that have been applied to resolve the dependencies, per dependency ID
        def execute
          rInstallationList = []
          rIgnoreList = []
          rContextModifiers = {}

          lExit = false
          while (!lExit)
            display
            # Wait for input
            $stdout.write('Please enter choice number -> ')
            lUserChoiceText = $stdin.gets
            # Parse user choice
            lInvalid = false
            # Check that we have an array of integers not 0
            lUserChoice = lUserChoiceText.split('.').map do |iElem|
              lInt = iElem.to_i
              if (lInt == 0)
                lInvalid = true
              end
              next lInt
            end
            if (!lInvalid)
              # Check that each value does not exceed maximal value
              if ((lUserChoice.empty?) or
                  (lUserChoice[0] > @MissingDependencies.size + 1))
                lInvalid = true
              elsif (lUserChoice[0] == @MissingDependencies.size + 1)
                if (lUserChoice.size == 1)
                  # We want to apply those choices
                  lExit = true
                else
                  lInvalid = true
                end
              else
                # A given dependency has been selected
                lDepDesc = @MissingDependencies[lUserChoice[0]]
                lDepInfo = @DependenciesInfo[lDepDesc.ID]
                case lUserChoice[1]
                when 1
                  # Ask to modify the context somewhere
                  if (lUserChoice.size == 2)
                    # Just select that we locate it
                  else
                    # We try to use a given ContextModifier
                    if (lUserChoice.size == 3)
                      if (lUserChoice[2] > lDepInfo.AffectingContextModifiers.size)
                        lInvalid = true
                      else
                        # Select a new location for the given context modifier
                        affectContextModifier(lDepDesc, lDepInfo.AffectingContextModifiers[lUserChoice[2]])
                      end
                    else
                      lInvalid = true
                    end
                  end
                when 2
                  # Ask to ignore the dependency
                  if (lUserChoice.size == 2)
                    # Nothing to do, just remember the choice
                  else
                    lInvalid = true
                  end
                when 3
                  # Ask to install the dependency
                  if (lUserChoice.size == 4)
                    if (lUserChoice[2] > lDepDesc.Installers.size)
                      lInvalid = true
                    else
                      lInstallerName, lInstallerContent, lContextModifiers = lDepDesc.Installers[lUserChoice[2]]
                      # Access the possible destinations
                      @Installer.accessPlugin('Installers', lInstallerName) do |ioPlugin|
                        if (lUserChoice[3] > ioPlugin.PossibleDestinations.size)
                          lInvalid = true
                        else
                          # Check if it is a DEST_OTHER flavour
                          if (ioPlugin.PossibleDestinations[lUserChoice[3]][0] == DEST_OTHER)
                            # Replace the other location of this dependency
                            if (!selectOtherInstallLocation(lDepDesc, ioPlugin.PossibleDestinations[lUserChoice[3]][1]))
                              lInvalid = true
                            end
                          end
                        end
                      end
                    end
                  else
                    lInvalid = true
                  end
                else
                  lInvalid = true
                end
                if (!lInvalid)
                  # Remember the user selection for this dependency
                  lDepInfo.UserChoice = lUserChoice[1..-1]
                end
              end
            end
            # Now either store the last selection
            if (lInvalid)
              puts "Invalid selection. Please type the selection correctly (i.e. 1.3.2)"
            end
          end
          # Get the lists to apply
          @MissingDependencies.each do |iDepDesc|
            lDepInfo = @DependenciesInfo[iDepDesc.ID]
            case lDepInfo.UserChoice[0]
            when 1
              # Check if the Testers are all resolved
              if (lDepInfo.ResolvedTesters.size == iDepDesc.Testers.size)
                lStateText = 'Found'
              else
                lStateText = 'Locate incomplete'
              end
            when 2
              # To be ignored
              rIgnoreList << iDepDesc
            when 3
              # To be installed
              lInstallChoice = '*'
              lStateText = 'Install'
            else
              logBug "Unknown user choice: #{lDepInfo.UserChoice[0]} for dependency #{lDepID}."
              lStateText = 'Unknown'
            end
          end

          return rInstallationList, rIgnoreList, rContextModifiers

        end

        private

        # Ask the user to change the context of a given context modifier to resolve a dependency
        #
        # Parameters:
        # * *iDepDesc* (_DependencyDescription_): The dependency description for which we modify the context
        # * *iCMName* (_String_): Name of the ContextModifier we want to use
        def affectContextModifier(iDepDesc, iCMName)
          lDepInfo = @DependenciesInfo[iDepDesc.ID]
          @Installer.accessPlugin('ContextModifiers', iCMName) do |ioPlugin|
            # Get the name of LocationSelector class to use
            lLocationSelectorName = ioPlugin.LocationSelectorName
            @Installer.accessPlugin('LocationSelectors_Text', lLocationSelectorName) do |iLSPlugin|
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
                  iDepDesc.Testers.each do |iTesterInfo|
                    if (!lDepInfo.ResolvedTesters.has_key?(lIdxTester))
                      # Test this one
                      iTesterName, iTesterContent = iTesterInfo
                      @Installer.accessPlugin('Testers', iTesterName) do |iTesterPlugin|
                        if (iTesterPlugin.isContentResolved?(iTesterContent))
                          # Yes, it resolved this one
                          lDepInfo.ResolvedTesters[lIdxTester] = [ iCMName, lLocationToTry ]
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

        # Select a different install location for a dependency
        #
        # Parameters:
        # * *iDepDesc* (_DependencyDescription_): The dependency description for which we modify the context
        # * *iLocationSelectorName* (_String_): The location selector name
        # Return:
        # * _Boolean_: Is the selection valid ?
        def selectOtherInstallLocation(iDepDesc, iLocationSelectorName)
          rSuccess = false

          @Installer.accessPlugin('LocationSelectors_Text', iLocationSelectorName) do |iPlugin|
            # Get the location from the plugin
            lInstallLocation = iPlugin.getNewLocation
            if (lInstallLocation != nil)
              @DependenciesInfo[iDepDesc.ID].OtherLocation = lInstallLocation
              rSuccess = true
            end
          end

          return rSuccess
        end

        # Display the current state
        def display
          lIdxMissingDeps = 1
          @MissingDependencies.each do |iDepDesc|
            lDepID = iDepDesc.ID
            # Get the dependency info
            lDepInfo = @DependenciesInfo[lDepID]
            # Check the state of this dependency
            lStateText = ''
            lLocateChoice = ' '
            lIgnoreChoice = ' '
            lInstallChoice = ' '
            case lDepInfo.UserChoice[0]
            when 1
              # To be located
              lLocateChoice = '*'
              # Check if the Testers are all resolved
              if (lDepInfo.ResolvedTesters.size == iDepDesc.Testers.size)
                lStateText = 'Found'
              else
                lStateText = 'Locate incomplete'
              end
            when 2
              # To be ignored
              lIgnoreChoice = '*'
              lStateText = 'Ignore'
            when 3
              # To be installed
              lInstallChoice = '*'
              lStateText = 'Install'
            else
              logBug "Unknown user choice: #{lDepInfo.UserChoice[0]} for dependency #{lDepID}."
              lStateText = 'Unknown'
            end
            # Display title
            puts "#{lIdxMissingDeps}. [ #{lStateText} ] #{lDepID}"
            puts ''
            # Display the "Locate it" choice
            puts "  #{lIdxMissingDeps}.1. (#{lLocateChoice}) Locate it"
            lIdxTester = 0
            iDepDesc.Testers.each do |iTesterInfo|
              iTesterName, iTesterContent = iTesterInfo
              # Check the state of this tester
              lTesterText = nil
              if (lDepInfo.ResolvedTesters.has_key?(lIdxTester))
                lTesterText = 'Found'
              else
                lTesterText = 'Missing'
              end
              puts "        [ #{lTesterText} ] #{iTesterName} - #{iTesterContent}"
              lIdxTester += 1
            end
            # Display the choices for location
            lIdxACM = 1
            lDepInfo.AffectingContextModifiers.each do |iCMName|
              puts "    #{lIdxMissingDeps}.1.#{lIdxACM}. Add location to #{iCMName}"
              lIdxACM += 1
            end
            puts ''
            # Display the "Ignore it" choice
            puts "  #{lIdxMissingDeps}.2. (#{lIgnoreChoice}) Ignore it"
            puts ''
            # Display the "Install it" choice
            puts "  #{lIdxMissingDeps}.3. (#{lInstallChoice}) Install it"
            lIdxInstaller = 1
            iDepDesc.Installers.each do |iInstallerInfo|
              iInstallerName, iInstallerContent, iContextModifiers = iInstallerInfo
              lInstallSelectionText = ' '
              if (lDepInfo.UserChoice[1] == lIdxInstaller)
                lInstallSelectionText = '*'
              end
              puts "    #{lIdxMissingDeps}.3.#{lIdxInstaller}. (#{lInstallSelectionText}) #{iInstallerName} - #{iInstallerContent}"
              puts '               Install in:'
              ioInstaller.accessPlugin('Installers', iInstallerName) do |iPlugin|
                lIdxDest = 1
                iPlugin.PossibleDestinations.each do |iDestInfo|
                  iDestFlavour, iDestLocation = iDestInfo
                  lFlavourText = nil
                  lDestLocation = iDestLocation
                  case iDestFlavour
                  when DEST_LOCAL
                    lFlavourText = 'Local'
                  when DEST_SYSTEM
                    lFlavourText = 'System'
                  when DEST_USER
                    lFlavourText = 'User'
                  when DEST_TEMP
                    lFlavourText = 'Temporary'
                  when DEST_OTHER
                    lFlavourText = 'Other'
                    lDestLocation = lDepInfo.OtherLocation
                  else
                    logBug "Unknown flavour ID: #{iDestFlavour}"
                    lFlavourText = 'Unknown'
                  end
                  lInstallLocationSelectionText = ' '
                  if (lDepInfo.UserChoice[2] == lIdxDest)
                    lInstallLocationSelectionText = '*'
                  end
                  puts "      #{lIdxMissingDeps}.3.#{lIdxInstaller}.#{lIdxDest}. (#{lInstallLocationSelectionText}) #{lFlavourText} - #{lDestLocation}"
                  lIdxDest += 1
                end
              end
              lIdxInstaller += 1
            end
            puts ''
            lIdxMissingDeps += 1
          end
          # Display the apply choice
          puts "#{lIdxMissingDeps}. Apply."
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
      # * <em>list<[DependencyDescription,Integer,Object]></em>: The list of dependencies to install, along with the index of installer and their respective install location
      # * <em>list<DependencyDescription></em>: The list of dependencies that the user chose to ignore deliberately
      # * <em>map<String,list<[String,Object]>></em>: The list of context modifiers that can be applied to resolve the dependencies, per dependency ID
      def execute(ioInstaller, iMissingDependencies)
        return TextUI.new(ioInstaller, iMissingDependencies).execute
      end

    end

  end

end