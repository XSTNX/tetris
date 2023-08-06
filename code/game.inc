ifndef GAME_INC
GAME_INC = 1

externdef gameQuit:proc

GAME_QUIT macro errorCode:req
ifdifi <errorCode>,<al>
	mov al,errorCode
endif
	call gameQuit
endm

endif
