	processor 6502

; ---------------------------------------------------------------
; Include required files with definitions and macros
; ---------------------------------------------------------------
	include "vcs.h"
	include "macro.h"

; ---------------------------------------------------------------
; Start our ROM code
; ---------------------------------------------------------------
	seg code
	org $F000

Start:
	CLEAN_START	; Macro to safely clear memory and TIA
        ldx #$80	; Blue background color
        stx COLUBK
        
        lda #$1C	; Yellow playfield color
        sta COLUPF

; ---------------------------------------------------------------
; Start a new frame by turning on VBLANK and VSYNC
; ---------------------------------------------------------------
StartFrame:
	lda #2		; Store binary value x00000010 in register A
	sta VBLANK	; Turn on VBLANK
	sta VSYNC	; Turn on VSYNC

; ---------------------------------------------------------------
; Generate the three lines of VSYNC
; ---------------------------------------------------------------
	sta WSYNC	; First scanline
	sta WSYNC	; Second scanline
	sta WSYNC	; Third scanline
	lda #0
	sta VSYNC	; Turn off VSYNC

; ---------------------------------------------------------------
; Let the TIA output the recommended 37 scanlines of VBLANK
; ---------------------------------------------------------------
	repeat 37
        sta WSYNC
        repend
	lda #0
	sta VBLANK	; Turn off VBLANK
  
; ---------------------------------------------------------------
; Set the CTRLPF register to allow playfield reflection
; ---------------------------------------------------------------
	ldx #%00000001 ; CTRLPF register (D0 means reflect the PF)
        stx CTRLPF

; ---------------------------------------------------------------
; Draw 192 visible scanlines (kernel)
; ---------------------------------------------------------------
	; Skip 7 scanlines with no PF set
	ldx #0
        stx PF0
        stx PF1
        stx PF2
        repeat 7
        sta WSYNC
        repend
        
        ; Set the PF0 to 1110 (LSB first) and PF1-PF2 as 1111 1111
        ldx #%11100000
        stx PF0
        ldx #%11111111
        stx PF1
        stx PF2
        repeat 7
        sta WSYNC
        repend
        
        ; Set the next 164 lines only with PF0 third bit enabled
        ldx #%00100000
        stx PF0
        ldx #%00000000
        stx PF1
        stx PF2
 	repeat 164
        sta WSYNC
        repend
        
        ; Set the PF0 to 1110 (LSB first) and PF1-PF2 as 1111 1111
        ldx #%11100000
        stx PF0
        ldx #%11111111
        stx PF1
        stx PF2
        repeat 7
        sta WSYNC
        repend
        
        ; Skip 7 vertical lines with no PF set
        ldx #0
        stx PF0
        stx PF1
        stx PF2
        repeat 7
        sta WSYNC
        repend

; ---------------------------------------------------------------
; Output 30 more VBLANK linex (forescan) to complete our frame
; ---------------------------------------------------------------
	lda #2
        sta VBLANK
        repeat 30
        sta WSYNC
        repend
        lda #0
        sta VBLANK

; ---------------------------------------------------------------
; Jump to the next frame
; ---------------------------------------------------------------
	jmp StartFrame

; ---------------------------------------------------------------
; Complete my ROM size to 4KB
; ---------------------------------------------------------------
	org $FFFC
	.word Start
	.word Start