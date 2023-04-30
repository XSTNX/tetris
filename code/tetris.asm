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
TETRIS_PIECE_HORIZ_SPEED            equ 64

COLOR_EXTEND_WORD_IMM macro aImm:req
    mov ax,((aImm and 3) shl 0) or ((aImm and 3) shl 2) or ((aImm and 3) shl 4) or ((aImm and 3) shl 6) or ((aImm and 3) shl 8) or ((aImm and 3) shl 10) or ((aImm and 3) shl 12) or ((aImm and 3) shl 14)
endm

code segment readonly public

;-------------;
; Code public ;
;-------------;

tetrisInit proc
    mov ax,400h
    mov [TetrisFallingPieceCol],ax
    mov [TetrisFallingPiecePrevCol],ax
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
    mov al,1
    mov si,TETRIS_BOARD_ROWS - 1
    call tetrisRenderBlockRowTest
    mov al,2
    mov si,TETRIS_BOARD_ROWS - 2
    call tetrisRenderBlockRowTest
    mov al,3
    mov si,TETRIS_BOARD_ROWS - 3
    call tetrisRenderBlockRowTest
    mov al,1
    mov si,TETRIS_BOARD_ROWS - 4
    call tetrisRenderBlockRowTest
    ret
tetrisInitRender endp

tetrisUpdate proc
    ; Horizontal movement.
    mov ax,[TetrisFallingPieceCol]
    mov [TetrisFallingPiecePrevCol],ax
	KEYBOARD_IS_KEY_PRESSED BIOS_KEYBOARD_SCANCODE_ARROW_LEFT
	jnz short @f    
    sub ax,TETRIS_PIECE_HORIZ_SPEED
    cmp ax,(1 shl 8)
	jae short @f
    mov ax,(1 shl 8)
@@:
	KEYBOARD_IS_KEY_PRESSED BIOS_KEYBOARD_SCANCODE_ARROW_RIGHT
    jnz short @f    
    add ax,TETRIS_PIECE_HORIZ_SPEED
    cmp ax,((TETRIS_BOARD_COLS - 2) shl 8)
	jbe short @f
    mov ax,((TETRIS_BOARD_COLS - 2) shl 8)
@@:
    mov [TetrisFallingPieceCol],ax

    ; Vertical movement.
    mov ax,[TetrisFallingPieceRow]
    mov [TetrisFallingPiecePrevRow],ax
	KEYBOARD_IS_KEY_PRESSED BIOS_KEYBOARD_SCANCODE_ARROW_DOWN
	jnz short @f
    ; Reset piece and return.
    mov [TetrisFallingPieceCol],400h
    mov [TetrisFallingPieceRow],0
    ret
@@:
    ; Update piece row.
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
    xor al,al
    mov cl,8
    mov dx,[TetrisFallingPiecePrevRow]
    shr dx,cl
    mov cx,[TetrisFallingPiecePrevCol]
    mov cl,ch
    xor ch,ch
    call tetrisRenderPiece

    ; Draw new position.
    mov al,3
    mov cl,8
    mov dx,[TetrisFallingPieceRow]
    shr dx,cl
    mov cx,[TetrisFallingPieceCol]
    mov cl,ch
    xor ch,ch
    call tetrisRenderPiece

if CONSOLE_ENABLED
    call tetrisRenderDebug
endif
    ret
tetrisRender endp

;--------------;
; Code private ;
;--------------;

if CONSOLE_ENABLED
tetrisRenderDebug proc private
    CONSOLE_SET_CURSOR_COL_ROW 0, 0
    mov al,[TetrisFallingPieceColHI]
    call consolePrintByte
    mov al,"-"
    call consolePrintChar
    mov al,[TetrisFallingPieceRowHI]
    call consolePrintByte
    ret
tetrisRenderDebug endp
endif

; Input: al (blockId), bx (unsigned col), si (unsigned row).
; Clobber: ax, bx, si, di.
tetrisRenderBlock proc private
if ASSERT_ENABLED
    cmp al,4
    jb short @f
    ASSERT
@@:
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

    mov bx,ax
    xor bh,bh
    shl bx,1
    shl bx,1
    ; Render the four even lines.
    mov ax,[TetrisBlockColor + bx]
    mov di,si
    stosw
    add di,TETRIS_RENDER_NEXT_LINE_OFFSET
    mov ax,[TetrisBlockColor + 2 + bx]
repeat 2
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
    mov ax,[TetrisBlockColor + bx]
    stosw

    ret
tetrisRenderBlock endp

; Input: al (blockId), cx (unsigned col), dx (unsigned row).
; Clobber: bx, si, di.
tetrisRenderPiece proc private
    ; May need to validate col,row.
    mov bp,ax
    mov bx,cx
    mov si,dx
    call tetrisRenderBlock
    mov ax,bp
    mov bx,cx
    mov si,dx
    dec bx
    inc si
    call tetrisRenderBlock
    mov ax,bp
    mov bx,cx
    mov si,dx
    inc si
    mov ax,bp
    call tetrisRenderBlock
    mov bx,cx
    mov si,dx
    inc bx
    inc si
    mov ax,bp
    call tetrisRenderBlock
    ret
tetrisRenderPiece endp

; Input: al (blockId), si (unsigned row).
; Clobber: nothing.
tetrisRenderBlockRowTest proc private
    push ax
    and al,3
    mov cx,TETRIS_BOARD_COLS
colLoop:
    mov bx,cx
    dec bx
    push ax
    push si
    call tetrisRenderBlock
    pop si
    pop ax
    dec al
    jnz short skipResetColor
    mov al,3
skipResetColor:
    loop colLoop
    pop ax
    ret
tetrisRenderBlockRowTest endp

code ends

constData segment readonly public
                                        ;    Limit, Center
    TetrisBlockColor                word    00000h, 00000h,
                                            05555h, 0fd7fh,
                                            0aaaah, 05695h,
                                            0ffffh, 0abeah
constData ends

data segment public
    TetrisFallingPieceCol           label word
    TetrisFallingPieceColLO         byte ?
    TetrisFallingPieceColHI         byte ?
    TetrisFallingPieceRow           label word
    TetrisFallingPieceRowLO         byte ?
    TetrisFallingPieceRowHI         byte ?
    TetrisFallingPiecePrevCol       word ?
    TetrisFallingPiecePrevRow       word ?
data ends

end
