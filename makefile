DEFINE_TEXT = DEBUG
#DEFINE_TEXT = RELEASE
INCLUDE_FOLDER = .
ML_OPTIONS = /AT /c /Cp /D$(DEFINE_TEXT) /I$(INCLUDE_FOLDER) /nologo /Sc /W3 /WX /X
TMP_FOLDER = obj
OUTPUT_FOLDER = bin
EXECUTABLE_NAME = invdrs
EXECUTABLE_EXT = com

$(OUTPUT_FOLDER)\$(EXECUTABLE_NAME).$(EXECUTABLE_EXT) : $(TMP_FOLDER)\game.obj $(TMP_FOLDER)\assert.obj $(TMP_FOLDER)\console.obj $(TMP_FOLDER)\keyboard.obj $(TMP_FOLDER)\level.obj $(TMP_FOLDER)\player.obj $(TMP_FOLDER)\render.obj $(TMP_FOLDER)\test1.obj $(TMP_FOLDER)\test2.obj $(TMP_FOLDER)\test3.obj $(TMP_FOLDER)\test4.obj $(TMP_FOLDER)\test5.obj $(TMP_FOLDER)\tetris.obj $(TMP_FOLDER)\timer.obj
	link /NOLOGO /TINY @<<inout.lnk
$**, $@;
<<

code\assert.inc : code\errcode.inc
code\console.inc : code\ascii.inc
code\keyboard.inc : code\assert.inc
code\render.inc : code\bios.inc

obj\assert.obj : code\assert.asm code\assert.inc code\game.inc
	ml $(ML_OPTIONS) /Fo"$(TMP_FOLDER)\assert.obj" /Fl"$(TMP_FOLDER)\assert.lst" code\assert.asm

obj\console.obj : code\console.asm code\console.inc code\assert.inc code\bios.inc
	ml $(ML_OPTIONS) /Fo"$(TMP_FOLDER)\console.obj" /Fl"$(TMP_FOLDER)\console.lst" code\console.asm

obj\game.obj : code\game.asm code\game.inc code\console.inc code\dos.inc code\errcode.inc code\keyboard.inc code\level.inc code\render.inc code\test1.inc code\test2.inc code\test3.inc code\test4.inc
	ml $(ML_OPTIONS) /Fo"$(TMP_FOLDER)\game.obj" /Fl"$(TMP_FOLDER)\game.lst" code\game.asm

obj\keyboard.obj : code\keyboard.asm code\keyboard.inc code\bios.inc
	ml $(ML_OPTIONS) /Fo"$(TMP_FOLDER)\keyboard.obj" /Fl"$(TMP_FOLDER)\keyboard.lst" code\keyboard.asm

obj\level.obj : code\level.asm code\level.inc code\bios.inc code\player.inc code\render.inc
	ml $(ML_OPTIONS) /Fo"$(TMP_FOLDER)\level.obj" /Fl"$(TMP_FOLDER)\level.lst" code\level.asm

obj\player.obj : code\player.asm code\player.inc code\console.inc code\keyboard.inc code\render.inc
	ml $(ML_OPTIONS) /Fo"$(TMP_FOLDER)\player.obj" /Fl"$(TMP_FOLDER)\player.lst" code\player.asm

obj\render.obj : code\render.asm code\render.inc code\assert.inc code\bios.inc
	ml $(ML_OPTIONS) /Fo"$(TMP_FOLDER)\render.obj" /Fl"$(TMP_FOLDER)\render.lst" code\render.asm

obj\test1.obj : code\test1.asm code\test1.inc code\assert.inc code\assumSeg.inc code\console.inc code\keyboard.inc code\render.inc
	ml $(ML_OPTIONS) /Fo"$(TMP_FOLDER)\test1.obj" /Fl"$(TMP_FOLDER)\test1.lst" code\test1.asm

obj\test2.obj : code\test2.asm code\test2.inc code\assert.inc code\assumSeg.inc code\console.inc code\keyboard.inc code\render.inc code\timer.inc
	ml $(ML_OPTIONS) /Fo"$(TMP_FOLDER)\test2.obj" /Fl"$(TMP_FOLDER)\test2.lst" code\test2.asm

obj\test3.obj : code\test3.asm code\test3.inc code\assert.inc code\assumSeg.inc code\console.inc code\keyboard.inc code\render.inc
	ml $(ML_OPTIONS) /Fo"$(TMP_FOLDER)\test3.obj" /Fl"$(TMP_FOLDER)\test3.lst" code\test3.asm

obj\test4.obj : code\test4.asm code\test4.inc code\assert.inc code\assumSeg.inc code\console.inc code\keyboard.inc code\render.inc code\timer.inc
	ml $(ML_OPTIONS) /Fo"$(TMP_FOLDER)\test4.obj" /Fl"$(TMP_FOLDER)\test4.lst" code\test4.asm

obj\test5.obj : code\test5.asm code\test5.inc code\assert.inc code\assumSeg.inc code\console.inc
	ml $(ML_OPTIONS) /Fo"$(TMP_FOLDER)\test5.obj" /Fl"$(TMP_FOLDER)\test5.lst" code\test5.asm

obj\tetris.obj : code\tetris.asm code\tetris.inc code\assert.inc code\assumSeg.inc code\console.inc code\keyboard.inc code\render.inc code\timer.inc
	ml $(ML_OPTIONS) /Fo"$(TMP_FOLDER)\tetris.obj" /Fl"$(TMP_FOLDER)\tetris.lst" code\tetris.asm

obj\timer.obj : code\timer.asm code\timer.inc code\assumSeg.inc code\bios.inc
	ml $(ML_OPTIONS) /Fo"$(TMP_FOLDER)\timer.obj" /Fl"$(TMP_FOLDER)\timer.lst" code\timer.asm

clean :
	-del $(OUTPUT_FOLDER)\$(EXECUTABLE_NAME).$(EXECUTABLE_EXT)
	-del $(TMP_FOLDER)\*.lst
	-del $(TMP_FOLDER)\*.obj

debug :
	debug $(OUTPUT_FOLDER)\$(EXECUTABLE_NAME).$(EXECUTABLE_EXT)

run :
	$(OUTPUT_FOLDER)\$(EXECUTABLE_NAME).$(EXECUTABLE_EXT)