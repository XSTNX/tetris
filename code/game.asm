include code\console.inc

TEST_GAMEPLAY_BOX_WIDTH 				equ 8
TEST_GAMEPLAY_BOX_HALF_WIDTH 			equ TEST_GAMEPLAY_BOX_WIDTH / 2
TEST_GAMEPLAY_BOX_HEIGHT 				equ 12
TEST_GAMEPLAY_BOX_HALF_HEIGHT 			equ TEST_GAMEPLAY_BOX_HEIGHT / 2
TEST_GAMEPLAY_POSX_LIMIT_LEFT 			equ 30
TEST_GAMEPLAY_POSX_LIMIT_RIGHT 			equ 290
TEST_GAMEPLAY_POSX_START 				equ 160
TEST_GAMEPLAY_POSY 						equ 190
TEST_GAMEPLAY_POSY_BOX_START			equ TEST_GAMEPLAY_POSY - (TEST_GAMEPLAY_BOX_HEIGHT / 2)
TEST_GAMEPLAY_POSY_BOX_END				equ TEST_GAMEPLAY_POSY_BOX_START + TEST_GAMEPLAY_BOX_HEIGHT
TEST_GAMEPLAY_SPEEDX_LOW 				equ 0
TEST_GAMEPLAY_SPEEDX_HIGH 				equ 5
TEST_GAMEPLAY_SHOT_WIDTH				equ 2
TEST_GAMEPLAY_SHOT_HALF_WIDTH			equ TEST_GAMEPLAY_SHOT_WIDTH / 2
TEST_GAMEPLAY_SHOT_HEIGHT				equ 6
TEST_GAMEPLAY_SHOT_HALF_HEIGHT			equ TEST_GAMEPLAY_SHOT_HEIGHT / 2
TEST_GAMEPLAY_SHOT_POSY_START 			equ TEST_GAMEPLAY_POSY_BOX_START - TEST_GAMEPLAY_SHOT_HALF_HEIGHT
TEST_GAMEPLAY_SHOT_POSY_START_PACKED 	equ TEST_GAMEPLAY_SHOT_POSY_START * 256
TEST_GAMEPLAY_SHOT_SPEED_PACKED			equ 400h
TEST_GAMEPLAY_SHOT_COOLDOWN 			equ 10
TEST_GAMEPLAY_SHOT_MAX_COUNT 			equ 5
; assert(TEST_GAMEPLAY_SHOT_MAX_COUNT < 256)
TEST_GAMEPLAY_RENDER_DELETE_MAX_COUNT	equ TEST_GAMEPLAY_SHOT_MAX_COUNT * 2

allSegments group code, constData, data
    assume cs:allSegments, ds:allSegments

code segment public
	extern consolePrintByte:proc, consolePrintByteHex:proc
	org 100h

;----------;
; Private. ;
;----------;

main proc private
	; Read current video mode.
	mov ah,BIOS_VIDEO_FUNC_GET_VIDEO_MODE
	int BIOS_VIDEO_INT
	cmp al,BIOS_VIDEO_MODE_80_25_TEXT_MONO
	jne short gameStart
	; Print wrong video card message and quit.
	mov dx,offset StrWrongVideoCard
	CONSOLE_PRINT_DOS_STRING
	jmp short gameQuit

gameStart:
	; Save current video mode.
	push ax

	; Set graphics mode.
	mov al,BIOS_VIDEO_MODE_320_200_4_COLOR
	mov ah,BIOS_VIDEO_FUNC_SET_VIDEO_MODE
	int BIOS_VIDEO_INT
	; Set palette 0.
	mov bx,100h
	mov ah,BIOS_VIDEO_FUNC_SET_PLT_BKG_BDR
	int BIOS_VIDEO_INT

	call testGameplayInit
	call testGameplayInitRender
