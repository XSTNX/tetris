include code\console.inc
include code\keyboard.inc

TEST2_BOX_WIDTH					equ 16
TEST2_BOX_HALF_WIDTH 			equ TEST2_BOX_WIDTH / 2
TEST2_BOX_HEIGHT 				equ 16
TEST2_BOX_HALF_HEIGHT 			equ TEST2_BOX_HEIGHT / 2
TEST2_BOX_POSX_START            equ BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH
TEST2_BOX_POSY_START            equ BIOS_VIDEO_MODE_320_200_4_HALF_HEIGHT
TEST2_BOX_SPEEDY_PACKED 		equ 40h

allSegments group code, data
    assume cs:allSegments, ds:allSegments

code segment public

extern consolePrintByte:proc, consolePrintByteHex:proc
extern renderBox320x200x4:proc, renderHorizLine320x200x4:proc

test2Init proc
    mov [Test2PosXLow],0
	mov [Test2PosXHigh],TEST2_BOX_POSX_START
    mov [Test2PosYPacked],TEST2_BOX_POSY_START * 256
	mov [Test2PrevPosY],TEST2_BOX_POSY_START

    ret
test2Init endp

test2InitRender proc
    call test2Render
    
    ; Top.
	mov cx,0
    mov bx,BIOS_VIDEO_MODE_320_200_4_WIDTH
    mov dx,TEST2_BOX_HEIGHT * 256
    mov al,2
	call renderBox320x200x4
    ; Bottom.
	mov cx,0
    mov bx,BIOS_VIDEO_MODE_320_200_4_WIDTH
    mov dx,(BIOS_VIDEO_MODE_320_200_4_HEIGHT - TEST2_BOX_HEIGHT) + (BIOS_VIDEO_MODE_320_200_4_HEIGHT * 256)
    mov al,2
	call renderBox320x200x4
    ; Center vert.
	mov cx,BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH - TEST2_BOX_HALF_WIDTH
    mov bx,BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH + TEST2_BOX_HALF_WIDTH
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
test2InitRender endp

test2Update proc
    mov ax,[Test2PosYPacked]
    mov [Test2PrevPosY],ah
    add ax,TEST2_BOX_SPEEDY_PACKED
    cmp ah,BIOS_VIDEO_MODE_320_200_4_HEIGHT
    jb skipRoll
    xor ah,ah
skipRoll:
    mov [Test2PosYPacked],ax

    ret
test2Update endp

test2Render proc
    ; Erase previous box.
	mov cx,[Test2PosXHigh]
	sub cx,TEST2_BOX_HALF_WIDTH
	mov bx,cx
	add bx,TEST2_BOX_WIDTH
    mov dl,[Test2PrevPosY]
	sub dl,TEST2_BOX_HALF_HEIGHT
	mov dh,dl
    add dh,TEST2_BOX_HEIGHT
    mov al,1
	call renderBox320x200x4

    ; Draw current box.
	mov cx,[Test2PosXHigh]
	sub cx,TEST2_BOX_HALF_WIDTH
	mov bx,cx
	add bx,TEST2_BOX_WIDTH
    mov dl,byte ptr [Test2PosYPacked + 1]
	sub dl,TEST2_BOX_HALF_HEIGHT
	mov dh,dl
    add dh,TEST2_BOX_HEIGHT
ifdef DEBUG
    ; Save top and bottom of the box to print it later.
    push dx
endif
    mov al,3
	call renderBox320x200x4

ifdef DEBUG
    ; Print debug info.
	consoleSetCursorPos 0, 0
    pop dx
    push dx
	call consolePrintByte
    consoleSetCursorPos 3, 0
    consolePrintChar "-"
    consoleSetCursorPos 4, 0
    pop dx
    mov dl,dh
	call consolePrintByte
    consoleSetCursorPos 0, 1
    mov dl,byte ptr [Test2PosYPacked + 1]
    call consolePrintByte
    consoleSetCursorPos 0, 2
    mov dl,"N"
	keyboardIsKeyPressed BIOS_KEYBOARD_SCANCODE_ARROW_UP
	jnz skipKeyPressed
	mov dl,"Y"
skipKeyPressed:
    consolePrintChar dl
endif

    ret
test2Render endp

; ---------;
; Private. ;
; ---------;

code ends

data segment public
	Test2PosXLow            dw ?
	Test2PosXHigh           dw ?
    Test2PosYPacked         dw ?
    Test2PrevPosY           db ?
data ends

end
