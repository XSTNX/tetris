DEFINE_TEXT = DEBUG
#DEFINE_TEXT = RELEASE
INCLUDE_FOLDER = .
ML_OPTIONS = /AT /c /Cp /D$(DEFINE_TEXT) /I$(INCLUDE_FOLDER) /nologo /Sc /W3 /WX /X
SRC_FOLDER = code
TMP_FOLDER = obj
OUTPUT_FOLDER = bin
EXECUTABLE_NAME = invdrs
EXECUTABLE_EXT = com

$(OUTPUT_FOLDER)\$(EXECUTABLE_NAME).$(EXECUTABLE_EXT) : $(TMP_FOLDER)\game.obj $(TMP_FOLDER)\assert.obj $(TMP_FOLDER)\console.obj $(TMP_FOLDER)\keyboard.obj $(TMP_FOLDER)\level.obj $(TMP_FOLDER)\player.obj $(TMP_FOLDER)\render.obj $(TMP_FOLDER)\test1.obj $(TMP_FOLDER)\test2.obj $(TMP_FOLDER)\test3.obj $(TMP_FOLDER)\test4.obj $(TMP_FOLDER)\test5.obj $(TMP_FOLDER)\tetris.obj $(TMP_FOLDER)\timer.obj
	link /NOLOGO /TINY @<<inout.lnk
$**, $@;
<<

$(SRC_FOLDER)\assert.inc : $(SRC_FOLDER)\errcode.inc
$(SRC_FOLDER)\console.inc : $(SRC_FOLDER)\ascii.inc
$(SRC_FOLDER)\keyboard.inc : $(SRC_FOLDER)\assert.inc
$(SRC_FOLDER)\render.inc : $(SRC_FOLDER)\bios.inc

$(TMP_FOLDER)\assert.obj : $(SRC_FOLDER)\assert.asm $(SRC_FOLDER)\assert.inc $(SRC_FOLDER)\game.inc
	ml $(ML_OPTIONS) /Fo"$@" /Fl"$*.lst" $(SRC_FOLDER)\$(*B).asm

$(TMP_FOLDER)\console.obj : $(SRC_FOLDER)\console.asm $(SRC_FOLDER)\console.inc $(SRC_FOLDER)\assert.inc $(SRC_FOLDER)\bios.inc
	ml $(ML_OPTIONS) /Fo"$@" /Fl"$*.lst" $(SRC_FOLDER)\$(*B).asm

$(TMP_FOLDER)\game.obj : $(SRC_FOLDER)\game.asm $(SRC_FOLDER)\game.inc $(SRC_FOLDER)\console.inc $(SRC_FOLDER)\dos.inc $(SRC_FOLDER)\errcode.inc $(SRC_FOLDER)\keyboard.inc $(SRC_FOLDER)\level.inc $(SRC_FOLDER)\render.inc $(SRC_FOLDER)\test1.inc $(SRC_FOLDER)\test2.inc $(SRC_FOLDER)\test3.inc $(SRC_FOLDER)\test4.inc $(SRC_FOLDER)\test5.inc
	ml $(ML_OPTIONS) /Fo"$@" /Fl"$*.lst" $(SRC_FOLDER)\$(*B).asm

$(TMP_FOLDER)\keyboard.obj : $(SRC_FOLDER)\keyboard.asm $(SRC_FOLDER)\keyboard.inc $(SRC_FOLDER)\bios.inc
	ml $(ML_OPTIONS) /Fo"$@" /Fl"$*.lst" $(SRC_FOLDER)\$(*B).asm

$(TMP_FOLDER)\level.obj : $(SRC_FOLDER)\level.asm $(SRC_FOLDER)\level.inc $(SRC_FOLDER)\bios.inc $(SRC_FOLDER)\player.inc $(SRC_FOLDER)\render.inc
	ml $(ML_OPTIONS) /Fo"$@" /Fl"$*.lst" $(SRC_FOLDER)\$(*B).asm

$(TMP_FOLDER)\player.obj : $(SRC_FOLDER)\player.asm $(SRC_FOLDER)\player.inc $(SRC_FOLDER)\console.inc $(SRC_FOLDER)\keyboard.inc $(SRC_FOLDER)\render.inc
	ml $(ML_OPTIONS) /Fo"$@" /Fl"$*.lst" $(SRC_FOLDER)\$(*B).asm

