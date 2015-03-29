
module N65

  class InstructionBase


    #####
    ##  Sort of a "pure virtual" class method, not really tho.
    def self.parse(line)
      fail(NotImplementedError, "#{self.class.name} must implement self.parse")
    end


    ####
    ##  Does this instruction have unresolved symbols?
    def unresolved_symbols?
      false
    end


    ####
    ##  Another method subclasses will be expected to implement
    def exec(assembler)
      fail(NotImplementedError, "#{self.class.name} must implement exec")
    end

  end

end
