#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Testers

    # Test that some Ruby files are accessible
    class RubyRequires < RDI::Model::Tester

      # Give the name of possible ContextModifiers that might change the resolution of this Tester.
      # This is used to know what context modifiers the user can use to resolve dependencies without having to install.
      #
      # Return:
      # * <em>list<String></em>: The list of ContextModifiers names
      def getAffectingContextModifiers
        return [ 'GemPath', 'RubyLoadPath' ]
      end

      # Test if a given content is resolved
      #
      # Parameters:
      # * *iContent* (_Object_): The tester's content
      # Return:
      # * _Boolean_: Is the content resolved ?
      def isContentResolved?(iContent)
        # * *iContent* (<em>list<String></em>): The list of requires to resolve
        rSuccess = false

        # Handle RubyGems as an option
        if (defined?(Gem) == nil)
          # No RubyGem.
          # For each required file, test that it exists among $LOAD_PATH
          iContent.each do |iRequireName|
            lFileFilter = iRequireName
            if (File.extname(iRequireName).empty?)
              lFileFilter = "#{iRequireName}.{rb,so,o,sl,dll}"
            end
            rSuccess = false
            $LOAD_PATH.each do |iDir|
              rSuccess = (!Dir.glob(File.expand_path("#{iDir}/#{lFileFilter}")).empty?)
              if (rSuccess)
                # We found it. Don't try other paths.
                break
              end
            end
            if (!rSuccess)
              # We didn't find this require. Don't try other requires.
              break
            end
          end
        else
          # RubyGems is here. Use it.
          # For each required file, test that it exists among the RubyGems' loaded paths
          iContent.each do |iRequireName|
            rSuccess = (!Gem.find_files(iRequireName).empty?)
            if (!rSuccess)
              # We did not find this one: don't even try the next ones
              break
            end
          end
        end

        return rSuccess
      end

    end

  end

end
