#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

# Run the test suite of RDI

# Set to true to enable tests using WxRuby
$RDITest_WX_Installed = false

lRootDir = File.expand_path("#{File.dirname(__FILE__)}/..")
lTestDir = "#{lRootDir}/test"

$LOAD_PATH << lTestDir
$LOAD_PATH << "#{lRootDir}/lib"

require 'Common'

(
  Dir.glob("#{lTestDir}/Flows/*.rb") +
  Dir.glob("#{lTestDir}/Plugins/Views/*.rb") +
  Dir.glob("#{lTestDir}/Plugins/Testers/*.rb") +
  Dir.glob("#{lTestDir}/Plugins/Installers/*.rb") +
  Dir.glob("#{lTestDir}/Plugins/LocationSelectors/*.rb") +
  Dir.glob("#{lTestDir}/Plugins/ContextModifiers/*.rb")
).each do |iFileName|
  # Remove the test dir from the file name, and require it.
  require iFileName[lTestDir.size+1..-1]
end
