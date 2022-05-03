GAME_NO_EXTERNS equ 1
include code\game.inc
include code\console.inc
include code\dos.inc
include code\errcode.inc
include code\keyboard.inc
include code\level.inc
include code\render.inc
include code\test.inc
include code\test2.inc
include code\test3.inc
include code\test4.inc

GAME_SET_LEVEL_GAME_STATE macro
	mov [GameStateInitProc],offset allSegments:levelInit
	mov [GameStateInitRenderProc],offset allSegments:levelInitRender
	mov [GameStateUpdateProc],offset allSegments:levelUpdate
	mov [GameStateRenderProc],offset allSegments:levelRender
endm

GAME_SET_TEST_GAME_STATE macro
	mov [GameStateInitProc],offset allSegments:testInit
	mov [GameStateInitRenderProc],offset allSegments:testInitRender
	mov [GameStateUpdateProc],offset allSegments:testUpdate
	mov [GameStateRenderProc],offset allSegments:testRender
endm

GAME_SET_TEST2_GAME_STATE macro
	mov [GameStateInitProc],offset allSegments:test2Init
	mov [GameStateInitRenderProc],offset allSegments:test2InitRender
	mov [GameStateUpdateProc],offset allSegments:test2Update
	mov [GameStateRenderProc],offset allSegments:test2Render
endm

GAME_SET_TEST3_GAME_STATE macro
	mov [GameStateInitProc],offset allSegments:test3Init
	mov [GameStateInitRenderProc],offset allSegments:test3InitRender
	mov [GameStateUpdateProc],offset allSegments:test3Update
	mov [GameStateRenderProc],offset allSegments:test3Render
endm

GAME_SET_TEST4_GAME_STATE macro
	mov [GameStateInitProc],offset allSegments:test4Init
	mov [GameStateInitRenderProc],offset allSegments:test4InitRender
	mov [GameStateUpdateProc],offset allSegments:test4Update
	mov [GameStateRenderProc],offset allSegments:test4Render
endm

VIDEO_SET_VIDEO_MODE macro
	; Set new video mode.
	mov ax,BIOS_VIDEO_MODE_320_200_4_COLOR + (BIOS_VIDEO_FUNC_SET_VIDEO_MODE * 256)
	int BIOS_VIDEO_INT
	; Set palette num.
	RENDER_SET_PALETTE_320x200x4 0
if CONSOLE_ENABLED
	; Set console cursor pos.
	call readCurrentCursorPosAndSetConsoleCursorPos
endif
endm

VIDEO_START macro
local skip, skipNotValid
	cmp [GameVideoAlreadyInitalized],0
	jne short skip
	;; Read current video mode.
	mov ah,BIOS_VIDEO_FUNC_GET_VIDEO_MODE
	int BIOS_VIDEO_INT
	;; Check if video mode is valid.
	cmp al,BIOS_VIDEO_MODE_80_25_TEXT_MONO
	jne short skipNotValid
	GAME_QUIT ERROR_CODE_VIDEO
skipNotValid:
	;; Save and set current video mode.
	mov [GamePrevVideoMode],al
	VIDEO_SET_VIDEO_MODE
	inc [GameVideoAlreadyInitalized]
skip:
endm

VIDEO_STOP macro
	cmp [GameVideoAlreadyInitalized],1
	jne short @f
	;; Restore previous video mode.
	mov al,[GamePrevVideoMode]
	mov ah,BIOS_VIDEO_FUNC_SET_VIDEO_MODE
	int BIOS_VIDEO_INT
	dec [GameVideoAlreadyInitalized]
@@:
endm

allSegments group code, constData, data
    assume cs:allSegments, ds:allSegments, es:allSegments

code segment readonly public

	org 100h
gameMain proc private
	; All procedures should assume the direction flag is reset.
	cld
if CONSOLE_ENABLED
	; Make sure console can print on the right place even before setting the video mode.
	call readCurrentCursorPosAndSetConsoleCursorPos
endif
	; Might make more sense to create this table at assembly time, need to figure out how to use the repeat macro.
	call renderInitMultiplyRowBy80Table
	call keyboardStart
	VIDEO_START

	; Start the game directly on the level for now.
	;GAME_SET_LEVEL_GAME_STATE
	;GAME_SET_TEST_GAME_STATE
	GAME_SET_TEST2_GAME_STATE
	;GAME_SET_TEST3_GAME_STATE
	;GAME_SET_TEST4_GAME_STATE

	call [GameStateInitProc]
	; Game states should assume the extra segment points to video memory at the start of the render functions.
	mov ax,BIOS_VIDEO_MODE_320_200_4_START_ADDR
	mov es,ax
	WAIT_VSYNC
	call [GameStateInitRenderProc]
gameLoop:
	call [GameStateUpdateProc]
	call testPaletteChange
	; Game states should assume the extra segment points to video memory at the start of the render functions.
	mov ax,BIOS_VIDEO_MODE_320_200_4_START_ADDR
	mov es,ax
	WAIT_VSYNC
	call [GameStateRenderProc]

	; Continue gameloop until ESC is pressed.
