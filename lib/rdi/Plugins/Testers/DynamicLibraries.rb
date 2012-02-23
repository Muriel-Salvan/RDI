#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'rdi/Model/Tester'

module RDI

  module Testers

    # Test that some DLLs are accessible
    class DynamicLibraries < RDI::Model::Tester

      # Give the name of possible ContextModifiers that might change the resolution of this Tester.
      # This is used to know what context modifiers the user can use to resolve dependencies without having to install.
      #
      # Return::
      # * <em>list<String></em>: The list of ContextModifiers names
      def get_affecting_context_modifiers
        return [ 'LibraryPath' ]
      end

      # Test if a given content is resolved
      #
      # Parameters::
      # * *iContent* (_Object_): The tester's content
      # Return::
      # * _Boolean_: Is the content resolved ?
      def is_content_resolved?(iContent)
        # * *iContent* (<em>list<String></em>): The list of DLLs to resolve
        rSuccess = false

        # For each required file, test that it exists among $LOAD_PATH
        iContent.each do |iDLLName|
          getSystemLibsPath.each do |iDir|
            rSuccess = File.exists?("#{iDir}/#{iDLLName}")
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

        return rSuccess
      end

    end

  end

end
