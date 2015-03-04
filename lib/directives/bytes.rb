require_relative '../instruction_base'

module Assembler6502


  ####
  ##  This directive to include bytes
  class Bytes < InstructionBase

    ####
    ##  Try to parse an incbin directive
    def self.parse(line)
      match_data = line.match(/^\.bytes\s+(.+)$/)
      return nil if match_data.nil?

      bytes_array = match_data[1].split(',').map do |byte_string|
        number = byte_string.gsub('$', '')
        integer = number.to_i(16)
        fail(SyntaxError, "#{integer} is too large for one byte") if integer > 0xff
        integer
      end

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
      assembler.write_memory(@bytes_array)
    end


    ####
    ##  Display, I don't want to write all these out
    def to_s
      ".bytes (#{@bytes_array.length})"
    end

  end

end
