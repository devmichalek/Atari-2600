	processor 6502

	include "../vcs.h"
	include "../macro.h"

	seg code
	org $f000	; Defines the origin of the ROM ar $F000

Start:
	;CLEAN_START	; Macro to safely clear the memory

; ---------------------------------------------------------------
; Set background luminosity color to yellow
; ---------------------------------------------------------------
	lda #$1E		; Load color into register A ($1E is NTSC yellow)
	sta COLUBK	; Store value of A register into background address $09

	jmp Start	; Repeat from start

; ---------------------------------------------------------------
; Fill ROM size to exactly 4KB
; ---------------------------------------------------------------
	org $FFFC
	.word Start	; Reset vector at $FFFC (where program starts)
	.word Start	; Interrupt vector at $FFFE (unused in the VCS)