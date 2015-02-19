;------------------------------------------------------------------------------
;  This is a direct port of Michael Martin's tutorial project for NES101
;
;  I believe that tutorial can be found here:
;  http://hackipedia.org/Platform/Nintendo/NES/tutorial,%20NES%20programming%20101/NES101.html
;
;  I just rewrote it to have something interesting to test my assembler on.
;  Saf 2015
;
  ;  Create an iNES header
  .ines {"prog": 1, "char": 1, "mapper": 0, "mirror": 0}

  ;  SRAM
  ;  I have no way to do this right now, but I need to add
  ;  the ability to simply name parts of memory with a sort
  ;  of alias, specifically in the zero page where memory 
  ;  access is quick.
  ;  For now, let's just remember that in the zero page:
  ;    *dx     = $00    ;  The speed delta x of the sprite
  ;    *a      = $01    ;  Whether the A button is down
  ;    *scroll = $02    ;  The scroll amount
  ;
  ;    *sprite = $200   ;  Some sprite memory
  ;  Actually I can probably do this with a .org and label pair

.org $0200
sprite:

  ;  Main Code Segment
.org $C000

reset:  
  SEI
	CLD

	; Wait two VBLANKs.
wait_vb1:
 	LDA $2002
	BPL wait_vb1

wait_vb2:
	LDA $2002
	BPL wait_vb2


	; Clear out RAM.
  LDA #$00
  LDX #$00
clear_segments:
  STA $00, X
  STA $0100, X
  STA $0200, X
  STA $0300, X
  STA $0400, X
  STA $0500, X
  STA $0600, X
  STA $0700, X
  INX
  BNE clear_segments


	; Reset the stack pointer.
  LDX #$FF
  TXS

	; Disable all graphics.
  LDA #$00
  STA $2000
  STA $2001

	JSR init_graphics
	JSR init_input
	JSR init_sound

	; Set basic PPU registers.  Load background from $0000,
	; sprites from $1000, and the name table from $2000.
  LDA #$88
  STA $2000
  LDA #$1E
  STA $2001
	CLI


	; Transfer control to the VBLANK routines.
forever:   
  JMP forever

init_graphics:
  JSR init_sprites
  JSR load_palette
  JSR load_name_tables
  JSR init_scrolling
  RTS

init_input:
  ; The A button starts out not-pressed.
  LDA #$00
  STA $01    ; $01 = A button
  RTS

init_sound:
  ; initialize sound hardware
  LDA #$01
  STA $4015
  LDA #$00
  STA $4001
	LDA #$40
	STA $4017
  RTS


init_sprites:

  ; Clear page #2, which we'll use to hold sprite data
  LDA #$00
  LDX #$00
sprite_clear1:
  STA $0200, X             ; $0200 = sprite
  INX
  BNE sprite_clear1

  ; initialize Sprite 0
  LDA #$70
  STA $0200                ; sprite Y coordinate
  LDA #$01
  STA $0201                ; sprite + 1Pattern number
  STA $0203                ; sprite+3 X coordinate
                           ; sprite+2, color, stays 0.

  ; Set initial value of dx
  LDA #$01
  STA $00                 ;  dx = $00
  RTS

; Load palette into $3F00
load_palette:
  LDA #$3F
  LDX #$00
  STA $2006
  STX $2006
loady_loop:
  LDA palette, X
  STA $2007
  INX
  CPX #$20
  BNE loady_loop
  RTS

; Jam some text into the first name table (at $2400, thanks to mirroring)
load_name_tables:
  LDY #$00
  LDX #$04
  LDA #<bg
  STA $10
  LDA #>bg
  STA $11
  LDA #$24
  STA $2006
  LDA #$00
  STA $2006
go_back:
  LDA ($10), Y
  STA $2007
  INY
  BNE go_back
  INC $11
  DEX
  BNE go_back
  RTS

; Clear out the Name Table at $2800 (where we already are.  Yay.)
  LDY #$00
  LDX #$04
  LDA #$00
back:
  STA $2007
  INY
  BNE back
  DEX
  BNE back
  RTS

init_scrolling:
  LDA #$F0
  STA $02    ; scroll
  RTS

update_sprite:
  LDA #>sprite
  STA $4014                ; Jam page $200-$2FF into SPR-RAM

  LDA $05                  ;  sprite+3  Is this right???
  BEQ hit_left
  CMP #$F7
  BNE edge_done
  ; Hit right
  LDX #$FF
  STX $00                   ;  dx
  JSR high_c
  JMP edge_done


