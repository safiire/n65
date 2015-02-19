# assembler6502

An NES assembler for the 6502 microprocessor written in Ruby

 Usage: ./assembler\_6502.rb <infile.asm> -o outfile.nes

  This is a pretty straightfoward assembler, that is currently set up
  to produce iNES ROM formatted binaries from simple assembly listings.
  It is good at knowing which addressing modes are and are not allowed for 
  each instruction, and contains some examples of correct syntax.

  Parsing is done by Regular Expression, because, well the language is
  so regular, it actually took less time than anything else I've tried
  to parse in the past, including Scheme using parsec.
  
  It handles labels, and does a two pass assembly, first assembling
  the byte codes, and then going back and filling in the proper addresses
  where labels were used.

  I have used this to compile some code for the NES, and it ran correctly
  on FCEUX, got it to make some sounds, load tiles, sprites, and scrolling.

  Some Todos:
  - I may make this into a Rubygem
  - Maybe I can put some better error messages.
  - Should I also make a 6502 Emulator in Ruby?

 Some new additions:
  - Ported NES101 tutor to this assembler.
  - Added msb and lsb byte selectors on address labels
  - added .org directive
  - added .dw directive
  - added .bytes directive
  - added .incbin directive
  - added .ascii directive
  - Invented my own iNES header directive that is JSON
  - Split the project up into separate files per class
  - Wrote some more unit tests
  - Added OptionParser for commandline opts
  - Tested a ROM with Sound output
  - Tested a ROM that changes background color

I decided that during the first pass of assembly, I should just initialize
an entire 65535 byte virtual memory images, and write the instructions to
their correct places, and then after resolving symbols during the second pass,
I just clip out the Cartridge ROM area and iNES header at the end, works great 
so far.

