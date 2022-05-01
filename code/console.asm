CONSOLE_NO_EXTERNS equ 1
include code\console.inc
if CONSOLE_ENABLED

include code\assert.inc
include code\bios.inc

CONSOLE_COLS        equ 40
CONSOLE_ROWS        equ 25

allSegments group code, data
    assume cs:allSegments, ds:allSegments, es:nothing

code segment readonly public

; ------------;
; Code public ;
; ------------;

; Input: al (just the low nibble, the high nibble is cleared).
; Clobber: ax.
consolePrintNibbleHex proc
	and al,0fh
	cmp al,10
	jb short @f
	add al,"A" - ("9" + 1)
@@:
	add al,"0"
	call consolePrintChar
	ret
consolePrintNibbleHex endp

; Input: al.
; Clobber: ax, cx, dx.
consolePrintByte proc
	mov cl,10
	xor dx,dx
@@:
	xor ah,ah
	div cl
	push ax
	inc dx
	test al,al
	jne @b
	mov cx,3
	; Operating on bytes is enough here since the result of the subtraction is in [0,2].
	; Not sure if operating on bytes makes the subtraction any faster???
	sub cl,dl
	jz leadingZeroesDone
leadingZeroes:
	xor al,al
	call consolePrintNibbleHex
	loop leadingZeroes
leadingZeroesDone:
	mov cx,dx
digits:
	pop ax
	mov al,ah
	call consolePrintNibbleHex
	loop digits
	ret
consolePrintByte endp

; Input: al.
; Clobber: ax, cx.
consolePrintByteHex proc
	mov ch,al
	mov cl,4
	shr al,cl
	call consolePrintNibbleHex
	mov al,ch
	call consolePrintNibbleHex
	ret
consolePrintByteHex endp

; Input: ax.
; Clobber: ax, bx, cx, dx.
consolePrintWord proc
	mov cx,10
	xor bx,bx
@@:
	xor dx,dx
	div cx
	push dx
	inc bx
	test ax,ax
	jne @b
	; Operating on bytes is enough here since ch is zero already and the result of the subtraction is in [0,4].
	; Not sure if operating on bytes makes the subtraction any faster???
	mov cl,5
	sub cl,bl
	jz leadingZeroesDone
leadingZeroes:
	xor al,al
	call consolePrintNibbleHex
	loop leadingZeroes
leadingZeroesDone:
	mov cx,bx
digits:
	pop ax
	call consolePrintNibbleHex
	loop digits
	ret
consolePrintWord endp

; Input: ax.
; Clobber: ax, cx, dh.
consolePrintWordHex proc
	mov dh,al
	mov al,ah
	call consolePrintByteHex
	mov al,dh
	call consolePrintByteHex
	ret
consolePrintWordHex endp

; Input: al.
; Clobber: ax.
consolePrintChar proc
    push bx
    push cx
    push dx
    cmp al,ASCII_CR
    jne short @f
    ; Read current cursor pos.
    mov dx,[ConsoleCursorColRow]
    ; Reset col.
    xor dl,dl
    jmp short updateCursorPos
@@:
    cmp al,ASCII_LF
    jne short @f
    ; Read current cursor pos.
    mov dx,[ConsoleCursorColRow]
    jmp short incrementCursorRow
@@:
    ; LSB: color 3, MSB: page number 0.
    mov bx,0003h
    ; Numbers of times the char should be printed.
    mov cx,1
    mov ah,BIOS_VIDEO_FUNC_SET_CHAR_AT_CURSOR_POS
    int BIOS_VIDEO_INT

    ; Read current cursor pos.
    mov dx,[ConsoleCursorColRow]
    ; Increment col.
    inc dl
    cmp dl,CONSOLE_COLS
    jb updateCursorPos
    ; Reset col.
    xor dl,dl
incrementCursorRow:    
    ; Increment row.
    inc dh
    cmp dh,CONSOLE_ROWS
    jb updateCursorPos
    ; Reset row.
    xor dh,dh
updateCursorPos:
    call consoleSetCursorPos
    pop dx
    pop cx
    pop bx
	ret
consolePrintChar endp

; Input: ds:si (null-terminated string).
consolePrintString proc
	pushf
	cld
@@:
	lodsb
	test al,al
	jz short done
	call consolePrintChar
	jmp short @b
done:
	popf
	ret
consolePrintString endp

consoleSetCursorPos proc
if ASSERT_ENABLED
    cmp dl,CONSOLE_COLS
    jb @f
    ASSERT
@@:
    cmp dh,CONSOLE_ROWS
    jb @f
    ASSERT
@@:
endif
    mov [ConsoleCursorColRow],dx
    ;; Use page number 0.
    xor bh,bh
    mov ah,BIOS_VIDEO_FUNC_SET_CURSOR_POS
    int BIOS_VIDEO_INT
	ret
consoleSetCursorPos endp

consoleNextLine proc
    ; Read current cursor pos.
    mov dx,[ConsoleCursorColRow]
    ; Reset col.
    xor dl,dl
    ; Increment row.
    inc dh
    cmp dh,CONSOLE_ROWS
    jb @f
    ; Reset row.
    xor dh,dh
@@:
	call consoleSetCursorPos
	ret
consoleNextLine endp

; -------------;
; Code private ;
; -------------;

code ends

data segment public
	public ConsoleCursorColRow
	ConsoleCursorColRow		label word
	ConsoleCursorCol		byte ?
	ConsoleCursorRow		byte ?
data ends

endif

end
