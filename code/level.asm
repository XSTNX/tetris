include code\console.inc
include code\keyboard.inc

LEVEL_BOX_WIDTH					equ 8
LEVEL_BOX_HALF_WIDTH 			equ LEVEL_BOX_WIDTH / 2
LEVEL_BOX_HEIGHT 				equ 12
LEVEL_BOX_HALF_HEIGHT 			equ LEVEL_BOX_HEIGHT / 2
LEVEL_POSX_LIMIT_LEFT 			equ 30
LEVEL_POSX_LIMIT_RIGHT 			equ BIOS_VIDEO_MODE_320_200_4_WIDTH - LEVEL_POSX_LIMIT_LEFT
LEVEL_POSX_START 				equ BIOS_VIDEO_MODE_320_200_4_HALF_WIDTH
LEVEL_POSY 						equ BIOS_VIDEO_MODE_320_200_4_HEIGHT - 10
LEVEL_POSY_BOX_START			equ LEVEL_POSY - (LEVEL_BOX_HEIGHT / 2)
LEVEL_POSY_BOX_END				equ LEVEL_POSY_BOX_START + LEVEL_BOX_HEIGHT
LEVEL_SPEEDX_LOW 				equ 0
LEVEL_SPEEDX_HIGH 				equ 5
LEVEL_SHOT_WIDTH				equ 2
LEVEL_SHOT_HALF_WIDTH			equ LEVEL_SHOT_WIDTH / 2
LEVEL_SHOT_HEIGHT				equ 6
LEVEL_SHOT_HALF_HEIGHT			equ LEVEL_SHOT_HEIGHT / 2
LEVEL_SHOT_POSY_START 			equ LEVEL_POSY_BOX_START - LEVEL_SHOT_HALF_HEIGHT
LEVEL_SHOT_POSY_START_PACKED 	equ LEVEL_SHOT_POSY_START * 256
LEVEL_SHOT_SPEED_PACKED			equ 400h
LEVEL_SHOT_COOLDOWN 			equ 10
LEVEL_SHOT_MAX_COUNT 			equ 5
; assert(LEVEL_SHOT_MAX_COUNT < 256)
LEVEL_RENDER_DELETE_MAX_COUNT	equ LEVEL_SHOT_MAX_COUNT * 2

allSegments group code, data
    assume cs:allSegments, ds:allSegments

code segment public

extern consolePrintByte:proc
extern renderBox320x200x4:proc, renderHorizLine320x200x4:proc

levelInit proc
	cld

	xor ax,ax
	mov [LevelShotCooldown],al
	mov [LevelShotCount],ax
	mov [LevelPosXLow],ax
	mov [LevelRenderDeleteCount],ax
	; Zero out both LevelRenderDeleteWidth and LevelRenderDeleteHeight
	mov cx,LEVEL_RENDER_DELETE_MAX_COUNT * 2
	mov di,offset LevelRenderDeleteWidth
	rep stosw

	mov ax,LEVEL_POSX_START
	mov [LevelPosXHigh],ax
	mov [LevelPrevPosXHigh],ax
levelInit endp

levelUpdate proc
	mov ax,ds
	mov es,ax

	; Save prev posX.
	mov ax,[LevelPosXHigh]
	mov [LevelPrevPosXHigh],ax

	; Update cooldown.
	mov al,[LevelShotCooldown]
	test al,al
	jz short skipShotCoolDownDecrement
	dec ax
	mov [LevelShotCooldown],al
skipShotCoolDownDecrement:

	; Update shots.
	mov cx,[LevelShotCount]
	test cx,cx
	jz short loopShotDone
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

	; Store the direction of movement in al.
	xor al,al
	keyboardIsKeyPressed BIOS_KEYBOARD_SCANCODE_ARROW_LEFT
	jnz short skipArrowLeftPressed
	dec ax
skipArrowLeftPressed:
	keyboardIsKeyPressed BIOS_KEYBOARD_SCANCODE_ARROW_RIGHT
	jnz short skipArrowRightPressed
	inc ax
skipArrowRightPressed:

	; Move left.
	cmp al,0ffh
	jne short skipMoveLeft
	; Compute new posX.
	mov cx,[LevelPosXLow]
	sub cx,LEVEL_SPEEDX_LOW
	mov dx,[LevelPosXHigh]
	sbb dx,LEVEL_SPEEDX_HIGH
	; Limit posX if needed.
	cmp dx,LEVEL_POSX_LIMIT_LEFT
	jae short skipLimitPosXLeft
	xor cx,cx
	mov dx,LEVEL_POSX_LIMIT_LEFT
