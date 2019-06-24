/* Power2 procedure is in C.ASM  */
/* Compile with CL cmain.c c.obj */

#include <stdio.h>

extern int Power2( int factor, int power );

void main()
{
    printf( "3 times 2 to the power of 5 is %d\n", Power2( 3, 5 ) );
}
