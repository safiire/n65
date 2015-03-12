
module Assembler6502

  require_relative 'instruction'
  require_relative 'directives/ines_header'
  require_relative 'directives/org'
  require_relative 'directives/segment'
  require_relative 'directives/incbin'
  require_relative 'directives/inc'
  require_relative 'directives/dw'
  require_relative 'directives/bytes'
  require_relative 'directives/ascii'
  require_relative 'directives/label'
  require_relative 'directives/enter_scope'
  require_relative 'directives/exit_scope'
  require_relative 'directives/space'


  ####
  ##  This class determines what sort of line of code we
  ##  are dealing with, parses one line, and returns an 
  ##  object deriving from InstructionBase
  class Parser

    ####  Custom Exceptions
    class CannotParse < StandardError; end


    Directives = [INESHeader, Org, Segment, IncBin, Inc, DW, Bytes, ASCII, EnterScope, ExitScope, Space]

    ####
    ##  Parses a line of program source into an object
    ##  deriving from base class InstructionBase
    def self.parse(line)
      sanitized = sanitize_line(line)
      return nil if sanitized.empty?

      ##  First check to see if we have a label.
      label = Label.parse(sanitized)
      unless label.nil?
        return label
      end

      ##  Now check if we have a directive
      directive = parse_directive(sanitized)
      unless directive.nil?
        return directive
      end

      ##  Now, surely it is an asm instruction?
      instruction = Instruction.parse(sanitized)
      unless instruction.nil?
        return instruction
      end

      ##  Guess not, we have no idea
      fail(CannotParse, sanitized)
    end


    private
    ####
    ##  Sanitize one line of program source
    def self.sanitize_line(line)
      code = line.split(';').first || ""
      code.strip.chomp
    end


    ####
    ##  Try to Parse a directive
    def self.parse_directive(line)
      if line.start_with?('.')
        Directives.each do |directive|
          object = directive.parse(line)
          return object unless object.nil?
        end
      end
      nil
    end

  end

end
