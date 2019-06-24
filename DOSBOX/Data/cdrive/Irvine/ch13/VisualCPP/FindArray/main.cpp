// main.cpp - Testing the FindArray subroutine.
#include <stdlib.h>
#include <iostream.h>
#include "findarr.h"

int main()
{
  const unsigned ARRAY_SIZE = 10000; 
  long array[ARRAY_SIZE];
  
// Fill the array with pseudorandom integers.
  for(unsigned i = 0; i < ARRAY_SIZE; i++)
     array[i] = rand();
  
  long searchVal;
  cout << "Enter an integer to find [0 to "
       << RAND_MAX << ": ";
  cin >> searchVal;

  if( FindArray2( searchVal, array, ARRAY_SIZE ))
    cout << "Your number was found.\n";
  else
    cout << "Your number was not found.\n";

// Call FindArray2 for the CPP version.

 return 0;
}