$(TMP_FOLDER)\render.obj : $(SRC_FOLDER)\render.asm $(SRC_FOLDER)\render.inc $(SRC_FOLDER)\assert.inc $(SRC_FOLDER)\bios.inc
	ml $(ML_OPTIONS) /Fo"$@" /Fl"$*.lst" $(SRC_FOLDER)\$(*B).asm

$(TMP_FOLDER)\test1.obj : $(SRC_FOLDER)\test1.asm $(SRC_FOLDER)\test1.inc $(SRC_FOLDER)\assert.inc $(SRC_FOLDER)\assumSeg.inc $(SRC_FOLDER)\console.inc $(SRC_FOLDER)\keyboard.inc $(SRC_FOLDER)\render.inc
	ml $(ML_OPTIONS) /Fo"$@" /Fl"$*.lst" $(SRC_FOLDER)\$(*B).asm

$(TMP_FOLDER)\test2.obj : $(SRC_FOLDER)\test2.asm $(SRC_FOLDER)\test2.inc $(SRC_FOLDER)\assert.inc $(SRC_FOLDER)\assumSeg.inc $(SRC_FOLDER)\console.inc $(SRC_FOLDER)\keyboard.inc $(SRC_FOLDER)\render.inc $(SRC_FOLDER)\timer.inc
	ml $(ML_OPTIONS) /Fo"$@" /Fl"$*.lst" $(SRC_FOLDER)\$(*B).asm

$(TMP_FOLDER)\test3.obj : $(SRC_FOLDER)\test3.asm $(SRC_FOLDER)\test3.inc $(SRC_FOLDER)\assert.inc $(SRC_FOLDER)\assumSeg.inc $(SRC_FOLDER)\console.inc $(SRC_FOLDER)\keyboard.inc $(SRC_FOLDER)\render.inc
	ml $(ML_OPTIONS) /Fo"$@" /Fl"$*.lst" $(SRC_FOLDER)\$(*B).asm

$(TMP_FOLDER)\test4.obj : $(SRC_FOLDER)\test4.asm $(SRC_FOLDER)\test4.inc $(SRC_FOLDER)\assert.inc $(SRC_FOLDER)\assumSeg.inc $(SRC_FOLDER)\console.inc $(SRC_FOLDER)\keyboard.inc $(SRC_FOLDER)\render.inc $(SRC_FOLDER)\timer.inc
	ml $(ML_OPTIONS) /Fo"$@" /Fl"$*.lst" $(SRC_FOLDER)\$(*B).asm

$(TMP_FOLDER)\test5.obj : $(SRC_FOLDER)\test5.asm $(SRC_FOLDER)\test5.inc $(SRC_FOLDER)\assert.inc $(SRC_FOLDER)\assumSeg.inc $(SRC_FOLDER)\console.inc
	ml $(ML_OPTIONS) /Fo"$@" /Fl"$*.lst" $(SRC_FOLDER)\$(*B).asm

$(TMP_FOLDER)\tetris.obj : $(SRC_FOLDER)\tetris.asm $(SRC_FOLDER)\tetris.inc $(SRC_FOLDER)\assert.inc $(SRC_FOLDER)\assumSeg.inc $(SRC_FOLDER)\console.inc $(SRC_FOLDER)\keyboard.inc $(SRC_FOLDER)\render.inc $(SRC_FOLDER)\timer.inc
	ml $(ML_OPTIONS) /Fo"$@" /Fl"$*.lst" $(SRC_FOLDER)\$(*B).asm

$(TMP_FOLDER)\timer.obj : $(SRC_FOLDER)\timer.asm $(SRC_FOLDER)\timer.inc $(SRC_FOLDER)\assumSeg.inc $(SRC_FOLDER)\bios.inc
	ml $(ML_OPTIONS) /Fo"$@" /Fl"$*.lst" $(SRC_FOLDER)\$(*B).asm

clean :
	-del $(OUTPUT_FOLDER)\$(EXECUTABLE_NAME).$(EXECUTABLE_EXT)
	-del $(TMP_FOLDER)\*.lst
	-del $(TMP_FOLDER)\*.obj

debug :
	debug $(OUTPUT_FOLDER)\$(EXECUTABLE_NAME).$(EXECUTABLE_EXT)

run :
	$(OUTPUT_FOLDER)\$(EXECUTABLE_NAME).$(EXECUTABLE_EXT)