gem 'minitest'
require 'minitest/autorun'
require 'minitest/unit'

require_relative '../lib/n65/symbol_table.rb'
require_relative '../lib/n65.rb'


class TestSymbolTable < MiniTest::Test
  include N65

  ####
  ##  Test that we can make simple global symbols
  def test_define_global_symbols
    st = SymbolTable.new
    st.define_symbol('dog', 'woof')
    assert_equal('woof', st.resolve_symbol('dog'))
  end


  ####
  ##  Test entering into a sub scope, and setting and retrieving values
  def test_enter_scope
    st = SymbolTable.new
    st.enter_scope('animals')
    st.define_symbol('dog', 'woof')
    assert_equal('woof', st.resolve_symbol('dog'))
  end


  ####
  ##  Access something from an outer scope without dot syntax
  def test_outer_scope
    st = SymbolTable.new
    st.enter_scope('outer')
    st.define_symbol('dog', 'woof')
    st.enter_scope('inner')
    st.define_symbol('pig', 'oink')
    assert_equal('woof', st.resolve_symbol('dog'))
  end


  ####
  ##  Access something from an outer scope without dot syntax
  def test_shadow
    st = SymbolTable.new
    st.enter_scope('outer')
    st.define_symbol('dog', 'woof')
    st.enter_scope('inner')
    st.define_symbol('dog', 'bark')
    assert_equal('bark', st.resolve_symbol('dog'))
    assert_equal('woof', st.resolve_symbol('outer.dog'))
    st.exit_scope
    st.exit_scope
    assert_equal('bark', st.resolve_symbol('outer.inner.dog'))
  end


  ####
  ##  Test exiting a sub scope, and seeing that the variable is unavailable by simple name
  def test_exit_scope
    st = SymbolTable.new
    st.enter_scope('animals')
    st.define_symbol('dog', 'woof')
    assert_equal('woof', st.resolve_symbol('dog'))

    st.exit_scope

    assert_raises(SymbolTable::UndefinedSymbol) do
      assert_equal('woof', st.resolve_symbol('dog'))
    end
  end


  ####
  ##  Test exiting a sub scope, and being able to access a symbol through a full path
  def test_exit_scope_full_path
    st = SymbolTable.new
    st.enter_scope('animals')
    st.define_symbol('dog', 'woof')
    assert_equal('woof', st.resolve_symbol('dog'))

    st.exit_scope

    assert_equal('woof', st.resolve_symbol('animals.dog'))
  end


  ####
  ##  Have two symbols that are the same but are in different scopes
  def test_two_scopes_same_symbol
    st = SymbolTable.new
    st.define_symbol('dog', 'woof')
    assert_equal('woof', st.resolve_symbol('dog'))

    st.enter_scope('animals')

    st.define_symbol('dog', 'woofwoof')
    assert_equal('woofwoof', st.resolve_symbol('dog'))

    st.exit_scope

    assert_equal('woof', st.resolve_symbol('dog'))
    assert_equal('woofwoof', st.resolve_symbol('animals.dog'))
  end


  ####
  ##  How do you get stuff out of the global scope when you are in
  ##  a sub scope?
  def test_access_global_scope
    st = SymbolTable.new
    st.define_symbol('dog', 'woof')
    assert_equal('woof', st.resolve_symbol('dog'))

    st.enter_scope('animals')
    st.define_symbol('pig', 'oink')
    assert_equal('oink', st.resolve_symbol('pig'))

    ##  Ok, now I want to access global.dog basically from the previous scope
    assert_equal('woof', st.resolve_symbol('global.dog'))
  end


  ####
  ##  Now I want to just test making an anonymous scope
  def test_anonymous_scope
    st = SymbolTable.new
    st.define_symbol('dog', 'woof')
    assert_equal('woof', st.resolve_symbol('dog'))

    st.enter_scope
    st.define_symbol('pig', 'oink')
    assert_equal('oink', st.resolve_symbol('pig'))

    ##  Ok, now I want to access global.dog basically from the previous scope
    assert_equal('woof', st.resolve_symbol('global.dog'))

    ##  Now exit the anonymous scope and get dog
    st.exit_scope
    assert_equal('woof', st.resolve_symbol('global.dog'))
    assert_equal('woof', st.resolve_symbol('dog'))
  end


  ####
  ##  Now I want to test that I cannot exist the outer-most
  ##  global scope by mistake
  def test_cant_exit_global
    st = SymbolTable.new
    assert_raises(SymbolTable::CantExitScope) do
      st.exit_scope
    end
  end


  ####
  ##  I would like the name of the scope to take on the
  ##  value of the program counter at that location.
  def test_scope_as_symbol
    program = <<-ASM
      .ines {"prog": 1, "char": 0, "mapper": 0, "mirror": 0}
      .org $8000
      .segment prog 0
      .scope main
        sei
        cld
        lda \#$00
        jmp main
      .
      jmp main
      jmp global.main
    ASM

    ####  There really should be an evaluate string method
    assembler = Assembler.new
    program.split(/\n/).each do |line|
      assembler.assemble_one_line(line)
    end
    assembler.fulfill_promises
    assert_equal(0x8000, assembler.symbol_table.resolve_symbol('global.main'))
  end


  ####
  ##  Fix a bug where we can't see a forward declared symbol in a scope
  def test_foward_declaration_in_scope
    program = <<-ASM
    ;;;;
    ;  Create an iNES header
    .ines {"prog": 1, "char": 0, "mapper": 0, "mirror": 0}

    ;;;;
    ;  Try to expose a problem we have with scopes
    ;  We don't seem to be able to branch to a forward
    ;  declared symbol within a scope
    .org $8000
    .scope main
      sei
      cld
      lda #\$00
      bne forward_symbol
      nop
      nop
      nop
      forward_symbol:
      rts
    .
    ASM

    ####  There really should be an evaluate string method
    assembler = Assembler.new
    program.split(/\n/).each do |line|
      assembler.assemble_one_line(line)
    end
    puts YAML.dump(assembler.symbol_table)
    assembler.fulfill_promises

    ####  The forward symbol should have been resolved to +3, and the ROM should look like this:
    correct_rom = [0x4e, 0x45, 0x53, 0x1a, 0x1, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                   0x78,        # SEI
                   0xd8,        # CLD
                   0xa9, 0x0,   # LDA immediate 0
                   0xd0, 0x3,   # BNE +3
                   0xea,        # NOP
                   0xea,        # NOP
                   0xea,        # NOP
                   0x60         # RTS forward_symbol
    ]

    ####  Grab the first 26 bytes of the rom and make sure they assemble to the above
    emitted_rom = assembler.emit_binary_rom.bytes[0...26]
    assert_equal(correct_rom, emitted_rom)
    ####  Yup it is fixed now.
  end

end

