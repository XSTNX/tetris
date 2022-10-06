include code\test2.inc
include code\assert.inc
include code\assumSeg.inc
include code\console.inc
include code\keyboard.inc
include code\render.inc
include code\timer.inc

TEST2_PIXELS_PER_FRAME      equ 1024

code segment readonly public

; ------------;
; Code public ;
; ------------;

test2Init proc
    ;mov al,[testData]

    xor ax,ax
    mov [Test2PosX],ax
    mov [Test2PosYColor],100h
if CONSOLE_ENABLED
    mov [Test2Ticks],ax
    mov [Test2FrameCounter],al
    mov [Test2PrevFrameCounter],al
endif
    ret
test2Init endp

test2InitRender proc
if CONSOLE_ENABLED
    call timerResetTicks
endif
    ret
test2InitRender endp

test2Update proc
    ret
test2Update endp

test2Render proc
    mov cx,[Test2PosX]
    mov dx,[Test2PosYColor]
    mov di,TEST2_PIXELS_PER_FRAME    

nextPixel:
    push cx
    push dx
    call renderPixel320x200x4
    pop dx
    pop cx
    ; Increment posX.
    inc cx
    cmp cx,BIOS_VIDEO_MODE_320_200_4_WIDTH
    jne short skipUpdate
    ; Reset posX.
    xor cx,cx
    ; Increment posY.
    inc dl
    cmp dl,BIOS_VIDEO_MODE_320_200_4_HEIGHT
    jne short skipUpdate
    ; Reset posY.
    xor dl,dl
    ; Increment color keeping it in range.
    inc dh
    and dh,11b
skipUpdate:
    dec di
    jnz nextPixel

    ; Save updated values.
    mov [Test2PosX],cx
    mov [Test2PosYColor],dx

if CONSOLE_ENABLED
    CONSOLE_SET_CURSOR_COL_ROW 0, 0
    call timerGetTicks
    mov bx,ax
    mov cx,ax
    mov al,[Test2FrameCounter]
    inc al
    mov [Test2FrameCounter],al
    sub cx,[Test2Ticks]
    cmp cx,18
    jb @f
    mov [Test2Ticks],bx
    mov [Test2PrevFrameCounter],al
    mov [Test2FrameCounter],0
@@:
    mov al,[Test2PrevFrameCounter]
    call consolePrintByte
endif
    ret
test2Render endp

; -------------;
; Code private ;
; -------------;

code ends

    ; It's supposed to prevent from using instructions in data segments, but doesn't seem to work, maybe I'm doing it wrong?
    assume cs:error
constData segment readonly public
constData ends

data segment public
    Test2PosX           word ?
    Test2PosYColor      label word
    Test2PosY           byte ?
    Test2Color          byte ?
if CONSOLE_ENABLED
    Test2Ticks          word ?
    Test2FrameCounter   byte ?
    Test2PrevFrameCounter   byte ?
endif    
;testData label byte
;    mov ax,1
data ends

end
