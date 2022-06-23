TEST_NO_EXTERNS equ 1
include code\test.inc
include code\assert.inc
include code\assumSeg.inc
include code\console.inc
include code\keyboard.inc
include code\render.inc

TEST_BOX_SIDE					equ 16
TEST_BOX_HALF_SIDE              equ TEST_BOX_SIDE / 2
TEST_BOX_POSX                   equ BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH
TEST_BOX_POSY_START             equ BIOS_VIDEO_MODE_320_200_4_HALF_HEIGHT
TEST_BOX_LOWX                   equ TEST_BOX_POSX - TEST_BOX_HALF_SIDE
TEST_BOX_HIGHX                  equ TEST_BOX_POSX + TEST_BOX_HALF_SIDE
TEST_BOX_SPEEDY_PACKED 			equ 100h

code segment readonly public

; ------------;
; Code public ;
; ------------;

testInit proc
    mov [TestPosYPacked],TEST_BOX_POSY_START * 256
	mov [TestPrevPosY],TEST_BOX_POSY_START

    ret
testInit endp

testInitRender proc
    ; Top rect.
    xor cx,cx
    mov di,BIOS_VIDEO_MODE_320_200_4_WIDTH
    mov dx,0 + (2 * 256)
    mov bl,TEST_BOX_SIDE
	call renderRect320x200x4
    ; Bottom rect.
    xor cx,cx
    mov di,BIOS_VIDEO_MODE_320_200_4_WIDTH
    mov dx,(BIOS_VIDEO_MODE_320_200_4_HEIGHT - TEST_BOX_SIDE) + (2 * 256)
    mov bl,BIOS_VIDEO_MODE_320_200_4_HEIGHT
	call renderRect320x200x4
    ; Center rect.
    mov cx,BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH - TEST_BOX_HALF_SIDE
    mov di,BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH + TEST_BOX_HALF_SIDE
    mov dx,0 + (1 * 256)
    mov bl,BIOS_VIDEO_MODE_320_200_4_HEIGHT
	call renderRect320x200x4
    ; Center horiz line.
	xor cx,cx
	mov di,BIOS_VIDEO_MODE_320_200_4_WIDTH
    mov dx,BIOS_VIDEO_MODE_320_200_4_HALF_HEIGHT + (1 * 256)
	call renderHorizLine320x200x4

    ret
testInitRender endp

testUpdate proc
    mov ax,[TestPosYPacked]
    mov [TestPrevPosY],ah
    add ax,TEST_BOX_SPEEDY_PACKED
    cmp ah,BIOS_VIDEO_MODE_320_200_4_HEIGHT
    jb short @f
    sub ah,BIOS_VIDEO_MODE_320_200_4_HEIGHT
@@:
    mov [TestPosYPacked],ax

    ret
testUpdate endp

testRender proc
    ; Erase previous box.
	mov cx,TEST_BOX_LOWX
    mov di,TEST_BOX_HIGHX
    ; Save lowX and highX to reuse them when drawing the current box.
    push cx
    push di
    mov dl,[TestPrevPosY]
	sub dl,TEST_BOX_HALF_SIDE
	mov bl,dl
    add bl,TEST_BOX_SIDE
    mov dh,1
    ; Keep lowY and highY within screen bounds.
    cmp dl,BIOS_VIDEO_MODE_320_200_4_HEIGHT
    jb short @f
    xor dl,dl
@@:
    cmp bl,BIOS_VIDEO_MODE_320_200_4_HEIGHT + 1
    jb short @f
    mov bl,BIOS_VIDEO_MODE_320_200_4_HEIGHT
@@:
	call renderRect320x200x4

    ; Draw current box.
    pop di
    pop cx
    mov dl,byte ptr [TestPosYPacked + 1]
	sub dl,TEST_BOX_HALF_SIDE
	mov bl,dl
    add bl,TEST_BOX_SIDE
    mov dh,3
    ; Keep lowY and highY within screen bounds.
    cmp dl,BIOS_VIDEO_MODE_320_200_4_HEIGHT
    jb short @f
    xor dl,dl
@@:
    cmp bl,BIOS_VIDEO_MODE_320_200_4_HEIGHT + 1
    jb short @f
    mov bl,BIOS_VIDEO_MODE_320_200_4_HEIGHT
@@:
ifdef DEBUG
    ; Save highY and lowY, in that order, to print them later.
    push bx
    push dx
endif
    call renderRect320x200x4

if CONSOLE_ENABLED
    ; Print debug info.
	CONSOLE_SET_CURSOR_COL_ROW 0, 0
    pop ax
	call consolePrintByte
    mov al,"-"
    call consolePrintChar
    pop ax
	call consolePrintByte
    call consoleNextLine
    mov al,byte ptr [TestPosYPacked + 1]
    call consolePrintByte
    call consoleNextLine
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

constData segment readonly public
constData ends

data segment public
    TestPosYPacked          dw ?
    TestPrevPosY            db ?
data ends

end
