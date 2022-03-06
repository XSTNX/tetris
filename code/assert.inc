ifdef DEBUG
ASSERT_ENABLED		equ 1
else
ASSERT_ENABLED		equ 0
endif

include code\errcode.inc

ifndef ASSERT_NO_EXTERNS
if ASSERT_ENABLED
extern assert:proc
endif
endif

ASSERT macro
if ASSERT_ENABLED
	ASSERT_WITH_ERROR_ARG ERROR_CODE_ASSERT
endif
endm

; Validate if errorCode is already in al??????
ASSERT_WITH_ERROR_ARG macro errorCode:req
if ASSERT_ENABLED
	mov al,errorCode
	call assert
endif	
endm
