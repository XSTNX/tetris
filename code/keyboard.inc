KEYBOARD_ENABLED                equ 1
KEYBOARD_KEY_PRESSED_COUNT      equ 128

ifndef KEYBOARD_NO_EXTERNS

extern keyboardStart:proc, keyboardStop:proc
extern KeyboardKeyPressed:byte

endif

; Input: scancode (scancode of the key, from 0 to 7fh).
; Output: zf (zero flag set if the key is pressed).
keyboardIsKeyPressed macro scancode:req
    test cs:[KeyboardKeyPressed + scancode],080h
endm
