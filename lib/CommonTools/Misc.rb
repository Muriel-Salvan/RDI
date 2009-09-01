#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module CommonTools

  module Misc

    # Set these methods into the Kernel namespace
    def self.initializeMisc
      Object.module_eval('include CommonTools::Misc')
    end

    # Get a valid file name, taking into account platform specifically prohibited characters in file names.
    #
    # Parameters:
    # * *iFileName* (_String_): The original file name wanted
    # Return:
    # * _String_: The correct file name
    def getValidFileName(iFileName)
      if ((defined?($CT_Platform_Info) != nil))
        return iFileName.gsub(/[#{Regexp.escape($CT_Platform_Info.getProhibitedFileNamesCharacters)}]/, '_')
      else
        return iFileName
      end
    end

    # Extract a Zip archive in a given system dependent lib sub-directory
    #
    # Parameters:
    # * *iZipFileName* (_String_): The zip file name to extract content from
    # * *iDirName* (_String_): The name of the directory to store the zip to
    # Return:
    # * _Boolean_: Success ?
    def extractZipFile(iZipFileName, iDirName)
      rSuccess = true

      # Extract content of iFileName to #{$PBS_ExtDllsDir}/#{iLibName}
      begin
        # We don't put this require in the global scope as it needs first a DLL to be loaded by plugins
        # TODO: Use RDI if possible to ensure the dependency
        require 'zip/zipfilesystem'
        Zip::ZipInputStream::open(iZipFileName) do |iZipFile|
          while (lEntry = iZipFile.get_next_entry)
            lDestFileName = "#{iDirName}/#{lEntry.name}"
            if (lEntry.directory?)
              FileUtils::mkdir_p(lDestFileName)
            else
              FileUtils::mkdir_p(File.dirname(lDestFileName))
              lEntry.extract(lDestFileName)
            end
          end
        end
      rescue Exception
        logExc $!, "Exception while unzipping #{iZipFileName} into #{iDirName}"
        rSuccess = false
      end

      return rSuccess
    end

  end

end