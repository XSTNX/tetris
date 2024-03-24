include code\tetris.inc
include code\assert.inc
include code\assumSeg.inc
include code\console.inc
include code\keyboard.inc
include code\render.inc
include code\timer.inc

TETRIS_BOARD_RANDOM_BLOCKS              equ 1
TETRIS_BOARD_COLS                       equ 12
TETRIS_BOARD_ROWS                       equ 21
TETRIS_BOARD_VISIBLE_COLS               equ TETRIS_BOARD_COLS - 2
TETRIS_BOARD_VISIBLE_ROWS               equ TETRIS_BOARD_ROWS - 1
TETRIS_BOARD_COUNT                      equ TETRIS_BOARD_COLS * TETRIS_BOARD_ROWS
TETRIS_BLOCK_SIZE                       equ 8
TETRIS_BLOCK_HALF_SIZE                  equ (TETRIS_BLOCK_SIZE shr 1)
TETRIS_BLOCK_START_COL                  equ ((TETRIS_BOARD_COLS shr 1) - 1)
TETRIS_BOARD_CELL_UNUSED                equ 0
TETRIS_BOARD_CELL_USED                  equ 1
TETRIS_BOARD_START_POS_X                equ BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH - ((TETRIS_BOARD_VISIBLE_COLS shr 1) * TETRIS_BLOCK_SIZE)
TETRIS_BOARD_START_POS_Y                equ BIOS_VIDEO_MODE_320_200_4_HALF_HEIGHT - ((TETRIS_BOARD_VISIBLE_ROWS shr 1) * TETRIS_BLOCK_SIZE)
TETRIS_BOARD_BANK_START_OFFSET          equ ((TETRIS_BOARD_START_POS_Y shr 1) * BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE) + (((TETRIS_BOARD_START_POS_X - TETRIS_BLOCK_SIZE) / TETRIS_BLOCK_SIZE) shl 1)
TETRIS_BOARD_BORDER_COLOR               equ 1
TETRIS_RENDER_BLOCK_WIDTH_IN_BYTES      equ 2
TETRIS_RENDER_BLOCK_NEXT_LINE_OFFSET    equ (BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE - TETRIS_RENDER_BLOCK_WIDTH_IN_BYTES)
TETRIS_RENDER_NEXT_BANK_OFFSET          equ (BIOS_VIDEO_MODE_320_200_4_BANK1_OFFSET - TETRIS_RENDER_BLOCK_WIDTH_IN_BYTES) - ((TETRIS_BLOCK_HALF_SIZE - 1) * BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE)
TETRIS_FALLING_PIECE_SPEED_X            equ 64
TETRIS_FALLING_PIECE_SPEED_Y            equ 16
TETRIS_FALLING_PIECE_COLOR_MASK         equ 11b
TETRIS_FALLING_PIECE_COLOR_CLEAR        equ TETRIS_FALLING_PIECE_COLOR_MASK + 1
TETRIS_FALLING_PIECE_COLOR_COUNT        equ TETRIS_FALLING_PIECE_COLOR_CLEAR + 1
TETRIS_KEY_LEFT					        equ BIOS_KEYBOARD_SCANCODE_ARROW_LEFT
TETRIS_KEY_RIGHT				        equ BIOS_KEYBOARD_SCANCODE_ARROW_RIGHT
TETRIS_KEY_DOWN				            equ BIOS_KEYBOARD_SCANCODE_ARROW_DOWN
TETRIS_LEVEL_STATE_PLAY                 equ 0
TETRIS_LEVEL_STATE_ANIM                 equ 1
TETRIS_LEVEL_STATE_OVER                 equ 2
TETRIS_LEVEL_STATE_ANIM_FRAMES_LEFT     equ 25

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
    mov cx,(TETRIS_BOARD_COLS shr 1)
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
    mov bx,offset TetrisRandomBlocks
@@:
    mov cl,[bx+TetrisBoardRandomBlock.Col]
    cmp cl,0
    je short @f
    mov dl,[bx+TetrisBoardRandomBlock.Row]
    mov al,[bx+TetrisBoardRandomBlock.Color]
    mov si,bx
    call tetrisRenderBlock
    mov bx,si
    add bx,sizeof TetrisBoardRandomBlock
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
; Clobber: si, bp.
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
    mov bl,dh
    xor bh,bh
    mov si,bx
    mov bl,ch
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
    ; Decrement row so we go back to the free cell above this one.
    dec dh
    call tetrisBoardSetCellUsed
    mov al,TETRIS_LEVEL_STATE_ANIM
    call tetrisSetLevelNextState
    mov [TetrisLevelStateAnimFramesLeft],TETRIS_LEVEL_STATE_ANIM_FRAMES_LEFT
@@:

    mov [TetrisFallingPieceCol],cx
    mov [TetrisFallingPieceRow],dx
    ret
tetrisUpdateLevelStatePlay endp

; Clobber: everything.
tetrisUpdateLevelStateAnim proc private
    dec [TetrisLevelStateAnimFramesLeft]
    jnz short done
    mov [TetrisBoardRowToWipeVideoOffset],0
    ; Check if the row is full.
    mov ch,1
    mov dh,[TetrisFallingPieceRowHI]
    call tetrisBoardGetCellAddr
    mov ax,TETRIS_BOARD_CELL_USED or (TETRIS_BOARD_CELL_USED shl 8)
    ; static_assert((TETRIS_BOARD_VISIBLE_COLS & 1) == 0)
    mov cx,(TETRIS_BOARD_VISIBLE_COLS shr 1)
    mov di,bx
    repe scasw
    jne short @f
    ; If row is full, empty it.
    mov ax,TETRIS_BOARD_CELL_UNUSED or (TETRIS_BOARD_CELL_UNUSED shl 8)
    ; static_assert((TETRIS_BOARD_VISIBLE_COLS & 1) == 0)
    mov cx,(TETRIS_BOARD_VISIBLE_COLS shr 1)
    mov di,bx
    rep stosw
    ; Maybe I should store this offset in a table so it doesn't have to be computed every time.
    mov cl,1
    mov dl,dh
    call tetrisRenderGetVideoOffset
    mov [TetrisBoardRowToWipeVideoOffset],di
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
    call tetrisRenderBlock
    ; Draw new position.
    mov al,[TetrisFallingPieceColor]
    mov cl,[TetrisFallingPieceColHI]
    mov dl,[TetrisFallingPieceRowHI]
    jmp tetrisRenderBlock
