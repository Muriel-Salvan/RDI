#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module PBS

  module DependenciesLoader

    class DependenciesLoader

      # Adds a list of directories to the load path, ensuring no doublons
      #
      # Parameters:
      # *iDirsList* (<em>list<String></em>): The list of directories
      def addToLoadPath(iDirsList)
        $LOAD_PATH.replace(($LOAD_PATH + iDirsList).uniq)
      end

      # Get the list of local library directories:
      # * From the ext directory
      # * From the ext gems
      # * From declared directories in GEM_PATH
      #
      # Return:
      # * <em>list<String></em>: The list of directories
      def getLocalExternalLibDirs
        rList = []

        # Manually set libs in local PBS installation
        Dir.glob("#{$PBS_ExtDir}/*") do |iDir|
          if ((iDir != "#{$PBS_ExtDir}/gems") and
              (iDir != "#{$PBS_ExtDir}/libs") and
              (File.exists?("#{iDir}/lib")))
            rList << "#{iDir}/lib"
          end
        end
        # Manually set Gems in local PBS installation
        if (File.exists?($PBS_ExtGemsDir))
          Dir.glob("#{$PBS_ExtGemsDir}/gems/*") do |iDir|
            if (File.exists?("#{iDir}/lib"))
              rList << "#{iDir}/lib"
            end
          end
        end
        # Every directory from GEM_PATH if it exists
        # We do so as we don't want to depend on RubyGems.
        if (defined?(Gem))
          Gem.path.each do |iGemDir|
            if (File.exists?("#{iGemDir}/gems"))
              Dir.glob("#{iGemDir}/gems/*") do |iDir|
                if (File.exists?("#{iDir}/lib"))
                  rList << "#{iDir}/lib"
                end
              end
            end
          end
        end

        return rList
      end

      # Get the list of directories to parse for libraries (plugin dependencies).
      # Check for existence before return.
      # The list depends on options
      #
      # Return:
      # * <em>list<String></em>: The list of directories
      def getExternalLibDirs
        rList = getLocalExternalLibDirs

        # Every previously searched directory for this architecture
        if (@Options[:externalLibDirs][RUBY_PLATFORM] != nil)
          @Options[:externalLibDirs][RUBY_PLATFORM].each do |iDir|
            if (File.exists?("#{iDir}/lib"))
              rList << "#{iDir}/lib"
            end
          end
        end

        return rList.uniq
      end

      # Ensure RubyGems environment is loaded correctly
      #
      # Parameters:
      # * *iAcceptDialogs* (_Boolean_): Do we accept displaying dialogs ? This is used to indicate that this method is called without wxruby environment set up. [optional = true]
      # Return:
      # * _Boolean_: Is RubyGems loaded ?
      def ensureRubyGems(iAcceptDialogs = true)
        rSuccess = true

        # First ensure that RubyGems is up and running
        # This require is left here, as we don't want to need it if we don't call this method.
        begin
          require 'rubygems'
          require 'rubygems/command'
          require 'rubygems/remote_installer'
          require 'rubygems/gem_commands'
        rescue Exception
          # RubyGems is not installed (or badly installed).
          # Use our own installation of RubyGems
          # First, clean up possible symbols of previous RubyGems installations
          if (Kernel.method_defined?(:require_gem))
            Kernel.send(:remove_method, :require_gem)
          end
          if (Kernel.method_defined?(:gem))
            Kernel.send(:remove_method, :gem)
          end
          if (Object.const_defined?(:Gem))
            Object.send(:remove_const, :Gem)
          end
          # Test if gem_original_require exists
          begin
            gem_original_require
          rescue ArgumentError
            # It exists: reset the alias
            Kernel.send(:remove_method, :require)
            Kernel.module_eval('alias require gem_original_require')
          rescue Exception
            # Nothing to do
          end
          # Add our path to rubygems at the beginning of the load path
          $LOAD_PATH.replace(["#{$PBS_RootDir}/ext/rubygems"] + $LOAD_PATH)
          # Remove any required file from the require cache concerning rubygems
          $".delete_if do |iFileName|
            (iFileName.match(/^rubygems.*$/) != nil)
          end
          begin
            # Now we reload our version of RubyGems
            require 'rubygems'
            require 'rubygems/command'
            require 'rubygems/remote_installer'
            require 'rubygems/gem_commands'
          rescue Exception
            if (iAcceptDialogs)
              logExc $!, 'PBS installation of RubyGems could not get required'
            else
              if ($PBS_ScreenOutputErr)
                $stderr << "PBS installation of RubyGems could not get required: #{$!}.\nException stack:\n#{$!.backtrace.join("\n")}\n"
              end
            end
            rSuccess = false
          end
        end

        return rSuccess
      end

      # Ensure that WxRuby is up and running in our environment
      # This method uses sendMsg method to notify the user. This method has to be defined by the caller.
      #
      # Return:
      # * _Boolean_: Is WxRuby loaded ?
      def ensureWxRuby
        rSuccess = true

        begin
          require 'wx'
        rescue Exception
          # Try to check all paths to load for libs
          addToLoadPath(getLocalExternalLibDirs)
          begin
            require 'wx'
          rescue Exception
            rSuccess = false
            # We need to download wxruby gem
            if (ensureRubyGems(false))
              # Now we want to install the Gem
              $PBS_Platform.sendMsg("WxRuby is not part of this PBS installation.\nInstalling WxRuby will begin after this message, and will take around 10 Mb.\nYou will be notified once it is completed.")
              rSuccess = installGem($PBS_ExtGemsDir, 'wxruby --version 2.0.0', nil, false)
              if (rSuccess)
                # Add the path again
                addToLoadPath(getLocalExternalLibDirs)
                begin
                  require 'wx'
                rescue Exception
                  $PBS_Platform.sendMsg("WxRuby could not be installed (#{$!}).\nPlease install WxRuby manually in PBS local installation, or reinstall PBS completely.")
                end
                $PBS_Platform.sendMsg("WxRuby has been successfully installed.\nPBS will start after this message.")
              else
                $PBS_Platform.sendMsg("WxRuby could not be installed.\nPlease install WxRuby manually in PBS local installation, or reinstall PBS completely.")
              end
            else
              $PBS_Platform.sendMsg("Unable to install RubyGems.\nPlease download WxRuby manually in PBS local installation, or reinstall PBS completely.")
            end
          end
        end

        return rSuccess
      end

    end

  end

end

