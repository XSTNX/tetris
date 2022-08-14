TETRIS_NO_EXTERNS equ 1
include code\tetris.inc
include code\assert.inc
include code\assumSeg.inc
include code\console.inc
include code\keyboard.inc
include code\render.inc
include code\timer.inc

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
