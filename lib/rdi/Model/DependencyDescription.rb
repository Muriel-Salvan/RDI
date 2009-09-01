#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Model

    # Class storing information about a dependency
    class DependencyDescription

      # ID of the description
      #   String
      attr_reader :ID

      # List of the testers that must be resolved to ensure this dependency (list of couples [ TesterName, TesterContent ])
      #   list< [ String, Object ] >
      attr_reader :Testers

      # List of the possible installers
      #   list< [ String, Object, list< [ String, Object ] > ] >
      #   list< [ InstallerName, InstallerContent, list< [ ContextModifierName, ContextModifierContent ] > ] >
      attr_reader :Installers

      # Constructor
      #
      # Parameters:
      # * *iID* (_String_): ID of this description. This can be used for example to further associate context modifiers to previously installed dependencies
      def initialize(iID)
        @ID = iID
        @Testers = []
        @Installers = []
      end

      # Add given testers and installers lists
      #
      # Parameters:
      # * *iTesters* (<em>list<TesterInfo></em>): List of Testers
      # * *iInstallers* (<em>list<InstallerInfo></em>): List of Installers
      # Return:
      # * _DependencyDescription_: self, useful to concatenate such method calls
      def addTestersAndInstallers(iTesters, iInstallers)
        iTesters.each do |iTesterInfo|
          addTesterInfo(iTesterInfo)
        end
        iInstallers.each do |iInstallerInfo|
          addInstallerInfo(iInstallerInfo)
        end

        return self
      end

      # Add a complete description.
      # Here are the formats authorized:
      # * { :Testers => list< TesterInfo >, :Installers => list< InstallerInfo > }
      # * [ list< TesterInfo >, list< InstallerInfo > ]
      #
      # Parameters:
      # * *iDescription* (_Object_): The description
      # Return:
      # * _DependencyDescription_: self, useful to concatenate such method calls
      def addDescription(iDescription)
        if (iDescription.is_a?(Array))
          addTestersAndInstallers(iDescription[0], iDescription[1])
        elsif (iDescription.is_a?(Hash))
          addTestersAndInstallers(iDescription[:Testers], iDescription[:Installers])
        else
          logBug "Invalid Description: #{iDescription.inspect}."
        end

        return self
      end

      # Add a tester info
      # Here are the following formats accepted for each Tester info:
      # * [ String, Object ]
      # * { :Type => String, :Content => Object }
      #
      # Parameters:
      # * *iTesterInfo* (_Object_): The tester info
      # Return:
      # * _DependencyDescription_: self, useful to concatenate such method calls
      def addTesterInfo(iTesterInfo)
        if (iTesterInfo.is_a?(Array))
          @Testers << iTesterInfo
        elsif (iTesterInfo.is_a?(Hash))
          @Testers << [ iTesterInfo[:Type], iTesterInfo[:Content] ]
        else
          logBug "Invalid TesterInfo: #{iTesterInfo.inspect}."
        end

        return self
      end

      # Add an installer info
      # Here are the following formats accepted for each Installer info:
      # * [ String, Object, list< ContextModifierInfo > ]
      # * [ :Type => String, :Content => Object, :ContextModifiers => list< ContextModifierInfo > ]
      #
      # Parameters:
      # * *iInstallerInfo* (_Object_): The installer info
      # Return:
      # * _DependencyDescription_: self, useful to concatenate such method calls
      def addInstallerInfo(iInstallerInfo)
        if (iInstallerInfo.is_a?(Array))
          lNewInstallerInfo = [ iInstallerInfo[0], iInstallerInfo[1], [] ]
          iInstallerInfo[2].each do |iContextModifierInfo|
            lNewInstallerInfo[2] << getContextModifierInfo(iContextModifierInfo)
          end
          @Installers << lNewInstallerInfo
        elsif (iInstallerInfo.is_a?(Hash))
          lNewInstallerInfo = [ iInstallerInfo[:Type], iInstallerInfo[:Content], [] ]
          iInstallerInfo[:ContextModifiers].each do |iContextModifierInfo|
            lNewInstallerInfo[2] << getContextModifierInfo(iContextModifierInfo)
          end
          @Installers << lNewInstallerInfo
        else
          logBug "Invalid InstallerInfo: #{iInstallerInfo.inspect}."
        end

        return self
      end

      private

      # Get the corresponding context modifier info
      # Here are the following formats accepted for each ContextModifier info:
      # * [ String, Object ]
      # * { :Type => String, :Content => Object }
      #
      # Parameters:
      # * *iContextModifierInfo* (_Object_): The context modifier info
      # Return:
      # * _Object_: The resulting context modifier info as stored internally
      def getContextModifierInfo(iContextModifierInfo)
        rContextModifierInfo = nil

        if (iContextModifierInfo.is_a?(Array))
          rContextModifierInfo = iContextModifierInfo
        elsif (iContextModifierInfo.is_a?(Hash))
          rContextModifierInfo = [ iContextModifierInfo[:Type], iContextModifierInfo[:Content] ]
        else
          logBug "Invalid ContextModifierInfo: #{iContextModifierInfo.inspect}."
        end

        return rContextModifierInfo
      end

    end

  end

end