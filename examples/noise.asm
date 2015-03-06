;------------------------------------------------------------------------------
;  This is a direct port of Michael Martin's tutorial project for NES101
;  With some modifications to the tile map, and extra comments, and ported to
;  suit my assembler. - Saf
;  See:
;  http://hackipedia.org/Platform/Nintendo/NES/tutorial,%20NES%20programming%20101/NES101.html
;
;;;;
;  Create an iNES header
.ines {"prog": 1, "char": 0, "mapper": 0, "mirror": 0}

;;;;
;  Here is a good spot to associate zero page memory addresses
;  with quick access variables in the program.

.org $0200
sprite:


;;;;
;  Setup the interrupt vectors
.org $FFFA
.dw vblank
.dw main
.dw irq


.org $C000
;;;;
;  Here is our code entry point, which we'll call main.
main:
  ;  Disable interrupts and decimal flag
  sei
	cld

  ;  Wait for 2 vblanks
  wait_vb1:
    lda $2002
    bpl wait_vb1
  wait_vb2:
    lda $2002
    bpl wait_vb2

  ;  Now we want to initialize the hardware to a known state
  lda #$00
  ldx #$00
  clear_segments:
    sta $00, X
    sta $0100, X
    sta $0200, X
    sta $0300, X
    sta $0400, X
    sta $0500, X
    sta $0600, X
    sta $0700, X
    inx
    bne clear_segments

  ;  Reset the stack pointer
  ldx #$FF
  txs

	; Disable all graphics.
  lda #$00
  sta $2000
  sta $2001

  ;  Init APU
  ldx #$0F
  stx $4015

  ;  Turn on noise tone
  ldx #$85
  stx $400E

  ;  Set volume to max
  ldx #$3F
  stx $400C

  ; Load Length counter
  ldx #$01
  stx $400F

  ;  Resume interrupts and loop here forever
	cli
  forever:
    jmp forever


;;;;
;  Update everything on every vblank
vblank: 
  rti


;;;;
;  Don't do anything on IRQ
irq:    
  rti
