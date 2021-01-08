INCLUDE_FOLDER = .
ML_FLAGS = /AT /c /I $(INCLUDE_FOLDER) /W3 /X
LINK_FLAGS = /tiny

all : bin\invdrs.com

bin\invdrs.com : obj\game.obj obj\console.obj obj\level.obj obj\render.obj
	link $(LINK_FLAGS) obj\game.obj obj\console.obj obj\level.obj obj\render.obj, bin\invdrs.com;

code\console.inc : code\ascii.inc code\bios.inc code\dos.inc	

obj\console.obj : code\console.asm code\console.inc
	ml $(ML_FLAGS) /Fo obj\console.obj code\console.asm

obj\game.obj : code\game.asm code\console.inc
	ml $(ML_FLAGS) /Fo obj\game.obj code\game.asm

obj\level.obj : code\level.asm code\console.inc
	ml $(ML_FLAGS) /Fo obj\level.obj code\level.asm

obj\render.obj : code\render.asm
	ml $(ML_FLAGS) /Fo obj\render.obj code\render.asm

clean :
	-del bin\*.com
	-del obj\*.obj