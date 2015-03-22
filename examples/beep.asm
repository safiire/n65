;  Create an iNES header
.ines {"prog": 1, "char": 0, "mapper": 0, "mirror": 1}

  ;  Here is the start of our code
.org $C000
.scope main
  LDA #$01	; square 1
  STA $4015
  LDA #$F8	; period low
  STA $4002
  LDA #$02	; period high
  STA $4003
  LDA #$BF	; volume
  STA $4000
  forever:
    JMP forever

nothing:
  RTI

  .org $FFFA     ;  Here are the three interrupt vectors
  .dw  nothing   ;  VBlank non-maskable interrupt
  .dw  main      ;  When the processor is reset or powers on
  .dw  nothing   ;  External interrupt IRQ
