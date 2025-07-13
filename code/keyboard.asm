; I need to use KEYBOARD_INC_HACK or there will be some sort of error in KeyboardKeyPressed, figure out!!!????
KEYBOARD_INC_HACK equ 1
include code\keyboard.inc
include code\bios.inc

KEYBOARD_KEY_PRESSED_INDEX_MASK     equ KEYBOARD_KEY_PRESSED_COUNT - 1

allSegments group code, data
    assume cs:allSegments, ds:allSegments, es:nothing

code segment readonly public

;-------------;
; Code public ;
;-------------;

; Clobber: ax, cx, dx, di.
keyboardStart proc
    cmp [KeyboardAlreadyInitialized],0
    jne short @f
    ; Initialize KeyboardKeyPressed array with no key pressed.
    mov ax,KEYBOARD_KEY_PRESSED_VALUE_MASK or (KEYBOARD_KEY_PRESSED_VALUE_MASK shl 8)
    .errnz KEYBOARD_KEY_PRESSED_COUNT and 1
    mov cx,KEYBOARD_KEY_PRESSED_COUNT shr 1
    mov di,offset allSegments:KeyboardKeyPressed
    rep stosw
if KEYBOARD_ENABLED
    ; Read current interrupt handler with one instruction, so an interrupt can't modify it while the memory is fetched.
    push es
    mov es,cx
    les ax,es:[BIOS_KEYBOARD_REQUIRED_INT_ADDR_OFFSET]
    ; Save current interrupt handler.
    mov [KeyboardPrevIntHandlerOffset],ax
    mov [KeyboardPrevIntHandlerSegment],es
    ; Set new interrupt handler.
    mov ax,offset allSegments:keyboardIntHandler
    mov dx,cs
    call keyboardSetIntHandler
    pop es
endif
    inc [KeyboardAlreadyInitialized]
@@:
    ret
keyboardStart endp

; Clobber: ax, dx, di, es.
keyboardStop proc
    cmp [KeyboardAlreadyInitialized],0
    je short @f
if KEYBOARD_ENABLED
    ; Restore previous interrupt handler.
    mov ax,[KeyboardPrevIntHandlerOffset]
    mov dx,[KeyboardPrevIntHandlerSegment]
    call keyboardSetIntHandler
endif
    dec [KeyboardAlreadyInitialized]
@@:
    ret
keyboardStop endp

;--------------;
; Code private ;
;--------------;

if KEYBOARD_ENABLED
; Input: ax (offset), dx (segment)
; Clobber: ax, di, es
keyboardSetIntHandler proc private
    ; Set destination.
    xor di,di
    mov es,di
    mov di,BIOS_KEYBOARD_REQUIRED_INT_ADDR_OFFSET
    ; Write vector with interrupts disabled, so the operation is atomic.
    cli
    stosw
    mov ax,dx
    stosw
    sti
    ret
keyboardSetIntHandler endp

; Clobber: nothing.
assume cs:allSegments, ds:nothing, es:nothing
keyboardIntHandler proc private
    ; Should I enable interrupts here somewhere??????????????
    ; Read scancode.
    push ax
    in al,60h
    push bx
    mov bl,al
    ; The code to clear the key is taken from INL_KeyService(void) of WOLFSRC/ID_IN.C in https://github.com/id-Software/wolf3d.
    ; Would be nice to find documentation on how this works exactly. Without clearing the key, the game doesn't respond
    ; to input properly in MartyPC, which is likely what will happen on a real IBM PC, but DosBox works fine without it.
	; outportb(0x61,(temp = inportb(0x61)) | 0x80);
	; outportb(0x61,temp);
    ; Clear key.
    in al,61h
    mov bh,al
    or al,80h
    out 61h,al
    mov al,bh
    out 61h,al
    ; Store key state.
    ; This procedure is an interrupt handler, so the array has to be accessed through cs, since the contents of ds are unknown.    
    mov al,bl
    and bx,KEYBOARD_KEY_PRESSED_INDEX_MASK
    mov cs:[KeyboardKeyPressed + bx],al
    pop bx
    ; Send end of interrupt.
    mov al,20h
    out 20h,al
    pop ax    
    iret
keyboardIntHandler endp
assume cs:allSegments, ds:allSegments, es:nothing
endif
code ends

data segment public
if KEYBOARD_ENABLED
    KeyboardPrevIntHandlerOffset        word ?
    KeyboardPrevIntHandlerSegment       word ?
endif
    ; The scancode of the key is used as an index into the array. The key is pressed when the msb is clear.
    public KeyboardKeyPressed
    KeyboardKeyPressed                  byte KEYBOARD_KEY_PRESSED_COUNT dup(?)
    KeyboardAlreadyInitialized          byte 0
data ends

end
