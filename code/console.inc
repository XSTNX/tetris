ifdef DEBUG
CONSOLE_ENABLED		equ 1
else
CONSOLE_ENABLED		equ 0
endif

if CONSOLE_ENABLED

include code\ascii.inc

ifndef CONSOLE_NO_EXTERNS
extern consolePrintNibbleHex:proc, consolePrintByte:proc, consolePrintByteHex:proc, consolePrintWord:proc, consolePrintWordHex:proc
extern consolePrintChar:proc, consolePrintString:proc, consoleSetCursorColRow:proc, consoleNextLine:proc
endif

endif

; Input: aCol (unsigned byte), aRow (unsigned byte).
; Clobber: nothing.
CONSOLE_SET_CURSOR_COL_ROW macro aCol:req, aRow:req
if CONSOLE_ENABLED
    ; Validate arguments, at the very least that they fit in one byte???
    push dx
    mov dx,aCol or (aRow shl 8)
    call consoleSetCursorColRow
    pop dx
endif
endm
