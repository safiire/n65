module Assembler6502

  ####
  ##  Represents a label
  class Label
    attr_reader :label, :address

    def self.parse_label(asm_line, address)
      sanitized = Assembler6502.sanitize_line(asm_line)
      match_data = sanitized.match(/#{Instruction::Sym}:/)

      unless match_data.nil?
        _, label = match_data.to_a
        self.new(label, address)
      else
        nil
      end
    end


    ####
    ##  Create a label on an address
    def initialize(label, address)
      @label = label
      @address = address
    end


    ####
    ##  Pretty print
    def to_s
      sprintf("%.4X | #{@label}", @address)
    end


    ####
    ##  Labels take no space
    def length
      0
    end


    ####
    ##  Emit bytes, (none)
    def emit_bytes
      []
    end

    ####
    ##  Mode
    def mode
      "label"
    end

    ####
    ##  Description
    def description
      sprintf("Label pointing to $%.4X", @address)
    end

  end

end
