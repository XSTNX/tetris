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

ASSERT macro errorCode
if ASSERT_ENABLED
ifnb <errorCode>
ifdifi <errorCode>,<al>
	mov al,errorCode
endif
else
	mov al,ERROR_CODE_ASSERT
endif
	call assert
endif
endm
