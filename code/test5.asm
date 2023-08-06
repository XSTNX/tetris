include code\test5.inc
include code\assert.inc
include code\assumSeg.inc
include code\console.inc

PRIME_COUNT     equ 3 + 97 ; Force count to be at least three, so the array always contains zero, one and two.

code segment readonly public

;-------------;
; Code public ;
;-------------;

test5Init proc
    ; Init array.
    mov ax,ds
    mov es,ax
    mov al,1
    mov si,offset PrimeArray
    mov cx,PRIME_COUNT
    mov di,si
    rep stosb
    ; Compute prime numbers.
    mov ax,2
    xor dl,dl
primeLoop0:
    mov bx,ax
primeLoop1:
    add bx,ax
    cmp bx,PRIME_COUNT
    jae short primeNext
    mov [si + bx],dl
    jmp short primeLoop1
primeNext:
    inc ax
    cmp ax,PRIME_COUNT
    jb short primeLoop0
    ret
test5Init endp

test5InitRender proc
if CONSOLE_ENABLED
    mov bx,2
    mov al,bl
    call consolePrintByte
    mov cx,PRIME_COUNT - 3
    jcxz short done
    mov si,offset PrimeArray
    inc bx
@@:
    cmp byte ptr [si + bx],1
    jne short next
    mov al,','
    call consolePrintChar
    mov al,bl
    call consolePrintByte
next:
    inc bx
    loop short @b
done:
endif
    ret
test5InitRender endp

test5Update proc
    ret
test5Update endp

test5Render proc
    ret
test5Render endp

;--------------;
; Code private ;
;--------------;

code ends

constData segment readonly public
constData ends

data segment public
    PrimeArray      byte PRIME_COUNT dup (?)
data ends

end
