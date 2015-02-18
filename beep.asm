reset:
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
