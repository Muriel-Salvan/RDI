#--
# Copyright (c) 2009 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'rdi/Model/Installer'

module RDI

  module Installers

    class Yum < RDI::Model::Installer

      # Get the list of possible destinations
      #
      # Return:
      # * <em>list<[Integer,Object]></em>: The list of possible destinations and their corresponding installation location (or location selector name for DEST_OTHER)
      def getPossibleDestinations
        return [
          [ DEST_SYSTEM, '/' ]
        ]
      end

      # Install a dependency
      #
      # Parameters:
      # * *iContent* (_Object_): The dependency's content
      # * *iLocation* (_Object_): The installation location
      # * *ioInstallEnv* (<em>map<Symbol,Object></em>): The installed environment, that can be modified here. Stored variables will the be accessible to ContextModifiers. [optional = {}]
      # Return:
      # * _Exception_: The error, or nil in case of success
      def installDependency(iContent, iLocation, ioInstallEnv = {})
        # * *iContent* (_String_): The yum install command
        # * *iLocation* (_String_): The directory to install to
        rError = nil

        begin
          if (!system("yum -y -q install #{iContent}"))
            rError = RuntimeError.new("Execution of 'yum -y -q install #{iContent}' ended in error with code #{$?.exitstatus}.")
          end
        rescue Exception
          rError = $!
        end

        return rError
      end

    end

  end

end
