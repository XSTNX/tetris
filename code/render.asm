RENDER_NO_EXTERNS equ 1
include code\render.inc
include code\bios.inc

computeVideoAddr320x200x4 macro
local skipOdd
	mov bl,dl
	shr dl,1
	mov al,80
	mul dl
	shr cx,1
	shr cx,1
	add ax,cx
	mov di,ax
	;; Is posY odd?
	test bl,1
	lea bx,[di + 2000h]	
	jz skipOdd
	add di,80
skipOdd:
endm

; Should assert on the debug configuration if the positions are out of range!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Document which registers it destroys!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Input:
;	cx (unsigned posX).
;	dl (unsigned posY).
;	dh (2bit color).
;   es (video ram).
RENDER_PIXEL_320x200x4 macro
local notOddRow
	xor bx,bx
	;; Divide posY by two, since even rows go in one bank and odd rows in another.
	shr dl,1
	jnc skipOddRow
	;; If it's an odd row, the bank starts at offset 2000h instead of 0000h.
	mov bh,20h
skipOddRow:
	;; Multiply posY by 80 to obtain the offset in video memory to the row the pixel belongs to.
	;; I assume shifting and adding is faster than multiplying but it would be nice to confirm it???????????
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
	;; Read the byte in video memory where the pixel is and mask it.
	mov al,es:[bx]
	shl si,1
	mov cx,word ptr [RenderPixelShiftMask320x200x4 + si]
	and al,ch
	;; Add the new pixel.
	shl dh,cl
	or al,dh
	;; Write the updated byte to video memory.
	mov es:[bx],al
endm

allSegments group code, constData
    assume cs:allSegments, ds:allSegments, es:nothing

code segment readonly public

; ------------;
; Code public ;
; ------------;

renderPixel320x200x4 proc
	RENDER_PIXEL_320x200x4
	ret
renderPixel320x200x4 endp

; Input:
;	cx (unsigned left limit).
;	bx (unsigned right limit + 1).
;	dl (unsigned posY).
;	dh (2bit color).
; Note:
; 	Will render garbage if cx, bx or dl is outside the limits of the video mode.
renderHorizLine320x200x4 proc
nextPixel:
	push bx
	push cx
	push dx
	RENDER_PIXEL_320x200x4
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
;	al (2bit color).
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

; Input.
;	cx: posXLow (unsigned word).
;	dl: posYLow (unsigned byte).
renderEraseSprite8x8 proc
	; Compute addr in video memory to erase.
	computeVideoAddr320x200x4

	xor ax,ax
	mov cx,4
renderLineEven:
	stosw
	stosb
	add di,77
	loop renderLineEven

	mov cx,4
	mov di,bx
renderLineOdd:
	stosw
	stosb
	add di,77
	loop renderLineOdd

	ret
renderEraseSprite8x8 endp

; Input.
;	cx: posXLow (unsigned word).
;	dl: posYLow (unsigned byte).
;	si: bitmap (near ptr).
renderSprite8x8 proc
	; Compute addr in video memory to copy the bitmap to.
	computeVideoAddr320x200x4

	; Copy even lines.
	mov cx,4
renderLineEven:
	lodsw
	stosw
	lodsb
	stosb
	add di,77
	loop renderLineEven
	
	; Copy odd lines.
	mov cx,4
	mov di,bx
renderLineOdd:
	lodsw
	stosw
	lodsb
	stosb
	add di,77
	loop renderLineOdd

	ret
renderSprite8x8 endp

; -------------;
; Code private ;
; -------------;

code ends

constData segment readonly public
	RenderPixelShiftMask320x200x4	byte 6, 00111111b, 4, 11001111b, 2, 11110011b, 0, 11111100b
constData ends

end
