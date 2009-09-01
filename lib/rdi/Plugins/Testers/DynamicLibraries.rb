#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Testers

    # Test that some DLLs are accessible
    class DynamicLibraries

      # Test if a given content is resolved
      #
      # Parameters:
      # * *iContent* (_Object_): The tester's content
      # Return:
      # * _Boolean_: Is the content resolved ?
      def isContentResolved?(iContent)
        # * *iContent* (<em>list<String></em>): The list of DLLs to resolve
        rSuccess = false

        # For each required file, test that it exists among $LOAD_PATH
        iContent.each do |iDLLName|
          $CT_Platform_Info.getSystemLibsPath.each do |iDir|
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
