include ascii.inc
include bios.inc
include dos.inc

TEST_GAMEPLAY_BOX_WIDTH 		equ 8
TEST_GAMEPLAY_BOX_HEIGHT 		equ 12
TEST_GAMEPLAY_POSX_LIMIT_LEFT 	equ 30
TEST_GAMEPLAY_POSX_LIMIT_RIGHT 	equ 290
TEST_GAMEPLAY_POSX_START 		equ 160
TEST_GAMEPLAY_POSY 				equ 190
TEST_GAMEPLAY_POSY_BOX_START	equ TEST_GAMEPLAY_POSY - (TEST_GAMEPLAY_BOX_HEIGHT/2)
TEST_GAMEPLAY_POSY_BOX_END		equ TEST_GAMEPLAY_POSY_BOX_START + TEST_GAMEPLAY_BOX_HEIGHT
TEST_GAMEPLAY_SPEEDX_LOW 		equ 0
TEST_GAMEPLAY_SPEEDX_HIGH 		equ 5
TEST_GAMEPLAY_SHOT_POSX_START 	equ 155
TEST_GAMEPLAY_SHOT_SPEED_LOW	equ 0
TEST_GAMEPLAY_SHOT_SPEED_HIGH	equ 7
TEST_GAMEPLAY_SHOT_COOLDOWN 	equ 10
TEST_GAMEPLAY_SHOT_MAX_COUNT 	equ 4

allSegments group code, data
    assume cs:allSegments, ds:allSegments

code segment public
	org 100h

main proc
	; Save previous video mode.
	mov ah,BIOS_VIDEO_FUNC_GET_VIDEO_MODE
	int BIOS_VIDEO_INT
	push ax

	; Set graphics mode.
	mov al,BIOS_VIDEO_MODE_320_200_4_BURST_ON
	mov ah,BIOS_VIDEO_FUNC_SET_VIDEO_MODE
	int BIOS_VIDEO_INT	
	; Set palette 0.
	mov bx,100h
	mov ah,BIOS_VIDEO_FUNC_SET_PLT_BKG_BDR
	int BIOS_VIDEO_INT

	call testGameplayInit
	call testGameplayRender
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

	; Quit.
	int DOS_COM_TERMINATION_INT
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

; Input: dh (row), dl (col)
SET_CURSOR_POS macro
    ; Use page number 0.
    xor bh,bh
    mov ah,BIOS_VIDEO_FUNC_SET_CURSOR_POS
    int BIOS_VIDEO_INT
endm

printNibbleHex proc
	and dl,0fh
	cmp dl,10
	jb short noLetter
	add dl,'A'-10
	jmp short printChar
noLetter:
	add dl,'0'
printChar:
	mov ah,DOS_REQUEST_FUNC_PRINT_CHAR
	int DOS_REQUEST_INT
	ret
printNibbleHex endp

printByte proc
	mov al,dl
	mov bl,10
	xor cx,cx
divide:
	xor ah,ah
	div bl
	push ax
	inc cx
	test al,al
	jne divide
	mov bx,3
	sub bx,cx
	jz nextDigit
leadingZeroes:
	xor dl,dl
	call printNibbleHex
	dec bx
	jnz leadingZeroes
nextDigit:
	pop dx
	mov dl,dh
	call printNibbleHex
	loop nextDigit
	ret
printByte endp

printByteHex proc
	mov ch,dl
	mov cl,4
	shr dl,cl
	call printNibbleHex
	mov dl,ch
	call printNibbleHex
	ret
printByteHex endp

printWord proc
	mov ax,dx
	mov bx,10
	xor cx,cx
divide:
	xor dx,dx
	div bx
	push dx
	inc cx
	test ax,ax
	jne divide
	; Setting bl is enough since bh is zero.
	mov bl,5
	sub bl,cl
	jz nextDigit
leadingZeroes:	
	xor dl,dl
	call printNibbleHex
	dec bx
	jnz leadingZeroes
nextDigit:
	pop dx
	call printNibbleHex
	loop nextDigit
	ret
printWord endp

printWordHex proc
	xchg dl,dh
	call printByteHex
	mov dl,dh
	call printByteHex
	ret
printWordHex endp

DRAW_PIXEL macro
local notOddRow
	xor bx,bx
	; Divide posY by two, since the even rows go in one bank and the odd rows in another.
	shr dl,1
	jnc notOddRow
	; If it's an odd row, the bank starts at offset 2000h instead of 0000h.
	mov bh,20h
