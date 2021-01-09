include code\console.inc

SET_LEVEL_GAME_STATE macro
	mov [GameInitProc],offset levelInit
	mov [GameInitRenderProc],offset levelInitRender
	mov [GameUpdateProc], offset levelUpdate
	mov [GameRenderProc], offset levelRender
endm

SET_TEST_GAME_STATE macro
	mov [GameInitProc],offset testInit
	mov [GameInitRenderProc],offset testInitRender
	mov [GameUpdateProc], offset testUpdate
	mov [GameRenderProc], offset testRender
endm

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

allSegments group code, constData, data
    assume cs:allSegments, ds:allSegments

code segment public

extern consolePrintByte:proc, consolePrintByteHex:proc, consolePrintString:proc
extern levelInit:proc, levelInitRender:proc, levelUpdate:proc, levelRender:proc
extern testInit:proc, testInitRender:proc, testUpdate:proc, testRender:proc

;----------;
; Private. ;
;----------;

	org 100h
main proc private
	; Read current video mode.
	mov ah,BIOS_VIDEO_FUNC_GET_VIDEO_MODE
	int BIOS_VIDEO_INT
	; Check if video card is valid.
	cmp al,BIOS_VIDEO_MODE_80_25_TEXT_MONO
	jne short gameStart
	; If not, print wrong video card message and quit.
	mov dx,offset StrWrongVideoCard
	call consolePrintString
	DOS_QUIT

gameStart:
	; Save current video mode.
	push ax

	; Set new video mode.
	mov al,BIOS_VIDEO_MODE_320_200_4_COLOR
	mov ah,BIOS_VIDEO_FUNC_SET_VIDEO_MODE
	int BIOS_VIDEO_INT
	; Set palette 0.
	mov bx,100h
	mov ah,BIOS_VIDEO_FUNC_SET_PLT_BKG_BDR
	int BIOS_VIDEO_INT

	; Start the game directly on the level for now.
	SET_LEVEL_GAME_STATE
	;SET_TEST_GAME_STATE

	call [GameInitProc]
	WAIT_VSYNC
	call [GameInitRenderProc]
gameLoop:
	call [GameUpdateProc]
	WAIT_VSYNC
	call [GameRenderProc]
	
	; Don't quit the gameloop until ESC is pressed.
	mov ah,DOS_REQUEST_FUNC_INPUT_STATUS
	int DOS_REQUEST_INT
	test al,al
	jz short gameLoop
	mov ah,BIOS_KEYBOARD_FUNC_GET_CHAR
	int BIOS_KEYBOARD_INT
	cmp ah,BIOS_KEYBOARD_SCANCODE_ESC
	jne short gameLoop

	; Restore previous video mode and quit.
	pop ax
	mov ah,BIOS_VIDEO_FUNC_SET_VIDEO_MODE
	int BIOS_VIDEO_INT
	DOS_QUIT
main endp

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
	call consolePrintString
	pop ax
	push ax
	mov dl,ah
	call consolePrintByteHex

	mov dl," "
	CONSOLE_PRINT_CHAR

	; Print ascii.
	mov dx,offset strASCII
	call consolePrintString
	pop ax
	mov dl,al
	CONSOLE_PRINT_CHAR

	CONSOLE_GO_NEXT_LINE
	jmp short nextkey

quit:
	DOS_QUIT

strScancode:
	db "Scancode: ", 0
strASCII:
	db " ASCII: ", 0
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

testDOSVersion proc private
	mov ah,DOS_REQUEST_FUNC_GET_VERSION_NUM
	int DOS_REQUEST_INT
	push bx
	push ax

	mov dx,offset strVer
	call consolePrintString

	; Major version.
	pop dx
	push dx
	call consolePrintByte
	
	mov dl,"."
	CONSOLE_PRINT_CHAR
	
	; Minor version.
	pop dx
	mov dl,dh
	call consolePrintByte
	
	mov dx,offset strDOSType
	call consolePrintString

	; Dos type.
	pop dx
	mov dl,dh
	call consolePrintByteHex

	ret
strVer:
	db "Ver: ", 0
strDOSType:
	db " DosType: ", 0
testDOSVersion endp

code ends

constData segment public
	StrWrongVideoCard				db "You need a Color Graphics Adapter to play this game.", 0
constData ends

data segment public
	GameInitProc		dw ?
	GameInitRenderProc	dw ?
	GameUpdateProc		dw ?
	GameRenderProc		dw ?
data ends

end main
