require_relative '../instruction_base'

module N65


  ####
  ##  This directive gives a symbolic name for memory and creates space for a variable in RAM
  class Space < InstructionBase

    ####
    ##  Try to parse a .space directive
    def self.parse(line)
      match_data = line.match(/^.space\s+([a-zA-Z]?[a-zA-Z0-9_]+?)\s+([0-9]+)$/)
      return nil if match_data.nil?
      _, name, size = match_data.to_a

      Space.new(name, size.to_i)
    end


    ####
    ##  Initialize some memory space with a name
    def initialize(name, size)
      @name = name
      @size = size
    end


    ####
    ##  .space creates a symbol at the current PC, and then advances PC by size
    def exec(assembler)
      program_counter = assembler.program_counter
      assembler.symbol_table.define_symbol(@name, program_counter)
      assembler.program_counter += @size
    end


    ####
    ##  Display
    def to_s
      ".space #{@name} #{@size}"
    end

  end

end
