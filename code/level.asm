include code\console.inc
include code\keyboard.inc

LEVEL_AUTO_MOVE					equ 0
LEVEL_BOX_WIDTH					equ 8
LEVEL_BOX_HALF_WIDTH 			equ LEVEL_BOX_WIDTH / 2
LEVEL_BOX_HEIGHT 				equ 12
LEVEL_BOX_HALF_HEIGHT 			equ LEVEL_BOX_HEIGHT / 2
LEVEL_POSX_LIMIT_LOW 			equ 30
LEVEL_POSX_LIMIT_HIGH 			equ BIOS_VIDEO_MODE_320_200_4_WIDTH - LEVEL_POSX_LIMIT_LOW
LEVEL_POSX_START 				equ BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH
LEVEL_POSY 						equ BIOS_VIDEO_MODE_320_200_4_HEIGHT - 10
LEVEL_POSY_BOX_START			equ LEVEL_POSY - (LEVEL_BOX_HEIGHT / 2)
LEVEL_POSY_BOX_END				equ LEVEL_POSY_BOX_START + LEVEL_BOX_HEIGHT
LEVEL_SPEEDX_BYTE_FRACTION		equ 0
; static_assert(LEVEL_SPEEDX_BYTE_FRACTION < 256)
LEVEL_SPEEDX	 				equ 5
LEVEL_SHOT_WIDTH				equ 2
LEVEL_SHOT_HALF_WIDTH			equ LEVEL_SHOT_WIDTH / 2
LEVEL_SHOT_HEIGHT				equ 6
LEVEL_SHOT_HALF_HEIGHT			equ LEVEL_SHOT_HEIGHT / 2
LEVEL_SHOT_POSY_START 			equ LEVEL_POSY_BOX_START - LEVEL_SHOT_HALF_HEIGHT
LEVEL_SHOT_POSY_START_PACKED 	equ LEVEL_SHOT_POSY_START * 256
LEVEL_SHOT_SPEED_PACKED			equ 400h
LEVEL_SHOT_COOLDOWN 			equ 10
LEVEL_SHOT_MAX_COUNT 			equ 5
; static_assert(LEVEL_SHOT_MAX_COUNT < 128)
LEVEL_RENDER_DELETE_MAX_COUNT	equ LEVEL_SHOT_MAX_COUNT * 2

allSegments group code, data
    assume cs:allSegments, ds:allSegments

code segment public

extern consolePrintByte:proc, consolePrintByteHex:proc, consolePrintWord:proc, consolePrintWordHex:proc
extern renderBox320x200x4:proc, renderHorizLine320x200x4:proc

levelInit proc
	xor ax,ax
	mov [LevelShotCount],ax
	mov [LevelRenderDeleteCount],ax
	mov [LevelShotCooldown],al
	mov [LevelPosXByteFraction],al
	; Zero out both LevelRenderDeleteWidth and LevelRenderDeleteHeight
	mov cx,LEVEL_RENDER_DELETE_MAX_COUNT * 2
	mov di,offset LevelRenderDeleteWidth
	rep stosw

	mov ax,LEVEL_POSX_START
	mov [LevelPosX],ax
	mov [LevelPrevPosX],ax

if LEVEL_AUTO_MOVE
	mov [LevelAutoMoveDir],1
endif
levelInit endp

levelUpdate proc
	mov ax,ds
	mov es,ax

	; Save prev posX.
	mov ax,[LevelPosX]
	mov [LevelPrevPosX],ax

	; Update cooldown.
	mov al,[LevelShotCooldown]
	test al,al
	jz short skipShotCoolDownDecrement
	dec ax
	mov [LevelShotCooldown],al
skipShotCoolDownDecrement:

	; Update shots.
	mov cx,[LevelShotCount]
	jcxz short loopShotDone
	mov dx,LEVEL_SHOT_SPEED_PACKED
	mov si,offset LevelShotPosYPacked
	mov di,si
loopShot:
	lodsw
	cmp ax,dx
	jb short loopDelete
	mov byte ptr [(LevelShotPrevPosY - LevelShotPosYPacked) + di],ah
	sub ax,dx
	stosw
	jmp short loopShotNext
loopDelete:
	call levelDeleteShot
	dec si
	dec si
	mov di,si
loopShotNext:
	loop loopShot
loopShotDone:

if LEVEL_AUTO_MOVE
	; Check current direction of movement.
	mov al,[LevelAutoMoveDir]
	cmp al,1
	jne short autoMoveLeft
	; Check if need to flip direction left.
	cmp [LevelPosX],LEVEL_POSX_LIMIT_HIGH
	jne short autoMoveDone
	dec ax
	dec ax
	mov [LevelAutoMoveDir],al
	jmp short autoMoveDone
autoMoveLeft:
	; Check if need to flip direction right.
	cmp [LevelPosX],LEVEL_POSX_LIMIT_LOW
	jne short autoMoveDone
	inc ax
	inc ax
	mov [LevelAutoMoveDir],al
autoMoveDone:
	; Check if need to flip direction to right.
