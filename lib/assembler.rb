
module Assembler6502

  ####
  ##  An assembler
  class Assembler
    attr_reader :assembly_code

    ####
    ##  Assemble from a file to a file
    def self.from_file(infile, outfile)
      assembler = self.new(File.read(infile))
      byte_array = self.create_ines_header + assembler.assemble(0x8000)

      File.open(outfile, 'w') do |fp|
        fp.write(byte_array.pack('C*'))
      end
    end


    ####
    ##  iNES Header
    def self.create_ines_header
      [0x4E, 0x45, 0x53, 0x1a, 0x1, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0]
    end


    ####
    ##  Assemble 6502 Mnemomics into a program
    def initialize(assembly_code, label_index = {})
      @assembly_code = assembly_code
      @foreign_labels = label_index
    end


    ####
    ##  Assemble the 6502 assembly
    def assemble(start_address = 0x600)
      program_data = first_pass_parse(@assembly_code, start_address, @foreign_labels)
      @foreign_labels.merge!(program_data.labels)
      second_pass_resolve(program_data.instructions, @foreign_labels)
    rescue => exception
      STDERR.puts "Error:\n\t#{exception.message}"
      exit(1)
    end


    ####
    ##  Just a hexdump
    def hexdump
      assemble.map{|byte| sprintf("%.2x", (byte & 0xFF))}
    end


    ####
    ##  First pass of the assembler just parses each line.
    ##  Collecting labels, and leaving labels in instructions 
    ##  as placeholders, you can provide the code's start address,
    ##  or arbitrary labels that are not found the given asm
    def first_pass_parse(assembly_code, address = 0x0600, labels = {})
      instructions = []

      assembly_code.split(/\n/).each do |line|
        parsed_line = Assembler6502::Instruction.parse(line, address)
        case parsed_line
        when Label
          labels[parsed_line.label.to_sym] = parsed_line
        when Instruction
          instructions << parsed_line
          address += parsed_line.length
        when nil
        else
          fail(SyntaxError, sprintf("%.4X: Failed to parse: #{line}"))
        end
      end
      OpenStruct.new(:instructions => instructions, :labels => labels)
    end


    ####
    ##  The second pass makes each instruction emit bytes
    ##  while also using knowledge of label addresses to 
    ##  resolve absolute and relative usage of labels.
    def second_pass_resolve(instructions, labels)
      instructions.inject([]) do |sum, instruction|
        if instruction.unresolved_symbols?
          instruction.resolve_symbols(labels)
        end
        puts instruction
        sum += instruction.emit_bytes
        sum
      end
    end

  end

end
