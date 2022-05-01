ifdef DEBUG
CONSOLE_ENABLED		equ 1
else
CONSOLE_ENABLED		equ 0
endif

include code\ascii.inc
if CONSOLE_ENABLED
include code\assert.inc
include code\bios.inc

CONSOLE_COLS        equ 40
CONSOLE_ROWS        equ 25

ifndef CONSOLE_NO_EXTERNS
extern consolePrintNibbleHex:proc, consolePrintByte:proc, consolePrintByteHex:proc, consolePrintWord:proc, consolePrintWordHex:proc
extern consolePrintChar:proc, consolePrintString:proc
extern ConsoleCursorColRow:word
endif
endif

CONSOLE_NEXT_LINE macro
if CONSOLE_ENABLED
    ; Read current cursor pos.
    mov dx,[ConsoleCursorColRow]
    ; Reset col.
    xor dl,dl
    ; Increment row.
    inc dh
    cmp dh,CONSOLE_ROWS
    jb @f
    ; Reset row.
    xor dh,dh
@@:
    CONSOLE_SET_CURSOR_POS_IN_DX
endif    
endm

; Input: aChar, moved to al (unsigned byte).
CONSOLE_PRINT_CHAR macro aChar:req
if CONSOLE_ENABLED
ifdifi <aChar>, <al>
    ; Char to print.
    mov al,aChar
endif
    call consolePrintChar
endif
endm

CONSOLE_PRINT_STRING macro aAddr:req
if CONSOLE_ENABLED
ifdifi <aAddr>, <si>
    mov si,aAddr
endif
    call consolePrintString
endif
endm

; Input: aCol (X coord - unsigned byte), aRow (Y coord - unsigned byte).
CONSOLE_SET_CURSOR_POS macro aCol:req, aRow:req
if CONSOLE_ENABLED
    mov dx,aCol + (aRow * 256)
    CONSOLE_SET_CURSOR_POS_IN_DX
endif    
endm

CONSOLE_SET_CURSOR_POS_IN_DX macro
if CONSOLE_ENABLED
if ASSERT_ENABLED
    cmp dl,CONSOLE_COLS
    jb @f
    ASSERT
@@:
    cmp dh,CONSOLE_ROWS
    jb @f
    ASSERT
@@:
endif
    mov [ConsoleCursorColRow],dx
    ;; Use page number 0.
    xor bh,bh
    mov ah,BIOS_VIDEO_FUNC_SET_CURSOR_POS
    int BIOS_VIDEO_INT
endif    
endm