else
	; Read keyboard and store the direction of movement in al.
	xor al,al
	keyboardIsKeyPressed BIOS_KEYBOARD_SCANCODE_ARROW_LEFT
	jnz short skipArrowLeftPressed
	dec ax
skipArrowLeftPressed:
	keyboardIsKeyPressed BIOS_KEYBOARD_SCANCODE_ARROW_RIGHT
	jnz short skipArrowRightPressed
	inc ax
skipArrowRightPressed:
endif

	; Move left.
	cmp al,0ffh
	jne short skipMoveLeft
	; Compute new posX.
	mov cl,[LevelPosXByteFraction]
	sub cl,LEVEL_SPEEDX_BYTE_FRACTION
	mov dx,[LevelPosX]
	sbb dx,LEVEL_SPEEDX
	; Limit posX if needed.
	cmp dx,LEVEL_POSX_LIMIT_LOW
	jae short skipLimitPosXLeft
	xor cl,cl
	mov dx,LEVEL_POSX_LIMIT_LOW
skipLimitPosXLeft:
	; Save new posX.
	mov [LevelPosXByteFraction],cl
	mov [LevelPosX],dx
	; No need to check if moved right.
	jmp short [skipMoveRight]
skipMoveLeft:

	; Move right.
	cmp al,1
	jne short skipMoveRight
	; Compute new posX.
	mov cl,[LevelPosXByteFraction]
	add cl,LEVEL_SPEEDX_BYTE_FRACTION
	mov dx,[LevelPosX]
	adc dx,LEVEL_SPEEDX
	; Limit posX if needed.
	cmp dx,LEVEL_POSX_LIMIT_HIGH
	jb short skipLimitPosXRight
	xor cl,cl
	mov dx,LEVEL_POSX_LIMIT_HIGH
skipLimitPosXRight:
	; Save new posX.
	mov [LevelPosXByteFraction],cl
	mov [LevelPosX],dx
skipMoveRight:

	; Shoot.
ife LEVEL_AUTO_MOVE
	keyboardIsKeyPressed BIOS_KEYBOARD_SCANCODE_E
	jnz short skipShot
endif
	mov cx,[LevelShotCount]
	cmp cx,LEVEL_SHOT_MAX_COUNT
	je short skipShot
	cmp [LevelShotCooldown],0
	jne short skipShot
	mov [LevelShotCooldown],LEVEL_SHOT_COOLDOWN
	; Don't need to read this again if dx is not overriden.
	mov dx,[LevelPosX]
	mov di,cx
	shl di,1
	mov [LevelShotPosX + di],dx
	mov [LevelShotPosYPacked + di],LEVEL_SHOT_POSY_START_PACKED
	; If the shot was updated after this, setting prev pos wouldn't be needed, is it worth doing?
	mov byte ptr [LevelShotPrevPosY + di],LEVEL_SHOT_POSY_START
	inc cx
	mov byte ptr [LevelShotCount],cl
skipShot:

	ret
levelUpdate endp

levelInitRender proc
	call levelRender
	; Execute code after the regular render function so the ES segment is set to video memory.
	mov cx,0
	mov bx,BIOS_VIDEO_MODE_320_200_4_WIDTH
	mov dl,LEVEL_POSY_BOX_END
	mov dh,2
	call renderHorizLine320x200x4
	ret
levelInitRender endp

levelRender proc
	mov ax,BIOS_VIDEO_MODE_320_200_4_START_ADDR
	mov es,ax

	; Clear deleted sprites.
	mov cx,[LevelRenderDeleteCount]
	test cx,cx
	jz short loopDeleteDone
	xor di,di
loopDelete:
	push cx
		
	mov cx,[LevelRenderDeletePosX + di]
	mov bx,cx
	add bx,[LevelRenderDeleteWidth + di]
	mov dl,byte ptr [LevelRenderDeletePosY + di]
	mov dh,dl
	add dh,byte ptr [LevelRenderDeleteHeight + di]
	mov al,0
	call renderBox320x200x4

	inc di
	inc di
	pop cx
	loop loopDelete
	
	; Set delete count back to zero.
	mov byte ptr [LevelRenderDeleteCount],cl
loopDeleteDone:

	; Render shots.
	mov cx,[LevelShotCount]
	jcxz short loopShotDone
	xor di,di
loopShot:
	push cx

	; Erase previous shot.
	mov cx,[LevelShotPosX + di]
	sub cx,LEVEL_SHOT_HALF_WIDTH
	mov bx,cx
	add bx,LEVEL_SHOT_WIDTH
	mov dl,byte ptr [LevelShotPrevPosY + di]
	sub dl,LEVEL_SHOT_HALF_HEIGHT
	mov dh,dl
	add dh,LEVEL_SHOT_HEIGHT
	mov al,0
	call renderBox320x200x4

	; Draw current shot.
	mov cx,[LevelShotPosX + di]
	sub cx,LEVEL_SHOT_HALF_WIDTH
	mov bx,cx
	add bx,LEVEL_SHOT_WIDTH
	mov dl,byte ptr [(LevelShotPosYPacked + 1) + di]
	sub dl,LEVEL_SHOT_HALF_HEIGHT
	mov dh,dl
	add dh,LEVEL_SHOT_HEIGHT
	mov al,1
	call renderBox320x200x4

	inc di
	inc di
	pop cx
	loop loopShot
