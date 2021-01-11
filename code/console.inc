include code\ascii.inc
include code\bios.inc
include code\dos.inc

consoleGoToNextLine macro
    consolePrintCharCR
    consolePrintCharLF
endm

; Input: aChar (unsigned byte).
consolePrintChar macro aChar:req
;; If the argument is in dl already, this opcode is not needed.
ifdifi <aChar>, <dl>
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
consolePrintDOSStr macro
	mov ah,DOS_REQUEST_FUNC_PRINT_STRING
	int DOS_REQUEST_INT
endm

; Input: aCol (X coord - unsigned byte), aRow (Y coord - unsigned byte).
consoleSetCursorPos macro aCol:req, aRow:req
    mov dx,aCol + (aRow * 256)
    ;; Use page number 0.
    xor bh,bh
    mov ah,BIOS_VIDEO_FUNC_SET_CURSOR_POS
    int BIOS_VIDEO_INT
endm
