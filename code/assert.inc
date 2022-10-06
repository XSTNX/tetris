ifndef assert_inc
assert_inc = 1

ifdef DEBUG
ASSERT_ENABLED		equ 1
else
ASSERT_ENABLED		equ 0
endif

include code\errcode.inc

if ASSERT_ENABLED
externdef assert:proc
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

endif
