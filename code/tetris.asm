include code\tetris.inc
include code\assert.inc
include code\assumSeg.inc
include code\console.inc
include code\keyboard.inc
include code\render.inc
include code\timer.inc

TETRIS_BOARD_INIT_BLOCKS                equ 1
TETRIS_BOARD_COLS                       equ 12
TETRIS_BOARD_ROWS                       equ 21
TETRIS_BOARD_FIRST_VISIBLE_COL          equ 1
TETRIS_BOARD_VISIBLE_COLS               equ TETRIS_BOARD_COLS - 2
.errnz TETRIS_BOARD_VISIBLE_COLS and 1
TETRIS_BOARD_VISIBLE_ROWS               equ TETRIS_BOARD_ROWS - 1
TETRIS_BOARD_COUNT                      equ TETRIS_BOARD_COLS * TETRIS_BOARD_ROWS
TETRIS_BLOCK_SIZE                       equ 8
TETRIS_BLOCK_HALF_SIZE                  equ (TETRIS_BLOCK_SIZE shr 1)
TETRIS_BLOCK_START_COL                  equ ((TETRIS_BOARD_COLS shr 1) - 1)
TETRIS_BLOCK_START_COL_LOHI             equ 80h or (TETRIS_BLOCK_START_COL shl 8)
TETRIS_BOARD_BLOCK_ID_0                 equ 0
TETRIS_BOARD_BLOCK_ID_1                 equ 1
TETRIS_BOARD_BLOCK_ID_2                 equ 2
TETRIS_BOARD_BLOCK_ID_3                 equ 3
TETRIS_BOARD_BLOCK_ID_4                 equ 4
TETRIS_BOARD_BLOCK_ID_5                 equ 5
TETRIS_BOARD_BLOCK_ID_6                 equ 6
TETRIS_BOARD_BLOCK_ID_7                 equ 7
TETRIS_BOARD_BLOCK_ID_EMPTY             equ 8
TETRIS_BOARD_BLOCK_ID_COUNT             equ TETRIS_BOARD_BLOCK_ID_EMPTY + 1
; .err isPowerOfTwo(TETRIS_BOARD_BLOCK_ID_EMPTY)
TETRIS_BOARD_BLOCK_ID_MASK              equ TETRIS_BOARD_BLOCK_ID_EMPTY - 1
TETRIS_BOARD_BLOCK_HIGHLIGHT_COLOR      equ 0ffffh
TETRIS_BOARD_START_POS_X                equ BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH - ((TETRIS_BOARD_VISIBLE_COLS shr 1) * TETRIS_BLOCK_SIZE)
TETRIS_BOARD_START_POS_Y                equ BIOS_VIDEO_MODE_320_200_4_HALF_HEIGHT - ((TETRIS_BOARD_VISIBLE_ROWS shr 1) * TETRIS_BLOCK_SIZE)
TETRIS_BOARD_BANK_START_OFFSET          equ ((TETRIS_BOARD_START_POS_Y shr 1) * BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE) + (((TETRIS_BOARD_START_POS_X - TETRIS_BLOCK_SIZE) / TETRIS_BLOCK_SIZE) shl 1)
TETRIS_BOARD_BORDER_COLOR               equ 1
TETRIS_RENDER_BLOCK_WIDTH_IN_BYTES      equ 2
TETRIS_RENDER_BLOCK_NEXT_LINE_OFFSET    equ (BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE - TETRIS_RENDER_BLOCK_WIDTH_IN_BYTES)
TETRIS_RENDER_NEXT_BANK_OFFSET          equ (BIOS_VIDEO_MODE_320_200_4_BANK1_OFFSET - TETRIS_RENDER_BLOCK_WIDTH_IN_BYTES) - ((TETRIS_BLOCK_HALF_SIZE - 1) * BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE)
TETRIS_FALLING_PIECE_SPEED_X_LOHI       equ 00040h
TETRIS_FALLING_PIECE_SPEED_Y_LOHI       equ 00010h
TETRIS_KEY_MOVE_PIECE_LEFT			    equ BIOS_KEYBOARD_SCANCODE_ARROW_LEFT
TETRIS_KEY_MOVE_PIECE_RIGHT				equ BIOS_KEYBOARD_SCANCODE_ARROW_RIGHT
TETRIS_KEY_DROP_PIECE                   equ BIOS_KEYBOARD_SCANCODE_ARROW_DOWN
TETRIS_LEVEL_STATE_PLAY                 equ 0
TETRIS_LEVEL_STATE_ANIM                 equ 1
TETRIS_LEVEL_STATE_OVER                 equ 2
TETRIS_LEVEL_STATE_ANIM_FRAMES_LEFT     equ 25
; Color names have to be short or the macro where they are used will not parse correctly. I guess it hits some sort of limit.
T_BKGRND                                equ BIOS_VIDEO_MODE_320_200_4_PALETTE_0_COLOR_BACKGROUND
T_GREEN                                 equ BIOS_VIDEO_MODE_320_200_4_PALETTE_0_COLOR_GREEN
T_RED                                   equ BIOS_VIDEO_MODE_320_200_4_PALETTE_0_COLOR_RED
T_YELLOW                                equ BIOS_VIDEO_MODE_320_200_4_PALETTE_0_COLOR_YELLOW

