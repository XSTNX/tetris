TEST3_NO_EXTERNS equ 1
include code\test3.inc
include code\assert.inc
include code\assumSeg.inc
include code\console.inc
include code\keyboard.inc
include code\render.inc

code segment readonly public

; ------------;
; Code public ;
; ------------;

test3Init proc
    ret
test3Init endp

test3InitRender proc
    ; ax (line count).
    ; cx (unsigned lowX).
    ; di (unsigned highX + 1).
    ; dl (unsigned posY).
    ; dh (2bit color).
    mov ax,BIOS_VIDEO_MODE_320_200_4_HEIGHT
    mov di,BIOS_VIDEO_MODE_320_200_4_WIDTH
    xor dx,dx   
@@:
    push ax
    xor cx,cx
    push dx
    call renderHorizLine320x200x4
    ; Increment posY and color.
    pop dx
    add dx,101h
    and dh,11b
    pop ax
    dec ax
    jne short @b
    ; Text.
	mov si,offset allSegments:tmpText
	call consolePrintString
    ret
tmpText:
	db "Es la guitarra de Lolo!", 0
test3InitRender endp

test3Update proc
    ret
test3Update endp

test3Render proc
	mov al,"X"
	call consolePrintChar
    ret
test3Render endp

; -------------;
; Code private ;
; -------------;

code ends

constData segment readonly public
constData ends

data segment public
data ends

end
