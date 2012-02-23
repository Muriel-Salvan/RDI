#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'rdi/Model/Installer'

module RDI

  module Installers

    class Download < RDI::Model::Installer

      # Get the list of possible destinations
      #
      # Return::
      # * <em>list< [Integer,Object] ></em>: The list of possible destinations and their corresponding installation location (or location selector name for DEST_OTHER)
      def get_possible_destinations
        return [
          [ DEST_LOCAL, "#{@Installer.ExtDir}/Downloads" ],
          [ DEST_SYSTEM, @Installer.SystemDir ],
          [ DEST_USER, @Installer.UserDir ],
          [ DEST_TEMP, @Installer.TempDir ],
          [ DEST_OTHER, 'Directory' ]
        ]
      end

      # Install a dependency
      #
      # Parameters::
      # * *iContent* (_Object_): The dependency's content
      # * *iLocation* (_Object_): The installation location
      # * *ioInstallEnv* (<em>map<Symbol,Object></em>): The installed environment, that can be modified here. Stored variables will the be accessible to ContextModifiers. [optional = {}]
      # Return::
      # * _Exception_: The error, or nil in case of success
      def install_dependency(iContent, iLocation, ioInstallEnv = {})
        # * *iContent* (_String_): The URL
        # * *iLocation* (_String_): The directory to install to
        rError = nil

        # Download the URL
        # The URL can be a zip file, a targz, a direct file ...
        # Don't use URL caching.
        access_file(iContent, :local_file_access => true) do |iLocalFileName, iBaseName|
          case File.extname(iLocalFileName).upcase
          when '.ZIP'
            # Unzip before
            rError = extract_zip_file(iLocalFileName, iLocation)
            if (rError != nil)
              rError = RuntimeError.new("Error while unzipping from #{iLocalFileName} to #{iLocation}:\n#{rError}")
            end
          # TODO: Handle targz, bz...
          else
            # Just copy
            begin
              FileUtils::mkdir_p(iLocation)
              FileUtils::cp(iLocalFileName, "#{iLocation}/#{File.basename(iLocalFileName)}")
            rescue Exception
              rError = $!
            end
          end
          ioInstallEnv[:InstallDir] = iLocation
        end

        return rError
      end

    end

  end

end
