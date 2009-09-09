#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Test

    module Views

      class SimpleWxGUI < RDITestCase

        include RDITestCase_Views

        # Constructor
        def setup
          super
          @ViewPluginName = 'SimpleWxGUI'
          require 'Plugins/WxEnv'
          RDI::Test::RDIWx.installTestWxEnv
        end

        # initScenario
        #
        # Parameters:
        # * *ioPlugin* (_Object_): The View plugin
        # * *iScenario* (<em>list<[Integer,String,Object]></em>): The scenario
        # * *iMissingDependencies* (<em>list<DependencyDescription></em>): The missing dependencies list
        def initScenario(ioPlugin, iScenario, iMissingDependencies)
          # Display it to the user for him to perform the actions
          @Scenario = iScenario
        end

        # executeScenario
        #
        # Parameters:
        # * *ioPlugin* (_Object_): The View plugin
        # * *ioInstaller* (_Installer_): The RDI installer
        # * *iMissingDependencies* (<em>list<DependencyDescription></em>): The missing dependencies list
        # Return:
        # * <em>list<DependencyUserChoice></em>: The corresponding user choices
        def executeScenario(ioPlugin, ioInstaller, iMissingDependencies)
          # Modify the constructor of DependenciesLoaderDialog to trap its instance (as Wx::get_app.get_top_window does not work as expected)
          # Load it first to ensure the class will be loaded
          ioInstaller.accessPlugin('Views', 'SimpleWxGUI') do |iPlugin|
            require 'rdi/Plugins/Views/SimpleWxGUI/DependenciesLoaderDialog'
          end
          if (defined?($RDI_ModifiedDepLoaderDialog) == nil)
            $RDI_ModifiedDepLoaderDialog = true
            RDI::Views::SimpleWxGUI::DependenciesLoaderDialog.module_eval('
        alias :initialize_ORG :initialize

        # Constructor
        #
        # Parameters:
        # * *iParent* (<em>Wx::Window</em>): The parent
        # * *ioInstaller* (_Installer_): The installer
        # * *iDepsUserChoices* (<em>list<DependencyUserChoice></em>): The dependency user choices to reflect in this dialog
        def initialize(iParent, ioInstaller, iDepsUserChoices)
          initialize_ORG(iParent, ioInstaller, iDepsUserChoices)
          $RDI_DepLoaderDialog = self
        end

            ')
          end
          $RDI_DepLoaderDialog = nil
          Thread.new do
            # This thread will pilot our GUI
            begin
              lExit = false
              while !lExit
                # Get the Top window (don't use Wx::get_app.get_top_window as it is not updated after several dialogs displayed)
                # TODO (wxRuby): Make Wx::get_app.get_top_window work as expected
                lTopWindow = $RDI_DepLoaderDialog
                if (lTopWindow != nil)
                  # Add some methods that will give us some internals
                  lTopWindow.class.module_eval('
        # The list of dependency panels
        #   list< DependencyPanel >
        attr_reader :DependencyPanels

        # The Apply button
        #   Wx::Button
        attr_reader :BApply

        # The list of DepUserChoices
        #   list< DependencyUserChoice >
        attr_reader :DepsUserChoices

                    ')
                  lTopWindow.DependencyPanels[0].class.module_eval('
        # The Locate radio button
        #   Wx::RadioButton
        attr_reader :RBLocate

        # The Ignore radio button
        #   Wx::RadioButton
        attr_reader :RBIgnore

        # The Installers components
        #   list< [ RadioButton, StaticBitmap, list< RadioButton > ] >
        attr_reader :InstallerComponents

                    ')
                  # Execute the scenario
                  @Scenario.each do |iActionInfo|
                    iAction, iDepID, iParameters = iActionInfo
                    # First, find the correct dependency panel
                    lDepPanel = nil
                    lDepUserChoice = nil
                    if (iDepID != nil)
                      # Find the correct index
                      lIdxDep = 0
                      iMissingDependencies.each do |iDepDesc|
                        if (iDepDesc.ID == iDepID)
                          break
                        end
                        lIdxDep += 1
                      end
                      lDepPanel = lTopWindow.DependencyPanels[lIdxDep]
                      lDepUserChoice = lTopWindow.DepsUserChoices[lIdxDep]
                    end
                    case iAction
                    when ACTION_LOCATE
                      lDepPanel.RBLocate.command(Wx::CommandEvent.new(Wx::EVT_COMMAND_RADIOBUTTON_SELECTED, lDepPanel.RBLocate.get_id))
                    when ACTION_IGNORE
                      lDepPanel.RBIgnore.command(Wx::CommandEvent.new(Wx::EVT_COMMAND_RADIOBUTTON_SELECTED, lDepPanel.RBIgnore.get_id))
                    when ACTION_INSTALL
                      lIdxInstaller, lIdxDest, lOtherLocation = iParameters
                      lRBDest = lDepPanel.InstallerComponents[lIdxInstaller][2][lIdxDest]
                      # In case of DEST_OTHER, we must use a different LocationSelector
                      lOtherFound = false
                      lInstallerName, lInstallerContent, lContextModifiers = lDepUserChoice.DepDesc.Installers[lIdxInstaller]
                      ioInstaller.accessPlugin('Installers', lInstallerName) do |iPlugin|
                        lFlavour, lLocation = iPlugin.PossibleDestinations[lIdxDest]
                        if (lFlavour == DEST_OTHER)
                          setupFakeSelector(lLocation, lOtherLocation) do
                            lRBDest.command(Wx::CommandEvent.new(Wx::EVT_COMMAND_RADIOBUTTON_SELECTED, lRBDest.get_id))
                          end
                          lOtherFound = true
                          break
                        end
                      end
                      if (!lOtherFound)
                        lRBDest.command(Wx::CommandEvent.new(Wx::EVT_COMMAND_RADIOBUTTON_SELECTED, lRBDest.get_id))
                      end
                    when ACTION_APPLY
                      lTopWindow.BApply.command(Wx::CommandEvent.new(Wx::EVT_COMMAND_BUTTON_CLICKED, lTopWindow.BApply.get_id))
                      # Exit our loop
                      lExit = true
                      break
                    when ACTION_SELECT_AFFECTING_CONTEXTMODIFIER
                      # TODO
                      lCMName, lLocation = iParameters
                      # Click on the button named "Change #{lCMName}"
                      # TODO (wxRuby): Make Window#find_window_by_label work (little typo)
                      lButton = Wx::Window.find_window_by_label("Change #{lCMName}", lDepPanel)
                      # Change the LocationSelector
                      ioInstaller.accessPlugin('ContextModifiers', lCMName) do |ioCMPlugin|
                        # Get the name of LocationSelector class to use
                        # Setup a fake selector
                        setupFakeSelector(ioCMPlugin.LocationSelectorName, lLocation) do
                          lButton.command(Wx::CommandEvent.new(Wx::EVT_COMMAND_BUTTON_CLICKED, lButton.get_id))
                        end
                      end
                    else
                      logBug "Unknown Action: #{iAction}"
                    end
                  end
                  # Time between each action: 200 ms
                  sleep(0.2)
                end
                # Time between each attempt to find the new window: 200 ms
                sleep(0.2)
              end
            rescue Exception
              logExc $!, 'Exception while piloting GUI for testing.'
            end
          end

          return ioPlugin.execute(ioInstaller, iMissingDependencies)
        end

      end

    end

  end

end
