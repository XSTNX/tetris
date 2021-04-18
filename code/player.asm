include code\console.inc
include code\keyboard.inc

; Config.
if KEYBOARD_ENABLED
PLAYER_AUTO_MOVE                equ 0
else
PLAYER_AUTO_MOVE                equ 1
endif
PLAYER_USE_SPRITES              equ 1

; Constants.
PLAYER_WIDTH                    equ 8
PLAYER_HALF_WIDTH 			    equ PLAYER_WIDTH / 2
PLAYER_HEIGHT 				    equ 8
PLAYER_HALF_HEIGHT 			    equ PLAYER_HEIGHT / 2
PLAYER_POSX_LIMIT_LOW 			equ 30
PLAYER_POSX_LIMIT_HIGH 			equ BIOS_VIDEO_MODE_320_200_4_WIDTH - PLAYER_POSX_LIMIT_LOW
PLAYER_POSX_START 				equ BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH
PLAYER_POSY                     equ BIOS_VIDEO_MODE_320_200_4_HEIGHT - PLAYER_HALF_HEIGHT - 5
PLAYER_POSY_START			    equ PLAYER_POSY - PLAYER_HALF_HEIGHT
PLAYER_POSY_END				    equ PLAYER_POSY_START + PLAYER_HEIGHT
PLAYER_SPEEDX_BYTE_FRACTION		equ 0
; static_assert(PLAYER_SPEEDX_BYTE_FRACTION < 256)
PLAYER_SPEEDX	 				equ 5
PLAYER_SHOT_WIDTH				equ 2
PLAYER_SHOT_HALF_WIDTH			equ PLAYER_SHOT_WIDTH / 2
PLAYER_SHOT_HEIGHT				equ 6
PLAYER_SHOT_HALF_HEIGHT			equ PLAYER_SHOT_HEIGHT / 2
PLAYER_SHOT_POSY_START 			equ PLAYER_POSY_START - PLAYER_SHOT_HALF_HEIGHT
PLAYER_SHOT_POSY_START_PACKED 	equ PLAYER_SHOT_POSY_START * 256
PLAYER_SHOT_SPEED_PACKED        equ 400h
PLAYER_SHOT_COOLDOWN 			equ 10
PLAYER_SHOT_MAX_COUNT 			equ 5
; static_assert(PLAYER_SHOT_MAX_COUNT < 128)
PLAYER_RENDER_DELETE_MAX_COUNT	equ PLAYER_SHOT_MAX_COUNT * 2
PLAYER_KEY_LEFT					equ BIOS_KEYBOARD_SCANCODE_ARROW_LEFT
PLAYER_KEY_RIGHT				equ BIOS_KEYBOARD_SCANCODE_ARROW_RIGHT
PLAYER_KEY_SHOOT				equ BIOS_KEYBOARD_SCANCODE_E

allSegments group code, constData, data
    assume cs:allSegments, ds:allSegments

code segment public

extern consolePrintByte:proc, consolePrintByteHex:proc, consolePrintWord:proc, consolePrintWordHex:proc
extern renderBox320x200x4:proc, renderEraseSprite8x8:proc, renderSprite8x8:proc

playerInit proc
	xor ax,ax
	mov [PlayerShotCount],ax
	mov [PlayerRenderDeleteCount],ax
	mov [PlayerShotCooldown],al
	mov [PlayerPosXByteFraction],al
	; Zero out both PlayerRenderDeleteWidth and PlayerRenderDeleteHeight
	mov cx,PLAYER_RENDER_DELETE_MAX_COUNT * 2
	mov di,offset PlayerRenderDeleteWidth
	rep stosw

	mov ax,PLAYER_POSX_START
	mov [PlayerPosX],ax
	mov [PlayerPrevPosX],ax

if PLAYER_AUTO_MOVE
	mov [PlayerAutoMoveDir],1
endif
playerInit endp

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
	mov si,offset PlayerShotPosYPacked
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
	keyboardIsKeyPressed PLAYER_KEY_LEFT
	jnz short skipKeyLeftPressed
	dec ax
skipKeyLeftPressed:
	keyboardIsKeyPressed PLAYER_KEY_RIGHT
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
	keyboardIsKeyPressed PLAYER_KEY_SHOOT
	jnz short skipShot
endif
	mov cx,[PlayerShotCount]
	cmp cx,PLAYER_SHOT_MAX_COUNT
	je short skipShot
	cmp [PlayerShotCooldown],0
	jne short skipShot
	mov [PlayerShotCooldown],PLAYER_SHOT_COOLDOWN
	; Don't need to read this again if dx is not overriden.
	mov dx,[PlayerPosX]
	mov di,cx
	shl di,1
	mov [PlayerShotPosX + di],dx
	mov [PlayerShotPosYPacked + di],PLAYER_SHOT_POSY_START_PACKED
	; If the shot was updated after this, setting prev pos wouldn't be needed, is it worth doing?
	mov byte ptr [PlayerShotPrevPosY + di],PLAYER_SHOT_POSY_START
	inc cx
	mov byte ptr [PlayerShotCount],cl
skipShot:

	ret
playerUpdate endp

playerInitRender proc
	call playerRender
playerInitRender endp

