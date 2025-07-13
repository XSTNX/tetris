include code\player.inc
include code\console.inc
include code\keyboard.inc
include code\render.inc

; Config.
if KEYBOARD_ENABLED
PLAYER_AUTO_MOVE                equ 0
else
PLAYER_AUTO_MOVE                equ 1
endif
PLAYER_USE_TILES				equ 1

; Constants.
PLAYER_WIDTH                    equ 8
PLAYER_HALF_WIDTH 			    equ PLAYER_WIDTH / 2
PLAYER_HEIGHT 				    equ 8
PLAYER_HALF_HEIGHT 			    equ PLAYER_HEIGHT / 2
PLAYER_POSX_LIMIT_LOW 			equ 30
PLAYER_POSX_LIMIT_HIGH 			equ BIOS_VIDEO_MODE_320_200_4_WIDTH - PLAYER_POSX_LIMIT_LOW
PLAYER_POSX_START 				equ BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH
PLAYER_POSY                     equ BIOS_VIDEO_MODE_320_200_4_HEIGHT - PLAYER_HALF_HEIGHT - 5
PLAYER_POSY_LOW					equ PLAYER_POSY - PLAYER_HALF_HEIGHT
PLAYER_SPEEDX_BYTE_FRACTION		equ 0
.erre PLAYER_SPEEDX_BYTE_FRACTION lt 256
PLAYER_SPEEDX	 				equ 5
PLAYER_SHOT_WIDTH				equ 2
PLAYER_SHOT_HALF_WIDTH			equ PLAYER_SHOT_WIDTH / 2
PLAYER_SHOT_HEIGHT				equ 6
PLAYER_SHOT_HALF_HEIGHT			equ PLAYER_SHOT_HEIGHT / 2
PLAYER_SHOT_POSY_START 			equ PLAYER_POSY_LOW - PLAYER_SHOT_HALF_HEIGHT
PLAYER_SHOT_POSY_START_PACKED 	equ PLAYER_SHOT_POSY_START * 256
PLAYER_SHOT_SPEED_PACKED        equ 400h
PLAYER_SHOT_COOLDOWN 			equ 10
PLAYER_SHOT_MAX_COUNT 			equ 5
.erre PLAYER_SHOT_MAX_COUNT lt 128
PLAYER_RENDER_DELETE_MAX_COUNT	equ PLAYER_SHOT_MAX_COUNT * 2
PLAYER_KEY_LEFT					equ BIOS_KEYBOARD_SCANCODE_ARROW_LEFT
PLAYER_KEY_RIGHT				equ BIOS_KEYBOARD_SCANCODE_ARROW_RIGHT
PLAYER_KEY_SHOOT				equ BIOS_KEYBOARD_SCANCODE_LEFT_SHIFT

allSegments group code, constData, data
    assume cs:allSegments, ds:allSegments, es:nothing

code segment readonly public

;-------------;
; Code public ;
;-------------;

; Clobber: everything.
playerInit proc
	xor ax,ax
	mov [PlayerShotCount],ax
	mov [PlayerRenderDeleteCount],ax
	mov [PlayerShotCooldown],al
	mov [PlayerPosXByteFraction],al
	; Zero out both PlayerRenderDeleteWidth and PlayerRenderDeleteHeight
	mov cx,2 * PLAYER_RENDER_DELETE_MAX_COUNT
	mov di,offset PlayerRenderDeleteWidth
	rep stosw

	mov ax,PLAYER_POSX_START
	mov [PlayerPosX],ax
	mov [PlayerPrevPosX],ax

if PLAYER_AUTO_MOVE
	mov [PlayerAutoMoveDir],1
endif
	ret
playerInit endp

; Clobber: everything.
playerUpdate proc
	mov ax,ds
	mov es,ax

	; Save prev posX.
	mov ax,[PlayerPosX]
	mov [PlayerPrevPosX],ax

	; Update cooldown.
	mov al,[PlayerShotCooldown]
	test al,al
	jz short skipShotCoolDownDecrement
	dec ax
	mov [PlayerShotCooldown],al
skipShotCoolDownDecrement:

	; Update shots.
	mov cx,[PlayerShotCount]
	jcxz short loopShotDone
	mov dx,PLAYER_SHOT_SPEED_PACKED
	mov si,offset allSegments:PlayerShotPosYPacked
	mov di,si
loopShot:
	lodsw
	cmp ax,dx
	jb short loopDelete
	mov byte ptr [(PlayerShotPrevPosY - PlayerShotPosYPacked) + di],ah
	sub ax,dx
	stosw
	jmp short loopShotNext
loopDelete:
	call playerDeleteShot
	dec si
	dec si
	mov di,si
loopShotNext:
	loop loopShot
loopShotDone:

