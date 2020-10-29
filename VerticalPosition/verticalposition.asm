	processor 6502

; ---------------------------------------------------------------
; Include required files with definitions and macros
; ---------------------------------------------------------------
	include "../vcs.h"
	include "../macro.h"

; ---------------------------------------------------------------
; Start an uninitialized segment at $80 for var declaration
; We have memory from $80 to $FF to work with (128B), minus a
; few at the end if we use the stack
; ---------------------------------------------------------------
	seg.u Variables
	org $80
P0Height		byte	; Player sprite height
PlayerYPos	byte	; Player sprite Y coordinate

; ---------------------------------------------------------------
; Start our ROM code segment starting at $F000
; ---------------------------------------------------------------
	seg Code
	org $F000

Reset:
	CLEAN_START	; Macro to clean memory and TIA

	ldx #$00		; Black background color
	stx COLUBK	; Store value of register X intro the register COLUBX

; ---------------------------------------------------------------
; Initialize variables
; ---------------------------------------------------------------
	lda #180
	sta PlayerYPos	; PlayerYPos = 180

	lda #9
	sta P0Height	; P0Height = 9

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
	sta WSYNC
	repend

	lda #0
	sta VSYNC	; Turn VSYNC off

; ---------------------------------------------------------------
; Let the TIA output the 37 recommended lines of VBLANK
; ---------------------------------------------------------------
	repeat 37
	sta WSYNC
	repend

	lda #0
	sta VBLANK	; Turn VBLANK off

; ---------------------------------------------------------------
; Draw the 192 visible scanlines
; ---------------------------------------------------------------
	ldx #192

Scanline:
	txa		; Transfer value hold by register X to register A
	sec		; Set carry flag
	sbc PlayerYPos	; Substract sprite Y coordinate (minus value hold by register A)
	cmp P0Height	; Are we inside the sprite height bounds?
	bcc LoadBitmap	; If result < SpriteHeight then jump
	lda #0		; Else set index to 0

LoadBitmap:
	tay		; Transfer value hold by register A to register Y
	lda P0Bitmap,y	; Load player bitmap slice of data (P0Bitmap + Y)
	sta WSYNC	; Wait for the next scanline
	sta GRP0		; Set graphics for player 0 slice
	lda P0Color,y	; Load player color from table
	sta COLUP0	; Set color for player 0 slice

	dex
	bne Scanline	; Repeat next scanline until finished

; ---------------------------------------------------------------
; Output 30 more VBLANK overscan lines to complete our frame
; ---------------------------------------------------------------
Overscan:
	lda #2
	sta VBLANK
	repeat 30
	sta WSYNC
	repend

; ---------------------------------------------------------------
; Decrement Y-coordinate in each frame for animation effect
; ---------------------------------------------------------------
	dec PlayerYPos

; ---------------------------------------------------------------
; Loop to the next frame
; ---------------------------------------------------------------
	jmp StartFrame

; ---------------------------------------------------------------
; Lookup table for the player graphics bitmap
; ---------------------------------------------------------------
P0Bitmap:
	byte #%00000000
	byte #%00101000
	byte #%01110100
	byte #%11111010
	byte #%11111010
	byte #%11111010
	byte #%11111110
	byte #%01101100
	byte #%00110000

; ---------------------------------------------------------------
; Lookup table for the player colors
; ---------------------------------------------------------------
P0Color:
	byte #$00
	byte #$40
	byte #$40
	byte #$40
	byte #$40
	byte #$42
	byte #$42
	byte #$44
	byte #$D2

; ---------------------------------------------------------------
; Complete ROM size adding reset addresses at $FFFC
; ---------------------------------------------------------------
	org $FFFC
	word Reset
	word Reset