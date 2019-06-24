/******************************************************************************\
*       This is a part of the Microsoft Source Code Samples.
*       Copyright (C) 1993 Microsoft Corporation.
*       All rights reserved.
*       This source code is only intended as a supplement to
*       Microsoft Development Tools.
*		Sample borrowed from Microsoft Visual C++ 1.00 for Microsoft Windows NT. 
\******************************************************************************/

/*************************************************************************\
*  PROGRAM: Threads.c
*
*  PURPOSE:
*
*     To demonstrate multi-threading.
*
*  FUNCTIONS:
*
*    WinMain()      - Initializes a window, and process the message loop.
*    MainWndProc()  - Process messages, launches server & client threads.
*    ThreadProc()   - Draws a rectangle to a window.
*	 AsmThreadProc()- Assembly procedure that draws a rectangle to a window.
*
*  COMMENTS:
*
*    To Use:
*      When starting this application, two threads are created.  The
*      first draws a green box, the second a red.  Both boxes are moved
*      about the screen as their individual threads calculate a new
*      position and redraws the box. 
*
*      Note through out the sample "red thread" or "green thread" are
*      referred to.  This simply indicates the thread which draws either the
*      red or green rectangle.
*
\*************************************************************************/


#include <windows.h>
#include <stdlib.h>
#include <time.h>
#include "threads.h"



/*************************************************************************\
*
*  FUNCTION: WinMain(HANDLE, HANDLE, LPSTR, int)
*
*  PURPOSE: calls initialization function, processes message loop
*
*  COMMENTS:
*
\*************************************************************************/
int APIENTRY WinMain (HANDLE hInstance,
                      HANDLE hPrevInstance,
                      LPSTR  lpCmdLine,
                      int    nCmdShow)
{
  MSG  msg;
  WNDCLASS wc;

  UNREFERENCED_PARAMETER( lpCmdLine );
  UNREFERENCED_PARAMETER( hPrevInstance );

  hInst = hInstance;

  wc.style = 0; 							// Replaces CS_SIZEREDRAW.
  wc.lpfnWndProc = (WNDPROC)MainWndProc;	// The client window procedure.
  wc.cbClsExtra = 0;                     	// No room reserved for extra data.
  wc.cbWndExtra = 0;
  wc.hInstance = hInstance;
  wc.hIcon = LoadIcon (NULL, IDI_ASTERISK);
  wc.hCursor = LoadCursor (NULL, IDC_ARROW);
  wc.hbrBackground = GetStockObject (BLACK_BRUSH);
  wc.lpszMenuName = NULL;
  wc.lpszClassName = "ThreadsWClass";

  RegisterClass(&wc);


  hWind = CreateWindow ("ThreadsWClass",
                       "2 Threads     Red = Asm, Green = C",
                       WS_OVERLAPPEDWINDOW,
                       CW_USEDEFAULT,
                       CW_USEDEFAULT,
                       CW_USEDEFAULT,
                       CW_USEDEFAULT,
                       NULL,
                       NULL,
                       hInstance,
                       NULL);


 


  ShowWindow(hWind, nCmdShow);
  while (GetMessage (&msg, NULL, 0, 0))
    DispatchMessage (&msg);   // Dispatch message to window.

  return (msg.wParam);           // Returns value from PostQuitMessage.

}

/*************************************************************************\
*
*  FUNCTION:  MainWndProc (hWind, UINT, UINT, LONG)
*
*  PURPOSE:   To process the windows messages. This procedure totally
*             controls the priority of the threads.
*
*  VARIABLES USED:
*
*    - hThread1,hThread2
*             Static handles to the two created threads.
*
*    - ThreadID1, ThreadID2
*             DWORDs used in the CreateThread call.
*
*    - pColor1, pColor2
*             DWORDs used to allocate some memory to use as a parameter
*             to pass color values to the threads.  This memory was
*             allocated so that the threads wouldn't have to rely on this
*             procedures stack for the values.
*
*    - Buf[80]:
*             Character buffer used to write messages to the user.
*
*
*  MESSAGES:
*
*    WM_DESTROY:     - Terminates the threads and post the quit message.
*    WM_CREATE:      - Allocates memory to hold some color values, and
*                      creates the two threads.
*    WM_COMMAND
*
*      
*
*  CALLED BY:
*
*    WinMain();
*
*  CALLS TO:
*
*    ThreadProc();
*	 AsmThreadProc();
*
*  COMMENTS:
*
*
\*************************************************************************/


