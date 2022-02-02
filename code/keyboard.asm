KEYBOARD_NO_EXTERNS equ 1
include code\keyboard.inc
include code\bios.inc
include code\dos.inc
include code\errcode.inc

KEYBOARD_KEY_PRESSED_COUNT      equ 128

allSegments group code
    assume cs:allSegments, ds:allSegments, es:allSegments

; The code is written to run in a COM file, so all procedures but keyboardSystemInt assume all segment registers have
; the same value on enter.
; The code segment is not readonly because the data is stored there as well and it will be modified by the interrupt handler.
code segment public

; ------------;
; Code public ;
; ------------;

; Output: al (error code).
keyboardStart proc
if KEYBOARD_ENABLED
    push es

    ; Save BIOS system interrupt handler first, so calling keyboardStop will still work even if the intercept
    ; function can't be overriden.
    mov ax,(DOS_REQUEST_FUNC_GET_INT_VECTOR * 256) + BIOS_SYSTEM_INT
    int DOS_REQUEST_INT
    mov ds:[KeyboardPrevSystemIntHandlerOffset],bx
    mov ds:[KeyboardPrevSystemIntHandlerSegment],es

    ; Get system environment.
    mov ah,BIOS_SYSTEM_FUNC_GET_ENVIRONMENT
    int BIOS_SYSTEM_INT
    jnc short skipCallError
    mov al,ERROR_CODE_KEYBOARD_GET_ENV_NO_SUPPORT
    jmp short quit
skipCallError:

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
    mov al,ERROR_CODE_NONE

quit:
    pop es
endif    
    ret
keyboardStart endp

keyboardStop proc
if KEYBOARD_ENABLED
    ; Restore previous keyboard interrupt handler.
    mov ax,(DOS_REQUEST_FUNC_SET_INT_VECTOR * 256) + BIOS_SYSTEM_INT
    push ds
    lds dx,ds:[KeyboardPrevSystemIntHandlerFarPtr]
    int DOS_REQUEST_INT
    pop ds
endif
    ret
keyboardStop endp

; -------------;
; Code private ;
; -------------;

assume cs:allSegments, ds:nothing, es:nothing

if KEYBOARD_ENABLED
; This procedure doesn't assume ds is equal to cs, since the interrupt could ocurr while its executing another interrupt.
keyboardSystemInt proc private
    ; Is it the keyboard intercept function?
    cmp ah,BIOS_SYSTEM_FUNC_KEYBOARD_INTERCEPT
    jne short skipKeyProcess

    ; Store key state.
    push bp
    mov bp,ax
    and bp,KEYBOARD_KEY_PRESSED_COUNT - 1
    mov cs:[KeyboardKeyPressed + bp],al
    
    ; Clear carry flag to consume the scancode.
    ; Offset is 6 because bp is still in the stack.
    mov bp,sp
    and byte ptr [bp + 6],0feh
    pop bp

    ; Done.
    iret

skipKeyProcess:
    ; No, the prev handler should take care of it.
    jmp cs:[KeyboardPrevSystemIntHandlerFarPtr]
keyboardSystemInt endp
endif

    ; Data is stored in the code segment since it needs to be accesible to the interrupt handler.
    ; Should I align the data?
    public KeyboardKeyPressed
    ; The scancode of the key is used as an index into the array. If the msb is clear, the key is pressed.
    KeyboardKeyPressed                      byte KEYBOARD_KEY_PRESSED_COUNT dup(080h)
if KEYBOARD_ENABLED
    KeyboardPrevSystemIntHandlerFarPtr      label dword
    KeyboardPrevSystemIntHandlerOffset      word ?
    KeyboardPrevSystemIntHandlerSegment     word ?
endif

code ends

end