if PLAYER_AUTO_MOVE
	; Check current direction of movement.
	mov al,[PlayerAutoMoveDir]
	cmp al,1
	jne short autoMoveLeft
	; Check if need to flip direction left.
	cmp [PlayerPosX],PLAYER_POSX_LIMIT_HIGH
	jne short autoMoveDone
	dec ax
	dec ax
	mov [PlayerAutoMoveDir],al
	jmp short autoMoveDone
autoMoveLeft:
	; Check if need to flip direction right.
	cmp [PlayerPosX],PLAYER_POSX_LIMIT_LOW
	jne short autoMoveDone
	inc ax
	inc ax
	mov [PlayerAutoMoveDir],al
autoMoveDone:
	; Check if need to flip direction to right.
else
	; Read keyboard and store the direction of movement in al.
	xor al,al
	KEYBOARD_IS_KEY_PRESSED PLAYER_KEY_LEFT
	jnz short skipKeyLeftPressed
	dec ax
skipKeyLeftPressed:
	KEYBOARD_IS_KEY_PRESSED PLAYER_KEY_RIGHT
	jnz short skipKeyRightPressed
	inc ax
skipKeyRightPressed:
endif

	; Move left.
	cmp al,0ffh
	jne short skipMoveLeft
	; Compute new posX.
	mov cl,[PlayerPosXByteFraction]
	sub cl,PLAYER_SPEEDX_BYTE_FRACTION
	mov dx,[PlayerPosX]
	sbb dx,PLAYER_SPEEDX
	; Limit posX if needed.
	cmp dx,PLAYER_POSX_LIMIT_LOW
	jae short skipLimitPosXLeft
	xor cl,cl
	mov dx,PLAYER_POSX_LIMIT_LOW
skipLimitPosXLeft:
	; Save new posX.
	mov [PlayerPosXByteFraction],cl
	mov [PlayerPosX],dx
	; No need to check if moved right.
	jmp short [skipMoveRight]
skipMoveLeft:

	; Move right.
	cmp al,1
	jne short skipMoveRight
	; Compute new posX.
	mov cl,[PlayerPosXByteFraction]
	add cl,PLAYER_SPEEDX_BYTE_FRACTION
	mov dx,[PlayerPosX]
	adc dx,PLAYER_SPEEDX
	; Limit posX if needed.
	cmp dx,PLAYER_POSX_LIMIT_HIGH
	jb short skipLimitPosXRight
	xor cl,cl
	mov dx,PLAYER_POSX_LIMIT_HIGH
skipLimitPosXRight:
	; Save new posX.
	mov [PlayerPosXByteFraction],cl
	mov [PlayerPosX],dx
skipMoveRight:

	; Shoot.
ife PLAYER_AUTO_MOVE
	KEYBOARD_IS_KEY_PRESSED PLAYER_KEY_SHOOT
	jnz short skipShot
endif
	mov ax,[PlayerShotCount]
	cmp al,PLAYER_SHOT_MAX_COUNT
	je short skipShot
	cmp [PlayerShotCooldown],0
	jne short skipShot
	mov [PlayerShotCooldown],PLAYER_SHOT_COOLDOWN
	; Don't need to read this again if dx is not overriden.
	mov dx,[PlayerPosX]
	mov di,ax
	shl di,1
	mov [PlayerShotPosX + di],dx
	mov [PlayerShotPosYPacked + di],PLAYER_SHOT_POSY_START_PACKED
	; If the shot was updated after this, setting prev pos wouldn't be needed, is it worth doing?
	mov byte ptr [PlayerShotPrevPosY + di],PLAYER_SHOT_POSY_START
	inc ax
	mov byte ptr [PlayerShotCount],al
skipShot:

	ret
playerUpdate endp

; Clobber: everything.
playerRender proc
	; Clear deleted sprites.
	mov cx,[PlayerRenderDeleteCount]
	jcxz short loopDeleteDone
	xor di,di
loopDelete:
	push cx
		
	mov cx,[PlayerRenderDeletePosX + di]
	mov bx,cx
	add bx,[PlayerRenderDeleteWidth + di]
	mov dl,byte ptr [PlayerRenderDeletePosY + di]
	mov dh,dl
	add dh,byte ptr [PlayerRenderDeleteHeight + di]
	xor al,al
	call renderRect320x200x4

	inc di
	inc di
	pop cx
	loop loopDelete
	
	; Set delete count back to zero.
	mov byte ptr [PlayerRenderDeleteCount],cl
loopDeleteDone:

	; Render shots.
	mov cx,[PlayerShotCount]
	jcxz short loopShotDone
	xor bx,bx
loopShot:
	push cx

