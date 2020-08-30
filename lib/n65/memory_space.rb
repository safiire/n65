# frozen_string_literal: true

module N65
  # Let's use this to simulate a virtual address space
  # Either a 16kb prog rom or 8kb char rom space.
  # It can also be used to create arbitrary sized spaces
  # for example to build the final binary ROM in.
  class MemorySpace
    class AccessOutsideProgRom < StandardError; end
    class AccessOutsideCharRom < StandardError; end
    class AccessOutOfBounds < StandardError; end

    # Some constants, the size of PROG and CHAR ROM
    BANK_SIZES = {
      ines: 0x10,
      prog: 0x4000,
      char: 0x2000
    }.freeze

    def self.create_prog_rom
      create_bank(:prog)
    end

    def self.create_char_rom
      create_bank(:char)
    end

    def self.create_bank(type)
      new(BANK_SIZES[type], type)
    end

    # Create a completely zeroed memory space
    def initialize(size, type)
      @type = type
      @memory = Array.new(size, 0x0)
      @bytes_written = 0
    end

    # Normalized read from memory
    def read(address, count)
      from_normalized = normalize_address(address)
      to_normalized = normalize_address(address + (count - 1))
      ensure_addresses_in_bounds!([from_normalized, to_normalized])

      @memory[from_normalized..to_normalized]
    end

    # Normalized write to memory
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

    # Return the memory as an array of bytes to write to disk
    def emit_bytes
      @memory
    end

    # Bank Usage information
    def usage_info
      percent_used = @bytes_written / @memory.size.to_f * 100
      percent_string = format('%0.2f', percent_used)
      bytes_written_hex = format('$%04x', @bytes_written)
      memory_size_hex = format('$%04x', @memory.size)
      "(#{bytes_written_hex} / #{memory_size_hex}) #{percent_string}%"
    end

    private

    # Are the given addresses in bounds?  If not blow up.
    def ensure_addresses_in_bounds!(addresses)
      addresses.each do |address|
        unless address >= 0 && address < @memory.size
          raise(AccessOutOfBounds, format("Address $%.4X is out of bounds in this #{@type} bank"))
        end
      end
      true
    end

    # Since prog rom can be loaded at either 0x8000 or 0xC000
    # We should normalize the addresses to fit properly into
    # these banks, basically it acts like it is mirroring addresses
    # in those segments.  Char rom doesn't need this.  This will also
    # fail if you are accessing outside of the address space.
    def normalize_address(address)
      case @type
      when :prog
        normalize_prog_rom_address(address)
      when :char
        normalize_char_rom_address(address)
      else
        address
      end
    end

    def normalize_prog_rom_address(address)
      return (address - 0x8000) if address_inside_prog_rom1?(address)
      return (address - 0xC000) if address_inside_prog_rom2?(address)

      message = 'Address $%.4X is outside PROG ROM'
      raise(AccessOutsideProgRom, format(message, address))
    end

    def normalize_char_rom_address(address)
      return address if address_inside_char_rom?(address)

      message = 'Address $%.4X is outside CHAR ROM'
      raise(AccessOutsideCharRom, format(message, address))
    end

    def address_inside_prog_rom1?(address)
      address >= 0x8000 && address < 0xC000
    end

    def address_inside_prog_rom2?(address)
      address >= 0xC000 && address <= 0xffff
    end

    def address_inside_char_rom?(address)
      address >= 0x0000 && address <= 0x1fff
    end
  end
end
