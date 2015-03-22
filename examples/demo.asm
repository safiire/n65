;------------------------------------------------------------------------------
;  This is a direct port of Michael Martin's tutorial project for NES101
;  With some modifications to the tile map, and extra comments, and ported to
;  suit my assembler. - Saf
;  See:
;  http://hackipedia.org/Platform/Nintendo/NES/tutorial,%20NES%20programming%20101/NES101.html
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
;  Here is a good spot to associate zero page memory addresses
;  to symbols that we can use throughout the program.
.org $0000
.space dx 1
.space a_button 1
.space scroll 1


;;;;
;  We can use scope to declare a C like struct at $0200
.org $0200
.scope sprite
  .space y 1
  .space pattern 1
  .space color 1
  .space x 1
.


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
  lda #%00
  ldx #$00
  clear_segments:
    sta $0, x
    sta $100, x
    sta $200, x
    sta $300, x
    sta $400, x
    sta $500, x
    sta $600, x
    sta $700, x
    inx
    bne clear_segments

  ;  Reset the stack pointer
  ldx #$FF
  txs

  ;  Disable all graphics and vblank nmi
  lda #$00
  sta nes.ppu.control
  sta nes.ppu.mask

  jsr init_graphics
  jsr init_input
  jsr init_sound
  jsr init_ppu

  ;  Resume interrupts and loop here forever
  cli
  forever:
    jmp forever
.


