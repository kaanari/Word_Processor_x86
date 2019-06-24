// ENCODE2.CPP

#include <iostream.h>
#include <fstream.h>

// Translate a buffer of <count> bytes, using an encryption
// character <eChar>. Uses an XOR operation (ASM function).

const int BUFSIZE = 200;
char buffer[BUFSIZE];

int main() 
{  
  unsigned count;    // character count
 
  unsigned short encryptCode;
  cout << "Encryption code [0-255]? ";
  cin >> encryptCode;
  unsigned char encryptChar = (unsigned char) encryptCode;
  
  ifstream infile( "infile.txt", ios::binary );
  ofstream outfile( "outfile.txt", ios::binary );
  
  while (!infile.eof() )
  {
    infile.read(buffer, BUFSIZE );
    count = infile.gcount();

    __asm {
       lea esi,buffer
       mov ecx,count
       mov al, encryptChar
    L1:
       xor [esi],al
       inc  esi
       Loop L1
   } // asm
    
    outfile.write(buffer, count);
  }

  return 0;
}
