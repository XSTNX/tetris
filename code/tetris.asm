include code\tetris.inc
include code\assert.inc
include code\assumSeg.inc
include code\console.inc
include code\keyboard.inc
include code\render.inc
include code\timer.inc

TETRIS_BOARD_RANDOM_BLOCKS          equ 1
TETRIS_BOARD_COLS                   equ 12
TETRIS_BOARD_ROWS                   equ 21
TETRIS_BOARD_VISIBLE_COLS           equ TETRIS_BOARD_COLS - 2
TETRIS_BOARD_VISIBLE_ROWS           equ TETRIS_BOARD_ROWS - 1
TETRIS_BOARD_COUNT                  equ TETRIS_BOARD_COLS * TETRIS_BOARD_ROWS
TETRIS_BLOCK_SIZE                   equ 8
TETRIS_BLOCK_START_COL              equ ((TETRIS_BOARD_COLS / 2) - 1)
TETRIS_BOARD_CELL_UNUSED            equ 0
TETRIS_BOARD_CELL_USED              equ 1
TETRIS_BOARD_START_POS_X            equ BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH - ((TETRIS_BOARD_VISIBLE_COLS / 2) * TETRIS_BLOCK_SIZE)
TETRIS_BOARD_START_POS_Y            equ BIOS_VIDEO_MODE_320_200_4_HALF_HEIGHT - ((TETRIS_BOARD_VISIBLE_ROWS / 2) * TETRIS_BLOCK_SIZE)
TETRIS_BOARD_BANK_START_OFFSET      equ ((TETRIS_BOARD_START_POS_Y / 2) * BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE) + (((TETRIS_BOARD_START_POS_X - TETRIS_BLOCK_SIZE) / TETRIS_BLOCK_SIZE) * 2)
TETRIS_BOARD_BORDER_COLOR           equ 1
TETRIS_RENDER_NEXT_LINE_OFFSET      equ (BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE - 2)
TETRIS_FALLING_PIECE_SPEED_X        equ 64
TETRIS_FALLING_PIECE_SPEED_Y        equ 16
TETRIS_FALLING_PIECE_COLOR_MASK     equ 11b
TETRIS_FALLING_PIECE_COLOR_CLEAR    equ TETRIS_FALLING_PIECE_COLOR_MASK + 1
TETRIS_FALLING_PIECE_COLOR_COUNT    equ TETRIS_FALLING_PIECE_COLOR_CLEAR + 1
TETRIS_KEY_LEFT					    equ BIOS_KEYBOARD_SCANCODE_ARROW_LEFT
TETRIS_KEY_RIGHT				    equ BIOS_KEYBOARD_SCANCODE_ARROW_RIGHT
TETRIS_KEY_DOWN				        equ BIOS_KEYBOARD_SCANCODE_ARROW_DOWN
TETRIS_LEVEL_STATE_PLAY             equ 0
TETRIS_LEVEL_STATE_ANIM             equ 1
TETRIS_LEVEL_STATE_OVER             equ 2
TETRIS_LEVEL_STATE_ANIM_FRAMES_LEFT equ 25

if TETRIS_BOARD_RANDOM_BLOCKS
TetrisBoardRandomBlock struct
    Col     byte ?
    Row     byte ?
    Color   byte ?
TetrisBoardRandomBlock ends
endif

code segment readonly public

;-------------;
; Code public ;
;-------------;

; Clobber: everything.
tetrisInit proc
    mov [TetrisLevelState],TETRIS_LEVEL_STATE_PLAY
    mov [TetrisLevelNextStateSet],0
    mov [TetrisFallingPieceColor],TETRIS_FALLING_PIECE_COLOR_MASK
    call tetrisBoardInitFallingPiece
    ; Init board.
    ; static_assert(TETRIS_BOARD_COLS == 12)
    mov cx,TETRIS_BOARD_VISIBLE_ROWS
    mov di,offset TetrisBoardCellUsedArray
