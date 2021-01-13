include code\bios.inc
include code\dos.inc
include code\errcode.inc

KEYBOARD_KEY_PRESSED_COUNT      equ 128

allSegments group code, data
    assume cs:allSegments, ds:allSegments

code segment public

; Output: al (error code).
keyboardStart proc
    push ds
    push es

    mov ah,BIOS_SYSTEM_FUNC_GET_ENVIRONMENT
    int BIOS_SYSTEM_INT

    ; Check if the size is big enough to contain the configuration.
    cmp word ptr es:[bx + BIOS_SYSTEM_ENVIRONMENT_LENGTH],BIOS_SYSTEM_ENVIRONMENT_CFG_OFFSET + 1
    jae short skipSizeError
    mov al,ERROR_CODE_KEYBOARD_SIZE
    jmp short quit
skipSizeError:
    ; Check if keyboard intercept funcion is available.
    test byte ptr es:[bx + BIOS_SYSTEM_ENVIRONMENT_CFG_OFFSET], BIOS_SYSTEM_ENVIRONMENT_CFG_MASK
    jnz skipInterceptNotAvaiableError
    mov al,ERROR_CODE_KEYBOARD_NO_INTRCPT
    jmp short quit
skipInterceptNotAvaiableError:

    ; Keys are not pressed by default (a key press that happened before the game started can't be detected).
    mov ax,8080h
    mov di,offset KeyboardKeyPressed
    mov cx,KEYBOARD_KEY_PRESSED_COUNT / 2
    rep stosw

    ; Save previous keyboard interrupt handler.
    mov ax,(DOS_REQUEST_FUNC_GET_INT_VECTOR * 256) + BIOS_SYSTEM_INT
    int DOS_REQUEST_INT
    mov [KeyboardPrevIntHandlerOffset],bx
    mov [KeyboardPrevIntHandlerSegment],es

    ; Set new keyboard interrupt handler.
    mov ax,(DOS_REQUEST_FUNC_SET_INT_VECTOR * 256) + BIOS_SYSTEM_INT
    mov dx,cs
    mov ds,dx
    mov dx,offset keyboardNewInt
    int DOS_REQUEST_INT

    mov al,ERROR_CODE_KEYBOARD_NONE

quit:
    pop es
    pop ds
    ret
keyboardStart endp

keyboardStop proc
    ; Restore previous keyboard interrupt handler.
    mov ax,(DOS_REQUEST_FUNC_SET_INT_VECTOR * 256) + BIOS_SYSTEM_INT
    mov dx,[KeyboardPrevIntHandlerOffset]
    ; Data segment needs to be set last, since we can't access data until it's restored.
    push ds
    mov ds,[KeyboardPrevIntHandlerSegment]
    int DOS_REQUEST_INT
    pop ds

    ret
keyboardStop endp

; ---------;
; Private. ;
; ---------;

keyboardNewInt proc private
    cmp ah,BIOS_SYSTEM_FUNC_KEYBOARD_INTERCEPT
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

public KeyboardKeyPressed

    KeyboardPrevIntHandlerOffset        dw ?
    KeyboardPrevIntHandlerSegment       dw ?
    ; The scancode of the key is used as an index into the array. If the msb is clear, the key is pressed.
    KeyboardKeyPressed                  db KEYBOARD_KEY_PRESSED_COUNT dup(?)
data ends

end
