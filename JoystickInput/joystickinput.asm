	processor 6502

; ---------------------------------------------------------------
; Include required files with register mapping and macros
; ---------------------------------------------------------------
	include "../vcs.h"
	include "../macro.h"

; ---------------------------------------------------------------
; Start an uninitialized segment at $80 for var declaration.
; We have memory from $80 to $FF to work with, minus a few at
; the end if we use the stack.
; ---------------------------------------------------------------
	seg.u Variables
	org $80
P0XPos byte			; Sprite X coordinate

; ---------------------------------------------------------------
; Start our ROM code segment starting at $F000.
; ---------------------------------------------------------------
	seg Code
	org $F000

Reset:
	CLEAN_START		; Macro to clean memory and TIA

	ldx #$80		; Blue background color
	stx COLUBK

	ldx #$D0		; Green playfield floor color
	stx COLUPF

; ---------------------------------------------------------------
; Initialize variables
; ---------------------------------------------------------------
	lda #10
	sta P0XPos		; Initialize player X coordinate

; ---------------------------------------------------------------
; Start a new frame by configuring VBLANK and VSYNC
; ---------------------------------------------------------------
StartFrame:
	lda #2
	sta VBLANK		; Turn VBLANK on
	sta VSYNC		; Turn VSYNC on

; ---------------------------------------------------------------
; Display 3 vertical lines of VSYNC
; ---------------------------------------------------------------
	repeat 3
	sta WSYNC		; First three VSYNC scanlines
	repend
	lda #0
	sta VSYNC		; Turn VSYNC off

; ---------------------------------------------------------------
; Set player horizontal position while in VBLANK
; ---------------------------------------------------------------
	lda P0XPos		; Load register A with desired X position
	and #$7F		; AND position with $7F to fix range
	sta WSYNC		; Wait for next scanline
	sta HMCLR		; Clear old horizontal position values

	sec				; Set carry flag before subtraction
DivideLoop:
	sbc #15			; Subtract 15 from the accumulator
	bcs DivideLoop	; loop while carry flag is still set

	eor #7			; Adjust the remainder in A between -8 and 7
	asl				; Shift left by 4, as HMP0 uses only 4 bits
	asl
	asl
	asl
	sta HMP0		; Set fine position
	sta RESP0		; Reset 15-step brute position
	sta WSYNC		; Wait for next scanline
	sta HMOVE		; Apply the fine position offset

; ---------------------------------------------------------------
; Let the TIA output the remaining 35 lines of VBLANK (37 - 2)
; ---------------------------------------------------------------
	repeat 35
		sta WSYNC
	repend
	lda #0
	sta VBLANK		; Turn VBLANK off

; ---------------------------------------------------------------
; Draw the 192 visible scanlines
; ---------------------------------------------------------------
	repeat 160
		sta WSYNC	; Wait for 160 empty scanlines
	repend

	ldy #17			; Counter to draw 17 rows of player0 bitmap
DrawBitmap:
	lda P0Bitmap,y	; Load player bitmap slice of data
	sta GRP0		; Set graphics for player 0 slice

	lda P0Color,y	; Load player color from lookup table
	sta COLUP0		; Set color for player 0 slice

	sta WSYNC		; Wait for next scanline

	dey
	bne DrawBitmap	; Repeat next scanline until finished

	lda #0
	sta GRP0		; Disable P0 bitmap graphics

	lda #$FF		; Enable grass playfield
	sta PF0
	sta PF1
	sta PF2

	repeat 15
	sta WSYNC		; Wait for remaining 15 empty scanlines
	repend

	lda #0			; Disable grass playfield
	sta PF0
	sta PF1
	sta PF2

; ---------------------------------------------------------------
; Output 30 more VBLANK overscan lines to complete our frame
; ---------------------------------------------------------------
Overscan:
	lda #2
	sta VBLANK		; Turn VBLANK on again for overscan
	repeat 30
	sta WSYNC
	repend

; ---------------------------------------------------------------
; Joystick input test for P0 up/down/left/right
; ---------------------------------------------------------------
CheckP0Up:
	lda #%00010000
	bit SWCHA
	bne CheckP0Down
	inc P0XPos

CheckP0Down:
	lda #%00100000
	bit SWCHA
	bne CheckP0Left
	dec P0XPos

CheckP0Left:
	lda #%01000000
	bit SWCHA
	bne CheckP0Right
	dec P0XPos

CheckP0Right:
	lda #%10000000
	bit SWCHA
	bne NoInput
	inc P0XPos

NoInput:
	; Fallback when no input was performed

; ---------------------------------------------------------------
; Loop to next frame
; ---------------------------------------------------------------
	jmp StartFrame

; ---------------------------------------------------------------
; Lookup table for the player graphics bitmap
; ---------------------------------------------------------------
P0Bitmap:
	byte #%00000000
	byte #%00010100
	byte #%00010100
	byte #%00010100
	byte #%00010100
	byte #%00010100
	byte #%00011100
	byte #%01011101
	byte #%01011101
	byte #%01011101
	byte #%01011101
	byte #%01111111
	byte #%00111110
	byte #%00010000
	byte #%00011100
	byte #%00011100
	byte #%00011100

; ---------------------------------------------------------------
; Lookup table for the player colors
; ---------------------------------------------------------------
P0Color:
	byte #$00
	byte #$F6
	byte #$F2
	byte #$F2
	byte #$F2
	byte #$F2
	byte #$F2
	byte #$C2
	byte #$C2
	byte #$C2
	byte #$C2
	byte #$C2
	byte #$C2
	byte #$3E
	byte #$3E
	byte #$3E
	byte #$24

; ---------------------------------------------------------------
; Complete ROM size
; ---------------------------------------------------------------
	org $FFFC
	word Reset
	word Reset
