	processor 6502

; --------------------------------------------------------------------
; Include required files with VCS register memory mapping and macros
; --------------------------------------------------------------------
	include "../vcs.h"
	include "../macro.h"

; --------------------------------------------------------------------
; Declare the variable starting from memory address $80
; --------------------------------------------------------------------
	seg.u Variables
	org $80

JetXPos		byte		; Player0 x-position
JetYPos		byte		; Player0 y-position
BomberXPos	byte		; Bomber x-position
BomberYPos	byte		; Bomber y-position

; --------------------------------------------------------------------
; Start our ROM code at memory address $F000
; --------------------------------------------------------------------
	seg Code
	org $F000

Reset:
	CLEAN_START		; Call macro to reset memory and registers


; --------------------------------------------------------------------
; Initialize RAM variables and TIA registers
; --------------------------------------------------------------------
	lda #10
	sta JetYPos		; JetYPos = 10
	lda #60
	sta JetXPos		; JetXPos = 60

; --------------------------------------------------------------------
; Start the main display loop and frame rendering
; --------------------------------------------------------------------
StartFrame:


; --------------------------------------------------------------------
; Display VSYNC and VBLANK
; --------------------------------------------------------------------
	lda #2
	sta VBLANK		; Turn VBLANK on
	sta VSYNC		; Turn VSYNC on
	repeat 3
	sta WSYNC		; Display 3 recommended lines of VSYNC
	repend
	lda #0
	sta VSYNC		; Turn VSYNC off
	repeat 37
	sta WSYNC		; Display the 37 recommended lines of VBLANK
	repend
	sta VBLANK

; --------------------------------------------------------------------
; Dispaly the 192 visible scanlines of our main game
; --------------------------------------------------------------------
GameVisibleLine:
	lda #$84			; Set background color to blue
	sta COLUBK
	lda #$C2			; Set playfield color to green
	sta COLUPF

	lda #%00000001
	sta CTRLPF		; Set playfield reflection
	lda #$F0
	sta PF0			; Setting PF0 (playfield) bit pattern
	lda #$FC
	sta PF1			; Setting PF1 (playfield) bit pattern
	lda #0
	sta PF2			; Setting PF2 (playfield) bit pattern

	ldx #192			; X counts the number of remaining scanline
.GameLineLoop
	sta WSYNC
	dex			; X--
	bne .GameLineLoop		; Repeat next main game scanline until finished

; --------------------------------------------------------------------
; Display overscan
; --------------------------------------------------------------------
	lda #2
	sta VBLANK		; Turn VBLANK on again
	repeat 30
	sta WSYNC
	repend
	lda #0
	sta VBLANK 		; Turn VBLANK off

; --------------------------------------------------------------------
; Loop back to start a brand new frame
; --------------------------------------------------------------------
	jmp StartFrame		; Continue to display the next frame

; --------------------------------------------------------------------
; Complete ROM size with exactly 4KB
; --------------------------------------------------------------------
	org $FFFC		; Move to position $FFFC
	.word Reset		; Write 2 bytes with the program reset address
	.word Reset		; Write 2 bytes with the interruption vector