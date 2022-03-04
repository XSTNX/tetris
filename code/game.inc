ifndef GAME_NO_EXTERNS
extern gameQuitWithErrorArg:proc
endif

; Validate if errorCode is already in al??????
GAME_QUIT_WITH_ERROR_ARG macro errorCode:req
	mov al,errorCode
	call gameQuitWithErrorArg
endm
