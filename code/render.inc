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

; Input: aVideoMode (constant unsigned byte).
RENDER_SET_VIDEO_MODE macro aVideoMode:req
	mov ax,aVideoMode or (BIOS_VIDEO_FUNC_SET_VIDEO_MODE shl 8)
	int BIOS_VIDEO_INT
endm

; Output: al (unsigned byte video mode).
RENDER_GET_VIDEO_MODE macro
	mov ah,BIOS_VIDEO_FUNC_GET_VIDEO_MODE
	int BIOS_VIDEO_INT
endm

; Input: aPaletteNum (constant unsigned byte).
RENDER_SET_PALETTE_NUM macro aPaletteNum:req
	mov ah,BIOS_VIDEO_FUNC_SET_PLT_BKG_BDR
    mov bx,aPaletteNum or (BIOS_VIDEO_SET_PLT_BKG_BDR_PALETTE shl 8)
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
