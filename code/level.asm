LEVEL_NO_EXTERNS equ 1
include code\level.inc
include code\bios.inc
include code\player.inc
include code\render.inc

allSegments group code
    assume cs:allSegments, ds:allSegments, es:nothing

code segment readonly public

; ------------;
; Code public ;
; ------------;

levelInit proc
	call playerInit
	ret
levelInit endp

levelUpdate proc
	call playerUpdate
	ret
levelUpdate endp

levelInitRender proc
	xor cx,cx
	mov di,BIOS_VIDEO_MODE_320_200_4_WIDTH
	mov dx,(BIOS_VIDEO_MODE_320_200_4_HEIGHT - 4) + (2 * 256)
	call renderHorizLine320x200x4
	call playerRender
	ret
levelInitRender endp

levelRender proc
	call playerRender
	ret
levelRender endp

; -------------;
; Code private ;
; -------------;

code ends

end
