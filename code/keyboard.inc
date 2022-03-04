include code\game.inc

KEYBOARD_ENABLED                equ 1
KEYBOARD_KEY_PRESSED_COUNT      equ 128

ifndef KEYBOARD_NO_EXTERNS
extern keyboardStart:proc, keyboardStop:proc
extern KeyboardKeyPressed:byte
endif

; Input: scancode (unsigned byte, from 0 to KEYBOARD_KEY_PRESSED_COUNT - 1).
; Output: zf (zero flag set if the key is pressed).
KEYBOARD_IS_KEY_PRESSED macro scancode:req
ifdef ASSERT
    ; How to avoid moving the scancode to a register if the argument is a register already????????
    push ax
    mov ax,scancode
    cmp ax,KEYBOARD_KEY_PRESSED_COUNT
    jb short @f
    GAME_QUIT_WITH_ERROR_ARG ERROR_CODE_ASSERT
@@:
    pop ax
endif
    test cs:[KeyboardKeyPressed + scancode],080h
endm
