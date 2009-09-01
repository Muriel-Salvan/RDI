#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module CommonTools

  module URLCache

    module URLHandlers

      # Handler of FTP URLs
      class FTP

        # Get a list of regexps matching the URL to get to this handler
        #
        # Return:
        # * <em>list<Regexp></em>: The list of regexps matching URLs from this handler
        def self.getMatchingRegexps
          return [
            /^(ftp|ftps):\/\/.*$/
          ]
        end

        # Constructor
        #
        # Parameters:
        # * *iURL* (_String_): The URL that this handler will manage
        def initialize(iURL)
          @URL = iURL
          lURLMatch = iURL.match(/^(ftp|ftps):\/\/([^\/]*)\/(.*)$/)
          if (lURLMatch == nil)
            lURLMatch = iURL.match(/^(ftp|ftps):\/\/(.*)$/)
          end
          if (lURLMatch == nil)
            logBug "URL #{iURL} was identified as an ftp like, but it appears to be false."
          else
            @URLProtocol, @URLServer, @URLPath = lURLMatch[1..3]
          end
        end

        # Get the server ID
        #
        # Return:
        # * _String_: The server ID
        def getServerID
          return "#{@URLProtocol}://#{@URLServer}"
        end

        # Get the current CRC of the URL
        #
        # Return:
        # * _Integer_: The CRC
        def getCRC
          # We consider FTP URLs to be definitive: CRCs will never change.
          return 0
        end

        # Get a corresponding file base name.
        # This method has to make sure file extensions are respected, as it can be used for further processing.
        #
        # Return:
        # * _String_: The file name
        def getCorrespondingFileBaseName
          lBase = File.basename(@URLPath)
          lExt = File.extname(@URLPath)
          lFileName = nil
          if (lExt.empty?)
            lFileName = lBase
          else
            # Check that extension has no characters following the URL (#, ? and ;)
            lBase = lBase[0..lBase.size-lExt.size-1]
            lFileName = "#{lBase}#{lExt.gsub(/^([^#\?;]*).*$/,'\1')}"
          end

          return getValidFileName(lFileName)
        end

        # Get the content of the URL
        #
        # Parameters:
        # * *iFollowRedirections* (_Boolean_): Do we follow redirections while accessing the content ?
        # Return:
        # * _Integer_: Type of content returned
        # * _Object_: The content, depending on the type previously returned:
        # ** _Exception_ if CONTENT_ERROR: The corresponding error
        # ** _String_ if CONTENT_REDIRECT: The new URL
        # ** _String_ if CONTENT_STRING: The real content
        # ** _String_ if CONTENT_LOCALFILENAME: The name of the local file name storing the content
        # ** _String_ if CONTENT_LOCALFILENAME_TEMPORARY: The name of the temporary local file name storing the content
        def getContent(iFollowRedirections)
          rContentFormat = nil
          rContent = nil

          begin
            lFTPConnection = Net::FTP.new(@URLServer)
            lFTPConnection.login
            lFTPConnection.chdir(File.dirname(@URLPath))
            rContent = getCorrespondingFileBaseName
            rContentFormat = CONTENT_LOCALFILENAME_TEMPORARY
            logDebug "URL #{@URL} => Temporary file #{rContent}"
            lFTPConnection.getbinaryfile(File.basename(@URLPath), rContent)
            lFTPConnection.close
          rescue Exception
            rContent = $!
            rContentFormat = CONTENT_ERROR
            logDebug "Error accessing #{@URL}: #{rContent}"
          end

          return rContentFormat, rContent
        end

      end

    end

  end

end