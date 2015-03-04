require_relative '../instruction_base'

module Assembler6502


  ####
  ##  This directive instruction can include a binary file
  class DW < InstructionBase

    ####
    ##  Try to parse a dw directive
    def self.parse(line)

      ##  Maybe it is a straight up bit of hex
      match_data = line.match(/^\.dw\s+\$([0-9A-F]{1,4})$/)
      unless match_data.nil?
        word = match_data[1].to_i(16)
        return DW.new(word)
      end

      ##  Or maybe it points to a symbol
      match_data = line.match(/^\.dw\s+([A-Za-z_][A-Za-z0-9_\.]+)/)
      unless match_data.nil?
        symbol = match_data[1]
        return DW.new(symbol)
      end
      nil
    end


    ####
    ##  Initialize with filename
    def initialize(value)
      @value = value
    end


    ####
    ##  Execute on the assembler, now in this case value may
    ##  be a symbol that needs to be resolved, if so we return
    ##  a lambda which can be executed later, with the promise
    ##  that that symbol will have then be defined
    ##  This is a little complicated, I admit.
    def exec(assembler)

      ##  Save these current values into the closure
      pc = assembler.program_counter
      segment = assembler.current_segment
      bank = assembler.current_bank

      ##  Create a promise, if this symbol is not defined yet.
      promise = lambda do 
        value = assembler.symbol_table.resolve_symbol(@value)
        bytes = [value & 0xFFFF].pack('S').bytes
        assembler.write_memory(bytes, pc, segment, bank)
      end

      ##  Try to execute it now, or setup the promise to return
      case @value
      when Fixnum
        bytes = [@value & 0xFFFF].pack('S').bytes
        assembler.write_memory(bytes)
      when String
        begin
          promise.call
        rescue SymbolTable::UndefinedSymbol
          ##  Must still advance PC before returning promise, so we'll write
          ##  a place holder value of 0xDEAD
          assembler.write_memory([0xDE, 0xAD], pc, segment, bank)
          return promise
        end
      else
        fail("Uknown argument in .dw directive")
      end
    end


    ####
    ##  Display
    def to_s
      case @value
      when String
        ".dw #{@value}"
      when Fixnum
        ".dw $%4.X" % @value
      end
    end

  end

end
