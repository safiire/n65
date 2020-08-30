#!/usr/bin/env ruby
# frozen_string_literal: true

##############################################################################
# From http://www.6502.org/tutorials/6502opcodes.html
# This web page has information about each and every 6502 instruction
# Specifically:
#
# - Description of what each of the instructions do
# - Which modes are supported by which instructions, immediate, zero page
#   zero page x, and y, absolute, indirect, relative etc.
# - The hex codes each instruction assembles to, in each mode.
# - The lengths in bytes of each instruction, by mode
# - The possibly variable number of cycles each instruction takes.
#
# There are 56 of them, and in my programmer laziness I just wrote this
# script to parse the page into the data structure that you see in
# opcodes.yaml.  This really helped in creating the assembler, and
# it had basically everything I needed to know, and sped up writing
# this by huge factor.  So, yay to this page, and this script!

require 'yaml'

# Instruction name, and output structure to fill in.
name = :adc
output = { name: {} }

# Copy paste the tables from that website into this heredoc:
text = <<~'TEXT'
  Immediate     ADC #$44      $69  2   2
  Zero Page     ADC $44       $65  2   3
  Zero Page,X   ADC $44,X     $75  2   4
  Absolute      ADC $4400     $6D  3   4
  Absolute,X    ADC $4400,X   $7D  3   4+
  Absolute,Y    ADC $4400,Y   $79  3   4+
  Indirect,X    ADC ($44,X)   $61  2   6
  Indirect,Y    ADC ($44),Y   $71  2   5+
TEXT

# And now iterate over each line to extract the info
lines = text.split(/\n/)
lines.each do |line|
  # Grab out the values we care about
  parts = line.split
  cycles, len, hex = parts[-1], parts[-2], parts[-3]
  hex = format('0x%X', hex.gsub('$', '').to_i(16))

  match_data = cycles.match(/([0-9]+)(\+?)/)
  cycles = match_data[1]
  boundary = match_data[2]
  hash = { hex: hex, len: len, cycles: cycles, boundry_add: boundary != '' }

  # And now decide which mode the line belongs to, collecting each listed mode
  hash = case line
         when /^Accumulator/
           { accumulator: hash }
         when /^Immediate/
           { immediate: hash }
         when /^Zero Page,X/
           { zero_page_x: hash }
         when /^Zero Page,Y/
           { zero_page_y: hash }
         when /^Zero Page/
           { zero_page: hash }
         when /^Absolute,X/
           { absolute_x: hash }
         when /^Absolute,Y/
           { absolute_y: hash }
         when /^Absolute/
           { absolute: hash }
         when /^Indirect,X/
           { indirect_x: hash }
         when /^Indirect,Y/
           { indirect_y: hash }
         when /^Indirect/
           { indirect: hash }
         when /^Implied/
           { implied: hash }
         else
           {}
         end
  output[name].merge!(hash)
end

# Now output some yaml, and I only had to do this about 45 times
# instead of laboriously and mistak-pronely doing it by hand.
puts YAML.dump(output).gsub("'", '')

# See opcodes.yaml
