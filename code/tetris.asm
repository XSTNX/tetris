include code\tetris.inc
include code\assert.inc
include code\assumSeg.inc
include code\bios.inc
include code\console.inc
include code\keyboard.inc
include code\timer.inc

TETRIS_BOARD_INIT_BLOCKS                equ 1
TETRIS_BOARD_COLS                       equ 10
.errnz TETRIS_BOARD_COLS and 1
TETRIS_BOARD_HALF_COLS                  equ TETRIS_BOARD_COLS shr 1
TETRIS_BOARD_ROWS                       equ 20
.errnz TETRIS_BOARD_ROWS and 1
TETRIS_BOARD_HALF_ROWS                  equ TETRIS_BOARD_ROWS shr 1
TETRIS_BOARD_COUNT                      equ TETRIS_BOARD_COLS * TETRIS_BOARD_ROWS
TETRIS_BLOCK_SIZE                       equ 8
.errnz TETRIS_BLOCK_SIZE and 1
TETRIS_BLOCK_HALF_SIZE                  equ TETRIS_BLOCK_SIZE shr 1
TETRIS_BLOCK_START_COL                  equ TETRIS_BOARD_HALF_COLS
TETRIS_BLOCK_START_COL_LOHI             equ 80h or (TETRIS_BLOCK_START_COL shl 8)
TETRIS_BLOCK_COLOR_BKGRND               equ BIOS_VIDEO_MODE_320_200_4_PALETTE_0_COLOR_BACKGROUND
TETRIS_BLOCK_COLOR_GREEN                equ BIOS_VIDEO_MODE_320_200_4_PALETTE_0_COLOR_GREEN
TETRIS_BLOCK_COLOR_RED                  equ BIOS_VIDEO_MODE_320_200_4_PALETTE_0_COLOR_RED
TETRIS_BLOCK_COLOR_YELLOW               equ BIOS_VIDEO_MODE_320_200_4_PALETTE_0_COLOR_YELLOW
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
TETRIS_BOARD_BLOCK_HIGHLIGHT_COLOR      equ BIOS_VIDEO_MODE_320_200_4_PALETTE_0_COLOR_YELLOW
TETRIS_BOARD_BLOCK_HIGHLIGHT_COLOR_BYTE equ (TETRIS_BOARD_BLOCK_HIGHLIGHT_COLOR shl 6) or (TETRIS_BOARD_BLOCK_HIGHLIGHT_COLOR shl 4) or (TETRIS_BOARD_BLOCK_HIGHLIGHT_COLOR shl 2) or TETRIS_BOARD_BLOCK_HIGHLIGHT_COLOR
TETRIS_BOARD_BLOCK_HIGHLIGHT_COLOR_WORD equ TETRIS_BOARD_BLOCK_HIGHLIGHT_COLOR_BYTE or (TETRIS_BOARD_BLOCK_HIGHLIGHT_COLOR_BYTE shl 8)
TETRIS_RENDER_BOARD_START_POS_X         equ BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH - (TETRIS_BOARD_HALF_COLS * TETRIS_BLOCK_SIZE)
; Make sure the board's first pixel is at the start of a byte in video memory.
.errnz TETRIS_RENDER_BOARD_START_POS_X mod BIOS_VIDEO_MODE_320_200_4_PIXELS_P_BYTE
TETRIS_RENDER_BOARD_START_POS_Y         equ BIOS_VIDEO_MODE_320_200_4_HALF_HEIGHT - (TETRIS_BOARD_HALF_ROWS * TETRIS_BLOCK_SIZE)
; Make sure the board starts rendering on an even line.
.errnz TETRIS_RENDER_BOARD_START_POS_Y and 1
TETRIS_RENDER_BOARD_BANK_COL_OFFSET     equ TETRIS_RENDER_BOARD_START_POS_X / BIOS_VIDEO_MODE_320_200_4_PIXELS_P_BYTE
; Make sure the col offset is aligned to 2 bytes, since word string instructions will be used to write to video memory. Doesn't really matter for the 8088, but makes sense for the 8086 and up.
.errnz TETRIS_RENDER_BOARD_BANK_COL_OFFSET and 1
TETRIS_RENDER_BOARD_BANK_ROW_OFFSET     equ (TETRIS_RENDER_BOARD_START_POS_Y shr 1) * BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE
TETRIS_RENDER_BOARD_BANK_OFFSET         equ TETRIS_RENDER_BOARD_BANK_ROW_OFFSET + TETRIS_RENDER_BOARD_BANK_COL_OFFSET
TETRIS_RENDER_BORDER_COLOR              equ BIOS_VIDEO_MODE_320_200_4_PALETTE_0_COLOR_RED
TETRIS_RENDER_BORDER_USE_SOLID_COLOR    equ 0
if TETRIS_RENDER_BORDER_USE_SOLID_COLOR
TETRIS_RENDER_BORDER_COLOR_BYTE         equ (TETRIS_RENDER_BORDER_COLOR shl 6) or (TETRIS_RENDER_BORDER_COLOR shl 4) or (TETRIS_RENDER_BORDER_COLOR shl 2) or TETRIS_RENDER_BORDER_COLOR
else
TETRIS_RENDER_BORDER_COLOR_BYTE         equ (TETRIS_RENDER_BORDER_COLOR shl 6) or (TETRIS_BLOCK_COLOR_BKGRND shl 4) or (TETRIS_RENDER_BORDER_COLOR shl 2) or TETRIS_BLOCK_COLOR_BKGRND
endif
TETRIS_RENDER_BORDER_COLOR_WORD         equ TETRIS_RENDER_BORDER_COLOR_BYTE or (TETRIS_RENDER_BORDER_COLOR_BYTE shl 8)
TETRIS_RENDER_BLOCK_WIDTH_IN_BITS       equ TETRIS_BLOCK_SIZE * BIOS_VIDEO_MODE_320_200_4_BITS_P_PIXEL
.erre TETRIS_RENDER_BLOCK_WIDTH_IN_BITS eq 16
TETRIS_RENDER_BLOCK_WIDTH_IN_BYTES      equ TETRIS_RENDER_BLOCK_WIDTH_IN_BITS / 8
.erre TETRIS_RENDER_BLOCK_WIDTH_IN_BYTES eq 2
TETRIS_FALLING_PIECE_SPEED_X_LOHI       equ 00040h
TETRIS_FALLING_PIECE_SPEED_Y_LOHI       equ 00010h
TETRIS_KEY_MOVE_PIECE_LEFT			    equ BIOS_KEYBOARD_SCANCODE_ARROW_LEFT
TETRIS_KEY_MOVE_PIECE_RIGHT				equ BIOS_KEYBOARD_SCANCODE_ARROW_RIGHT
TETRIS_KEY_DROP_PIECE                   equ BIOS_KEYBOARD_SCANCODE_ARROW_DOWN
TETRIS_LEVEL_STATE_PLAY                 equ 0
TETRIS_LEVEL_STATE_ANIM                 equ 1
TETRIS_LEVEL_STATE_OVER                 equ 2
TETRIS_LEVEL_STATE_ANIM_FRAMES_LEFT     equ 25

