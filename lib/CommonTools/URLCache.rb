#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module CommonTools

  module URLCache

    # Class that caches every access to a URI (local file name, http, data...).
    # This ensures just that several files are instantiated just once.
    # For local files, it takes into account the file modification date/time to know if the Wx::Bitmap file has to be refreshed.
    class URLCache

      # Exception for reporting server down errors.
      class ServerDownError < RuntimeError
      end

      # Constructor
      def initialize
        # Map of known contents, interpreted in many flavors
        # map< Integer, [ Integer, Object ] >
        # map< URL's hash, [ CRC, Content ] >
        @URLs = {}
        # Map of hosts down (no need to try again such a host)
        # map< String >
        @HostsDown = {}
      end

      # Get a content from a URL.
      # Here are the different formats the URL can have:
      # * Local file name
      # * http/https/ftp/ftps:// protocols
      # * data:image URI
      # * file:// protocol
      # It also handles redirections or zipped files
      #
      # Parameters:
      # * *iURL* (_String_): The URL
      # * *iParameters* (<em>map<Symbol,Object></em>): Additional parameters:
      # ** *:ForceLoad* (_Boolean_): Do we force to refresh the cache ? [optional = false]
      # ** *:FollowRedirections* (_Boolean_): Do we follow redirections ? [optional = true]
      # ** *:NbrRedirectionsAllowed* (_Integer_): Number of redirections allowed [optional = 10]
      # ** *:LocalFileAccess* (_Boolean_): Do we need a local file to read the content from ? If not, the content itslef will be given the code block. [optional = false]
      # * _CodeBlock_: The code returning the object corresponding to the content:
      # ** *iContent* (_String_): File content, or file name if :LocalFileAccess was true
      # ** Returns:
      # ** _Object_: Object read from the content, or nil in case of error
      # ** _Exception_: The error encountered, or nil in case of success
      # Return:
      # * <em>Object</em>: The corresponding URL content, or nil in case of failure
      # * _Exception_: The error, or nil in case of success
      def getURLContent(iURL, iParameters = {})
        rObject = nil
        rError = nil

        # Parse parameters
        lForceLoad = iParameters[:ForceLoad]
        if (lForceLoad == nil)
          lForceLoad = false
        end
        # Get the URL handler corresponding to this URL
        lURLHandler = getURLHandler(iURL)
        lServerID = lURLHandler.getServerID
        if (@HostsDown.has_key?(lServerID))
          rError = ServerDownError.new("Server #{iURL} is currently down.")
        else
          lURLHash = iURL.hash
          # Check if it is in the cache, or if we force refresh, or if the URL was invalidated
          lCurrentCRC = lURLHandler.getCRC
          if ((@URLs[lURLHash] == nil) or
              (lForceLoad) or
              (@URLs[lURLHash][0] != lCurrentCRC))
            # Load it for real
            # Reset previous value if it was set
            @URLs[lURLHash] = nil
            # Get the object
            lObject = nil
            lAccessError = accessFile(iURL, iParameters.merge(:URLHandler => iURL)) do |iContent, iBaseName|
              lObject, rError = yield(iContent)
            end
            if (lAccessError != nil)
              rError = lAccessError
            end
            # Put lObject in the cache if no error was found
            if (rError == nil)
              # OK, register it
              @URLs[lURLHash] = [ lCurrentCRC, lObject ]
            elsif (rError.is_a?(SocketError))
              # We have a server down
              @HostsDown[lServerID] = nil
            end
          end
          # If no error was found (errors can only happen if it was not already in the cache), take it from the cache
          if (rError == nil)
            rObject = @URLs[lURLHash][1]
          end
        end

        return rObject, rError
      end

    end

    # Initialize a global cache
    def self.initializeURLCache
      $CT_URLCache = URLCache.new
      Object.module_eval('include CommonTools::URLCache')
    end

    # Get a content from a URL.
    # Here are the different formats the URL can have:
    # * Local file name
    # * http/https/ftp/ftps:// protocols
    # * data:image URI
    # * file:// protocol
    # It also handles redirections or zipped files
    #
    # Parameters:
    # * *iURL* (_String_): The URL
    # * *iParameters* (<em>map<Symbol,Object></em>): Additional parameters:
    # ** *:ForceLoad* (_Boolean_): Do we force to refresh the cache ? [optional = false]
    # ** *:FollowRedirections* (_Boolean_): Do we follow redirections ? [optional = true]
    # ** *:NbrRedirectionsAllowed* (_Integer_): Number of redirections allowed [optional = 10]
    # ** *:LocalFileAccess* (_Boolean_): Do we need a local file to read the content from ? If not, the content itslef will be given the code block. [optional = false]
    # * _CodeBlock_: The code returning the object corresponding to the content:
    # ** *iContent* (_String_): File content, or file name if :LocalFileAccess was true
    # ** Returns:
    # ** _Object_: Object read from the content, or nil in case of error
    # ** _Exception_: The error encountered, or nil in case of success
    # Return:
    # * <em>Object</em>: The corresponding URL content, or nil in case of failure
    # * _Exception_: The error, or nil in case of success
    def getURLContent(iURL, iParameters = {})
      return $CT_URLCache.getURLContent(iURL, iParameters) do |iContent|
        next yield(iContent)
      end
    end

  end

end
