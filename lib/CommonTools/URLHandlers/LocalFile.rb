#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module CommonTools

  module URLCache

    module URLHandlers

      # Handler of file URLs
      class LocalFile

        # Get a list of regexps matching the URL to get to this handler
        #
        # Return:
        # * <em>list<Regexp></em>: The list of regexps matching URLs from this handler
        def self.getMatchingRegexps
          return [
            /^file:\/\/\/(.*)$/
          ]
        end

        # Constructor
        #
        # Parameters:
        # * *iURL* (_String_): The URL that this handler will manage
        def initialize(iURL)
          @URL = iURL
          lURLMatch = iURL.match(/^file:\/\/([^\/]*)\/(.*)$/)
          if (lURLMatch != nil)
            @URL = lURLMatch[1]
          end
        end

        # Get the server ID
        #
        # Return:
        # * _String_: The server ID
        def getServerID
          return nil
        end

        # Get the current CRC of the URL
        #
        # Return:
        # * _Integer_: The CRC
        def getCRC
          # We consider the file's modification time
          if (File.exists?(@URL))
            return File.mtime(@URL)
          else
            return 0
          end
        end

        # Get a corresponding file base name.
        # This method has to make sure file extensions are respected, as it can be used for further processing.
        #
        # Return:
        # * _String_: The file name
        def getCorrespondingFileBaseName
          return File.basename(@URL)
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

          if (File.exists?(@URL))
            rContent = @URL
            rContentFormat = CONTENT_LOCALFILENAME
          else
            rContent = Errno::ENOENT.new(@URL)
            rContentFormat = CONTENT_ERROR
          end

          return rContentFormat, rContent
        end

      end

    end

  end

end