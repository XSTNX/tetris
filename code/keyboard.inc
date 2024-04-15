ifndef KEYBOARD_INC
KEYBOARD_INC = 1

include code\assert.inc

KEYBOARD_ENABLED                    equ 1
KEYBOARD_KEY_PRESSED_COUNT          equ 128
KEYBOARD_KEY_PRESSED_VALUE_MASK     equ 80h

externdef keyboardStart:proc, keyboardStop:proc
ifndef KEYBOARD_INC_HACK
externdef KeyboardKeyPressed:byte
endif

; Input: scancode (unsigned byte constant, from 0 to KEYBOARD_KEY_PRESSED_COUNT - 1).
; Output: zf (set if true).
; Clobber: nothing.
KEYBOARD_IS_KEY_PRESSED macro aScancode:req
    .erre aScancode lt KEYBOARD_KEY_PRESSED_COUNT
    test cs:[KeyboardKeyPressed + aScancode],KEYBOARD_KEY_PRESSED_VALUE_MASK
endm

endif
