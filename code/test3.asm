TEST3_NO_EXTERNS equ 1
include code\test3.inc
include code\assumSeg.inc
include code\console.inc
include code\render.inc

code segment readonly public

; ------------;
; Code public ;
; ------------;

test3Init proc
    ret
test3Init endp

test3InitRender proc
    ; ax (line count)
    ; cx (unsigned left limit).
    ; bx (unsigned right limit + 1).
    ; dl (unsigned posY).
    ; dh (color).
    mov ax,200
    xor cx,cx
    mov bx,320
    xor dx,dx
lineLoop:
    push ax
    push bx
    push cx
    call renderHorizLine320x200x4
    ; Increment posY and color.
    add dx,101h
    and dh,11b
    pop cx
    pop bx
    pop ax
    dec ax
    jne short lineLoop
    ; Text.
    mov dx,offset allSegments:tmpText
    call consolePrintString
    ret
tmpText:
	db "Es la guitarra de Lolo!", 0
test3InitRender endp

test3Update proc
    ret
test3Update endp

test3Render proc
    CONSOLE_PRINT_CHAR 'X'
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