hit_left:
  LDX #$01
  STX $00                    ;  dx
  JSR high_c

edge_done:                ; update X and store it.
  CLC
  ADC $00                    ;  dx
  STA $05                 ;  sprite+3 Is this right?
  RTS

react_to_input:
  LDA #$01                ; strobe joypad
  STA $4016
  LDA #$00
  STA $4016

  LDA $4016               ; Is the A button down?
  AND #$01
  BEQ not_a                
  LDX $01                 ;  a
  BNE a_done              ; Only react if the A button wasn't down last time.
  STA $01                 ; Store the 1 in local variable 'a' so that we this is
  JSR reverse_dx          ; only called once per press.
  JMP a_done
not_a:  
  STA $01                 ; A has been released, so put that zero into 'a'.
a_done: 
  LDA $4016                ; B does nothing
  LDA $4016                ; Select does nothing
  LDA $4016                ; Start does nothing
  LDA $4016                ; Up
  AND #$01
  BEQ not_up
  LDX sprite                ; Load Y value
  CPX #$07
  BEQ not_up                ; No going past the top of the screen
  DEX                
  STX sprite

not_up: lda $4016                ; Down
  AND #$01
  BEQ not_dn
  LDX sprite
  CPX #$DF                  ; No going past the bottom of the screen.
  BEQ not_dn
  INX
  STX sprite
not_dn: 
  RTS                                ; Ignore left and right, we don't use 'em

reverse_dx:
  LDA #$FF                
  EOR $00          ; dx
  CLC
  ADC #$01
  STA $00          ; dx
  JSR low_c
  RTS

scroll_screen:
  LDX #$00                ; Reset VRAM
  STX $2006
  STX $2006

  LDX $02                 ; scroll                ; Do we need to scroll at all?
  BEQ no_scroll
  DEX
  STX $02                 ; scroll
  LDA #$00
  STA $2005                ; Write 0 for Horiz. Scroll value
  STX $2005                ; Write the value of 'scroll' for Vert. Scroll value
                
no_scroll:
  RTS

low_c:
  PHA
  LDA #$84
  STA $4000
  LDA #$AA
  STA $4002
  LDA #$09
  STA $4003
  PLA
  RTS

high_c:
  PHA
  LDA #$86
  STA $4000
  LDA #$69
  STA $4002
  LDA #$08
  STA $4003
  PLA
  RTS


vblank: 
  JSR scroll_screen
  JSR update_sprite
  JSR react_to_input

irq:    
  RTI

; palette data
palette:
.bytes $0E,$00,$0E,$19,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$01,$21
.bytes $0E,$20,$22,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00


; Background data
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

; Attribute table
.bytes $00,$00,$00,$00,$00,$00,$00,$00,
.bytes $00,$00,$FF,$FF,$FF,$00,$00,$00,
.bytes $00,$00,$FF,$FF,$FF,$00,$00,$00,
.bytes $00,$00,$FF,$FF,$FF,$00,$00,$00,
.bytes $00,$00,$FF,$FF,$FF,$00,$00,$00,
.bytes $00,$00,$FF,$FF,$FF,$00,$00,$00,
.bytes $00,$00,$FF,$FF,$FF,$00,$00,$00,
.bytes $00,$00,$00,$00,$00,$00,$00,$00,


;  Setup the interrupt vectors
.org $FFFA     ;first of the three vectors starts here
.dw vblank     ;when an NMI happens (once per frame if enabled) the processor will jump to the label NMI:
.dw reset      ;when the processor first turns on or is reset, it will jump to the label RESET:
.dw irq        ;external interrupt IRQ is not used in this tutorial



;  This is CHR-ROM page 1, which starts at 0x0000, but I'm skipping the first bit
;  So this is where tile memory is going to go, this is the commodore 64's character ROM
;  mapped to ASCII for tile numbers.  We are only using 4KB of this 8KB page.
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


;  This is CHR-ROM page 2, which starts at 0x2000, and we put the sprite data here.
.org $1000

.bytes $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; Character 0: Blank
.bytes $18,$24,$66,$99,$99,$66,$24,$18,$00,$18,$18,$66,$66,$18,$18,$00 ; Character 1: Diamond sprite

