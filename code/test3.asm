include code\assumSeg.inc
include code\game.inc
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
    mov ax,3
    xor cx,cx
    mov bx,319
    mov dx,99 + (1 * 256);
lineLoop:
    push ax
    push bx
    push cx
    call renderHorizLine320x200x4
    ; Increment posY and color.
    add dx,101h
    pop cx
    pop bx
    pop ax
    dec ax
    jne short lineLoop
    ret
test3InitRender endp

test3Update proc
    ret
test3Update endp

test3Render proc
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
