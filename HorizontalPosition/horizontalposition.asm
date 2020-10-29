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
P0XPos	byte		; Sprite X coordinate

; ---------------------------------------------------------------
; Start our ROM code segment starting at $F000.
; ---------------------------------------------------------------
	seg Code
	org $F000

Reset:
	CLEAN_START	; Macro to clean memory and TIA

	ldx #$00		; Black background color
	stx COLUBK

; ---------------------------------------------------------------
; Initialize variables
; ---------------------------------------------------------------
	lda #50
	sta P0XPos	; initialize player X coordinate

; ---------------------------------------------------------------
; Start a new frame by configuring VBLANK and VSYNC
; ---------------------------------------------------------------
StartFrame:
	lda #2
	sta VBLANK	; Turn VBLANK on
	sta VSYNC	; Turn VSYNC on

; ---------------------------------------------------------------
; Display 3 vertical lines of VSYNC
; ---------------------------------------------------------------
	repeat 3
	sta WSYNC	; first three VSYNC scanlines
	repend
	lda #0
	sta VSYNC	; turn VSYNC off

; ---------------------------------------------------------------
; Set player horizontal position while in VBLANK
; ---------------------------------------------------------------
	lda P0XPos	; Load register A with desired X position
	and #$7F		; Same as AND 01111111, forces bit 7 to zero
			; Keeping the result positive

	sta WSYNC	; Wait for next scanline
	sta HMCLR	; Clear old horizontal position values

	sec		; Set carry flag before subtraction
DivideLoop:
	sbc #15		; A -= 15
	bcs DivideLoop	; Loop while carry flag is still set

	eor #7		; Adjust the remainder in A between -8 and 7
	asl		; Shift left by 4, as HMP0 uses only 4 bits
	asl
	asl
	asl
	sta HMP0		; Set fine position
	sta RESP0	; Reset 15-step brute position
	sta WSYNC	; Wait for next scanline
	sta HMOVE	; Apply the fine position offset

; ---------------------------------------------------------------
; Let the TIA output the 37 recommended lines of VBLANK
; ---------------------------------------------------------------
	repeat 37
	sta WSYNC
	repend

	lda #0
	sta VBLANK	 ; Turn VBLANK off

; ---------------------------------------------------------------
; Draw the 192 visible scanlines
; ---------------------------------------------------------------
	repeat 60
	sta WSYNC	; Wait for 60 empty scanlines
	repend

	ldy 8		; Counter to draw 8 rows of bitmap
DrawBitmap:
	lda P0Bitmap,y	; Load player bitmap slice of data
	sta GRP0		; Set graphics for player 0 slice

	lda P0Color,y	; Load player color from lookup table
	sta COLUP0	; Set color for player 0 slice

	sta WSYNC	; Wait for next scanline

	dey
	bne DrawBitmap	; Repeat next scanline until finished

	lda #0
	sta GRP0		; Disable P0 bitmap graphics

	repeat 124
	sta WSYNC	; Wait for remaining 124 empty scanlines
	repend

; ---------------------------------------------------------------
; Output 30 more VBLANK overscan lines to complete our frame
; ---------------------------------------------------------------
Overscan:
	lda #2
	sta VBLANK	; Turn VBLANK on again for overscan
	repeat 30
	sta WSYNC
	repend

; ---------------------------------------------------------------
; Increment X coordinate before next frame for animation.
; ---------------------------------------------------------------
	inc P0XPos

; ---------------------------------------------------------------
; Loop to next frame
; ---------------------------------------------------------------
	jmp StartFrame

; ---------------------------------------------------------------
; Lookup table for the player graphics bitmap.
; ---------------------------------------------------------------
P0Bitmap:
	byte #%00000000
	byte #%00010000
	byte #%00001000
	byte #%00011100
	byte #%00110110
	byte #%00101110
	byte #%00101110
	byte #%00111110
	byte #%00011100

; ---------------------------------------------------------------
; Lookup table for the player colors.
; ---------------------------------------------------------------
P0Color:
	byte #$00
	byte #$02
	byte #$02
	byte #$52
	byte #$52
	byte #$52
	byte #$52
	byte #$52
	byte #$52

; ---------------------------------------------------------------
; Complete ROM size
; ---------------------------------------------------------------
	org $FFFC
	word Reset
	word Reset