TetrisBlockColor struct
    Limit       word ?
    Center      word ?
TetrisBlockColor ends

TETRIS_BLOCK_COLOR macro aIdStr:req, aLimitColor:req, aCenterColor:req
    .erre aLimitColor lt BIOS_VIDEO_MODE_320_200_4_COLOR_COUNT
    .erre aCenterColor lt BIOS_VIDEO_MODE_320_200_4_COLOR_COUNT
    TetrisBlockIdColor&aIdStr   label TetrisBlockColor
                                ; Limit left.
                                byte (aLimitColor shl 6) or (aLimitColor shl 4) or (aLimitColor shl 2) or aLimitColor
                                ; Limit right.
                                byte (aLimitColor shl 6) or (aLimitColor shl 4) or (aLimitColor shl 2) or aLimitColor
                                ; Center left.
                                byte (aLimitColor shl 6) or (aCenterColor shl 4) or (aCenterColor shl 2) or aCenterColor
                                ; Center right. 
                                byte (aCenterColor shl 6) or (aCenterColor shl 4) or (aCenterColor shl 2) or aLimitColor
endm

if TETRIS_BOARD_INIT_BLOCKS
TetrisBoardInitBlock struct
    BlockId     byte ?
    Col         byte ?
    Row         byte ?
TetrisBoardInitBlock ends
endif

