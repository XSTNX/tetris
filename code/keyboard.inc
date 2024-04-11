ifndef KEYBOARD_INC
KEYBOARD_INC = 1

include code\assert.inc

KEYBOARD_ENABLED                equ 1
KEYBOARD_KEY_PRESSED_COUNT      equ 128

externdef keyboardStart:proc, keyboardStop:proc
ifndef KEYBOARD_INC_HACK
externdef KeyboardKeyPressed:byte
endif

; Input: scancode (unsigned byte, from 0 to KEYBOARD_KEY_PRESSED_COUNT - 1).
; Output: zf (zero flag set if true).
; Clobber: nothing.
KEYBOARD_IS_KEY_PRESSED macro aScancode:req
local l
if ASSERT_ENABLED
    ifdifi <aScancode>,<ax>
    push ax
    mov ax,aScancode
    endif
    cmp ax,KEYBOARD_KEY_PRESSED_COUNT
    jb short l
    ASSERT
l:
    ifdifi <aScancode>,<ax>
    pop ax
    endif
endif
    test cs:[KeyboardKeyPressed + aScancode],080h
endm

endif
