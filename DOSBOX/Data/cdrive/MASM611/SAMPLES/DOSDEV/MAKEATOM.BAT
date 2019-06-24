REM Batch file for making ATOMS.SYS, ATOMTEST.EXE, CTEST.EXE

ml -FeATOMS.SYS atoms.asm
ml -Zi atomtest.asm
cl -Zi ctest.c

