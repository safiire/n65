# frozen_string_literal: true

require 'optparse'
require_relative '../n65'

module N65
  # This class handles the front end aspects,
  # parsing the commandline options and running the assembler
  class FrontEnd
    def initialize(argv)
      @options = { output_file: nil, write_symbol_table: false, quiet: false, cycle_count: false }
      @argv = argv.dup
    end

    # Run the assembler
    def run
      parser = create_option_parser
      parser.parse!(@argv)

      if @argv.size.zero?
        warn('No input files')
        exit(1)
      end

      # Only can assemble one file at once for now
      if @argv.size != 1
        warn('Can only assemble one input file at once, but you can use .inc and .incbin directives')
        exit(1)
      end

      input_file = @argv.shift

      # Make sure the input file exists
      unless File.exist?(input_file)
        warn("Input file #{input_file} does not exist")
        exit(1)
      end

      # Maybe they didn't provide an output file name, so we'll guess
      if @options[:output_file].nil?
        ext = File.extname(input_file)
        @options[:output_file] = "#{input_file.gsub(ext, '')}.nes"
      end

      if @options.values.any?(&:nil?)
        warn('Missing options try --help')
        exit(1)
      end

      N65::Assembler.from_file(input_file, @options)
    end

    private

    def create_option_parser
      OptionParser.new do |opts|
        opts.banner = "Usage: #{$PROGRAM_NAME} [options] <input_file.asm>"

        opts.on('-o', '--outfile filename', 'outfile') do |output_file|
          @options[:output_file] = output_file
        end

        opts.on('-s', '--symbols', 'Outputs a symbol map') do
          @options[:write_symbol_table] = true
        end

        opts.on('-c', '--cycles', 'Outputs a cycle count yaml document') do
          @options[:cycle_count] = true
        end

        opts.on('-q', '--quiet', 'No output on success') do
          @options[:quiet] = true
        end

        opts.on('-v', '--version', 'Displays Version') do
          puts "N65 Assembler Version #{N65::VERSION}"
          exit
        end

        opts.on('-h', '--help', 'Displays Help') do
          puts opts
          exit
        end
      end
    end
  end
end
