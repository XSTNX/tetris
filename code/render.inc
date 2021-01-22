include code\bios.inc

; Input: aPaletteNum, has to be a literal (unsigned byte).
renderSetPalette320x200x4 macro aPaletteNum:req
	mov ah,BIOS_VIDEO_FUNC_SET_PLT_BKG_BDR
    mov bx,(BIOS_VIDEO_SET_PLT_BKG_BDR_PALETTE * 256) + aPaletteNum
	int BIOS_VIDEO_INT
endm
