gem 'minitest'
require 'minitest/autorun'
require 'minitest/unit'

require_relative '../lib/n65/memory_space.rb'


class TestMemorySpace < MiniTest::Test
  include N65

  def test_create_prog_rom
    ##  First just try to read alll of it
    space = MemorySpace.create_prog_rom
    contents = space.read(0x8000, 0x4000)
    assert_equal(contents.size, 0x4000)
    assert(contents.all?{|byte| byte.zero?})

    ##  It is mirrored so this should also work
    space = MemorySpace.create_prog_rom
    contents = space.read(0xC000, 0x4000)
    assert_equal(contents.size, 0x4000)
    assert(contents.all?{|byte| byte.zero?})
  end


  def test_writing
    ##  Write some bytes into prog 2 area
    space = MemorySpace.create_prog_rom
    space.write(0xC000, "hi there".bytes)

    ##  Read them back..
    contents = space.read(0xC000, 8)
    assert_equal('hi there', contents.pack('C*'))

    ##  Should be mirrored in prog 1
    contents = space.read(0x8000, 8)
    assert_equal('hi there', contents.pack('C*'))
  end


  def test_reading_out_of_bounds
    space = MemorySpace.create_prog_rom
    assert_raises(MemorySpace::AccessOutsideProgRom) do
      space.read(0x200, 10)
    end

    ##  But that is valid char rom area, so no explody
    space = MemorySpace.create_char_rom
    space.read(0x200, 10)

    ##  But something like this should explode
    space = MemorySpace.create_char_rom
    assert_raises(MemorySpace::AccessOutsideCharRom) do
      space.read(0x8001, 10)
    end
  end


  ####
  ##  There seem to be problems writing bytes right to
  ##  the end of the memory map, specifically where the
  ##  vector table is in prog rom, so let's test that.
  def test_writing_to_end
    space = MemorySpace.create_prog_rom
    bytes = [0xDE, 0xAD]

    ##  Write the NMI address to FFFA
    space.write(0xFFFA, bytes)

    ##  Write the entry point to FFFC
    space.write(0xFFFC, bytes)

    ##  Write the irq to FFFE, and this fails, saying
    ##  I'm trying to write to $10000 for some reason.
    space.write(0xFFFE, bytes)

    ##  Write to the very first
    space.write(0x8000, bytes)
  end

end

