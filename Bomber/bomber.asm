	processor 6502

; --------------------------------------------------------------------
; Include required files with VCS register memory mapping and macros
; --------------------------------------------------------------------
	include "../vcs.h"
	include "../macro.h"

; --------------------------------------------------------------------
; Declare variables starting from memory address $80
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
JetAnimOffset	byte		; Player0 sprite frame offset for animation

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
	lda #68
	sta JetXPos		; JetXPos = 68
	lda #10
	sta JetYPos		; JetYPos = 10
	lda #62
	sta BomberXPos		; BomberXPos = 62
	lda #83
	sta BomberYPos		; BomberYPos = 83

; --------------------------------------------------------------------
; Initialize pointers to the correct lookup table addresses
; --------------------------------------------------------------------
	lda #<JetSprite
	sta JetSpritePtr		; lo-byte pointer for jet sprite lookup table
	lda #>JetSprite
	sta JetSpritePtr+1	; hi-byte pointer for jet sprite lookup table

	lda #<JetColor
	sta JetColorPtr		; lo-byte pointer for jet color lookup table
	lda #>JetColor
	sta JetColorPtr+1		; hi-byte pointer for jet color lookup table

	lda #<BomberSprite
	sta BomberSpritePtr	; lo-byte pointer for bomber sprite lookup table
	lda #>BomberSprite
	sta BomberSpritePtr+1	; hi-byte pointer for bomber sprite lookup table

	lda #<BomberColor
	sta BomberColorPtr	; lo-byte pointer for bomber color lookup table
	lda #>BomberColor
	sta BomberColorPtr+1	; hi-byte pointer for bomber color lookup table

; --------------------------------------------------------------------
; Start the main display loop and frame rendering
; --------------------------------------------------------------------
StartFrame:

; --------------------------------------------------------------------
; Calculations and tasks performed in the pre-VBLANK
; --------------------------------------------------------------------
	lda JetXPos
	ldy #0
	jsr SetObjectXPos		; Set Player0 horizontal position

	lda BomberXPos
	ldy #1
	jsr SetObjectXPos		; Set Player1 horizontal position

	sta WSYNC
	sta HMOVE		; Apply the horizontal offsets that was set previously

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
; Dispaly the 96 visible scanlines of our main game (2-line kernel)
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

	ldx #96			; X counts the number of remaining scanline
.GameLineLoop
.AreWeInsideJetSprite:
	txa			; Transfer X to A
	sec			; Make sure carry flag is set before substraction
	sbc JetYPos		; Substract sprite Y-coordinate
	cmp JET_HEIGHT		; Compare with height
	bcc .DrawSpriteP0		; If result < SpriteHeight. call the draw routine
	lda #0			; else, set lookup index to zero
.DrawSpriteP0
	clc			; Clear carry flag before addition
	adc JetAnimOffset		; Jump to the correct sprite fram address in memory
	tay			; Transfer A to Y
	lda (JetSpritePtr),Y	; Load Player0 bitmap data from lookup table
	sta WSYNC		; Wait for scanline
	sta GRP0			; Set graphics for Player0
	lda (JetColorPtr),Y	; Load Player0 color from lookup table
	sta COLUP0		; Set color of Player0

.AreWeInsideBomberSprite:
	txa			; Transfer X to A
	sec			; Make sure carry flag is set before substraction
	sbc BomberYPos		; Substract sprite Y-coordinate
	cmp BOMBER_HEIGHT		; Compare with height
	bcc .DrawSpriteP1		; If result < SpriteHeight. call the draw routine
	lda #0			; else, set lookup index to zero
.DrawSpriteP1
	tay			; Transfer A to Y
	lda #%00000101
	sta NUSIZ1		; Stretch Player1 sprite
	lda (BomberSpritePtr),Y	; Load Player1 bitmap data from lookup table
	sta WSYNC		; Wait for scanline
	sta GRP1			; Set graphics for Player1
	lda (BomberColorPtr),Y	; Load Player1 color from lookup table
	sta COLUP1		; Set color of Player1

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
; Process joystick input for Player0
; --------------------------------------------------------------------
CheckP0Up:
	lda #%00010000		; Player0 joystick up
	bit SWCHA
	bne CheckP0Down		; If bit pattern does not match, by pass this block
	inc JetYPos

CheckP0Down:
	lda #%00100000		; Player0 joystick down
	bit SWCHA
	bne CheckP0Left		; If bit pattern does not match, by pass this block
	dec JetYPos

CheckP0Left:
	lda #%01000000		; Player0 joystick left
	bit SWCHA
	bne CheckP0Right		; If bit pattern does not match, by pass this block
	dec JetXPos

CheckP0Right:
	lda #%10000000		; Player0 joystick right
	bit SWCHA
	bne EndInputCheck		; If bit pattern does not match, by pass this block
	inc JetXPos

EndInputCheck:			; Fallback when no input was performed

; --------------------------------------------------------------------
; Loop back to start a brand new frame
; --------------------------------------------------------------------
	jmp StartFrame		; Continue to display the next frame

; --------------------------------------------------------------------
; Subroutine to handle object horizontal position with fine offset
; --------------------------------------------------------------------
; A is the target x-coordinate position in pixels of our object
; Y is the object type (0:player0, 1:player1, 2:missile0, 3:missile1, 4:ball)
; --------------------------------------------------------------------
SetObjectXPos subroutine
	sta WSYNC		; Start a fresh new scanline
	sec			; Make sure carry-flag is set before subtracion
.Div15Loop
	sbc #15			; Subtract 15 from accumulator
	bcs .Div15Loop		; Loop until carry-flag is clear
	eor #7			; Handle offset range from -8 to 7
	asl
	asl
	asl
	asl			; Four shift lefts to get only the top 4 bits
	sta HMP0,Y		; Store the fine offset to the correct HMxx
	sta RESP0,Y		; Fix object position in 15-step increment
	rts

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