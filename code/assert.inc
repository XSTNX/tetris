ifndef ASSERT_INC
ASSERT_INC = 1

ifdef DEBUG
ASSERT_ENABLED		equ 1
else
ASSERT_ENABLED		equ 0
endif

include code\errcode.inc

if ASSERT_ENABLED
externdef assert:proc
endif

ASSERT macro aErrorCode
if ASSERT_ENABLED
	ifnb <aErrorCode>
		ifdifi <aErrorCode>,<al>
	mov al,aErrorCode
		endif
	else
	mov al,ERROR_CODE_ASSERT
	endif
	call assert
endif
endm

endif
