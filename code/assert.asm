ASSERT_NO_EXTERNS equ 1
include code\assert.inc
include code\game.inc

if ASSERT_ENABLED

allSegments group code
    assume cs:allSegments, ds:allSegments, es:nothing

code segment readonly public

; ------------;
; Code public ;
; ------------;

assert proc
    GAME_QUIT_WITH_ERROR_ARG al
assert endp

; -------------;
; Code private ;
; -------------;

code ends

endif

end
