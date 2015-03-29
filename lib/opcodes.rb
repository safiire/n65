require 'yaml'

module N65

  ##  Load OpCode definitions into this module
  MyDirectory = File.expand_path(File.dirname(__FILE__))
  OpCodes = YAML.load_file("#{MyDirectory}/../data/opcodes.yaml")

end
