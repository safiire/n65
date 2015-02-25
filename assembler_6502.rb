#!/usr/bin/env ruby
###############################################################################
##  6502 Assembler
##
##  Usage: ./assembler_6502.rb <infile.asm>
##
##  This the front end of the Assembler, just processes commandline arguments
##  and passes them to the actual assembler.

require_relative 'lib/assembler'
require_relative 'lib/front_end'

Assembler6502::FrontEnd.new(ARGV).run
