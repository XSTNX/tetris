include code\bios.inc
include code\dos.inc

KEYBOARD_KEY_PRESSED_COUNT equ 128

allSegments group code, data
    assume cs:allSegments, ds:allSegments

code segment public

keyboardStart proc
    ; Keys are not pressed by default (a key press that happened before the game started can't be detected).
    mov ax,8080h
    mov di,offset KeyboardKeyPressed
    mov cx,KEYBOARD_KEY_PRESSED_COUNT / 2
    rep stosw

    ; Save previous keyboard interrupt handler.
    mov ax,(DOS_REQUEST_FUNC_GET_INT_VECTOR * 256) + BIOS_SYSTEM_SERVICES_INT
    push es
    int DOS_REQUEST_INT
    mov [KeyboardPrevIntHandlerOffset],bx
    mov [KeyboardPrevIntHandlerSegment],es
    pop es

    ; Set new keyboard interrupt handler.
    mov ax,(DOS_REQUEST_FUNC_SET_INT_VECTOR * 256) + BIOS_SYSTEM_SERVICES_INT
    push ds
    mov dx,cs
    mov ds,dx
    mov dx,offset keyboardNewInt
    int DOS_REQUEST_INT
    pop ds

    ret
keyboardStart endp

keyboardStop proc
    ; Restore previous keyboard interrupt handler.
    mov ax,(DOS_REQUEST_FUNC_SET_INT_VECTOR * 256) + BIOS_SYSTEM_SERVICES_INT
    mov dx,[KeyboardPrevIntHandlerOffset]
    ; Data segment needs to be set last, since we can't access data until it's restored.
    push ds
    mov ds,[KeyboardPrevIntHandlerSegment]
    int DOS_REQUEST_INT
    pop ds

    ret
keyboardStop endp

; Input: bx (scancode, from 0 to KEYBOARD_KEY_PRESSED_COUNT - 1).
; Output: cf (carry flag set means the key is pressed).
keyboardIsKeyPressed proc
    clc
    test [KeyboardKeyPressed + bx],KEYBOARD_KEY_PRESSED_COUNT
    jnz short skip
    stc
skip:
    ret
keyboardIsKeyPressed endp

; ---------;
; Private. ;
; ---------;

keyboardNewInt proc private
    cmp ah,BIOS_SYSTEM_SERVICES_FUNC_KEYBD_INTRCPT
    jne short skipKeyProcess

    ; Clobbered registers have to be restored.
    push bx

    mov bl,al
    and bx,KEYBOARD_KEY_PRESSED_COUNT - 1
    mov [KeyboardKeyPressed + bx],al

    pop bx

skipKeyProcess:
    jmp dword ptr [KeyboardPrevIntHandlerOffset]
keyboardNewInt endp

code ends

data segment public
    KeyboardPrevIntHandlerOffset        dw ?
    KeyboardPrevIntHandlerSegment       dw ?
    ; The scancode of the key is used as an index into the array. If the msb is clear, the key is pressed.
    KeyboardKeyPressed                  db KEYBOARD_KEY_PRESSED_COUNT dup(?)
data ends

end