code segment readonly public

;-------------;
; Code public ;
;-------------;

; Clobber: everything.
tetrisStart proc
    .erre (lengthof TetrisBoardBlockIdRowAddrs) eq (lengthof TetrisBoardBlockRowVideoBankOffsets)
    
    mov ax,offset TetrisBoardBlockIds
    mov cx,lengthof TetrisBoardBlockIdRowAddrs 
    mov di,offset TetrisBoardBlockIdRowAddrs
@@:
    stosw
    add ax,TETRIS_BOARD_COLS
    loop short @b

    mov ax,TETRIS_RENDER_BOARD_BANK_OFFSET
    mov cx,lengthof TetrisBoardBlockRowVideoBankOffsets
    mov di,offset TetrisBoardBlockRowVideoBankOffsets
@@:
    stosw
    add ax,TETRIS_BLOCK_HALF_SIZE * BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE
    loop short @b

    ret
tetrisStart endp

; Clobber: everything.
tetrisInit proc
    mov [TetrisLevelState],TETRIS_LEVEL_STATE_PLAY
    mov [TetrisLevelNextStateSet],0
    mov [TetrisFallingPieceBlockId],TETRIS_BOARD_BLOCK_ID_MASK
    call tetrisBoardInitFallingPiece
    ; Empty the board.
    mov ax,TETRIS_BOARD_BLOCK_ID_EMPTY or (TETRIS_BOARD_BLOCK_ID_EMPTY shl 8)
    .errnz TETRIS_BOARD_COUNT and 1
    mov cx,(TETRIS_BOARD_COUNT shr 1)
    mov di,offset TetrisBoardBlockIds
    rep stosw
if TETRIS_BOARD_INIT_BLOCKS
    mov di,offset TetrisBoardInitBlocks
@@:
    cmp di,offset TetrisBoardInitBlocksEnd
    je short @f
    mov al,[di].TetrisBoardInitBlock.BlockId
    mov ch,[di].TetrisBoardInitBlock.Col
    mov dh,[di].TetrisBoardInitBlock.Row
    call tetrisBoardSetBlockId
    add di,sizeof TetrisBoardInitBlock
    jmp short @b
@@:
endif
    ret
tetrisInit endp

; Clobber: everything.
tetrisInitRender proc
    mov ax,TETRIS_RENDER_BORDER_COLOR_WORD
    ; Top border, renders on an odd line.
    mov cx,TETRIS_BOARD_COLS
    mov di,BIOS_VIDEO_MODE_320_200_4_BANK1_OFFSET + TETRIS_RENDER_BOARD_BANK_OFFSET - BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE
    rep stosw
    ; Bottom border, renders on an even line.
    mov cx,TETRIS_BOARD_COLS
    mov di,TETRIS_RENDER_BOARD_BANK_OFFSET + (TETRIS_BOARD_ROWS * TETRIS_BLOCK_HALF_SIZE * BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE)
    rep stosw
    ; Left border, even lines.
    mov al,(TETRIS_BLOCK_COLOR_BKGRND shl 6) or (TETRIS_BLOCK_COLOR_BKGRND shl 4) or (TETRIS_BLOCK_COLOR_BKGRND shl 2) or TETRIS_RENDER_BORDER_COLOR
    mov cx,TETRIS_BOARD_ROWS * TETRIS_BLOCK_HALF_SIZE
    mov di,TETRIS_RENDER_BOARD_BANK_OFFSET - 1
@@:
    stosb
    add di,BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE - 1
    loop short @b
if TETRIS_RENDER_BORDER_USE_SOLID_COLOR
    ; Left border, odd lines.
    mov cx,TETRIS_BOARD_ROWS * TETRIS_BLOCK_HALF_SIZE
    mov di,BIOS_VIDEO_MODE_320_200_4_BANK1_OFFSET + TETRIS_RENDER_BOARD_BANK_OFFSET - 1
@@:
    stosb
    add di,BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE - 1
    loop short @b
