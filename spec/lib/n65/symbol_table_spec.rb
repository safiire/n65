# frozen_string_literal: true

require_relative '../../../lib/n65/symbol_table'
require_relative '../../../lib/n65'

RSpec.describe(N65::SymbolTable) do
  subject { described_class.new }

  context 'when defining a global symbol' do
    before { subject.define_symbol('dog', 'woof') }

    it 'can resolve the value' do
      expect(subject.resolve_symbol('dog')).to eq('woof')
    end
  end

  context 'when entering a sub-scope' do
    before do
      subject.enter_scope('animals')
      subject.define_symbol('dog', 'woof')
    end

    it 'can resolve the value' do
      expect(subject.resolve_symbol('dog')).to eq('woof')
    end

    it 'can resolve the value with full dot syntax' do
      expect(subject.resolve_symbol('animals.dog')).to eq('woof')
    end
  end

  context 'when accessing a symbol at higher scope' do
    before do
      subject.enter_scope('outer')
      subject.define_symbol('dog', 'woof')
      subject.enter_scope('inner')
      subject.define_symbol('pig', 'oink')
    end

    it 'can resolve the outer value without dot syntax' do
      expect(subject.resolve_symbol('dog')).to eq('woof')
    end

    it 'can resolve the value in current scope' do
      expect(subject.resolve_symbol('pig')).to eq('oink')
    end
  end

  context 'when a symbol from an outer scope is shadowed' do
    before do
      subject.enter_scope('outer')
      subject.define_symbol('dog', 'woof')
      subject.enter_scope('inner')
      subject.define_symbol('dog', 'bark')
    end

    it 'the inner scope shadows the outer' do
      expect(subject.resolve_symbol('dog')).to eq('bark')
    end

    it 'does not shadow it when we leave the inner scope' do
      subject.exit_scope
      expect(subject.resolve_symbol('dog')).to eq('woof')
    end

    it 'can access inner via dot syntax if we exit both scopes' do
      subject.exit_scope
      subject.exit_scope
      expect(subject.resolve_symbol('outer.inner.dog')).to eq('bark')
    end
  end

  context 'when trying to access a symbol not in scope' do
    before do
      subject.enter_scope('animals')
      subject.define_symbol('dog', 'woof')
      subject.exit_scope
    end

    it 'is undefined' do
      expect { subject.resolve_symbol('dog') }.to raise_error(described_class::UndefinedSymbol)
    end
  end

  context 'when trying to access a symbol not in scope' do
    before do
      subject.enter_scope('animals')
      subject.define_symbol('dog', 'woof')
      subject.exit_scope
    end

    it 'can be accessed by full path' do
      expect(subject.resolve_symbol('animals.dog')).to eq('woof')
    end
  end

  context 'when we have two symbols with the same name in different scopes' do
    before do
      subject.define_symbol('dog', 'woof')
      subject.enter_scope('animals')
      subject.define_symbol('dog', 'woof woof')
      subject.exit_scope
    end

    it 'can access each by full path' do
      expect(subject.resolve_symbol('dog')).to eq('woof')
    end

    it 'can access each by full path' do
      expect(subject.resolve_symbol('animals.dog')).to eq('woof woof')
    end
  end

  context 'when trying to access symbols at top scope' do
    before do
      subject.define_symbol('dog', 'woof')
      subject.enter_scope('animals')
      subject.define_symbol('dog', 'woof woof')
    end

    it 'can use the global prefix' do
      expect(subject.resolve_symbol('global.dog')).to eq('woof')
    end
  end

  context 'when creating an anonymous scope' do
    before do
      subject.define_symbol('dog', 'woof')
      subject.enter_scope
      subject.define_symbol('dog', 'woof woof')
    end

    it 'gets the value in the current anonymous scope' do
      expect(subject.resolve_symbol('dog')).to eq('woof woof')
    end

    it 'can get the outer dog by dot syntax' do
      expect(subject.resolve_symbol('global.dog')).to eq('woof')
    end

    it 'can get the outer dog by exiting anonymous scope and resolving' do
      subject.exit_scope
      expect(subject.resolve_symbol('dog')).to eq('woof')
    end
  end

  context 'when trying to exit the top most scope' do
    it 'raises an error' do
      expect { subject.exit_scope }.to raise_error(described_class::CantExitScope)
    end
  end

  context 'when checking the address value of a scope' do
    let(:assembler) { N65::Assembler.new }
    let(:program) do
      <<~'ASM'
        .ines {"prog": 1, "char": 0, "mapper": 0, "mirror": 0}
        .org $8000
        .segment prog 0
        .scope main
          sei
          cld
          lda #$00
          jmp main
        .
        jmp main
        jmp global.main
      ASM
    end

    before { assembler.assemble_string(program) }

    it 'assigns the value of the scope main to the program counter value' do
      expect(assembler.symbol_table.resolve_symbol('global.main')).to eq(0x8000)
    end
  end

  context 'when we try to jump to a forward declared symbol' do
    let(:assembler) { N65::Assembler.new }
    let(:program) do
      <<~'ASM'
        .ines {"prog": 1, "char": 0, "mapper": 0, "mirror": 0}
        .org $8000
        .scope main
          sei
          cld
          lda #$00
          bne forward_symbol
          nop
          nop
          nop
          forward_symbol:
          rts
        .
      ASM
    end
    let(:correct_binary) do
      [
        0x78,        # SEI
        0xd8,        # CLD
        0xa9, 0x0,   # LDA immediate 0
        0xd0, 0x3,   # BNE +3
        0xea,        # NOP
        0xea,        # NOP
        0xea,        # NOP
        0x60         # RTS forward_symbol
      ]
    end
    let(:emitted_rom) { assembler.emit_binary_rom.bytes[16...26] }

    before { assembler.assemble_string(program) }

    it 'assembles the branch to forward_symbol correctly' do
      expect(emitted_rom).to eq(correct_binary)
    end
  end
end
