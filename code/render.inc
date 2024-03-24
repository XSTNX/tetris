ifndef RENDER_INC
RENDER_INC = 1

include code\bios.inc

RENDER_CGA_STATUS_PORT				equ 3dah
; The books MASM Bible and Turbo Assembler Bible both say vsync is in bit0, not bit3, but this is not the behavior I'm seeing in DOSBox.
; This should be confirmed on real hardware.
RENDER_CGA_STATUS_MASK_VSYNC		equ (1 shl 3)

externdef renderStart:proc
externdef renderPixel320x200x4:proc, renderHorizLine320x200x4:proc, renderVertLine320x200x4:proc, renderRect320x200x4:proc
externdef renderTile8x8:proc, renderEmptyTile8x8:proc
ifndef RENDER_INC_HACK
externdef RenderMultiplyRowBy80Table:word
endif

; Input: aPaletteNum, has to be a literal (unsigned byte).
RENDER_SET_PALETTE_320x200x4 macro aPaletteNum:req
	mov ah,BIOS_VIDEO_FUNC_SET_PLT_BKG_BDR
    mov bx,aPaletteNum + (BIOS_VIDEO_SET_PLT_BKG_BDR_PALETTE * 256)
	int BIOS_VIDEO_INT
endm

; Clobber: ax, dx.
RENDER_WAIT_FOR_VSYNC macro
local wait0, wait1
	mov dx,RENDER_CGA_STATUS_PORT
	; Wait until vsync is over if it has already started.
wait0:
	in al,dx
	test al,RENDER_CGA_STATUS_MASK_VSYNC
	jnz short wait0
	; Wait until vsync begins.
wait1:
	in al,dx
	test al,RENDER_CGA_STATUS_MASK_VSYNC
	jz short wait1
endm

endif
