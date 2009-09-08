#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

# This file declares modules that might be shared across several projects.

module CommonTools

  module Logging

    # The logger class singleton
    class Logger

      # Constructor
      #
      # Parameters:
      # * *iLibRootDir* (_String_): The library root directory that will not appear in the logged stack messages
      # * *iBugTrackerURL* (_String_): The application's bug tracker URL, used to report bugs
      # * *iSilentOutputs* (_Boolean_): Do we silent outputs (nothing sent to $stdout or $stderr) ? [optional = false]
      def initialize(iLibRootDir, iBugTrackerURL, iSilentOutputs = false)
        @LibRootDir, @BugTrackerURL = iLibRootDir, iBugTrackerURL
        @DebugMode = false
        @LogFile = nil
        @ErrorsStack = nil
        @MessagesStack = nil
        @ScreenOutput = (!iSilentOutputs)
        @ScreenOutputErr = (!iSilentOutputs)
        if (!iSilentOutputs)
          # Test if we can write to stdout
          begin
            $stdout << "Launch Logging - stdout\n"
          rescue Exception
            # Redirect to a file if possible
            begin
              redirectStdOutToFile('./stdout')
              $stdout << "Launch Logging - stdout\n"
            rescue Exception
              # Disable
              @ScreenOutput = false
            end
          end
          # Test if we can write to stderr
          begin
            $stderr << "Launch Logging - stderr\n"
          rescue Exception
            # Redirect to a file if possible
            begin
              redirectStdErrToFile('./stderr')
              $stderr << "Launch Logging - stderr\n"
            rescue Exception
              # Disable
              @ScreenOutputErr = false
            end
          end
        end
      end

      # Redirect $stdout to a file
      #
      # Parameters:
      # * *iFileName* (_String_): File name to redirect $stdout to
      def redirectStdOutToFile(iFileName)
        lFile = File.open(iFileName, 'w')
        $stdout.reopen(lFile)
      end

      # Redirect $stderr to a file
      #
      # Parameters:
      # * *iFileName* (_String_): File name to redirect $stderr to
      def redirectStdErrToFile(iFileName)
        lFile = File.open(iFileName, 'w')
        $stderr.reopen(lFile)
      end

      # Set the debug mode
      #
      # Parameters:
      # * *iDebugMode* (_Boolean_): Are we in debug mode ?
      def activateLogDebug(iDebugMode)
        @DebugMode = iDebugMode
        if (iDebugMode)
          logInfo 'Activated log debug'
        else
          logInfo 'Deactivated log debug'
        end
      end

      # Set the stack of the errors to fill.
      # If set to nil, errors will be displayed as they appear.
      # If set to a stack, errors will silently be added to the list.
      #
      # Parameters:
      # * *iErrorsStack* (<em>list<String></em>): The stack of errors, or nil to unset it
      def setLogErrorsStack(iErrorsStack)
        @ErrorsStack = iErrorsStack
      end

      # Set the stack of the messages to fill.
      # If set to nil, messages will be displayed as they appear.
      # If set to a stack, messages will silently be added to the list.
      #
      # Parameters:
      # * *iMessagesStack* (<em>list<String></em>): The stack of messages, or nil to unset it
      def setLogMessagesStack(iMessagesStack)
        @MessagesStack = iMessagesStack
      end

      # Log an exception
      # This is called when there is a bug due to an exception in the program. It has been set in many places to detect bugs.
      #
      # Parameters:
      # * *iException* (_Exception_): Exception
      # * *iMsg* (_String_): Message to log
      def logExc(iException, iMsg)
        logBug("#{iMsg}
Exception: #{iException}
Exception stack:
#{getSimpleCaller(iException.backtrace, caller).join("\n")}
...")
      end

      # Log a bug
      # This is called when there is a bug in the program. It has been set in many places to detect bugs.
      #
      # Parameters:
      # * *iMsg* (_String_): Message to log
      def logBug(iMsg)
        lCompleteMsg = "Bug: #{iMsg}
Stack:
#{getSimpleCaller(caller[0..-2]).join("\n")}"
        # Log into stderr
        if (@ScreenOutputErr)
          $stderr << "!!! BUG !!! #{lCompleteMsg}\n"
        end
        if (@LogFile != nil)
          logFile(lCompleteMsg)
        end
        # Display Bug dialog
        # Call it only if showModal exists
        if (defined?(showModal) == nil)
          # Use normal platform dependent message, if the platform has been initialized (otherwise, stick to $stderr)
          if (defined?($CT_Platform_Info) != nil)
            $CT_Platform_Info.sendMsg("A bug has just occurred.
Normally you should never see this message, but this application is not bug-less.
We are sorry for the inconvenience caused.
If you want to help improving this application, please inform us of this bug:
take the time to open a ticket at the bugs tracker.
We will always try our best to correct bugs.
Thanks.

Details:
#{lCompleteMsg}
")
          end
        else
          # We require the file here, as we hope it will not be required often
          require 'CommonTools/GUI/BugReportDialog.rb'
          showModal(GUI::BugReportDialog, nil, lCompleteMsg, @BugTrackerURL) do |iModalResult, iDialog|
            # Nothing to do
          end
        end
      end

      # Log an error.
      # Those errors can be normal, as they mainly depend on external factors (lost connection, invalid user file...)
      #
      # Parameters:
      # * *iMsg* (_String_): Message to log
      def logErr(iMsg)
        # Log into stderr
        if (@ScreenOutputErr)
          $stderr << "!!! ERR !!! #{iMsg}\n"
        end
        if (@LogFile != nil)
          logFile(iMsg)
        end
        # Display dialog only if we are not redirecting messages to a stack
        if (@ErrorsStack == nil)
          if (defined?(showModal) == nil)
            # Use normal platform dependent message, if the platform has been initialized (otherwise, stick to $stderr)
            if (defined?($CT_Platform_Info) != nil)
              $CT_Platform_Info.sendMsg(iMsg)
            end
          else
            showModal(Wx::MessageDialog, nil,
              iMsg,
              :caption => 'Error',
              :style => Wx::OK|Wx::ICON_ERROR
            ) do |iModalResult, iDialog|
              # Nothing to do
            end
          end
        else
          @ErrorsStack << iMsg
        end
      end

      # Log a normal message to the user
      # This is used to display a simple message to the user
      #
      # Parameters:
      # * *iMsg* (_String_): Message to log
      def logMsg(iMsg)
        # Log into stderr
        if (@ScreenOutput)
          $stdout << "#{iMsg}\n"
        end
        if (@LogFile != nil)
          logFile(iMsg)
        end
        # Display dialog only if we are not redirecting messages to a stack
        if (@MessagesStack == nil)
          # Display dialog
          if (defined?(showModal) == nil)
            # Use normal platform dependent message, if the platform has been initialized (otherwise, stick to $stderr)
            if (defined?($CT_Platform_Info) != nil)
              $CT_Platform_Info.sendMsg(iMsg)
            end
          else
            showModal(Wx::MessageDialog, nil,
              iMsg,
              :caption => 'Notification',
              :style => Wx::OK|Wx::ICON_INFORMATION
            ) do |iModalResult, iDialog|
              # Nothing to do
            end
          end
        else
          @MessagesStack << iMsg
        end
      end

      # Log an info.
      # This is just common journal.
      #
      # Parameters:
      # * *iMsg* (_String_): Message to log
      def logInfo(iMsg)
        # Log into stdout
        if (@ScreenOutput)
          $stdout << "#{iMsg}\n"
        end
        if (@LogFile != nil)
          logFile(iMsg)
        end
      end

      # Log a debugging info.
      # This is used when debug is activated
      #
      # Parameters:
      # * *iMsg* (_String_): Message to log
      def logDebug(iMsg)
        # Log into stdout
        if ((@DebugMode) and
            (@ScreenOutput))
          $stdout << "#{iMsg}\n"
        end
        if (@LogFile != nil)
          logFile(iMsg)
        end
      end

      private

      # Log a message in the log file
      #
      # Parameters:
      # * *iMsg* (_String_): The message to log
      def logFile(iMsg)
        File.open(@LogFile, 'a+') do |oFile|
          oFile << "#{Time.now.gmtime.strftime('%Y/%m/%d %H:%M:%S')} - #{iMsg}\n"
        end
      end

      # Get a stack trace in a simple format:
      # Remove @LibRootDir paths from it.
      #
      # Parameters:
      # * *iCaller* (<em>list<String></em>): The caller
      # * *iReferenceCaller* (<em>list<String></em>): The reference caller: we will not display lines from iCaller that also belong to iReferenceCaller [optional = nil]
      # Return:
      # * <em>list<String></em>): The simple stack
      def getSimpleCaller(iCaller, iReferenceCaller = nil)
        rSimpleCaller = []

        lCaller = nil
        # If there is a reference caller, remove the lines from lCaller that are also in iReferenceCaller
        if (iReferenceCaller == nil)
          lCaller = iCaller
        else
          lIdxCaller = iCaller.size - 1
          lIdxRef = iReferenceCaller.size - 1
          while ((lIdxCaller >= 0) and
                 (lIdxRef >= 0) and
                 (iCaller[lIdxCaller] == iReferenceCaller[lIdxRef]))
            lIdxCaller -= 1
            lIdxRef -= 1
          end
          # Here we have either one of the indexes that is -1, or the indexes point to different lines between the caller and its reference.
          lCaller = iCaller[0..lIdxCaller+1]
        end
        lCaller.each do |iCallerLine|
          lMatch = iCallerLine.match(/^(.*):([[:digit:]]*):in (.*)$/)
          if (lMatch == nil)
            # Did not get which format. Just add it blindly.
            rSimpleCaller << iCallerLine
          else
            rSimpleCaller << "#{File.expand_path(lMatch[1]).gsub(@LibRootDir, '')}:#{lMatch[2]}:in #{lMatch[3]}"
          end
        end

        return rSimpleCaller
      end

    end

    # The following methods are meant to be included in a class to be easily useable.

    # Initialize the logging features
    #
    # Parameters:
    # * *iLibRootDir* (_String_): The library root directory that will not appear in the logged stack messages
    # * *iBugTrackerURL* (_String_): The application's bug tracker URL, used to report bugs
    # * *iSilentOutputs* (_Boolean_): Do we silent outputs (nothing sent to $stdout or $stderr) ? [optional = false]
    def self.initializeLogging(iLibRootDir, iBugTrackerURL, iSilentOutputs = false)
      $CT_Logging_Logger = CommonTools::Logging::Logger.new(iLibRootDir, iBugTrackerURL, iSilentOutputs)
      # Add the module accessible from the Kernel
      Object.module_eval('include CommonTools::Logging')
    end

    # Set the debug mode
    #
    # Parameters:
    # * *iDebugMode* (_Boolean_): Are we in debug mode ?
    def activateLogDebug(iDebugMode)
      $CT_Logging_Logger.activateLogDebug(iDebugMode)
    end

    # Set the stack of the errors to fill.
    # If set to nil, errors will be displayed as they appear.
    # If set to a stack, errors will silently be added to the list.
    #
    # Parameters:
    # * *iErrorsStack* (<em>list<String></em>): The stack of errors, or nil to unset it
    def setLogErrorsStack(iErrorsStack)
      $CT_Logging_Logger.setLogErrorsStack(iErrorsStack)
    end

    # Set the stack of the messages to fill.
    # If set to nil, messages will be displayed as they appear.
    # If set to a stack, messages will silently be added to the list.
    #
    # Parameters:
    # * *iMessagesStack* (<em>list<String></em>): The stack of messages, or nil to unset it
    def setLogMessagesStack(iMessagesStack)
      $CT_Logging_Logger.setLogMessagesStack(iMessagesStack)
    end

    # Log an exception
    # This is called when there is a bug due to an exception in the program. It has been set in many places to detect bugs.
    #
    # Parameters:
    # * *iException* (_Exception_): Exception
    # * *iMsg* (_String_): Message to log
    def logExc(iException, iMsg)
      $CT_Logging_Logger.logExc(iException, iMsg)
    end

    # Log a bug
    # This is called when there is a bug in the program. It has been set in many places to detect bugs.
    #
    # Parameters:
    # * *iMsg* (_String_): Message to log
    def logBug(iMsg)
      $CT_Logging_Logger.logBug(iMsg)
    end

    # Log an error.
    # Those errors can be normal, as they mainly depend on external factors (lost connection, invalid user file...)
    #
    # Parameters:
    # * *iMsg* (_String_): Message to log
    def logErr(iMsg)
      $CT_Logging_Logger.logErr(iMsg)
    end

    # Log a normal message to the user
    # This is used to display a simple message to the user
    #
    # Parameters:
    # * *iMsg* (_String_): Message to log
    def logMsg(iMsg)
      $CT_Logging_Logger.logMsg(iMsg)
    end

    # Log an info.
    # This is just common journal.
    #
    # Parameters:
    # * *iMsg* (_String_): Message to log
    def logInfo(iMsg)
      $CT_Logging_Logger.logInfo(iMsg)
    end

    # Log a debugging info.
    # This is used when debug is activated
    #
    # Parameters:
    # * *iMsg* (_String_): Message to log
    def logDebug(iMsg)
      $CT_Logging_Logger.logDebug(iMsg)
    end

  end

end