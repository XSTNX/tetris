include code\errcode.inc

ifndef GAME_NO_EXTERNS
extern gameQuitWithErrorArg:proc
endif

GAME_QUIT macro
	GAME_QUIT_WITH_ERROR_ARG ERROR_CODE_NONE
endm

GAME_QUIT_WITH_ERROR_ARG macro errorCode:req
	mov al,errorCode
	call gameQuitWithErrorArg
endm
