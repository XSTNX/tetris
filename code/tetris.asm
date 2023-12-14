include code\tetris.inc
include code\assert.inc
include code\assumSeg.inc
include code\console.inc
include code\keyboard.inc
include code\render.inc
include code\timer.inc

TETRIS_BOARD_COLS                   equ 10
TETRIS_BOARD_ROWS                   equ 21
TETRIS_BOARD_VISIBLE_ROWS           equ TETRIS_BOARD_ROWS - 1
TETRIS_BOARD_COUNT                  equ TETRIS_BOARD_COLS * TETRIS_BOARD_ROWS
TETRIS_BLOCK_SIZE                   equ 8
TETRIS_BLOCK_START_COL              equ ((TETRIS_BOARD_COLS / 2) - 1)
TETRIS_BOARD_CELL_USED              equ 1
TETRIS_BOARD_START_POS_X            equ BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH - ((TETRIS_BOARD_COLS / 2) * TETRIS_BLOCK_SIZE)
TETRIS_BOARD_START_POS_Y            equ BIOS_VIDEO_MODE_320_200_4_HALF_HEIGHT - ((TETRIS_BOARD_VISIBLE_ROWS / 2) * TETRIS_BLOCK_SIZE)
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

code segment readonly public

;-------------;
; Code public ;
;-------------;

; Clobber: everything.
tetrisInit proc
    ; Init col and row.
    mov ax,(TETRIS_BLOCK_START_COL shl 8)
    mov [TetrisFallingPieceCol],ax
    mov [TetrisFallingPiecePrevColHI],ah
    xor ax,ax
    mov [TetrisFallingPieceRow],ax
    mov [TetrisFallingPiecePrevRowHI],ah
    ; Init board.
    ; static_assert((TETRIS_BOARD_COLS & 1) == 0)
    mov cx,(TETRIS_BOARD_COLS * TETRIS_BOARD_VISIBLE_ROWS) / 2
    mov di,offset TetrisBoardCellUsedArray
    rep stosw
    mov ax,TETRIS_BOARD_CELL_USED or (TETRIS_BOARD_CELL_USED shl 8)
    mov cx,(TETRIS_BOARD_COLS * (TETRIS_BOARD_ROWS - TETRIS_BOARD_VISIBLE_ROWS)) / 2
    rep stosw
    ; Add random blocks.
    mov bx,TETRIS_BLOCK_START_COL
    mov si,5
    call tetrisBoardSetCellUsed
    mov bx,1
    mov si,9
    call tetrisBoardSetCellUsed
    mov bx,1
    mov si,10
    call tetrisBoardSetCellUsed
    mov bx,1
    mov si,11
    call tetrisBoardSetCellUsed
    mov bx,1
    mov si,12
    call tetrisBoardSetCellUsed
    mov bx,5
    mov si,16
    call tetrisBoardSetCellUsed
    mov bx,6
    mov si,16
    call tetrisBoardSetCellUsed
    mov bx,7
    mov si,16
    call tetrisBoardSetCellUsed
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
    mov dx,(TETRIS_BOARD_START_POS_Y + (TETRIS_BOARD_VISIBLE_ROWS * TETRIS_BLOCK_SIZE)) or (TETRIS_BOARD_LIMIT_COLOR shl 8)
    call renderHorizLine320x200x4
    ; Left limit.
    mov cx,TETRIS_BOARD_START_POS_X - 1
    mov dx,TETRIS_BOARD_START_POS_Y or (TETRIS_BOARD_LIMIT_COLOR shl 8)
    push dx
    mov bl,(TETRIS_BOARD_START_POS_Y + (TETRIS_BOARD_VISIBLE_ROWS * TETRIS_BLOCK_SIZE))
    push bx
    call renderVertLine320x200x4
    ; Right limit.
    mov cx,TETRIS_BOARD_START_POS_X + (TETRIS_BOARD_COLS * TETRIS_BLOCK_SIZE)
    pop bx
    pop dx
    call renderVertLine320x200x4
    ; Render random blocks.
    mov al,1
    mov bx,TETRIS_BLOCK_START_COL
    mov si,5
    call tetrisRenderBlock
    mov al,2
    mov bx,1
    mov si,9
    call tetrisRenderBlock
    mov al,1
    mov bx,1
    mov si,10
    call tetrisRenderBlock
    mov al,2
    mov bx,1
    mov si,11
    call tetrisRenderBlock
    mov al,1
    mov bx,1
    mov si,12
    call tetrisRenderBlock
    mov al,1
    mov bx,5
    mov si,16
    call tetrisRenderBlock
    mov al,2
    mov bx,6
    mov si,16
    call tetrisRenderBlock
    mov al,1
    mov bx,7
    mov si,16
    call tetrisRenderBlock
    ret
