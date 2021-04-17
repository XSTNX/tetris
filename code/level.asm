include code\bios.inc

allSegments group code
    assume cs:allSegments, ds:allSegments

code segment public

extern playerInit:proc, playerInitRender:proc, playerUpdate:proc, playerRender:proc
extern renderHorizLine320x200x4:proc

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

code ends

end
