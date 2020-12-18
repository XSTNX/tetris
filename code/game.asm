codeData group code, data
    assume cs:codeData, ds:codeData

code segment public
	org 100h

main proc
	int 20h
main endp

code ends

data segment public
data ends

	end main
