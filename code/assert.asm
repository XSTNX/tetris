include code\assert.inc
if ASSERT_ENABLED

include code\game.inc

allSegments group code
    assume cs:allSegments, ds:allSegments, es:nothing

code segment readonly public

; ------------;
; Code public ;
; ------------;

; Input: al (error code).
assert proc
    GAME_QUIT al
assert endp

; -------------;
; Code private ;
; -------------;

code ends

endif

end
