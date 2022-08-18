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

COLOR_EXTEND_WORD_IMM macro aImm:req
    mov ax,((aImm and 3) shl 0) or ((aImm and 3) shl 2) or ((aImm and 3) shl 4) or ((aImm and 3) shl 6) or ((aImm and 3) shl 8) or ((aImm and 3) shl 10) or ((aImm and 3) shl 12) or ((aImm and 3) shl 14)
endm

code segment readonly public

; ------------;
; Code public ;
; ------------;

tetrisInit proc
    mov [TetrisFallingPieceCol],4
    xor ax,ax
    mov [TetrisFallingPieceRow],ax
    mov [TetrisFallingPiecePrevRow],ax
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
    ; Test rows.
    mov ax,1
    mov si,TETRIS_BOARD_ROWS - 1
    call tetrisRenderBlockRowTest
    mov ax,2
    mov si,TETRIS_BOARD_ROWS - 2
    call tetrisRenderBlockRowTest
    mov ax,3
    mov si,TETRIS_BOARD_ROWS - 3
    call tetrisRenderBlockRowTest
    mov ax,1
    mov si,TETRIS_BOARD_ROWS - 4
    call tetrisRenderBlockRowTest
    ret
tetrisInitRender endp

tetrisUpdate proc
	KEYBOARD_IS_KEY_PRESSED BIOS_KEYBOARD_SCANCODE_E
	jnz short skipKeyLeftPressed
    ; Reset piece and return.
    mov [TetrisFallingPieceCol],4
    mov [TetrisFallingPieceRow],0
    ret
skipKeyLeftPressed:

    ; Update piece row.
    mov ax,[TetrisFallingPieceRow]
    mov [TetrisFallingPiecePrevRow],ax
    add ax,16
    cmp ax,(14 shl 8)
    jbe short skipSnap
    mov ax,(14 shl 8)
skipSnap:
    mov [TetrisFallingPieceRow],ax
    ret
tetrisUpdate endp

tetrisRender proc
    ; Erase previous position.
    xor ax,ax
    mov cl,8
    mov dx,[TetrisFallingPiecePrevRow]
    shr dx,cl
    mov cx,[TetrisFallingPieceCol]
    call tetrisRenderPiece

    ; Draw new position.
    COLOR_EXTEND_WORD_IMM(2)
    mov cl,8
    mov dx,[TetrisFallingPieceRow]
    shr dx,cl
    mov cx,[TetrisFallingPieceCol]
    call tetrisRenderPiece

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

    ; Render the four even lines.
    mov di,si
repeat 3
    stosw
    add di,TETRIS_RENDER_NEXT_LINE_OFFSET
endm
    stosw
    ; Render the four odd lines.
    lea di,[BIOS_VIDEO_MODE_320_200_4_BANK1_OFFSET + si]
repeat 3
    stosw
    add di,TETRIS_RENDER_NEXT_LINE_OFFSET
endm
    stosw

    ret
tetrisRenderBlock endp

; Input: ax (color for each block of the piece, 16bits that correspond to 8 pixels), cx (unsigned col), dx (unsigned row).
; Clobber: bx, si, di.
tetrisRenderPiece proc
    ; May need to validate col,row.
    mov bx,cx
    mov si,dx
    call tetrisRenderBlock
    mov bx,cx
    mov si,dx
    dec bx
    inc si
    call tetrisRenderBlock
    mov bx,cx
    mov si,dx
    inc si
    call tetrisRenderBlock
    mov bx,cx
    mov si,dx
    inc bx
    inc si
    call tetrisRenderBlock
    ret
tetrisRenderPiece endp

; Input: ax (color for the whole block, 16bits that correspond to 8 pixels), si (unsigned row).
; Clobber: nothing.
tetrisRenderBlockRowTest proc private
    push ax
    mov di,ax
    and di,3
    shl di,1
    xor bx,bx
colLoop:
    push bx
    push si
    push di
    mov ax,[TetrisBlockColorWord + di]
    call tetrisRenderBlock
    pop di
    pop si
    pop bx
    inc di
    inc di
    cmp di,8
    jb short skipResetColor
    mov di,2
skipResetColor:
    inc bx
    cmp bx,TETRIS_BOARD_COLS
    jb short colLoop
    pop ax
    ret
tetrisRenderBlockRowTest endp

code ends

constData segment readonly public
    TetrisBlockColorWord        word 0,5555h,0aaaah,0ffffh
constData ends

data segment public
    TetrisFallingPieceCol           word ?
    TetrisFallingPieceRow           word ?
    TetrisFallingPiecePrevRow       word ?
data ends

end
