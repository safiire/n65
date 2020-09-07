# frozen_string_literal: true

require 'digest/sha2'
require_relative '../lib/n65'

RSpec.describe(N65::Assembler) do
  describe 'assembling example files' do
    let(:examples) do
      File.join(__dir__, '..', 'examples')
    end

    let(:source) do
      File.read(File.join(examples, filename))
    end

    let(:assembler) do
      described_class.new
    end

    let(:binary) do
      assembler.assemble_string(source).emit_binary_rom
    end

    let(:sha256) do
      Digest::SHA256.hexdigest(binary)
    end

    context 'when assembling beep.asm' do
      let(:filename) { 'beep.asm' }
      let(:expected) { 'afce4dd85323d86dd6b2f8e4c9e7d704607b0480c3cf087bd8f66b37b8ddf269' }

      it 'have the correct sha256 digest' do
        expect(sha256).to eq(expected)
      end
    end

    context 'when assembling demo.asm' do
      let(:filename) { 'demo.asm' }
      let(:expected) { 'ff687730a0a4022519b177c1cd92f18eaafaa2e9606f9a579371e9c62ffcb726' }

      it 'have the correct sha256 digest' do
        expect(sha256).to eq(expected)
      end
    end

    context 'when assembling scales.asm' do
      let(:filename) { 'scales.asm' }
      let(:expected) { '2c6c586f3a9d35212a1a02e064a8bb71ec26ac857ed6572f217c10161f2de102' }

      it 'have the correct sha256 digest' do
        expect(sha256).to eq(expected)
      end
    end

    context 'when assembling pulse_chord.asm' do
      let(:filename) { 'pulse_chord.asm' }
      let(:expected) { '77712d504edbe9b30261939a9d72f51e14ee3029da04287b879dffbb36eb9b12' }

      it 'have the correct sha256 digest' do
        expect(sha256).to eq(expected)
      end
    end

    context 'when assembling noise.asm' do
      let(:filename) { 'noise.asm' }
      let(:expected) { 'ea790d892ecd2bf76f711fbcb8a2f8e9b4dbaa5dffb56b691924c81666d23673' }

      it 'have the correct sha256 digest' do
        expect(sha256).to eq(expected)
      end
    end

    context 'when assembling mario2.asm', skip: '.incbin include path should be relative to source file' do
      let(:filename) { 'mario2.asm' }
      let(:expected) { '0974b799eac7ffb8835fcbd518a5cdeeec734d5d9476cd11cb6b75491c6ef488' }

      it 'have the correct sha256 digest' do
        expect(sha256).to eq(expected)
      end
    end
  end
end
