include code\ascii.inc
include code\bios.inc
include code\dos.inc

consoleGoToNextLine macro
    consolePrintCharCR
    consolePrintCharLF
endm

; Note: the argument will be moved into dl for printing, so if the value is in dl already, just call it with no arguments.
consolePrintChar macro aChar
ifnb <aChar>
    mov dl,aChar
endif
	mov ah,DOS_REQUEST_FUNC_PRINT_CHAR
	int DOS_REQUEST_INT
endm

consolePrintCharCR macro
    consolePrintChar ASCII_CR
endm

consolePrintCharLF macro
    consolePrintChar ASCII_LF
endm

; Input: ds:dx (address of ASCII string ending in '$').
CONSOLE_PRINT_DOS_STRING macro
	mov ah,DOS_REQUEST_FUNC_PRINT_STRING
	int DOS_REQUEST_INT
endm

; Input: dh (row, Y coord), dl (col, X coord).
CONSOLE_SET_CURSOR_POS macro
    ;; Use page number 0.
    xor bh,bh
    mov ah,BIOS_VIDEO_FUNC_SET_CURSOR_POS
    int BIOS_VIDEO_INT
endm
