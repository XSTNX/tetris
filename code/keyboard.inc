ifndef KEYBOARD_INC
KEYBOARD_INC = 1

include code\assert.inc

KEYBOARD_ENABLED                equ 1
KEYBOARD_KEY_PRESSED_COUNT      equ 128

externdef keyboardStart:proc, keyboardStop:proc
ifndef KEYBOARD_NO_EXTERNS
externdef KeyboardKeyPressed:byte
endif

; Input: scancode (unsigned byte, from 0 to KEYBOARD_KEY_PRESSED_COUNT - 1).
; Output: zf (zero flag set if true).
; Clobber: nothing.
KEYBOARD_IS_KEY_PRESSED macro aScancode:req
if ASSERT_ENABLED
    ; How to avoid moving the scancode to a register if the argument is a register already????????
    push ax
    mov ax,aScancode
    cmp ax,KEYBOARD_KEY_PRESSED_COUNT
    jb short @f
    ASSERT
@@:
    pop ax
endif
    test cs:[KeyboardKeyPressed + aScancode],080h
endm

endif
