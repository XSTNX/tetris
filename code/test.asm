include code\console.inc

TEST_BOX_WIDTH					equ 16
TEST_BOX_HALF_WIDTH 			equ TEST_BOX_WIDTH / 2
TEST_BOX_HEIGHT 				equ 16
TEST_BOX_HALF_HEIGHT 			equ TEST_BOX_HEIGHT / 2

allSegments group code, data
    assume cs:allSegments, ds:allSegments

code segment public

extern consolePrintByte:proc
extern renderBox320x200x4:proc, renderHorizLine320x200x4:proc

testInit proc
    mov [TestPosXLow],0
    mov [TestPosXHigh],160
    mov [TestPosYPacked],BIOS_VIDEO_MODE_320_200_4_HALF_HEIGHT * 256

    ret
testInit endp

testInitRender proc
    call testRender
    
    ; Top.
	mov cx,0
    mov bx,BIOS_VIDEO_MODE_320_200_4_WIDTH
    mov dx,TEST_BOX_HEIGHT * 256
    mov al,2
	call renderBox320x200x4
    ; Bottom.
	mov cx,0
    mov bx,BIOS_VIDEO_MODE_320_200_4_WIDTH
    mov dx,(BIOS_VIDEO_MODE_320_200_4_HEIGHT - TEST_BOX_HEIGHT) + (BIOS_VIDEO_MODE_320_200_4_HEIGHT * 256)
    mov al,2
	call renderBox320x200x4
    ; Center vert.
	mov cx,BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH - TEST_BOX_HALF_WIDTH
    mov bx,BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH + TEST_BOX_HALF_WIDTH
    mov dx,BIOS_VIDEO_MODE_320_200_4_HEIGHT * 256
    mov al,1
	call renderBox320x200x4
    ; Center horiz.
	mov cx,0
	mov bx,BIOS_VIDEO_MODE_320_200_4_WIDTH
	mov dl,BIOS_VIDEO_MODE_320_200_4_HALF_HEIGHT
	mov dh,1
	call renderHorizLine320x200x4

    ret
testInitRender endp

testUpdate proc
    ret
testUpdate endp

testRender proc
	mov ax,BIOS_VIDEO_MODE_320_200_4_START_ADDR
	mov es,ax

	mov cx,[TestPosXHigh]
	sub cx,TEST_BOX_HALF_WIDTH
	mov bx,cx
	add bx,TEST_BOX_WIDTH
    mov dl,byte ptr [TestPosYPacked + 1]
	sub dl,TEST_BOX_HALF_HEIGHT
	mov dh,dl
    add dh,TEST_BOX_HEIGHT
    push dx    
    mov al,3
	call renderBox320x200x4

    ; Print debug info.
	xor dx,dx
	CONSOLE_SET_CURSOR_POS
    pop dx
    push dx
	call consolePrintByte
    mov dx,3
    CONSOLE_SET_CURSOR_POS
    mov dl,"-"
    CONSOLE_PRINT_CHAR
    mov dx,4
    CONSOLE_SET_CURSOR_POS
    pop dx
    mov dl,dh
	call consolePrintByte

    ret
testRender endp

; ---------;
; Private. ;
; ---------;

code ends

data segment public
	TestPosXLow             dw ?
	TestPosXHigh            dw ?
    TestPosYPacked          dw ?
data ends

end
