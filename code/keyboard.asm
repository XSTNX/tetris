; I need to use RENDER_INC_HACK or there will be some sort of error in KeyboardKeyPressed, figure out!!!????
KEYBOARD_INC_HACK equ 1
include code\keyboard.inc
include code\bios.inc

KEYBOARD_KEY_PRESSED_INDEX_MASK     equ KEYBOARD_KEY_PRESSED_COUNT - 1

allSegments group code, data
    assume cs:allSegments, ds:allSegments, es:nothing

; The code is written to run in a COM file, so all procedures but keyboardSystemInt assume all segment registers have
; the same value on enter.
; The code segment is not readonly because the data is stored there as well and it will be modified by the interrupt handler.
code segment public

;-------------;
; Code public ;
;-------------;

; Clobber: ax, dx, di, es.
keyboardStart proc
if KEYBOARD_ENABLED
    cmp [KeyboardAlreadyInitialized],0
    jne short @f
    push es
    ; Read current interrupt handler with one instruction, so an interrupt can't modify it while the memory is fetched.
    xor ax,ax
    mov es,ax
    les ax,es:[BIOS_KEYBOARD_REQUIRED_INT_ADDR_OFFSET]
    ; Save current interrupt handler.
    mov [KeyboardPrevIntHandlerOffset],ax
    mov [KeyboardPrevIntHandlerSegment],es
    ; Set new interrupt handler.
    mov ax,offset allSegments:keyboardIntHandler
    mov dx,cs
    call keyboardSetIntHandler
    inc [KeyboardAlreadyInitialized]
    pop es
@@:
endif
    ret
keyboardStart endp

; Clobber: ax, dx, di, es.
keyboardStop proc
if KEYBOARD_ENABLED
    cmp [KeyboardAlreadyInitialized],0
    je short @f
    ; Restore previous interrupt handler.
    mov ax,[KeyboardPrevIntHandlerOffset]
    mov dx,[KeyboardPrevIntHandlerSegment]
    call keyboardSetIntHandler
    dec [KeyboardAlreadyInitialized]
@@:
endif
    ret
keyboardStop endp

;--------------;
; Code private ;
;--------------;

if KEYBOARD_ENABLED
; Input: ax (offset), dx (segment)
; Clobber: ax, di, es
keyboardSetIntHandler proc private
    ; Destination.
    xor di,di
    mov es,di
    mov di,BIOS_KEYBOARD_REQUIRED_INT_ADDR_OFFSET

    ; Write vector, interrupts must be disabled, otherwise they could write on the vector themselves after one iteration of the repeat.
    ; Doesn't take into account that nmi could, in theory, write into the vector as well, but I don't think this would happen in practice.
    cli
    stosw
    mov ax,dx
    stosw
    sti

    ret
keyboardSetIntHandler endp

assume cs:allSegments, ds:nothing, es:nothing
keyboardIntHandler proc private
    ; Should I enable interrupts here somewhere??????????????
    push ax
    push bx
    push dx
    ; Read scancode.
    in al,60h
    mov dl,al
    ; The code to clear the key is taken from INL_KeyService(void) of WOLFSRC/ID_IN.C in https://github.com/id-Software/wolf3d.
    ; Would be nice to find documentation on how this works exactly. Without clearing the key, the game doesn't respond
    ; to input properly in MartyPC, which is likely what will happen on a real IBM PC, but DosBox works fine without it.
	; outportb(0x61,(temp = inportb(0x61)) | 0x80);
	; outportb(0x61,temp);
    ; Clear key.
    in al,61h
    mov bl,al
    or al,80h
    out 61h,al
    mov al,bl
    out 61h,al
    ; Store key state.
    mov bl,dl
    and bx,KEYBOARD_KEY_PRESSED_INDEX_MASK
    mov cs:[KeyboardKeyPressed + bx],dl
    ; Send end of interrupt.
    mov al,20h
    out 20h,al
    pop dx
    pop bx
    pop ax
    iret
keyboardIntHandler endp
assume cs:allSegments, ds:allSegments, es:nothing
endif

    ; This data is stored in the code segment since it needs to be accesible to the interrupt handler.
    ; Should I align the data?
    public KeyboardKeyPressed
    ; The scancode of the key is used as an index into the array. The key is pressed when the msb is clear.
    ; Does the array really need to be in the code segment? I should be able to address it from the code segment even if it's in the data segment.
    ; This would only work if the offset to the array is within 64KB, but this can be validated at assembly time.
    KeyboardKeyPressed                  byte KEYBOARD_KEY_PRESSED_COUNT dup(KEYBOARD_KEY_PRESSED_VALUE_MASK)
code ends

data segment public
if KEYBOARD_ENABLED
    KeyboardPrevIntHandlerFarPtr        label dword
    KeyboardPrevIntHandlerOffset        word ?
    KeyboardPrevIntHandlerSegment       word ?
    KeyboardAlreadyInitialized          byte 0
endif
data ends

end
