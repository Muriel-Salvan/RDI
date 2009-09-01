#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

# Run the test suite of RDI

lTestDir = File.dirname(__FILE__)
$LOAD_PATH << lTestDir

require 'Common.rb'

(
  Dir.glob("#{lTestDir}/Basic/*.rb") +
  Dir.glob("#{lTestDir}/Views/*.rb") +
  Dir.glob("#{lTestDir}/Testers/*.rb") +
  Dir.glob("#{lTestDir}/Installers/*.rb") +
  Dir.glob("#{lTestDir}/ContextModifiers/*.rb")
).each do |iFileName|
  # Remove the test dir from the file name, and require it.
  require iFileName[lTestDir.size+1..-1]
end
