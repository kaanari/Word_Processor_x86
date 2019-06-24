' Calls Power2 routine in BASIC.ASM
' Compile with BC BASMAIN.BAS BASIC.OBJ

DEFINT A-Z

DECLARE FUNCTION Power2 (A AS INTEGER, B AS INTEGER)
PRINT "3 times 2 to the power of 5 is ";
PRINT Power2(3, 5)


END
