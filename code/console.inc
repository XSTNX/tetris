include code\ascii.inc
include code\bios.inc

CONSOLE_COLS        equ 40
CONSOLE_ROWS        equ 25

ifndef CONSOLE_NO_EXTERNS
extern consolePrintNibbleHex:proc, consolePrintByte:proc, consolePrintByteHex:proc, consolePrintWord:proc, consolePrintWordHex:proc
extern consolePrintString:proc
extern ConsoleCursorColRow:word
endif

CONSOLE_NEXT_LINE macro
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
endm

; Input: aChar, moved to dl (unsigned byte).
CONSOLE_PRINT_CHAR macro aChar:req
local updateCursorPos, incrementCursorRow
    push bx
    push cx
ifdifi <aChar>, <al>
    ; Char to print.
    mov al,aChar
endif
    cmp al,ASCII_CR
    jne short @f
    ; Read current cursor pos.
    mov dx,[ConsoleCursorColRow]
    ; Reset col.
    xor dl,dl
    jmp short updateCursorPos
@@:
    cmp al,ASCII_LF
    jne short @f
    ; Read current cursor pos.
    mov dx,[ConsoleCursorColRow]
    jmp short incrementCursorRow
@@:
    ; LSB: color 3, MSB: page number 0.
    mov bx,0003h
    ; Numbers of times the char should be printed.
    mov cx,1
    mov ah,BIOS_VIDEO_FUNC_SET_CHAR_AT_CURSOR_POS
    int BIOS_VIDEO_INT

    ; Read current cursor pos.
    mov dx,[ConsoleCursorColRow]
    ; Increment col.
    inc dl
    cmp dl,CONSOLE_COLS
    jb updateCursorPos
    ; Reset col.
    xor dl,dl
incrementCursorRow:    
    ; Increment row.
    inc dh
    cmp dh,CONSOLE_ROWS
    jb updateCursorPos
    ; Reset row.
    xor dh,dh
updateCursorPos:
    CONSOLE_SET_CURSOR_POS_IN_DX
    pop cx
    pop bx
endm

; Input: aCol (X coord - unsigned byte), aRow (Y coord - unsigned byte).
CONSOLE_SET_CURSOR_POS macro aCol:req, aRow:req
    mov dx,aCol + (aRow * 256)
    CONSOLE_SET_CURSOR_POS_IN_DX
endm

CONSOLE_SET_CURSOR_POS_IN_DX macro
    mov [ConsoleCursorColRow],dx
    ;; Use page number 0.
    xor bh,bh
    mov ah,BIOS_VIDEO_FUNC_SET_CURSOR_POS
    int BIOS_VIDEO_INT
endm
