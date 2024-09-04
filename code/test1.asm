include code\test1.inc
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

; Change the code of how the block disappears from the screen.

code segment readonly public

;-------------;
; Code public ;
;-------------;

; Clobber: everything.
test1Init proc
    mov [Test1PosYPacked],TEST_BOX_POSY_START shl 8
	mov [Test1PrevPosY],TEST_BOX_POSY_START

    ret
test1Init endp

; Clobber: everything.
test1InitRender proc
    ; Top rect.
    xor cx,cx
    mov di,BIOS_VIDEO_MODE_320_200_4_WIDTH
    mov dx,0 or (2 shl 8)
    mov bl,TEST_BOX_SIDE
	call renderRect320x200x4
    ; Bottom rect.
    xor cx,cx
    mov di,BIOS_VIDEO_MODE_320_200_4_WIDTH
    mov dx,(BIOS_VIDEO_MODE_320_200_4_HEIGHT - TEST_BOX_SIDE) or (2 shl 8)
    mov bl,BIOS_VIDEO_MODE_320_200_4_HEIGHT
	call renderRect320x200x4
    ; Vert rect.
    mov cx,BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH - TEST_BOX_HALF_SIDE
    mov di,BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH + TEST_BOX_HALF_SIDE
    mov dx,0 or (1 shl 8)
    mov bl,BIOS_VIDEO_MODE_320_200_4_HEIGHT
	call renderRect320x200x4
    ; Horiz line.
	xor cx,cx
	mov di,BIOS_VIDEO_MODE_320_200_4_WIDTH
    mov dx,BIOS_VIDEO_MODE_320_200_4_HALF_HEIGHT or (1 shl 8)
	call renderHorizLine320x200x4

    ret
test1InitRender endp

; Clobber: everything.
test1Update proc
    mov ax,[Test1PosYPacked]
    mov [Test1PrevPosY],ah
    add ax,TEST_BOX_SPEEDY_PACKED
    cmp ah,BIOS_VIDEO_MODE_320_200_4_HEIGHT
    jb short @f
    sub ah,BIOS_VIDEO_MODE_320_200_4_HEIGHT
@@:
    mov [Test1PosYPacked],ax

    ret
test1Update endp

; Clobber: everything.
test1Render proc
    ; Erase previous box.
	mov cx,TEST_BOX_LOWX
    mov di,TEST_BOX_HIGHX
    ; Save lowX and highX to reuse them when drawing the current box.
    push cx
    push di
    mov dl,[Test1PrevPosY]
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
    mov dl,byte ptr [Test1PosYPacked + 1]
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
    mov al,byte ptr [Test1PosYPacked + 1]
    call consolePrintByte
    call consoleNextLine
	KEYBOARD_IS_KEY_PRESSED BIOS_KEYBOARD_SCANCODE_ARROW_UP    
    mov al,"N"
	jnz @f
	mov al,"Y"
@@:
    call consolePrintChar
endif

    ret
test1Render endp

;--------------;
; Code private ;
;--------------;

code ends

constData segment readonly public
constData ends

data segment public
    Test1PosYPacked         word ?
    Test1PrevPosY           byte ?
data ends

end
