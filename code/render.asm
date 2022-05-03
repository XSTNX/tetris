RENDER_NO_EXTERNS equ 1
include code\render.inc
include code\assert.inc
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

allSegments group code, constData, data
    assume cs:allSegments, ds:allSegments, es:nothing

code segment readonly public

; ------------;
; Code public ;
; ------------;

; Input: none.
; Clobber: ax, bx, cx, dx.
; Might make more sense to create this table at assembly time, need to figure out how to use the repeat macro.
renderInitMultiplyRowBy80Table proc
	xor bx,bx
	mov cx,100
	mov dl,80
@@:
	mov al,bl
	shr al,1
	mul dl
	mov [RenderMultiplyRowBy80Table + bx],ax
	inc bx
	inc bx
	loop @b
	ret
renderInitMultiplyRowBy80Table endp

; Input:
; cx (unsigned posX).
; dl (unsigned posY).
; dh (2bit color).
; ds (data).
; es (video ram).
;
; Clobber: ax, bx, cx, dx, si.
renderPixel320x200x4 proc
if ASSERT_ENABLED
    cmp cx,320
    jae short error
    cmp dl,200
    jae short error
	cmp dh,4
	jb skipError
error:
    ASSERT
skipError:
endif
	xor bx,bx
	; Check if posY is even or odd, since even rows go in one bank and odd rows in another.
	test dl,1
	jz skipOddRow
	; If it's an odd row, the bank starts at offset 2000h instead of 0000h.
	mov bh,20h
skipOddRow:
	; Multiply posY by 80 to obtain the offset in video memory to the row the pixel belongs to.
	mov si,dx
	and si,0feh
	or bx,[RenderMultiplyRowBy80Table + si]
	; Save the last two bits of posX, since they decide which bits in the video memory byte the pixel belong to.
	mov si,cx
	and si,11b
	; Divide posX by four to obtain the offset in video memory to the column the pixel belongs to.
	shr cx,1
	shr cx,1
	add bx,cx
	; Read the byte in video memory where the pixel is and mask it.
	mov al,es:[bx]
	shl si,1
	mov cx,word ptr [RenderPixelShiftMask320x200x4 + si]
	and al,ch
	; Add the new pixel.
	shl dh,cl
	or al,dh
	; Write the updated byte to video memory.
	mov es:[bx],al
	ret
renderPixel320x200x4 endp

; Input:
; cx (unsigned lowX).
; di (unsigned highX + 1).
; dl (unsigned posY).
; dh (2bit color).
; ds (data).
; es (video ram).
;
; Clobber: ax, bx, cx, dx, si, bp.
renderHorizLine320x200x4 proc
if ASSERT_ENABLED	
	cmp cx,di
	jb @f
	ASSERT
@@:
endif
@@:
	mov bp,cx
	push dx
	call renderPixel320x200x4
	pop dx
	lea cx,[bp + 1]
	cmp cx,di
	jb short @b
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

data segment public
	; Might make more sense to create this table at assembly time, need to figure out how to use the repeat macro.
	RenderMultiplyRowBy80Table		word 100 dup(?)
data ends

end