@@:
    mov ax,TETRIS_BOARD_CELL_USED or (TETRIS_BOARD_CELL_UNUSED shl 8)
    stosw
    dec ax
if ASSERT_ENABLED
    cmp ax,0
    je short skip
    ASSERT
skip:
endif
    stosw
    stosw
    stosw
    stosw
    mov ax,TETRIS_BOARD_CELL_UNUSED or (TETRIS_BOARD_CELL_USED shl 8)
    stosw
    loop short @b
    ; static_assert(TETRIS_BOARD_ROWS - TETRIS_BOARD_VISIBLE_ROWS == 1)
    mov ax,TETRIS_BOARD_CELL_USED or (TETRIS_BOARD_CELL_USED shl 8)
    mov cx,TETRIS_BOARD_COLS / 2
    rep stosw
if TETRIS_BOARD_RANDOM_BLOCKS
    mov di,offset TetrisRandomBlocks
@@:
    mov ch,[di+TetrisBoardRandomBlock.Col]
    cmp ch,0
    je short @f
    mov dh,[di+TetrisBoardRandomBlock.Row]
    call tetrisBoardSetCellUsed
    add di,sizeof TetrisBoardRandomBlock
    jmp short @b
@@:
endif
    ret
tetrisInit endp

; Clobber: everything.
tetrisInitRender proc
    ; Top border.
    mov cx,TETRIS_BOARD_START_POS_X
    push cx
    mov di,TETRIS_BOARD_START_POS_X + (TETRIS_BOARD_VISIBLE_COLS * TETRIS_BLOCK_SIZE)
    push di
    mov dx,(TETRIS_BOARD_START_POS_Y - 1) or (TETRIS_BOARD_BORDER_COLOR shl 8)
    call renderHorizLine320x200x4
    ; Bottom border.
    pop di
    pop cx
    mov dx,(TETRIS_BOARD_START_POS_Y + (TETRIS_BOARD_VISIBLE_ROWS * TETRIS_BLOCK_SIZE)) or (TETRIS_BOARD_BORDER_COLOR shl 8)
    call renderHorizLine320x200x4
    ; Left border.
    mov cx,TETRIS_BOARD_START_POS_X - 1
    mov dx,TETRIS_BOARD_START_POS_Y or (TETRIS_BOARD_BORDER_COLOR shl 8)
    push dx
    mov bl,(TETRIS_BOARD_START_POS_Y + (TETRIS_BOARD_VISIBLE_ROWS * TETRIS_BLOCK_SIZE))
    push bx
    call renderVertLine320x200x4
    ; Right border.
    mov cx,TETRIS_BOARD_START_POS_X + (TETRIS_BOARD_VISIBLE_COLS * TETRIS_BLOCK_SIZE)
    pop bx
    pop dx
    call renderVertLine320x200x4
if TETRIS_BOARD_RANDOM_BLOCKS
    mov di,offset TetrisRandomBlocks
@@:
    mov bl,[di+TetrisBoardRandomBlock.Col]
    cmp bl,0
    je short @f
    xor bh,bh
    mov cl,[di+TetrisBoardRandomBlock.Row]
    xor ch,ch
    mov si,cx
    mov al,[di+TetrisBoardRandomBlock.Color]
    mov dx,di
    call tetrisRenderBlock
    mov di,dx
    add di,sizeof TetrisBoardRandomBlock
    jmp short @b
@@:
endif    
    ret
tetrisInitRender endp

; Clobber: everything.
tetrisUpdate proc
    ; Change state if needed.
    cmp [TetrisLevelNextStateSet],1
    jne short @f
    mov [TetrisLevelNextStateSet],0
    mov al,[TetrisLevelNextState]
    mov [TetrisLevelState],al
@@:
    ; Update state.
    mov al,[TetrisLevelState]
    cmp al,TETRIS_LEVEL_STATE_PLAY
    jne short @f
    jmp tetrisUpdateLevelStatePlay
@@:
    cmp al,TETRIS_LEVEL_STATE_ANIM
    jne short @f
    jmp tetrisUpdateLevelStateAnim
