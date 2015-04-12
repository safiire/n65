require_relative '../instruction_base'
module N65


  ####
  ##  This directive instruction can include a binary file
  class Segment < InstructionBase

    ####
    ##  Try to parse a dw directive
    def self.parse(line)
      match_data = line.match(/^.segment (prog|char) (\d+)$/i)
      unless match_data.nil?
        _, segment, bank = match_data.to_a
        return Segment.new(segment, bank.to_i)
      end
      nil
    end


    ####
    ##  Initialize with filename
    def initialize(segment, bank)
      @bank = bank
      @segment = segment
    end


    ####
    ##  Execute the segment and bank change on the assembler
    def exec(assembler)
      assembler.current_segment = @segment
      assembler.current_bank = @bank
    end


    ####
    ##  Display
    def to_s
      ".segment #{@segment} #{@bank}"
    end

  end

end