endif        
    ; Right border, even lines.
    mov al,(TETRIS_RENDER_BORDER_COLOR shl 6) or (TETRIS_BLOCK_COLOR_BKGRND shl 4) or (TETRIS_BLOCK_COLOR_BKGRND shl 2) or TETRIS_BLOCK_COLOR_BKGRND
    mov cx,TETRIS_BOARD_ROWS * TETRIS_BLOCK_HALF_SIZE
    mov di,TETRIS_RENDER_BOARD_BANK_OFFSET + (TETRIS_RENDER_BLOCK_WIDTH_IN_BYTES * TETRIS_BOARD_COLS)
@@:
    stosb
    add di,BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE - 1
    loop short @b
if TETRIS_RENDER_BORDER_USE_SOLID_COLOR        
    ; Right border, odd lines.
    mov cx,TETRIS_BOARD_ROWS * TETRIS_BLOCK_HALF_SIZE
    mov di,BIOS_VIDEO_MODE_320_200_4_BANK1_OFFSET + TETRIS_RENDER_BOARD_BANK_OFFSET + (TETRIS_RENDER_BLOCK_WIDTH_IN_BYTES * TETRIS_BOARD_COLS)
@@:
    stosb
    add di,BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE - 1
    loop short @b
endif
if TETRIS_BOARD_INIT_BLOCKS
    mov si,offset TetrisBoardInitBlocks
@@:
    cmp si,offset TetrisBoardInitBlocksEnd
    je short @f
    mov al,[si].TetrisBoardInitBlock.BlockId
    mov cl,[si].TetrisBoardInitBlock.Col
    mov dl,[si].TetrisBoardInitBlock.Row
    call tetrisRenderBlock
    add si,sizeof TetrisBoardInitBlock
    jmp short @b
@@:
endif
if CONSOLE_ENABLED
    call tetrisInitRenderDebug
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
if CONSOLE_ENABLED
    call tetrisRenderDebug
endif
    ; Render state.
    mov al,[TetrisLevelState]
    cmp al,TETRIS_LEVEL_STATE_PLAY
    jne short @f
    jmp tetrisRenderLevelStatePlay
@@:
    cmp al,TETRIS_LEVEL_STATE_ANIM
    jne short @f
    jmp tetrisRenderLevelStateAnim
@@:
    jmp tetrisRenderLevelStateOver
tetrisRender endp

;--------------;
; Code private ;
;--------------;

; Input: al (next state).
tetrisSetLevelNextState proc private
if ASSERT_ENABLED
    ; The next state should be set only once per frame.
    cmp [TetrisLevelNextStateSet],0
    je short @f
    ASSERT
@@:
endif
    mov [TetrisLevelNextStateSet],1
    mov [TetrisLevelNextState],al
    ret
tetrisSetLevelNextState endp

; Input: ch (col), dh (row).
; Output: bx (addr).
; Clobber: si.
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
    xor bh,bh
    mov bl,dh
    shl bl,1
    mov si,[TetrisBoardBlockIdRowAddrs+bx]
    mov bl,ch
    add bx,si
    ret
tetrisBoardGetBlockAddr endp

; Input: ch (col), dh (row).
; Output: zf (set if true).
; Clobber: bx, si.
tetrisBoardGetBlockIsEmpty proc private
    call tetrisBoardGetBlockAddr
    cmp byte ptr [bx],TETRIS_BOARD_BLOCK_ID_EMPTY
    ret
tetrisBoardGetBlockIsEmpty endp

; Input: al (block id), ch (col), dh (row).
; Clobber: bx, si.
tetrisBoardSetBlockId proc private
if ASSERT_ENABLED
    cmp al,TETRIS_BOARD_BLOCK_ID_COUNT
    jb short @f
    ASSERT
@@:
endif
    call tetrisBoardGetBlockAddr
    mov [bx],al
    ret
tetrisBoardSetBlockId endp

; Output: al (block id), cx (colLOHI), dx (rowLOHI).
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
    ; Save falling piece previous pos.
    mov cx,[TetrisFallingPieceCol]
    mov [TetrisFallingPiecePrevColHI],ch
    mov dx,[TetrisFallingPieceRow]
    mov [TetrisFallingPiecePrevRowHI],dh

    ; Check both left and right keys before deciding if there should be horizontal movement.
    xor al,al
  	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_MOVE_PIECE_LEFT
	jnz short @f
    dec al
