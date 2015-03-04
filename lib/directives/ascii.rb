require_relative '../instruction_base'

module Assembler6502


  ####
  ##  This directive to include bytes
  class ASCII < InstructionBase


    ####
    ##  Try to parse an incbin directive
    def self.parse(line)
      match_data = line.match(/^\.ascii\s+"([^"]+)"$/)
      return nil if match_data.nil?
      ASCII.new($1)
    end


    ####
    ##  Initialize with filename
    def initialize(string)
      @string = string
    end


    ####
    ##  Execute on the assembler
    def exec(assembler)
      assembler.write_memory(@string.bytes)
    end


    ####
    ##  Display
    def to_s
      ".ascii \"#{@string}\""
    end

  end

end