tetrisRenderLevelStatePlay endp

; Clobber: everything.
tetrisRenderLevelStateAnim proc private
    ; Check if wiping the row is needed.
    cmp [TetrisLevelStateAnimFramesLeft],0
    jne short @f
    ; Is this check necessary?
    cmp [TetrisLevelNextState],TETRIS_LEVEL_STATE_PLAY
    jne short @f
    mov di,[TetrisBoardRowToWipeVideoOffset]
    xor ax,ax
    cmp di,ax
    je short @f
    ; static_assert(TETRIS_BLOCK_HALF_SIZE == 4)
    ; static_assert(TETRIS_RENDER_BLOCK_WIDTH_IN_BYTES == 2)
    ; Wipe the four even lines.
repeat (TETRIS_BLOCK_HALF_SIZE - 1)
    mov cx,TETRIS_BOARD_VISIBLE_COLS
    rep stosw
    add di,(BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE - (TETRIS_BOARD_VISIBLE_COLS shl 1))
endm
    mov cx,TETRIS_BOARD_VISIBLE_COLS
    rep stosw
    add di,(BIOS_VIDEO_MODE_320_200_4_BANK1_OFFSET - (TETRIS_BOARD_VISIBLE_COLS shl 1)) - ((TETRIS_BLOCK_HALF_SIZE - 1) * BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE)
    ; Wipe the four odd lines.
repeat (TETRIS_BLOCK_HALF_SIZE - 1)
    mov cx,TETRIS_BOARD_VISIBLE_COLS
    rep stosw
    add di,(BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE - (TETRIS_BOARD_VISIBLE_COLS shl 1))
endm
    mov cx,TETRIS_BOARD_VISIBLE_COLS
    rep stosw
@@:
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

; Input: cl (unsigned col), dl (unsigned row).
; Output: di (offset).
; Clobber: bx.
tetrisRenderGetVideoOffset proc private
if ASSERT_ENABLED
    ; static_assert(TETRIS_BOARD_COLS - TETRIS_BOARD_VISIBLE_COLS == 2)
    cmp cl,1
    jae short @f
    ASSERT
@@:
    cmp cl,TETRIS_BOARD_COLS - 1
    jb short @f
    ASSERT
@@:
    cmp dl,TETRIS_BOARD_VISIBLE_ROWS
    jb short @f
    ASSERT
@@:
endif
    mov bl,dl
    xor bh,bh
    mov di,bx
    mov bl,cl
    ; Each row contains four lines per bank.
    shl di,1
    shl di,1
    ; Multiply lines by two to obtain index into the multiplication table.
    shl di,1
    ; Load the offset into the bank for the start of the line.
    mov di,[RenderMultiplyRowBy80Table + di]
    ; Each col is 8 pixels, so it uses a word.
    shl bx,1
    ; Add row and column offsets to obtain the word in memory where the block starts.
    lea di,[TETRIS_BOARD_BANK_START_OFFSET + di + bx]
    ret
tetrisRenderGetVideoOffset endp

; Input: al (block color), cl (unsigned col), dl (unsigned row).
; Clobber: ax, bx, di, bp.
tetrisRenderBlock proc private
if ASSERT_ENABLED
    cmp al,TETRIS_FALLING_PIECE_COLOR_COUNT
    jb short @f
    ASSERT
@@:
endif
    call tetrisRenderGetVideoOffset
    ; Get limit color.
    mov bl,al
    xor bh,bh
    shl bx,1
    shl bx,1
    mov ax,[TetrisBlockColor + bx]
    mov bp,ax

    ; static_assert(TETRIS_BLOCK_HALF_SIZE == 4)
    ; Render the four even lines.
    stosw
    add di,TETRIS_RENDER_BLOCK_NEXT_LINE_OFFSET
    ; Get center color.
    mov ax,[TetrisBlockColor + (type TetrisBlockColor) + bx]
repeat 2
    stosw
    add di,TETRIS_RENDER_BLOCK_NEXT_LINE_OFFSET
endm
    stosw
    ; Render the four odd lines.
    add di,TETRIS_RENDER_NEXT_BANK_OFFSET
repeat 3
    stosw
    add di,TETRIS_RENDER_BLOCK_NEXT_LINE_OFFSET
endm
    mov ax,bp
    stosw

    ret
tetrisRenderBlock endp

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
    TetrisRandomBlockHorizLine0     byte     1,  19,     3,
                                             2,  19,     3,
                                             3,  19,     3,
                                             4,  19,     3,
                                             6,  19,     3,
                                             7,  19,     3
    TetrisRandomBlocksEnd           byte     0
endif
constData ends

data segment public
    TetrisLevelState                byte ?
    TetrisLevelNextStateSet         byte ?
    TetrisLevelNextState            byte ?
    TetrisLevelStateAnimFramesLeft  byte ?
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
    TetrisBoardRowToWipeVideoOffset word ?    
    TetrisBoardCellUsedArray        byte TETRIS_BOARD_COUNT dup(?)
data ends

end
