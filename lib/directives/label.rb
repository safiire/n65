
module N65

  ####
  ##  This class represents a label, and will create 
  ##  an entry in the symbol table associated with 
  ##  the address it appears at.
  class Label

    ####
    ##  Try to parse as a label
    def self.parse(line)
      match_data = line.match(/^([a-zA-Z][a-zA-Z0-9_]+):$/)
      unless match_data.nil?
        label = match_data[1].to_sym
        return self.new(label)
      end
      nil
    end


    ####
    ##  Create a new label object
    def initialize(symbol)
      @symbol = symbol
    end


    ####
    ##  Create an entry in the symbol table for this label
    def exec(assembler)
      program_counter = assembler.program_counter
      assembler.symbol_table.define_symbol(@symbol, program_counter)
    end


    ####
    ##  Display
    def to_s
      "#{@symbol}:"
    end


  end

end
