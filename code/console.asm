CONSOLE_NO_EXTERNS equ 1
include code\console.inc

allSegments group code
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
	consolePrintChar dl
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

; Input: ds:dx (far ptr to a null-terminated string).
consolePrintString proc
	pushf
	cld
	mov si,dx
printLoop:
	lodsb
	test al,al
	jz short printLoopDone
	consolePrintChar al
	jmp short printLoop
printLoopDone:
	popf
	ret
consolePrintString endp

; -------------;
; Code private ;
; -------------;

code ends

end
