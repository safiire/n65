# frozen_string_literal: true

require_relative '../instruction_base'

module N65
  # This directive to include bytes
  class ExitScope < InstructionBase
    def self.parse(line)
      match_data = line.match(/^\.$/)
      return nil if match_data.nil?

      ExitScope.new
    end

    # Execute on the assembler
    def exec(assembler)
      assembler.symbol_table.exit_scope
    end

    # Display
    def to_s
      '.'
    end
  end
end