@@:
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_MOVE_PIECE_RIGHT
    jnz short @f
    inc al
@@:
    .erre TETRIS_FALLING_PIECE_SPEED_X_LOHI le 100h
    ; Moved left?
	cmp al,0ffh
	jne short @f
    sub cx,TETRIS_FALLING_PIECE_SPEED_X_LOHI
    ; Moved past the left border?
    cmp ch,TETRIS_BOARD_COLS
    jae short moveBackRight
    ; Hit a block?
    call tetrisBoardGetBlockIsEmpty
	jz short @f
moveBackRight:
    ; Move back to the previous col.
    inc ch
    xor cl,cl
@@:
    ; Moved right?
	cmp al,1
    jne short @f
    add cx,TETRIS_FALLING_PIECE_SPEED_X_LOHI
    ; Moved past the right border?
    cmp ch,TETRIS_BOARD_COLS
    jae short moveBackLeft
    ; Hit a block?
    call tetrisBoardGetBlockIsEmpty
	jz short @f
moveBackLeft:
    ; Move back to the previous col.
    dec ch
    mov cl,0ffh
@@:

    ; Vertical movement.
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_DROP_PIECE
	jnz short @f
    ; Keep moving down, one row at a time until a piece or the board's end is found.
    call tetrisBoardGetBlockAddr
nextRow:
    inc dh
    ; Moved past the board's end?
    cmp dh,TETRIS_BOARD_ROWS
    jae short addPieceToBoard
    add bx,TETRIS_BOARD_COLS
    ; Found a piece?
    cmp byte ptr [bx],TETRIS_BOARD_BLOCK_ID_EMPTY
    je short nextRow
    jmp short addPieceToBoard
@@:
    ; If the piece was not dropped, use its speed to move it down.
    .erre TETRIS_FALLING_PIECE_SPEED_Y_LOHI le 100h
    add dx,TETRIS_FALLING_PIECE_SPEED_Y_LOHI
    ; Moved past the board's end?
    cmp dh,TETRIS_BOARD_ROWS
    jae short addPieceToBoard
    ; Found a piece?
    call tetrisBoardGetBlockIsEmpty
	jz short @f
addPieceToBoard:
    ; Decrement row so we go back to the empty cell above this one.
    dec dh
    mov al,[TetrisFallingPieceBlockId]
    call tetrisBoardSetBlockId
    mov al,TETRIS_LEVEL_STATE_ANIM
    call tetrisSetLevelNextState
    mov [TetrisLevelStateAnimFramesLeft],TETRIS_LEVEL_STATE_ANIM_FRAMES_LEFT
@@:

    ; Set new falling piece pos.
    mov [TetrisFallingPieceCol],cx
    mov [TetrisFallingPieceRow],dx
    ret
tetrisUpdateLevelStatePlay endp

; Clobber: everything.
tetrisUpdateLevelStateAnim proc private
    ; Is this the first frame of the state?
    cmp [TetrisLevelStateAnimFramesLeft],TETRIS_LEVEL_STATE_ANIM_FRAMES_LEFT
    jne short skipFirstFrame
    mov dh,TETRIS_BOARD_ROWS
    ; Check if the row is full.
    mov dl,[TetrisFallingPieceRowHI]
    mov bl,dl
    xor bh,bh
    shl bl,1
    mov bx,[TetrisBoardBlockIdRowAddrs+bx]
    mov ax,TETRIS_BOARD_BLOCK_ID_EMPTY or (TETRIS_BOARD_BLOCK_ID_EMPTY shl 8)
    mov cx,TETRIS_BOARD_COLS
    mov di,bx
    repne scasb
    je short clearDone
    ; If row is full, clear it.
if 0
    ; Disable this code temporarily, since the matching code to render the blocks that moved is not done yet.
@@:
    .erre offset TetrisBoardBlockIds gt TETRIS_BOARD_COLS
    lea si,[bx-TETRIS_BOARD_COLS]
    cmp si,offset TetrisBoardBlockIds
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
    mov cx,TETRIS_BOARD_HALF_COLS
    mov di,bx
    rep stosw
    mov dh,dl
