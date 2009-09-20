#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'rdi/Model/Tester'

module RDI

  module Testers

    # Test that some Exes are accessible
    class Binaries < RDI::Model::Tester

      # Give the name of possible ContextModifiers that might change the resolution of this Tester.
      # This is used to know what context modifiers the user can use to resolve dependencies without having to install.
      #
      # Return:
      # * <em>list<String></em>: The list of ContextModifiers names
      def getAffectingContextModifiers
        return [ 'SystemPath' ]
      end

      # Test if a given content is resolved
      #
      # Parameters:
      # * *iContent* (_Object_): The tester's content
      # Return:
      # * _Boolean_: Is the content resolved ?
      def isContentResolved?(iContent)
        # * *iContent* (<em>list<String></em>): The list of Exes to resolve (extensions might be guessed)
        rSuccess = false

        # For each required file, test that it exists among PATH
        iContent.each do |iExeName|
          $rUtilAnts_Platform_Info.getSystemExePath.each do |iDir|
            rSuccess = (!Dir.glob(File.expand_path("#{iDir}/#{iExeName}{,#{$rUtilAnts_Platform_Info.getDiscreteExeExtensions.join(',')}}")).empty?)
            if (rSuccess)
              # We found it. Don't try other paths.
              break
            end
          end
          if (!rSuccess)
            # We didn't find this exe. Don't try other requires.
            break
          end
        end

        return rSuccess
      end

    end

  end

end