if TETRIS_BOARD_INIT_BLOCKS
TetrisBoardInitBlock struct
    BlockId     byte ?
    Col         byte ?
    Row         byte ?
TetrisBoardInitBlock ends
endif

TETRIS_BLOCK_COLOR macro aIdStr:req, aLmtClr:req, aCtrClr:req
    .erre aLmtClr lt BIOS_VIDEO_MODE_320_200_4_COLOR_COUNT
    .erre aCtrClr lt BIOS_VIDEO_MODE_320_200_4_COLOR_COUNT
    ;; LLLL,LLLL,
    ;; LCCC,CCCL
    TetrisBlockIdColor&aIdStr byte (aLmtClr shl 6) or (aLmtClr shl 4) or (aLmtClr shl 2) or aLmtClr,
                                   (aLmtClr shl 6) or (aLmtClr shl 4) or (aLmtClr shl 2) or aLmtClr,    
                                   (aLmtClr shl 6) or (aCtrClr shl 4) or (aCtrClr shl 2) or aCtrClr,
                                   (aCtrClr shl 6) or (aCtrClr shl 4) or (aCtrClr shl 2) or aLmtClr
endm

code segment readonly public

;-------------;
; Code public ;
;-------------;

; Clobber: everything.
tetrisInit proc
    mov [TetrisLevelState],TETRIS_LEVEL_STATE_PLAY
    mov [TetrisLevelNextStateSet],0
    mov [TetrisFallingPieceBlockId],TETRIS_BOARD_BLOCK_ID_MASK
    call tetrisBoardInitFallingPiece
    ; Init board.
    .erre TETRIS_BOARD_COLS eq 12
    mov cx,TETRIS_BOARD_VISIBLE_ROWS
    mov di,offset TetrisBoardBlockIdArray
@@:
    mov ax,TETRIS_BOARD_BLOCK_ID_0 or (TETRIS_BOARD_BLOCK_ID_EMPTY shl 8)
    stosw
    mov al,TETRIS_BOARD_BLOCK_ID_EMPTY
    stosw
    stosw
    stosw
    stosw
    .erre TETRIS_BOARD_BLOCK_ID_0 eq 0
    xor ah,ah
    stosw
    loop short @b
    .erre TETRIS_BOARD_ROWS - TETRIS_BOARD_VISIBLE_ROWS eq 1
    .erre TETRIS_BOARD_BLOCK_ID_0 eq 0
    xor ax,ax
    mov cx,(TETRIS_BOARD_COLS shr 1)
    rep stosw
if TETRIS_BOARD_INIT_BLOCKS
    mov di,offset TetrisBoardInitBlocks
@@:
    mov al,[di+TetrisBoardInitBlock.BlockId]
    cmp al,TETRIS_BOARD_BLOCK_ID_EMPTY
    je short @f
    mov ch,[di+TetrisBoardInitBlock.Col]
    mov dh,[di+TetrisBoardInitBlock.Row]
    call tetrisBoardSetBlockId
    add di,sizeof TetrisBoardInitBlock
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
if TETRIS_BOARD_INIT_BLOCKS
    mov si,offset TetrisBoardInitBlocks
@@:
    mov al,[si+TetrisBoardInitBlock.BlockId]
    cmp al,TETRIS_BOARD_BLOCK_ID_EMPTY
    je short @f
    mov cl,[si+TetrisBoardInitBlock.Col]
    mov dl,[si+TetrisBoardInitBlock.Row]
    call tetrisRenderBlock
    add si,sizeof TetrisBoardInitBlock
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
tetrisBoardGetBlockAddr proc private
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
    .erre TETRIS_BOARD_COLS eq 12
    ; si = 12 * row = 4 * (row + (2 * row))
    mov bp,si
    shl si,1
    add si,bp
    shl si,1
    shl si,1
    lea bx,[TetrisBoardBlockIdArray + bx + si]
    ret