clearDone:
    mov [TetrisLevelStateAnimRowToClear],dh
skipFirstFrame:
    ; Is this the last frame of the state?
    dec [TetrisLevelStateAnimFramesLeft]
    jnz short done
    ; Set next state, either the game continues or it's over.
    call tetrisBoardInitFallingPiece
    call tetrisBoardGetBlockIsEmpty
    mov al,TETRIS_LEVEL_STATE_PLAY
	jz short @f
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
    mov dl,[TetrisLevelStateAnimRowToClear]
    cmp dl,TETRIS_BOARD_ROWS
    je short done
    xor cl,cl    
    mov al,[TetrisLevelStateAnimFramesLeft]
    ; Is this the first render frame of the state?
    .erre TETRIS_LEVEL_STATE_ANIM_FRAMES_LEFT gt 1
    cmp al,TETRIS_LEVEL_STATE_ANIM_FRAMES_LEFT - 1
    jne short skipHighlight
    call tetrisRenderGetBlockVideoBankOffset
    mov ax,TETRIS_BOARD_BLOCK_HIGHLIGHT_COLOR_WORD
@@:
    ; Render even lines.
repeat TETRIS_BLOCK_HALF_SIZE - 1
    mov cx,TETRIS_BOARD_COLS
    rep stosw
    add di,BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE - (TETRIS_BOARD_COLS shl 1)
endm
    mov cx,TETRIS_BOARD_COLS
    rep stosw
    add di,BIOS_VIDEO_MODE_320_200_4_BANK1_OFFSET - (TETRIS_BOARD_COLS shl 1) - ((TETRIS_BLOCK_HALF_SIZE - 1) * BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE)
    ; Render odd lines.
repeat TETRIS_BLOCK_HALF_SIZE - 1
    mov cx,TETRIS_BOARD_COLS
    rep stosw
    add di,BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE - (TETRIS_BOARD_COLS shl 1)
endm
    mov cx,TETRIS_BOARD_COLS
    rep stosw
    jmp short done
skipHighlight:
    ; Is this the last render frame of the state?
    cmp al,0
    jne short done
    ; Is this check necessary or an assert is enough?
    cmp [TetrisLevelNextState],TETRIS_LEVEL_STATE_PLAY
    jne short done
    ; This code should redraw the pieces that moved instead of clearing the current row.
    call tetrisRenderGetBlockVideoBankOffset
    xor ah,ah
    jmp short @b
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

; Input: cl (col), dl (row).
; Output: di (video bank offset).
; Clobber: bx.
tetrisRenderGetBlockVideoBankOffset proc private
if ASSERT_ENABLED
    cmp cl,TETRIS_BOARD_COLS
    jb short @f
    ASSERT
@@:
    cmp dl,TETRIS_BOARD_ROWS
    jb short @f
    ASSERT
@@:
endif
    xor bh,bh
    mov bl,dl
    shl bl,1
    mov di,[TetrisBoardBlockRowVideoBankOffsets+bx]
    ; Each col is 8 pixels, an a pixel is 2 bits, so one word per col.
    mov bl,cl
    shl bl,1
    add di,bx
    ret
tetrisRenderGetBlockVideoBankOffset endp

; Input: al (block id), cl (col), dl (row).
; Clobber: ax, bx, di, bp.
tetrisRenderBlock proc private
if ASSERT_ENABLED
    cmp al,TETRIS_BOARD_BLOCK_ID_COUNT
    jb short @f
    ASSERT
@@:
endif
    call tetrisRenderGetBlockVideoBankOffset
    ; Set bx to the correct offset into the color array.
    xor bh,bh
    mov bl,al
    .erre sizeof TetrisBlockColor eq 4
    shl bl,1
    ; Can avoid this extra shift with two separate arrays for the colors, but this setup makes it easier to define the colors, might change it later.
    shl bl,1
    mov ax,[TetrisBlockColors+bx].TetrisBlockColor.Limit
    mov bp,ax

    ; Render even lines.
    stosw
    add di,BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE - TETRIS_RENDER_BLOCK_WIDTH_IN_BYTES
    mov ax,[TetrisBlockColors+bx].TetrisBlockColor.Center
