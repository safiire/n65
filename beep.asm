  ;  Create an iNES header
  .ines {"prog": 1, "char": 0, "mapper": 0, "mirror": 1}

  ;  Here is the start of our code
  .org $C000
start:
  LDA #$01	; square 1
  STA $4015
  LDA #$08	; period low
  STA $4002
  LDA #$02	; period high
  STA $4003
  LDA #$BF	; volume
  STA $4000
forever:
  JMP forever

nmi:
  RTI

  .org $FFFA     ;  Here are the three interrupt vectors
  .dw  nmi       ;  VBlank non-maskable interrupt
  .dw  start     ;  When the processor is reset or powers on
  .dw  $0        ;  External interrupt IRQ
