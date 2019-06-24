// test1.cpp - Test Inline Operators

#pragma warning

int main()
{
struct Package {
  long originZip;        // 4
  long destinationZip;   // 4
  float shippingPrice;   // 4
};
  
   char myChar;
   bool myBool;
   short myShort;
   int  myInt;
   long myLong;
   float myFloat;
   double myDouble;
   Package myPackage;
   long double myLongDouble;
   long myLongArray[10];
__asm {

   mov  eax,length myInt;         // 1
   mov  eax,length myLongArray;   // 10

   mov  eax,type myChar;        // 1
   mov  eax,type myBool;        // 1
   mov  eax,type myShort;       // 2
   mov  eax,type myInt;         // 4
   mov  eax,type myLong;        // 4
   mov  eax,type myFloat;       // 4
   mov  eax,type myDouble;      // 8
   mov  eax,type myPackage;     // 12
   mov  eax,type myLongDouble;  // 8
   mov  eax,type myLongArray;   // 4

   mov  eax,size myLong;        // 4
   mov  eax,size myPackage;     // 12
   mov  eax,size myLongArray;   // 40
}

  return 0;
}