include code\assumSeg.inc
include code\game.inc
include code\render.inc

TEST2_PIXELS_PER_FRAME      equ 1024

; Input:
;	cx (unsigned posX).
;	dl (unsigned posY).
TEST2_ASSERT_POS macro
local error, skipError
ifdef ASSERT
    cmp cx,320
    jae short error
    cmp dl,200
    jb short skipError
error:
    GAME_QUIT_WITH_ERROR_ARG ERROR_CODE_ASSERT
skipError:
endif
endm

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
    mov ax,TEST2_PIXELS_PER_FRAME
    mov cx,[Test2PosX]
    mov dx,[Test2PosYColor]

nextPixel:
    TEST2_ASSERT_POS
    push ax
    push cx
    push dx
    call renderPixel320x200x4
    pop dx
    pop cx
    pop ax
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
    dec ax
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
