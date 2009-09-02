#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module RDI

  module Installers

    class Gem < RDI::Model::Installer

      # Get the list of possible destinations
      #
      # Return:
      # * <em>list<[Integer,Object]></em>: The list of possible destinations and their corresponding installation location (or location selector name for DEST_OTHER)
      def getPossibleDestinations
        return [
          [ DEST_LOCAL, @Installer.ExtDir ],
          [ DEST_SYSTEM, ::Gem.dir ],
          [ DEST_USER, ::Gem.user_dir ],
          [ DEST_TEMP, @Installer.TempDir ],
          [ DEST_OTHER, 'Directory' ]
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
        # * *iContent* (_String_): The gem install command
        # * *iLocation* (_String_): The directory to install to
        rError = nil

        # Load RubyGems
        require 'rubygems/command_manager'
        # Install
        begin
          ::Gem::CommandManager.instance.find_command('install').invoke(iContent, '-i', iLocation, '--no-rdoc', '--no-ri', '--no-test')
          ioInstallEnv[:InstallDir] = iLocation
        rescue ::Gem::SystemExitException
          # For RubyGems, this is normal behaviour: success results in an exception thrown with exit_code 0.
          if ($!.exit_code != 0)
            rError = $!
          end
        rescue Exception
          rError = $!
        end

        return rError
      end

    end

  end

end
