

module N65

  ####
  ##  All the regexes used to parse in one module
  module Regexes
    ##  Mnemonics 
    Mnemonic  = '([A-Za-z]{3})'
    Branches  = '(BPL|BMI|BVC|BVS|BCC|BCS|BNE|BEQ|bpl|bmi|bvc|bvs|bcc|bcs|bne|beq)'

    ##  Numeric Literals
    Hex8      = '\$([A-Fa-f0-9]{1,2})'
    Hex16     = '\$([A-Fa-f0-9]{3,4})'

    Bin8      = '%([01]{1,8})'
    Bin16     = '%([01]{9,16})'

    Num8      = Regexp.union(Regexp.new(Hex8), Regexp.new(Bin8)).to_s
    Num16     = Regexp.union(Regexp.new(Hex16),Regexp.new(Bin16)).to_s

    Immediate = "\##{Num8}"

    ##  Symbols, must begin with a letter, and supports dot syntax
    Sym       = '([a-zA-Z][a-zA-Z\d_\.]*)'


    ##  The X or Y register
    XReg      = '[Xx]'
    YReg      = '[Yy]'
  end

end
