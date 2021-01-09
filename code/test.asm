include code\console.inc

TEST_BOX_WIDTH					equ 16
TEST_BOX_HALF_WIDTH 			equ TEST_BOX_WIDTH / 2
TEST_BOX_HEIGHT 				equ 16
TEST_BOX_HALF_HEIGHT 			equ TEST_BOX_HEIGHT / 2

allSegments group code, data
    assume cs:allSegments, ds:allSegments

code segment public

extern consolePrintByte:proc
extern renderBox:proc, renderHorizLine:proc

testInit proc
    mov [TestPosXLow],0
    mov [TestPosXHigh],160
    mov [TestPosYPacked],100 * 256

    ret
testInit endp

testInitRender proc
    call testRender
	; Execute code after the regular render function so the ES segment is set to video memory.
	mov cx,0
	mov bx,BIOS_VIDEO_MODE_320_200_4_WIDTH
	mov dl,100
	mov dh,2
	call renderHorizLine
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
	call renderBox

	xor dx,dx
	CONSOLE_SET_CURSOR_POS
    pop dx
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
