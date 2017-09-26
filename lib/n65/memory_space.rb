
module N65

  ####
  ##  Let's use this to simulate a virtual address space
  ##  Either a 16kb prog rom or 8kb char rom space.
  ##  It can also be used to create arbitrary sized spaces
  ##  for example to build the final binary ROM in.
  class MemorySpace

    ####  Custom exceptions
    class AccessOutsideProgRom < StandardError; end
    class AccessOutsideCharRom < StandardError; end
    class AccessOutOfBounds < StandardError; end


    ####  Some constants, the size of PROG and CHAR ROM
    BankSizes = {
      :ines => 0x10,     #  16b
      :prog => 0x4000,   #  16kb
      :char => 0x2000,   #   8kb
    }


    ####
    ##  Create a new PROG ROM
    def self.create_prog_rom
      self.create_bank(:prog)
    end


    ####
    ##  Create a new CHAR ROM
    def self.create_char_rom
      self.create_bank(:char)
    end


    ####
    ##  Create a new bank
    def self.create_bank(type)
      self.new(BankSizes[type], type)
    end


    ####
    ##  Create a completely zeroed memory space
    def initialize(size, type)
      @type = type
      @memory = Array.new(size, 0x0)
      @bytes_written = 0
    end


    ####
    ##  Normalized read from memory
    def read(address, count)
      from_normalized = normalize_address(address)
      to_normalized = normalize_address(address + (count - 1))
      ensure_addresses_in_bounds!([from_normalized, to_normalized])

      @memory[from_normalized..to_normalized]
    end


    ####
    ##  Normalized write to memory
    def write(address, bytes)
      from_normalized = normalize_address(address)
      to_normalized = normalize_address(address + bytes.size - 1)
      ensure_addresses_in_bounds!([from_normalized, to_normalized])

      bytes.each_with_index do |byte, index|
        @memory[from_normalized + index] = byte
        @bytes_written += 1
      end
      bytes.size
    end


    ####
    ##  Return the memory as an array of bytes to write to disk
    def emit_bytes
      @memory
    end


    ####
    ##  Bank Usage information
    def usage_info
      percent_used = @bytes_written / @memory.size.to_f * 100
      percent_string = "%0.2f" % percent_used
      bytes_written_hex = "$%04x" % @bytes_written
      memory_size_hex = "$%04x" % @memory.size
      "(#{bytes_written_hex} / #{memory_size_hex}) #{percent_string}%"
    end


    private

    ####
    ##  Are the given addresses in bounds?  If not blow up.
    def ensure_addresses_in_bounds!(addresses)
      addresses.each do |address|
        unless address >= 0 && address < @memory.size
          fail(AccessOutOfBounds, sprintf("Address $%.4X is out of bounds in this #{@type} bank"))
        end
      end
      true
    end


    ####
    ##  Since prog rom can be loaded at either 0x8000 or 0xC000
    ##  We should normalize the addresses to fit properly into
    ##  these banks, basically it acts like it is mirroring addresses
    ##  in those segments.  Char rom doesn't need this.  This will also
    ##  fail if you are accessing outside of the address space.
    def normalize_address(address)
      case @type
      when :prog
        if address_inside_prog_rom1?(address)
          return address - 0x8000
        end
        if address_inside_prog_rom2?(address)
          return address - 0xC000
        end
        fail(AccessOutsideProgRom, sprintf("Address $%.4X is outside PROG ROM", address))
      when :char
        unless address_inside_char_rom?(address)
          fail(AccessOutsideCharRom, sprintf("Address $%.4X is outside CHAR ROM", address))
        end
        return address
      else
        return address
      end
    end


    ####
    ##  Is this address inside the prog rom 1 area?
    def address_inside_prog_rom1?(address)
      address >= 0x8000 && address < 0xC000
    end


    ####
    ##  Is this address inside the prog rom 2 area?
    def address_inside_prog_rom2?(address)
      address >= 0xC000 && address <= 0xffff
    end


    ####
    ##  Is this address inside the char rom area?
    def address_inside_char_rom?(address)
      address >= 0x0000 && address <= 0x1fff
    end

  end

end

