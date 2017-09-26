.ines {"prog": 1, "char": 0, "mapper": 0, "mirror": 0}
.inc <nes.sym>

.segment prog 0

;;  SRAM Variables
.org $0000
.scope audio
  .space timer 1
  .space next_note 1
  .space note_frequency 2
.

;;  Interrupt vectors
.org $FFFA
.dw vblank
.dw main
.dw irq


.org $C000
.scope main
  sei
  cld

  ;;  Setup the stack
  ldx #$ff
  txs

  ;;  Disable rendering, reset APU
  ldx #$00
  stx nes.ppu.control
  stx nes.ppu.mask
  jsr zero_apu

  .scope
    wait_vblank:
      bit nes.ppu.status
      bpl wait_vblank
  .

  clear_ram:
    lda #$00
    sta $00, x
    sta $100, x
    sta $300, x
    sta $400, x
    sta $500, x
    sta $600, x
    sta $700, x
    lda #$ff
    sta $200, x
    inx
    bne clear_ram

  .scope
    wait_vblank:
      bit nes.ppu.status
      bpl wait_vblank
  .

  jsr initialize

  forever:
    jmp forever
  rti
.


;;  Zero the APU
.scope zero_apu
  lda #$00
  ldx #$00
  loop:
    sta $4000, x
    inx
    cpx $18
    bne loop
  rts
.


;;  Initialize PPU and APU
.scope initialize
  lda #%00000011
  sta nes.apu.channel_enable

  ;  Reenable interrupts, Turn Vblank back on
  lda #%10000000
  sta nes.ppu.control

  ;  Initialize the audio structure
  lda #$00
  sta audio.timer zp
  lda #$30
  sta audio.next_note zp

  cli
  rts
.


;;  Keep time via 60fps vblank
.scope vblank
  ;  Update the audio timer so it resets every 64 frames
  ldx audio.timer zp
  inx
  txa
  and #%00000011
  sta audio.timer zp
  bne return

  ;  Play the next note on reset
  lda audio.next_note zp
  cmp #$80
  bmi continue
  lda #$30

  continue:
  jsr play_note
  sta audio.next_note zp
  inc audio.next_note zp

  return:
  rti
.


;;  Hi and lo byte tables for note frequencies
.scope midi_notes
  .scope hi
    .bytes $35, $32, $2f, $2c, $2a, $28, $25, $23, $21, $1f, $1d, $1c, $1a, $19, $17, $16
    .bytes $15, $14, $12, $11, $10, $0f, $0e, $0e, $0d, $0c, $0b, $0b, $0a, $0a, $09, $08
    .bytes $08, $07, $07, $07, $06, $06, $05, $05, $05, $05, $04, $04, $04, $03, $03, $03
    .bytes $03, $03, $02, $02, $02, $02, $02, $02, $02, $01, $01, $01, $01, $01, $01, $01
    .bytes $01, $01, $01, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .bytes $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .bytes $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .bytes $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .
  .scope lo
    .bytes $71, $71, $9c, $f0, $6a, $09, $ca, $ab, $aa, $c6, $fe, $4f, $b8, $38, $ce, $78
    .bytes $35, $04, $e4, $d5, $d5, $e3, $fe, $27, $5b, $9c, $e6, $3b, $9a, $01, $72, $ea
    .bytes $6a, $f1, $7f, $13, $ad, $4d, $f3, $9d, $4c, $00, $b8, $74, $34, $f8, $bf, $89
    .bytes $56, $26, $f9, $ce, $a6, $80, $5c, $3a, $1a, $fb, $df, $c4, $ab, $93, $7c, $67
    .bytes $52, $3f, $2d, $1c, $0c, $fd, $ef, $e1, $d5, $c9, $bd, $b3, $a9, $9f, $96, $8e
    .bytes $86, $7e, $77, $70, $6a, $64, $5e, $59, $54, $4f, $4b, $46, $42, $3f, $3b, $38
    .bytes $34, $31, $2f, $2c, $29, $27, $25, $23, $21, $1f, $1d, $1b, $1a, $18, $17, $15
    .bytes $14, $13, $12, $11, $10, $0f, $0e, $0d, $0c, $0c, $0b, $0a, $0a, $09, $08, $08
  .
.


;;  Play midi note held in A
.scope play_note
  pha
  tax
  lda #%10011111
  sta nes.apu.pulse1.control

  ;  Get the low byte of the timer
  ldy midi_notes.lo, x
  sty nes.apu.pulse1.ft
  sty audio.note_frequency+1 zp

  ;  Get the high 3 bits of the timer
  ldy midi_notes.hi, x
  tya
  and #%00000111
  ora #%11111000
  sta nes.apu.pulse1.ct
  sta audio.note_frequency zp

  pla
  rts
.


;;  IRQ, we are not using
.scope irq
  rti
.
