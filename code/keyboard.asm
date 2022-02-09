KEYBOARD_NO_EXTERNS equ 1
include code\keyboard.inc
include code\bios.inc
include code\errcode.inc

KEYBOARD_KEY_PRESSED_COUNT              equ 128
; Decide if the scancodes will be intercepted in BIOS_KEYBOARD_REQUIRED_INT or in BIOS_SYSTEM_INT. The later doesn't work on the original IBM PC.
KEYBOARD_USE_KEYBOARD_REQUIRED_INT      equ 1

; Input: stack arg0 (Interrupt handler address, far ptr).
keyboardSetIntHandler macro aAddrOffset:req
    ;; Source is in the stack, set si only, since ds is equal to ss.
    mov si,sp
    ;; Handler is a far ptr, two words must be copied.
    mov cx,2
    ;; Stack arg0 is two bytes past sp.
    add si,cx

    ;; Destination.
    xor di,di
    mov es,di
    mov di,aAddrOffset

    ;; Write vector, interrupts must be disabled, otherwise they could write on the vector themselves after one iteration of the repeat.
    ;; Doesn't take into account that nmi could, in theory, write into the vector as well, but I don't think this would happen in practice.
    cli
    rep movsw
    sti

    ret 4
endm

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
if KEYBOARD_USE_KEYBOARD_REQUIRED_INT
    ; Read current interrupt handler with one instruction, so an interrupt can't modify it while the memory is fetched.
    xor ax,ax
    mov es,ax
    les ax,es:[BIOS_KEYBOARD_REQUIRED_INT_ADDR_OFFSET]
    ; Save current interrupt handler.
    mov ds:[KeyboardPrevKeyboardRequiredIntHandlerOffset],ax
    mov ds:[KeyboardPrevKeyboardRequiredIntHandlerSegment],es
    ; Set new interrupt handler.
    push cs
    mov ax,offset allSegments:keyboardKeyboardRequiredInt
    push ax
    call keyboardSetKeyboardRequiredIntHandler
    mov al,ERROR_CODE_NONE
else
    ; Save current interrupt handlers first, so calling keyboardStop will still work even if the intercept
    ; function can't be overriden.
    ; Read current interrupt handler with one instruction, so an interrupt can't modify it while the memory is fetched.
    xor ax,ax
    mov es,ax
    les ax,es:[BIOS_SYSTEM_INT_ADDR_OFFSET]
    ; Save current interrupt handler.
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
    ; Check documentation again, what is this plus one??????????????????????????
    cmp word ptr es:[bx + BIOS_SYSTEM_ENVIRONMENT_LENGTH],BIOS_SYSTEM_ENVIRONMENT_CFG_OFFSET + 1
    jae short skipSizeError
    mov al,ERROR_CODE_KEYBOARD_GET_ENV_WRONG_SIZE
    jmp short done
skipSizeError:
    ; Check in the configuration if the keyboard intercept funcion is available.
    test byte ptr es:[bx + BIOS_SYSTEM_ENVIRONMENT_CFG_OFFSET],BIOS_SYSTEM_ENVIRONMENT_CFG_KI_MASK
    jnz skipInterceptNotAvaiableError
    mov al,ERROR_CODE_KEYBOARD_GET_ENV_NO_INTRCPT
    jmp short done
skipInterceptNotAvaiableError:

    ; Set new interrupt handler.
    push cs
    mov ax,offset allSegments:keyboardSystemInt
    push ax
    call keyboardSetSystemIntHandler
    mov al,ERROR_CODE_NONE
done:
endif
endif
    ret
keyboardStart endp

keyboardStop proc
if KEYBOARD_ENABLED
    ; Restore previous interrupt handler.
if KEYBOARD_USE_KEYBOARD_REQUIRED_INT
    push ds:[KeyboardPrevKeyboardRequiredIntHandlerSegment]
    push ds:[KeyboardPrevKeyboardRequiredIntHandlerOffset]
    call keyboardSetKeyboardRequiredIntHandler
else
    push ds:[KeyboardPrevSystemIntHandlerSegment]
    push ds:[KeyboardPrevSystemIntHandlerOffset]
    call keyboardSetSystemIntHandler
endif
endif
    ret
keyboardStop endp

; -------------;
; Code private ;
; -------------;

if KEYBOARD_ENABLED
if KEYBOARD_USE_KEYBOARD_REQUIRED_INT
; Input: stack arg0 (Interrupt handler address, far ptr).
keyboardSetKeyboardRequiredIntHandler proc private
    keyboardSetIntHandler BIOS_KEYBOARD_REQUIRED_INT_ADDR_OFFSET
keyboardSetKeyboardRequiredIntHandler endp
else
; Input: stack arg0 (Interrupt handler address, far ptr).
keyboardSetSystemIntHandler proc private
    keyboardSetIntHandler BIOS_SYSTEM_INT_ADDR_OFFSET
keyboardSetSystemIntHandler endp
endif
endif

assume cs:allSegments, ds:nothing, es:nothing

if KEYBOARD_ENABLED
if KEYBOARD_USE_KEYBOARD_REQUIRED_INT
keyboardKeyboardRequiredInt proc private
    ; Should I enable interrupts here somewhere??????????????
    ; Read scancode.
    push ax
    in al,060h
    ; Store key state.
    push bx
    mov bx,ax
    and bx,KEYBOARD_KEY_PRESSED_COUNT - 1
    mov cs:[KeyboardKeyPressed + bx],al
    ; Send end of interrupt.
    mov al,20h
    out 20h,al
    pop bx
    pop ax
    iret
keyboardKeyboardRequiredInt endp
else
; This procedure doesn't assume ds is equal to cs, since the interrupt could ocurr while its executing another interrupt.
keyboardSystemInt proc private

    ; Is it the keyboard intercept function?
    cmp ah,BIOS_SYSTEM_FUNC_KEYBOARD_INTERCEPT
    jne short skipKeyProcess

    ; Should I enable interrupts here? What if I do it at the beginning of the function??????????????
    sti

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
endif

    ; Data is stored in the code segment since it needs to be accesible to the interrupt handler.
    ; Should I align the data?
    public KeyboardKeyPressed
    ; The scancode of the key is used as an index into the array. If the msb is clear, the key is pressed.
    KeyboardKeyPressed                              byte KEYBOARD_KEY_PRESSED_COUNT dup(080h)
if KEYBOARD_ENABLED
if KEYBOARD_USE_KEYBOARD_REQUIRED_INT
    KeyboardPrevKeyboardRequiredIntHandlerFarPtr    label dword
    KeyboardPrevKeyboardRequiredIntHandlerOffset    word ?
    KeyboardPrevKeyboardRequiredIntHandlerSegment   word ?
else    
    KeyboardPrevSystemIntHandlerFarPtr              label dword
    KeyboardPrevSystemIntHandlerOffset              word ?
    KeyboardPrevSystemIntHandlerSegment             word ?
endif    
endif

code ends

end
