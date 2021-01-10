extern keyboardStart:proc, keyboardStop:proc

extern KeyboardKeyPressed:byte

; Input: bx (scancode of the key, from 0 to 7fh).
; Output: zf (zero flag set means the key is pressed).
KEYBOARD_IS_KEY_PRESSED macro
    test [KeyboardKeyPressed + bx],80h
endm
