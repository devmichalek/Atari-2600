	processor 6502

	include "../vcs.h"
	include "../macro.h"

	seg code
	org $F000

Start:
	CLEAN_START	; Macro to safely clear memory and TIA

; ---------------------------------------------------------------
; Start a new frame by turning on VBLANK and VSYNC
; ---------------------------------------------------------------
NextFrame:
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
	ldx #37		; Store value 37 into the register X
LoopVBlank:
	sta WSYNC	; Hit WSYNC and wait for the next scanline
	dex		; X--
	bne LoopVBlank	; Loop while value inside register X is different than 0

	lda #0
	sta VBLANK	; Turn off VBLANK

; ---------------------------------------------------------------
; Draw 192 visible scanlines (kernel)
; ---------------------------------------------------------------
	ldx #192
LoopScanline:
	stx COLUBK	; Set color of this scanline
	sta WSYNC	; Wait for the next scanline
	dex		; X--
	bne LoopScanline	; Loop while X != 0

; ---------------------------------------------------------------
; Output 30 more VBLANK linex (forescan) to complete our frame
; ---------------------------------------------------------------
	lda #2
	sta VBLANK

	ldx #30
LoopOverscan:
	sta WSYNC	; Wait for the next scanline
	dex
	bne LoopOverscan	; Loop while X != 0

	jmp NextFrame	; Jump to next frame

; ---------------------------------------------------------------
; Complete my ROM size to 4KB
; ---------------------------------------------------------------
	org $FFFC
	.word Start
	.word Start