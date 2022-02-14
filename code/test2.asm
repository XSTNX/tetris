include code\assumSeg.inc
include code\render.inc

code segment readonly public

; ------------;
; Code public ;
; ------------;

test2Init proc
    ;int 3
    mov al,[testData]
    ret
test2Init endp

test2InitRender proc
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
test2InitRender endp

test2Update proc
    ret
test2Update endp

test2Render proc
    xor cx,cx
    xor dx,dx
@@:
    push cx
    push dx
    call renderPixel320x200x4
    pop dx
    pop cx
    inc cx
    inc dh
    cmp dh,4
    jne @b
    ret
test2Render endp

; -------------;
; Code private ;
; -------------;

code ends

    ; It's supposed to prevent from using instructions in data segments, but doesn't seem to work, maybe I'm doing it wrong?
    assume cs:error
constData segment readonly public
constData ends

data segment public
testData label byte
    mov ax,1
data ends

end
