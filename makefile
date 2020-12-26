ML_FLAGS = /AT /c /W3
LINK_FLAGS = /tiny

all : bin\invdrs.com

bin\invdrs.com : obj\game.obj
	link $(LINK_FLAGS) obj\game.obj, bin\invdrs.com;

obj\game.obj : code\game.asm
	ml $(ML_FLAGS) /Fo obj\game.obj code\game.asm

clean :
	-del bin\*.com
	-del obj\*.obj