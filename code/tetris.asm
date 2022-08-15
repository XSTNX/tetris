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
TETRIS_BOARD_LIMIT_COLOR            equ 1
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
    mov dx,(TETRIS_BOARD_START_POS_Y - 1) or (TETRIS_BOARD_LIMIT_COLOR shl 8)
    call renderHorizLine320x200x4
    ; Bottom limit.
    pop di
    pop cx
    mov dx,(TETRIS_BOARD_START_POS_Y + (TETRIS_BOARD_ROWS * TETRIS_BLOCK_SIZE)) or (TETRIS_BOARD_LIMIT_COLOR shl 8)
    call renderHorizLine320x200x4
    ; Left limit.
    mov cx,TETRIS_BOARD_START_POS_X - 1
    mov dx,TETRIS_BOARD_START_POS_Y or (TETRIS_BOARD_LIMIT_COLOR shl 8)
    push dx
    mov bl,(TETRIS_BOARD_START_POS_Y + (TETRIS_BOARD_ROWS * TETRIS_BLOCK_SIZE))
    push bx
    call renderVertLine320x200x4
    ; Right limit.
    mov cx,TETRIS_BOARD_START_POS_X + (TETRIS_BOARD_COLS * TETRIS_BLOCK_SIZE)
    pop bx
    pop dx
    call renderVertLine320x200x4
    ret
tetrisInitRender endp

tetrisUpdate proc
    ret
tetrisUpdate endp

tetrisRender proc
    xor ax,ax
    mov cx,0
    mov dx,0
    call tetrisRenderBlock
    mov ax,05555h
    mov cx,1
    mov dx,0
    call tetrisRenderBlock
    mov ax,0aaaah
    mov cx,2
    mov dx,0
    call tetrisRenderBlock
    mov ax,0ffffh
    mov cx,3
    mov dx,0
    call tetrisRenderBlock
    ret
tetrisRender endp

; -------------;
; Code private ;
; -------------;

; Input: ax (color for the whole block, 16bits that correspond to 8 pixels), cx (unsigned col), dx (unsigned row).
; Clobber: bx,di.
tetrisRenderBlock proc private
if ASSERT_ENABLED
    cmp cx,TETRIS_BOARD_COLS
    jb @f
    ASSERT
@@:
    cmp dx,TETRIS_BOARD_ROWS
    jb @f
    ASSERT
@@:
endif
    mov bx,cx
    shl bx,1
    mov di,bx
    ;mov di,[RenderMultiplyRowBy80Table + bx]
repeat 3
    stosw
    add di,TETRIS_RENDER_NEXT_LINE_OFFSET
endm
    stosw

    mov di,BIOS_VIDEO_MODE_320_200_4_BANK1_OFFSET
    add di,bx
    ;add di,[RenderMultiplyRowBy80Table + bx]
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
