ifndef game_inc
game_inc = 1

externdef gameQuit:proc

GAME_QUIT macro errorCode:req
ifdifi <errorCode>,<al>
	mov al,errorCode
endif
	call gameQuit
endm

endif