playerRender proc
	; Clear deleted sprites.
	mov cx,[PlayerRenderDeleteCount]
	test cx,cx
	jz short loopDeleteDone
	xor di,di
loopDelete:
	push cx
		
	mov cx,[PlayerRenderDeletePosX + di]
	mov bx,cx
	add bx,[PlayerRenderDeleteWidth + di]
	mov dl,byte ptr [PlayerRenderDeletePosY + di]
	mov dh,dl
	add dh,byte ptr [PlayerRenderDeleteHeight + di]
	mov al,0
	call renderBox320x200x4

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
	xor di,di
loopShot:
	push cx

;if PLAYER_USE_SPRITES
if 0
	mov bp,di
	; Erase previous shot.
	mov cx,[PlayerShotPosX + di]
	sub cx,4
	mov dl,byte ptr [PlayerShotPrevPosY + di]
	sub dl,4
	call renderEraseSprite8x8

	mov di,bp
	; Draw current shot.
	mov cx,[PlayerShotPosX + di]
	sub cx,4
	mov dl,byte ptr [(PlayerShotPosYPacked + 1) + di]
	sub dl,4
	mov si,offset PlayerShotGfx0
	call renderSprite8x8
	mov di,bp
else
	; Erase previous shot.
	mov cx,[PlayerShotPosX + di]
	sub cx,PLAYER_SHOT_HALF_WIDTH
	mov bx,cx
	add bx,PLAYER_SHOT_WIDTH
	mov dl,byte ptr [PlayerShotPrevPosY + di]
	sub dl,PLAYER_SHOT_HALF_HEIGHT
	mov dh,dl
	add dh,PLAYER_SHOT_HEIGHT
	mov al,0
	call renderBox320x200x4
	
	; Draw current shot.
	mov cx,[PlayerShotPosX + di]
	sub cx,PLAYER_SHOT_HALF_WIDTH
	mov bx,cx
	add bx,PLAYER_SHOT_WIDTH
	mov dl,byte ptr [(PlayerShotPosYPacked + 1) + di]
	sub dl,PLAYER_SHOT_HALF_HEIGHT
	mov dh,dl
	add dh,PLAYER_SHOT_HEIGHT
	mov al,1
	call renderBox320x200x4
endif

	inc di
	inc di
	pop cx
	loop loopShot
loopShotDone:

if PLAYER_USE_SPRITES
	; Erase previous player.
	mov cx,[PlayerPrevPosX]
	sub cx,PLAYER_HALF_WIDTH
	mov dl,PLAYER_POSY_START
	call renderEraseSprite8x8

	; Draw current player.
	mov cx,[PlayerPosX]
	sub cx,PLAYER_HALF_WIDTH
	mov dl,PLAYER_POSY_START
	mov si,offset PlayerGfx
	call renderSprite8x8
else
	; Erase previous player.
	mov cx,[PlayerPrevPosX]
	sub cx,PLAYER_HALF_WIDTH
	mov bx,cx
	add bx,PLAYER_WIDTH
	mov dx,PLAYER_POSY_START + (PLAYER_POSY_END * 256)
	mov al,0
	call renderBox320x200x4

	; Draw current player.
	mov cx,[PlayerPosX]
	sub cx,PLAYER_HALF_WIDTH
	mov bx,cx
	add bx,PLAYER_WIDTH
	mov dx,PLAYER_POSY_START + (PLAYER_POSY_END * 256)
	mov al,3
	call renderBox320x200x4
endif

ifdef DEBUG
	call playerDebugPrintKeyboard
	;call playerDebugPrintPlayer
	;call playerDebugPrintShot
endif

	ret
playerRender endp

; ---------;
; Private. ;
; ---------;

ifdef DEBUG

playerDebugPrintKeyboard proc private
	; Left.
	consoleSetCursorPos 0, 0
	keyboardIsKeyPressed PLAYER_KEY_LEFT
	mov dl,"0"
	jnz short skipPressedKeyLeft
	mov dl,"1"
skipPressedKeyLeft:
	consolePrintChar dl

	; Right.
	consoleSetCursorPos 1, 0
	keyboardIsKeyPressed PLAYER_KEY_RIGHT
	mov dl,"0"
	jnz short skipPressedKeyRight
	mov dl,"1"
skipPressedKeyRight:
	consolePrintChar dl

	; SHOOT.
	consoleSetCursorPos 2, 0
	keyboardIsKeyPressed PLAYER_KEY_SHOOT
	mov dl,"0"
	jnz short skipPressedKeyShoot
	mov dl,"1"
skipPressedKeyShoot:
	consolePrintChar dl

	ret
playerDebugPrintKeyboard endp

playerDebugPrintPlayer proc private
	consoleSetCursorPos 0, 0
	mov dx,[PlayerPosX]
	call consolePrintWord
	consoleSetCursorPos 0, 1
	mov dl,[PlayerPosXByteFraction]
	call consolePrintByteHex
	ret
playerDebugPrintPlayer endp

playerDebugPrintShot proc private
	consoleSetCursorPos 0, 0
	mov dl,byte ptr [PlayerShotCount]
	call consolePrintByte
	consoleSetCursorPos 0, 1
	mov dl,[PlayerShotCooldown]
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

constData segment public
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
