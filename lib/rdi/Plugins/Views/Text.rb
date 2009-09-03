#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Views

    class Text

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

        # Fill it from the beginning
        iMissingDependencies.each do |iDepDesc|
          rDependenciesUserChoices << RDI::Model::DependencyUserChoice.new(ioInstaller, 'Text', iDepDesc)
        end
        # Start looping unless user validates its choices
        lExit = false
        while (!lExit)
          display(ioInstaller, iMissingDependencies, rDependenciesUserChoices)
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
                (lUserChoice[0] > iMissingDependencies.size + 1))
              lInvalid = true
            elsif (lUserChoice[0] == iMissingDependencies.size + 1)
              if (lUserChoice.size == 1)
                # We want to apply those choices
                lExit = true
              else
                lInvalid = true
              end
            else
              # A given dependency has been selected
              lDepDesc = iMissingDependencies[lUserChoice[0]-1]
              lDepUserChoice = rDependenciesUserChoices[lUserChoice[0]-1]
              case lUserChoice[1]
              when 1
                # Ask to modify the context somewhere
                if (lUserChoice.size == 2)
                  # Just select that we locate it
                  lDepUserChoice.setLocate
                else
                  # We try to use a given ContextModifier
                  if (lUserChoice.size == 3)
                    if (lUserChoice[2] > lDepUserChoice.AffectingContextModifiers.size)
                      lInvalid = true
                    else
                      # Select a new location for the given context modifier
                      lDepUserChoice.affectContextModifier(lDepDesc, lDepUserChoice.AffectingContextModifiers[lUserChoice[2]-1])
                    end
                  else
                    lInvalid = true
                  end
                end
              when 2
                # Ask to ignore the dependency
                if (lUserChoice.size == 2)
                  lDepUserChoice.setIgnore
                else
                  lInvalid = true
                end
              when 3
                # Ask to install the dependency
                if (lUserChoice.size == 4)
                  if (lUserChoice[2] > lDepDesc.Installers.size)
                    lInvalid = true
                  else
                    lInstallerName, lInstallerContent, lContextModifiers = lDepDesc.Installers[lUserChoice[2]-1]
                    # Access the possible destinations
                    ioInstaller.accessPlugin('Installers', lInstallerName) do |ioPlugin|
                      if (lUserChoice[3] > ioPlugin.PossibleDestinations.size)
                        lInvalid = true
                      else
                        lDepUserChoice.setInstaller(lUserChoice[2]-1, lUserChoice[3]-1)
                        # Check if it is a DEST_OTHER flavour
                        if (ioPlugin.PossibleDestinations[lUserChoice[3]-1][0] == DEST_OTHER)
                          # Replace the other location of this dependency
                          if (lDepUserChoice.selectOtherInstallLocation(ioPlugin.PossibleDestinations[lUserChoice[3]-1][1]))
                            lDepUserChoice.setInstaller(lUserChoice[2]-1, 0)
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
            end
          end
          # Now either store the last selection
          if (lInvalid)
            puts "Invalid selection. Please type the selection correctly (i.e. 1.3.2)"
          end
        end

        return rDependenciesUserChoices
      end

      private

      # Display the current state
      #
      # Parameters:
      # * *ioInstaller* (_Installer_): The RDI installer
      # * *iMissingDependencies* (<em>list<DependencyDescription></em>): The missing dependencies list
      # * *iDepsUserChoices* (<em>list<DependencyUserChoice></em>): The corresponding user choices
      def display(ioInstaller, iMissingDependencies, iDepsUserChoices)
        lIdxMissingDeps = 1
        iMissingDependencies.each do |iDepDesc|
          lDepID = iDepDesc.ID
          # Get the dependency info
          lDepUserChoice = iDepsUserChoices[lIdxMissingDeps-1]
          # Check the state of this dependency
          lStateText = ''
          lLocateChoice = ' '
          lIgnoreChoice = ' '
          lInstallChoice = ' '
          if (lDepUserChoice.Locate)
            # To be located
            lLocateChoice = '*'
            # Check if the Testers are all resolved
            if (lDepUserChoice.ResolvedTesters.size == iDepDesc.Testers.size)
              lStateText = 'Found'
            else
              lStateText = 'Locate incomplete'
            end
          elsif (lDepUserChoice.Ignore)
            # To be ignored
            lIgnoreChoice = '*'
            lStateText = 'Ignore'
          else
            # To be installed
            lInstallChoice = '*'
            lStateText = 'Install'
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
            if (lDepUserChoice.ResolvedTesters.has_key?(lIdxTester))
              lTesterText = 'Found'
            else
              lTesterText = 'Missing'
            end
            puts "        [ #{lTesterText} ] #{iTesterName} - #{iTesterContent}"
            lIdxTester += 1
          end
          # Display the choices for location
          lIdxACM = 1
          lDepUserChoice.AffectingContextModifiers.each do |iCMName|
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
            if (lDepUserChoice.IdxInstaller == lIdxInstaller-1)
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
                  if (lDepUserChoice.IdxInstaller == lIdxInstaller-1)
                    lDestLocation = lDepUserChoice.OtherLocation
                  else
                    lDestLocation = 'Choose'
                  end
                else
                  logBug "Unknown flavour ID: #{iDestFlavour}"
                  lFlavourText = 'Unknown'
                end
                lInstallLocationSelectionText = ' '
                if (lDepUserChoice.UserChoice[2] == lIdxDest)
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

  end

end