gameLoop:
	call testGameplayUpdate
	call testGameplayRender
	; Don't quit the gameloop until ESC is pressed.
	mov ah,DOS_REQUEST_FUNC_INPUT_STATUS
	int DOS_REQUEST_INT
	test al,al
	jz short gameLoop
	mov ah,BIOS_KEYBOARD_FUNC_GET_CHAR
	int BIOS_KEYBOARD_INT
	cmp ah,BIOS_KEYBOARD_SCANCODE_ESC
	jne short gameLoop

	; Restore previous video mode.
	pop ax
	mov ah,BIOS_VIDEO_FUNC_SET_VIDEO_MODE
	int BIOS_VIDEO_INT

gameQuit:
	DOS_QUIT
main endp

WAIT_VSYNC macro
local vsyncWait0, vsyncWait1
	mov dx,3dah
vsyncWait0:
	in al,dx
	test al,8
	jnz vsyncWait0
vsyncWait1:
	in al,dx
	test al,8
	jz vsyncWait1
endm

DRAW_PIXEL macro
local notOddRow
	xor bx,bx
	;; Divide posY by two, since the even rows go in one bank and the odd rows in another.
	shr dl,1
	jnc notOddRow
	;; If it's an odd row, the bank starts at offset 2000h instead of 0000h.
	mov bh,20h
notOddRow:
	;; Multiply posY by 80 to obtain the offset in video memory to the row the pixel belongs to.
	mov al,80
	mul dl
	or bx,ax
	;; Save the last two bits of posX, since they decide which bits in the video memory byte the pixel belong to.
	mov si,cx
	and si,11b
	;; Divide posX by four to obtain the offset in video memory to the column the pixel belongs to.
	shr cx,1
	shr cx,1	
	add bx,cx
	;; Read the byte in video memory where the pixel is.
	mov al,es:[bx]
	;; Mask the previous pixel.
	and al,DrawPixelMask[si]
	;; Add the new pixel.
	mov cl,DrawPixelShift[si]
	shl dh,cl
	or al,dh
	;; Write the updated byte to video memory.
	mov es:[bx],al
endm

drawHorizLine proc private
	push bx
	push cx
	push dx
	DRAW_PIXEL
	pop dx
	pop cx
	pop bx
	inc cx
	cmp cx,bx
	jne short drawHorizLine
	ret
drawHorizLine endp

drawBox proc private
	push ax
	push cx
	push dx
	mov dh,al
	call drawHorizLine
	pop dx
	pop cx
	pop ax
	inc dl
	cmp dl,dh
	jne short drawBox
	ret
drawBox endp

testKeyboardScancode proc private
nextKey:
	mov ah,BIOS_KEYBOARD_FUNC_GET_CHAR
	int BIOS_KEYBOARD_INT
	cmp al,3
	je quit
	; Save returned data.
	push ax	

	; Print scancode.	
	mov dx,offset strScancode
	CONSOLE_PRINT_DOS_STRING
	pop ax
	push ax
	mov dl,ah
	call consolePrintByteHex

	mov dl,' '
	CONSOLE_PRINT_CHAR

	; Print ascii.
	mov dx,offset strASCII
	CONSOLE_PRINT_DOS_STRING
	pop ax
	mov dl,al
	CONSOLE_PRINT_CHAR

	CONSOLE_GO_NEXT_LINE
	jmp short nextkey

quit:
	DOS_QUIT

strScancode:
	db 'Scancode: $'
strASCII:
	db ' ASCII: $'
testKeyboardScancode endp

testKeyboardFlags proc private
nextKey:
	mov ah,BIOS_KEYBOARD_FUNC_GET_FLAGS
	int BIOS_KEYBOARD_INT
	mov dl,al
	call consolePrintByteHex

	CONSOLE_GO_NEXT_LINE

	; Continue until a key is pressed.
	mov ah,DOS_REQUEST_FUNC_INPUT_STATUS
	int DOS_REQUEST_INT
	test al,al
	jz short nextKey

	ret
