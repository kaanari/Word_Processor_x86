/*------------------------------------------------------------------------

 C main that calls asm dll 
 
 Passes: char, short, int, long using stdcall calling and naming convention.

 Returns: number of failures.

--------------------------------------------------------------------------*/




#include <stdio.h>
#include <windows.h>

BOOL __stdcall VSIntTest( char int1, int int2, short int3, long int4 );

BOOL __stdcall RSIntTest( char *int1, int *int2, short *int3, long *int4 );


const bNegMax = -128;
const iNegOne = -1;
const suMax   = 32767;
const lNegMax = -2147483647 - 1;   


int main( void ) 
{ 

  char bVal1 = bNegMax;
  int iVal2 = iNegOne;
  short iVal3 = suMax;
  long lVal4 = lNegMax;

  int cErrors = 0;                // count of errors/failed tests


/* Call a function in the DLL passing various params by value.
   Since the params were passed by value, the original value passed
   shouldn't have changed, generate an error if they were. */

  
  if (!VSIntTest(bVal1, iVal2, iVal3, lVal4)) {
    printf("Failed: Passing signed integers by value, stdcall, to MASM DLL.\n");
	cErrors++;
  }
  else {
    if (!( (bVal1 == bNegMax) && (iVal2 == iNegOne) && (iVal3 == suMax) && (lVal4 == lNegMax) )) {
      printf("Stack corruption: signed integers by value, stdcall, to MASM DLL.\n");
	  cErrors++;
	}
    else {
      printf("Passed: Passing signed integers by value, stdcall, to MASM DLL.\n");
	}
  }



/* Call another function in the DLL passing various params by reference.
   Since the params were passed by reference, generate an error if they 
   were not changed to the desired values within the DLL. */


  if (!RSIntTest(&bVal1, &iVal2, &iVal3, &lVal4)) {
    printf("Failed: Passing signed integers by reference, stdcall, to MASM DLL.\n");
	cErrors++;
  }
  else {
    if (!( (bVal1 == 1) && (iVal2 == 1) && (iVal3 == 1) && (lVal4 == 1) )) {
      printf("Stack corruption: signed integers by reference, stdcall, to MASM DLL.\n");
	  cErrors++;
	}
    else 
      printf("Passed: Passing signed integers by reference, stdcall, to MASM DLL.\n");
  }
  

  return cErrors;  // return a count of errors.

}
