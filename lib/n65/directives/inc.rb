# frozen_string_literal: true

require_relative '../instruction_base'

module N65
  # This directive instruction can include another asm file
  class Inc < InstructionBase
    SYSTEM_INCLUDE = "#{File.dirname(__FILE__)}/../../../nes_lib"

    class FileNotFound < StandardError; end

    # Try to parse an incbin directive
    def self.parse(line)
      # Do We have a system directory include?
      match_data = line.match(/^\.inc <([^>]+)>$/)
      unless match_data.nil?
        filename = File.join(SYSTEM_INCLUDE, match_data[1])
        return Inc.new(filename)
      end

      # Do We have a project relative directory include?
      match_data = line.match(/^\.inc "([^"]+)"$/)
      unless match_data.nil?
        filename = File.join(Dir.pwd, match_data[1])
        return Inc.new(filename)
      end

      # Nope, not an inc directive
      nil
    end

    # Initialize with filename
    def initialize(filename)
      @filename = filename
    end

    # Execute on the assembler
    def exec(assembler)
      raise(FileNotFound, ".inc can't find #{@filename}") unless File.exist?(@filename)

      File.read(@filename).split(/\n/).each do |line|
        assembler.assemble_one_line(line)
      end
    end

    # Display
    def to_s
      ".inc \"#{@filename}\""
    end
  end
end