testKeyboardFlags endp

testVideo1 proc private
	mov ax,BIOS_VIDEO_MODE_320_200_4_START_ADDR
	mov es,ax
	cld
	
	; Even lines.
	xor di,di

	mov ax,5555h
	mov cx,480	
	rep stosw

	mov ax,0aaaah
	mov cx,480
	rep stosw

	mov ax,0ffffh
	mov cx,480
	rep stosw

	; Odd lines
	mov di,02000h

	mov cx,480
	rep stosw

	mov ax,5555h
	mov cx,480
	rep stosw

	mov ax,0aaaah
	mov cx,480
	rep stosw

	ret
testVideo1 endp

testVideo2 proc private
	mov ax,BIOS_VIDEO_MODE_320_200_4_START_ADDR
	mov es,ax

	; PosX.
	mov cx,1
	; PosY.
	mov dl,99
	; Color.
	mov dh,1
	DRAW_PIXEL
	; PosX.
	mov cx,3
	; PosY.
	mov dl,99
	; Color.
	mov dh,1
	DRAW_PIXEL
	; Start posX.
	mov cx,0
	; End posX.
	mov bx,BIOS_VIDEO_MODE_320_200_4_WIDTH
	; PosY.
	mov dl,100
	; Color.
	mov dh,1
	call drawHorizLine
	; Start posX.
	mov cx,0
	; End posX.
	mov bx,BIOS_VIDEO_MODE_320_200_4_WIDTH
	; PosY.
	mov dl,101
	; Color.
	mov dh,2
	call drawHorizLine

	; PosX.
	mov cx,1
	; PosY.
	mov dl,100
	; Color.
	mov dh,3
	DRAW_PIXEL

	; Start posX.
	mov cx,0
	; End posX.
	mov bx,BIOS_VIDEO_MODE_320_200_4_WIDTH
	; Start posY.
	mov dl,102
	; End posY.
	mov dh,105
	; Color.
	mov al,3
	call drawBox

	ret
testVideo2 endp

testDOSVersion proc private
	mov ah,DOS_REQUEST_FUNC_GET_VERSION_NUM
	int DOS_REQUEST_INT
	push bx
	push ax

	mov dx,offset strVer
	CONSOLE_PRINT_DOS_STRING

	; Major version.
	pop dx
	push dx
	call consolePrintByte
	
	mov dl,'.'
	CONSOLE_PRINT_CHAR
	
	; Minor version.
	pop dx
	mov dl,dh
	call consolePrintByte
	
	mov dx,offset strDOSType
	CONSOLE_PRINT_DOS_STRING

	; Dos type.
	pop dx
	mov dl,dh
	call consolePrintByteHex

	ret
strVer:
	db 'Ver: $'
strDOSType:
	db ' DosType: $'
testDOSVersion endp

testGameplayInit proc private
	cld

	xor ax,ax
	mov [TestGameplayShotCooldown],al
	mov [TestGameplayShotCount],ax
	mov [TestGameplayPosXLow],ax
	mov [TestGameplayRenderDeleteCount],ax
	; Zero out both TestGameplayRenderDeleteWidth and TestGameplayRenderDeleteHeight
	mov cx,TEST_GAMEPLAY_RENDER_DELETE_MAX_COUNT * 2
	mov di,offset TestGameplayRenderDeleteWidth
	rep stosw

	mov ax,TEST_GAMEPLAY_POSX_START
	mov [TestGameplayPosXHigh],ax
	mov [TestGameplayPrevPosXHigh],ax
testGameplayInit endp

testGameplayUpdate proc private
	mov ax,ds
	mov es,ax

	; Save prev posX.
	mov ax,[TestGameplayPosXHigh]
	mov [TestGameplayPrevPosXHigh],ax

	; Update cooldown.
	mov al,[TestGameplayShotCooldown]
	test al,al
	jz skipShotCoolDownDecrement
	dec ax
	mov [TestGameplayShotCooldown],al
