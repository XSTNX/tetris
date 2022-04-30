CONSOLE_NO_EXTERNS equ 1
include code\console.inc
if CONSOLE_ENABLED

allSegments group code, data
    assume cs:allSegments, ds:allSegments, es:nothing

code segment readonly public

; ------------;
; Code public ;
; ------------;

; Input: dl (only the low nibble).
consolePrintNibbleHex proc
	and dl,0fh
	cmp dl,10
	jb short skipLetter
	add dl,'A' - ('9' + 1)
skipLetter:
	add dl,'0'
	CONSOLE_PRINT_CHAR dl
	ret
consolePrintNibbleHex endp

; Input: dl.
consolePrintByte proc
	mov al,dl
	mov bl,10
	xor cx,cx
divide:
	xor ah,ah
	div bl
	push ax
	inc cx
	test al,al
	jne divide
	mov bx,3
	sub bx,cx
	je nextDigit
	xor dl,dl
leadingZeroes:
	call consolePrintNibbleHex
	dec bx
	jnz leadingZeroes
nextDigit:
	pop dx
	mov dl,dh
	call consolePrintNibbleHex
	loop nextDigit
	ret
consolePrintByte endp

; Input: dl.
consolePrintByteHex proc
	mov ch,dl
	mov cl,4
	shr dl,cl
	call consolePrintNibbleHex
	mov dl,ch
	call consolePrintNibbleHex
	ret
consolePrintByteHex endp

; Input: dx.
consolePrintWord proc
	mov ax,dx
	mov bx,10
	xor cx,cx
divide:
	xor dx,dx
	div bx
	push dx
	inc cx
	test ax,ax
	jne divide
	; Setting bl is enough since bh is zero.
	mov bl,5
	sub bl,cl
	je nextDigit
leadingZeroes:	
	xor dl,dl
	call consolePrintNibbleHex
	dec bx
	jnz leadingZeroes
nextDigit:
	pop dx
	call consolePrintNibbleHex
	loop nextDigit
	ret
consolePrintWord endp

; Input: dx.
consolePrintWordHex proc
	xchg dl,dh
	call consolePrintByteHex
	mov dl,dh
	call consolePrintByteHex
	ret
consolePrintWordHex endp

; Input: al.
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
    CONSOLE_SET_CURSOR_POS_IN_DX
    pop dx
    pop cx
    pop bx
	ret
consolePrintChar endp

; Input: ds:dx (far ptr to a null-terminated string).
consolePrintString proc
	pushf
	cld
	mov si,dx
printLoop:
	lodsb
	test al,al
	jz short printLoopDone
	CONSOLE_PRINT_CHAR al
	jmp short printLoop
printLoopDone:
	popf
	ret
consolePrintString endp

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
