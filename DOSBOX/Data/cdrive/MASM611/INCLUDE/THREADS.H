
#define GREEN    0x00007F10
#define RED      0x0000007F


LONG APIENTRY MainWndProc (HWND, UINT, UINT, LONG);
VOID ThreadProc (LPVOID *);

extern VOID cdecl AsmThreadProc( LPVOID *Color );


HANDLE hInst;
HANDLE hWind;
extern HANDLE hWind;

