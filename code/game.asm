include code\game.inc
include code\console.inc
include code\dos.inc
include code\errcode.inc
include code\keyboard.inc
include code\level.inc
include code\render.inc
include code\test1.inc
include code\test2.inc
include code\test3.inc
include code\test4.inc
include code\test5.inc
include code\tetris.inc

GAME_SET_GAME_STATE_LEVEL macro
	mov ax,offset allSegments:levelInit
	mov bx,offset allSegments:levelInitRender
	mov cx,offset allSegments:levelUpdate
	mov dx,offset allSegments:levelRender
	call gameSetState
endm

GAME_SET_GAME_STATE_TEST1 macro
	mov ax,offset allSegments:test1Init
	mov bx,offset allSegments:test1InitRender
	mov cx,offset allSegments:test1Update
	mov dx,offset allSegments:test1Render
	call gameSetState
endm

GAME_SET_GAME_STATE_TEST2 macro
	mov ax,offset allSegments:test2Init
	mov bx,offset allSegments:test2InitRender
	mov cx,offset allSegments:test2Update
	mov dx,offset allSegments:test2Render
	call gameSetState
endm

GAME_SET_GAME_STATE_TEST3 macro
	mov ax,offset allSegments:test3Init
	mov bx,offset allSegments:test3InitRender
	mov cx,offset allSegments:test3Update
	mov dx,offset allSegments:test3Render
	call gameSetState
endm

GAME_SET_GAME_STATE_TEST4 macro
	mov ax,offset allSegments:test4Init
	mov bx,offset allSegments:test4InitRender
	mov cx,offset allSegments:test4Update
	mov dx,offset allSegments:test4Render
	call gameSetState
endm

GAME_SET_GAME_STATE_TEST5 macro
	mov ax,offset allSegments:test5Init
	mov bx,offset allSegments:test5InitRender
	mov cx,offset allSegments:test5Update
	mov dx,offset allSegments:test5Render
	call gameSetState
endm

GAME_SET_GAME_STATE_TETRIS macro
	mov ax,offset allSegments:tetrisInit
	mov bx,offset allSegments:tetrisInitRender
	mov cx,offset allSegments:tetrisUpdate
	mov dx,offset allSegments:tetrisRender
	call gameSetState
endm

GAME_SET_GAME_STATE_TETRIS macro
	mov ax,offset allSegments:tetrisInit
	mov bx,offset allSegments:tetrisInitRender
	mov cx,offset allSegments:tetrisUpdate
	mov dx,offset allSegments:tetrisRender
	call gameSetState
endm

VIDEO_START macro
local skip, skipNotValid
	cmp [GameVideoAlreadyInitalized],0
	jne short skip
	;; Read current video mode.
	RENDER_GET_VIDEO_MODE
	;; Check if video mode is valid.
	cmp al,BIOS_VIDEO_MODE_80_25_TEXT_MONO
	jne short skipNotValid
	GAME_QUIT ERROR_CODE_VIDEO
skipNotValid:
	;; Save and set current video mode.
	mov [GamePrevVideoMode],al
	;; Set new video mode
	RENDER_SET_VIDEO_MODE BIOS_VIDEO_MODE_320_200_4_COLOR
	;; Set new palette num.
	RENDER_SET_PALETTE_NUM BIOS_VIDEO_MODE_320_200_4_PALETTE_0
if CONSOLE_ENABLED
	; Set console cursor pos.
	call readCurrentCursorPosAndSetConsoleCursorColRow
endif
	inc [GameVideoAlreadyInitalized]
skip:
endm

VIDEO_STOP macro
local l
	cmp [GameVideoAlreadyInitalized],1
	jne short l
	;; Restore previous video mode.
	mov al,[GamePrevVideoMode]
	mov ah,BIOS_VIDEO_FUNC_SET_VIDEO_MODE
	int BIOS_VIDEO_INT
	dec [GameVideoAlreadyInitalized]
l:
endm

allSegments group code, constData, data
	assume cs:allSegments, ds:allSegments, es:nothing, ss:allSegments

code segment readonly public

;-------------;
; Code public ;
;-------------;

	org 100h
; This procedure is in the public area just because a com file requires the main function to be at the begining of the code segment,
; but it will not be called by anyone else, so it's not in the include file.
gameMain proc
	; All procedures should assume the direction flag is reset.
	cld
if CONSOLE_ENABLED
	; Make sure console can print on the right place even before setting the video mode.
	call readCurrentCursorPosAndSetConsoleCursorColRow
