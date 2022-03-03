KEYBOARD_ENABLED                equ 1
KEYBOARD_KEY_PRESSED_COUNT      equ 128

ifndef KEYBOARD_NO_EXTERNS
extern keyboardStart:proc, keyboardStop:proc
extern KeyboardKeyPressed:byte
endif

; Input: scancode (scancode of the key, from 0 to KEYBOARD_KEY_PRESSED_COUNT - 1).
; Output: zf (zero flag set if the key is pressed).
KEYBOARD_IS_KEY_PRESSED macro scancode:req
    ; assert(scancode < KEYBOARD_KEY_PRESSED_COUNT);
    test cs:[KeyboardKeyPressed + scancode],080h
endm
