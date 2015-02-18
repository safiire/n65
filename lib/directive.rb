
module Assembler6502

  ####
  ##  This parses an assembler directive
  class Directive

    #####
    ##  Some directives are:
    ##  .inesprg x   ; x * 16KB of PRG code
    ##  .ineschr x   ; x * 8KB of CHR data
    ##  .inesmap x   ; mapper.  0 = NROM, I don't know the other types
    ##  .inesmir x   ; background mirroring, I don't know what this should be so x = 1
    ##  .bank x      ; Sets the bank number, there are 8 banks of 8192 bytes = 2**16
    ##  .org $hhhh   ; Positions the code at hex address $hhhh
    ##  .incbin "a"  ; Assembles the contents of a binary file into current address
    ##  .dw x        ; Assemble a 16-bit word at current address, x can be a label
    ##  .bytes a b c ; Assemble a sequence of bytes at the current address

    ####
    ##  This will return a new Directive, or nil if it is something else.
    def self.parse(directive_line)

    end

  end

end
