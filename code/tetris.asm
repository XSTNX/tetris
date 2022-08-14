TETRIS_NO_EXTERNS equ 1
include code\tetris.inc
include code\assert.inc
include code\assumSeg.inc
include code\console.inc
include code\keyboard.inc
include code\render.inc
include code\timer.inc

TETRIS_BLOCK_SIZE                   equ 8
TETRIS_BOARD_COLS                   equ 10
TETRIS_BOARD_ROWS                   equ 20
TETRIS_BOARD_START_POS_X            equ BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH - ((TETRIS_BOARD_COLS / 2) * TETRIS_BLOCK_SIZE)
TETRIS_BOARD_START_POS_Y            equ BIOS_VIDEO_MODE_320_200_4_HALF_HEIGHT - ((TETRIS_BOARD_ROWS / 2) * TETRIS_BLOCK_SIZE)
TETRIS_RENDER_NEXT_LINE_OFFSET      equ (BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE - 2)

code segment readonly public

; ------------;
; Code public ;
; ------------;

tetrisInit proc
    ret
tetrisInit endp

tetrisInitRender proc
    ; Top limit.
    mov cx,TETRIS_BOARD_START_POS_X
    push cx
    mov di,TETRIS_BOARD_START_POS_X + (TETRIS_BOARD_COLS * TETRIS_BLOCK_SIZE)
    push di
    mov dl,TETRIS_BOARD_START_POS_Y - 1
    call renderHorizLine320x200x4
    ; Bottom limit.
    pop di
    pop cx
    mov dl,TETRIS_BOARD_START_POS_Y + (TETRIS_BOARD_ROWS * TETRIS_BLOCK_SIZE)
    call renderHorizLine320x200x4
    ; Left limit.
    ; Right limit.
    ret
tetrisInitRender endp

tetrisUpdate proc
    ret
tetrisUpdate endp

tetrisRender proc
    mov ax,0aaaah
    xor dx,dx
    call tetrisRenderBlock
    ret
tetrisRender endp

; -------------;
; Code private ;
; -------------;

; Input: ax (color for the whole block, 8 pixels corresponding to 16bits), dl (unsigned col), dh (unsigned row).
; Clobber: di.
tetrisRenderBlock proc private
if ASSERT_ENABLED
    cmp dl,TETRIS_BOARD_COLS
    jb @f
    ASSERT
@@:
    cmp dh,TETRIS_BOARD_ROWS
    jb @f
    ASSERT
@@:
endif

    xor di,di
repeat 3
    stosw
    add di,TETRIS_RENDER_NEXT_LINE_OFFSET
endm
    stosw

    mov di,BIOS_VIDEO_MODE_320_200_4_BANK1_OFFSET
repeat 3
    stosw
    add di,TETRIS_RENDER_NEXT_LINE_OFFSET
endm
    stosw

    ret
tetrisRenderBlock endp

code ends

constData segment readonly public
constData ends

data segment public
data ends

end
