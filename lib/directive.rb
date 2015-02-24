require 'json'

module Assembler6502

  ####
  ##  This class can setup an iNES Header
  class INESHeader 
    attr_reader :prog, :char, :mapper, :mirror

    ####
    ##  Construct with the right values
    def initialize(prog = 0x1, char = 0x0, mapper = 0x0, mirror = 0x1)
      @prog, @char, @mapper, @mirror = prog, char, mapper, mirror
    end


    ####
    ##  What will the size of the ROM binary be?
    def rom_size
      size =  0x10               #  Always have a 16 byte header
      size += 0x4000 * @prog     #  16KB per PROG-ROM
      size += 0x2000 * @char     #  8KB per CHR_ROM
      size
    end


    ####
    ##  Emit the header bytes, this is not exactly right, but it works for now.
    def emit_bytes
      [0x4E, 0x45, 0x53, 0x1a, @prog, @char, @mapper, @mirror, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0]
    end

  end


  ####
  ##  This is an .org directive
  class Org
    attr_reader :address
    
    ####
    ##  Initialized with start address
    def initialize(address)
      @address = address
    end
  end


  ####
  ##  This is to include a binary file
  class IncBin
    attr_reader :address, :filepath

    class FileNotFound < StandardError; end

    ####
    ##  Initialize with a file path
    def initialize(filepath, address)
      @filepath = filepath
      @address = address
      unless File.exists?(filepath)
        fail(FileNotFound, ".incbin can't find #{filepath}")
      end
      @data = File.read(filepath).unpack('C*')
    end

    ####
    ##  What is the size of the read data?
    def size
      @data.size
    end


    ####
    ##  Emit bytes
    def emit_bytes
      @data
    end
  end


  ####
  ##  Data Word
  class DW
    attr_reader :address
    class WordTooLarge < StandardError; end

    def initialize(value, address)
      @value = value
      @address = address
    end

    def unresolved_symbols?
      @value.kind_of?(Symbol)
    end

    def resolve_symbols(labels)
      if unresolved_symbols? && labels[@value] != nil
        @value = labels[@value].address
      end
    end

    def to_s
      if @value.kind_of?(Symbol)
        sprintf("$%.4X | .dw #{@value}", @address)
      else
        sprintf("$%.4X | .dw $%.4X", @address, @value)
      end
    end

    def emit_bytes
      fail('Need to resolve symbol in .dw directive') if unresolved_symbols?
      [@value & 0xFFFF].pack('S').bytes
    end

  end


  ####
  ##  Just a bunch of bytes
  class Bytes
    def initialize(bytes)
      @bytes = bytes.split(',').map do |byte_string|
        number = byte_string.gsub('$', '')
        integer = number.to_i(16)
        fail(SyntaxError, "#{integer} is too large for one byte") if integer > 0xff
        integer
      end
    end

    def emit_bytes
      @bytes
    end
  end


  ####
  ##  This inserts ASCII text straight into the ROM
  class ASCII
    def initialize(string)
      @string = string
    end

    def emit_bytes
      @string.bytes
    end
  end


  ####
  ##  This parses an assembler directive
  class Directive

    ####
    ##  This will return a new Directive, or nil if it is something else.
    def self.parse(directive_line, address)
      sanitized = Assembler6502.sanitize_line(directive_line)

      case sanitized
      when /^\.ines (.+)$/
        header = JSON.parse($1)
        INESHeader.new(header['prog'], header['char'], header['mapper'], header['mirror'])

      when /^\.org\s+\$([0-9A-F]{4})$/
        Org.new($1.to_i(16))

      when /^\.incbin "([^"]+)"$/
        IncBin.new($1, address)

      when /^\.dw\s+\$([0-9A-F]{1,4})$/
        DW.new($1.to_i(16), address)

      when /^\.dw\s+([A-Za-z_][A-Za-z0-9_]+)/
        DW.new($1.to_sym, address)

      when /^\.ascii\s+"([^"]+)"$/
        ASCII.new($1)

      when /^\.bytes\s+(.+)$/
        Bytes.new($1)
      when /^\./
        fail(SyntaxError, "Syntax Error in Directive '#{sanitized}'")
      end
    end

  end

end




