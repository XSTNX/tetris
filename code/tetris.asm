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
TETRIS_BOARD_BANK_START_OFFSET      equ ((TETRIS_BOARD_START_POS_Y / 2) * BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE) + ((TETRIS_BOARD_START_POS_X / TETRIS_BLOCK_SIZE) * 2)
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
    ; First row.
    mov ax,0
    mov bx,0
    mov si,0
    call tetrisRenderBlock
    mov ax,05555h
    mov bx,1
    mov si,0
    call tetrisRenderBlock
    mov ax,0aaaah
    mov bx,2
    mov si,0
    call tetrisRenderBlock
    mov ax,0ffffh
    mov bx,3
    mov si,0
    call tetrisRenderBlock
    ; Second row.
    mov ax,05555h
    mov bx,0
    mov si,1
    call tetrisRenderBlock
    mov ax,0aaaah
    mov bx,1
    mov si,1
    call tetrisRenderBlock
    mov ax,0ffffh
    mov bx,2
    mov si,1
    call tetrisRenderBlock
    mov ax,0
    mov bx,3
    mov si,1
    call tetrisRenderBlock
    ; Third row.
    mov ax,0aaaah
    mov bx,0
    mov si,2
    call tetrisRenderBlock
    mov ax,0ffffh
    mov bx,1
    mov si,2
    call tetrisRenderBlock
    mov ax,0
    mov bx,2
    mov si,2
    call tetrisRenderBlock
    mov ax,05555h
    mov bx,3
    mov si,2
    call tetrisRenderBlock
    ret
tetrisRender endp

; -------------;
; Code private ;
; -------------;

; Input: ax (color for the whole block, 16bits that correspond to 8 pixels), bx (unsigned col), si (unsigned row).
; Clobber: bx, si, di.
tetrisRenderBlock proc private
if ASSERT_ENABLED
    cmp bx,TETRIS_BOARD_COLS
    jb short @f
    ASSERT
@@:
    cmp si,TETRIS_BOARD_ROWS
    jb short @f
    ASSERT
@@:
endif
    ; Each row contains four lines per bank.
    shl si,1
    shl si,1
    ; Multiply lines by two to use as an index into a table of words.
    shl si,1
    ; Load the offset into the bank for the start of the line.
    mov si,[RenderMultiplyRowBy80Table + si]
    ; Each col takes a word.
    shl bx,1
    ; Add row and column offsets to obtain the word in memory where the block starts.
    lea si,[TETRIS_BOARD_BANK_START_OFFSET + si + bx]
    mov di,si
repeat 3
    stosw
    add di,TETRIS_RENDER_NEXT_LINE_OFFSET
endm
    stosw

    lea di,[BIOS_VIDEO_MODE_320_200_4_BANK1_OFFSET + si]
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
