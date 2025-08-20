include code\render.inc
include code\assert.inc
include code\bios.inc

; Check how the address is computed compared to render pixel and how it's done in tetris.
COMPUTE_VIDEO_ADDR_320x200x4 macro
local l
	mov bl,dl
	;; Should use the multiplication table instead.
	shr dl,1
	mov al,BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE
	mul dl
	shr cx,1
	shr cx,1
	add ax,cx
	mov di,ax
	;; Is posY odd?
	test bl,1
	lea bx,[di + BIOS_VIDEO_MODE_320_200_4_BANK1_OFFSET]
	jz short l
	add di,BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE
l:
endm

allSegments group code, constData, data
    assume cs:allSegments, ds:allSegments, es:nothing

code segment readonly public

;-------------;
; Code public ;
;-------------;

; Clobber: ax, cx, dx, di.
renderStart proc
	; Initialize muliplication table.
	xor ax,ax
	mov cx,lengthof RenderMultiplyRowBy80Table
	mov di,offset RenderMultiplyRowBy80Table
@@:
	stosw
	add ax,BIOS_VIDEO_MODE_320_200_4_BYTES_P_LINE
	loop @b
	ret
renderStart endp

; Input:
; cx (unsigned posX).
; dl (unsigned posY).
; dh (2bit color).
; ds (data).
; es (video ram).
;
; Clobber: ax, bx, cx, dh, si.
renderPixel320x200x4 proc
if ASSERT_ENABLED
    cmp cx,BIOS_VIDEO_MODE_320_200_4_WIDTH
    jb short @f
	ASSERT
@@:
    cmp dl,BIOS_VIDEO_MODE_320_200_4_HEIGHT
    jb short @f
	ASSERT
@@:
	cmp dh,BIOS_VIDEO_MODE_320_200_4_COLOR_COUNT
    jb short @f
	ASSERT
@@:
endif
	.erre BIOS_VIDEO_MODE_320_200_4_BANK0_OFFSET eq 0
	xor bx,bx
	; Check if posY is even or odd, since even rows go in bank0 and odd rows in bank1.
	test dl,1
	jz short @f
	.erre low BIOS_VIDEO_MODE_320_200_4_BANK1_OFFSET eq 0
	mov bh,high BIOS_VIDEO_MODE_320_200_4_BANK1_OFFSET
@@:
	; Multiply posY by 80 to obtain the offset in video memory of the row the pixel belongs to.
	mov si,dx
	and si,0feh
	or bx,[RenderMultiplyRowBy80Table + si]
	; Save the low order two bits of posX, to decide which bits in a video memory byte the pixel belong to.
	mov si,cx
	and si,11b
	; Divide posX by four to obtain the offset in video memory of the col the pixel belongs to.
	shr cx,1
	shr cx,1
	add bx,cx
	; Read the byte in video memory where the pixel is and mask it.
	mov al,es:[bx]
	shl si,1
	mov cx,word ptr [RenderPixelShiftMask320x200x4 + si]
	and al,ch
	; Put the new pixel in the right place within the byte.
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
; Clobber: ax, bx, cx, si, bp.
renderHorizLine320x200x4 proc
if ASSERT_ENABLED	
	cmp cx,di
	jb short @f
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
; cx (unsigned posX).
; dl (unsigned lowY).
; bl (unsigned highY + 1).
; dh (2bit color).
; ds (data).
; es (video ram).
;
; Clobber: ax, dl, si.
renderVertLine320x200x4 proc
if ASSERT_ENABLED
	cmp dl,bl
	jb short @f
	ASSERT
endif
@@:
	push bx
	push cx
	push dx
	call renderPixel320x200x4
	pop dx
	pop cx
	pop bx
	inc dl
	cmp dl,bl
	jb short @b
	ret
renderVertLine320x200x4 endp

; Input:
; cx (unsigned lowX).
; di (unsigned highX + 1).
; dl (unsigned lowY).
; bl (unsigned highY + 1).
; dh (2bit color).
; ds (data).
; es (video ram).
;
; Clobber: ax, si, bp.
renderRect320x200x4 proc
if ASSERT_ENABLED
	cmp dl,bl
	jb short @f
	ASSERT
endif
@@:
	push bx
	push cx
	push dx
	call renderHorizLine320x200x4
	pop dx
	pop cx
	pop bx
	inc dl
	cmp dl,bl
	jb short @b
	ret
renderRect320x200x4 endp

; Input.
;	cx: posXLow (unsigned word).
;	dl: posYLow (unsigned byte).
renderEmptyTile8x8 proc
	; Compute addr in video memory to erase.
	COMPUTE_VIDEO_ADDR_320x200x4

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
renderEmptyTile8x8 endp

; Input.
;	cx: posXLow (unsigned word).
;	dl: posYLow (unsigned byte).
;	si: bitmap (near ptr).
renderTile8x8 proc
	; Compute addr in video memory to copy the bitmap to.
	COMPUTE_VIDEO_ADDR_320x200x4

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
renderTile8x8 endp

;--------------;
; Code private ;
;--------------;

code ends

constData segment readonly public
	RenderPixelShiftMask320x200x4	byte 6, 00111111b, 4, 11001111b, 2, 11110011b, 0, 11111100b
constData ends

data segment public
	; Each line in video memory uses 80 bytes and there are two banks with half of the lines each.
	RenderMultiplyRowBy80Table		word BIOS_VIDEO_MODE_320_200_4_HALF_HEIGHT dup(?)
data ends

end
