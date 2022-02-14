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
	mov cx,0
	mov bx,BIOS_VIDEO_MODE_320_200_4_WIDTH
	mov dl,196
	mov dh,2
	call renderHorizLine320x200x4
	call playerInitRender
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
