include code\console.inc
if CONSOLE_ENABLED

include code\assert.inc
include code\bios.inc

CONSOLE_COLS        	equ 40
CONSOLE_ROWS        	equ 25
CONSOLE_TEXT_COLOR		equ 3

allSegments group code, data
    assume cs:allSegments, ds:allSegments, es:nothing

code segment readonly public

;-------------;
; Code public ;
;-------------;

; Input: al (just the low nibble, the high nibble is cleared).
; Clobber: nothing.
consolePrintNibbleHex proc
if ASSERT_ENABLED
    cmp al,16
    jb short @f
    ASSERT
@@:
endif
	push ax
	and al,0fh
	cmp al,10
	jb short @f
	add al,"A" - ("9" + 1)
@@:
	add al,"0"
	call consolePrintChar
	pop ax
	ret
consolePrintNibbleHex endp

; Input: al.
; Clobber: nothing.
consolePrintByte proc
	push ax
	push cx
	push dx
	mov cl,10
	xor dx,dx
@@:
	xor ah,ah
	div cl
	push ax
	inc dx
	test al,al
	jnz short @b
	mov cx,3
	; Operating on bytes is enough here since the result of the subtraction is in [0,2].
	; Not sure if operating on bytes makes the subtraction any faster???
	sub cl,dl
	jz short leadingZeroesDone
	xor al,al	
leadingZeroes:
	call consolePrintNibbleHex
	loop leadingZeroes
leadingZeroesDone:
	mov cx,dx
digits:
	pop ax
	mov al,ah
	call consolePrintNibbleHex
	loop digits
	pop dx
	pop cx
	pop ax
	ret
consolePrintByte endp

; Input: al.
; Clobber: nothing.
consolePrintByteHex proc
	push ax
	push cx
	mov ch,al
	mov cl,4
	shr al,cl
	call consolePrintNibbleHex
	mov al,ch
	and al,0fh
	call consolePrintNibbleHex
	pop cx
	pop ax
	ret
consolePrintByteHex endp

; Input: ax.
; Clobber: nothing.
consolePrintWord proc
	push ax
	push bx
	push cx
	push dx
	mov cx,10
	xor bx,bx
@@:
	xor dx,dx
	div cx
	push dx
	inc bx
	test ax,ax
	jnz short @b
	; Operating on bytes is enough here since ch is zero already and the result of the subtraction is in [0,4].
	; Not sure if operating on bytes makes the subtraction any faster???
	mov cl,5
	sub cl,bl
	jz short leadingZeroesDone
	xor al,al	
leadingZeroes:
	call consolePrintNibbleHex
	loop leadingZeroes
leadingZeroesDone:
	mov cx,bx
digits:
	pop ax
	call consolePrintNibbleHex
	loop digits
	pop dx
	pop cx
	pop bx
	pop ax
	ret
consolePrintWord endp

; Input: ax.
; Clobber: nothing.
consolePrintWordHex proc
	push ax
	xchg al,ah
	call consolePrintByteHex
	mov al,ah
	call consolePrintByteHex
	pop ax
	ret
consolePrintWordHex endp

; Input: zf.
; Clobber: nothing.
consolePrintZeroFlag proc
	push ax
	mov al,"0"
	jnz short @f
	mov al,"1"
@@:
	call consolePrintChar
	pop ax
	ret
consolePrintZeroFlag endp

; Input: al.
; Clobber: nothing.
consolePrintChar proc
	push ax
    push bx
    push cx
    push dx
    cmp al,ASCII_CR
    jne short @f
    ; Read current cursor pos.
    mov dx,[ConsoleCursorColRow]
    ; Reset col.
    xor dl,dl
    jmp short updateCursorColRow
@@:
    cmp al,ASCII_LF
    jne short @f
    ; Read current cursor pos.
    mov dx,[ConsoleCursorColRow]
    jmp short incrementCursorRow
@@:
    ; LSB: color, MSB: page number 0.
    mov bx,CONSOLE_TEXT_COLOR
    ; Numbers of times the char should be printed.
    mov cx,1
    mov ah,BIOS_VIDEO_FUNC_SET_CHAR_AT_CURSOR_POS
    int BIOS_VIDEO_INT

    ; Read current cursor pos.
    mov dx,[ConsoleCursorColRow]
    ; Increment col.
    inc dl
    cmp dl,CONSOLE_COLS
    jb short updateCursorColRow
    ; Reset col.
    xor dl,dl
incrementCursorRow:    
    ; Increment row.
    inc dh
    cmp dh,CONSOLE_ROWS
    jb short updateCursorColRow
    ; Reset row.
    xor dh,dh
updateCursorColRow:
    call consoleSetCursorColRow
    pop dx
    pop cx
    pop bx
	pop ax
	ret
consolePrintChar endp

; Input: ds:si (null-terminated string).
; Clobber: nothing.
consolePrintString proc
	pushf
	push ax
	push si
	cld
@@:
	lodsb
	test al,al
	jz short done
	call consolePrintChar
	jmp short @b
done:
	pop si
	pop ax
	popf
	ret
consolePrintString endp

; Input: dl (unsigned col), dh (unsigned row).
; Clobber: nothing.
consoleSetCursorColRow proc
if ASSERT_ENABLED
    cmp dl,CONSOLE_COLS
    jb short @f
    ASSERT
@@:
    cmp dh,CONSOLE_ROWS
    jb short @f
    ASSERT
@@:
endif
	push ax
	push bx
    mov [ConsoleCursorColRow],dx
	; Maybe there is a faster way of setting the cursor position than using an int???
    mov ah,BIOS_VIDEO_FUNC_SET_CURSOR_POS
    ; Use page number 0.
    xor bh,bh
    int BIOS_VIDEO_INT
	pop bx
	pop ax
	ret
consoleSetCursorColRow endp

; Input: nothing.
; Clobber: nothing.
consoleNextLine proc
	push dx
    ; Read current cursor pos.
    mov dx,[ConsoleCursorColRow]
    ; Reset col.
    xor dl,dl
    ; Increment row.
    inc dh
    cmp dh,CONSOLE_ROWS
    jb short @f
    ; Reset row.
    xor dh,dh
@@:
	call consoleSetCursorColRow
	pop dx
	ret
consoleNextLine endp

;--------------;
; Code private ;
;--------------;

code ends

data segment public
	ConsoleCursorColRow		label word
	ConsoleCursorCol		byte ?
	ConsoleCursorRow		byte ?
data ends

endif

end