LONG APIENTRY MainWndProc (HWND hWind,
                           UINT message,
                           UINT wParam,
                           LONG lParam)
{
  static HANDLE hThread1, hThread2;
  DWORD  ThreadID1, ThreadID2;
  CHAR Buf[80];    
  static DWORD *pColor1, *pColor2;

  switch (message)
      {

        case WM_CREATE :

        	pColor1 = malloc(sizeof(DWORD));
          	*pColor1 = GREEN;
          	hThread1 =	CreateThread (NULL, 0,
                       	(LPTHREAD_START_ROUTINE)ThreadProc,
					   	(LPVOID)pColor1, 0,
                       	(LPDWORD)&ThreadID1);

			if (!hThread1)
            	{
             	wsprintf(Buf, "Error in creating C Green thread: %d",
                	    GetLastError());
             	MessageBox (hWind, Buf, "WM_CREATE", MB_OK);
            	}
			else
				{
				SetThreadPriority (hThread1, THREAD_PRIORITY_NORMAL);
				}

          	Sleep (500);           // Allow some time/distance between the
                                   // thread boxes.

          	pColor2 = malloc(sizeof(DWORD));
          	*pColor2 = RED;
          	hThread2 = 	CreateThread (NULL, 0,
            		   	(LPTHREAD_START_ROUTINE)AsmThreadProc,
				   		(LPVOID)pColor2, 0,
                        (LPDWORD)&ThreadID2);

          if (!hThread2)
            {
             wsprintf(Buf, "Error in creating Asm thread: %d",
                      GetLastError());
             MessageBox (hWind, Buf, "WM_CREATE", MB_OK);
            }
		else		
			{
			SetThreadPriority (hThread2, THREAD_PRIORITY_NORMAL);
			}

		
        return (0);


        case WM_COMMAND:  
        	switch (LOWORD(wParam))
        		{      
          		return (0);
				}

        case WM_DESTROY :					// When the window is destroyed
            TerminateThread(hThread1, 0);	// terminate the threads
			TerminateThread(hThread2, 0);
            free (pColor1);					// Free allocated memory.
			free (pColor2);
            PostQuitMessage (0);			// End it.
            return (0);

       }
    return DefWindowProc (hWind, message, wParam, lParam);
}

/*************************************************************************\
*
*  FUNCTION:  ThreadProc (LPVOID)
*
*  PURPOSE:   A thread procedure which calculates position on the window
*             and draws a colored rectangle.  The color of the rectangle
*             is determined by the input parameter.
*
*  VARIABLES USED:
*
*    - horizontal, vertical:
*             Local int used to indicate the next directional move the
*             rectangle will make.
*
*    - ulx, uly:
*             Local DWORD used for the Upper Left X corner and Upper
*             Upper Left Y position of the rectangle.
*
*    - rect:  A RECT structure used to determin the current size of the
*             window (in case the user resizes it).
*
*    - hdc:   HDC of the rectangle.
*
*    - Time:  A SYSTEMTIME structure.  It's milli-second field is used
*             to create an apparent random starting point for the
*             rectangles.
*
*    -hBrush: A handle to a Brush object, used to set the color of the
*             rectangle.
*
*    -width, height:
*             Local DWORDs used for the width and height of the rectangles.
*
*  CALLED BY:
*
*    MainWndProc();
*
\*************************************************************************/


VOID ThreadProc ( LPVOID *Color)
{
  int  horizontal, vertical;
  DWORD ulx, uly;
  RECT rect;
  HDC  hDC;
  SYSTEMTIME Time;
  HANDLE hBrush;
  DWORD width, height;

  width =  20;
  height = 20;

  GetSystemTime (&Time);                     // Get the time.

  do{}while(!GetClientRect(hWind, &rect));    // Loop, making sure window
                                             // exists.

  ulx = (Time.wMilliseconds % rect.right);   // Use MOD to get a random
  uly = (Time.wMilliseconds % rect.bottom);  // position.

  if(Time.wMilliseconds % 2 == 0)            // Use MOD to pick random
    {                                        // directions.
     horizontal = 1;
     vertical = 1;
    }
  else
    {
     horizontal = 1;
     vertical = -1;
    }
                                             // Set color as per input
                                             // parameter.
  hBrush = CreateSolidBrush((COLORREF)*Color);

  do
    {                                        // do forever ...
     GetClientRect( hWind, &rect);

     if ( (ulx+width) > (DWORD)rect.right)   // ... check for right edge,
      {
      ulx = rect.right - width;
      horizontal = -1;                       //   ... if so change direction;
      }

     if ((uly+height) > (DWORD)rect.bottom)  // ... check for bottom edge,
      {
      uly = rect.bottom - height;            //   ... if so change dir.
      vertical = -1;
      }

     if (uly <= 1)                           // ... check for right edge,
      {
      uly = 1;
      vertical = 1;
      }

     if (ulx <= 1)
      {                                      // ... check for top edge;
      ulx = 1;
      horizontal = 1;
      }

     hDC = GetDC(hWind);                      // ... Get DC,
     SelectObject( hDC, hBrush);             // ... Set brush color,
                                             // ... Draw rectangle,
     Rectangle (hDC, ulx, uly, ulx+width, uly+height);
     ReleaseDC(hWind, hDC);                   // ... Release DC
     ulx += horizontal;                      // ... Increment/decrement
     uly += vertical;                        // ... position.

    }while(1);
}
