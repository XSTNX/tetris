include code\ascii.inc
include code\dos.inc

CONSOLE_GO_NEXT_LINE macro
    CONSOLE_PRINT_CHAR_CR
    CONSOLE_PRINT_CHAR_LF
endm

; Input: dl.
CONSOLE_PRINT_CHAR macro
	mov ah,DOS_REQUEST_FUNC_PRINT_CHAR
	int DOS_REQUEST_INT
endm

CONSOLE_PRINT_CHAR_CR macro
    mov dl,ASCII_CR
    CONSOLE_PRINT_CHAR
endm

CONSOLE_PRINT_CHAR_LF macro
    mov dl,ASCII_LF
    CONSOLE_PRINT_CHAR
endm

; Input: ds:dx (address of ASCII string ending in '$').
CONSOLE_PRINT_DOS_STRING macro
	mov ah,DOS_REQUEST_FUNC_PRINT_STRING
	int DOS_REQUEST_INT
endm
