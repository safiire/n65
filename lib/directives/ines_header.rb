require 'json'
require_relative '../instruction_base'

module Assembler6502


  ####
  ##  This directive instruction can setup an ines header
  class INESHeader < InstructionBase
    attr_reader :prog, :char, :mapper, :mirror


    ####
    ##  Implementation of the parser for this directive
    def self.parse(line)
      match_data = line.match(/^\.ines (.+)$/)
      return nil if match_data.nil?

      header = JSON.parse(match_data[1])
      INESHeader.new(header['prog'], header['char'], header['mapper'], header['mirror'])
    end


    ####
    ##  Construct a header
    def initialize(prog, char, mapper, mirror)
      @prog, @char, @mapper, @mirror = prog, char, mapper, mirror
    end


    ####
    ##  Exec function the assembler will call
    def exec(assembler)
      assembler.set_ines_header(self)
    end


    ####
    ##  Emit the header bytes, this is not exactly right, but it works for now.
    def emit_bytes
      [0x4E, 0x45, 0x53, 0x1a, @prog, @char, @mapper, @mirror, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0]
    end


    ####
    ##  Display
    def to_s
      ".ines {\"prog\": #{@prog}, \"char\": #{@char}, \"mapper\": #{@mapper}, \"mirror\": #{@mirror}}"
    end

  end

end
