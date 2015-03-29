require_relative '../instruction_base'

module N65


  ####
  ##  This directive instruction can include a binary file
  class IncBin < InstructionBase

    ####  Custom Exceptions
    class FileNotFound < StandardError; end


    ####
    ##  Try to parse an incbin directive
    def self.parse(line)
      match_data = line.match(/^\.incbin "([^"]+)"$/)
      return nil if match_data.nil?
      filename = match_data[1]
      IncBin.new(filename)
    end


    ####
    ##  Initialize with filename
    def initialize(filename)
      @filename = filename
    end


    ####
    ##  Execute on the assembler
    def exec(assembler)
      unless File.exists?(@filename)
        fail(FileNotFound, ".incbin can't find #{@filename}")
      end
      data = File.read(@filename).unpack('C*')
      assembler.write_memory(data)
    end


    ####
    ##  Display
    def to_s
      ".incbin \"#{@filename}\""
    end


  end

end
