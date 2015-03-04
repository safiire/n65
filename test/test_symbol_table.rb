gem 'minitest'
require 'minitest/autorun'
require 'minitest/unit'

require_relative '../lib/symbol_table.rb'


class TestAssembler < MiniTest::Test
  include Assembler6502

  ####
  ##  Test that we can make simple global symbols
  def _test_define_global_symbols
    st = SymbolTable.new
    st.define_symbol('dog', 'woof')
    assert_equal('woof', st.resolve_symbol('dog'))
  end


  ####
  ##  Test entering into a sub scope, and setting and retrieving values
  def _test_enter_scope
    st = SymbolTable.new
    st.enter_scope('animals')
    st.define_symbol('dog', 'woof')
    assert_equal('woof', st.resolve_symbol('dog'))
  end


  ####
  ##  Test exiting a sub scope, and seeing that the variable is unavailable by simple name
  def _test_exit_scope
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
  def test_exit_scope
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

end