loopShotDone:

	; Erase previous box.
	mov cx,[LevelPrevPosX]
	sub cx,LEVEL_BOX_HALF_WIDTH
	mov bx,cx
	add bx,LEVEL_BOX_WIDTH
	mov dx,LEVEL_POSY_BOX_START + (LEVEL_POSY_BOX_END * 256)
	mov al,0
	call renderBox320x200x4

	; Draw current box.
	mov cx,[LevelPosX]
	sub cx,LEVEL_BOX_HALF_WIDTH
	mov bx,cx
	add bx,LEVEL_BOX_WIDTH
	mov dx,LEVEL_POSY_BOX_START + (LEVEL_POSY_BOX_END * 256)
	mov al,3
	call renderBox320x200x4

ifdef DEBUG
	;call levelDebugPrintPlayer
	call levelDebugPrintShot
endif

	ret
levelRender endp

; ---------;
; Private. ;
; ---------;

levelDebugPrintPlayer proc private
	consoleSetCursorPos 0, 0
	mov dx,[LevelPosX]
	call consolePrintWord
	consoleSetCursorPos 0, 1
	mov dl,[LevelPosXByteFraction]
	call consolePrintByteHex
	ret
levelDebugPrintPlayer endp

levelDebugPrintShot proc private
	consoleSetCursorPos 0, 0
	mov dl,byte ptr [LevelShotCount]
	call consolePrintByte
	consoleSetCursorPos 0, 1
	mov dl,[LevelShotCooldown]
	call consolePrintByte
	ret
levelDebugPrintShot endp

; Input: di (pointer to the position in LevelShotPosYPacked of the shot to be deleted).
levelDeleteShot proc private
	; Decrement shot count.
	mov bx,[LevelShotCount]
	dec bx
	mov [LevelShotCount],bx
	; Compute index of the last shot.
	shl bx,1
	; Increment render delete count.
	mov ax,[LevelRenderDeleteCount]
	push si
	mov si,ax
	; assert(ax < LEVEL_RENDER_DELETE_MAX_COUNT)
	inc ax
	mov byte ptr [LevelRenderDeleteCount],al
	shl si,1
	; Copy data to wipe shot from video memory on the next call to render.
	mov ax,[(LevelShotPosX - LevelShotPosYPacked) + di]
	sub ax,LEVEL_SHOT_HALF_WIDTH
	mov [LevelRenderDeletePosX + si],ax
	mov al,byte ptr [di + 1]
	sub al,LEVEL_SHOT_HALF_HEIGHT
	mov byte ptr [LevelRenderDeletePosY + si],al
	mov al,LEVEL_SHOT_WIDTH
	mov byte ptr [LevelRenderDeleteWidth + si],al
	mov al,LEVEL_SHOT_HEIGHT
	mov byte ptr [LevelRenderDeleteHeight + si],al
	; Copy data from last shot over deleted shot.
	mov ax,[LevelShotPosX + bx]
	mov [(LevelShotPosX - LevelShotPosYPacked) + di],ax
	mov ax,[LevelShotPosYPacked + bx]
	mov [di],ax
	mov al,byte ptr [LevelShotPrevPosY + bx]
	mov byte ptr [(LevelShotPrevPosY - LevelShotPosYPacked) + di],al
	pop si

	ret
levelDeleteShot endp

code ends

data segment public
	; The count will be stored in the LSB, the MSB will remain at zero.
	LevelShotCount				word ?
	LevelShotPosX				word LEVEL_SHOT_MAX_COUNT dup (?)
	LevelShotPosYPacked			word LEVEL_SHOT_MAX_COUNT dup (?)
	; The shot prev posY will be stored in the LSB, the MSB is unused.
	LevelShotPrevPosY			word LEVEL_SHOT_MAX_COUNT dup (?)
	LevelPosX					word ?
	LevelPrevPosX				word ?
	; The count will be stored in the LSB, the MSB will remain at zero.
	LevelRenderDeleteCount		word LEVEL_RENDER_DELETE_MAX_COUNT dup (?)
	; The render delete posX and PosY are measured from the top left corner.
	LevelRenderDeletePosX		word LEVEL_RENDER_DELETE_MAX_COUNT dup (?)
	; The render delete posY will be stored in the LSB, the MSB is unused.
	LevelRenderDeletePosY		word LEVEL_RENDER_DELETE_MAX_COUNT dup (?)
	; The render delete size will be stored in the LSB, the MSB is unused.
	LevelRenderDeleteWidth		word LEVEL_RENDER_DELETE_MAX_COUNT dup (?)
	LevelRenderDeleteHeight		word LEVEL_RENDER_DELETE_MAX_COUNT dup (?)
	LevelShotCooldown			byte ?
	LevelPosXByteFraction		byte ?	
if LEVEL_AUTO_MOVE
	LevelAutoMoveDir			byte ?
endif
data ends

end