repeat TETRIS_BLOCK_HALF_SIZE - 2
    stosw
    add di,BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE - TETRIS_RENDER_BLOCK_WIDTH_IN_BYTES
endm
    stosw

    ; Render odd lines.
    add di,(BIOS_VIDEO_MODE_320_200_4_BANK1_OFFSET - TETRIS_RENDER_BLOCK_WIDTH_IN_BYTES) - ((TETRIS_BLOCK_HALF_SIZE - 1) * BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE)
repeat TETRIS_BLOCK_HALF_SIZE - 1
    stosw
    add di,BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE - TETRIS_RENDER_BLOCK_WIDTH_IN_BYTES
endm
    mov ax,bp
    stosw

    ret
tetrisRenderBlock endp

if CONSOLE_ENABLED
; Clobber: everything.
tetrisInitRenderDebug proc private
    CONSOLE_SET_CURSOR_COL_ROW 0, 0
	mov si,offset allSegments:strLeft
	call consolePrintString
    CONSOLE_SET_CURSOR_COL_ROW 0, 1
	mov si,offset allSegments:strRight
	call consolePrintString
    CONSOLE_SET_CURSOR_COL_ROW 0, 2
	mov si,offset allSegments:strDrop
	call consolePrintString
    CONSOLE_SET_CURSOR_COL_ROW 0, 3
	mov si,offset allSegments:strCol
	call consolePrintString
    CONSOLE_SET_CURSOR_COL_ROW 6, 3
	mov al,","
	call consolePrintChar
    CONSOLE_SET_CURSOR_COL_ROW 0, 4
	mov si,offset allSegments:strRow
	call consolePrintString
    CONSOLE_SET_CURSOR_COL_ROW 6, 4
	mov al,","
	call consolePrintChar
    ret
strLeft:
    byte "Lft:", 0
strRight:
    byte "Rth:", 0
strDrop:
    byte "Drp:", 0
strCol:
    byte "Col:", 0
strRow:
    byte "Row:", 0
tetrisInitRenderDebug endp

; Clobber: everything.
tetrisRenderDebug proc private
    ; Technically I should store if the keys were pressed in variables, but it doesn't matter for a debug feature.
	CONSOLE_SET_CURSOR_COL_ROW 4, 0
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_MOVE_PIECE_LEFT
	call consolePrintZeroFlag
	CONSOLE_SET_CURSOR_COL_ROW 4, 1
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_MOVE_PIECE_RIGHT
    call consolePrintZeroFlag
	CONSOLE_SET_CURSOR_COL_ROW 4, 2
	KEYBOARD_IS_KEY_PRESSED TETRIS_KEY_DROP_PIECE
    call consolePrintZeroFlag
    CONSOLE_SET_CURSOR_COL_ROW 7, 3    
    mov ax,[TetrisFallingPieceCol]
    call consolePrintByteHex
    CONSOLE_SET_CURSOR_COL_ROW 4, 3
    mov al,ah
    call consolePrintByteHex
    CONSOLE_SET_CURSOR_COL_ROW 7, 4
    mov ax,[TetrisFallingPieceRow]
    call consolePrintByteHex
    CONSOLE_SET_CURSOR_COL_ROW 4, 4
    mov al,ah
    call consolePrintByteHex
    ret
tetrisRenderDebug endp
endif

code ends

