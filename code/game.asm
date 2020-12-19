include ascii.inc
include bios.inc
include dos.inc

allSegments group code, data
    assume cs:allSegments, ds:allSegments

code segment public
	org 100h

main proc
	; Save previous video mode.
	mov ah,BIOS_VIDEO_FUNC_GET_VIDEO_MODE
	int BIOS_VIDEO_INT
	push ax

	; Set graphics mode.
	mov al,BIOS_VIDEO_MODE_320_200_4_BURST_ON
	mov ah,BIOS_VIDEO_FUNC_SET_VIDEO_MODE
	int BIOS_VIDEO_INT	
	; Set palette 0.
	mov bx,100h
	mov ah,BIOS_VIDEO_FUNC_SET_PLT_BKG_BDR
	int BIOS_VIDEO_INT

	; Test writing pixels.
	call testVideo2

	; Check if any key was pressed before continuing.
checkKeypress:	
	mov ah,DOS_REQUEST_FUNC_INPUT_STATUS
	int DOS_REQUEST_INT
	test al,al
	jz short checkKeypress

	; Restore previous video mode.
	pop ax
	mov ah,BIOS_VIDEO_FUNC_SET_VIDEO_MODE
	int BIOS_VIDEO_INT

	; Quit.
	int DOS_COM_TERMINATION_INT
main endp

printNibbleInHex proc
	and dl,0fh
	cmp dl,10
	jb short noLetter
	add dl,'A'-10
	jmp short printChar
noLetter:
	add dl,'0'
printChar:
	mov ah,DOS_REQUEST_FUNC_PRINT_CHAR
	int DOS_REQUEST_INT
	ret
printNibbleInHex endp

printByte proc
	mov ch,dl
	mov cl,4
	shr dl,cl
	call printNibbleInHex
	mov dl,ch
	call printNibbleInHex
	ret
printByte endp

drawHorizLine proc
drawLoop:
	mov ah,BIOS_VIDEO_FUNC_SET_PIXEL
	int BIOS_VIDEO_INT
	inc cx
	cmp cx,bx
	jb short drawLoop
	ret
drawHorizLine endp

testKeyboard1 proc
nextKey:
	mov ah,BIOS_KEYBOARD_FUNC_GET_CHAR
	int BIOS_KEYBOARD_INT
	cmp al,3
	je quit

	; Print scancode.
	push ax
	mov dl,ah
	call printByte

	; Print ascii.
	mov dl,' '
	mov ah,DOS_REQUEST_FUNC_PRINT_CHAR
	int DOS_REQUEST_INT
	pop ax
	mov dl,al
	mov ah,DOS_REQUEST_FUNC_PRINT_CHAR
	int DOS_REQUEST_INT

	; Go to next line.
	mov dl,ASCII_CR
	mov ah,DOS_REQUEST_FUNC_PRINT_CHAR
	int DOS_REQUEST_INT
	mov dl,ASCII_LF
	mov ah,DOS_REQUEST_FUNC_PRINT_CHAR
	int DOS_REQUEST_INT

	jmp short nextkey

quit:
	int DOS_COM_TERMINATION_INT
testKeyboard1 endp

testKeyboard2 proc
nextKey:
	mov ah,BIOS_KEYBOARD_FUNC_GET_FLAGS
	int BIOS_KEYBOARD_INT
	mov dl,al
	call printByte

	; Go to next line.
	mov dl,ASCII_CR
	mov ah,DOS_REQUEST_FUNC_PRINT_CHAR
	int DOS_REQUEST_INT
	mov dl,ASCII_LF
	mov ah,DOS_REQUEST_FUNC_PRINT_CHAR
	int DOS_REQUEST_INT

	jmp short nextkey
testKeyboard2 endp

testVideo1 proc
	mov al,1
	mov cx,0
	mov bx,320
	mov dx,50
	call drawHorizLine
	mov al,2
	mov cx,0
	mov bx,320
	mov dx,100
	call drawHorizLine
	mov al,3
	mov cx,0
	mov bx,320
	mov dx,150
	call drawHorizLine

	ret
testVideo1 endp

testVideo2 proc
	mov ax,0b800h
	mov es,ax
	cld
	
	; Even lines.
	xor di,di

	mov ax,5555h
	mov cx,480	
	rep stosw

	mov ax,0aaaah
	mov cx,480
	rep stosw

	mov ax,0ffffh
	mov cx,480
	rep stosw

	; Odd lines
	mov di,02000h

	mov cx,480
	rep stosw

	mov ax,5555h
	mov cx,480
	rep stosw

	mov ax,0aaaah
	mov cx,480
	rep stosw

	ret
testVideo2 endp

code ends

data segment public
data ends

	end main
