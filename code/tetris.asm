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
TETRIS_BOARD_COUNT                  equ TETRIS_BOARD_COLS * TETRIS_BOARD_ROWS
TETRIS_BOARD_START_POS_X            equ BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH - ((TETRIS_BOARD_COLS / 2) * TETRIS_BLOCK_SIZE)
TETRIS_BOARD_START_POS_Y            equ BIOS_VIDEO_MODE_320_200_4_HALF_HEIGHT - ((TETRIS_BOARD_ROWS / 2) * TETRIS_BLOCK_SIZE)
TETRIS_BOARD_BANK_START_OFFSET      equ ((TETRIS_BOARD_START_POS_Y / 2) * BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE) + ((TETRIS_BOARD_START_POS_X / TETRIS_BLOCK_SIZE) * 2)
TETRIS_BOARD_LIMIT_COLOR            equ 1
TETRIS_RENDER_NEXT_LINE_OFFSET      equ (BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE - 2)
TETRIS_PIECE_SPEED_X                equ 64
TETRIS_PIECE_SPEED_Y                equ 16
TETRIS_KEY_LEFT					    equ BIOS_KEYBOARD_SCANCODE_ARROW_LEFT
TETRIS_KEY_RIGHT				    equ BIOS_KEYBOARD_SCANCODE_ARROW_RIGHT
TETRIS_KEY_DOWN				        equ BIOS_KEYBOARD_SCANCODE_ARROW_DOWN

;COLOR_EXTEND_WORD_IMM macro aImm:req
;    mov ax,((aImm and 3) shl 0) or ((aImm and 3) shl 2) or ((aImm and 3) shl 4) or ((aImm and 3) shl 6) or ((aImm and 3) shl 8) or ((aImm and 3) shl 10) or ((aImm and 3) shl 12) or ((aImm and 3) shl 14)
;endm

; Input: ax (unsigned col), bx (unsigned row).
; Output: zf (zero flag set if true).
; Clobber: bx, si.
TETRIS_BOARD_CELL_IS_USED macro
if ASSERT_ENABLED
    cmp ax,TETRIS_BOARD_COLS
    jb short @f
    ASSERT
@@:
    cmp bx,TETRIS_BOARD_ROWS
    jb short @f
    ASSERT
@@:
endif
    ; Could use a table to multiply faster by 10.
    ; static_assert(TETRIS_BOARD_COLS == 10)
    shl bx,1
    mov si,bx
    shl bx,1
    shl bx,1
    add bx,si
    add bx,ax
    cmp byte ptr [TetrisBoardCellUsedArray + bx],1
endm

code segment readonly public

;-------------;
; Code public ;
;-------------;

; Clobber: everything.
tetrisInit proc
    ; Init col and row.
    mov ax,(((TETRIS_BOARD_COLS / 2) - 1) shl 8)
    mov [TetrisFallingPieceCol],ax
    mov [TetrisFallingPiecePrevCol],ah
    xor ax,ax
    mov [TetrisFallingPieceRow],ax
    mov [TetrisFallingPiecePrevRow],ah
    ; Init board.
    ; static_assert((TETRIS_BOARD_COUNT & 1) == 0)
    mov cx,TETRIS_BOARD_COUNT / 2
    mov di,offset TetrisBoardCellUsedArray
    rep stosw
    ret
tetrisInit endp

; Clobber: everything.
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

; Clobber: everything.
tetrisUpdate proc
    mov ax,[TetrisFallingPieceCol]
    mov [TetrisFallingPiecePrevCol],ah
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_LEFT
	jnz short @f
    sub ax,TETRIS_PIECE_SPEED_X
    cmp ax,((TETRIS_BOARD_COLS - 1) shl 8)
	jbe short @f
    xor ax,ax
@@:
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_RIGHT
    jnz short @f
    add ax,TETRIS_PIECE_SPEED_X
    cmp ax,((TETRIS_BOARD_COLS - 1) shl 8)
	jbe short @f
    mov ax,((TETRIS_BOARD_COLS - 1) shl 8)
@@:

    mov bx,[TetrisFallingPieceRow]
    mov [TetrisFallingPiecePrevRow],bh
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_DOWN
	jnz short @f
@@:
    add bx,TETRIS_PIECE_SPEED_Y
    cmp bx,((TETRIS_BOARD_ROWS - 1) shl 8)
	jbe short @f
    mov bx,((TETRIS_BOARD_ROWS - 1) shl 8)
@@:

    mov [TetrisFallingPieceCol],ax
    mov [TetrisFallingPieceRow],bx
    ret
tetrisUpdate endp

; Clobber: everything.
tetrisRender proc
    ; Erase previous position.
    xor al,al
    mov cl,[TetrisFallingPiecePrevCol]
    mov dl,[TetrisFallingPiecePrevRow]
    call tetrisRenderPiece
    ; Draw new position.
    mov al,3
    mov cl,[TetrisFallingPieceColHI]
    mov dl,[TetrisFallingPieceRowHI]
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
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_LEFT
	call consolePrintZeroFlag
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_RIGHT
    call consolePrintZeroFlag
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_DOWN
    call consolePrintZeroFlag
    
    CONSOLE_SET_CURSOR_COL_ROW 0, 1
    mov ax,[TetrisFallingPieceCol]
    call consolePrintWordHex
    mov al,"-"
    call consolePrintChar
    mov ax,[TetrisFallingPieceRow]
    call consolePrintWordHex
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

; Input: al (blockId), cl (unsigned col), dl (unsigned row).
; Clobber: ax, bx, ch, dh, si, di.
tetrisRenderPiece proc private
    xor ch,ch
    mov bx,cx
    xor dh,dh
    mov si,dx
    call tetrisRenderBlock
    ret
tetrisRenderPiece endp

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
    TetrisFallingPiecePrevCol       byte ?
    TetrisFallingPiecePrevRow       byte ?
    ; Align array to a word boundary so the initialization code can run faster on the 80286 and up. But maybe it's better to have separate data segments for bytes and words.
    align word
    TetrisBoardCellUsedArray        byte TETRIS_BOARD_COUNT dup(?)
data ends

end
