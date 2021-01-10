include code\bios.inc
include code\dos.inc

allSegments group code, data
    assume cs:allSegments, ds:allSegments

code segment public

keyboardStart proc

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

; ---------;
; Private. ;
; ---------;

keyboardNewInt proc
    jmp dword ptr [KeyboardPrevIntHandlerOffset]
keyboardNewInt endp

code ends

data segment public
    KeyboardPrevIntHandlerOffset        dw ?
    KeyboardPrevIntHandlerSegment       dw ?
data ends

end