skipLimitPosXLeft:
	; Save new posX.
	mov [LevelPosXLow],cx
	mov [LevelPosXHigh],dx
skipMoveLeft:

	; Move right.
	cmp al,1
	jne short skipMoveRight
	; Compute new posX.
	mov cx,[LevelPosXLow]
	add cx,LEVEL_SPEEDX_LOW
	mov dx,[LevelPosXHigh]
	adc dx,LEVEL_SPEEDX_HIGH
	; Limit posX if needed.
	cmp dx,LEVEL_POSX_LIMIT_RIGHT
	jb short skipLimitPosXRight
	xor cx,cx
	mov dx,LEVEL_POSX_LIMIT_RIGHT
skipLimitPosXRight:
	; Save new posX.
	mov [LevelPosXLow],cx
	mov [LevelPosXHigh],dx
skipMoveRight:

	; Shoot.
	keyboardIsKeyPressed BIOS_KEYBOARD_SCANCODE_E
	jnz short skipShot
	mov cx,[LevelShotCount]
	cmp cx,LEVEL_SHOT_MAX_COUNT
	je short skipShot
	cmp [LevelShotCooldown],0
	jne short skipShot
	mov [LevelShotCooldown],LEVEL_SHOT_COOLDOWN
	; Don't need to read this again if dx is not overriden.
	mov dx,[LevelPosXHigh]
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
	mov [LevelRenderDeleteCount],cx
loopDeleteDone:

	; Render shots.
	mov cx,[LevelShotCount]
	test cx,cx
	jz short loopShotDone
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
	mov cx,[LevelPrevPosXHigh]
	sub cx,LEVEL_BOX_HALF_WIDTH
	mov bx,cx
	add bx,LEVEL_BOX_WIDTH
	mov dx,LEVEL_POSY_BOX_START + (LEVEL_POSY_BOX_END * 256)
	mov al,0
	call renderBox320x200x4

	; Draw current box.
	mov cx,[LevelPosXHigh]
	sub cx,LEVEL_BOX_HALF_WIDTH
	mov bx,cx
	add bx,LEVEL_BOX_WIDTH
	mov dx,LEVEL_POSY_BOX_START + (LEVEL_POSY_BOX_END * 256)
	mov al,3
	call renderBox320x200x4

.if DEBUG
	; Print debug info.
	consoleSetCursorPos 0, 0
	mov dl,byte ptr [LevelShotCount]
	call consolePrintByte
	consoleSetCursorPos 0, 1
	mov dl,[LevelShotCooldown]
	call consolePrintByte
.endif

	ret
levelRender endp

; ---------;
; Private. ;
; ---------;

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
	inc ax
	mov [LevelRenderDeleteCount],ax
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
	LevelShotCooldown			db ?
	; The shot count will be stored in the LSB, the MSB will remain at zero.
	LevelShotCount				dw ?
	LevelShotPosX				dw LEVEL_SHOT_MAX_COUNT dup (?)
	LevelShotPosYPacked			dw LEVEL_SHOT_MAX_COUNT dup (?)
	; The shot prev posY will be stored in the LSB, the MSB is unused.
	LevelShotPrevPosY			dw LEVEL_SHOT_MAX_COUNT dup (?)
	LevelPosXLow				dw ?
	LevelPosXHigh				dw ?
	LevelPrevPosXHigh			dw ?
	LevelRenderDeleteCount		dw LEVEL_RENDER_DELETE_MAX_COUNT dup (?)
	; The render delete posX and PosY are measured from the top left corner.
	LevelRenderDeletePosX		dw LEVEL_RENDER_DELETE_MAX_COUNT dup (?)
	; The render delete posY will be stored in the LSB, the MSB is unused.
	LevelRenderDeletePosY		dw LEVEL_RENDER_DELETE_MAX_COUNT dup (?)
	; The render delete size will be stored in the LSB, the MSB is unused.
	LevelRenderDeleteWidth		dw LEVEL_RENDER_DELETE_MAX_COUNT dup (?)
	LevelRenderDeleteHeight		dw LEVEL_RENDER_DELETE_MAX_COUNT dup (?)
data ends

end