;;;;
; nes.ppu.control: bitpattern is VPHB SINN
;   V:  NMI enable
;   P:  PPU master/slave (this does nothing on the NES)
;   H:  Sprite height 0 = 8x8, 1 = 8x16
;   B:  Background pattern table address (0: $0000; 1: $1000)
;   S:  Sprite pattern table address for 8x8 sprites (0: $0000; 1: $1000; ignored in 8x16 mode)
;   I:  VRAM address increment per CPU read/write of nes.vram.io (0: add 1, going across; 1: add 32, going down)
;   NN: Base nametable address (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
;
;   Equivalently, bits 0 and 1 are the most significant bit of the scrolling coordinates
;
; nes.ppu.mask: bitpattern is BGRs bMmG
;   BGR: Color emphasis bits
;   s:   Sprite enable
;   b:   Background enable
;   M:   Background left column enable
;   m:   Sprite left column enable
;   G:   Greyscale
;
.scope init_ppu
  lda #%10001000         ; NMI enable, 8x8 tile, Background: $0000, Sprites: $1000, Address increment: 1, Nametable: $2000
  sta nes.ppu.control
  lda #%00011110         ; No color emphasis, Enable sprites, Enable Background, Enable sprite and bg left column, no greyscale
  sta nes.ppu.mask
  rts
.


;;;;
;  Initialize all the sprites, palettes, nametables, and scrolling
.scope init_graphics
  jsr init_sprites
  jsr load_palette
  jsr load_name_tables
  jsr init_scrolling
  rts
.


;;;;
;  Initialize the controller input, keeping track of the A button
.scope init_input
  lda #$00
  sta a_button zp
  rts
.


;;;;
;  Initialize the APU to known values
.scope init_sound
  lda #$01
  sta nes.apu.channel_enable
  lda #$00
  sta nes.apu.pulse1.ramp_control
  rts
.


;;;;
;  Clear page #2, which we'll use to hold sprite data
;  This subroutine clearly shows why I need to have symbols
;  to refer to bits of RAM in the zero page like dx, etc.
.scope init_sprites
  lda #$00
  ldx #$00
  sprite_clear1:
    sta sprite, x
    inx
    bne sprite_clear1

  ; initialize Sprite 0
  lda #$70                       ;  Y Coordinate
  sta sprite.y                   ;  Initialize the y value of sprite 
  lda #$01
  sta sprite.pattern             ;  Pattern number 1
  sta sprite.x                   ;  X value also 1, and leave color 0

  ; Set initial value of dx
  lda #$01
  sta dx zp                      ; Initialize delta x value to 1
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
; Put the ASCII values from bg into the first name table, at $2400
; The tile values are conveniently mapped to their ASCII values
.scope load_name_tables
  ldy #$00
  ldx #$04
  lda #<bg
  sta $10           
  lda #>bg
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
  ;  This now clears the second name table?
  ;  I think this is because writing to $2007 auto increments the
  ;  written value
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
;  This initializes the scrolling value in the zero page 
;  So that we begin offscreen and can scroll down
.scope init_scrolling
  lda #$F0
  sta scroll zp
  rts
.


;;;;
;  Update the sprite, I don't exactly understand the DMA call yet.
.scope update_sprite
  lda #>sprite
  sta nes.oam.dma           ; Jam page $200-$2FF into SPR-RAM, how do we get these numbers?
  lda sprite.x             
  beq hit_left
  cmp #$F7
  bne edge_done          ; Detect hitting either edge
  ; Hit right
  ldx #$FF
  stx dx zp
  jsr high_c             ; And play a high C note if we do
  jmp edge_done

  hit_left:
    ldx #$01
    stx dx zp
    jsr high_c

  edge_done:                ; update X and store it.
    clc
    adc dx zp  
    sta sprite.x            
  rts
.


;;;;
;  Read the first controller, and handle input
.scope react_to_input
  lda #$01                ; strobe joypad
  sta nes.controller1
  lda #$00
  sta nes.controller1

  lda nes.controller1     ; Is the A button down?
  and #$01
  beq not_a
  ldx a_button zp
  bne a_done              ; Only react if the A button wasn't down last time.
  sta a_button zp         ; Store the 1 in local variable 'a' so that we this is
  jsr reverse_dx          ; only called once per press.
  jmp a_done
  not_a:  
    sta a_button zp       ; A has been released, so put that zero into 'a'.
  a_done: 
    lda nes.controller1   ; B does nothing
    lda nes.controller1   ; Select does nothing
    lda nes.controller1   ; Start does nothing
    lda nes.controller1   ; Up
    and #$01
    beq not_up
    ldx sprite.y          ; Load Y value
    cpx #$07
    beq not_up            ; No going past the top of the screen
    dex
    stx sprite.y

  not_up: 
    lda nes.controller1   ; Down
    and #$01
    beq not_dn
    ldx sprite.y
    cpx #$DF                  ; No going past the bottom of the screen.
    beq not_dn
    inx
    stx sprite.y
  not_dn: 
  rts                         ; Ignore left and right
.


;;;;
;  XORing with $ff toggles between 0x1 and 0xfe (-1)
.scope reverse_dx
  lda #$FF
  eor dx zp
  clc
  adc #$01         ; Add dx, and store to variable
  sta dx zp
  jsr low_c        ; Play the reverse low C note
  rts
.


;;;;
;  Scroll the screen if we have to
.scope scroll_screen
  ldx #$00                ; Reset VRAM Address to $0000
  stx nes.vram.address
  stx nes.vram.address

  ldx scroll zp           ; Do we need to scroll at all?
  beq return
  dex
  stx scroll zp           
  lda #$00
  sta nes.ppu.scroll  ; Write 0 for Horiz. Scroll value
  stx nes.ppu.scroll  ; Write the value of 'scroll' for Vert. Scroll value

  return:
  rts
.

  
;;;;
;  Play a low C note on square 1
.scope low_c
  pha
  lda #$84
  sta nes.apu.pulse1.control
  lda #$AA
  sta nes.apu.pulse1.ft
  lda #$09
  sta nes.apu.pulse1.ct
  pla
  rts
.


;;;;
;  Play a high C note on square 1
.scope high_c
  pha
  lda #$86
  sta nes.apu.pulse1.control
  lda #$69
  sta nes.apu.pulse1.ft
  lda #$08
  sta nes.apu.pulse1.ct
  pla
  rts
.


;;;;
;  Update everything on every vblank
.scope vblank
  jsr scroll_screen
  jsr update_sprite
  jsr react_to_input
  rti
.


;;;;
;  Don't do anything on IRQ
irq:    
  rti


;;;;
;  Palette data stored in the PROG section, to be copied later
;  There are four groups of four colors.  The first line is tile colors
;  and the second line is sprite colors.  These are combined with the attribute
;  table to create the final color on screen.  I have a feeling this is a bit
;  wrong, as every 4th color should be the same, because it is ultimately wired 
;  to the same memory address, and represents the transparent background color.
;  I will look into this.
palette:
.bytes $0E,$00,$0E,$19,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$01,$21
.bytes $0E,$20,$22,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00


;;;;
;  Background data stored in the PROG section to be copied later
;  See below where the tile numbers are mapped to ASCII values
bg:
.ascii "                                "
.ascii "                                "
.ascii "   SAF'S 6502 NES ASSEMBLER     "
.ascii "                                "
.ascii "                                "
.ascii "                                "
.ascii "    VSS              RES        "
.ascii "    RDY              PHI2       "
.ascii "    PH1              S0         "
.ascii "    IRQ      6       PHI0       "
.ascii "     NC              NC         "
.ascii "    NMI              NC         "
.ascii "   SYNC      5       R/W        "
.ascii "    VCC              D0         "
.ascii "     A0              D1         "
.ascii "     A1      0       D2         "
.ascii "     A2              D3         "
.ascii "     A3              D4         "
.ascii "     A4      2       D5         "
.ascii "     A5              D6         "
.ascii "     A6              D7         "
.ascii "     A7              A15        "
.ascii "     A8              A14        "
.ascii "     A9              A13        "
.ascii "    A10              A12        "
.ascii "    A11              VSS        "
.ascii "                                "
.ascii "                                "
.ascii "                                "
.ascii "                                "


;;;;
;  Attribute table:
;  The tiles on the screen are 8x8 pixels, but every 2x2 group of tiles shares
;  4 bits of color information (and 4 bits of something else) with the tiles.
;  When combined you get the final colors for the tiles.  That is why this is 8x8 bytes
.bytes $00,$00,$00,$00,$00,$00,$00,$00
.bytes $00,$00,$FF,$FF,$FF,$00,$00,$00
.bytes $00,$00,$FF,$FF,$FF,$00,$00,$00
.bytes $00,$00,$FF,$FF,$FF,$00,$00,$00
.bytes $00,$00,$FF,$FF,$FF,$00,$00,$00
.bytes $00,$00,$FF,$FF,$FF,$00,$00,$00
.bytes $00,$00,$FF,$FF,$FF,$00,$00,$00
.bytes $00,$00,$00,$00,$00,$00,$00,$00



;;;;
;  This begins the char ROM bank 0, which in mapper 0 spans from $0000 - $1FFF (8KB)
;  The PPU has direct access to the contents of char ROM.  
;  The first 4KB from $0000 - $0FFF is tile data, and the second 4KB is sprite data
;
;  The first $200 bytes are skipped to align the tile values to their ASCII 
;  values, so char 32 in ASCII is space, 33 is !, and so on.
;
;  This tileset is from the commodore64's character ROM.
;  Bytes 0-$0FFF, that is 4096 bytes, is tile data.
.segment char 0
.org $0200

.bytes $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 32
.bytes $18,$18,$18,$18,$00,$00,$18,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 33
.bytes $66,$66,$66,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 34
.bytes $66,$66,$FF,$66,$FF,$66,$66,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 35
.bytes $18,$3E,$60,$3C,$06,$7C,$18,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 36
.bytes $62,$66,$0C,$18,$30,$66,$46,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 37
.bytes $3C,$66,$3C,$38,$67,$66,$3F,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 38
.bytes $06,$0C,$18,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 39
.bytes $0C,$18,$30,$30,$30,$18,$0C,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 40
.bytes $30,$18,$0C,$0C,$0C,$18,$30,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 41
.bytes $00,$66,$3C,$FF,$3C,$66,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 42
.bytes $00,$18,$18,$7E,$18,$18,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 43
.bytes $00,$00,$00,$00,$00,$18,$18,$30,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 44
.bytes $00,$00,$00,$7E,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 45
.bytes $00,$00,$00,$00,$00,$18,$18,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 46
.bytes $00,$03,$06,$0C,$18,$30,$60,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 47
.bytes $3C,$66,$6E,$76,$66,$66,$3C,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 48
.bytes $18,$18,$38,$18,$18,$18,$7E,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 49
.bytes $3C,$66,$06,$0C,$30,$60,$7E,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 50
.bytes $3C,$66,$06,$1C,$06,$66,$3C,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 51
.bytes $06,$0E,$1E,$66,$7F,$06,$06,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 52
.bytes $7E,$60,$7C,$06,$06,$66,$3C,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 53
.bytes $3C,$66,$60,$7C,$66,$66,$3C,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 54
.bytes $7E,$66,$0C,$18,$18,$18,$18,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 55
.bytes $3C,$66,$66,$3C,$66,$66,$3C,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 56
.bytes $3C,$66,$66,$3E,$06,$66,$3C,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 57
.bytes $00,$00,$18,$00,$00,$18,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 58
.bytes $00,$00,$18,$00,$00,$18,$18,$30,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 59
.bytes $0E,$18,$30,$60,$30,$18,$0E,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 60
.bytes $00,$00,$7E,$00,$7E,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 61
.bytes $70,$18,$0C,$06,$0C,$18,$70,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 62
.bytes $3C,$66,$06,$0C,$18,$00,$18,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 63
.bytes $3C,$66,$6E,$6E,$60,$62,$3C,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 64
.bytes $18,$3C,$66,$7E,$66,$66,$66,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 65
.bytes $7C,$66,$66,$7C,$66,$66,$7C,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 66
.bytes $3C,$66,$60,$60,$60,$66,$3C,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 67
.bytes $78,$6C,$66,$66,$66,$6C,$78,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 68
.bytes $7E,$60,$60,$78,$60,$60,$7E,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 69
.bytes $7E,$60,$60,$78,$60,$60,$60,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 70
.bytes $3C,$66,$60,$6E,$66,$66,$3C,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 71
.bytes $66,$66,$66,$7E,$66,$66,$66,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 72
.bytes $3C,$18,$18,$18,$18,$18,$3C,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 73
.bytes $1E,$0C,$0C,$0C,$0C,$6C,$38,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 74
.bytes $66,$6C,$78,$70,$78,$6C,$66,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 75
.bytes $60,$60,$60,$60,$60,$60,$7E,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 76
.bytes $63,$77,$7F,$6B,$63,$63,$63,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 77
.bytes $66,$76,$7E,$7E,$6E,$66,$66,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 78
.bytes $3C,$66,$66,$66,$66,$66,$3C,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 79
.bytes $7C,$66,$66,$7C,$60,$60,$60,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 80
.bytes $3C,$66,$66,$66,$66,$3C,$0E,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 81
.bytes $7C,$66,$66,$7C,$78,$6C,$66,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 82
.bytes $3C,$66,$60,$3C,$06,$66,$3C,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 83
.bytes $7E,$18,$18,$18,$18,$18,$18,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 84
.bytes $66,$66,$66,$66,$66,$66,$3C,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 85
.bytes $66,$66,$66,$66,$66,$3C,$18,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 86
.bytes $63,$63,$63,$6B,$7F,$77,$63,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 87
.bytes $66,$66,$3C,$18,$3C,$66,$66,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 88
.bytes $66,$66,$66,$3C,$18,$18,$18,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 89
.bytes $7E,$06,$0C,$18,$30,$60,$7E,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 90
.bytes $3C,$30,$30,$30,$30,$30,$3C,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 91
.bytes $0C,$12,$30,$7C,$30,$62,$FC,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 92
.bytes $3C,$0C,$0C,$0C,$0C,$0C,$3C,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 93
.bytes $00,$18,$3C,$7E,$18,$18,$18,$18,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 94
.bytes $00,$10,$30,$7F,$7F,$30,$10,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Character 95


;;;;
;  Here we are still in char ROM bank 0, $1000 = 4096, so the next 4KB
;  is sprite tile data.  Char ROM banks in mapper 0 are 8KB split half
;  and half between tile and sprite data.  We only have two sprites, but
;  we have to move ahead to $1000 where sprite data begins.
.org $1000

.bytes $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; Character 0: Blank
.bytes $18,$24,$66,$99,$99,$66,$24,$18,$00,$18,$18,$66,$66,$18,$18,$00 ; Character 1: Diamond sprite

