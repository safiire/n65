;;;;
;  Create an iNES header
.ines {"prog": 1, "char": 0, "mapper": 0, "mirror": 0}

;;;;
;;  Start a prog segment number 0
.segment prog 0
.org $8000

.scope yay
  main:
    sei
    cld
  loop:
    ldx $00
    inx
    stx $00
    jmp loop
.

vblank:
irq:
  rti

;;;;
;;  Vector table
.org $FFFA

.dw vblank
.dw yay.main
.dw irq
