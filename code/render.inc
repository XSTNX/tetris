include code\bios.inc

ifndef RENDER_NO_EXTERNS
; Might make more sense to create this table at assembly time, need to figure out how to use the repeat macro.
extern renderInitMultiplyRowBy80Table:proc
extern renderPixel320x200x4:proc, renderHorizLine320x200x4:proc, renderRect320x200x4:proc
extern renderTile8x8:proc, renderEmptyTile8x8:proc
endif

; Input: aPaletteNum, has to be a literal (unsigned byte).
RENDER_SET_PALETTE_320x200x4 macro aPaletteNum:req
	mov ah,BIOS_VIDEO_FUNC_SET_PLT_BKG_BDR
    mov bx,aPaletteNum + (BIOS_VIDEO_SET_PLT_BKG_BDR_PALETTE * 256)
	int BIOS_VIDEO_INT
endm

WAIT_VSYNC macro
local vsyncWait0, vsyncWait1
	mov dx,3dah
vsyncWait0:
	in al,dx
	test al,8
	jnz short vsyncWait0
vsyncWait1:
	in al,dx
	test al,8
	jz short vsyncWait1
endm
