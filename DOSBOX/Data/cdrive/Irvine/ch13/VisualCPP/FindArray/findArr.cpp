// findArr.cpp


#include "findarr.h"

bool FindArray2( long searchVal, long array[], 
     long count )
{
  for(int i = 0; i < count; i++)
    if( searchVal == array[i] )
      return true;

  return false;
}