if 0;PLAYER_USE_TILES
	mov bp,di
	; Erase previous shot.
	mov cx,[PlayerShotPosX + bx]
	sub cx,4
	mov dl,byte ptr [PlayerShotPrevPosY + bx]
	sub dl,4
	call renderEmptyTile8x8

	mov di,bp
	; Draw current shot.
	mov cx,[PlayerShotPosX + bx]
	sub cx,4
	mov dl,byte ptr [(PlayerShotPosYPacked + 1) + bx]
	sub dl,4
	mov si,offset PlayerShotGfx0
	call renderTile8x8
	mov di,bp
else
	push bx

	; Erase previous shot.
	mov cx,[PlayerShotPosX + bx]
	sub cx,PLAYER_SHOT_HALF_WIDTH
	mov di,cx
	add di,PLAYER_SHOT_WIDTH
	mov dl,byte ptr [PlayerShotPrevPosY + bx]
	sub dl,PLAYER_SHOT_HALF_HEIGHT
	mov bl,dl
	add bl,PLAYER_SHOT_HEIGHT
	xor dh,dh
    ; Keep lowY within screen bounds.
    cmp dl,BIOS_VIDEO_MODE_320_200_4_HEIGHT
    jb short @f
    xor dl,dl
@@:
	call renderRect320x200x4
	
	pop bx
	push bx
	; Draw current shot.
	mov cx,[PlayerShotPosX + bx]
	sub cx,PLAYER_SHOT_HALF_WIDTH
	mov di,cx
	add di,PLAYER_SHOT_WIDTH
	mov dl,byte ptr [(PlayerShotPosYPacked + 1) + bx]
	sub dl,PLAYER_SHOT_HALF_HEIGHT
	mov bl,dl
	add bl,PLAYER_SHOT_HEIGHT
	mov dh,1
    ; Keep lowY within screen bounds.
    cmp dl,BIOS_VIDEO_MODE_320_200_4_HEIGHT
    jb short @f
    xor dl,dl
@@:	
	call renderRect320x200x4

	pop bx
endif

	inc bx
	inc bx
	pop cx
	loop loopShot
loopShotDone:

	; Erase previous player.
	mov cx,[PlayerPrevPosX]
	sub cx,PLAYER_HALF_WIDTH
	mov dl,PLAYER_POSY_LOW
	call renderEmptyTile8x8

	; Draw current player.
	mov cx,[PlayerPosX]
	sub cx,PLAYER_HALF_WIDTH
	mov dl,PLAYER_POSY_LOW
	; Select the proper bitmap based on posLeft mod 4.
	mov si,cx
	and si,11b
	shl si,1
	mov si,[si+offset allSegments:PlayerGfx]
	call renderTile8x8

if CONSOLE_ENABLED
	call playerDebugPrintKeyboard
	call playerDebugPrintPlayer
	call playerDebugPrintShot
endif

	ret
playerRender endp

;--------------;
; Code private ;
;--------------;

if CONSOLE_ENABLED

playerDebugPrintKeyboard proc private
	CONSOLE_SET_CURSOR_COL_ROW 0, 0
	KEYBOARD_IS_KEY_PRESSED PLAYER_KEY_LEFT
	call consolePrintZeroFlag
	KEYBOARD_IS_KEY_PRESSED PLAYER_KEY_RIGHT
	call consolePrintZeroFlag
	KEYBOARD_IS_KEY_PRESSED PLAYER_KEY_SHOOT
	call consolePrintZeroFlag	
	ret
playerDebugPrintKeyboard endp

playerDebugPrintPlayer proc private
	CONSOLE_SET_CURSOR_COL_ROW 0, 1
	mov ax,[PlayerPosX]
	call consolePrintWord
	CONSOLE_SET_CURSOR_COL_ROW 6, 1
	mov al,[PlayerPosXByteFraction]
	call consolePrintByteHex
	ret
playerDebugPrintPlayer endp

playerDebugPrintShot proc private
	CONSOLE_SET_CURSOR_COL_ROW 0, 2
	mov al,byte ptr [PlayerShotCount]
	call consolePrintByte
	CONSOLE_SET_CURSOR_COL_ROW 4, 2
	mov al,[PlayerShotCooldown]
	call consolePrintByte
	ret
playerDebugPrintShot endp

endif