@@:
    jmp tetrisUpdateLevelStateOver
tetrisUpdate endp

; Clobber: everything.
tetrisRender proc
    ; Render state.
    mov al,[TetrisLevelState]
    cmp al,TETRIS_LEVEL_STATE_PLAY
    jne short @f
    call tetrisRenderLevelStatePlay
    jmp short done
@@:
    cmp al,TETRIS_LEVEL_STATE_ANIM
    jne short @f
    call tetrisRenderLevelStateAnim
    jmp short done
@@:
    call tetrisRenderLevelStateOver
done:

if CONSOLE_ENABLED
    call tetrisRenderDebug
endif
    ret
tetrisRender endp

;--------------;
; Code private ;
;--------------;

; Input: al (next state).
tetrisSetLevelNextState proc private
if ASSERT_ENABLED
    ; The next state should be set only once per frame.
    cmp [TetrisLevelNextStateSet],1
    jne short @f
    ASSERT
@@:
endif
    mov [TetrisLevelNextStateSet],1
    mov [TetrisLevelNextState],al
    ret
tetrisSetLevelNextState endp

; Input: ch (unsigned col), dh (unsigned row).
; Output: bx (addr).
; Clobber: ax, si, bp.
tetrisBoardGetCellAddr proc private
if ASSERT_ENABLED
    cmp ch,TETRIS_BOARD_COLS
    jb short @f
    ASSERT
@@:
    cmp dh,TETRIS_BOARD_ROWS
    jb short @f
    ASSERT
@@:
endif
    mov bl,ch
    xor bh,bh
    mov al,dh
    xor ah,ah
    mov si,ax
    ; Could use a table to multiply faster by 12.
    ; static_assert(TETRIS_BOARD_COLS == 12)
    ; si = 12 * row = 4 * (row + (2 * row))
    mov bp,si
    shl si,1
    lea si,[bp + si]
    shl si,1
    shl si,1
    lea bx,[TetrisBoardCellUsedArray + bx + si]
    ret
tetrisBoardGetCellAddr endp

; Input: ch (unsigned col), dh (unsigned row).
; Output: zf (set if true).
; Clobber: ax, bx, si, bp.
tetrisBoardGetCellIsUsed proc private
    call tetrisBoardGetCellAddr
    cmp byte ptr [bx],TETRIS_BOARD_CELL_USED
    ret
tetrisBoardGetCellIsUsed endp

; Input: ch (unsigned col), dh (unsigned row).
; Clobber: ax, bx, si, bp.
tetrisBoardSetCellUsed proc private
    call tetrisBoardGetCellAddr    
if ASSERT_ENABLED
    ; Validate that the cell is not used already.
    cmp byte ptr [bx],TETRIS_BOARD_CELL_USED
    jne short @f
    ASSERT
@@:
endif
    mov byte ptr [bx],TETRIS_BOARD_CELL_USED
    ret
tetrisBoardSetCellUsed endp

; Input: ch (unsigned col), dh (unsigned row) of the piece that already touched a used cell.
; Output: dh (decremented dh).
; Clobber: ax, bx, si, bp.
tetrisBoardAddPiece proc private
    ; Decrement row so we go back to the free cell above this one.
    dec dh
    call tetrisBoardSetCellUsed
    mov al,TETRIS_LEVEL_STATE_ANIM
    call tetrisSetLevelNextState
    mov [TetrisLevelStateAnimFramesLeft],TETRIS_LEVEL_STATE_ANIM_FRAMES_LEFT
    ret
tetrisBoardAddPiece endp

; Output: cx (unsigned col), dx (unsigned row).
tetrisBoardInitFallingPiece proc private
    mov cx,(TETRIS_BLOCK_START_COL shl 8)
    mov [TetrisFallingPieceCol],cx
    mov [TetrisFallingPiecePrevColHI],ch
    xor dx,dx
    mov [TetrisFallingPieceRow],dx
    mov [TetrisFallingPiecePrevRowHI],dh
    mov al,[TetrisFallingPieceColor]
    inc al
    and al,TETRIS_FALLING_PIECE_COLOR_MASK
    mov [TetrisFallingPieceColor],al
    ret
