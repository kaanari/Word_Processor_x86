C     Calls Power2 in FORTRAN.ASM
C     Compile with:  FL FMAIN.FOR FORTRAN.OBJ

      INTERFACE TO INTEGER*2 FUNCTION POWER2(A, B)
      INTEGER*2 A, B
      END

      PROGRAM MAIN
      INTEGER*2 POWER2
      INTEGER*2 A, B
      A = 3
      B  = 5
      WRITE (*, *) '3 TIMES 2 TO THE B OR 5 IS ',POWER2(A, B)
      END
