TIMER_NO_EXTERNS equ 1
include code\timer.inc
include code\assumSeg.inc
include code\bios.inc

code segment readonly public

; ------------;
; Code public ;
; ------------;

timerGetTime proc
    mov ah,BIOS_TIMER_FUNC_GET_SYSTEM_TIME
    int BIOS_TIMER_INT
    ret
timerGetTime endp

; -------------;
; Code private ;
; -------------;

code ends

constData segment readonly public
constData ends

data segment public
data ends

end
