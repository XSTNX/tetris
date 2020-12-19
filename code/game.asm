include bios.inc
include dos.inc

allSegments group code, data
    assume cs:allSegments, ds:allSegments

code segment public
	org 100h

main proc
	; Save previous video mode.
	mov ah,FUNC_BIOS_VIDEO_GET_VIDEO_MODE
	int INT_BIOS_VIDEO
	mov [PrevVideoMode],al

	; Restore previous video mode.
	mov al,[PrevVideoMode]
	mov ah,FUNC_BIOS_VIDEO_SET_VIDEO_MODE
	int INT_BIOS_VIDEO

	; Quit.
	int INT_DOS_COM_TERMINATION
main endp

code ends

data segment public
	PrevVideoMode		db ?
data ends

	end main
