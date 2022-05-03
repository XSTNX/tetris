ifndef GAME_NO_EXTERNS
extern gameQuit:proc
endif

GAME_QUIT macro errorCode:req
ifdifi <errorCode>,<al>
	mov al,errorCode
endif
	call gameQuit
endm