constData segment readonly public
    TetrisBlockColors label TetrisBlockColor
                      ; IdStr,                LimitColor,               CenterColor.
    TETRIS_BLOCK_COLOR      0,  TETRIS_BLOCK_COLOR_GREEN,    TETRIS_BLOCK_COLOR_RED
    TETRIS_BLOCK_COLOR      1,  TETRIS_BLOCK_COLOR_GREEN, TETRIS_BLOCK_COLOR_YELLOW
    TETRIS_BLOCK_COLOR      2,    TETRIS_BLOCK_COLOR_RED, TETRIS_BLOCK_COLOR_BKGRND
    TETRIS_BLOCK_COLOR      3,    TETRIS_BLOCK_COLOR_RED,  TETRIS_BLOCK_COLOR_GREEN
    TETRIS_BLOCK_COLOR      4,    TETRIS_BLOCK_COLOR_RED, TETRIS_BLOCK_COLOR_YELLOW
    TETRIS_BLOCK_COLOR      5, TETRIS_BLOCK_COLOR_YELLOW, TETRIS_BLOCK_COLOR_BKGRND
    TETRIS_BLOCK_COLOR      6, TETRIS_BLOCK_COLOR_YELLOW,  TETRIS_BLOCK_COLOR_GREEN
    TETRIS_BLOCK_COLOR      7, TETRIS_BLOCK_COLOR_YELLOW,    TETRIS_BLOCK_COLOR_RED
    TETRIS_BLOCK_COLOR  Empty, TETRIS_BLOCK_COLOR_BKGRND, TETRIS_BLOCK_COLOR_BKGRND
                                            
if TETRIS_BOARD_INIT_BLOCKS
    TetrisBoardInitBlocks label TetrisBoardInitBlock
                                                       ; BlockId, Col, Row.
    TetrisBoardInitBlockHorizLine0      TetrisBoardInitBlock { 3,   0,  19 }
                                        TetrisBoardInitBlock { 3,   1,  19 }
                                        TetrisBoardInitBlock { 3,   2,  19 }
                                        TetrisBoardInitBlock { 3,   3,  19 }
    TetrisBoardInitBlockShape0          TetrisBoardInitBlock { 1,   1,  18 }
                                        TetrisBoardInitBlock { 1,   2,  17 }
                                        TetrisBoardInitBlock { 1,   2,  18 }
                                        TetrisBoardInitBlock { 1,   3,  17 }
    TetrisBoardInitBlockShape1          TetrisBoardInitBlock { 0,   4,  17 }
                                        TetrisBoardInitBlock { 0,   3,  18 }
                                        TetrisBoardInitBlock { 0,   4,  18 }
                                        TetrisBoardInitBlock { 0,   4,  19 }
    TetrisBoardInitBlockShape2          TetrisBoardInitBlock { 4,   6,  17 }
                                        TetrisBoardInitBlock { 4,   7,  17 }
                                        TetrisBoardInitBlock { 4,   6,  18 }
                                        TetrisBoardInitBlock { 4,   6,  19 }
    TetrisBoardInitBlockCube0           TetrisBoardInitBlock { 1,   7,  18 }
                                        TetrisBoardInitBlock { 1,   8,  18 }
                                        TetrisBoardInitBlock { 1,   7,  19 }
                                        TetrisBoardInitBlock { 1,   8,  19 }
    TetrisBoardInitBlockShape3          TetrisBoardInitBlock { 0,   8,  17 }
                                        TetrisBoardInitBlock { 0,   9,  17 }
                                        TetrisBoardInitBlock { 0,   9,  18 }
                                        TetrisBoardInitBlock { 0,   9,  19 }
    TetrisBoardInitBlocksEnd label TetrisBoardInitBlock
endif
constData ends

data segment public
    TetrisLevelState                    byte ?
    TetrisLevelNextStateSet             byte ?
    TetrisLevelNextState                byte ?
    TetrisLevelStateAnimFramesLeft      byte ?
    TetrisLevelStateAnimRowToClear      byte ?
    TetrisFallingPieceBlockId           byte ?
    TetrisFallingPieceCol               label word
    TetrisFallingPieceColLO             byte ?
    TetrisFallingPieceColHI             byte ?
    TetrisFallingPieceRow               label word
    TetrisFallingPieceRowLO             byte ?
    TetrisFallingPieceRowHI             byte ?
    TetrisFallingPiecePrevColHI         byte ?
    TetrisFallingPiecePrevRowHI         byte ?
    ; Align array to a word boundary so the initialization code can run faster on the 80286 and up. But maybe it's better to have separate data segments for bytes and words.
    align word
    TetrisBoardBlockIdRowAddrs          word TETRIS_BOARD_ROWS dup(?)
    TetrisBoardBlockRowVideoBankOffsets word TETRIS_BOARD_ROWS dup(?)
    TetrisBoardBlockIds                 byte TETRIS_BOARD_COUNT dup(?)
data ends

end
