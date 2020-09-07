# frozen_string_literal: true

module N65
  class InstructionBase
    def self.parse(_line)
      raise(NotImplementedError, "#{self.class.name} must implement #{__method__}")
    end

    def exec(_assembler)
      raise(NotImplementedError, "#{self.class.name} must implement #{__method__}")
    end

    def unresolved_symbols?
      false
    end
  end
end