tetrisBoardGetBlockAddr endp

; Input: ch (unsigned col), dh (unsigned row).
; Output: zf (set if true).
; Clobber: bx, si, bp.
tetrisBoardGetBlockIsEmpty proc private
    call tetrisBoardGetBlockAddr
    cmp byte ptr [bx],TETRIS_BOARD_BLOCK_ID_EMPTY
    ret
tetrisBoardGetBlockIsEmpty endp

; Input: al (block id), ch (unsigned col), dh (unsigned row).
; Clobber: bx, si, bp.
tetrisBoardSetBlockId proc private
if ASSERT_ENABLED
    .erre TETRIS_BOARD_COLS - TETRIS_BOARD_VISIBLE_COLS eq 2
    cmp ch,TETRIS_BOARD_FIRST_VISIBLE_COL
    jae short @f
    ASSERT
@@:
    cmp ch,TETRIS_BOARD_COLS - 1
    jb short @f
    ASSERT
@@:
    cmp dh,TETRIS_BOARD_VISIBLE_ROWS
    jb short @f
    ASSERT
@@:
endif
    call tetrisBoardGetBlockAddr
    mov byte ptr [bx],al
    ret
tetrisBoardSetBlockId endp

; Output: al (block id), cx (unsigned colLOHI), dx (unsigned rowLOHI).
tetrisBoardInitFallingPiece proc private
    mov al,[TetrisFallingPieceBlockId]
    inc al
    and al,TETRIS_BOARD_BLOCK_ID_MASK
    mov [TetrisFallingPieceBlockId],al
    mov cx,TETRIS_BLOCK_START_COL_LOHI
    mov [TetrisFallingPieceCol],cx
    mov [TetrisFallingPiecePrevColHI],ch
    xor dx,dx
    mov [TetrisFallingPieceRow],dx
    mov [TetrisFallingPiecePrevRowHI],dh
    ret
tetrisBoardInitFallingPiece endp

; Clobber: everything.
tetrisUpdateLevelStatePlay proc private
    mov cx,[TetrisFallingPieceCol]
    mov [TetrisFallingPiecePrevColHI],ch
    mov dx,[TetrisFallingPieceRow]
    mov [TetrisFallingPiecePrevRowHI],dh

    ; Horizontal movement.
    .erre TETRIS_FALLING_PIECE_SPEED_X_LOHI le 100h
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_MOVE_PIECE_LEFT
	jnz short @f
    sub cx,TETRIS_FALLING_PIECE_SPEED_X_LOHI
    call tetrisBoardGetBlockIsEmpty
	jz short @f
    inc ch
    xor cl,cl
@@:
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_MOVE_PIECE_RIGHT
    jnz short @f
    add cx,TETRIS_FALLING_PIECE_SPEED_X_LOHI
    call tetrisBoardGetBlockIsEmpty
	jz short @f
    dec ch
    mov cl,0ffh
@@:

    ; Vertical movement.
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_DROP_PIECE
	jnz short @f
nextRow:
    inc dh
    call tetrisBoardGetBlockIsEmpty
    jz short nextRow
    jmp short addPiece
@@:
    .erre TETRIS_FALLING_PIECE_SPEED_Y_LOHI le 100h
    add dx,TETRIS_FALLING_PIECE_SPEED_Y_LOHI
    call tetrisBoardGetBlockIsEmpty
	jz short @f
addPiece:
    ; Decrement row so we go back to the free cell above this one.
    dec dh
    mov al,TetrisFallingPieceBlockId
    call tetrisBoardSetBlockId
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
    cmp [TetrisLevelStateAnimFramesLeft],TETRIS_LEVEL_STATE_ANIM_FRAMES_LEFT
    jne short clearDone
    mov [TetrisLevelStateAnimRowToClear],TETRIS_BOARD_ROWS
    ; Check if the row is full.
    mov ch,TETRIS_BOARD_FIRST_VISIBLE_COL
    mov dh,[TetrisFallingPieceRowHI]
    call tetrisBoardGetBlockAddr
    mov al,TETRIS_BOARD_BLOCK_ID_EMPTY
    mov cx,TETRIS_BOARD_VISIBLE_COLS
    mov di,bx
    repne scasb
    je short clearDone
    ; If row is full, clear it.