tetrisBoardInitFallingPiece endp

; Clobber: everything.
tetrisUpdateLevelStatePlay proc private
    mov cx,[TetrisFallingPieceCol]
    mov [TetrisFallingPiecePrevColHI],ch
    mov dx,[TetrisFallingPieceRow]
    mov [TetrisFallingPiecePrevRowHI],dh

    ; Horizontal movement.
    ; static_assert(TETRIS_FALLING_PIECE_SPEED_X <= 0x100)
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_LEFT
	jnz short @f
    sub cx,TETRIS_FALLING_PIECE_SPEED_X
    call tetrisBoardGetCellIsUsed
	jnz short @f
    inc ch
    xor cl,cl
@@:
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_RIGHT
    jnz short @f
    add cx,TETRIS_FALLING_PIECE_SPEED_X
    call tetrisBoardGetCellIsUsed
	jnz short @f
    dec ch
    mov cl,0ffh
@@:

    ; Vertical movement.
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_DOWN
	jnz short @f
nextRow:    
    inc dh
    call tetrisBoardGetCellIsUsed
    jnz short nextRow
    jmp short addPiece
@@:
    ; static_assert(TETRIS_FALLING_PIECE_SPEED_Y <= 0x100)
    add dx,TETRIS_FALLING_PIECE_SPEED_Y
    call tetrisBoardGetCellIsUsed
	jnz short @f
addPiece:
    call tetrisBoardAddPiece
@@:

    mov [TetrisFallingPieceCol],cx
    mov [TetrisFallingPieceRow],dx
    ret
tetrisUpdateLevelStatePlay endp

; Clobber: everything.
tetrisUpdateLevelStateAnim proc private
    dec [TetrisLevelStateAnimFramesLeft]
    jnz short done
    mov [TetrisLevelStateAnimRowToWipe],TETRIS_BOARD_ROWS
    ; Check if the row is full.
    mov ch,1
    mov dh,[TetrisFallingPieceRowHI]
    call tetrisBoardGetCellAddr
    mov ax,TETRIS_BOARD_CELL_USED or (TETRIS_BOARD_CELL_USED shl 8)
    ; static_assert((TETRIS_BOARD_VISIBLE_COLS & 1) == 0)
    mov cx,TETRIS_BOARD_VISIBLE_COLS / 2
    mov di,bx
    repe scasw
    jne short @f
    mov [TetrisLevelStateAnimRowToWipe],dh
    ; If row is full, empty it.
    mov ax,TETRIS_BOARD_CELL_UNUSED or (TETRIS_BOARD_CELL_UNUSED shl 8)
    ; static_assert((TETRIS_BOARD_VISIBLE_COLS & 1) == 0)
    mov cx,TETRIS_BOARD_VISIBLE_COLS / 2
    mov di,bx
    rep stosw
@@:
    ; Set next state, either the game continues or it's over.
    call tetrisBoardInitFallingPiece
    call tetrisBoardGetCellIsUsed
    mov al,TETRIS_LEVEL_STATE_PLAY
	jnz short @f
    mov al,TETRIS_LEVEL_STATE_OVER
@@:
    call tetrisSetLevelNextState
done:
    ret
tetrisUpdateLevelStateAnim endp

; Clobber: everything.
tetrisUpdateLevelStateOver proc private
    ret
tetrisUpdateLevelStateOver endp

; Clobber: everything.
tetrisRenderLevelStatePlay proc private
    ; Erase previous position.
    mov al,TETRIS_FALLING_PIECE_COLOR_CLEAR
    mov cl,[TetrisFallingPiecePrevColHI]
    mov dl,[TetrisFallingPiecePrevRowHI]
    call tetrisRenderPiece
    ; Draw new position.
    mov al,[TetrisFallingPieceColor]
    mov cl,[TetrisFallingPieceColHI]
    mov dl,[TetrisFallingPieceRowHI]
    jmp tetrisRenderPiece
