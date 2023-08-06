DEFINE_TEXT = DEBUG
#DEFINE_TEXT = RELEASE
INCLUDE_FOLDER = .
ML_OPTIONS = /AT /c /Cp /D$(DEFINE_TEXT) /I$(INCLUDE_FOLDER) /nologo /Sc /W3 /WX /X

bin\invdrs.com : obj\game.obj obj\assert.obj obj\console.obj obj\keyboard.obj obj\level.obj obj\player.obj obj\render.obj obj\test.obj obj\test2.obj obj\test3.obj obj\test4.obj obj\test5.obj obj\tetris.obj obj\timer.obj
	link /NOLOGO /TINY @<<inout.lnk
$**, $@;
<<

code\assert.inc : code\errcode.inc
code\console.inc : code\ascii.inc
code\keyboard.inc : code\assert.inc
code\render.inc : code\bios.inc

obj\assert.obj : code\assert.asm code\assert.inc code\game.inc
	ml $(ML_OPTIONS) /Fo"obj\assert.obj" /Fl"obj\assert.lst" code\assert.asm

obj\console.obj : code\console.asm code\console.inc code\assert.inc code\bios.inc
	ml $(ML_OPTIONS) /Fo"obj\console.obj" /Fl"obj\console.lst" code\console.asm

obj\game.obj : code\game.asm code\game.inc code\console.inc code\dos.inc code\errcode.inc code\keyboard.inc code\level.inc code\render.inc code\test.inc code\test2.inc code\test3.inc code\test4.inc
	ml $(ML_OPTIONS) /Fo"obj\game.obj" /Fl"obj\game.lst" code\game.asm

obj\keyboard.obj : code\keyboard.asm code\keyboard.inc code\bios.inc
	ml $(ML_OPTIONS) /Fo"obj\keyboard.obj" /Fl"obj\keyboard.lst" code\keyboard.asm

obj\level.obj : code\level.asm code\level.inc code\bios.inc code\player.inc code\render.inc
	ml $(ML_OPTIONS) /Fo"obj\level.obj" /Fl"obj\level.lst" code\level.asm

obj\player.obj : code\player.asm code\player.inc code\console.inc code\keyboard.inc code\render.inc
	ml $(ML_OPTIONS) /Fo"obj\player.obj" /Fl"obj\player.lst" code\player.asm

obj\render.obj : code\render.asm code\render.inc code\assert.inc code\bios.inc
	ml $(ML_OPTIONS) /Fo"obj\render.obj" /Fl"obj\render.lst" code\render.asm

obj\test.obj : code\test.asm code\test.inc code\assert.inc code\assumSeg.inc code\console.inc code\keyboard.inc code\render.inc
	ml $(ML_OPTIONS) /Fo"obj\test.obj" /Fl"obj\test.lst" code\test.asm

obj\test2.obj : code\test2.asm code\test2.inc code\assert.inc code\assumSeg.inc code\console.inc code\keyboard.inc code\render.inc code\timer.inc
	ml $(ML_OPTIONS) /Fo"obj\test2.obj" /Fl"obj\test2.lst" code\test2.asm

obj\test3.obj : code\test3.asm code\test3.inc code\assert.inc code\assumSeg.inc code\console.inc code\keyboard.inc code\render.inc
	ml $(ML_OPTIONS) /Fo"obj\test3.obj" /Fl"obj\test3.lst" code\test3.asm

obj\test4.obj : code\test4.asm code\test4.inc code\assert.inc code\assumSeg.inc code\console.inc code\keyboard.inc code\render.inc code\timer.inc
	ml $(ML_OPTIONS) /Fo"obj\test4.obj" /Fl"obj\test4.lst" code\test4.asm

obj\test5.obj : code\test5.asm code\test5.inc code\assert.inc code\assumSeg.inc code\console.inc
	ml $(ML_OPTIONS) /Fo"obj\test5.obj" /Fl"obj\test5.lst" code\test5.asm

obj\tetris.obj : code\tetris.asm code\tetris.inc code\assert.inc code\assumSeg.inc code\console.inc code\keyboard.inc code\render.inc code\timer.inc
	ml $(ML_OPTIONS) /Fo"obj\tetris.obj" /Fl"obj\tetris.lst" code\tetris.asm

obj\timer.obj : code\timer.asm code\timer.inc code\assumSeg.inc code\bios.inc
	ml $(ML_OPTIONS) /Fo"obj\timer.obj" /Fl"obj\timer.lst" code\timer.asm

clean :
	-del bin\*.com
	-del obj\*.lst
	-del obj\*.obj

run :
	bin\invdrs.com