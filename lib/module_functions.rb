
module Assembler6502

  ####
  ##  This cleans up a line, removing whitespace and newlines
  def sanitize_line(asm_line)
    sanitized = asm_line.split(';').first || ""
    sanitized.strip.chomp
  end
  module_function :sanitize_line

end
