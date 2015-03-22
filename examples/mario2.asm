;------------------------------------------------------------------------------
;  Let's try to recreate a bit of a level from Mario 2
;
;;;;
;  Create an iNES header
.ines {"prog": 1, "char": 1, "mapper": 0, "mirror": 0}


;;;;
;  Include all the symbols in the nes library
.inc <nes.sym>


;;;;
;  Open the prog section bank 0
.segment prog 0

;;;;
;  Current horizontal scroll value
.org $0000
.space horizontal_scroll 1


;;;;
;  Setup the interrupt vectors
.org $FFFA
.dw vblank
.dw main
.dw irq


;;;;
;  Here is our code entry point, which we'll call main.
.org $C000
.scope main
  ;  Disable interrupts and decimal flag
  sei
  cld

  ;  Wait for 2 vblanks
  wait_vb1:
    lda nes.ppu.status
    bpl wait_vb1
  wait_vb2:
    lda nes.ppu.status
    bpl wait_vb2

  ;  Now we want to initialize the hardware to a known state
  lda #$00
  ldx #$00
  clear_segments:
    sta $00, x
    sta $0100, x
    sta $0200, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    inx
    bne clear_segments

  ;  Reset the stack pointer
  ldx #$FF
  txs

  ;  Disable all graphics and vblank nmi
  lda #$00
  sta nes.ppu.control1
  sta nes.ppu.control2

  ;  Call subroutines to initialize the graphics
  jsr load_palette
  jsr load_name_tables
  jsr init_scrolling
  jsr init_ppu

  ;  Resume interrupts and loop here forever
  cli
  forever:
    jmp forever
.


;;;;
; Set basic PPU registers.  Load background from $0000,
; sprites from $1000, and the name table from $2000.
; These literals would make more sense in binary.
.scope init_ppu
  lda #$88
  sta nes.ppu.control1
  lda #$1E
  sta nes.ppu.control2
  rts
.


;;;;
;  This initializes the scrolling value in the zero page 
;  So that we begin offscreen and can scroll down
.scope init_scrolling
  lda #$00
  sta horizontal_scroll zp
  rts
.


;;;;
;  Load palette into $3F00
.scope load_palette
  lda #$3F
  ldx #$00
  sta nes.vram.address
  stx nes.vram.address
  loop:
    lda palette, x
    sta nes.vram.io
    inx
    cpx #$20
    bne loop
  rts
.


;;;;
;  Load the background tiles into the name table
.scope load_name_tables
  ldy #$00
  ldx #$04
  lda #<background
  sta $10           
  lda #>background
  sta $11
  lda #$24
  sta nes.vram.address
  lda #$00
  sta nes.vram.address
  loop:
    lda ($10), y
    sta nes.vram.io
    iny
    bne loop
    inc $11
    dex
    bne loop
  ;  Now clear the second nametable
  ldy #$00
  ldx #$04
  lda #$00
  .scope
    loop:
      sta nes.vram.io
      iny
      bne loop
      dex
      bne loop
  .
  rts
.


;;;;
;  Scroll the screen if we have to
.scope scroll_screen
  ldx #$00                ; Reset VRAM Address to $0000
  stx nes.vram.address
  stx nes.vram.address

  ldx horizontal_scroll zp
  inx
  stx horizontal_scroll zp


  lda #$00
  stx nes.ppu.scroll      ; Write the new horizontal scroll value
  sta nes.ppu.scroll      ; Write 0 for vertical scroll
  rts
.


;;;;
;  VBlank routine
.scope vblank
  jsr scroll_screen
  rti
.


.scope irq
  rti
.

;;;;
;  Here is a bg palette which I ripped from Mario 2, but, I just put black for sprite palette
palette:
.bytes $21, $30, $12, $0F, $21, $30, $16, $0F, $21, $27, $17, $0F, $21, $29, $1A, $0F
.bytes $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F


;;;;
;  This is the background tile map, or "Name Table" for a bit of a Mario 2 Level.
;  Here is how I generated this from a string of hex
;  ary.map{|byte| "$%.2X" % byte.to_i(16) }.each_slice(32){|group| puts ".bytes #{group.join(', ')}" }
background:
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $BA, $BC, $FA, $FA, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $BB, $BD, $FA, $FA, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $BA, $BC, $FA, $FA, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $BB, $BD, $FA, $FA, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $BA, $BC, $FA, $FA, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $BB, $BD, $FA, $FA, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $BA, $BC, $FA, $FA, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $BB, $BD, $FA, $FA, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $BA, $BC, $FA, $FA, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $BB, $BD, $FA, $FA, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $BA, $BC, $FA, $FA, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $B0, $B1, $B0, $B1, $90, $91, $FA, $FA, $FA, $FA
.bytes $B4, $B6, $B8, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $60, $62, $64, $62, $64, $62, $64, $62, $64, $66, $FA, $FA
.bytes $B5, $B7, $B9, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $46, $63, $65, $63, $65, $63, $65, $63, $65, $67, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $61, $63, $65, $63, $65, $63, $65, $63, $65, $67, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $61, $63, $65, $63, $65, $63, $65, $63, $65, $67, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $DE, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $61, $63, $65, $63, $65, $63, $65, $63, $65, $67, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $61, $63, $65, $63, $65, $63, $65, $63, $65, $67, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $61, $63, $65, $63, $65, $63, $65, $63, $65, $67, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $61, $63, $65, $63, $65, $63, $65, $63, $65, $67, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $61, $63, $65, $63, $65, $63, $65, $63, $65, $67, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $61, $63, $65, $63, $65, $63, $65, $63, $65, $67, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $61, $63, $65, $63, $65, $63, $65, $63, $65, $67, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $61, $63, $65, $63, $65, $63, $65, $63, $65, $67, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $61, $63, $65, $63, $65, $63, $65, $63, $65, $67, $FA, $FA
.bytes $FA, $FA, $FA, $FA, $FA, $FA, $B0, $B1, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $FA, $61, $63, $65, $63, $65, $63, $65, $63, $65, $67, $FA, $FA
.bytes $70, $72, $70, $72, $70, $72, $70, $72, $70, $72, $70, $72, $70, $72, $70, $72, $70, $72, $70, $72, $70, $72, $70, $72, $70, $72, $70, $72, $70, $72, $70, $72
.bytes $71, $73, $71, $73, $71, $73, $71, $73, $71, $73, $71, $73, $71, $73, $71, $73, $71, $73, $71, $73, $71, $73, $71, $73, $71, $73, $71, $73, $71, $73, $71, $73
.bytes $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AF
.bytes $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AE, $AE, $AE, $AE, $AE, $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AF, $AE, $AF
.bytes $55, $55, $55, $55, $33, $44, $DD, $DD, $57, $55, $55, $55, $33, $44, $DD, $DD, $55, $55, $55, $55, $33, $44, $DD, $DD, $50, $55, $55, $55, $CC, $FF, $FF, $FF
.bytes $55, $55, $55, $54, $FF, $FF, $FF, $FF, $55, $55, $55, $55, $33, $FF, $FF, $FF, $F5, $F5, $F5, $F5, $F3, $FF, $FF, $FF, $5A, $5A, $5A, $5A, $0A, $0A, $0A, $0A


;;;;
;  Here is my character (tile) data
.segment char 0
.org $0000
.incbin "mario2.char"

