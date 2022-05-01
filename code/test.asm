TEST_NO_EXTERNS equ 1
include code\test.inc
include code\console.inc
include code\keyboard.inc
include code\render.inc

TEST_BOX_WIDTH					equ 16
TEST_BOX_HALF_WIDTH 			equ TEST_BOX_WIDTH / 2
TEST_BOX_HEIGHT 				equ 16
TEST_BOX_HALF_HEIGHT 			equ TEST_BOX_HEIGHT / 2
TEST_BOX_POSX_START             equ BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH
TEST_BOX_POSY_START             equ BIOS_VIDEO_MODE_320_200_4_HALF_HEIGHT
TEST_BOX_SPEEDY_PACKED 			equ 30h

allSegments group code, data
    assume cs:allSegments, ds:allSegments, es:nothing

code segment readonly public

; ------------;
; Code public ;
; ------------;

testInit proc
    mov [TestPosXLow],0
	mov [TestPosXHigh],TEST_BOX_POSX_START
    mov [TestPosYPacked],TEST_BOX_POSY_START * 256
	mov [TestPrevPosY],TEST_BOX_POSY_START

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
    mov ax,[TestPosYPacked]
    mov [TestPrevPosY],ah
    add ax,TEST_BOX_SPEEDY_PACKED
    cmp ah,BIOS_VIDEO_MODE_320_200_4_HEIGHT
    jb @f
    sub ah,BIOS_VIDEO_MODE_320_200_4_HEIGHT
@@:
    mov [TestPosYPacked],ax

    ret
testUpdate endp

testRender proc
    ; Erase previous box.
	mov cx,[TestPosXHigh]
	sub cx,TEST_BOX_HALF_WIDTH
	mov bx,cx
	add bx,TEST_BOX_WIDTH
    mov dl,[TestPrevPosY]
	sub dl,TEST_BOX_HALF_HEIGHT
	mov dh,dl
    add dh,TEST_BOX_HEIGHT
    mov al,1
	call renderBox320x200x4

    ; Draw current box.
	mov cx,[TestPosXHigh]
	sub cx,TEST_BOX_HALF_WIDTH
	mov bx,cx
	add bx,TEST_BOX_WIDTH
    mov dl,byte ptr [TestPosYPacked + 1]
	sub dl,TEST_BOX_HALF_HEIGHT
	mov dh,dl
    add dh,TEST_BOX_HEIGHT
ifdef DEBUG
    ; Save top and bottom of the box to print it later.
    push dx
endif
    mov al,3
	call renderBox320x200x4

if CONSOLE_ENABLED
    ; Print debug info.
	CONSOLE_SET_CURSOR_POS 0, 0
    pop ax
    mov bl,ah
	call consolePrintByte
    CONSOLE_PRINT_CHAR "-"
    mov al,bl
	call consolePrintByte
    CONSOLE_NEXT_LINE
    mov al,byte ptr [TestPosYPacked + 1]
    call consolePrintByte
    CONSOLE_NEXT_LINE
    mov al,"N"
	KEYBOARD_IS_KEY_PRESSED BIOS_KEYBOARD_SCANCODE_ARROW_UP
	jnz @f
	mov al,"Y"
@@:
    call consolePrintChar
endif

    ret
testRender endp

; -------------;
; Code private ;
; -------------;

code ends

data segment public
	TestPosXLow             dw ?
	TestPosXHigh            dw ?
    TestPosYPacked          dw ?
    TestPrevPosY            db ?
data ends

end