endif
	call renderStart
	call keyboardStart
	VIDEO_START

	; Start the game directly on the level for now.
	;GAME_SET_GAME_STATE_LEVEL
	;GAME_SET_GAME_STATE_TEST1
	;GAME_SET_GAME_STATE_TEST2
	;GAME_SET_GAME_STATE_TEST3
	;GAME_SET_GAME_STATE_TEST4
	;GAME_SET_GAME_STATE_TEST5
	GAME_SET_GAME_STATE_TETRIS

	call [GameStateInitProc]
	; Game states should assume the extra segment points to video memory at the start of the render functions.
	mov ax,BIOS_VIDEO_MODE_320_200_4_START_ADDR
	mov es,ax
	RENDER_WAIT_FOR_VSYNC
	call [GameStateInitRenderProc]
	mov ax,BIOS_VIDEO_MODE_320_200_4_START_ADDR
	mov es,ax
	call [GameStateRenderProc]
	; Point the extra segment back to start.
	mov ax,ds
	mov es,ax
gameLoop:
	call [GameStateUpdateProc]
	call testPaletteChange
	; Game states should assume the extra segment points to video memory at the start of the render functions.
	mov ax,BIOS_VIDEO_MODE_320_200_4_START_ADDR
	mov es,ax
	RENDER_WAIT_FOR_VSYNC
	call [GameStateRenderProc]
	; Point the extra segment back to start.
	mov ax,ds
	mov es,ax

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
	je short @f
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

;--------------;
; Code private ;
;--------------;

gameSetState proc private
	mov [GameStateInitProc],ax
	mov [GameStateInitRenderProc],bx
	mov [GameStateUpdateProc],cx
	mov [GameStateRenderProc],dx
	CONSOLE_SET_CURSOR_COL_ROW 0, 0
	ret
gameSetState endp

if CONSOLE_ENABLED
readCurrentCursorPosAndSetConsoleCursorColRow proc private
	mov ah,BIOS_VIDEO_FUNC_GET_CURSOR_POS_SIZE
	int BIOS_VIDEO_INT
	call consoleSetCursorColRow
	ret
readCurrentCursorPosAndSetConsoleCursorColRow endp
endif

ife KEYBOARD_ENABLED
; Output: zf (zero flag set if ESC is pressed).
testCheckKeyboardBufferForESCKey proc private
checkBuffer:
	mov ah,BIOS_KEYBOARD_FUNC_CHECK_KEY
	int BIOS_KEYBOARD_INT
	jnz short getKey
	; Clear zero flag and return, since the buffer is empty.
	or ah,0ffh
	ret
getKey:
	; Remove key from buffer.
	mov ah,BIOS_KEYBOARD_FUNC_GET_KEY
	int BIOS_KEYBOARD_INT
	cmp ah,BIOS_KEYBOARD_SCANCODE_ESC
	; If key is not ESC, look in the buffer again.
	jne short checkBuffer
	ret
testCheckKeyboardBufferForESCKey endp
endif

testPaletteChange proc private
	KEYBOARD_IS_KEY_PRESSED BIOS_KEYBOARD_SCANCODE_1
	jnz short skipChangePaletteNum0
	RENDER_SET_PALETTE_NUM BIOS_VIDEO_MODE_320_200_4_PALETTE_0
	; Returns here just in case, so the palette can't be changed two times in the same frame.
	ret
skipChangePaletteNum0:
	KEYBOARD_IS_KEY_PRESSED BIOS_KEYBOARD_SCANCODE_2
	jnz short skipChangePaletteNum1
	RENDER_SET_PALETTE_NUM BIOS_VIDEO_MODE_320_200_4_PALETTE_1
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

	; Print scancode.
	mov si,offset allSegments:strScancode
	call consolePrintString
	xchg al,ah
	call consolePrintByteHex

	; Print ascii.
	mov si,offset allSegments:strASCII
	call consolePrintString
	mov al,ah
	call consolePrintChar

	call consoleNextLine
	jmp short nextKey
quit:
	GAME_QUIT ERROR_CODE_NONE

strStart:
	byte "Press any key to see its scancode and ascii value, press CTRL-C to quit.", ASCII_CR, ASCII_LF, 0
strScancode:
	byte "Scancode: ", 0
strASCII:
	byte " - ASCII: ", 0
testKeyboardScancode endp

testKeyboardFlags proc private
printFlags:
	mov ah,BIOS_KEYBOARD_FUNC_GET_FLAGS
	int BIOS_KEYBOARD_INT
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

	mov si,offset allSegments:strVer
	call consolePrintString
	; Major version.
	call consolePrintByte
	mov al,"."
	call consolePrintChar
	; Minor version.
	mov al,ah
	call consolePrintByte

	mov si,offset allSegments:strDOSType
	call consolePrintString
	; Dos type.
	mov al,bh
	call consolePrintByteHex

	GAME_QUIT ERROR_CODE_NONE
strVer:
	byte "Ver: ", 0
strDOSType:
	byte " DosType: ", 0
testDOSVersion endp

endif

code ends

constData segment readonly public
	ErrorStr						byte "Error code: 0x", 0
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
