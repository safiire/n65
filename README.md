# assembler6502

An assembler for the 6502 Chip written in Ruby

 6502 Assembler

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
  on FCEUX, got it to make some sounds, etc.

  Some Todos:
  - I need to add the .byte operator to add data bytes.
  - I need to add the #\<$800 and #\>$800 style operators to select the
    MSB and LSB of immediate values during assembly.
  - I need to make the text/code/data sections easier to configure, it is 
    currently set to 0x8000 like NES Prog ROM
  - I need to add commandline options through the OptionParser library
  - I may make this into a Rubygem
  - I need to split the project up into one class per file like usual.
  - Maybe I can put some better error messages.
  - I should just make a 6502 CPU emulator probably now too.
