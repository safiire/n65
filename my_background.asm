  ;  Create an iNES header
  .ines {"prog": 1, "char": 1, "mapper": 0, "mirror": 1}


  ;  Main code segment
  .org $C000 
start:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, X
  STA $0100, X
  STA $0200, X
  STA $0400, X
  STA $0500, X
  STA $0600, X
  STA $0700, X
  LDA #$FE
  STA $0300, X
  INX
  BNE clrmem

vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2


  LDA #$60        ;intensify blues
  STA $2001

forever:
  JMP forever     ;jump back to Forever, infinite loop

nmi:
  RTI


  .org $FFFA     ;first of the three vectors starts here
  .dw nmi        ;when an NMI happens (once per frame if enabled) the processor will jump to the label NMI:
  .dw start      ;when the processor first turns on or is reset, it will jump to the label RESET:
  .dw $0         ;external interrupt IRQ is not used in this tutorial
