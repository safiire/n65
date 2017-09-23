gem 'minitest'
require 'minitest/autorun'
require 'minitest/unit'

require_relative '../lib/n65.rb'


class TestArithmeticSymbols < MiniTest::Test
  include N65


  def test_identify_plain_symbol
    re = Regexp.new(Regexes::Sym)
    assert_match(re, 'dog')
    assert_match(re, 'animal.dog')
    assert_match(re, 'global.animal.dog')
  end


  def test_symbol_values
    st = SymbolTable.new
    st.define_symbol('variable', 0xff)
    assert_equal(0xff, st.resolve_symbol('variable'))
  end


  def test_perform_symbolic_arithmetic
    st = SymbolTable.new
    st.define_symbol('variable', 0x20)
    assert_equal(0x21, st.resolve_symbol('variable+1'))
    assert_equal(0x40, st.resolve_symbol('variable*2'))
  end


  def test_symbol_addition
    program = <<-ASM
    .ines {"prog": 1, "char": 0, "mapper": 0, "mirror": 0}

    .org $0020
    .scope struct
      .space a 1
      .space b 1
    .

    .org $8000
    .scope main
      sei
      cld
      lda struct+1 zp
      lda struct*2 zp
      rts
    .
    ASM

    assembler = Assembler.new
    program.split(/\n/).each do |line|
      assembler.assemble_one_line(line)
    end
    assembler.fulfill_promises

    binary = assembler.emit_binary_rom[16...23].split(//).map(&:ord)

    ##  So yay, arithmetic on symbols works now :)
    correct = [
      0x78,         #  sei
      0xd8,         #  cld
      0xa5,         #  lda
      0x21,         #  $20 + 1
      0xa5,         #  lda
      0x40,         #  $20 * 2
      0x60          #  rts
    ]
    assert_equal(binary, correct)
  end


end

