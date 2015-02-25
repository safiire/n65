
module Assembler6502

  ####
  ##  This is a base class for anything which can emit bytes
  class EmitsBytes

    def emit_bytes
      fail(NotImplementedError, "#{self.class} must implement emit_bytes")
    end

  end

end
