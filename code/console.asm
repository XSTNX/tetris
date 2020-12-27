include code\dos.inc

allSegments group code
    assume cs:allSegments

code segment public

; Input: dl (just the low nibble).
printNibbleHex proc
	and dl,0fh
	cmp dl,10
	jb short skipLetter
	add dl,'A' - ('9' + 1)
skipLetter:
	add dl,'0'
printChar:
	mov ah,DOS_REQUEST_FUNC_PRINT_CHAR
	int DOS_REQUEST_INT
	ret
printNibbleHex endp

; Input: dl.
printByte proc
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
	call printNibbleHex
	dec bx
	jnz leadingZeroes
nextDigit:
	pop dx
	mov dl,dh
	call printNibbleHex
	loop nextDigit
	ret
printByte endp

printByteHex proc
	mov ch,dl
	mov cl,4
	shr dl,cl
	call printNibbleHex
	mov dl,ch
	call printNibbleHex
	ret
printByteHex endp

printWord proc
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
	call printNibbleHex
	dec bx
	jnz leadingZeroes
nextDigit:
	pop dx
	call printNibbleHex
	loop nextDigit
	ret
printWord endp

printWordHex proc
	xchg dl,dh
	call printByteHex
	mov dl,dh
	call printByteHex
	ret
printWordHex endp

; ---------;
; Private. ;
; ---------;

code ends

    end
