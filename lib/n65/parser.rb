# frozen_string_literal: true

module N65
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

  # This class determines what sort of line of code we
  # are dealing with, parses one line, and returns an
  # object deriving from InstructionBase
  class Parser
    class CannotParse < StandardError; end

    DIRECTIVES = [INESHeader, Org, Segment, IncBin, Inc, DW, Bytes, ASCII, EnterScope, ExitScope, Space].freeze

    # Parses a line of program source into an object
    # deriving from base class InstructionBase
    def self.parse(line)
      sanitized = sanitize_line(line)
      return nil if sanitized.empty?

      # First check to see if we have a label.
      label = Label.parse(sanitized)
      return label unless label.nil?

      # Now check if we have a directive
      directive = parse_directive(sanitized)
      return directive unless directive.nil?

      # Now, surely it is an asm instruction?
      instruction = Instruction.parse(sanitized)
      return instruction unless instruction.nil?

      # Guess not, we have no idea
      raise(CannotParse, sanitized)
    end

    # Sanitize one line of program source
    def self.sanitize_line(line)
      code = line.split(';').first || ''
      code.strip.chomp
    end
    private_class_method :sanitize_line

    ##  Try to Parse a directive
    def self.parse_directive(line)
      if line.start_with?('.')
        DIRECTIVES.each do |directive|
          object = directive.parse(line)
          return object unless object.nil?
        end
      end
      nil
    end
    private_class_method :parse_directive
  end
end