; Input: di (pointer to the position in PlayerShotPosYPacked of the shot to be deleted).
playerDeleteShot proc private
	; Decrement shot count.
	mov bx,[PlayerShotCount]
	dec bx
	mov [PlayerShotCount],bx
	; Compute index of the last shot.
	shl bx,1
	; Increment render delete count.
	mov ax,[PlayerRenderDeleteCount]
	push si
	mov si,ax
	; assert(ax < PLAYER_RENDER_DELETE_MAX_COUNT)
	inc ax
	mov byte ptr [PlayerRenderDeleteCount],al
	shl si,1
	; Copy data to wipe shot from video memory on the next call to render.
	mov ax,[(PlayerShotPosX - PlayerShotPosYPacked) + di]
	sub ax,PLAYER_SHOT_HALF_WIDTH
	mov [PlayerRenderDeletePosX + si],ax
	mov al,byte ptr [di + 1]
	sub al,PLAYER_SHOT_HALF_HEIGHT
	mov byte ptr [PlayerRenderDeletePosY + si],al
	mov al,PLAYER_SHOT_WIDTH
	mov byte ptr [PlayerRenderDeleteWidth + si],al
	mov al,PLAYER_SHOT_HEIGHT
	mov byte ptr [PlayerRenderDeleteHeight + si],al
	; Copy data from last shot over deleted shot.
	mov ax,[PlayerShotPosX + bx]
	mov [(PlayerShotPosX - PlayerShotPosYPacked) + di],ax
	mov ax,[PlayerShotPosYPacked + bx]
	mov [di],ax
	mov al,byte ptr [PlayerShotPrevPosY + bx]
	mov byte ptr [(PlayerShotPrevPosY - PlayerShotPosYPacked) + di],al
	pop si

	ret
playerDeleteShot endp

code ends

constData segment readonly public
	PlayerGfx					word PlayerGfx0, PlayerGfx1, PlayerGfx2, PlayerGfx3
	PlayerGfx0					byte 0ffh, 0ffh, 000h
								byte 0ffh, 0ffh, 000h
								byte 0ffh, 0ffh, 000h
								byte 0ffh, 0ffh, 000h
								byte 0ffh, 0ffh, 000h
								byte 0ffh, 0ffh, 000h
								byte 0ffh, 0ffh, 000h
								byte 0ffh, 0ffh, 000h
	PlayerGfx1					byte 03fh, 0ffh, 0c0h
								byte 03fh, 0ffh, 0c0h
								byte 03fh, 0ffh, 0c0h
								byte 03fh, 0ffh, 0c0h
								byte 03fh, 0ffh, 0c0h
								byte 03fh, 0ffh, 0c0h
								byte 03fh, 0ffh, 0c0h
								byte 03fh, 0ffh, 0c0h
	PlayerGfx2					byte 00fh, 0ffh, 0f0h
								byte 00fh, 0ffh, 0f0h
								byte 00fh, 0ffh, 0f0h
								byte 00fh, 0ffh, 0f0h
								byte 00fh, 0ffh, 0f0h
								byte 00fh, 0ffh, 0f0h
								byte 00fh, 0ffh, 0f0h
								byte 00fh, 0ffh, 0f0h
	PlayerGfx3					byte 003h, 0ffh, 0fch
								byte 003h, 0ffh, 0fch
								byte 003h, 0ffh, 0fch
								byte 003h, 0ffh, 0fch
								byte 003h, 0ffh, 0fch
								byte 003h, 0ffh, 0fch
								byte 003h, 0ffh, 0fch
								byte 003h, 0ffh, 0fch
	PlayerShotGfx0				byte 000h, 000h
								byte 001h, 040h
								byte 001h, 040h
								byte 001h, 040h
								byte 001h, 040h
								byte 001h, 040h
								byte 001h, 040h
								byte 000h, 000h
constData ends

data segment public
	; The count will be stored in the LSB, the MSB will remain at zero.
	PlayerShotCount				word ?
	PlayerShotPosX				word PLAYER_SHOT_MAX_COUNT dup (?)
	PlayerShotPosYPacked		word PLAYER_SHOT_MAX_COUNT dup (?)
	; The shot prev posY will be stored in the LSB, the MSB is unused.
	PlayerShotPrevPosY			word PLAYER_SHOT_MAX_COUNT dup (?)
	PlayerPosX					word ?
	PlayerPrevPosX				word ?
	; The count will be stored in the LSB, the MSB will remain at zero.
	PlayerRenderDeleteCount		word PLAYER_RENDER_DELETE_MAX_COUNT dup (?)
	; The render delete posX and PosY are measured from the top left corner.
	PlayerRenderDeletePosX		word PLAYER_RENDER_DELETE_MAX_COUNT dup (?)
	; The render delete posY will be stored in the LSB, the MSB is unused.
	PlayerRenderDeletePosY		word PLAYER_RENDER_DELETE_MAX_COUNT dup (?)
	; The render delete size will be stored in the LSB, the MSB is unused.
	PlayerRenderDeleteWidth		word PLAYER_RENDER_DELETE_MAX_COUNT dup (?)
	PlayerRenderDeleteHeight	word PLAYER_RENDER_DELETE_MAX_COUNT dup (?)
	PlayerShotCooldown			byte ?
	PlayerPosXByteFraction		byte ?	
if PLAYER_AUTO_MOVE
	PlayerAutoMoveDir			byte ?
endif
	
data ends

end
