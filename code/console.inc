ifdef DEBUG
CONSOLE_ENABLED		equ 1
else
CONSOLE_ENABLED		equ 0
endif

include code\ascii.inc
if CONSOLE_ENABLED
include code\assert.inc
include code\bios.inc

ifndef CONSOLE_NO_EXTERNS
extern consolePrintNibbleHex:proc, consolePrintByte:proc, consolePrintByteHex:proc, consolePrintWord:proc, consolePrintWordHex:proc
extern consolePrintChar:proc, consolePrintString:proc, consoleSetCursorPos:proc, consoleNextLine:proc
extern ConsoleCursorColRow:word
endif
endif

; Input: aCol (X coord - unsigned byte), aRow (Y coord - unsigned byte).
CONSOLE_SET_CURSOR_POS macro aCol:req, aRow:req
if CONSOLE_ENABLED
    mov dx,aCol + (aRow * 256)
    call consoleSetCursorPos
endif
endm
