# frozen_string_literal: true

require_relative '../instruction_base'

module N65
  # This directive to include bytes
  class ASCII < InstructionBase
    def self.parse(line)
      match_data = line.match(/^\.ascii\s+"([^"]+)"$/)
      return nil if match_data.nil?

      ASCII.new(match_data[1])
    end

    def initialize(string)
      @string = string
    end

    def exec(assembler)
      assembler.write_memory(@string.bytes)
    end

    def to_s
      ".ascii \"#{@string}\""
    end
  end
end
