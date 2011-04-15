#--
# Copyright (c) 2009 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Test

    module Views

      class Text < RDITestCase

        include RDITestCase_Views

        # Constructor
        def setup
          super
          @ViewPluginName = 'Text'
        end

        # Initialize the context to inject the following scenario to the View plugin
        #
        # Parameters:
        # * *ioPlugin* (_Object_): The View plugin
        # * *iScenario* (<em>list<[Integer,String,Object]></em>): The scenario
        # * *iMissingDependencies* (<em>list<DependencyDescription></em>): The missing dependencies list
        def initScenario(ioPlugin, iScenario, iMissingDependencies)
          # Index the dependencies ID
          # map< String, Integer >
          lDepsIndex = {}
          lIdx = 0
          iMissingDependencies.each do |iDepDesc|
            lDepsIndex[iDepDesc.ID] = lIdx
            lIdx += 1
          end
          # Get the list of commands to perform
          # list< String >
          lCmdList = []
          # Display it to the user for him to perform the actions
          iScenario.each do |iActionInfo|
            iAction, iDepID, iParameters = iActionInfo
            lStr = ''
            if (iDepID != nil)
              lStr += "#{lDepsIndex[iDepID]+1}."
            end
            case iAction
            when ACTION_LOCATE
              lStr += '1.'
            when ACTION_IGNORE
              lStr += '2.'
            when ACTION_INSTALL
              lStr += "3.#{iParameters[0]+1}.#{iParameters[1]+1}."
              if (iParameters[2] != nil)
                lCmdList << lStr
                lStr = iParameters[2]
              end
            when ACTION_APPLY
              lStr = "#{iMissingDependencies.size+1}."
            when ACTION_SELECT_AFFECTING_CONTEXTMODIFIER
              # Find the position of ContextModifier named iParameters[0] in the UI display
              lStr += "1.#{RDI::Model::DependencyUserChoice::getAffectingContextModifiers(@Installer, iMissingDependencies[lDepsIndex[iDepID]]).index(iParameters[0])+1}."
              lCmdList << lStr
              lStr = iParameters[1]
            else
              logBug "Unknown Action: #{iAction}"
            end
            lCmdList << lStr
          end
          # Write the file that will serve $stdin
          File.open("#{@Installer.TempDir}/stdin", 'w') do |iFile|
            iFile << lCmdList.join("\n")
          end
          # Now we redirect $stdin and $stdout on files
          @StdOutOrg = $stdout
          $stdout = File.open("#{@Installer.TempDir}/stdout", 'w')
          @StdInOrg = $stdin
          $stdin = File.open("#{@Installer.TempDir}/stdin", 'r')
        end

        # Finalize scenarion.
        # If context was modified by initScenario, revert it here.
        #
        # Parameters:
        # * *ioPlugin* (_Object_): The View plugin
        def finalScenario(ioPlugin)
          # We direct back $stdin and $stdout
          $stdout.close
          $stdin.close
          $stdout = @StdOutOrg
          $stdin = @StdInOrg
        end

        # Call the execute method of the plugin.
        #
        # Parameters:
        # * *ioPlugin* (_Object_): The View plugin
        # * *ioInstaller* (_Installer_): The RDI installer
        # * *iMissingDependencies* (<em>list<DependencyDescription></em>): The missing dependencies list
        # Return:
        # * <em>list<DependencyUserChoice></em>: The corresponding user choices
        def executeScenario(ioPlugin, ioInstaller, iMissingDependencies)
          return ioPlugin.execute(ioInstaller, iMissingDependencies)
        end

      end

    end

  end

end