tetrisRenderLevelStatePlay endp

; Clobber: everything.
tetrisRenderLevelStateAnim proc private
    ; Check if wiping the row is needed.
    cmp [TetrisLevelStateAnimFramesLeft],0
    jne short done
    ; Is this check necessary?
    cmp [TetrisLevelNextState],TETRIS_LEVEL_STATE_PLAY
    jne short done
    mov al,[TetrisLevelStateAnimRowToWipe]
    cmp al,TETRIS_BOARD_ROWS
    jae short done
    ; Should wipe the video memory directly which is faster than calling tetrisRenderBlock for each column.
    mov cx,TETRIS_BOARD_VISIBLE_COLS
    xor ah,ah
    mov dx,ax
@@:
    mov al,TETRIS_FALLING_PIECE_COLOR_CLEAR
    mov bx,cx
    mov si,dx
    call tetrisRenderBlock
    loop short @b
done:
    ret
tetrisRenderLevelStateAnim endp

; Clobber: everything.
tetrisRenderLevelStateOver proc private
if CONSOLE_ENABLED
    CONSOLE_SET_CURSOR_COL_ROW 15, 1
	mov si,offset allSegments:tmpText
	call consolePrintString
endif
    ret
if CONSOLE_ENABLED
tmpText:
	byte "Game Over!", 0
endif
tetrisRenderLevelStateOver endp

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

; Input: al (block color), bx (unsigned col), si (unsigned row).
; Clobber: ax, bx, si, di, bp.
tetrisRenderBlock proc private
if ASSERT_ENABLED
    cmp al,TETRIS_FALLING_PIECE_COLOR_COUNT
    jb short @f
    ASSERT
@@:
    ; static_assert(TETRIS_BOARD_COLS - TETRIS_BOARD_VISIBLE_COLS == 2)
    cmp bx,1
    jae short @f
    ASSERT
@@:
    cmp bx,TETRIS_BOARD_COLS - 1
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
    mov bp,ax
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
    mov ax,bp
    stosw

    ret
tetrisRenderBlock endp

; Input: al (piece color), cl (unsigned col), dl (unsigned row).
; Clobber: ax, bx, ch, dh, si, di, bp.
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
                                        ;    Limit, Center.
    TetrisBlockColor                word    0aaaah, 0febfh,
                                            0ffffh, 0abeah,
                                            05555h, 0fd7fh,
                                            0aaaah, 05695h,
                                            00000h, 00000h
if TETRIS_BOARD_RANDOM_BLOCKS           ;  Col, Row, Color.
    TetrisRandomBlocks              label byte
    TetrisRandomBlockShape0         byte     8,  17,     2,
                                             9,  17,     2,
                                             8,  18,     2,
                                             8,  19,     2
    TetrisRandomBlockCube0          byte     9,  18,     1,
                                            10,  18,     1,
                                             9,  19,     1,
                                            10,  19,     1
    TetrisRandomBlocksEnd           byte     0
endif
constData ends

data segment public
    TetrisLevelState                byte ?
    TetrisLevelNextStateSet         byte ?
    TetrisLevelNextState            byte ?
    TetrisLevelStateAnimFramesLeft  byte ?
    TetrisLevelStateAnimRowToWipe   byte ?
    TetrisFallingPieceCol           label word
    TetrisFallingPieceColLO         byte ?
    TetrisFallingPieceColHI         byte ?
    TetrisFallingPieceRow           label word
    TetrisFallingPieceRowLO         byte ?
    TetrisFallingPieceRowHI         byte ?
    TetrisFallingPiecePrevColHI     byte ?
    TetrisFallingPiecePrevRowHI     byte ?
    TetrisFallingPieceColor         byte ?
    ; Align array to a word boundary so the initialization code can run faster on the 80286 and up. But maybe it's better to have separate data segments for bytes and words.
    align word
    TetrisBoardCellUsedArray        byte TETRIS_BOARD_COUNT dup(?)
data ends

end
