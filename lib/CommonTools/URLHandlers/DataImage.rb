#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module CommonTools

  module URLCache

    module URLHandlers

      # Handler of data:image URIs
      class DataImage

        # Get a list of regexps matching the URL to get to this handler
        #
        # Return:
        # * <em>list<Regexp></em>: The list of regexps matching URLs from this handler
        def self.getMatchingRegexps
          return [
            /^data:image.*$/
          ]
        end

        # Constructor
        #
        # Parameters:
        # * *iURL* (_String_): The URL that this handler will manage
        def initialize(iURL)
          @URL = iURL
          lMatchData = @URL.match(/data:image\/(.*);base64,(.*)/)
          if (lMatchData == nil)
            logBug "URL #{iURL[0..23]}... was identified as a data:image like, but it appears to be false."
          else
            @Ext = lMatchData[1]
            if (@Ext == 'x-icon')
              @Ext = 'ico'
            end
            @Data = lMatchData[2]
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
          # As the content is in the URL, it will be natural to not find it anymore in the cache when it is changed.
          # Therefore there is no need to return a CRC.
          return 0
        end

        # Get a corresponding file base name.
        # This method has to make sure file extensions are respected, as it can be used for further processing.
        #
        # Return:
        # * _String_: The file name
        def getCorrespondingFileBaseName
          return "DataImage.#{@Ext}"
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

          # Here we unpack the string in a base64 encoding.
          if (@Data.empty?)
            rContent = RuntimeError.new("Empty URI to decode: #{@URL}")
            rContentFormat = CONTENT_ERROR
          else
            rContent = @Data.unpack('m')[0]
            rContentFormat = CONTENT_STRING
          end

          return rContentFormat, rContent
        end

      end

    end

  end

end