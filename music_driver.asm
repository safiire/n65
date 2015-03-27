;------------------------------------------------------------------------------
;  An NES music engine that understands the binary stream outputted from my
;  MIDI converter :)
;;;;
;  Create an iNES header
.ines {"prog": 1, "char": 0, "mapper": 0, "mirror": 0}


;;;;
;  Include all the symbols in the nes library
.inc <nes.sym>


;;;;
;  Let's put a data structure to control the sound engine in the zero page
.org $0000
.scope sound_engine
  ;  Where we are reading from ROM
  .space stream_read_ptr_lo 1
  .space stream_read_ptr_hi 1

  ;  Where we are writing in the APU
  .space stream_write_ptr_lo 1
  .space stream_write_ptr_hi 1
  .space delta 1
.


;;;;
;  Open the prog section bank 0
.segment prog 0


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

  ;  Initialize sound engine structure
  ;  To read from $D000, and to write to $40**
  lda #>music_buffer
  sta sound_engine.stream_read_ptr_hi
  lda #<music_buffer
  sta sound_engine.stream_read_ptr_lo

  ; Make the first delta happen immediately
  lda #$01
  sta sound_engine.delta

  lda #$40
  sta sound_engine.stream_write_ptr_hi

  jsr init_sound

  ;  Resume interrupts and NMI and loop here forever
  lda #%10000000
  sta nes.ppu.control
  cli
  forever:
    jmp forever
.


;;;;
;  Initialize the APU to enable Pulse1
;  Bitfield: ---D NT21
.scope init_sound
  lda #$00
  sta nes.apu.pulse1.control
  sta nes.apu.pulse1.ramp_control
  sta nes.apu.pulse1.ft
  sta nes.apu.pulse1.ct
  lda #$01
  sta nes.apu.channel_enable
  rts
.


;;;;
;  VBlank reads our music buffer
.scope vblank
  ;  Backup our registers
  pha
  txa
  pha
  tya
  pha

  jsr sound_engine_driver

  ;  Restore the registers
  pla
  tay
  pla
  tax
  pla
  rti
.

;;;;
;  Sound driver that updates the APU registers
;  via a stream of APU write commands
.scope sound_engine_driver
  dec sound_engine.delta
  bne done

  read_event:
    ;  Load the new delta from the stream
    ldy #$00
    lda (sound_engine.stream_read_ptr_lo), Y
    sta sound_engine.delta

    ;  Read pulse1 control register value
    ldy #$01
    lda (sound_engine.stream_read_ptr_lo), Y
    sta nes.apu.pulse1.control

    ;  Read the value for pulse1.ft
    ldy #$02
    lda (sound_engine.stream_read_ptr_lo), Y
    sta nes.apu.pulse1.ft


    ;  Read the value for pulse1.ct
    ldy #$03
    lda (sound_engine.stream_read_ptr_lo), Y
    sta nes.apu.pulse1.ct

    ;  Advance the 16-bit stream pointer by number of bytes read
    lda sound_engine.stream_read_ptr_lo
    clc
    adc #$04
    sta sound_engine.stream_read_ptr_lo
    bcc done
    inc sound_engine.stream_read_ptr_hi

    ;  If the very next event is 0 delta away, do it now too
    ;  Read the value for pulse1.ct
    ldy #$04
    lda (sound_engine.stream_read_ptr_lo), Y
    beq read_event

  done:
  rts
.


;;;;
;  IRQ Does nothing
.scope irq
  rti
.

;;;;
;  Include the music buffer stream
.org $D000
music_buffer:
.incbin "data.mus"
