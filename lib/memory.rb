module Assembler6502

  ####
  ##  Let's use this to simulate a virtual address space, by default
  ##  we simulate the 64KB of addressable space on the NES
  class MemorySpace


    ####  Some constants, the size of PROG and CHAR ROM
    INESHeaderSize = 0x10
    ProgROMSize = 0x4000
    CharROMSize = 0x2000


    ####
    ##  Create a completely zeroed memory space, 2**16 by default
    def initialize(size = 2**16)
      @memory = Array.new(size, 0x0)
    end


    ####
    ##  Read from memory
    ##  TODO: This could use some boundry checking
    def read(address, count)
      @memory[address..(address + count - 1)]
    end


    ####
    ##  Write to memory
    ##  TODO: This could use some boundry checking
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

end

