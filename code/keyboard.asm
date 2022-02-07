KEYBOARD_NO_EXTERNS equ 1
include code\keyboard.inc
include code\bios.inc
include code\errcode.inc

KEYBOARD_KEY_PRESSED_COUNT              equ 128
KEYBOARD_BIOS_SYSTEM_INT_ADDR_OFFSET    equ (BIOS_SYSTEM_INT * 4)

allSegments group code
    assume cs:allSegments, ds:allSegments, es:nothing

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
    ; Save current system interrupt handler first, so calling keyboardStop will still work even if the intercept
    ; function can't be overriden.
    xor ax,ax
    mov es,ax
    ; Read current handler with one instruction, so an interrupt can't modify it while the memory is fetched.
    les ax,es:[KEYBOARD_BIOS_SYSTEM_INT_ADDR_OFFSET]
    mov ds:[KeyboardPrevSystemIntHandlerOffset],ax
    mov ds:[KeyboardPrevSystemIntHandlerSegment],es

    ; Get system environment.
    mov ah,BIOS_SYSTEM_FUNC_GET_ENVIRONMENT
    int BIOS_SYSTEM_INT
    jnc short skipCallError
    mov al,ERROR_CODE_KEYBOARD_GET_ENV_NO_SUPPORT
    jmp short done
skipCallError:

    ; Check if the environment size is big enough to contain the configuration.
    cmp word ptr es:[bx + BIOS_SYSTEM_ENVIRONMENT_LENGTH],BIOS_SYSTEM_ENVIRONMENT_CFG_OFFSET + 1
    jae short skipSizeError
    mov al,ERROR_CODE_KEYBOARD_GET_ENV_WRONG_SIZE
    jmp short done
skipSizeError:
    ; Check in the configuration if the keyboard intercept funcion is available.
    test byte ptr es:[bx + BIOS_SYSTEM_ENVIRONMENT_CFG_OFFSET],BIOS_SYSTEM_ENVIRONMENT_CFG_MASK
    jnz skipInterceptNotAvaiableError
    mov al,ERROR_CODE_KEYBOARD_GET_ENV_NO_INTRCPT
    jmp short done
skipInterceptNotAvaiableError:

    ; Set new system interrupt handler.
    push cs
    mov ax,offset allSegments:keyboardSystemInt
    push ax
    call keyboardSetInterrupHandler
    mov al,ERROR_CODE_NONE
done:
endif
    ret
keyboardStart endp

keyboardStop proc
if KEYBOARD_ENABLED
    ; Restore previous keyboard interrupt handler.
    push ds:[KeyboardPrevSystemIntHandlerSegment]
    push ds:[KeyboardPrevSystemIntHandlerOffset]
    call keyboardSetInterrupHandler
endif
    ret
keyboardStop endp

; -------------;
; Code private ;
; -------------;

; Input: stack arg0 (Interrupt handler address, far ptr).
keyboardSetInterrupHandler proc private
    ; Source is in the stack, set si only, since ds is equal to ss.
    mov si,sp
    ; Handler is a far ptr, two words must be copied.
    mov cx,2
    ; Stack arg0 is two bytes past sp.
    add si,cx

    ; Destination.
    xor di,di
    mov es,di
    mov di,KEYBOARD_BIOS_SYSTEM_INT_ADDR_OFFSET

    ; Write vector, interrupts must be disabled, otherwise they could write on the vector themselves after one iteration of the repeat.
    ; Doesn't take into account that nmi could, in theory, write into the vector as well, but I don't think this would happen in practice.
    cli
    rep movsw
    sti

    ret 4
keyboardSetInterrupHandler endp

assume cs:allSegments, ds:nothing, es:nothing

if KEYBOARD_ENABLED
; This procedure doesn't assume ds is equal to cs, since the interrupt could ocurr while its executing another interrupt.
keyboardSystemInt proc private
    sti

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
