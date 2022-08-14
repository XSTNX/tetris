TETRIS_NO_EXTERNS equ 1
include code\tetris.inc
include code\assert.inc
include code\assumSeg.inc
include code\console.inc
include code\keyboard.inc
include code\render.inc
include code\timer.inc

NEXT_LINE_OFFSET        equ (BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE - 2)

code segment readonly public

; ------------;
; Code public ;
; ------------;

tetrisInit proc
    ret
tetrisInit endp

tetrisInitRender proc
    ret
tetrisInitRender endp

tetrisUpdate proc
    ret
tetrisUpdate endp

tetrisRender proc
    mov ax,0ffffh
    xor di,di
repeat 3
    stosw
    add di,NEXT_LINE_OFFSET
endm
    stosw

    mov di,BIOS_VIDEO_MODE_320_200_4_BANK1_OFFSET
repeat 3
    stosw
    add di,NEXT_LINE_OFFSET
endm
    stosw

    ret
tetrisRender endp

; -------------;
; Code private ;
; -------------;

code ends

constData segment readonly public
constData ends

data segment public
data ends

end
