;  Create an iNES header
.ines {"prog": 2, "char": 0, "mapper": 0, "mirror": 1}

;  The supermario.nsf file is 17084 bytes, this includes a 0x80 byte header.
;  It is supposed to be loaded into memory 0x8000, but we don't want that 
;  header, so let's include the nsf to 0x8000 - 0x80 so it lines up properly

.org $7F80
.incbin "super_mario.nsf"

;  Had to start this prog segment a bit later because the mario nsf is > 16KB
.org $C300
start:
  CLD
  SEI
  LDA #$00
  STA $2000

;  Wait for 2 vblanks
wait_vb1:
  LDA $2002
  BPL wait_vb1

wait_vb2:
  LDA $2002
  BPL wait_vb2

;  Clear out the sound registers
  LDA #$00
  LDX #$00
clear_sound_registers:
  STA $4000, X
  INX
  CPX #$0F
  BNE clear_sound_registers

  LDA #$10
  STA $4010
  LDA #$00
  STA $4011
  STA $4012
  STA $4013

;  Enable sound channels (except DMC)
  LDA #$0F
  STA $4015

;  Reset frame counter and clock divider
  LDA #$C0
  STA $4017

;  Set song and NTSC
  LDA #$00          ;  Song 0
  LDX #$00          ;  NTSC
  JSR $8000

;  Enable Vblank NMI
  LDA #$80
  STA $2000

forever:
  JMP forever

nmi:
  LDA $2002
  LDA #$00
  STA $2000
  LDA $80
  STA $2000
  JSR $8000
  RTI

irq:
  RTI

.ascii "The end of prog2"

.org $FFFA
  .dw nmi
  .dw start
  .dw irq

