#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'rdi/Plugins/Views/SimpleWxGUI/DependencyPanel.rb'
# Needed to copy files once downloaded
require 'fileutils'

module RDI

  module Views

    class SimpleWxGUI

      # Dialog that downloads missing dependencies
      # Apart launchers, only this class has a dependency on RubyGems
      class DependenciesLoaderDialog < Wx::Dialog

        # Constructor
        #
        # Parameters:
        # * *iParent* (<em>Wx::Window</em>): The parent
        # * *ioInstaller* (_Installer_): The installer
        # * *iDepsUserChoices* (<em>list<DependencyUserChoice></em>): The dependency user choices to reflect in this dialog
        def initialize(iParent, ioInstaller, iDepsUserChoices)
          super(iParent,
            :title => 'RDI: Runtime Dependencies Installer',
            :style => Wx::DEFAULT_DIALOG_STYLE|Wx::RESIZE_BORDER|Wx::MAXIMIZE_BOX
          )

          # This boolean will prevent undesirable refreshes
          @DuringInit = true

          @Installer, @DepsUserChoices = ioInstaller, iDepsUserChoices
          @IconsDir = "#{File.dirname(__FILE__)}/Icons"

          # Create components
          @BApply = Wx::Button.new(self, Wx::ID_ANY, 'Apply')
          lSTMessage = Wx::StaticText.new(self, Wx::ID_ANY, "#{@DepsUserChoices.size} dependencies could not be found.\nPlease indicate what action to take for each one of them before continuing.",
            :style => Wx::ALIGN_CENTRE
          )
          lFont = lSTMessage.font
          lFont.weight = Wx::FONTWEIGHT_BOLD
          lSTMessage.font = lFont

          # The notebook containing the scroll windows
          @NBDeps = Wx::Notebook.new(self)
          # Create the image list for the notebook
          lNotebookImageList = Wx::ImageList.new(16, 16)
          @NBDeps.image_list = lNotebookImageList
          # Make this image list driven by a manager
          @NBImageListManager = RUtilAnts::GUI::ImageListManager.new(lNotebookImageList, 16, 16)

          # Create the list of Panels displaying each dependency
          @DependencyPanels = []
          @DepsUserChoices.each do |iDepUserChoice|
            @DependencyPanels << DependencyPanel.new(
              @NBDeps,
              @Installer,
              iDepUserChoice,
              self
            )
          end

          # The notebook pages, 1 per dependency
          lIdx = 0
          @DepsUserChoices.each do |iDepUserChoice|
            @NBDeps.add_page(
              @DependencyPanels[lIdx],
              iDepUserChoice.DepDesc.ID,
              false,
              -1
            )
            lIdx += 1
          end

          # Resize some components as they will be used for sizers
          @NBDeps.fit

          # Put everything in sizers
          lMainSizer = Wx::BoxSizer.new(Wx::VERTICAL)
          lMainSizer.add_item(lSTMessage, :border => 8, :flag => Wx::ALIGN_CENTER|Wx::ALL, :proportion => 0)
          lMainSizer.add_item(@NBDeps, :flag => Wx::GROW, :proportion => 1)
          lMainSizer.add_item(@BApply, :border => 8, :flag => Wx::ALIGN_RIGHT|Wx::ALL, :proportion => 0)
          self.sizer = lMainSizer

          self.fit

          # Events
          evt_button(@BApply) do |iEvent|
            self.end_modal(Wx::ID_OK)
          end

          @DuringInit = false

          # Update the tabs
          @DependencyPanels.each do |iPanel|
            notifyRefresh(iPanel)
          end

        end

        # A panel has been refreshed
        #
        # Parameters:
        # * *iPanel* (<em>Wx::Panel</em>): The panel just refreshed
        def notifyRefresh(iPanel)
          if (!@DuringInit)
            # Find the Tab containing this Panel
            lIdx = @DependencyPanels.index(iPanel)
            lDepUserChoice = @DepsUserChoices[lIdx]
            lIconName = "#{@IconsDir}/Dependency.png"
            if (lDepUserChoice.Locate)
              if (lDepUserChoice.ResolvedTesters.size == lDepUserChoice.DepDesc.Testers.size)
                # Complete
                lIconName = "#{@IconsDir}/ValidOK.png"
              else
                # Incomplete
                lIconName = "#{@IconsDir}/ValidKO.png"
              end
            elsif (lDepUserChoice.Ignore)
              lIconName = "#{@IconsDir}/Ignore.png"
            else
              # Get the icon of the selected Installer
              lInstallerName = lDepUserChoice.DepDesc.Installers[lDepUserChoice.IdxInstaller][0]
              # TODO: Accept more data formats
              lInstallerIconName = "#{@Installer.RDILibDir}/Plugins/Installers/Icons/#{lInstallerName}.png"
              if (File.exists?(lInstallerIconName))
                lIconName = lInstallerIconName
              end
            end
            lIdxImage = @NBImageListManager.getImageIndex(lIconName) do
              lIcon, lError = getBitmapFromURL(lIconName)
              if (lIcon == nil)
                lIcon, lError = getBitmapFromURL("#{@IconsDir}/Dependency.png")
              end
              next lIcon
            end
            @NBDeps.set_page_image(lIdx, lIdxImage)
          end
        end

      end

    end

  end

end
