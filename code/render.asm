include code\bios.inc

RENDER_PIXEL_320_200_4 macro
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
	and al,RenderPixelMask320x200x4[si]
	;; Add the new pixel.
	mov cl,RenderPixelShift320x200x4[si]
	shl dh,cl
	or al,dh
	;; Write the updated byte to video memory.
	mov es:[bx],al
endm

allSegments group code, constData
    assume cs:allSegments, ds:allSegments

code segment public

; Input:
;	cx (left limit).
;	bx (right limit + 1).
;	dl (posY).
;	dh (color).
renderHorizLine320x200x4 proc
start:
	push bx
	push cx
	push dx
	RENDER_PIXEL_320_200_4
	pop dx
	pop cx
	pop bx
	inc cx
	cmp cx,bx
	jne short start
	ret
renderHorizLine320x200x4 endp

; Input:
;	cx (left limit).
;	bx (right limit + 1).
;	dl (top limit).
;	dh (bottom limit + 1).
;	al (color).
renderBox320x200x4 proc
start:
	cmp dl,BIOS_VIDEO_MODE_320_200_4_HEIGHT
	jb skipLimitTop
	xor dl,dl
skipLimitTop:
	cmp dh,BIOS_VIDEO_MODE_320_200_4_HEIGHT
	jb skipLimitBottom
	mov dh,BIOS_VIDEO_MODE_320_200_4_HEIGHT
skipLimitBottom:
	push ax
	push cx
	push dx
	mov dh,al
	call renderHorizLine320x200x4
	pop dx
	pop cx
	pop ax
	inc dl
	cmp dl,dh
	jne short start
	ret
renderBox320x200x4 endp

; ---------;
; Private. ;
; ---------;

code ends

constData segment public
	RenderPixelMask320x200x4		db 00111111b, 11001111b, 11110011b, 11111100b
	RenderPixelShift320x200x4		db         6,         4,         2,         0
constData ends

end
