require_relative '../instruction_base'

module Assembler6502


  ####
  ##  This directive to include bytes
  class EnterScope < InstructionBase


    ####
    ##  Try to parse an incbin directive
    def self.parse(line)
      match_data = line.match(/^\.scope\s+([a-zA-Z][a-zA-Z0-9_]+)$/)
      return nil if match_data.nil?
      EnterScope.new(match_data[1])
    end


    ####
    ##  Initialize with filename
    def initialize(name)
      @name = name
    end


    ####
    ##  Execute on the assembler
    def exec(assembler)
      assembler.symbol_table.enter_scope(@name)
    end


    ####
    ##  Display
    def to_s
      ".scope #{@name}"
    end

  end

end
