# To change this template, choose Tools | Templates
# and open the template in the editor.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module CommonTools

  module URLAccess

    # Constants identifying which form is the content returned by URL handlers
    CONTENT_ERROR = 0
    CONTENT_REDIRECT = 1
    CONTENT_STRING = 2
    CONTENT_LOCALFILENAME = 3
    CONTENT_LOCALFILENAME_TEMPORARY = 4

    # Class
    class Manager

      # Constructor
      def initialize
        # Get the map of plugins to read URLs
        # map< String, [ list<Regexp>, String ] >
        # map< PluginName, [ List of matching regexps, Plugin class name ] >
        @Plugins = {}
        Dir.glob("#{File.dirname(__FILE__)}/URLHandlers/*.rb").each do |iFileName|
          begin
            lPluginName = File.basename(iFileName)[0..-4]
            require "CommonTools/URLHandlers/#{lPluginName}.rb"
            @Plugins[lPluginName] = [
              eval("CommonTools::URLCache::URLHandlers::#{lPluginName}::getMatchingRegexps"),
              "CommonTools::URLCache::URLHandlers::#{lPluginName}"
            ]
          rescue Exception
            logExc$!, "Error while requiring URLHandler plugin #{iFileName}"
          end
        end
      end

      # Access the content of a URL.
      # No cache.
      # It calls a code block with the binary content of the URL (or a local file name if required).
      #
      # Parameters:
      # * *iURL* (_String_): The URL (used to detect cyclic redirections)
      # * *iParameters* (<em>map<Symbol,Object></em>): Additional parameters:
      # ** *:ForceLoad* (_Boolean_): Do we force to refresh the cache ? [optional = false]
      # ** *:FollowRedirections* (_Boolean_): Do we follow redirections ? [optional = true]
      # ** *:NbrRedirectionsAllowed* (_Integer_): Number of redirections allowed [optional = 10]
      # ** *:LocalFileAccess* (_Boolean_): Do we need a local file to read the content from ? If not, the content itslef will be given the code block. [optional = false]
      # ** *:URLHandler* (_Object_): The URL handler, if it has already been instantiated, or nil otherwise [optional = nil]
      # * _CodeBlock_: The code returning the object corresponding to the content:
      # ** *iContent* (_String_): File content, or file name if :LocalFileAccess was true
      # ** *iFileBaseName* (_String_): The base name the file could have. Useful to get file name extensions.
      # ** Returns:
      # ** _Exception_: The error encountered, or nil in case of success
      def accessFile(iURL, iParameters = {})
        rError = nil

        lFollowRedirections = iParameters[:lFollowRedirections]
        lNbrRedirectionsAllowed = iParameters[:NbrRedirectionsAllowed]
        lLocalFileAccess = iParameters[:LocalFileAccess]
        lURLHandler = iParameters[:URLHandler]
        if (lFollowRedirections == nil)
          lFollowRedirections = true
        end
        if (lNbrRedirectionsAllowed == nil)
          lNbrRedirectionsAllowed = 10
        end
        if (lLocalFileAccess == nil)
          lLocalFileAccess = false
        end
        if (lURLHandler == nil)
          lURLHandler = getURLHandler(iURL)
        end
        # Get the content from the handler
        lContentFormat, lContent = lURLHandler.getContent(lFollowRedirections)
        case (lContentFormat)
        when CONTENT_ERROR
          rError = lContent
        when CONTENT_REDIRECT
          # Handle too much redirections (cycles)
          if (lContent.upcase == iURL.upcase)
            rError = RedirectionError.new("Redirecting to the same URL: #{iURL}")
          elsif (lNbrRedirectionsAllowed < 0)
            rError = RedirectionError.new("Too much URL redirections for URL: #{iURL} redirecting to #{lContent}")
          elsif (lFollowRedirections)
            # Follow the redirection if we want it
            lNewParameters = iParameters.clone
            lNewParameters[:NbrRedirectionsAllowed] = lNbrRedirectionsAllowed - 1
            # Reset the URL handler for the new parameters.
            lNewParameters[:URLHandler] = nil
            rError = accessFile(lContent, lNewParameters) do |iContent, iBaseName|
              yield(iContent, iBaseName)
            end
          else
            rError = RedirectionError.new("Received invalid redirection for URL: #{iURL}")
          end
        when CONTENT_STRING
          # The content is directly accessible.
          if (lLocalFileAccess)
            # Write the content in a local temporary file
            require 'tmpdir'
            lBaseName = lURLHandler.getCorrespondingFileBaseName
            lLocalFileName = "#{Dir.tmpdir}/URLCache/#{lBaseName}"
            begin
              FileUtils::mkdir_p(File.dirname(lLocalFileName))
              File.open(lLocalFileName, 'wb') do |oFile|
                oFile.write(lContent)
              end
            rescue Exception
              rError = $!
              lContent = nil
            end
            if (rError == nil)
              yield(lLocalFileName, lBaseName)
              # Delete the temporary file
              File.unlink(lLocalFileName)
            end
          else
            # Give it to the code block directly
            yield(lContent, lURLHandler.getCorrespondingFileBaseName)
          end
        when CONTENT_LOCALFILENAME, CONTENT_LOCALFILENAME_TEMPORARY
          lLocalFileName = lContent
          # The content is a local file name already accessible
          if (!lLocalFileAccess)
            # First, read the local file name
            begin
              File.open(lLocalFileName, 'rb') do |iFile|
                # Replace the file name with the real content
                lContent = iFile.read
              end
            rescue Exception
              rError = $!
            end
          end
          if (rError == nil)
            yield(lContent, lURLHandler.getCorrespondingFileBaseName)
          end
          # If the file was temporary, delete it
          if (lContentFormat == CONTENT_LOCALFILENAME_TEMPORARY)
            File.unlink(lLocalFileName)
          end
        end

        return rError
      end

      # Get the URL handler corresponding to this URL
      #
      # Parameters:
      # * *iURL* (_String_): The URL
      # Return:
      # * _Object_: The URL handler
      def getURLHandler(iURL)
        rURLHandler = nil

        # Try out every regexp unless it matches.
        # If none matches, assume a local file.
        @Plugins.each do |iPluginName, iPluginInfo|
          iRegexps, iPluginClassName = iPluginInfo
          iRegexps.each do |iRegexp|
            if (iRegexp.match(iURL) != nil)
              # Found a matching handler
              rURLHandler = eval("#{iPluginClassName}.new(iURL)")
              break
            end
          end
          if (rURLHandler != nil)
            break
          end
        end
        if (rURLHandler == nil)
          # Assume a local file
          rURLHandler = eval("#{@Plugins['LocalFile'][1]}.new(iURL)")
        end

        return rURLHandler
      end

    end

    # Initialize a global plugins cache
    def self.initializeURLAccess
      $CT_URLAccess_Manager = Manager.new
      Object.module_eval('include CommonTools::URLAccess')
    end

    # Access the content of a URL.
    # No cache.
    # It calls a code block with the binary content of the URL (or a local file name if required).
    #
    # Parameters:
    # * *iURL* (_String_): The URL (used to detect cyclic redirections)
    # * *iParameters* (<em>map<Symbol,Object></em>): Additional parameters:
    # ** *:ForceLoad* (_Boolean_): Do we force to refresh the cache ? [optional = false]
    # ** *:FollowRedirections* (_Boolean_): Do we follow redirections ? [optional = true]
    # ** *:NbrRedirectionsAllowed* (_Integer_): Number of redirections allowed [optional = 10]
    # ** *:LocalFileAccess* (_Boolean_): Do we need a local file to read the content from ? If not, the content itslef will be given the code block. [optional = false]
    # ** *:URLHandler* (_Object_): The URL handler, if it has already been instantiated, or nil otherwise [optional = nil]
    # * _CodeBlock_: The code returning the object corresponding to the content:
    # ** *iContent* (_String_): File content, or file name if :LocalFileAccess was true
    # ** *iFileBaseName* (_String_): The base name the file could have. Useful to get file name extensions.
    # ** Returns:
    # ** _Exception_: The error encountered, or nil in case of success
    def accessFile(iURL, iParameters = {})
      return $CT_URLAccess_Manager.accessFile(iURL, iParameters) do |iContent, iBaseName|
        yield(iContent, iBaseName)
      end
    end

    # Get the URL handler corresponding to this URL
    #
    # Parameters:
    # * *iURL* (_String_): The URL
    # Return:
    # * _Object_: The URL handler
    def getURLHandler(iURL)
      return $CT_URLAccess_Manager.getURLHandler(iURL)
    end

  end

end
