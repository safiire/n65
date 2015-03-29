require_relative '../instruction_base'
require_relative '../regexes.rb'

module Assembler6502


  ####
  ##  This directive to include bytes
  class Bytes < InstructionBase

    ####  Custom Exceptions
    class InvalidByteValue < StandardError; end


    ####
    ##  Try to parse an incbin directive
    def self.parse(line)
      match_data = line.match(/^\.bytes\s+(.+)$/)
      return nil if match_data.nil?

      bytes_array = match_data[1].split(',').map do |byte_string|

        ##  Does byte_string represent a numeric literal, or is it a symbol?
        ##  In numeric captures $2 is always binary, $1 is always hex

        case byte_string.strip
        when Regexp.new("^#{Regexes::Num8}$")
          $2.nil? ? $1.to_i(16) : $2.to_i(2)

        when Regexp.new("^#{Regexes::Num16}$")
          value = $2.nil? ? $1.to_i(16) : $2.to_i(2)

          ##  Break value up into two bytes
          high = (0xff00 & value) >> 8
          low  = (0x00ff & value)
          [low, high]
        when Regexp.new("^#{Regexes::Sym}$")
          $1
        else
          fail(InvalidByteValue, byte_string)
        end
      end.flatten

      Bytes.new(bytes_array)
    end


    ####
    ##  Initialize with filename
    def initialize(bytes_array)
      @bytes_array = bytes_array
    end


    ####
    ##  Execute on the assembler
    def exec(assembler)

      promise = assembler.with_saved_state do |saved_assembler|
        @bytes_array.map! do |byte|
          case byte
          when Fixnum
            byte
          when String
            value = saved_assembler.symbol_table.resolve_symbol(byte)
          else
            fail(InvalidByteValue, byte)
          end
        end
        saved_assembler.write_memory(@bytes_array)
      end

      begin
        promise.call
      rescue SymbolTable::UndefinedSymbol
        ##  Write the bytes but assume a zero page address for all symbols
        ##  And just write 0xDE for a placeholder
        placeholder_bytes = @bytes_array.map do |byte|
          case bytes
          when Fixnum
            byte
          when String
            0xDE
          else
            fail(InvalidByteValue, byte)
          end
        end
        assembler.write_memory(placeholder_bytes)
        return promise
      end
    end


    ####
    ##  Display, I don't want to write all these out
    def to_s
      ".bytes (#{@bytes_array.length})"
    end

  end

end
