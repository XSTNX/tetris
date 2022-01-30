include code\console.inc
include code\errcode.inc
include code\keyboard.inc
include code\render.inc

setLevelGameState macro
	mov [GameInitProc],offset allSegments:levelInit
	mov [GameInitRenderProc],offset allSegments:levelInitRender
	mov [GameUpdateProc],offset allSegments:levelUpdate
	mov [GameRenderProc],offset allSegments:levelRender
endm

setTestGameState macro
	mov [GameInitProc],offset allSegments:testInit
	mov [GameInitRenderProc],offset allSegments:testInitRender
	mov [GameUpdateProc],offset allSegments:testUpdate
	mov [GameRenderProc],offset allSegments:testRender
endm

setTest2GameState macro
	mov [GameInitProc],offset allSegments:test2Init
	mov [GameInitRenderProc],offset allSegments:test2InitRender
	mov [GameUpdateProc],offset allSegments:test2Update
	mov [GameRenderProc],offset allSegments:test2Render
endm

allSegments group code, constData, data
    assume cs:allSegments, ds:allSegments

code segment readonly public

extern consolePrintByte:proc, consolePrintByteHex:proc, consolePrintString:proc
extern levelInit:proc, levelInitRender:proc, levelUpdate:proc, levelRender:proc
extern testInit:proc, testInitRender:proc, testUpdate:proc, testRender:proc
extern test2Init:proc, test2InitRender:proc, test2Update:proc, test2Render:proc

; ------------;
; Code public ;
; ------------;

; -------------;
; Code private ;
; -------------;

	org 100h
main proc private
	; Game states should assume the direction flag is always reset.
	cld

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
	;setTest2GameState

	call [GameInitProc]
	; Game states should assume the extra segment points to video memory at the start of the render functions.
	mov ax,BIOS_VIDEO_MODE_320_200_4_START_ADDR
	mov es,ax
	waitVSync
	call [GameInitRenderProc]
gameLoop:
	call [GameUpdateProc]
	call testPaletteChange
	; Game states should assume the extra segment points to video memory at the start of the render functions.
	mov ax,BIOS_VIDEO_MODE_320_200_4_START_ADDR
	mov es,ax
	waitVSync
	call [GameRenderProc]

	; Continue gameloop until ESC is pressed.
if KEYBOARD_ENABLED
	keyboardIsKeyPressed BIOS_KEYBOARD_SCANCODE_ESC
else
	; If keyboard is disabled, a different way to check for ESC is needed.
	call testCheckKeyboardBufferForESCKey
endif
	jnz short gameLoop

	; Restore previous video mode.
	mov al,[GamePrevVideoMode]
	mov ah,BIOS_VIDEO_FUNC_SET_VIDEO_MODE
	int BIOS_VIDEO_INT

quit:
	call keyboardStop
	dosQuitCOM
main endp

ife KEYBOARD_ENABLED
; Output: zf (zero flag set if ESC is pressed).
testCheckKeyboardBufferForESCKey proc private
checkBuffer:
	mov ah,BIOS_KEYBOARD_FUNC_CHECK_KEY
	int BIOS_KEYBOARD_INT
	jnz getKey
	; Clear zero flag and return, since the buffer is empty.
	or ah,0ffh
	ret
getKey:
	; Remove key from the buffer.
	mov ah,BIOS_KEYBOARD_FUNC_GET_KEY
	int BIOS_KEYBOARD_INT
	cmp ah,BIOS_KEYBOARD_SCANCODE_ESC
	; If key is not ESC, look in the buffer again.
	jne checkBuffer
	ret
testCheckKeyboardBufferForESCKey endp
endif

testPaletteChange proc private
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

ifdef DEBUG

testKeyboardScancode proc private
	mov dx,offset ds:strStart
	call consolePrintString

nextKey:
	mov ah,BIOS_KEYBOARD_FUNC_GET_KEY
	int BIOS_KEYBOARD_INT
	cmp al,3
	je short quit
	; Save returned data.
	push ax

	; Print scancode.
	mov dx,offset ds:strScancode
	call consolePrintString
	pop ax
	push ax
	mov dl,ah
	call consolePrintByteHex

	; Print ascii.
	mov dx,offset ds:strASCII
	call consolePrintString
	pop ax
	consolePrintChar al

	consoleNextLine
	jmp short nextKey

quit:
	dosQuitCOM

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

	consoleNextLine

	; Continue until a key is pressed.
	mov ah,DOS_REQUEST_FUNC_INPUT_STATUS
	int DOS_REQUEST_INT
	test al,al
	jz short nextKey

	dosQuitCOM
testKeyboardFlags endp

testDOSVersion proc private
	mov ah,DOS_REQUEST_FUNC_GET_VERSION_NUM
	int DOS_REQUEST_INT
	push bx
	push ax

	mov dx,offset ds:strVer
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
	
	mov dx,offset ds:strDOSType
	call consolePrintString

	; Dos type.
	pop dx
	mov dl,dh
	call consolePrintByteHex

	dosQuitCOM
strVer:
	db "Ver: ", 0
strDOSType:
	db " DosType: ", 0
testDOSVersion endp

endif

code ends

constData segment readonly public
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
