TEST4_NO_EXTERNS equ 1
include code\test4.inc
include code\assumSeg.inc
include code\render.inc

code segment readonly public

; ------------;
; Code public ;
; ------------;

test4Init proc
    ret
test4Init endp

test4InitRender proc
    ret
test4InitRender endp

test4Update proc
    ret
test4Update endp

test4Render proc
    ; LowX.
    mov cx,0
    ; HighX + 1.
    mov bx,320
    ; PosY.
    mov dl,199
    ; Color.
    mov dh,2
    call renderHorizLine320x200x4
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
