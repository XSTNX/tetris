DEFINE_TEXT = DEBUG
#DEFINE_TEXT = RELEASE
INCLUDE_FOLDER = .
EXECUTABLE_NAME = invdrs
ML_OPTIONS = /AT /c /Cp /D$(DEFINE_TEXT) /I$(INCLUDE_FOLDER) /nologo /Sc /W3 /WX /X
LINK_OPTIONS = /NOLOGO /TINY

all : bin\$(EXECUTABLE_NAME).com

bin\$(EXECUTABLE_NAME).com : obj\game.obj obj\console.obj obj\keyboard.obj obj\level.obj obj\render.obj obj\test.obj
	link $(LINK_OPTIONS) obj\game.obj obj\console.obj obj\keyboard.obj obj\level.obj obj\render.obj obj\test.obj, bin\$(EXECUTABLE_NAME).com;

code\console.inc : code\ascii.inc code\bios.inc code\dos.inc

obj\console.obj : code\console.asm code\console.inc
	ml $(ML_OPTIONS) /Fo"obj\console.obj" /Fl"obj\console.lst" code\console.asm

obj\game.obj : code\game.asm code\console.inc code\errcode.inc code\keyboard.inc
	ml $(ML_OPTIONS) /Fo"obj\game.obj" /Fl"obj\game.lst" code\game.asm

obj\keyboard.obj : code\keyboard.asm code\bios.inc code\dos.inc code\errcode.inc
	ml $(ML_OPTIONS) /Fo"obj\keyboard.obj" /Fl"obj\keyboard.lst" code\keyboard.asm

obj\level.obj : code\level.asm code\console.inc code\keyboard.inc
	ml $(ML_OPTIONS) /Fo"obj\level.obj" /Fl"obj\level.lst" code\level.asm

obj\render.obj : code\render.asm code\bios.inc
	ml $(ML_OPTIONS) /Fo"obj\render.obj" /Fl"obj\render.lst" code\render.asm

obj\test.obj : code\test.asm code\console.inc code\keyboard.inc
	ml $(ML_OPTIONS) /Fo"obj\test.obj" /Fl"obj\test.lst" code\test.asm

clean :
	-del bin\*.com
	-del obj\*.lst
	-del obj\*.obj