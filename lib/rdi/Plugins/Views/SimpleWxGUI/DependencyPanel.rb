#--
# Copyright (c) 2009 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Views

    class SimpleWxGUI

      # Panel that proposes how to resolve a dependency
      class DependencyPanel < Wx::Panel

        # Constructor
        # The notifier control window must have a notifyInstallDecisionChanged method implemented
        #
        # Parameters:
        # * *iParent* (<em>Wx::Window</em>): The parent window
        # * *ioInstaller* (_Installer_): The installer
        # * *iDepUserChoice* (_DependencyUserChoice_): The dependency's user choice
        # * *iNotifierControl* (_Object_): The notifier control that will be notified upon changes
        def initialize(iParent, ioInstaller, iDepUserChoice, iNotifierControl)
          super(iParent)

          @Installer, @DepUserChoice, @NotifierControl = ioInstaller, iDepUserChoice, iNotifierControl
          @IconsDir = "#{File.dirname(__FILE__)}/Icons"

          # Create components

          # The locate part
          @RBLocate = Wx::RadioButton.new(self, Wx::ID_ANY, 'Locate', :style => Wx::RB_GROUP)
          # The Testers' statuses
          # The list of [ StaticBitmap, StaticText ] used to represent Testers' state
          # list< [ Wx::StaticBitmap, Wx::StaticText ] >
          @TesterComponents = []
          @DepUserChoice.DepDesc.Testers.each do |iTesterInfo|
            iTesterName, iTesterContent = iTesterInfo
            @TesterComponents << [
              Wx::StaticBitmap.new(self, Wx::ID_ANY, Wx::Bitmap.new),
              Wx::StaticText.new(self, Wx::ID_ANY, "#{iTesterName}: #{iTesterContent}")
            ]
          end
          # The buttons affecting ContextModifiers
          # The list of Buttons used to affect ContextModifiers
          # list< Wx::Button >
          lACMComponents = []
          @DepUserChoice.AffectingContextModifiers.each do |iCMName|
            lACMComponents << Wx::Button.new(self, Wx::ID_ANY, "Change #{iCMName}")
          end

          # The ignore part
          @RBIgnore = Wx::RadioButton.new(self, Wx::ID_ANY, 'Ignore')

          # The install part
          @RBInstall = Wx::RadioButton.new(self, Wx::ID_ANY, 'Install')
          # The list of installers info
          # list< [ RadioButton, StaticBitmap, list< RadioButton > ] >
          @InstallerComponents = []
          # First, create the installers radio buttons before their respective destinations radio buttons.
          # This is done this way to ensure correct radio buttons grouping
          @DepUserChoice.DepDesc.Installers.each do |iInstallerInfo|
            iInstallerName, iInstallerContent, iContextModifiers = iInstallerInfo
            lRBInstaller = nil
            if (@InstallerComponents.empty?)
              # First item of the group
              lRBInstaller = Wx::RadioButton.new(self, Wx::ID_ANY, "#{iInstallerName} - #{iInstallerContent}", :style => Wx::RB_GROUP)
            else
              lRBInstaller = Wx::RadioButton.new(self, Wx::ID_ANY, "#{iInstallerName} - #{iInstallerContent}")
            end
            # Icon of the installer
            lIconName = "#{@IconsDir}/Dependency.png"
            # TODO: Accept more data formats
            lInstallerIconName = "#{@Installer.RDILibDir}/Plugins/Installers/Icons/#{iInstallerName}.png"
            if (File.exists?(lInstallerIconName))
              lIconName = lInstallerIconName
            end
            @InstallerComponents << [
              lRBInstaller,
              Wx::StaticBitmap.new(self, Wx::ID_ANY, Wx::Bitmap.new(lIconName)),
              []
            ]
          end
          lIdxInstaller = 0
          @DepUserChoice.DepDesc.Installers.each do |iInstallerInfo|
            iInstallerName, iInstallerContent, iContextModifiers = iInstallerInfo
            lDestinationComponents = @InstallerComponents[lIdxInstaller][2]
            @Installer.accessPlugin('Installers', iInstallerName) do |iPlugin|
              iPlugin.PossibleDestinations.each do |iDestInfo|
                iFlavour, iLocation = iDestInfo
                lFlavourText = nil
                lDestLocation = iLocation
                case iFlavour
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
                  lDestLocation = "Choose #{iLocation}"
                else
                  logBug "Unknown flavour ID: #{iFlavour}"
                  lFlavourText = 'Unknown'
                end
                if (lDestinationComponents.empty?)
                  # First destination radio button
                  lDestinationComponents << Wx::RadioButton.new(self, Wx::ID_ANY, "#{lFlavourText} - #{lDestLocation}", :style => Wx::RB_GROUP)
                else
                  lDestinationComponents << Wx::RadioButton.new(self, Wx::ID_ANY, "#{lFlavourText} - #{lDestLocation}")
                end
              end
            end
            lIdxInstaller += 1
          end

          # Put them into sizers
          lMainSizer = Wx::BoxSizer.new(Wx::VERTICAL)
          lMainSizer.add_item(@RBLocate, :proportion => 0)

          lLocateSizer = Wx::BoxSizer.new(Wx::HORIZONTAL)
          lLocateSizer.add_item([16,0], :proportion => 0)

          lLocateChoicesSizer = Wx::BoxSizer.new(Wx::VERTICAL)
          @TesterComponents.each do |iTesterComponentsList|
            lSB, lST = iTesterComponentsList
            lTesterSizer = Wx::BoxSizer.new(Wx::HORIZONTAL)
            lTesterSizer.add_item(lSB, :proportion => 0)
            lTesterSizer.add_item([8,0], :proportion => 0)
            lTesterSizer.add_item(lST, :proportion => 0)
            lLocateChoicesSizer.add_item(lTesterSizer, :proportion => 0)
          end
          lACMComponents.each do |iACMButton|
            lLocateChoicesSizer.add_item(iACMButton, :proportion => 0)
          end

          lLocateSizer.add_item(lLocateChoicesSizer, :proportion => 0)

          lMainSizer.add_item(lLocateSizer, :proportion => 0)
          lMainSizer.add_item([0,16], :proportion => 0)
          lMainSizer.add_item(@RBIgnore, :proportion => 0)
          lMainSizer.add_item([0,16], :proportion => 0)
          lMainSizer.add_item(@RBInstall, :proportion => 0)

          lInstallSizer = Wx::BoxSizer.new(Wx::HORIZONTAL)
          lInstallSizer.add_item([16,0], :proportion => 0)

          lInstallersListSizer = Wx::BoxSizer.new(Wx::VERTICAL)
          @InstallerComponents.each do |iInstallerComponentsInfo|
            lRBInstaller, lSBIcon, lRBListDests = iInstallerComponentsInfo

            lInstallerChoiceSizer = Wx::BoxSizer.new(Wx::HORIZONTAL)
            lInstallerChoiceSizer.add_item(lRBInstaller, :proportion => 0)
            lInstallerChoiceSizer.add_item(lSBIcon, :proportion => 0)

            lInstallersListSizer.add_item(lInstallerChoiceSizer, :proportion => 0)

            lDestinationsListWithTabSizer = Wx::BoxSizer.new(Wx::HORIZONTAL)
            lDestinationsListWithTabSizer.add_item([16,0], :proportion => 0)

            lDestinationsListSizer = Wx::BoxSizer.new(Wx::VERTICAL)
            lRBListDests.each do |iRBDestination|
              lDestinationsListSizer.add_item(iRBDestination, :proportion => 0)
            end

            lDestinationsListWithTabSizer.add_item(lDestinationsListSizer, :proportion => 0)

            lInstallersListSizer.add_item(lDestinationsListWithTabSizer, :proportion => 0)
          end

          lInstallSizer.add_item(lInstallersListSizer, :proportion => 0)

          lMainSizer.add_item(lInstallSizer, :proportion => 0)

          self.sizer = lMainSizer
          self.fit

          # Set events
          # Click on "Locate"
          evt_radiobutton(@RBLocate) do |iEvent|
            @DepUserChoice.setLocate
            refreshComponents
          end
          # Click on any of the ACM
          lACMIdx = 0
          lACMComponents.each do |iACMButton|
            # Clone indexes for them to be persistent in the code block
            lACMIdxCloned = lACMIdx
            evt_button(iACMButton) do |iEvent|
              # Call the correct LocationSelector
              @DepUserChoice.affectContextModifier(@DepUserChoice.AffectingContextModifiers[lACMIdxCloned])
              refreshComponents
            end
            lACMIdx += 1
          end
          # Click on "Ignore"
          evt_radiobutton(@RBIgnore) do |iEvent|
            @DepUserChoice.setIgnore
            refreshComponents
          end
          # Click on "Install"
          evt_radiobutton(@RBInstall) do |iEvent|
            @DepUserChoice.setInstaller(0, 0)
            refreshComponents
          end
          # Click on any of the installers
          lIdxInstaller = 0
          @InstallerComponents.each do |iInstallerComponentsInfo|
            # Clone the indexes to make them persistent in the code block
            lIdxInstallerCloned = lIdxInstaller
            lRBInstaller, lSBIcon, lRBListDests = iInstallerComponentsInfo
            evt_radiobutton(lRBInstaller) do |iEvent|
              @DepUserChoice.setInstaller(lIdxInstallerCloned, 0)
              refreshComponents
            end
            # Click on any of the destinations
            lIdxDest = 0
            lRBListDests.each do |iRBDestination|
              lIdxDestCloned = lIdxDest
              evt_radiobutton(iRBDestination) do |iEvent|
                @DepUserChoice.setInstaller(lIdxInstallerCloned, lIdxDestCloned)
                # If it is DEST_OTHER, call the LocationSelector
                @Installer.accessPlugin('Installers', @DepUserChoice.DepDesc.Installers[lIdxInstallerCloned][0]) do |iPlugin|
                  iFlavour, iLocation = iPlugin.PossibleDestinations[lIdxDestCloned]
                  if (iFlavour == DEST_OTHER)
                    @DepUserChoice.selectOtherInstallLocation(iLocation)
                  end
                end
                refreshComponents
              end
              lIdxDest += 1
            end
            lIdxInstaller += 1
          end

          # Refresh the components
          refreshComponents

        end

        # Refresh components
        def refreshComponents
          # Testers icons
          lIdxTester = 0
          @TesterComponents.each do |iTesterComponentsList|
            iSBStatus, iSTTitle = iTesterComponentsList
            # Check if the Tester is resolved
            if (@DepUserChoice.ResolvedTesters.has_key?(lIdxTester))
              iSBStatus.bitmap, lError = getBitmapFromURL("#{@IconsDir}/ValidOK.png")
            else
              iSBStatus.bitmap, lError = getBitmapFromURL("#{@IconsDir}/ValidKO.png")
            end
            lIdxTester += 1
          end
          # Selections
          @RBLocate.set_value(@DepUserChoice.Locate)
          @RBIgnore.set_value(@DepUserChoice.Ignore)
          @RBInstall.set_value(@DepUserChoice.IdxInstaller != nil)
          lIdxInstaller = 0
          @InstallerComponents.each do |iInstallerComponentsInfo|
            lRBInstaller, lSBIcon, lRBListDests = iInstallerComponentsInfo
            lRBInstaller.set_value((@DepUserChoice.IdxInstaller == lIdxInstaller))
            lIdxDest = 0
            lRBListDests.each do |iRBDestination|
              iRBDestination.set_value(
                ((@DepUserChoice.IdxInstaller == lIdxInstaller) and
                 (@DepUserChoice.IdxDestination == lIdxDest))
              )
              # Change the text if it is DEST_OTHER
              @Installer.accessPlugin('Installers', @DepUserChoice.DepDesc.Installers[lIdxInstaller][0]) do |iPlugin|
                iFlavour, iLocation = iPlugin.PossibleDestinations[lIdxDest]
                if (iFlavour == DEST_OTHER)
                  # If it is the current one, use OtherLocation
                  if ((@DepUserChoice.IdxInstaller == lIdxInstaller) and
                      (@DepUserChoice.IdxDestination == lIdxDest))
                    iRBDestination.label = "Other (#{@DepUserChoice.OtherLocation})"
                  else
                    iRBDestination.label = "Other (Choose #{iLocation})"
                  end
                end
              end
              lIdxDest += 1
            end
            lIdxInstaller += 1
          end
          # Fit again, as some labels might have changed
          self.fit
          # Notify refresh
          @NotifierControl.notifyRefresh(self)
        end

      end

    end

  end

end
