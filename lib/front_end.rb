require 'optparse'

module Assembler6502

  ####
  ##  This class handles the front end aspects, 
  ##  parsing the commandline options and running the assembler
  class FrontEnd

    ####
    ##  Initialize with ARGV commandline
    def initialize(argv)
      @options = {:output_file => nil}
      @argv = argv.dup
    end


    ####
    ##  Run the assembler
    def run
      ##  First use the option parser
      parser = create_option_parser
      parser.parse!(@argv)

      ##  Whatever is leftover in argv the input files
      if @argv.size.zero?
        STDERR.puts("No input files")
        exit(1)
      end

      ##  Only can assemble one file at once for now
      if @argv.size != 1
        STDERR.puts "Can only assemble one input file at once :("
        exit(1)
      end

      input_file = @argv.shift

      ##  Make sure the input file exists
      unless File.exists?(input_file)
        STDERR.puts "Input file #{input_file} does not exist"
        exit(1)
      end
      
      ##  Maybe they didn't provide an output file name, so we'll guess
      if @options[:output_file].nil?
        ext = File.extname(input_file)
        @options[:output_file] = input_file.gsub(ext, '') + '.nes'
      end

      if @options.values.any?(&:nil?)
        STDERR.puts "Missing options try --help"
        exit(1)
      end

      begin
        Assembler6502::Assembler.from_file(input_file, @options[:output_file])
      rescue StandardError => error
        STDERR.puts("Assemble Failed!")
        STDERR.puts(error.class)
        if error.message
          STDERR.puts(error.message)
        end
        exit(1)
      end
    end

    private

    ####
    ##  Create a commandline option parser
    def create_option_parser
      OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} [options] <input_file.asm>"

        opts.on('-o', '--outfile filename', 'outfile') do |output_file|
          @options[:output_file] = output_file;
        end

        opts.on('-h', '--help', 'Displays Help') do
          puts opts
          exit
        end
      end
    end

  end

end
