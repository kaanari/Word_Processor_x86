/*** MAIN.C - A test driver for a sample NT application
*
* Copyright (C) 1992 Microsoft Corporation
*
* usage : main [substring in pBuf below]
*       : main is
*
*************************************************************************/

char * _stdcall szSearch(char * pBuf,int cbBuf,char *szTok);
int      puts(char *);
int      strlen(char *);

char * pBuf = "This is sample text to test our search algorithm with. Have fun with this";

int main (
int     argc,
char  **argv
)
{
	char * pFound;
	while(argc--) {
		if (pFound = szSearch(pBuf,strlen(pBuf),argv[argc])) {
			puts(pFound);
		}
	}
	return(0);
}