if KEYBOARD_ENABLED
	KEYBOARD_IS_KEY_PRESSED BIOS_KEYBOARD_SCANCODE_ESC
else
	; If keyboard is disabled, a different way to check for ESC is needed.
	call testCheckKeyboardBufferForESCKey
endif
	jnz short gameLoop
	
	GAME_QUIT ERROR_CODE_NONE
gameMain endp

; Input: al (error code).
; Output: does not return.
gameQuit proc
if CONSOLE_ENABLED
	; Save error code.
	push ax
endif	
	; Stop video and keyboard.
	VIDEO_STOP
	call keyboardStop
if CONSOLE_ENABLED	
	; Check for error.
	pop ax
	cmp al,ERROR_CODE_NONE
	je @f
	; Print error.
	push ax
	mov si,offset allSegments:ErrorStr
	call consolePrintString
	pop ax
	call consolePrintByteHex
@@:
endif
	DOS_QUIT_COM
gameQuit endp

if CONSOLE_ENABLED
readCurrentCursorPosAndSetConsoleCursorPos proc private
	mov ah,BIOS_VIDEO_FUNC_GET_CURSOR_POS_SIZE
	int BIOS_VIDEO_INT
	call consoleSetCursorPos
	ret
readCurrentCursorPosAndSetConsoleCursorPos endp
endif

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
	; Remove key from buffer.
	mov ah,BIOS_KEYBOARD_FUNC_GET_KEY
	int BIOS_KEYBOARD_INT
	cmp ah,BIOS_KEYBOARD_SCANCODE_ESC
	; If key is not ESC, look in the buffer again.
	jne checkBuffer
	ret
testCheckKeyboardBufferForESCKey endp
endif

testPaletteChange proc private
	KEYBOARD_IS_KEY_PRESSED BIOS_KEYBOARD_SCANCODE_1
	jnz skipChangePaletteNum0
	RENDER_SET_PALETTE_320x200x4 0
	; Returns here just in case, so the palette can't be changed two times in the same frame.
	ret
skipChangePaletteNum0:
	KEYBOARD_IS_KEY_PRESSED BIOS_KEYBOARD_SCANCODE_2
	jnz skipChangePaletteNum1
	RENDER_SET_PALETTE_320x200x4 1
skipChangePaletteNum1:
	ret
testPaletteChange endp

if CONSOLE_ENABLED

testKeyboardScancode proc private
	mov si,offset allSegments:strStart
	call consolePrintString
nextKey:
	mov ah,BIOS_KEYBOARD_FUNC_GET_KEY
	int BIOS_KEYBOARD_INT
	cmp al,ASCII_EOT
	je short quit
	; Save returned data.
	push ax

	; Print scancode.
	mov si,offset allSegments:strScancode
	call consolePrintString
	pop ax
	push ax
	mov dl,ah
	call consolePrintByteHex

	; Print ascii.
	mov si,offset allSegments:strASCII
	call consolePrintString
	pop ax
	call consolePrintChar

	call consoleNextLine
	jmp short nextKey
quit:
	GAME_QUIT ERROR_CODE_NONE

strStart:
	db "Press any key to see its scancode and ascii value, press CTRL-C to quit.", ASCII_CR, ASCII_LF, 0
strScancode:
	db "Scancode: ", 0
strASCII:
	db " - ASCII: ", 0
testKeyboardScancode endp

testKeyboardFlags proc private
printFlags:
	mov ah,BIOS_KEYBOARD_FUNC_GET_FLAGS
	int BIOS_KEYBOARD_INT
	mov dl,al
	call consolePrintByteHex
	call consoleNextLine

	; Continue until a key is pressed.
	mov ah,BIOS_KEYBOARD_FUNC_CHECK_KEY
	int BIOS_KEYBOARD_INT
	jz short printFlags

	; Remove key from buffer.
	mov ah,BIOS_KEYBOARD_FUNC_GET_KEY
	int BIOS_KEYBOARD_INT

	GAME_QUIT ERROR_CODE_NONE
testKeyboardFlags endp

testDOSVersion proc private
	mov ah,DOS_REQUEST_FUNC_GET_VERSION_NUM
	int DOS_REQUEST_INT
	push bx
	push ax

	mov si,offset allSegments:strVer
	call consolePrintString

	; Major version.
	pop dx
	push dx
	call consolePrintByte

	mov al,"."
	call consolePrintChar
	
	; Minor version.
	pop dx
	mov dl,dh
	call consolePrintByte

	mov si,offset allSegments:strDOSType
	call consolePrintString

	; Dos type.
	pop dx
	mov dl,dh
	call consolePrintByteHex

	GAME_QUIT ERROR_CODE_NONE
strVer:
	db "Ver: ", 0
strDOSType:
	db " DosType: ", 0
testDOSVersion endp

endif

code ends

constData segment readonly public
	ErrorStr				byte "Error code: 0x", 0
constData ends

data segment public
	GameStateInitProc				word ?
	GameStateInitRenderProc			word ?
	GameStateUpdateProc				word ?
	GameStateRenderProc				word ?
	GameVideoAlreadyInitalized		byte 0
	GamePrevVideoMode				byte ?
data ends

end gameMain