notOddRow:
	; Multiply posY by 80 to obtain the offset in video memory to the row the pixel belongs to.
	mov al,80
	mul dl
	or bx,ax
	; Save the last two bits of posX, since they decide which bits in the video memory byte the pixel belong to.
	mov si,cx
	and si,11b
	; Divide posX by four to obtain the offset in video memory to the column the pixel belongs to.
	shr cx,1
	shr cx,1	
	add bx,cx
	; Read the byte in video memory where the pixel is.
	mov al,es:[bx]
	; Mask the previous pixel.
	and al,DrawPixelMask[si]
	; Add the new pixel.
	mov cl,DrawPixelShift[si]
	shl dh,cl
	or al,dh
	; Write the updated byte to video memory.
	mov es:[bx],al
endm

drawHorizLine proc
	push bx
	push cx
	push dx
	DRAW_PIXEL
	pop dx
	pop cx
	pop bx
	inc cx
	cmp cx,bx
	jb short drawHorizLine
	ret
drawHorizLine endp

drawBox proc
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
	jb short drawBox
	ret
drawBox endp

testKeyboardScancode proc
nextKey:
	mov ah,BIOS_KEYBOARD_FUNC_GET_CHAR
	int BIOS_KEYBOARD_INT
	cmp al,3
	je quit

	; Print scancode.
	push ax
	mov dl,ah
	call printByteHex

	; Print ascii.
	mov dl,' '
	mov ah,DOS_REQUEST_FUNC_PRINT_CHAR
	int DOS_REQUEST_INT
	pop ax
	mov dl,al
	mov ah,DOS_REQUEST_FUNC_PRINT_CHAR
	int DOS_REQUEST_INT

	; Go to next line.
	mov dl,ASCII_CR
	mov ah,DOS_REQUEST_FUNC_PRINT_CHAR
	int DOS_REQUEST_INT
	mov dl,ASCII_LF
	mov ah,DOS_REQUEST_FUNC_PRINT_CHAR
	int DOS_REQUEST_INT

	jmp short nextkey

quit:
	int DOS_COM_TERMINATION_INT
testKeyboardScancode endp

testKeyboardFlags proc
nextKey:
	mov ah,BIOS_KEYBOARD_FUNC_GET_FLAGS
	int BIOS_KEYBOARD_INT
	mov dl,al
	call printByteHex

	; Go to next line.
	mov dl,ASCII_CR
	mov ah,DOS_REQUEST_FUNC_PRINT_CHAR
	int DOS_REQUEST_INT
	mov dl,ASCII_LF
	mov ah,DOS_REQUEST_FUNC_PRINT_CHAR
	int DOS_REQUEST_INT

	; Continue until a key is pressed.
	mov ah,DOS_REQUEST_FUNC_INPUT_STATUS
	int DOS_REQUEST_INT
	test al,al
	jz short nextKey

	ret
testKeyboardFlags endp

testVideo1 proc
	mov al,1
	mov cx,0
	mov bx,320
	mov dx,50
	call drawHorizLine
	mov al,2
	mov cx,0
	mov bx,320
	mov dx,100
	call drawHorizLine
	mov al,3
	mov cx,0
	mov bx,320
	mov dx,150
	call drawHorizLine

	ret
testVideo1 endp

testVideo2 proc
	mov ax,0b800h
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
testVideo2 endp

testVideo3 proc
	mov ax,0b800h
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
	mov bx,320
	; PosY.
	mov dl,100
	; Color.
	mov dh,1
	call drawHorizLine
	; Start posX.
	mov cx,0
	; End posX.
	mov bx,320
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
	mov bx,320
	; Start posY.
	mov dl,102
	; End posY.
	mov dh,105
	; Color.
	mov al,3
	call drawBox

	ret
testVideo3 endp

testDOSVersion proc
	mov ah,DOS_REQUEST_FUNC_GET_VERSION_NUM
	int DOS_REQUEST_INT
	push bx
	push ax	

	mov dx,strVer
	mov ah,DOS_REQUEST_FUNC_PRINT_STRING
	int DOS_REQUEST_INT

	; Major version.
	pop dx
	push dx
	call printByte
	
	mov dl,'.'
	mov ah,DOS_REQUEST_FUNC_PRINT_CHAR
	int DOS_REQUEST_INT
	
	; Minor version.
	pop dx
	mov dl,dh
	call printByte
	
	mov dx,strDOSType
	mov ah,DOS_REQUEST_FUNC_PRINT_STRING
	int DOS_REQUEST_INT

	; Dos type.
	pop dx
	mov dl,dh
	call printByteHex

	ret
