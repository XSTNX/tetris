TEST2_NO_EXTERNS equ 1
include code\test2.inc
include code\assert.inc
include code\assumSeg.inc
include code\console.inc
include code\keyboard.inc
include code\render.inc

TEST2_PIXELS_PER_FRAME      equ 1024

code segment readonly public

; ------------;
; Code public ;
; ------------;

test2Init proc
    ;mov al,[testData]

    mov [Test2PosX],0
    mov [Test2PosYColor],100h

    ret
test2Init endp

test2InitRender proc
    ret
test2InitRender endp

test2Update proc
    ret
test2Update endp

test2Render proc
    mov cx,[Test2PosX]
    mov dx,[Test2PosYColor]
    mov di,TEST2_PIXELS_PER_FRAME    

nextPixel:
    push cx
    push dx
    call renderPixel320x200x4
    pop dx
    pop cx
    ; Increment posX.
    inc cx
    cmp cx,320
    jne short skipUpdate
    ; Reset posX.
    xor cx,cx
    ; Increment posY.
    inc dl
    cmp dl,200
    jne short skipUpdate
    ; Reset posY.
    xor dl,dl
    ; Increment color keeping it in range.
    inc dh
    and dh,11b
skipUpdate:
    dec di
    jnz nextPixel

    ; Save updated values.
    mov [Test2PosX],cx
    mov [Test2PosYColor],dx

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
    Test2PosX       word ?
    Test2PosYColor  label word
    Test2PosY       byte ?
    Test2Color      byte ?
;testData label byte
;    mov ax,1
data ends

end
