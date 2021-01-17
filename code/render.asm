include code\bios.inc

renderPixel320x200x4 macro
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
;	cx (unsigned left limit).
;	bx (unsigned right limit + 1).
;	dl (unsigned posY).
;	dh (color).
; Note:
; 	Will render garbage if cx, bx or dl is outside the limits of the video mode.
renderHorizLine320x200x4 proc
nextPixel:
	push bx
	push cx
	push dx
	renderPixel320x200x4
	pop dx
	pop cx
	pop bx
	inc cx
	cmp cx,bx
	jne short nextPixel
	ret
renderHorizLine320x200x4 endp

; Input:
;	cx (unsigned left limit).
;	bx (unsigned right limit + 1).
;	dl (unsigned top limit).
;	dh (unsigned bottom limit + 1).
;	al (color).
; Note:
; 	Will render garbage if cx or bx is outside the limits of the video mode.
; 	Can only handle either dl or dh being outside the limits of the video mode, if both are it will render garbage.
renderBox320x200x4 proc
	cmp dl,BIOS_VIDEO_MODE_320_200_4_HEIGHT
	jb skipLimitTop
	xor dl,dl
skipLimitTop:
	cmp dh,BIOS_VIDEO_MODE_320_200_4_HEIGHT
	jb skipLimitBottom
	mov dh,BIOS_VIDEO_MODE_320_200_4_HEIGHT
skipLimitBottom:

nextLine:
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
	jne short nextLine
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