skipShotCoolDownDecrement:

	; Update shots.
	mov cx,[TestGameplayShotCount]
	test cx,cx
	jz loopShotDone
	mov dx,TEST_GAMEPLAY_SHOT_SPEED_PACKED
	mov si,offset TestGameplayShotPosYPacked
	mov di,si
loopShot:
	lodsw
	cmp ax,dx
	jb short loopDelete
	mov byte ptr [(TestGameplayShotPrevPosY - TestGameplayShotPosYPacked) + di],ah
	sub ax,dx
	stosw
	jmp short loopShotNext
loopDelete:
	call testGameplayDeleteShot
	dec si
	dec si
loopShotNext:
	loop loopShot
loopShotDone:

	; Poll keyboard.
	mov ah,BIOS_KEYBOARD_FUNC_GET_FLAGS
	int BIOS_KEYBOARD_INT
	
	; Figure out direction of movement.
	xor bx,bx
	test al,BIOS_KEYBOARD_FLAGS_LEFT_SHIFT
	jz skipDirLeft
	dec bx
skipDirLeft:
	test al,BIOS_KEYBOARD_FLAGS_RIGHT_SHIFT
	jz skipDirRight
	inc bx
skipDirRight:

	; Move left.
	cmp bl,0ffh
	jne skipMoveLeft
	; Compute new posX.
	mov cx,[TestGameplayPosXLow]
	sub cx,TEST_GAMEPLAY_SPEEDX_LOW
	mov dx,[TestGameplayPosXHigh]
	sbb dx,TEST_GAMEPLAY_SPEEDX_HIGH
	; Limit posX if needed.
	cmp dx,TEST_GAMEPLAY_POSX_LIMIT_LEFT
	jae skipLimitPosXLeft
	xor cx,cx
	mov dx,TEST_GAMEPLAY_POSX_LIMIT_LEFT
skipLimitPosXLeft:
	; Save new posX.
	mov [TestGameplayPosXLow],cx
	mov [TestGameplayPosXHigh],dx
skipMoveLeft:

	; Move right.
	cmp bl,1
	jne skipMoveRight
	; Compute new posX.
	mov cx,[TestGameplayPosXLow]
	add cx,TEST_GAMEPLAY_SPEEDX_LOW
	mov dx,[TestGameplayPosXHigh]
	adc dx,TEST_GAMEPLAY_SPEEDX_HIGH
	; Limit posX if needed.
	cmp dx,TEST_GAMEPLAY_POSX_LIMIT_RIGHT
	jb skipLimitPosXRight
	xor cx,cx
	mov dx,TEST_GAMEPLAY_POSX_LIMIT_RIGHT
skipLimitPosXRight:
	; Save new posX.
	mov [TestGameplayPosXLow],cx
	mov [TestGameplayPosXHigh],dx
skipMoveRight:

	; Shoot.
	test al,BIOS_KEYBOARD_FLAGS_CTRL
	jz skipShot
	mov cx,[TestGameplayShotCount]
	cmp cx,TEST_GAMEPLAY_SHOT_MAX_COUNT
	je skipShot
	cmp [TestGameplayShotCooldown],0
	jne skipShot
	mov [TestGameplayShotCooldown],TEST_GAMEPLAY_SHOT_COOLDOWN
	; Don't need to read this again if dx is not overriden.
	mov dx,[TestGameplayPosXHigh]
	mov di,cx
	shl di,1
	mov [TestGameplayShotPosX + di],dx
	mov [TestGameplayShotPosYPacked + di],TEST_GAMEPLAY_SHOT_POSY_START_PACKED
	; If the shot was updated after this, setting prev pos wouldn't be needed, is it worth doing?
	mov byte ptr [TestGameplayShotPrevPosY + di],TEST_GAMEPLAY_SHOT_POSY_START
	inc cx
	mov byte ptr [TestGameplayShotCount],cl
