require 'json'
require_relative '../instruction_base'

module N65

  ####
  ##  This directive instruction can setup an iNES header
  class INESHeader < InstructionBase
    attr_reader :prog, :char, :mapper, :mirror, :battery_backed, :fourscreen_vram, :prog_ram, :tv

    Defaults = {prog: 1, char: 0, mapper: 0, mirror: 0, battery_backed: 0, fourscreen_vram: 0, prog_ram: 0, tv: 0}

    ####
    ##  Implementation of the parser for this directive
    def self.parse(line)
      match_data = line.match(/^\.ines (.+)$/)
      return nil if match_data.nil?

      header = JSON.parse(match_data[1])
      header = header.inject({}) do |hash, (key, val)|
        hash[key.to_sym] = val
        hash
      end

      header = Defaults.merge(header)

      INESHeader.new(
        header[:prog],
        header[:char],
        header[:mapper],
        header[:mirror],
        header[:battery_backed],
        header[:fourscreen_vram],
        header[:prog_ram],
        header[:tv])
    end


    ####
    ##  Construct a header
    def initialize(prog, char, mapper, mirror, battery_backed, fourscreen_vram, prog_ram, tv)
      @prog = prog
      @char = char
      @mapper = mapper
      @mirror = mirror
      @battery_backed = battery_backed
      @fourscreen_vram = fourscreen_vram
      @prog_ram = prog_ram
      @tv = tv
    end


    ####
    ##  Exec function the assembler will call
    def exec(assembler)
      assembler.set_ines_header(self)
    end


    ####
    ##  Emit the header bytes
    def emit_bytes

      mapper_lo_nybble = (@mapper & 0x0f)
      mapper_hi_nybble = (@mapper & 0xf0) >> 4

      flag6 = 0
      flag6 |= 0x1 if @mirror == 1
      flag6 |= 0x2 if @battery_backed == 1
      flag6 |= 0x8 if @fourscreen_vram == 1
      flag6 |= (mapper_lo_nybble << 4)

      flag7 = 0
      flag7 |= (mapper_hi_nybble << 4)

      [0x4E, 0x45, 0x53, 0x1a,
       @prog & 0xff,
       @char & 0xff,
       flag6 & 0xff,
       flag7 & 0xff,
       @prog_ram & 0xff,
       0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0]
    end


    ####
    ##  Display
    def to_s
      [".ines {\"prog\": #{@prog}, \"char\": #{@char}, \"mapper\": #{@mapper}, ",
       "\"mirror\": #{@mirror}}, \"battery_backed\": #{@battery_backed}, ",
       "\"fourscreen_vram\": #{@fourscreen_vram}, \"prog_ram\": #{@prog_ram}, ",
       "\"tv\": #{@tv}"].join
    end

  end

end
