	processor 6502

	seg code		; Code starts here

	org $F000	; Define the code origin at $F000

Start:
	sei		; Disable intrerupts
	cld 		; Disable the BCD decimal math mode
	ldx #$FF		; Loads the X register with #$FF
	txs		; Transfer X register to SP (stack pointer register)

; ---------------------------------------------------------------
; Clear the Zero Page region ($00 to $FF)
; Meaning the entire TIA register space and also RAM
; ---------------------------------------------------------------
	lda #0		; A = 0
	ldx #$FF		; X = #$FF
	sta $FF		; Make sure $FF is zeroed before the loop start
ClearLoop:
	dex		; Decrement X
	sta $0,X 	; Store zero (value hold by acumulator - register A) at address $0 + X
	bne ClearLoop	; Loop until X is equal to 0 (z-flag set)

; ---------------------------------------------------------------
; Fill ROM size to exactly 4KB
; ---------------------------------------------------------------
	org $FFFC	; Go to the position 4KB - 4B
	.word Start	; Add 2B, reset vector at $FFC (where program starts)
	.word Start	; Add 2B, interrupt vector at $FFFE (unused in VCS)