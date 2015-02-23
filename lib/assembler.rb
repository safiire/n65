
module Assembler6502

  ####
  ##  Let's simulate the entire 0xFFFF addressable memory space
  ##  In the NES, and create reading and writing methods for it.
  class MemorySpace
    INESHeaderSize = 0x10
    ProgROMSize = 0x4000
    CharROMSize = 0x2000

    ####
    ##  Create a completely zeroed memory space
    def initialize(size = 2**16)
      @memory = Array.new(size, 0x0)
    end


    ####
    ##  Read from memory
    def read(address, count)
      @memory[address..(address + count - 1)]
    end


    ####
    ##  Write to memory
    def write(address, bytes)
      bytes.each_with_index do |byte, index|
        @memory[address + index] = byte
      end
    end


    ####
    ##  Return the memory as an array of bytes to write to disk
    def emit_bytes
      @memory
    end

  end


  ####
  ##  The Main Assembler
  class Assembler

    ##  Custom exceptions
    class INESHeaderNotFound < StandardError; end


    ####
    ##  Assemble from a file to a file
    def self.from_file(infile, outfile)
      assembler = self.new(File.read(infile))
      byte_array = assembler.assemble

      File.open(outfile, 'w') do |fp|
        fp.write(byte_array.pack('C*'))
      end
    end

    ####
    ##  Assemble 6502 Mnemomics and .directives into a program
    def initialize(assembly_code)
      @ines_header = nil
      @assembly_code = assembly_code
    end


    ####
    ##  Run the assembly process into a virtual memory object
    def assemble_in_virtual_memory
      address = 0x0
      labels = {}
      memory = MemorySpace.new
      unresolved_instructions = []

      puts "Assembling, first pass..."
      @assembly_code.split(/\n/).each do |raw_line|
        sanitized = Assembler6502.sanitize_line(raw_line)
        next if sanitized.empty?
        parsed_line = Assembler6502::Instruction.parse(sanitized, address)
        
        case parsed_line
        when INESHeader
          fail(SyntaxError, "Already got ines header") unless @ines_header.nil?
          @ines_header = parsed_line
          puts "\tGot iNES Header"

        when Org
          address = parsed_line.address
          puts "\tMoving to address: $%X" % address

        when Label
          puts "\tLabel #{parsed_line.label} = $%X" % parsed_line.address
          labels[parsed_line.label.to_sym] = parsed_line

        when Instruction
          if parsed_line.unresolved_symbols?
            puts "\tSaving instruction with unresolved symbols #{parsed_line}, for second pass"
            unresolved_instructions << parsed_line
          else
            puts "\tWriting instruction #{parsed_line}"
            memory.write(parsed_line.address, parsed_line.emit_bytes)
          end
          address += parsed_line.length

        when IncBin
          puts "\t Including binary file #{parsed_line.filepath}"
          memory.write(parsed_line.address, parsed_line.emit_bytes)
          address += parsed_line.size

        when DW
          if parsed_line.unresolved_symbols?
            puts "\tSaving #{parsed_line} directive with unresolved symbols, for second pass"
            unresolved_instructions << parsed_line
          else
            puts "\tWriting #{parsed_line} to memory"
            memory.write(address, parsed_line.emit_bytes)
          end
          address += 2

        when Bytes
          bytes = parsed_line.emit_bytes
          puts "\tWriting raw #{bytes.size} bytes to #{sprintf("$%X", address)}"
          memory.write(address, bytes)
          address += bytes.size

        when ASCII
          bytes = parsed_line.emit_bytes
          puts "\tWriting ascii string to memory \"#{bytes.pack('C*')}\""
          memory.write(address, bytes)
          address += bytes.size

        else
          fail(SyntaxError, sprintf("%.4X: Failed to parse: #{parsed_line}", address))
        end
      end

      puts "Second pass: Resolving Symbols..."
      unresolved_instructions.each do |instruction|
        if instruction.unresolved_symbols?
          instruction.resolve_symbols(labels)
        end
        puts "\tResolved #{instruction}"
        memory.write(instruction.address, instruction.emit_bytes)
      end
      puts 'Done'

      memory
    end


    ####
    ##  After assembling the binary into the full 16-bit memory space
    ##  we can now slice out the parts that should go into the binary ROM
    ##  I am guessing the ROM size should be 1 bank of 16KB cartridge ROM
    ##  plus the 16 byte iNES header.  If the ROM is written into memory 
    ##  beginning at 0xC000, this should reach right up to the interrupt vectors
    def assemble_old
      virtual_memory = assemble_in_virtual_memory

      ##  First we need to be sure we have an iNES header
      fail(INESHeaderNotFound) if @ines_header.nil?

      ##  Create memory to hold the ROM
      nes_rom = MemorySpace.new(0x10 + 0x4000)

      ##  First write the iNES header itself
      nes_rom.write(0x0, @ines_header.emit_bytes)

      ##  Write only one PROG section from 0xC000
      start_address = 0xC000
      length = 0x4000
      prog_rom = virtual_memory.read(start_address, length)
      write_start = 0x10
      nes_rom.write(write_start, prog_rom)

      ##  Now try writing one CHR-ROM section from 0x0000
      start_address = 0x0000
      length = 0x4000
      char_rom = virtual_memory.read(start_address, length)
      write_start = 0x10 + 0x4000
      nes_rom.write(write_start, char_rom)

      nes_rom.emit_bytes

      #rom_size = 16 + (0xffff - 0xc000)
      #nes_rom = MemorySpace.new(rom_size)
      #nes_rom.write(0x0, virtual_memory.read(0x0, 0x10))
      #nes_rom.write(0x10, virtual_memory.read(0xC000, 0x4000))
      #nes_rom.emit_bytes
    end


    ####
    ##  New ROM assembly, this is so simplified, and needs to take banks into account
    ##  This will happen once I fully understand mappers and banks.
    def assemble
      ##  Assemble into a virtual memory space
      virtual_memory = assemble_in_virtual_memory

      ##  First we need to be sure we have an iNES header
      fail(INESHeaderNotFound) if @ines_header.nil?

      ##  Now we want to create a ROM layout for PROG
      ##  This is simplified and only holds max two PROG entries
      prog_rom = MemorySpace.new(@ines_header.prog * MemorySpace::ProgROMSize)
      case @ines_header.prog
      when 0
        fail("You must have at least one PROG section")
        exit(1)
      when 1
        prog_rom.write(0x0, virtual_memory.read(0xc000, MemorySpace::ProgROMSize))
      when 2
        prog_rom.write(0x0, virtual_memory.read(0x8000, MemorySpace::ProgROMSize))
        prog_rom.write(MemorySpace::ProgROMSize, virtual_memory.read(0xC000, MemorySpace::ProgROMSize))
      else
        fail("I can't support more than 2 PROG sections")
        exit(1)
      end

      ##  Now we want to create a ROM layout for CHAR
      ##  This is simplified and only holds max two CHAR entries
      char_rom = MemorySpace.new(@ines_header.char * MemorySpace::CharROMSize)
      case @ines_header.char
      when 0
      when 1
        char_rom.write(0x0, virtual_memory.read(0x0000, MemorySpace::CharROMSize))
      when 2
        char_rom.write(0x0, virtual_memory.read(0x0000, MemorySpace::CharROMSize))
        char_rom.write(MemorySpace::CharROMSize, virtual_memory.read(0x2000, MemorySpace::CharROMSize))
      else
        fail("I can't support more than 2 CHAR sections")
        exit(1)
      end

      if @ines_header.char.zero?
        @ines_header.emit_bytes + prog_rom.emit_bytes
      else
        @ines_header.emit_bytes + prog_rom.emit_bytes + char_rom.emit_bytes
      end
    end

  end

end
