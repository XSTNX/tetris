DEBUG_FLAG = 1
INCLUDE_FOLDER = .
ML_OPTIONS = /AT /c /DDEBUG=$(DEBUG_FLAG) /I $(INCLUDE_FOLDER) /W3 /X
LINK_OPTIONS = /tiny

all : bin\invdrs.com

bin\invdrs.com : obj\game.obj obj\console.obj obj\keyboard.obj obj\level.obj obj\render.obj obj\test.obj
	link $(LINK_OPTIONS) obj\game.obj obj\console.obj obj\keyboard.obj obj\level.obj obj\render.obj obj\test.obj, bin\invdrs.com;

code\console.inc : code\ascii.inc code\bios.inc code\dos.inc

obj\console.obj : code\console.asm code\console.inc
	ml $(ML_OPTIONS) /Fo obj\console.obj code\console.asm

obj\game.obj : code\game.asm code\console.inc code\errcode.inc code\keyboard.inc
	ml $(ML_OPTIONS) /Fo obj\game.obj code\game.asm

obj\keyboard.obj : code\keyboard.asm code\bios.inc code\dos.inc code\errcode.inc
	ml $(ML_OPTIONS) /Fo obj\keyboard.obj code\keyboard.asm

obj\level.obj : code\level.asm code\console.inc code\keyboard.inc
	ml $(ML_OPTIONS) /Fo obj\level.obj code\level.asm

obj\render.obj : code\render.asm code\bios.inc
	ml $(ML_OPTIONS) /Fo obj\render.obj code\render.asm

obj\test.obj : code\test.asm code\console.inc code\keyboard.inc
	ml $(ML_OPTIONS) /Fo obj\test.obj code\test.asm

clean :
	-del bin\*.com
	-del obj\*.obj