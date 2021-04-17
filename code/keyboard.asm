KEYBOARD_NO_EXTERNS equ 1
include code\keyboard.inc
include code\bios.inc
include code\dos.inc
include code\errcode.inc

KEYBOARD_KEY_PRESSED_COUNT      equ 128

allSegments group code
    assume cs:allSegments

; The code is written to run in a COM file, so all procedures but keyboardSystemInt assume segment registers have
; the same value on enter.
code segment public

; Output: al (error code).
keyboardStart proc
    push ds
    push es

    ; Set keys to not pressed.
    mov ax,8080h
    mov cx,KEYBOARD_KEY_PRESSED_COUNT / 2
    mov di,offset allSegments:KeyboardKeyPressed
    rep stosw

if KEYBOARD_ENABLED
    ; Save BIOS system interrupt handler first, so calling keyboardStop will still work even if the intercept
    ; function can't be overriden.
    mov ax,(DOS_REQUEST_FUNC_GET_INT_VECTOR * 256) + BIOS_SYSTEM_INT
    int DOS_REQUEST_INT
    mov ds:[KeyboardBIOSSystemIntHandlerOffset],bx
    mov ds:[KeyboardBIOSSystemIntHandlerSegment],es

    ; Get system environment.
    mov ah,BIOS_SYSTEM_FUNC_GET_ENVIRONMENT
    int BIOS_SYSTEM_INT

    ; Check if the environment size is big enough to contain the configuration.
    cmp word ptr es:[bx + BIOS_SYSTEM_ENVIRONMENT_LENGTH],BIOS_SYSTEM_ENVIRONMENT_CFG_OFFSET + 1
    jae short skipSizeError
    mov al,ERROR_CODE_KEYBOARD_SIZE
    jmp short quit
skipSizeError:
    ; Check in the configuration if the keyboard intercept funcion is available.
    test byte ptr es:[bx + BIOS_SYSTEM_ENVIRONMENT_CFG_OFFSET], BIOS_SYSTEM_ENVIRONMENT_CFG_MASK
    jnz skipInterceptNotAvaiableError
    mov al,ERROR_CODE_KEYBOARD_NO_INTRCPT
    jmp short quit
skipInterceptNotAvaiableError:

    ; Set new system interrupt handler.
    mov ax,(DOS_REQUEST_FUNC_SET_INT_VECTOR * 256) + BIOS_SYSTEM_INT
    mov dx,offset allSegments:keyboardSystemInt
    int DOS_REQUEST_INT
endif
    mov al,ERROR_CODE_KEYBOARD_NONE

quit:
    pop es
    pop ds
    ret
keyboardStart endp

keyboardStop proc
if KEYBOARD_ENABLED
    ; Restore previous keyboard interrupt handler.
    mov ax,(DOS_REQUEST_FUNC_SET_INT_VECTOR * 256) + BIOS_SYSTEM_INT
    push ds
    lds dx,ds:[KeyboardBIOSSystemIntHandlerDWordPtr]
    int DOS_REQUEST_INT
    pop ds
endif
    ret
keyboardStop endp

; ---------;
; Private. ;
; ---------;

; This procedure doesn't assume ds is equal to cs, since the interrupt could ocurr while its executing another interrupt.
keyboardSystemInt proc private
    ; Is it the keyboard intercept function?
    cmp ah,BIOS_SYSTEM_FUNC_KEYBOARD_INTERCEPT
    jne short skipKeyProcess

    ; Store key state.
    push bx
    mov bl,al
    and bx,KEYBOARD_KEY_PRESSED_COUNT - 1
    mov cs:[KeyboardKeyPressed + bx],al
    pop bx
    
    ; Clear carry flag to consume the scancode.
    add sp,4
    popf
    clc
    pushf
    sub sp,4

    ; Done.
    iret

skipKeyProcess:
    ; No, let the BIOS handle it.
    jmp cs:[KeyboardBIOSSystemIntHandlerDWordPtr]
keyboardSystemInt endp

    ; Data is stored in the code segment since it needs to be accesible to the new interrupt.
    public KeyboardKeyPressed
    ; The scancode of the key is used as an index into the array. If the msb is clear, the key is pressed.
    KeyboardKeyPressed                      byte KEYBOARD_KEY_PRESSED_COUNT dup(?)
    KeyboardBIOSSystemIntHandlerDWordPtr    label dword
    KeyboardBIOSSystemIntHandlerOffset      word ?
    KeyboardBIOSSystemIntHandlerSegment     word ?

code ends

end
