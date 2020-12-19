include bios.inc
include dos.inc

allSegments group code, data
    assume cs:allSegments, ds:allSegments

code segment public
	org 100h

main proc
	; Save previous video mode.
	mov ah,BIOS_FUNC_VIDEO_GET_VIDEO_MODE
	int BIOS_INT_VIDEO
	push ax

	; Set graphics mode.
	mov al,BIOS_VIDEO_MODE_320_200_4_BURST_ON
	mov ah,BIOS_FUNC_VIDEO_SET_VIDEO_MODE
	int BIOS_INT_VIDEO

	; Restore previous video mode.
	pop ax
	mov ah,BIOS_FUNC_VIDEO_SET_VIDEO_MODE
	int BIOS_INT_VIDEO

	; Quit.
	int DOS_INT_COM_TERMINATION
main endp

code ends

data segment public
data ends

	end main
