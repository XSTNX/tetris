ML_FLAGS = /AT /c /W3
LINK_FLAGS = /tiny

all : bin\invdrs.com

bin\invdrs.com : obj\game.obj obj\console.obj
	link $(LINK_FLAGS) obj\game.obj obj\console.obj, bin\invdrs.com;

obj\game.obj : code\game.asm code\ascii.inc code\bios.inc code\dos.inc
	ml $(ML_FLAGS) /Fo obj\game.obj code\game.asm

obj\console.obj : code\console.asm code\dos.inc
	ml $(ML_FLAGS) /Fo obj\console.obj code\console.asm

clean :
	-del bin\*.com
	-del obj\*.obj