	processor 6502

; ---------------------------------------------------------------
; Include required files with definitions and macros
; ---------------------------------------------------------------
	include "../vcs.h"
	include "../macro.h"

; ---------------------------------------------------------------
; Start an uninitialized segment at $80 for variable declaration
; ---------------------------------------------------------------
	seg.u Variables
	org $80
P0Height .byte		; Defines one byte for player 0 height
P1Height .byte		; Defines one byte for player 1 height

; ---------------------------------------------------------------
; Start our ROM code
; ---------------------------------------------------------------
	seg code
	org $F000

Start:
	CLEAN_START	; Macro to safely clear memory and TIA
	ldx #$80		; Blue background color
	stx COLUBK

	lda #%1111	; Yellow playfield color
	sta COLUPF

; ---------------------------------------------------------------
; Initialize P0Height and P1Height with the value 10.
; ---------------------------------------------------------------
	lda #10		; A = 10
	sta P0Height	; P0Height = A
	sta P1Height	; P1Height = A

; ---------------------------------------------------------------
; Set the TIA registers for the colors of P0 and P1
; ---------------------------------------------------------------
	lda #$48		; Player 0 color light red
	sta COLUP0

	lda #$C6		; Player 1 color light green
	sta COLUP1

	ldy #%00000010
	sty CTRLPF

; ---------------------------------------------------------------
; Start a new frame by configuring on VBLANK and VSYNC
; ---------------------------------------------------------------
NextFrame:
	lda #2		; Store binary value x00000010 in register A
	sta VBLANK	; Turn VBLANK on
	sta VSYNC	; Turn VSYNC on

; ---------------------------------------------------------------
; Generate the three lines of VSYNC
; ---------------------------------------------------------------
	sta WSYNC	; First scanline
	sta WSYNC	; Second scanline
	sta WSYNC	; Third scanline
	lda #0
	sta VSYNC	; Turn VSYNC off

; ---------------------------------------------------------------
; Let the TIA output the recommended 37 scanlines of VBLANK
; ---------------------------------------------------------------
	repeat 37
	sta WSYNC
	repend
	lda #0
	sta VBLANK	; Turn VBLANK off

; ---------------------------------------------------------------
; Draw 192 visible scanlines (kernel)
; ---------------------------------------------------------------
VisibleScanLines:
	; Draw 10 empty scanlines at the top of the frame
	repeat 10
	sta WSYNC
	repend

; ---------------------------------------------------------------
; Display 10 scanlines for the scoreboard number
; Pull data from an array of bytes defined at NumberBitmap
; ---------------------------------------------------------------
	ldy #0
ScoreboardLoop:
	lda NumberBitmap,y
	sta PF1
	sta WSYNC
	iny			; Increment value hold by register Y
	cpy #10			; Compare Y register with value 10
	bne ScoreboardLoop	; If value hold by register Y is not equal to 10 loop

	lda #0
	sta PF1			; Reset register PF1

	; Draw 50 empty scanlines between scoreboard and player
	repeat 50
	sta WSYNC
	repend

; ---------------------------------------------------------------
; Display 10 for player 0 graphics.
; Pull data from an array of bytes defined at PlayerBitmap
; ---------------------------------------------------------------
	ldy #0
Player0Loop:
	lda PlayerBitmap,y
	sta GRP0
	sta WSYNC
	iny
	cpy P0Height
	bne Player0Loop

	lda #0
	sta GRP0			; Reset register GRP0

; ---------------------------------------------------------------
; Display 10 for player 1 graphics.
; Pull data from an array of bytes defined at PlayerBitmap
; ---------------------------------------------------------------
	ldy #0
Player1Loop:
	lda PlayerBitmap,y
	sta GRP1
	sta WSYNC
	iny
	cpy P1Height
	bne Player1Loop

	lda #0
	sta GRP1			; Reset register GRP1

; ---------------------------------------------------------------
; Draw the remaining 102 scanning lines (192-90)
; ---------------------------------------------------------------
	repeat 102
	sta WSYNC
	repend

; ---------------------------------------------------------------
; Output 30 more VBLANK overscan lines to complete our fram
; ---------------------------------------------------------------
	repeat 30
	sta WSYNC
	repend

; ---------------------------------------------------------------
; Jump to the beggining
; ---------------------------------------------------------------
	jmp NextFrame

; ---------------------------------------------------------------
; Defines an array of bytes to draw the scoreboard number.
; We add these bytes in the last ROM addresses.
; ---------------------------------------------------------------
	org $FFE8
PlayerBitmap:
	.byte #%01111110   ;  ######
	.byte #%11111111   ; ########
	.byte #%10011001   ; #  ##  #
	.byte #%11111111   ; ########
	.byte #%11111111   ; ########
	.byte #%11111111   ; ########
	.byte #%10111101   ; # #### #
	.byte #%11000011   ; ##    ##
	.byte #%11111111   ; ########
	.byte #%01111110   ;  ######

; ---------------------------------------------------------------
; Defines an array of bytes to draw the scoreboard number.
; We add these bytes in the final ROM addresses.
; ---------------------------------------------------------------
	org $FFF2
NumberBitmap:
	.byte #%00001110   ; ########
	.byte #%00001110   ; ########
	.byte #%00000010   ;      ###
	.byte #%00000010   ;      ###
	.byte #%00001110   ; ########
	.byte #%00001110   ; ########
	.byte #%00001000   ; ###
	.byte #%00001000   ; ###
	.byte #%00001110   ; ########
	.byte #%00001110   ; ########

; ---------------------------------------------------------------
; Complete ROM size
; ---------------------------------------------------------------
	org $FFFC
	.word Start
	.word Start