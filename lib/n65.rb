require_relative 'n65/version'
require_relative 'n65/symbol_table'
require_relative 'n65/memory_space'
require_relative 'n65/parser'

module N65

  class Assembler
    attr_reader :program_counter, :current_segment, :current_bank, :symbol_table, :virtual_memory, :promises

    #####  Custom exceptions
    class AddressOutOfRange < StandardError; end
    class InvalidSegment < StandardError; end
    class WriteOutOfBounds < StandardError; end
    class INESHeaderAlreadySet < StandardError; end
    class FileNotFound < StandardError; end


    ####
    ##  Assemble from an asm file to a nes ROM
    def self.from_file(infile, outfile)
      fail(FileNotFound, infile) unless File.exists?(infile)

      assembler = self.new
      program = File.read(infile)

      puts "Building #{infile}"
      ##  Process each line in the file
      program.split(/\n/).each_with_index do |line, line_number|
        begin
          assembler.assemble_one_line(line)
        rescue StandardError => e
          STDERR.puts("\n\n#{e.class}\n#{line}\n#{e}\nOn line #{line_number}")
          exit(1)
        end
        print '.'
      end
      puts

      ##  Second pass to resolve any missing symbols.
      print "Second pass, resolving symbols..."
      assembler.fulfill_promises
      puts " Done."

      ##  Let's not export the symbol table to a file anymore
      ##  Will add an option for this later.
      #print "Writing symbol table to #{outfile}.yaml..."
      #File.open("#{outfile}.yaml", 'w') do |fp|
        #fp.write(assembler.symbol_table.export_to_yaml)
      #end
      #puts "Done."

      ##  For right now, let's just emit the first prog bank
      File.open(outfile, 'w') do |fp|
        fp.write(assembler.emit_binary_rom)
      end
      puts "All Done :)"
    end


    ####
    ##  Initialize with a bank 1 of prog space for starters
    def initialize
      @ines_header = nil
      @program_counter = 0x0
      @current_segment = :prog
      @current_bank = 0x0
      @symbol_table = SymbolTable.new
      @promises = []
      @virtual_memory = {
        :prog => [MemorySpace.create_prog_rom],
        :char => []
      }
    end


    ####
    ##  Return an object that contains the assembler's current state
    def get_current_state
      saved_program_counter, saved_segment, saved_bank = @program_counter, @current_segment, @current_bank
      saved_scope = symbol_table.scope_stack.dup
      OpenStruct.new(program_counter: saved_program_counter, segment: saved_segment, bank: saved_bank, scope: saved_scope)
    end


    ####
    ##  Set the current state from an OpenStruct
    def set_current_state(struct)
      @program_counter, @current_segment, @current_bank = struct.program_counter, struct.segment, struct.bank
      symbol_table.scope_stack = struct.scope.dup
    end


    ####
    ##  This is the main assemble method, it parses one line into an object
    ##  which when given a reference to this assembler, controls the assembler
    ##  itself through public methods, executing assembler directives, and 
    ##  emitting bytes into our virtual memory spaces.  Empty lines or lines
    ##  with only comments parse to nil, and we just ignore them.
    def assemble_one_line(line)
      parsed_object = Parser.parse(line)

      unless parsed_object.nil?
        exec_result = parsed_object.exec(self)

        ##  If we have returned a promise save it for the second pass
        @promises << exec_result if exec_result.kind_of?(Proc)
      end
    end


    ####
    ##  This will empty out our promise queue and try to fullfil operations
    ##  that required an undefined symbol when first encountered.
    def fulfill_promises
      while promise = @promises.pop
        promise.call
      end
    end


    ####
    ##  This rewinds the state of the assembler, so a promise can be 
    ##  executed with a previous state, for example if we can't resolve
    ##  a symbol right now, and want to try during the second pass
    def with_saved_state(&block)
      ##  Save the current state of the assembler
      old_state = get_current_state

      lambda do

        ##  Set the assembler state back to the old state and run the block like that
        set_current_state(old_state)
        block.call(self)
      end
    end


    ####
    ##  Write to memory space. Typically, we are going to want to write
    ##  to the location of the current PC, current segment, and current bank.
    ##  Bounds check is inside MemorySpace#write
    def write_memory(bytes, pc = @program_counter, segment = @current_segment, bank = @current_bank)
      memory_space = get_virtual_memory_space(segment, bank)
      memory_space.write(pc, bytes)
      @program_counter += bytes.size
    end


    ####
    ##  Set the iNES header
    def set_ines_header(ines_header)
      fail(INESHeaderAlreadySet) unless @ines_header.nil?
      @ines_header = ines_header
    end


    ####
    ##  Set the program counter
    def program_counter=(address)
      fail(AddressOutOfRange) unless address_within_range?(address)
      @program_counter = address
    end


    ####
    ##  Set the current segment, prog or char.
    def current_segment=(segment)
      segment = segment.to_sym
      unless valid_segment?(segment)
        fail(InvalidSegment, "#{segment} is not a valid segment.  Try prog or char")
      end
      @current_segment = segment
    end


    ####
    ##  Set the current bank, create it if it does not exist
    def current_bank=(bank_number)
      memory_space = get_virtual_memory_space(@current_segment, bank_number)
      if memory_space.nil?
        @virtual_memory[@current_segment][bank_number] = MemorySpace.create_bank(@current_segment)
      end
      @current_bank = bank_number
    end


    ####
    ##  Emit a binary ROM
    def emit_binary_rom
      progs = @virtual_memory[:prog]
      chars = @virtual_memory[:char]
      puts "iNES Header"
      puts "+ #{progs.size} PROG ROM bank#{progs.size != 1 ? 's' : ''}"
      puts "+ #{chars.size} CHAR ROM bank#{chars.size != 1 ? 's' : ''}"

      rom_size  = 0x10 
      rom_size += MemorySpace::BankSizes[:prog] * progs.size
      rom_size += MemorySpace::BankSizes[:char] * chars.size

      puts "= Output ROM will be #{rom_size} bytes"
      rom = MemorySpace.new(rom_size, :rom)

      offset = 0x0
      offset += rom.write(0x0, @ines_header.emit_bytes)

      progs.each do |prog|
        offset += rom.write(offset, prog.read(0x8000, MemorySpace::BankSizes[:prog]))
      end

      chars.each do |char|
        offset += rom.write(offset, char.read(0x0, MemorySpace::BankSizes[:char]))
      end
      rom.emit_bytes.pack('C*')
    end


    private


    ####
    ##  Get virtual memory space
    def get_virtual_memory_space(segment, bank_number)
      @virtual_memory[segment][bank_number]
    end


    ####
    ##  Is this a 16-bit address within range?
    def address_within_range?(address)
      address >= 0 && address < 2**16
    end


    ####
    ##  Is this a valid segment?
    def valid_segment?(segment)
      [:prog, :char].include?(segment)
    end

  end

end
