include code\timer.inc
include code\assumSeg.inc
include code\bios.inc

code segment readonly public

; ------------;
; Code public ;
; ------------;

; Output: ax (ticks elapsed since last call to timerReset)
; Clobber: bx, cx, dx.
timerGetTicks proc
    mov ah,BIOS_TIMER_FUNC_GET_SYSTEM_TIME
    int BIOS_TIMER_INT
    mov bx,[TimerPrevTickLo]
    mov ax,[TimerPrevTickHi]
    mov [TimerPrevTickLo],dx
    mov [TimerPrevTickHi],cx
    sub dx,bx
    sbb cx,ax
    mov ax,[TimerTicksElapsed]
    add ax,dx
    mov [TimerTicksElapsed],ax
    ret
timerGetTicks endp

; Clobber: ax, cx, dx.
timerResetTicks proc
    mov ah,BIOS_TIMER_FUNC_GET_SYSTEM_TIME
    int BIOS_TIMER_INT
    mov [TimerPrevTickLo],dx
    mov [TimerPrevTickHi],cx
    mov [TimerTicksElapsed],0
    ret
timerResetTicks endp

; -------------;
; Code private ;
; -------------;

code ends

constData segment readonly public
constData ends

data segment public
    TimerPrevTick               label dword
    TimerPrevTickLo             word ?    
    TimerPrevTickHi             word ?
    TimerTicksElapsed           word ?
data ends

end
