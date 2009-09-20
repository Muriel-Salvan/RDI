#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module Gem

  class GemPathList < Array

    # Add a path to the list
    #
    # Parameters:
    # * *iDirName* (_String_): Directory to add to the list
    def <<(iDirName)
      # Add the path for real in the internals
      super
      # Add the lib directory if it is already initialized
      if ((defined?(@LibDirs) != nil) and
          (@LibDirs != nil))
        Dir.glob("#{iDirName}/gems/*").each do |iGemDirName|
          if (File.exists?("#{iGemDirName}/lib"))
            @LibDirs << iGemDirName
          end
        end
      end
      # Add the path in RubyGems
      Gem.path_ORG << iDirName
    end

    # Get the list of lib directories accessible through the paths
    #
    # Return:
    # * <em>list<String></em>: List of paths
    def getLibDirs
      if ((defined?(@LibDirs) == nil) or
          (@LibDirs == nil))
        # Create it
        @LibDirs = []
        each do |iGemsDirName|
          Dir.glob("#{iGemsDirName}/gems/*").each do |iGemDirName|
            if (File.exists?("#{iGemDirName}/lib"))
              @LibDirs << iGemDirName
            end
          end
        end
      end

      return @LibDirs
    end

    # Clear the paths
    def clear_paths
      Gem.clear_paths_ORG
      # Reset our cache with the new paths
      replace(Gem.path_ORG)
      @LibDirs = nil
    end

    # Clear the cache
    def clearCache
      @LibDirs = nil
    end

  end

  $RDI_GemPath_Cache = GemPathList.new(Gem.path)

  # Alias the old class methods
  class << self
    alias :find_files_ORG :find_files
    remove_method :find_files
    alias :path_ORG :path
    remove_method :path
    alias :clear_paths_ORG :clear_paths
    remove_method :clear_paths
  end

  # Return the list of files matching a Ruby require
  #
  # Parameters:
  # * *iRequireName* (_String_): Name to require
  # Return:
  # * <em>list<String></em>: File names list
  def self.find_files(iRequireName)
    rFilesList = []

    lRequireGlob = iRequireName
    if (File.extname(iRequireName).empty?)
      # Look using globs of any extension
      lRequireGlob = "#{iRequireName}.{rb,so,o,sl,dll}"
    end
    # 1. Look through Ruby LOAD PATH and the cache
    ($LOAD_PATH + $RDI_GemPath_Cache.getLibDirs).each do |iLibDir|
      lList = Dir.glob("#{iLibDir}/#{lRequireGlob}")
      if (!lList.empty?)
        rFilesList = lList
        break
      end
    end
    # 3. Ask RubyGems for real
    if (rFilesList.empty?)
      rFilesList = Gem.find_files_ORG(iRequireName)
    end

    return rFilesList
  end

  # Return the list of Gem paths
  #
  # Return:
  # * <em>list<String></em>: List of Gem paths
  def self.path
    return $RDI_GemPath_Cache
  end

  # Clear the paths
  def self.clear_paths
    $RDI_GemPath_Cache.clear_paths
  end

  # Clear the library cache
  # This is useful to ensure usecase tests isolation
  def self.clearCache_RDI
    $RDI_GemPath_Cache.clearCache
  end

end
