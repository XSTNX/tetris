KEYBOARD_NO_EXTERNS equ 1
include code\keyboard.inc
include code\bios.inc
include code\errcode.inc

allSegments group code
    assume cs:allSegments, ds:allSegments, es:nothing

; The code is written to run in a COM file, so all procedures but keyboardSystemInt assume all segment registers have
; the same value on enter.
; The code segment is not readonly because the data is stored there as well and it will be modified by the interrupt handler.
code segment public

; ------------;
; Code public ;
; ------------;

keyboardStart proc
if KEYBOARD_ENABLED
    cmp ds:[KeyboardAlreadyInitialized],0
    jne @f
    ; Read current interrupt handler with one instruction, so an interrupt can't modify it while the memory is fetched.
    xor ax,ax
    mov es,ax
    les ax,es:[BIOS_KEYBOARD_REQUIRED_INT_ADDR_OFFSET]
    ; Save current interrupt handler.
    mov ds:[KeyboardPrevIntHandlerOffset],ax
    mov ds:[KeyboardPrevIntHandlerSegment],es
    ; Set new interrupt handler.
    push cs
    mov ax,offset allSegments:keyboardIntHandler
    push ax
    call keyboardSetIntHandler
    inc ds:[KeyboardAlreadyInitialized]
@@:
endif
    ret
keyboardStart endp

keyboardStop proc
if KEYBOARD_ENABLED
    cmp ds:[KeyboardAlreadyInitialized],1
    jne @f
    ; Restore previous interrupt handler
    push ds:[KeyboardPrevIntHandlerSegment]
    push ds:[KeyboardPrevIntHandlerOffset]
    call keyboardSetIntHandler
    dec ds:[KeyboardAlreadyInitialized]
@@:
endif
    ret
keyboardStop endp

; -------------;
; Code private ;
; -------------;

if KEYBOARD_ENABLED
; Input: stack arg0 (Interrupt handler address, far ptr).
keyboardSetIntHandler proc private
    ; Source is in the stack, set si only, since ds is equal to ss.
    mov si,sp
    ; Handler is a far ptr, two words must be copied.
    mov cx,2
    ; Stack arg0 is two bytes past sp.
    add si,cx

    ; Destination.
    xor di,di
    mov es,di
    mov di,BIOS_KEYBOARD_REQUIRED_INT_ADDR_OFFSET

    ; Write vector, interrupts must be disabled, otherwise they could write on the vector themselves after one iteration of the repeat.
    ; Doesn't take into account that nmi could, in theory, write into the vector as well, but I don't think this would happen in practice.
    cli
    rep movsw
    sti

    ret 4
keyboardSetIntHandler endp
endif

; The following code doesn't assume ds is equal to cs, since the interrupt could ocurr while its executing another interrupt that changed ds.
assume cs:allSegments, ds:nothing, es:nothing

if KEYBOARD_ENABLED
keyboardIntHandler proc private
    ; Should I enable interrupts here somewhere??????????????
    ; Wolfenstein 3D tells the XT keyboard to clear the key, which I'm not doing but probably should?????????

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
keyboardIntHandler endp
endif

    ; Data is stored in the code segment since it needs to be accesible to the interrupt handler.
    ; Should I align the data?
    public KeyboardKeyPressed
    ; The scancode of the key is used as an index into the array. If the msb is clear, the key is pressed.
    KeyboardKeyPressed                  byte KEYBOARD_KEY_PRESSED_COUNT dup(080h)
if KEYBOARD_ENABLED
    KeyboardAlreadyInitialized          byte 0
    KeyboardPrevIntHandlerFarPtr        label dword
    KeyboardPrevIntHandlerOffset        word ?
    KeyboardPrevIntHandlerSegment       word ?
endif

code ends

end
