KEYBOARD_ENABLED    equ 1

ifndef KEYBOARD_NO_EXTERNS

extern keyboardStart:proc, keyboardStop:proc
extern KeyboardKeyPressed:byte

endif

; Input: scancode (scancode of the key, from 0 to 7fh).
; Output: zf (zero flag set means the key is pressed).
keyboardIsKeyPressed macro scancode:req
    test cs:[KeyboardKeyPressed + scancode],80h
endm
