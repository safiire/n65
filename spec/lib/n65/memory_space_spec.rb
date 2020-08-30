# frozen_string_literal: true

require_relative '../../../lib/n65/memory_space'

RSpec.describe(N65::MemorySpace) do
  describe '.new' do
    context 'when provided a size and type' do
      let(:bank) { described_class.new(size, type) }
      let(:size) { 0x100 }
      let(:type) { :prog }

      it 'returns a zeroed bank' do
        expect(bank.emit_bytes.all?(&:zero?)).to eq(true)
      end

      it 'returns the requested sized bank' do
        expect(bank.emit_bytes.size).to be(size)
      end
    end
  end

  describe '.create_prog_rom' do
    context 'when creating a new prog rom' do
      let(:bank) { described_class.create_prog_rom }

      it 'returns a zeroed bank' do
        expect(bank.emit_bytes.all?(&:zero?)).to eq(true)
      end

      it 'returns the correct sized bank' do
        expect(bank.emit_bytes.size).to eq(0x4000)
      end
    end
  end

  describe '.create_char_rom' do
    context 'when creating a new prog rom' do
      let(:bank) { described_class.create_char_rom }

      it 'returns a zeroed bank' do
        expect(bank.emit_bytes.all?(&:zero?)).to eq(true)
      end

      it 'returns the correct sized bank' do
        expect(bank.emit_bytes.size).to eq(0x2000)
      end
    end
  end

  describe '#read prog rom' do
    let(:address) { 0xC100 }
    let(:mirroed_address) { 0x8100 }
    let(:bank) { described_class.create_prog_rom }
    let(:data) { 'hi there'.bytes }

    before { bank.write(address, data) }

    context 'when reading from the bank' do
      it 'can read back from the 0xC000 base address' do
        expect(bank.read(address, data.size)).to eq(data)
      end

      it 'can read back from the 0x8000 mirrored address' do
        expect(bank.read(mirroed_address, data.size)).to eq(data)
      end
    end

    context 'when attempting to read out of bounds' do
      it 'throws an error' do
        expect { bank.read(0x0, 0x10) }.to raise_error(described_class::AccessOutsideProgRom)
      end

      it 'throws an error' do
        expect { bank.read(0xffff, 0x10) }.to raise_error(described_class::AccessOutsideProgRom)
      end
    end
  end

  describe '#read char rom' do
    let(:address) { 0x100 }
    let(:bank) { described_class.create_char_rom }
    let(:data) { 'hi there'.bytes }

    before { bank.write(address, data) }

    context 'when reading from the bank' do
      it 'can read from the bank' do
        expect(bank.read(address, data.size)).to eq(data)
      end
    end

    context 'when attempting to read out of bounds' do
      it 'throws an error' do
        expect { bank.read(0x2000, 0x10) }.to raise_error(described_class::AccessOutsideCharRom)
      end
    end
  end

  describe '#write prog rom' do
    let(:address) { 0xC100 }
    let(:mirroed_address) { 0x8100 }
    let(:bank) { described_class.create_prog_rom }
    let(:data) { 'hi there'.bytes }

    before { bank.write(mirroed_address, data) }

    context 'when reading from the bank' do
      it 'can read back from the 0xC000 base address' do
        expect(bank.read(address, data.size)).to eq(data)
      end

      it 'can read back from the 0x8000 mirrored address' do
        expect(bank.read(mirroed_address, data.size)).to eq(data)
      end
    end

    context 'when attempting to write out of bounds' do
      it 'throws an error' do
        expect { bank.write(0x0, data) }.to raise_error(described_class::AccessOutsideProgRom)
      end

      it 'throws an error' do
        expect { bank.write(0xffff, data) }.to raise_error(described_class::AccessOutsideProgRom)
      end
    end
  end

  describe '#write char rom' do
    let(:address) { 0x100 }
    let(:bank) { described_class.create_char_rom }
    let(:data) { 'hi there'.bytes }

    before { bank.write(address, data) }

    context 'when reading from the bank' do
      it 'can read from the bank' do
        expect(bank.read(address, data.size)).to eq(data)
      end
    end

    context 'when attempting to write out of bounds' do
      it 'throws an error' do
        expect { bank.write(0x2000, data) }.to raise_error(described_class::AccessOutsideCharRom)
      end
    end
  end
end
