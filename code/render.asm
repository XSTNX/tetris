RENDER_PIXEL macro
local notOddRow
	xor bx,bx
	;; Divide posY by two, since the even rows go in one bank and the odd rows in another.
	shr dl,1
	jnc notOddRow
	;; If it's an odd row, the bank starts at offset 2000h instead of 0000h.
	mov bh,20h
notOddRow:
	;; Multiply posY by 80 to obtain the offset in video memory to the row the pixel belongs to.
	mov al,80
	mul dl
	or bx,ax
	;; Save the last two bits of posX, since they decide which bits in the video memory byte the pixel belong to.
	mov si,cx
	and si,11b
	;; Divide posX by four to obtain the offset in video memory to the column the pixel belongs to.
	shr cx,1
	shr cx,1	
	add bx,cx
	;; Read the byte in video memory where the pixel is.
	mov al,es:[bx]
	;; Mask the previous pixel.
	and al,RenderPixelMask[si]
	;; Add the new pixel.
	mov cl,RenderPixelShift[si]
	shl dh,cl
	or al,dh
	;; Write the updated byte to video memory.
	mov es:[bx],al
endm

allSegments group code, constData
    assume cs:allSegments, ds:allSegments

code segment public

renderHorizLine proc
	push bx
	push cx
	push dx
	RENDER_PIXEL
	pop dx
	pop cx
	pop bx
	inc cx
	cmp cx,bx
	jne short renderHorizLine
	ret
renderHorizLine endp

renderBox proc
	push ax
	push cx
	push dx
	mov dh,al
	call renderHorizLine
	pop dx
	pop cx
	pop ax
	inc dl
	cmp dl,dh
	jne short renderBox
	ret
renderBox endp

; ---------;
; Private. ;
; ---------;

code ends

constData segment public
	RenderPixelMask         db 00111111b, 11001111b, 11110011b, 11111100b
	RenderPixelShift        db         6,         4,         2,         0
constData ends

end
