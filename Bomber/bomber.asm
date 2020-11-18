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
JetSpritePtr	word		; Pointer to player0 sprite lookup table
JetColorPtr	word		; Pointer to player0 color lookup table
BomberSpritePtr	word		; Pointer to player1 sprite lookup table
BomberColorPtr	word		; Pointer to player1 color lookup table

; --------------------------------------------------------------------
; Define constants
; --------------------------------------------------------------------
JET_HEIGHT = 9			; player0 sprite height (# rows in lookup table)
BOMBER_HEIGHT = 9			; player1 sprite height (# rows in lookup table)

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
	lda #83
	sta BomberYPos		; BomberYPos = 83
	lda #54
	sta BomberXPos		; BomberXPos = 54

; --------------------------------------------------------------------
; Initialize pointers to the correct lookup table addresses
; --------------------------------------------------------------------
	lda #<JetSprite
	sta JetSpritePtr		; lo-byte pointer for jet sprite lookup table
	lda #>JetSprite
	sta JetSpritePtr+1	; hi-byte pointer for jet sprite lookup table
	lda #<JetColor
	sta JetColorPtr		; lo-byte pointer for jet color table
	lda #>JetColor
	sta JetColorPtr+1		; hi-byte pointer for jet color table

	lda #<BomberSprite
	sta BomberSpritePtr	; lo-byte pointer for bomber sprite lookup table
	lda #>BomberSprite
	sta BomberSpritePtr+1	; hi-byte pointer for bomber sprite lookup table
	lda #<BomberColor
	sta BomberColorPtr	; lo-byte pointer for bomber color table
	lda #>BomberColor
	sta BomberColorPtr+1	; hi-byte pointer for bomber color table

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
; Declare ROM lookup tables
; --------------------------------------------------------------------
JetSprite:
    .byte #%00000000         ;
    .byte #%00010100         ;   # #
    .byte #%01111111         ; #######
    .byte #%00111110         ;  #####
    .byte #%00011100         ;   ###
    .byte #%00011100         ;   ###
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #

JetSpriteTurn:
    .byte #%00000000         ;
    .byte #%00001000         ;    #
    .byte #%00111110         ;  #####
    .byte #%00011100         ;   ###
    .byte #%00011100         ;   ###
    .byte #%00011100         ;   ###
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #

BomberSprite:
    .byte #%00000000         ;
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #
    .byte #%00101010         ;  # # #
    .byte #%00111110         ;  #####
    .byte #%01111111         ; #######
    .byte #%00101010         ;  # # #
    .byte #%00001000         ;    #
    .byte #%00011100         ;   ###

JetColor:
    .byte #$00
    .byte #$FE
    .byte #$0C
    .byte #$0E
    .byte #$0E
    .byte #$04
    .byte #$BA
    .byte #$0E
    .byte #$08

JetColorTurn:
    .byte #$00
    .byte #$FE
    .byte #$0C
    .byte #$0E
    .byte #$0E
    .byte #$04
    .byte #$0E
    .byte #$0E
    .byte #$08

BomberColor:
    .byte #$00
    .byte #$32
    .byte #$32
    .byte #$0E
    .byte #$40
    .byte #$40
    .byte #$40
    .byte #$40
    .byte #$40

; --------------------------------------------------------------------
; Complete ROM size with exactly 4KB
; --------------------------------------------------------------------
	org $FFFC		; Move to position $FFFC
	.word Reset		; Write 2 bytes with the program reset address
	.word Reset		; Write 2 bytes with the interruption vector