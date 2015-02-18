gem 'minitest'
require 'minitest/autorun'
require 'minitest/unit'

require_relative '../assembler_6502.rb'

class TestAssembler < MiniTest::Test

  def setup
    ##  Remember the modes which can use 16-bit absolute labels are:
    ##  - absolute
    ##  - absolute_x
    ##  - absolute_y
    ##  The JMP instruction can use 16-bit labels
    ##  - absolute
    ##  - indirect (it is the only indirect instruction)
    ##
    ##  The Branching instructions can use labels, but they are all relative 8-bit addresses
  end


  def test_adc
    asm = <<-'ASM'
      ADC #$FF         ;  Immediate
    label:
      ADC $FF          ;  Zero Page
      ADC $FF, X       ;  Zero Page X
      ADC $FFFF        ;  Absolute
      ADC $FFFF, X     ;  Absolute X
      ADC $FFFF, Y     ;  Absolute Y
      ADC label        ;  Absolute Label
      ADC label, X     ;  Absolute X Label
      ADC label, Y     ;  Absolute Y Label
      ADC ($FF, X)     ;  Indirect X
      ADC ($FF), Y     ;  Indirect Y
    ASM
    assembler = Assembler6502::Assembler.new(asm)
    correct = %w{69 ff 65 ff 75 ff 6d ff ff 7d ff ff 79 ff ff 6d 02 06 7d 02 06 79 02 06 61 ff 71 ff}
    assert_equal(correct, assembler.hexdump)
  end


  def test_and
    asm = <<-'ASM'
      AND #$FF         ;  Immediate
    label:
      AND $FF          ;  Zero Page
      AND $FF, X       ;  Zero Page X
      AND $FFFF        ;  Absolute
      AND $FFFF, X     ;  Absolute X
      AND $FFFF, Y     ;  Absolute Y
      AND label        ;  Absolute Label
      AND label, X     ;  Absolute X Label
      AND label, Y     ;  Absolute Y Label
      AND ($FF, X)     ;  Indirect X
      AND ($FF), Y     ;  Indirect Y
    ASM
    assembler = Assembler6502::Assembler.new(asm)
    correct = %w{29 ff 25 ff 35 ff 2d ff ff 3d ff ff 39 ff ff 2d 02 06 3d 02 06 39 02 06 21 ff 31 ff}
    assert_equal(correct, assembler.hexdump)
  end


  def test_asl
    asm = <<-'ASM'
      ASL              ;  Implied
    label:
      ASL $FF          ;  Zero Page
      ASL $FF, X       ;  Zero Page X
      ASL $FFFF        ;  Absolute
      ASL $FFFF, X     ;  Absolute X
      ASL label        ;  Absolute Label
      ASL label, X     ;  Absolute X Label
    ASM
    assembler = Assembler6502::Assembler.new(asm)
    correct = %w{0a 06 ff 16 ff 0e ff ff 1e ff ff 0e 01 06 1e 01 06}
    assert_equal(correct, assembler.hexdump)
  end


  def test_bit
    asm = <<-'ASM'
      BIT $FF          ;  Zero Page
    label:
      BIT $FFFF        ;  Absolute
      BIT label        ;  Absolute
    ASM
    assembler = Assembler6502::Assembler.new(asm)
    correct = %w{24 ff 2c ff ff 2c 02 06}
    assert_equal(correct, assembler.hexdump)
  end


  def test_branches
    asm = <<-'ASM'
      LDX #$08
    decrement:
      DEX
      STX $0200
      CPX #$03
      BNE decrement
      STX $0201
      BPL decrement
      BMI decrement
      BVC decrement
      BVS decrement
      BCC decrement
      BCS decrement
      BEQ decrement
      BRK
    ASM
    assembler = Assembler6502::Assembler.new(asm)
    correct = %w{a2 08 ca 8e 00 02 e0 03 d0 f8 8e 01 02 10 f3 30 f1 50 ef 70 ed 90 eb b0 e9 f0 e7 00}
    assert_equal(correct, assembler.hexdump)
  end


  def test_stack_instructions
    asm = <<-'ASM'
      TXS
      TSX
      PHA
      PLA
      PHP
      PLP
      NOP
    ASM
    assembler = Assembler6502::Assembler.new(asm)
    correct = %w{9a ba 48 68 08 28 ea}
    assert_equal(correct, assembler.hexdump)
  end






end

