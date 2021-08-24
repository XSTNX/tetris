include code\assumSeg.inc

code segment readonly public

extern renderHorizLine320x200x4:proc

test2Init proc
    ;int 3
    mov al,[testData]
    ret
test2Init endp

test2InitRender proc
    call test2Render    

    ret
test2InitRender endp

test2Update proc
    ret
test2Update endp

test2Render proc
;	cx (unsigned left limit).
;	bx (unsigned right limit + 1).
;	dl (unsigned posY).
;	dh (color).
    xor cx,cx
    mov bx,319
    mov dx,(1 * 256) + 99;
    mov si,3
lineLoop:
    push bx
    push cx
    push si
    call renderHorizLine320x200x4
    pop si
    pop cx  
    pop bx
    add dx,101h
    dec si
    jne lineLoop
    ret
test2Render endp

; ---------;
; Private. ;
; ---------;

code ends

    ; It's supposed to prevent from using instructions in data segments, but doesn't seem to work, maybe I'm doing it wrong?
    assume cs:error
constData segment readonly public
constData ends

data segment public
testData label byte
    mov ax,1
data ends

end
