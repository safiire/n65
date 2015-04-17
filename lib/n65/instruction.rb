require_relative 'opcodes'
require_relative 'regexes'

module N65

  ####
  ##  Represents a single 6502 Instruction
  class Instruction
    attr_reader :op, :arg, :mode, :hex, :description, :length, :cycle, :boundry_add, :flags, :address

    ##  Custom Exceptions
    class InvalidInstruction < StandardError; end
    class UnresolvedSymbols < StandardError; end
    class InvalidAddressingMode < StandardError; end
    class AddressOutOfRange < StandardError; end
    class ArgumentTooLarge < StandardError; end

    ##  Include Regexes
    include Regexes

    AddressingModes = {
      :relative => {
        :example     => 'B** my_label',
        :display     => '%s $%.4X',
        :regex       => /$^/i,  #  Will never match this one
        :regex_label => /^#{Branches}\s+#{Sym}$/
      },

      :immediate => {
        :example     => 'AAA #$FF',
        :display     => '%s #$%.2X',
        :regex       => /^#{Mnemonic}\s+#{Immediate}$/,
        :regex_label => /^#{Mnemonic}\s+#(<|>)#{Sym}$/
      },

      :implied => {
        :example     => 'AAA',
        :display     => '%s',
        :regex       => /^#{Mnemonic}$/
      },

      :zero_page => {
        :example     => 'AAA $FF',
        :display     => '%s $%.2X',
        :regex       => /^#{Mnemonic}\s+#{Num8}$/,
        :regex_label => /^#{Mnemonic}\s+#{Sym}\s+zp$/
      },

      :zero_page_x => {
        :example     => 'AAA $FF, X',
        :display     => '%s $%.2X, X',
        :regex       => /^#{Mnemonic}\s+#{Num8}\s?,\s?#{XReg}$/,
        :regex_label => /^#{Mnemonic}\s+#{Sym}\s?,\s?#{XReg}\s+zp$/
      },

      :zero_page_y => {
        :example     => 'AAA $FF, Y',
        :display     => '%s $%.2X, Y',
        :regex       => /^#{Mnemonic}\s+#{Num8}\s?,\s?#{YReg}$/,
        :regex_label => /^#{Mnemonic}\s+#{Sym}\s?,\s?#{YReg} zp$/
      },

      :absolute => {
        :example     => 'AAA $FFFF',
        :display     => '%s $%.4X',
        :regex       => /^#{Mnemonic}\s+#{Num16}$/,
        :regex_label => /^#{Mnemonic}\s+#{Sym}$/
      },

      :absolute_x => {
        :example     => 'AAA $FFFF, X',
        :display     => '%s $%.4X, X',
        :regex       => /^#{Mnemonic}\s+#{Num16}\s?,\s?#{XReg}$/,
        :regex_label => /^#{Mnemonic}\s+#{Sym}\s?,\s?#{XReg}$/
      },

      :absolute_y => {
        :example     => 'AAA $FFFF, Y',
        :display     => '%s $%.4X, Y',
        :regex       => /^#{Mnemonic}\s+#{Num16}\s?,\s?#{YReg}$/,
        :regex_label => /^#{Mnemonic}\s+#{Sym}\s?,\s?#{YReg}$/
      },

      :indirect => {
        :example     => 'AAA ($FFFF)',
        :display     => '%s ($%.4X)',
        :regex       => /^#{Mnemonic}\s+\(#{Num16}\)$/,
        :regex_label => /^#{Mnemonic}\s+\(#{Sym}\)$/
      },

      :indirect_x => {
        :example     => 'AAA ($FF, X)',
        :display     => '%s ($%.2X, X)',
        :regex       => /^#{Mnemonic}\s+\(#{Num8}\s?,\s?#{XReg}\)$/,
        :regex_label => /^#{Mnemonic}\s+\(#{Sym}\s?,\s?#{XReg}\)$/
      },

      :indirect_y => {
        :example     => 'AAA ($FF), Y)',
        :display => '%s ($%.2X), Y',
        :regex       => /^#{Mnemonic}\s+\(#{Num8}\)\s?,\s?#{YReg}$/,
        :regex_label => /^#{Mnemonic}\s+\(#{Sym}\)\s?,\s?#{YReg}$/
      }
    }

    ####
    ##  Parse one line of assembly, returns nil if the line
    ##  is ultimately empty of asm instructions
    ##  Raises SyntaxError if the line is malformed in some way
    def self.parse(line)

      ##  Try to parse this line in each addressing mode
      AddressingModes.each do |mode, parse_info|

        ##  We have regexes that match each addressing mode
        match_data = parse_info[:regex].match(line)

        unless match_data.nil?
          ##  We must have a straight instruction without symbols, construct
          ##  an Instruction from the match_data, and return it
          _, op, arg_hex, arg_bin = match_data.to_a

          ##  Until I think of something better, it seems that the union regex
          ##  puts a hexidecimal argument in one capture, and a binary in the next
          ##  This is annoying, but still not as annoying as using Treetop to parse
          if arg_hex != nil
            return Instruction.new(op, arg_hex.to_i(16), mode)
          elsif arg_bin != nil
            return Instruction.new(op, arg_bin.to_i(2), mode)
          else
            return Instruction.new(op, nil, mode)
          end

        else
          ##  Can this addressing mode even use labels?
          unless parse_info[:regex_label].nil?

            ##  See if it does in fact have a symbolic argument
            match_data = parse_info[:regex_label].match(line)

            unless match_data.nil?
              ##  We have found an assembly instruction containing a symbolic
              ##  argument.  We can resolve this symbol later by looking at the
              ##  symbol table in the #exec method
              match_array = match_data.to_a

              ##  If we have a 4 element array, this means we matched something
              ##  like LDA #<label, which is a legal immediate one byte value
              ##  by taking the msb.  We need to make that distinction in the
              ##  Instruction, by passing an extra argument
              if match_array.size == 4
                _, op, byte_selector, arg = match_array
                return Instruction.new(op, arg, mode, byte_selector.to_sym)
              else
                _, op, arg = match_array
                return Instruction.new(op, arg, mode)
              end
            end
          end
        end
      end

      ##  We just don't recognize this line of asm, it must be a Syntax Error
      fail(SyntaxError, line)
    end


    ####
    ##  Create an instruction.  Having the instruction op a downcased symbol is nice
    ##  because that can later be used to index into our opcodes hash in OpCodes
    ##  OpCodes contains the definitions of each OpCode
    def initialize(op, arg, mode, byte_selector = nil)

      @byte_selector = byte_selector.nil? ? nil : byte_selector.to_sym
      fail(InvalidInstruction, "Bad Byte selector: #{byte_selector}") unless [:>, :<, nil].include?(@byte_selector)

      ##  Lookup the definition of this opcode, otherwise it is an invalid instruction
      @op = op.downcase.to_sym
      definition = OpCodes[@op]
      fail(InvalidInstruction, op) if definition.nil?

      @arg = arg

      ##  Be sure the mode is an actually supported mode.
      @mode = mode.to_sym
      fail(InvalidAddressingMode, mode) unless AddressingModes.has_key?(@mode)

      if definition[@mode].nil?
        fail(InvalidInstruction, "#{op} cannot be used in #{mode} mode")
      end

      @description, @flags = definition.values_at(:description, :flags)
      @hex, @length, @cycles, @boundry_add = definition[@mode].values_at(:hex, :len, :cycles, :boundry_add)
    end


    ####
    ##  Is this instruction a zero page instruction?
    def zero_page_instruction?
      [:zero_page, :zero_page_x, :zero_page_y].include?(@mode)
    end


    ####
    ##  Execute writes the emitted bytes to virtual memory, and updates PC
    ##  If there is a symbolic argument, we can try to resolve it now, or
    ##  promise to resolve it later.
    def exec(assembler)

      promise = assembler.with_saved_state do |saved_assembler|
        @arg = saved_assembler.symbol_table.resolve_symbol(@arg)

        ##  If the instruction uses a byte selector, we need to apply that.
        @arg = apply_byte_selector(@byte_selector, @arg)

        ##  If the instruction is relative we need to work out how far away it is
        @arg = @arg - saved_assembler.program_counter - 2 if @mode == :relative

        saved_assembler.write_memory(emit_bytes)
      end

      case @arg
      when Fixnum, NilClass
        assembler.write_memory(emit_bytes)
      when String
        begin
          ##  This works correctly now :)
          promise.call
        rescue SymbolTable::UndefinedSymbol
          placeholder = [@hex, 0xDE, 0xAD][0...@length]
          ##  I still have to write a placeholder instruction of the right
          ##  length.  The promise will come back and resolve the address.
          assembler.write_memory(placeholder)
          return promise
        end
      end
    end


    ####
    ##  Apply a byte selector to an argument
    def apply_byte_selector(byte_selector, value)
      return value if byte_selector.nil?
      case byte_selector
      when :>
        high_byte(value)
      when :<
        low_byte(value)
      end
    end


    ####
    ##  Emit bytes from asm structure
    def emit_bytes
      case @length
      when 1
        [@hex]
      when 2
        if zero_page_instruction? && @arg < 0 || @arg > 0xff
          fail(ArgumentTooLarge, "For #{@op} in #{@mode} mode, only 8-bit values are allowed")
        end
        [@hex, @arg]
      when 3
        [@hex] + break_16(@arg)
      else
        fail("Can't handle instructions > 3 bytes")
      end
    end


    private
    ####
    ##  Break an integer into two 8-bit parts
    def break_16(integer)
      [integer & 0x00FF, (integer & 0xFF00) >> 8]
    end


    ####
    ##  Take the high byte of a 16-bit integer
    def high_byte(word)
      (word & 0xFF00) >> 8
    end


    ####
    ##  Take the low byte of a 16-bit integer
    def low_byte(word)
      word & 0xFF
    end

  end

end