if 0
    ; Disable this code temporarily, since the matching code to render the blocks that moved is not done yet.
@@:
    .erre offset TetrisBoardBlockIdArray gt TETRIS_BOARD_COLS
    lea si,[bx-TETRIS_BOARD_COLS]
    cmp si,offset TetrisBoardBlockIdArray
    jb short clearRow
    ; If there is a row above this one, copy it here.
    mov cx,(TETRIS_BOARD_VISIBLE_COLS shr 1)
    mov di,bx
    mov bx,si
    rep movsw
    jmp short @b
endif
clearRow:
    ; If there are no more rows above this one, clear it.
    mov ax,(TETRIS_BOARD_BLOCK_ID_EMPTY or (TETRIS_BOARD_BLOCK_ID_EMPTY shl 8))
    mov cx,(TETRIS_BOARD_VISIBLE_COLS shr 1)
    mov di,bx
    rep stosw
    mov [TetrisLevelStateAnimRowToClear],dh
clearDone:
    dec [TetrisLevelStateAnimFramesLeft]
    jnz short nextStateDone
    ; Set next state, either the game continues or it's over.
    call tetrisBoardInitFallingPiece
    call tetrisBoardGetBlockIsEmpty
    mov al,TETRIS_LEVEL_STATE_PLAY
	jz short @f
    mov al,TETRIS_LEVEL_STATE_OVER
@@:
    call tetrisSetLevelNextState
nextStateDone:
    ret
tetrisUpdateLevelStateAnim endp

; Clobber: everything.
tetrisUpdateLevelStateOver proc private
    ret
tetrisUpdateLevelStateOver endp

; Clobber: everything.
tetrisRenderLevelStatePlay proc private
    ; Erase previous position.
    mov al,TETRIS_BOARD_BLOCK_ID_EMPTY
    mov cl,[TetrisFallingPiecePrevColHI]
    mov dl,[TetrisFallingPiecePrevRowHI]
    call tetrisRenderBlock
    ; Draw new position.
    mov al,[TetrisFallingPieceBlockId]
    mov cl,[TetrisFallingPieceColHI]
    mov dl,[TetrisFallingPieceRowHI]
    jmp tetrisRenderBlock
tetrisRenderLevelStatePlay endp

; Clobber: everything.
tetrisRenderLevelStateAnim proc private
    .erre TETRIS_LEVEL_STATE_ANIM_FRAMES_LEFT gt 1
    mov cl,TETRIS_BOARD_FIRST_VISIBLE_COL
    mov bl,[TetrisLevelStateAnimRowToClear]
    cmp bl,TETRIS_BOARD_ROWS
    je short done
    mov al,[TetrisLevelStateAnimFramesLeft]
    ; Check if highlighting the row is needed.
    cmp al,TETRIS_LEVEL_STATE_ANIM_FRAMES_LEFT - 1
    jne short highlightSkip
    mov dl,bl
    call tetrisRenderGetVideoOffset
    mov ax,TETRIS_BOARD_BLOCK_HIGHLIGHT_COLOR
tmpLabel:
    .erre TETRIS_BLOCK_HALF_SIZE eq 4
    .erre TETRIS_RENDER_BLOCK_WIDTH_IN_BYTES eq 2
    ; Highlight the four even lines.
repeat (TETRIS_BLOCK_HALF_SIZE - 1)
    mov cx,TETRIS_BOARD_VISIBLE_COLS
    rep stosw
    add di,(BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE - (TETRIS_BOARD_VISIBLE_COLS shl 1))
endm
    mov cx,TETRIS_BOARD_VISIBLE_COLS
    rep stosw
    add di,(BIOS_VIDEO_MODE_320_200_4_BANK1_OFFSET - (TETRIS_BOARD_VISIBLE_COLS shl 1)) - ((TETRIS_BLOCK_HALF_SIZE - 1) * BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE)
    ; Highlight the four odd lines.
repeat (TETRIS_BLOCK_HALF_SIZE - 1)
    mov cx,TETRIS_BOARD_VISIBLE_COLS
    rep stosw
    add di,(BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE - (TETRIS_BOARD_VISIBLE_COLS shl 1))
endm
    mov cx,TETRIS_BOARD_VISIBLE_COLS
    rep stosw
    jmp short done
highlightSkip:
    ; Check if clearing the row is needed.
    cmp al,0
    jne short done
    ; Is this check necessary or an assert is enough?
    cmp [TetrisLevelNextState],TETRIS_LEVEL_STATE_PLAY
    jne short done
    ; This code should redraw the pieces that moved instead of clearing the current row.
    mov dl,bl
    call tetrisRenderGetVideoOffset
    xor ah,ah
    jmp short tmpLabel
