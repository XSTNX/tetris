TEST4_NO_EXTERNS equ 1
include code\test4.inc
include code\assert.inc
include code\assumSeg.inc
include code\console.inc
include code\keyboard.inc
include code\render.inc

code segment readonly public

; ------------;
; Code public ;
; ------------;

test4Init proc
    ret
test4Init endp

test4InitRender proc
    ; Text.
    mov ax,000ah
    call consolePrintWordHex
	mov al,"-"
	call consolePrintChar
    mov ax,00e9h
    call consolePrintWordHex
	mov al,"-"
	call consolePrintChar
    mov ax,00cf0h
    call consolePrintWordHex

    ; Pixel.
    ; PosX.
    xor cx,cx
    ; PosY, Color.
    mov dx,(BIOS_VIDEO_MODE_320_200_4_HEIGHT - 2) + (3 * 256)
    push dx
    call renderPixel320x200x4
    ; PosX.
    mov cx,BIOS_VIDEO_MODE_320_200_4_WIDTH - 1
    ; PosY, Color.
    pop dx
    call renderPixel320x200x4

    ; Line.
    ; LowX.
    xor cx,cx
    ; HighX + 1.
    mov di,BIOS_VIDEO_MODE_320_200_4_WIDTH
    ; PosY, Color.
    mov dx,(BIOS_VIDEO_MODE_320_200_4_HEIGHT - 1) + (2 * 256)
    call renderHorizLine320x200x4

    ; Box.
    ; LowX.
    xor cx,cx
    ; HighX + 1.
    mov di,BIOS_VIDEO_MODE_320_200_4_WIDTH
    ; LowY, Color.
    mov dx,8 + (1 * 256)
    ; HighY + 1.
    mov bl,16
    call renderRect320x200x4

    ret
test4InitRender endp

test4Update proc
    ret
test4Update endp

test4Render proc
    ret
test4Render endp

; -------------;
; Code private ;
; -------------;

code ends

constData segment readonly public
constData ends

data segment public
data ends

end
