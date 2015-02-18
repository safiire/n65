
module Assembler6502

  ####
  ##  Let's simulate the entire 0xFFFF addressable memory space
  ##  In the NES, and create reading and writing methods for it.
  class MemorySpace

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
          puts "\tWriting iNES Header"
          memory.write(0x0, parsed_line.emit_bytes)

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
            puts "\tWriting instruction #{parsed_line} to memory"
            memory.write(parsed_line.address, parsed_line.emit_bytes)
          end
          address += parsed_line.length
          puts "\tAdvanced address to %X" % address

        when IncBin
          puts "\tI Don't support .incbin yet"

        when DW
          if parsed_line.unresolved_symbols?
            puts "\tSaving .dw directive with unresolved symbols #{parsed_line}, for second pass"
            unresolved_instructions << parsed_line
          else
            puts "\tWriting .dw #{parsed_line.inspect} to memory"
            memory.write(address, parsed_line.emit_bytes)
          end
          address += 2

        when Bytes
          bytes = parsed_line.emit_bytes
          puts "\tWriting raw bytes to memory #{bytes.inspect}"
          memory.write(address, bytes)
          address += bytes.size
        else
          fail(SyntaxError, sprintf("%.4X: Failed to parse: #{parsed_line}", address))
        end
      end

      print "Second pass: Resolving Symbols..."
      unresolved_instructions.each do |instruction|
        if instruction.unresolved_symbols?
          instruction.resolve_symbols(labels)
        end
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
    def assemble
      virtual_memory = assemble_in_virtual_memory
      rom_size = 16 + (0xffff - 0xc000)
      nes_rom = MemorySpace.new(rom_size)
      nes_rom.write(0x0, virtual_memory.read(0x0, 0x10))
      nes_rom.write(0x10, virtual_memory.read(0xC000, 0x4000))
      nes_rom.emit_bytes
    end

  end

end
