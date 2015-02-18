
module Assembler6502

  ####
  ##  Represents a single 6502 Instruction
  class Instruction
    attr_reader :op, :arg, :mode, :hex, :description, :length, :cycle, :boundry_add, :flags, :address

    ##  Custom Exceptions
    class InvalidInstruction < StandardError; end
    class UnresolvedSymbols < StandardError; end
    class InvalidAddressingMode < StandardError; end
    class AddressOutOfRange < StandardError; end

    Mnemonic  = '([A-Z]{3})'
    Hex8      = '\$([A-Z0-9]{2})'
    Hex16     = '\$([A-Z0-9]{4})'
    Immediate = '\#\$([0-9A-F]{2})'
    Sym       = '([A-Za-z_][A-Za-z0-9_]+)'
    Branches  = '(BPL|BMI|BVC|BVS|BCC|BCS|BNE|BEQ)'

    AddressingModes = {
      :relative => {
        :example     => 'B** my_label',
        :display     => '%s $%.4X',
        :regex       => /$^/,  #  Will never match this one
        :regex_label => /^#{Branches}\s+#{Sym}$/
      },

      :immediate => { 
        :example     => 'AAA #$FF',
        :display     => '%s #$%.2X',
        :regex       => /^#{Mnemonic}\s+#{Immediate}$/
      },

      :implied => {
        :example     => 'AAA',
        :display     => '%s',
        :regex       => /^#{Mnemonic}$/
      },

      :zero_page => {
        :example     => 'AAA $FF',
        :display     => '%s $%.2X',
        :regex       => /^#{Mnemonic}\s+#{Hex8}$/
      },

      :zero_page_x => {
        :example     => 'AAA $FF, X',
        :display     => '%s $%.2X, X',
        :regex       => /^#{Mnemonic}\s+#{Hex8}\s?,\s?X$/
      },

      :zero_page_y => {
        :example     => 'AAA $FF, Y',
        :display     => '%s $%.2X, Y',
        :regex       => /^#{Mnemonic}\s+#{Hex8}\s?,\s?Y$/
      },

      :absolute => {
        :example     => 'AAA $FFFF',
        :display     => '%s $%.4X',
        :regex       => /^#{Mnemonic}\s+#{Hex16}$/,
        :regex_label => /^#{Mnemonic}\s+#{Sym}$/
      },

      :absolute_x => {
        :example     => 'AAA $FFFF, X',
        :display     => '%s $%.4X, X',
        :regex       => /^#{Mnemonic}\s+#{Hex16}\s?,\s?X$/,
        :regex_label => /^#{Mnemonic}\s+#{Sym}\s?,\s?X$/
      },

      :absolute_y => {
        :example     => 'AAA $FFFF, Y',
        :display     => '%s $%.4X, Y',
        :regex       => /^#{Mnemonic}\s+#{Hex16}\s?,\s?Y$/,
        :regex_label => /^#{Mnemonic}\s+#{Sym}\s?,\s?Y$/
      },

      :indirect => {
        :example     => 'AAA ($FFFF)',
        :display     => '%s ($%.4X)',
        :regex       => /^#{Mnemonic}\s+\(#{Hex16}\)$/,
        :regex_label => /^#{Mnemonic}\s+\(#{Sym}\)$/
      },

      :indirect_x => {
        :example     => 'AAA ($FF, X)',
        :display     => '%s ($%.2X, X)',
        :regex       => /^#{Mnemonic}\s+\(#{Hex8}\s?,\s?X\)$/,
        :regex_label => /^#{Mnemonic}\s+\(#{Sym}\s?,\s?X\)$/
      },

      :indirect_y => {
        :example     => 'AAA ($FF, X)',
        :display => '%s ($%.2X), Y',
        :regex       => /^#{Mnemonic}\s+\(#{Hex8}\)\s?,\s?Y$/,
        :regex_label => /^#{Mnemonic}\s+\(#{Sym}\)\s?,\s?Y$/
      }
    }

    ####
    ##  Parse one line of assembly, returns nil if the line
    ##  is ultimately empty of instructions or labels
    ##  Raises SyntaxError if the line is malformed in some way
    def self.parse(asm_line, address)

      ##  First, sanitize the line, which removes whitespace, and comments.
      sanitized = Assembler6502.sanitize_line(asm_line)

      ##  Empty lines assemble to nothing
      return nil if sanitized.empty?

      ##  Let's see if this line is an assembler directive
      directive = Directive.parse(sanitized, address)
      return directive unless directive.nil?


      ##  Let's see if this line is a label, and try 
      ##  to create a label for the current address
      label = Label.parse_label(sanitized, address)
      return label unless label.nil?

      ##  We must have some asm, so try to parse it in each addressing mode
      AddressingModes.each do |mode, parse_info|

        ##  We have regexes that match each addressing mode
        match_data = parse_info[:regex].match(sanitized)

        unless match_data.nil?
          ##  We must have a straight instruction without labels, construct 
          ##  an Instruction from the match_data, and return it
          _, op, arg = match_data.to_a
          return Instruction.new(op, arg, mode, address)

        else
          ##  Can this addressing mode even use labels?
          unless parse_info[:regex_label].nil?

            ##  See if it does in fact have a label/symbolic argument
            match_data = parse_info[:regex_label].match(sanitized)

            unless match_data.nil?
              ##  Yep, the arg is a label, we can resolve that to an address later
              ##  Buf for now we will create an Instruction where the label is a 
              ##  symbol reference to the label we found, ie. arg.to_sym
              _, op, arg = match_data.to_a
              return Instruction.new(op, arg.to_sym, mode, address)
            end
          end
        end
      end

      ##  We just don't recognize this line of asm, it must be a Syntax Error
      fail(SyntaxError, sprintf("%.4X: #{asm_line}", address))
    end


    ####
    ##  Create an instruction.  Having the instruction op a downcased symbol is nice
    ##  because that can later be used to index into our opcodes hash in OpCodes
    ##  OpCodes contains the definitions of each OpCode
    def initialize(op, arg, mode, address)

      ##  Lookup the definition of this opcode, otherwise it is an invalid instruction
      @op = op.downcase.to_sym
      definition = OpCodes[@op]
      fail(InvalidInstruction, op) if definition.nil?

      ##  Be sure the mode is an actually supported mode.
      @mode = mode.to_sym
      fail(InvalidAddressingMode, mode) unless AddressingModes.has_key?(@mode)

      ##  Make sure the address is in range 
      if address < 0x0 || address > 0xFFFF
        fail(AddressOutOfRange, address)
      end
      @address = address

      ##  Argument can either be a symbolic label, a hexidecimal number, or nil.
      @arg = case arg
      when Symbol then arg  
      when String
        if arg.match(/[0-9A-F]{1,4}/).nil?
          fail(SyntaxError, "#{arg} is not a valid hexidecimal number")
        else
          arg.to_i(16)
        end
      when nil then nil
      else
        fail(SyntaxError, "Cannot parse argument #{arg}")
      end

      if definition[@mode].nil?
        fail(InvalidInstruction, "#{op} cannot be used in #{mode} mode")
      end
      @description, @flags = definition.values_at(:description, :flags)
      @hex, @length, @cycles, @boundry_add = definition[@mode].values_at(:hex, :len, :cycles, :boundry_add)
    end


    ####
    ##  Does this instruction have unresolved symbols?
    def unresolved_symbols?
      @arg.kind_of?(Symbol)
    end


    ####
    ##  Resolve symbols
    def resolve_symbols(symbols)
      if unresolved_symbols?
        if symbols[@arg].nil?
          fail(SyntaxError, "Unknown symbol #{@arg.inspect}")
        end

        ##  Based on this instructions length, we should resolve the address
        ##  to either an absolute one, or a relative one.  The only relative addresses
        ##  are the branching ones, which are 2 bytes in size, hence the extra 2 byte difference
        case @length
        when 2
          @arg = symbols[@arg].address - @address - 2
        when 3
          @arg = symbols[@arg].address
        else
          fail(SyntaxError, "Probably can't use symbol #{@arg.inspect} with #{@op}")
        end
      end
    end


    ####
    ##  Emit bytes from asm structure
    def emit_bytes
      fail(UnresolvedSymbols, "Symbol #{@arg.inspect} needs to be resolved") if unresolved_symbols?
      case @length
      when 1
        [@hex]
      when 2
        [@hex, @arg]
      when 3
        [@hex] + break_16(@arg)
      else
        fail("Can't handle instructions > 3 bytes")
      end
    end


    ####
    ##  Hex dump of this instruction
    def hexdump
      emit_bytes.map{|byte| sprintf("%.2X", byte & 0xFF)}
    end


    ####
    ##  Pretty Print
    def to_s
      if unresolved_symbols?
        display = AddressingModes[@mode][:display]
        sprintf("%.4X | %s %s", @address, @op, @arg.to_s)
      else
        display = AddressingModes[@mode][:display]
        sprintf("%.4X | #{display}", @address, @op, @arg)
      end
    end

    private
    ####
    ##  Break an integer into two 8-bit parts
    def break_16(integer)
      [integer & 0x00FF, (integer & 0xFF00) >> 8]
    end

  end

end
