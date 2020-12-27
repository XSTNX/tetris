INCLUDE_FOLDER = .
ML_FLAGS = /AT /c /I $(INCLUDE_FOLDER) /W3 /X
LINK_FLAGS = /tiny

all : bin\invdrs.com

bin\invdrs.com : obj\game.obj obj\console.obj
	link $(LINK_FLAGS) obj\game.obj obj\console.obj, bin\invdrs.com;

obj\game.obj : code\game.asm code\bios.inc code\console.inc
	ml $(ML_FLAGS) /Fo obj\game.obj code\game.asm

obj\console.obj : code\console.asm code\console.inc
	ml $(ML_FLAGS) /Fo obj\console.obj code\console.asm

code\console.inc : code\ascii.inc code\dos.inc

clean :
	-del bin\*.com
	-del obj\*.obj