done:
    ret
tetrisRenderLevelStateAnim endp

; Clobber: everything.
tetrisRenderLevelStateOver proc private
if CONSOLE_ENABLED
    CONSOLE_SET_CURSOR_COL_ROW 15, 1
	mov si,offset allSegments:tmpText
	call consolePrintString
    jmp short @f
tmpText:
	byte "Game Over!", 0
@@:
endif
    ret
tetrisRenderLevelStateOver endp

; Input: cl (unsigned col), dl (unsigned row).
; Output: di (offset).
; Clobber: bx.
tetrisRenderGetVideoOffset proc private
if ASSERT_ENABLED
    .erre TETRIS_BOARD_COLS - TETRIS_BOARD_VISIBLE_COLS eq 2
    cmp cl,TETRIS_BOARD_FIRST_VISIBLE_COL
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

; Input: al (block id), cl (unsigned col), dl (unsigned row).
; Clobber: ax, bx, di, bp.
tetrisRenderBlock proc private
if ASSERT_ENABLED
    cmp al,TETRIS_BOARD_BLOCK_ID_COUNT
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
    mov ax,[TetrisBlockIdColor + bx]
    mov bp,ax

    .erre TETRIS_BLOCK_HALF_SIZE eq 4
    ; Render the four even lines.
    stosw
    add di,TETRIS_RENDER_BLOCK_NEXT_LINE_OFFSET
    ; Get center color.
    mov ax,[TetrisBlockIdColor + (type TetrisBlockIdColor) + bx]
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
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_MOVE_PIECE_LEFT
	call consolePrintZeroFlag
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_MOVE_PIECE_RIGHT
    call consolePrintZeroFlag
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_DROP_PIECE
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
    TetrisBlockIdColor                     label word
                      ; IdStr,     LmtClr,     CtrClr.
    TETRIS_BLOCK_COLOR      0,    T_GREEN,      T_RED
    TETRIS_BLOCK_COLOR      1,    T_GREEN,   T_YELLOW
    TETRIS_BLOCK_COLOR      2,      T_RED,   T_BKGRND
    TETRIS_BLOCK_COLOR      3,      T_RED,    T_GREEN
    TETRIS_BLOCK_COLOR      4,      T_RED,   T_YELLOW
    TETRIS_BLOCK_COLOR      5,   T_YELLOW,   T_BKGRND
    TETRIS_BLOCK_COLOR      6,   T_YELLOW,    T_GREEN
    TETRIS_BLOCK_COLOR      7,   T_YELLOW,      T_RED
    TETRIS_BLOCK_COLOR  Empty,   T_BKGRND,   T_BKGRND
                                            
if TETRIS_BOARD_INIT_BLOCKS            ; BlockId, Col, Row.
    TetrisBoardInitBlocks              label byte
    TetrisBoardInitBlockHorizLine0     byte    3,   1,  19,
                                               3,   2,  19,
                                               3,   3,  19,
                                               3,   4,  19
    TetrisBoardInitBlockShape0         byte    1,   2,  18,
                                               1,   3,  17,
                                               1,   3,  18,
                                               1,   4,  17
    TetrisBoardInitBlockShape1         byte    0,   5,  17,
                                               0,   4,  18,
                                               0,   5,  18,
                                               0,   5,  19
    TetrisBoardInitBlockShape2         byte    4,   7,  17,
                                               4,   8,  17,
                                               4,   7,  18,
                                               4,   7,  19
    TetrisBoardInitBlockCube0          byte    1,   8,  18,
                                               1,   9,  18,
                                               1,   8,  19,
                                               1,   9,  19
    TetrisBoardInitBlockShape3         byte    0,   9,  17,
                                               0,  10,  17,
                                               0,  10,  18,
                                               0,  10,  19
    TetrisBoardInitBlocksEnd           byte    TETRIS_BOARD_BLOCK_ID_EMPTY
endif
constData ends

data segment public
    TetrisLevelState                byte ?
    TetrisLevelNextStateSet         byte ?
    TetrisLevelNextState            byte ?
    TetrisLevelStateAnimFramesLeft  byte ?
    TetrisLevelStateAnimRowToClear  byte ?
    TetrisFallingPieceBlockId       byte ?
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
    TetrisBoardBlockIdArray         byte TETRIS_BOARD_COUNT dup(?)
data ends

end
