#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'rdi/Model/Installer'
require 'rUtilAnts/Misc'
RUtilAnts::Misc::install_misc_on_object

module RDI

  module Installers

    class DownloadAndInstall < RDI::Installers::Download

      # Install a dependency
      #
      # Parameters::
      # * *iContent* (_Object_): The dependency's content
      # * *iLocation* (_Object_): The installation location
      # * *ioInstallEnv* (<em>map<Symbol,Object></em>): The installed environment, that can be modified here. Stored variables will the be accessible to ContextModifiers. [optional = {}]
      # Return::
      # * _Exception_: The error, or nil in case of success
      def install_dependency(iContent, iLocation, ioInstallEnv = {})
        # * *iContent* (<em>[String,Proc]</em>): The URL and the code to install
        # * *iLocation* (_String_): The directory to install to
        rError = nil

        iURL, iCmdProc = iContent
        # First we download in a temp directory
        lTmpDir = "#{@Installer.TempDir}/DlAndInst"
        require 'fileutils'
        FileUtils::mkdir_p(lTmpDir)
        rError = super(iURL, lTmpDir)
        if (rError == nil)
          # And then we execute the command to install it
          change_dir(lTmpDir) do
            if (iCmdProc.call(iLocation))
              # Remove temporary directory
              FileUtils::rm_rf(lTmpDir)
              ioInstallEnv[:InstallDir] = iLocation
            else
              rError = RuntimeError.new('Installation code failed')
            end
          end
        end

        return rError
      end

    end

  end

end