tetrisInitRender endp

; Clobber: everything.
tetrisUpdate proc
    mov bx,[TetrisFallingPieceCol]
    mov [TetrisFallingPiecePrevColHI],bh
    mov ax,[TetrisFallingPieceRow]
    mov [TetrisFallingPiecePrevRowHI],ah

    ; Horizontal movement.
    ; static_assert(TETRIS_PIECE_SPEED_X <= 0x100)
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_LEFT
	jnz short @f
    sub bx,TETRIS_PIECE_SPEED_X
    cmp bx,((TETRIS_BOARD_COLS - 1) shl 8)
	jbe short @f
    xor bx,bx
    jmp leftDone
@@:
    call tetrisBoardGetCellIsUsed
	jnz short leftDone
    inc bh
    xor bl,bl
leftDone:

	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_RIGHT
    jnz short @f
    add bx,TETRIS_PIECE_SPEED_X
    cmp bx,((TETRIS_BOARD_COLS - 1) shl 8)
	jbe short @f
    mov bx,((TETRIS_BOARD_COLS - 1) shl 8)
    jmp rightDone
@@:
    call tetrisBoardGetCellIsUsed
	jnz short rightDone
    dec bh
    xor bl,bl
rightDone:

    ; Vertical movement.
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_DOWN
	jnz short @f
@@:
    ; static_assert(TETRIS_PIECE_SPEED_Y <= 0x100)
    add ax,TETRIS_PIECE_SPEED_Y
    call tetrisBoardGetCellIsUsed
	jnz short @f
    dec ah
    xor al,al
@@:

    mov [TetrisFallingPieceCol],bx
    mov [TetrisFallingPieceRow],ax
    ret
tetrisUpdate endp

; Clobber: everything.
tetrisRender proc
    ; Erase previous position.
    xor al,al
    mov cl,[TetrisFallingPiecePrevColHI]
    mov dl,[TetrisFallingPiecePrevRowHI]
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

; Input: bx (unsigned col), si (unsigned row).
; Output: bx (addr).
; Clobber: si, bp.
tetrisBoardGetCellAddr proc private
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
    ; Could use a table to multiply faster by 10.
    ; static_assert(TETRIS_BOARD_COLS == 10)
    ; si = 10 * row = 2 * row + 8 * row.
    shl si,1
    mov bp,si
    shl si,1
    shl si,1
    lea si,[bp + si]
    lea bx,[TetrisBoardCellUsedArray + bx + si]
    ret
tetrisBoardGetCellAddr endp

; Input: bh (unsigned col), ah (unsigned row).
; Output: zf (set if true).
; Clobber: si, bp.
tetrisBoardGetCellIsUsed proc private
    push ax
    push bx
    mov bl,bh
    xor bh,bh
    mov al,ah
    xor ah,ah
    mov si,ax
    call tetrisBoardGetCellAddr
    cmp byte ptr [bx],TETRIS_BOARD_CELL_USED
    pop bx
    pop ax
    ret
tetrisBoardGetCellIsUsed endp

; Input: bx (unsigned col), si (unsigned row).
; Clobber: bx, si, bp.
tetrisBoardSetCellUsed proc private
    call tetrisBoardGetCellAddr
    mov byte ptr [bx],TETRIS_BOARD_CELL_USED
    ret
tetrisBoardSetCellUsed endp

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
    cmp si,TETRIS_BOARD_VISIBLE_ROWS
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
    TetrisFallingPiecePrevColHI     byte ?
    TetrisFallingPiecePrevRowHI     byte ?
    ; Align array to a word boundary so the initialization code can run faster on the 80286 and up. But maybe it's better to have separate data segments for bytes and words.
    align word
    TetrisBoardCellUsedArray        byte TETRIS_BOARD_COUNT dup(?)
data ends

end
