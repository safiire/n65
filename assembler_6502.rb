#!/usr/bin/env ruby
###############################################################################
##  6502 Assembler
##
##  Usage: ./assembler_6502.rb <infile.asm>
##
##  This is a pretty straightfoward assembler, that is currently set up
##  to produce iNES ROM formatted binaries from simple assembly listings.
##  It is good at knowing which addressing modes are and are not allowed for 
##  each instruction, and contains some examples of correct syntax.
##
##  Parsing is done by Regular Expression, because, well the language is
##  so regular, it actually took less time than anything else I've tried
##  to parse in the past, including Scheme using parsec.
##  
##  It handles labels, and does a two pass assembly, first assembling
##  the byte codes, and then going back and filling in the proper addresses
##  where labels were used.
##
##  I have used this to compile some code for the NES, and it ran correctly
##  on FCEUX, got it to make some sounds, etc.
##
##  Some Todos:
##  - I need to add the #<$800 and #>$800 style operators to select the
##    MSB and LSB of immediate values during assembly.
##  - I may make this into a Rubygem
##  - Maybe I can put some better error messages.
##  - I should just make a 6502 CPU emulator probably now too.


require 'yaml'
require 'ostruct'
require 'optparse'
require_relative 'lib/directive'
require_relative 'lib/assembler'
require_relative 'lib/instruction'
require_relative 'lib/label'

module Assembler6502

  #####
  ##  Load in my OpCode definitions
  MyDirectory = File.expand_path(File.dirname(__FILE__))
  OpCodes = YAML.load_file("#{MyDirectory}/data/opcodes.yaml")

  ####
  ##  Clean up a line of assembly
  def sanitize_line(asm_line)
    sanitized = asm_line.split(';').first || ""
    sanitized.strip.chomp
  end
  module_function :sanitize_line


  ####
  ##  Run the assembler using commandline arguments
  def run
    options = {:out_file => nil}
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options] <input_file.asm>"

      opts.on('-o', '--outfile filename', 'outfile') do |out_file|
        options[:out_file] = out_file;
      end

      opts.on('-h', '--help', 'Displays Help') do
        puts opts
        exit
      end
    end
    parser.parse!(ARGV)

    ##  For now let's just handle one file at a time.
    if ARGV.size != 1
      STDERR.puts "Can only assemble one input file at once :("
      exit(1)
    end
    input_file = ARGV.shift

    ##  Make sure the input file exists
    unless File.exists?(input_file)
      STDERR.puts "Input file #{input_file} does not exist"
      exit(1)
    end
    
    ##  Maybe they didn't provide an output file name, so we'll guess
    if options[:out_file].nil?
      ext = File.extname(input_file)
      options[:out_file] = input_file.gsub(ext, '') + '.nes'
    end

    if options.values.any?(&:nil?)
      STDERR.puts "Missing options try --help"
      exit(1)
    end
    Assembler6502::Assembler.from_file(input_file, options[:out_file])
  end
  module_function :run

end

Assembler6502.run
