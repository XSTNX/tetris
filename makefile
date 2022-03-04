DEFINE_TEXT = DEBUG
#DEFINE_TEXT = RELEASE
INCLUDE_FOLDER = .
EXECUTABLE_NAME = invdrs
ML_OPTIONS = /AT /c /Cp /D$(DEFINE_TEXT) /I$(INCLUDE_FOLDER) /nologo /Sc /W3 /WX /X
LINK_OPTIONS = /NOLOGO /TINY
# Keep game.obj first, since a com file is created.
OBJ_FILES = obj\game.obj obj\console.obj obj\keyboard.obj obj\level.obj obj\player.obj obj\render.obj obj\test.obj obj\test2.obj obj\test3.obj

all : bin\$(EXECUTABLE_NAME).com

bin\$(EXECUTABLE_NAME).com : $(OBJ_FILES)
	link $(LINK_OPTIONS) @<<inout.lnk
$(OBJ_FILES), bin\$(EXECUTABLE_NAME).com;
<<

code\console.inc : code\ascii.inc code\bios.inc code\dos.inc
code\game.inc : code\errcode.inc
code\keyboard.inc : code\game.inc
code\render.inc : code\bios.inc

obj\console.obj : code\console.asm code\console.inc
	ml $(ML_OPTIONS) /Fo"obj\console.obj" /Fl"obj\console.lst" code\console.asm

obj\game.obj : code\game.asm code\game.inc code\console.inc code\keyboard.inc code\level.inc code\render.inc code\test.inc code\test2.inc code\test3.inc
	ml $(ML_OPTIONS) /Fo"obj\game.obj" /Fl"obj\game.lst" code\game.asm

obj\keyboard.obj : code\keyboard.asm code\keyboard.inc code\bios.inc
	ml $(ML_OPTIONS) /Fo"obj\keyboard.obj" /Fl"obj\keyboard.lst" code\keyboard.asm

obj\level.obj : code\level.asm code\level.inc code\bios.inc code\player.inc code\render.inc
	ml $(ML_OPTIONS) /Fo"obj\level.obj" /Fl"obj\level.lst" code\level.asm

obj\player.obj : code\player.asm code\player.inc code\console.inc code\keyboard.inc code\render.inc
	ml $(ML_OPTIONS) /Fo"obj\player.obj" /Fl"obj\player.lst" code\player.asm

obj\render.obj : code\render.asm code\render.inc code\bios.inc
	ml $(ML_OPTIONS) /Fo"obj\render.obj" /Fl"obj\render.lst" code\render.asm

obj\test.obj : code\test.asm code\test.inc code\console.inc code\keyboard.inc code\render.inc
	ml $(ML_OPTIONS) /Fo"obj\test.obj" /Fl"obj\test.lst" code\test.asm

obj\test2.obj : code\test2.asm code\test2.inc code\assumSeg.inc code\game.inc code\render.inc
	ml $(ML_OPTIONS) /Fo"obj\test2.obj" /Fl"obj\test2.lst" code\test2.asm

obj\test3.obj : code\test3.asm code\test3.inc code\assumSeg.inc code\render.inc
	ml $(ML_OPTIONS) /Fo"obj\test3.obj" /Fl"obj\test3.lst" code\test3.asm

clean :
	-del bin\*.com
	-del obj\*.lst
	-del obj\*.obj