include code\console.inc
include code\errcode.inc
include code\keyboard.inc
include code\render.inc

setLevelGameState macro
	mov [GameInitProc],offset levelInit
	mov [GameInitRenderProc],offset levelInitRender
	mov [GameUpdateProc],offset levelUpdate
	mov [GameRenderProc],offset levelRender
endm

setTestGameState macro
	mov [GameInitProc],offset testInit
	mov [GameInitRenderProc],offset testInitRender
	mov [GameUpdateProc],offset testUpdate
	mov [GameRenderProc],offset testRender
endm

WAIT_VSYNC macro
local vsyncWait0, vsyncWait1
	mov dx,3dah
vsyncWait0:
	in al,dx
	test al,8
	jnz short vsyncWait0
vsyncWait1:
	in al,dx
	test al,8
	jz short vsyncWait1
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
	call keyboardStart
	; Check if keyboard started properly.
	cmp al,ERROR_CODE_KEYBOARD_NONE
	je short skipKeyboardStartError
	; If not, print error message and quit.
	mov dx,offset StrErrorKeyboard
	call consolePrintString
	jmp short quit
skipKeyboardStartError:

	; Read current video mode.
	mov ah,BIOS_VIDEO_FUNC_GET_VIDEO_MODE
	int BIOS_VIDEO_INT
	; Check if video card is valid.
	cmp al,BIOS_VIDEO_MODE_80_25_TEXT_MONO
	jne short skipVideoModeError
	; If not, print error message and quit.
	mov dx,offset StrErrorVideoCard
	call consolePrintString
	jmp short quit
skipVideoModeError:

	; Save current video mode.
	mov [GamePrevVideoMode],al
	; Set new video mode.
	mov al,BIOS_VIDEO_MODE_320_200_4_COLOR
	mov ah,BIOS_VIDEO_FUNC_SET_VIDEO_MODE
	int BIOS_VIDEO_INT
	; Set palette num.
	renderSetPalette320x200x4 0

	; Start the game directly on the level for now.
	setLevelGameState
	;setTestGameState

	call [GameInitProc]
	WAIT_VSYNC
	call [GameInitRenderProc]
gameLoop:
	call [GameUpdateProc]
	call testPaletteChange
	WAIT_VSYNC
	call [GameRenderProc]

	; Continue gameloop until ESC is pressed.
	keyboardIsKeyPressed BIOS_KEYBOARD_SCANCODE_ESC
	jnz short gameLoop

	; Restore previous video mode.
	mov al,[GamePrevVideoMode]
	mov ah,BIOS_VIDEO_FUNC_SET_VIDEO_MODE
	int BIOS_VIDEO_INT

quit:
	call keyboardStop
	dosQuit
main endp

testPaletteChange proc
	keyboardIsKeyPressed BIOS_KEYBOARD_SCANCODE_1
	jnz skipChangePaletteNum0
	renderSetPalette320x200x4 0
	; Returns here just in case, so the palette can't be changed two times in the same frame.
	ret
skipChangePaletteNum0:
	keyboardIsKeyPressed BIOS_KEYBOARD_SCANCODE_2
	jnz skipChangePaletteNum1
	renderSetPalette320x200x4 1
skipChangePaletteNum1:
	ret
testPaletteChange endp

testKeyboardScancode proc private
	mov dx,offset strStart
	call consolePrintString

nextKey:
	mov ah,BIOS_KEYBOARD_FUNC_GET_CHAR
	int BIOS_KEYBOARD_INT
	cmp al,3
	je short quit
	; Save returned data.
	push ax

	; Print scancode.	
	mov dx,offset strScancode
	call consolePrintString
	pop ax
	push ax
	mov dl,ah
	call consolePrintByteHex

	; Print ascii.
	mov dx,offset strASCII
	call consolePrintString
	pop ax
	consolePrintChar al

	consoleGoToNextLine
	jmp short nextKey

quit:
	dosQuit

strStart:
	db "Press any key to see its scancode and ascii value, press CTRL-C to quit.", ASCII_CR, ASCII_LF, 0
strScancode:
	db "Scancode: ", 0
strASCII:
	db " - ASCII: ", 0
testKeyboardScancode endp

testKeyboardFlags proc private
nextKey:
	mov ah,BIOS_KEYBOARD_FUNC_GET_FLAGS
	int BIOS_KEYBOARD_INT
	mov dl,al
	call consolePrintByteHex

	consoleGoToNextLine

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

	consolePrintChar "."
	
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
	StrErrorVideoCard		byte "Video Error: You need a Color Graphics Adapter to play this game.", 0
	StrErrorKeyboard		byte "Keyboard error.", 0
constData ends

data segment public
	GameInitProc			word ?
	GameInitRenderProc		word ?
	GameUpdateProc			word ?
	GameRenderProc			word ?
	GamePrevVideoMode		byte ?
data ends

end main
