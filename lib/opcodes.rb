require 'yaml'

module Assembler6502

  ##  Load OpCode definitions into this module
  MyDirectory = File.expand_path(File.dirname(__FILE__))
  OpCodes = YAML.load_file("#{MyDirectory}/../data/opcodes.yaml")

end
