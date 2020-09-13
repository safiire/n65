# frozen_string_literal: true

require_relative 'n65/version'
require_relative 'n65/symbol_table'
require_relative 'n65/memory_space'
require_relative 'n65/parser'

module N65
  class Assembler
    attr_reader :program_counter, :current_segment, :current_bank, :symbol_table, :virtual_memory, :promises

    class AddressOutOfRange < StandardError; end
    class InvalidSegment < StandardError; end
    class WriteOutOfBounds < StandardError; end
    class INESHeaderAlreadySet < StandardError; end
    class FileNotFound < StandardError; end

    # Assemble from an asm file to a nes ROM
    # TODO: This really needs a logger instead of all these unless quiet conditions
    def self.from_file(infile, options)
      raise(FileNotFound, infile) unless File.exist?(infile)

      assembler = new
      program = File.read(infile)
      output_file = options[:output_file]

      puts "Building #{infile}" unless options[:quiet]
      # Process each line in the file
      program.each_line.each_with_index do |line, line_number|
        begin
          assembler.assemble_one_line(line)
        rescue StandardError => e
          warn("\n\n#{e.class}\n#{line}\n#{e}\nOn line #{line_number}")
          exit(1)
        end
        print '.' unless options[:quiet]
      end
      puts unless options[:quiet]

      # Second pass to resolve any missing symbols.
      print 'Second pass, resolving symbols...' unless options[:quiet]
      assembler.fulfill_promises
      puts ' Done.' unless options[:quiet]

      # Optionally write out a symbol map
      if options[:write_symbol_table]
        print "Writing symbol table to #{output_file}.yaml..." unless options[:quiet]
        File.open("#{output_file}.yaml", 'w') do |fp|
          fp.write(assembler.symbol_table.export_to_yaml)
        end
        puts 'Done.' unless options[:quiet]
      end

      # Optionally write out cycle count for subroutines
      if options[:cycle_count]
        print "Writing subroutine cycle counts to #{output_file}.cycles.yaml..." unless options[:quiet]
        File.open("#{output_file}.cycles.yaml", 'w') do |fp|
          fp.write(assembler.symbol_table.export_cycle_count_yaml)
        end
        puts 'Done.' unless options[:quiet]
      end

      # Emit the complete binary ROM
      rom = assembler.emit_binary_rom
      File.open(output_file, 'w') do |fp|
        fp.write(rom)
      end

      return if options[:quiet]

      rom_size = rom.size
      rom_size_hex = format('%x', rom_size)
      assembler.print_bank_usage
      puts "Total size: $#{rom_size_hex}, #{rom_size} bytes"
    end

    # Initialize with a bank 1 of prog space for starters
    def initialize
      @ines_header = nil
      @program_counter = 0x0
      @current_segment = :prog
      @current_bank = 0x0
      @symbol_table = SymbolTable.new
      @promises = []
      @virtual_memory = {
        prog: [MemorySpace.create_prog_rom],
        char: []
      }
    end

    # Return an object that contains the assembler's current state
    def get_current_state
      saved_program_counter, saved_segment, saved_bank = @program_counter, @current_segment, @current_bank
      saved_scope = symbol_table.scope_stack.dup
      OpenStruct.new(
        program_counter: saved_program_counter,
        segment: saved_segment,
        bank: saved_bank,
        scope: saved_scope
      )
    end

    # Set the current state from an OpenStruct
    def set_current_state(struct)
      @program_counter, @current_segment, @current_bank = struct.program_counter, struct.segment, struct.bank
      symbol_table.scope_stack = struct.scope.dup
    end

    # This is the main assemble method, it parses one line into an object
    # which when given a reference to this assembler, controls the assembler
    # itself through public methods, executing assembler directives, and
    # emitting bytes into our virtual memory spaces.  Empty lines or lines
    # with only comments parse to nil, and we just ignore them.
    def assemble_one_line(line)
      parsed_object = Parser.parse(line)
      return if parsed_object.nil?

      exec_result = parsed_object.exec(self)

      # TODO: I could perhaps keep a tally of cycles used per top level scope here
      if parsed_object.respond_to?(:cycles)
        @symbol_table.add_cycles(parsed_object.cycles)
      end

      # If we have returned a promise save it for the second pass
      @promises << exec_result if exec_result.is_a?(Proc)
    end

    # Assemble the given string
    def assemble_string(string)
      string.each_line do |line|
        assemble_one_line(line)
      end
      fulfill_promises
      self
    end

    # This will empty out our promise queue and try to fullfil operations
    # that required an undefined symbol when first encountered.
    def fulfill_promises
      @promises.pop.call while @promises.any?
    end

    # This rewinds the state of the assembler, so a promise can be
    # executed with a previous state, for example if we can't resolve
    # a symbol right now, and want to try during the second pass
    def with_saved_state(&block)
      saved_state = get_current_state
      lambda do
        set_current_state(saved_state)
        block.call(self)
      end
    end

    # Write to memory space. Typically, we are going to want to write
    # to the location of the current PC, current segment, and current bank.
    def write_memory(bytes, pc = @program_counter, segment = @current_segment, bank = @current_bank)
      memory_space = get_virtual_memory_space(segment, bank)
      memory_space.write(pc, bytes)
      @program_counter += bytes.size
    end

    # Set the iNES header
    def set_ines_header(ines_header)
      raise(INESHeaderAlreadySet) unless @ines_header.nil?

      @ines_header = ines_header
    end

    # Set the program counter
    def program_counter=(address)
      raise(AddressOutOfRange) unless address_within_range?(address)

      @program_counter = address
    end

    # Set the current segment, prog or char.
    def current_segment=(segment)
      segment = segment.to_sym
      raise(InvalidSegment, "#{segment} is not a valid segment.  Try prog or char") unless valid_segment?(segment)

      @current_segment = segment
    end

    # Set the current bank, create it if it does not exist
    def current_bank=(bank_number)
      memory_space = get_virtual_memory_space(@current_segment, bank_number)
      @virtual_memory[@current_segment][bank_number] = MemorySpace.create_bank(@current_segment) if memory_space.nil?
      @current_bank = bank_number
    end

    def emit_binary_rom
      progs = @virtual_memory[:prog]
      chars = @virtual_memory[:char]

      rom_size  = 0x10
      rom_size += MemorySpace::BANK_SIZES[:prog] * progs.size
      rom_size += MemorySpace::BANK_SIZES[:char] * chars.size

      rom = MemorySpace.new(rom_size, :rom)

      offset = 0x0
      offset += rom.write(0x0, @ines_header.emit_bytes)

      progs.each do |prog|
        offset += rom.write(offset, prog.read(0x8000, MemorySpace::BANK_SIZES[:prog]))
      end

      chars.each do |char|
        offset += rom.write(offset, char.read(0x0, MemorySpace::BANK_SIZES[:char]))
      end
      rom.emit_bytes.pack('C*')
    end

    # TODO: Use StringIO to build output
    def print_bank_usage
      puts
      puts 'ROM Structure {'
      puts '  iNES 1.0 Header: $10 bytes'

      @virtual_memory[:prog].each_with_index do |prog_rom, bank_number|
        puts "  PROG ROM bank #{bank_number}: #{prog_rom.usage_info}"
      end

      @virtual_memory[:char].each_with_index do |char_rom, bank_number|
        puts "  CHAR ROM bank #{bank_number}: #{char_rom.usage_info}"
      end
      puts '}'
    end

    private

    def get_virtual_memory_space(segment, bank_number)
      @virtual_memory[segment][bank_number]
    end

    def address_within_range?(address)
      address >= 0 && address < 2**16
    end

    def valid_segment?(segment)
      %i[prog char].include?(segment)
    end
  end
end