skipShot:

	ret
testGameplayUpdate endp

; Input: di (pointer to the position in TestGameplayShotPosYPacked of the shot to be deleted).
testGameplayDeleteShot proc private
	; Decrement shot count.
	mov bx,[TestGameplayShotCount]
	dec bx
	mov [TestGameplayShotCount],bx
	; Compute index of the last shot.
	shl bx,1
	; Increment render delete count.
	mov ax,[TestGameplayRenderDeleteCount]
	push si
	mov si,ax
	inc ax
	mov [TestGameplayRenderDeleteCount],ax
	shl si,1
	; Copy data to wipe shot from video memory on the next call to render.
	mov ax,[(TestGameplayShotPosX - TestGameplayShotPosYPacked) + di]
	sub ax,TEST_GAMEPLAY_SHOT_HALF_WIDTH
	mov [TestGameplayRenderDeletePosX + si],ax
	mov al,byte ptr [di + 1]
	sub al,TEST_GAMEPLAY_SHOT_HALF_HEIGHT
	mov byte ptr [TestGameplayRenderDeletePosY + si],al
	mov al,TEST_GAMEPLAY_SHOT_WIDTH
	mov byte ptr [TestGameplayRenderDeleteWidth + si],al
	mov al,TEST_GAMEPLAY_SHOT_HEIGHT
	mov byte ptr [TestGameplayRenderDeleteHeight + si],al
	; Copy data from last shot over deleted shot.
	mov ax,[TestGameplayShotPosX + bx]
	mov [(TestGameplayShotPosX - TestGameplayShotPosYPacked) + di],ax
	mov ax,[TestGameplayShotPosYPacked + bx]
	mov [di],ax
	mov al,byte ptr [TestGameplayShotPrevPosY + bx]
	mov byte ptr [(TestGameplayShotPrevPosY - TestGameplayShotPosYPacked) + di],al
	pop si

	ret
testGameplayDeleteShot endp

testGameplayInitRender proc private
	call testGameplayRender
	; Execute code after the regular render function so the ES segment is set to video memory.
	mov cx,0
	mov bx,BIOS_VIDEO_MODE_320_200_4_WIDTH
	mov dl,TEST_GAMEPLAY_POSY_BOX_END
	mov dh,2
	call drawHorizLine
	ret
testGameplayInitRender endp

testGameplayRender proc private
	mov ax,BIOS_VIDEO_MODE_320_200_4_START_ADDR
	mov es,ax

	WAIT_VSYNC
	xor dx,dx
	CONSOLE_SET_CURSOR_POS
	mov dl,byte ptr [TestGameplayShotCount]
	call consolePrintByte
	mov dx,100h
	CONSOLE_SET_CURSOR_POS
	mov dl,[TestGameplayShotCooldown]
	call consolePrintByte
	
	; Clear deleted sprites.
	mov cx,[TestGameplayRenderDeleteCount]
	test cx,cx
	jz loopDeleteDone
	xor di,di
loopDelete:
	push cx
		
	mov cx,[TestGameplayRenderDeletePosX + di]
	mov bx,cx
	add bx,[TestGameplayRenderDeleteWidth + di]
	mov dl,byte ptr [TestGameplayRenderDeletePosY + di]
	mov dh,dl
	add dh,byte ptr [TestGameplayRenderDeleteHeight + di]
	mov al,0
	call drawBox

	inc di
	inc di
	pop cx
	loop loopDelete
	
	; Set delete count back to zero.
	mov [TestGameplayRenderDeleteCount],cx
loopDeleteDone:

	; Render shots.
	mov cx,[TestGameplayShotCount]
	test cx,cx
	jz loopShotDone
	xor di,di
