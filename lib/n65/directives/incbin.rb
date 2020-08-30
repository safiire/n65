# frozen_string_literal: true

require_relative '../instruction_base'

module N65
  # This directive instruction can include a binary file
  class IncBin < InstructionBase
    class FileNotFound < StandardError; end

    def self.parse(line)
      match_data = line.match(/^\.incbin "([^"]+)"$/)
      return nil if match_data.nil?

      filename = match_data[1]
      IncBin.new(filename)
    end

    def initialize(filename)
      @filename = filename
    end

    def exec(assembler)
      raise(FileNotFound, ".incbin can't find #{@filename}") unless File.exist?(@filename)

      data = File.read(@filename).unpack('C*')
      assembler.write_memory(data)
    end

    def to_s
      ".incbin \"#{@filename}\""
    end
  end
end
