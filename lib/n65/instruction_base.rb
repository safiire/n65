# frozen_string_literal: true

module N65
  class InstructionBase
    def self.parse(_line)
      raise(NotImplementedError, "#{self.class.name} must implement self.parse")
    end

    def unresolved_symbols?
      false
    end

    def exec(_assembler)
      raise(NotImplementedError, "#{self.class.name} must implement exec")
    end
  end
end
