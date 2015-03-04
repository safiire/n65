require_relative '../instruction_base'

module Assembler6502

  ####
  ##  This is an .org directive
  class Org < InstructionBase
    attr_reader :address

    ####
    ##  Try to parse an .org statement
    def self.parse(line)
      match_data = line.match(/^\.org\s+\$([0-9A-Fa-f]{4})$/)
      return nil if match_data.nil?
      address = match_data[1].to_i(16)
      Org.new(address)
    end

    
    ####
    ##  Initialized with address to switch to
    def initialize(address)
      @address = address
    end


    ####
    ##  Exec this directive on the assembler
    def exec(assembler)
      assembler.program_counter = address
    end


    ####
    ##  Display
    def to_s
      if @address <= 0xff
        ".org $%2.X" % @address
      else
        ".org $%4.X" % @address
      end
    end

  end

end

