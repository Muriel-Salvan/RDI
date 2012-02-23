#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
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
      # Return::
      # * <em>list<String></em>: The list of ContextModifiers names
      def get_affecting_context_modifiers
        return [ 'SystemPath' ]
      end

      # Test if a given content is resolved
      #
      # Parameters::
      # * *iContent* (_Object_): The tester's content
      # Return::
      # * _Boolean_: Is the content resolved ?
      def is_content_resolved?(iContent)
        # * *iContent* (<em>list<String></em>): The list of Exes to resolve (extensions might be guessed)
        rSuccess = false

        # For each required file, test that it exists among PATH
        iContent.each do |iExeName|
          getSystemExePath.each do |iDir|
            rSuccess = (!Dir.glob(File.expand_path("#{iDir}/#{iExeName}{,#{getDiscreteExeExtensions.join(',')}}")).empty?)
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