loopShot:
	push cx

	; Erase previous shot.
	mov cx,[TestGameplayShotPosX + di]
	sub cx,TEST_GAMEPLAY_SHOT_HALF_WIDTH
	mov bx,cx
	add bx,TEST_GAMEPLAY_SHOT_WIDTH
	mov dl,byte ptr [TestGameplayShotPrevPosY + di]
	sub dl,TEST_GAMEPLAY_SHOT_HALF_HEIGHT
	mov dh,dl
	add dh,TEST_GAMEPLAY_SHOT_HEIGHT
	mov al,0
	call drawBox

	; Draw current shot.
	mov cx,[TestGameplayShotPosX + di]
	sub cx,TEST_GAMEPLAY_SHOT_HALF_WIDTH
	mov bx,cx
	add bx,TEST_GAMEPLAY_SHOT_WIDTH
	mov dl,byte ptr [(TestGameplayShotPosYPacked + 1) + di]
	sub dl,TEST_GAMEPLAY_SHOT_HALF_HEIGHT
	mov dh,dl
	add dh,TEST_GAMEPLAY_SHOT_HEIGHT
	mov al,1
	call drawBox

	inc di
	inc di
	pop cx
	loop loopShot
loopShotDone:

	; Erase previous box.
	mov cx,[TestGameplayPrevPosXHigh]
	sub cx,TEST_GAMEPLAY_BOX_HALF_WIDTH
	mov bx,cx
	add bx,TEST_GAMEPLAY_BOX_WIDTH
	mov dx,TEST_GAMEPLAY_POSY_BOX_START + (TEST_GAMEPLAY_POSY_BOX_END * 256)
	mov al,0
	call drawBox

	; Draw current box.
	mov cx,[TestGameplayPosXHigh]
	sub cx,TEST_GAMEPLAY_BOX_HALF_WIDTH
	mov bx,cx
	add bx,TEST_GAMEPLAY_BOX_WIDTH
	mov dx,TEST_GAMEPLAY_POSY_BOX_START + (TEST_GAMEPLAY_POSY_BOX_END * 256)
	mov al,3
	call drawBox

	ret
testGameplayRender endp

code ends

constData segment public
	StrWrongVideoCard				db 'You need a Color Graphics Adapter to play this game.$'
	DrawPixelMask					db 00111111b, 11001111b, 11110011b, 11111100b
	DrawPixelShift 					db 6, 4, 2, 0
constData ends

data segment public
	TestGameplayShotCooldown		db ?
	; The shot count will be stored in the LSB, the MSB will remain at zero.
	TestGameplayShotCount			dw ?
	TestGameplayShotPosX			dw TEST_GAMEPLAY_SHOT_MAX_COUNT dup (?)
	TestGameplayShotPosYPacked		dw TEST_GAMEPLAY_SHOT_MAX_COUNT dup (?)
	; The shot prev posY will be stored in the LSB, the MSB is unused.
	TestGameplayShotPrevPosY		dw TEST_GAMEPLAY_SHOT_MAX_COUNT dup (?)
	TestGameplayPosXLow				dw ?
	TestGameplayPosXHigh			dw ?
	TestGameplayPrevPosXHigh		dw ?
	TestGameplayRenderDeleteCount	dw TEST_GAMEPLAY_RENDER_DELETE_MAX_COUNT dup (?)
	; The render delete posX and PosY are measured from the top left corner. 
	TestGameplayRenderDeletePosX	dw TEST_GAMEPLAY_RENDER_DELETE_MAX_COUNT dup (?)
	; The render delete posY will be stored in the LSB, the MSB is unused.
	TestGameplayRenderDeletePosY	dw TEST_GAMEPLAY_RENDER_DELETE_MAX_COUNT dup (?)
	; The render delete size will be stored in the LSB, the MSB is unused.
	TestGameplayRenderDeleteWidth	dw TEST_GAMEPLAY_RENDER_DELETE_MAX_COUNT dup (?)
	TestGameplayRenderDeleteHeight	dw TEST_GAMEPLAY_RENDER_DELETE_MAX_COUNT dup (?)
data ends

	end main