strVer:
	db 'Ver: $'
strDOSType:
	db ' DosType: $'
testDOSVersion endp

testGameplayInit proc
	mov ax,0b800h
	mov es,ax

	mov [TestGameplayPosXLow],0
	mov ax,TEST_GAMEPLAY_POSX_START
	mov [TestGameplayPosXHigh],ax
	mov [TestGameplayPrevPosXHigh],ax

	mov [TestGameplayShotCooldown],0
	mov [TestGameplayShotCount],0
testGameplayInit endp

testGameplayUpdate proc
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
	mov cl,[TestGameplayShotCount]
	test cl,cl
	jz loopShotDone
	xor bx,bx
	xor ch,ch
loopShot:
	mov al,[TestGameplayShotPosYLow + bx]
	sub al,TEST_GAMEPLAY_SHOT_SPEED_LOW
	mov [TestGameplayShotPosYLow + bx],al
	mov al,[TestGameplayShotPosYHigh + bx]
	sbb al,TEST_GAMEPLAY_SHOT_SPEED_High
	mov [TestGameplayShotPosYHigh + bx],al
	inc bx
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
	mov bl,[TestGameplayShotCount]
	cmp bl,TEST_GAMEPLAY_SHOT_MAX_COUNT
	jae skipShot
	cmp [TestGameplayShotCooldown],0
	jne skipShot
	mov [TestGameplayShotCooldown],TEST_GAMEPLAY_SHOT_COOLDOWN
	mov ax,[TestGameplayPosXHigh]
	xor bh,bh
	mov [TestGameplayShotPosX + bx],ax
	mov [TestGameplayShotPosYLow + bx],bh
	mov [TestGameplayShotPosYHigh + bx],TEST_GAMEPLAY_SHOT_POSX_START
	inc bx
	mov [TestGameplayShotCount],bl
skipShot:

	ret
testGameplayUpdate endp

testGameplayRender proc
	WAIT_VSYNC
	xor dx,dx
	SET_CURSOR_POS
	mov dl,[TestGameplayShotCount]
	call printByte
	mov dx,100h
	SET_CURSOR_POS
	mov dl,[TestGameplayShotCooldown]
	call printByte

	; --- Erase previous box. ---
	; Start posX.
	mov cx,[TestGameplayPrevPosXHigh]
	sub cx,TEST_GAMEPLAY_BOX_WIDTH/2
	; End posX.
	mov bx,cx
	add bx,TEST_GAMEPLAY_BOX_WIDTH
	; Start/end posY.
	mov dx,TEST_GAMEPLAY_POSY_BOX_START + (TEST_GAMEPLAY_POSY_BOX_END * 256)
	; Color.
	mov al,0
	call drawBox

	; --- Draw current box. ---
	; Start posX.
	mov cx,[TestGameplayPosXHigh]
	sub cx,TEST_GAMEPLAY_BOX_WIDTH/2
	; End posX.
	mov bx,cx
	add bx,TEST_GAMEPLAY_BOX_WIDTH
	; Start/end posY.
	mov dx,TEST_GAMEPLAY_POSY_BOX_START + (TEST_GAMEPLAY_POSY_BOX_END * 256)
	; Color.
	mov al,3
	call drawBox

	ret
testGameplayRender endp

code ends

data segment public
	DrawPixelMask				db 00111111b, 11001111b, 11110011b, 11111100b
	DrawPixelShift 				db 6, 4, 2, 0
	TestGameplayShotCooldown	db ?	
	TestGameplayShotCount		db ?
	TestGameplayShotPosX		dw TEST_GAMEPLAY_SHOT_MAX_COUNT dup (?)
	TestGameplayShotPosYLow		db TEST_GAMEPLAY_SHOT_MAX_COUNT dup (?)
	TestGameplayShotPosYHigh	db TEST_GAMEPLAY_SHOT_MAX_COUNT dup (?)
	TestGameplayPosXLow			dw ?
	TestGameplayPosXHigh		dw ?
	TestGameplayPrevPosXHigh	dw ?
data ends

	end main
