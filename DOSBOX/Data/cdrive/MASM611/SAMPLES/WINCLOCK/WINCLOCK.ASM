;----------------------------------------------------------------------------;
;                               winclock.ASM                                 ;
;----------------------------------------------------------------------------;
;                                                                            ;
; Sample MASM 6.1 program using the Windows API Interface. It heavily relies ;
; on the MASM 6.x high level constructs like INVOKE and .IF/.ELSE/.ENDIF.    ;
; The program, although simple enough, actually does quite a bit. Double     ;
; clicking on the window will bring up a popup menu with other options,      ;
; including setting an alarm.                                                ;
;                                                                            ;
; Adding to this code should be simple enough. New features could include    ;
; making sure that fonts are displayed with the appropiate aspect ratio.     ;
;                                                                            ;
; Note that this program doesn't attempt to teach how to program in Windows. ;
; For that you should consult the Windows Software Developers Kit or other   ;
; reference books.                                                           ;
;                                                                            ;
;----------------------------------------------------------------------------;

                .model  small, pascal, nearstack
                .286

                ?WINPROLOGUE = 1
                NOKERNEL = 1
                NOSOUND = 1
                NOCOMM = 1
                NODRIVERS = 1
                include win.inc                 ; Converted from WINDOWS.H

;----------------------------------------------------------------------------;
;                        Prototypes & External Definitions                   ;
;----------------------------------------------------------------------------;

WinMain          PROTO PASCAL, hInstance:HANDLE,  hPrevInstance:HANDLE,
                        lpszCmdLine:LPSTR, nCmdShow:SWORD
WndProc          PROTO FAR PASCAL,  :HWND, :WORD, :SWORD, :SDWORD
Initialize       PROTO,             :PINT, :PINT, :PINT,  :PINT
Resize           PROTO,             :HWND
SetupTimer       PROTO,             :HWND, :WORD

extern __astart:proc            ; When Windows load an app, it expects astart
                                ; to have the necessary start-up code. We get
                                ; astart from APPENTRY.ASM

;----------------------------------------------------------------------------;
;                             Numeric Equates                                ;
;----------------------------------------------------------------------------;

INIT_FONT        EQU    30t             ; initial font height
MAX_HEIGHT       EQU    100             ; Maximum Font Height
TOP_CORNER       EQU    1               ; Set to 0 for Lower-Right Corner Clock

IDM_DATE         EQU    1t              ; definitions for Menu items
IDM_ALARM        EQU    2t
IDM_SET          EQU    3t
IDM_MENU         EQU    4t
IDM_EXIT         EQU    5t
IDM_ABOUT        EQU    6t
IDM_MINIMIZE     EQU    7t
IDM_ONTOP        EQU    8t
AMPM             EQU    3t              ; length of am/pm strings
SCROLLCHILD      EQU    30t             ; identifies scroll: any number will do
MAXTIME          EQU    1439t           ; max # of minutes
TIMER_SECS       EQU    1000t           ; timer interval: 1000 mill = 1 second
TIMER_MINS       EQU    60000t          ; interval for 1 minute: 1000 * 60
ICON_LEN         EQU    7t              ; # of chars to display icon time

;----------------------------------------------------------------------------;
;                               Data Segments                                ;
;----------------------------------------------------------------------------;

                .const          

szAppName       SBYTE   "WINClock",0                   

DateFmt         SBYTE   " %s %2d, %04d ",13,10,0
TimeFmt         SBYTE   " %d:%02d:%02d %s ",0
IconFmt         SBYTE   " %d:%02d ",0
AlarmFmt        SBYTE   " %d:%02d %s ",0
szAMPM          SBYTE   "am",0,"pm",0                   
szTooManyTimers SBYTE   "Too many clocks or timers!",0
szAlarmMsg      SBYTE   "Remember your Appointment!",0
szMonths        SBYTE   "Jan",0,"Feb",0,"Mar",0,"Apr",0,"May",0,"Jun",0,
                        "Jul",0,"Aug",0,"Sep",0,"Oct",0,"Nov",0,"Dec",0
szDateCmd       SBYTE   "Enable &Date", 0
szSetCmd        SBYTE   "S&et Alarm",0
szAlarmCmd      SBYTE   "Enable &Alarm", 0
szOnTopCmd      SBYTE   "Always on &Top",0
szMinimizeCmd   SBYTE   "&Minimize", 0
szExitCmd       SBYTE   "E&xit", 0
szAboutCmd      SBYTE   "About &Clock...", 0
szAboutText     SBYTE   "Assembler Program Using the Windows API", 0
szDisplay       SBYTE   "DISPLAY", 0    ; to get a handle to entire display
szScrollBar     SBYTE   "scrollbar", 0  ; to create scrollbar 'class'                

                .data

EnableDate      BYTE    MF_CHECKED      ; Date initially enabled
EnableAlarm     BYTE    MF_UNCHECKED    ; Alarm initially disabled
AlwaysOnTop     BYTE    MF_CHECKED      ; Window will be on topmost
Iconized        BYTE    FALSE           ; Clock initially Normal Size
TestAlarm       BYTE    FALSE           ; so that we know to test for the alarm
SetAlarm        BYTE    FALSE           ; signalling while we set the alarm
AlarmTime       WORD    (MAXTIME/2)+1   ; initial alarm time: 12:00 pm

                .data?

cBuffer         SBYTE   40 dup (?)      ; buffer to receive text for drawing
hMenu           HMENU   ?               ; handle to Popup Menu
logfont         LOGFONT { }             ; logical font structure
hWndScrol       HWND    ?               ; handle to the scroll window
TextRect        RECT    { }             ; rectangle to draw text in

;----------------------------------------------------------------------------;
;                               Code Segment                                 ;
;----------------------------------------------------------------------------;

                .code

;----------------------------------------------------------------------------;
;                               WinMain                                      ;
;----------------------------------------------------------------------------;
;                                                                            ;
; Main routine called by Windows in program start. If no previous instances, ;
; sets up a window class and registers it. Initializes the program with      ;
; Initialize, creates a top window with the coordinates from Initialize, sets;
; up a child scroll bar control, and sets up the message loop.               ;
;                                                                            ;
;----------------------------------------------------------------------------;

WinMain         PROC,   hInstance:HANDLE,  hPrevInstance:HANDLE,
                        lpszCmdLine:LPSTR, nCmdShow:SWORD
                LOCAL   msg:MSG, wndclass:WNDCLASS, xStart:SWORD,
                        yStart:SWORD, xClient:SWORD, yClient:SWORD

                ; Local variables: msg: message to be used in the message loop
                ;                  wndclass: temp. to store window class
                ;                  x,y Start-Client: Size of Initial Window
;
;--- Check for previous instances
;
                .IF (hPrevInstance == 0)

                        lea     di, wndclass    ; because we use a NEARSTACK,
                        ASSUME  di:PTR WNDCLASS ; ss=ds

                        mov     ax, CS_HREDRAW OR CS_VREDRAW OR CS_DBLCLKS
                        mov     [di].style, ax 
                        mov     WORD PTR [di].lpfnWndProc,   LROFFSET WndProc
                        mov     WORD PTR [di].lpfnWndProc+2, SEG WndProc
                        xor     ax,ax
                        mov     [di].cbClsExtra, ax
                        mov     [di].cbWndExtra, ax

                        mov     [di].hIcon, ax  ; null icon: we will draw it

                        mov     ax, hInstance
                        mov     [di].hInstance, ax

                        INVOKE  LoadCursor, NULL, IDC_ARROW
                        mov     [di].hCursor, ax

                        INVOKE  GetStockObject, WHITE_BRUSH
                        mov     [di].hbrBackground, ax

                        xor     ax, ax
                        mov     WORD PTR [di].lpszMenuName,   ax
                        mov     WORD PTR [di].lpszMenuName+2, ax

                        mov     WORD PTR [di].lpszClassName,   OFFSET szAppName
                        mov     WORD PTR [di].lpszClassName+2, ds

                        INVOKE  RegisterClass, di
                        .IF (ax == 0)
                                mov     ax, FALSE
                                jmp     doRet
                        .ENDIF

                        ASSUME  di:NOTHING        

                .ENDIF     ;--- End of IF (hPrevInstance == 0)

;
;---- Initialize
;

                INVOKE  Initialize, ADDR xStart,  ADDR yStart,
                                    ADDR xClient, ADDR yClient

;
;---- Create Top Window
;

                INVOKE  CreateWindowEx, WS_EX_TOPMOST, ADDR szAppName,
                        ADDR szAppName, WS_BORDER OR WS_POPUP OR WS_THICKFRAME,
                        xStart, yStart, xClient, yClient, NULL, NULL, 
                        hInstance, NULL
                mov     si, ax          ; keep hWnd in SI, since SI doesn't
                                        ; change after function calls

                INVOKE  ShowWindow,    si, SW_SHOWNOACTIVATE
                INVOKE  UpdateWindow,  si
                                
                
;
;----Create Scroll Child Window
;

                INVOKE  CreateWindow, ADDR szScrollBar, NULL,
                        WS_CHILD OR WS_VISIBLE OR WS_TABSTOP OR SBS_HORZ,
                        0, 0, 0, 0, si, SCROLLCHILD, hInstance, NULL 
                mov     hWndScrol, ax

                INVOKE  SetScrollRange, ax, SB_CTL, 0, MAXTIME, FALSE
                INVOKE  SetScrollPos,   hWndScrol, SB_CTL, AlarmTime, FALSE

                INVOKE  ShowScrollBar,  hWndScrol, SB_CTL, TRUE
                INVOKE  ShowWindow,    hWndScrol, SW_SHOWNOACTIVATE
                INVOKE  UpdateWindow,  hWndScrol

;
;---- Message Loop
;

                .WHILE TRUE

                        INVOKE  GetMessage,    ADDR msg, NULL, 0, 0

                        .BREAK .IF (ax == 0)

                        INVOKE  TranslateMessage, ADDR msg
                        INVOKE  DispatchMessage,  ADDR msg

                .ENDW

;
;---- Return to Windows
;

                mov     ax, msg.wParam
doRet:
                ret

WinMain         ENDP


;----------------------------------------------------------------------------;
;                                Initialize                                  ;
;----------------------------------------------------------------------------;
;                                                                            ;
; Initializes the logfont struct, sizes the Initial Window, Makes the Menu.  ;  
;                                                                            ;
; For the size of the initial window: We get the DC for the entire display,  ;
; and calculate the size of the font into tmetric. With that, we allow for   ;
; the necessary distance from the top right corner so that there's enough    ;
; space for the text.                                                        ;
;                                                                            ;
;----------------------------------------------------------------------------;

Initialize      PROC USES si di, pxStart:PINT, pyStart:PINT, 
                                 pxClient:PINT, pyClient:PINT
                ; px,py,Start,Client will hold the dimensions of the initial
                ; window to create

                LOCAL hFont:HFONT, hDC:HDC, tmetric:TEXTMETRIC
                ; locals: a handle to a font, one to a device context, 
                ;         and a textmetric structure

;
;---- Initialize the logfont structure
;
        
                mov     bx, OFFSET logfont

                ASSUME  bx:PTR LOGFONT

                xor     ax, ax
                mov     [bx].lfHeight, INIT_FONT; Initial Font Height
                mov     [bx].lfWidth,  ax       ; width's set according to hght
                mov     [bx].lfEscapement, ax
                mov     [bx].lfOrientation, ax
                mov     [bx].lfWeight, FW_NORMAL
                mov     [bx].lfItalic, al
                mov     [bx].lfUnderline, al
                mov     [bx].lfStrikeOut, al
                mov     [bx].lfCharSet, ANSI_CHARSET
                mov     [bx].lfOutPrecision, al
                mov     [bx].lfClipPrecision, al
                mov     [bx].lfQuality, al
                mov     [bx].lfPitchAndFamily, DEFAULT_PITCH OR FF_SWISS
                mov     [bx].lfFaceName, NULL

                ASSUME  bx:NOTHING

;---- Get Initial Size for the Window Based on Font

                xor     dx, dx
                INVOKE  CreateIC, ADDR szDisplay, dx::dx, dx::dx, dx::dx
                mov     hDC, ax

                INVOKE  CreateFontIndirect, ADDR logfont
                mov     hFont, ax

                INVOKE  SelectObject, hDC, ax
                mov     hFont, ax

                INVOKE  GetTextMetrics, hDC, ADDR tmetric

                INVOKE  SelectObject, hDC, hFont

                INVOKE  DeleteObject, ax

                INVOKE  DeleteDC, hDC

                INVOKE  GetSystemMetrics, SM_CXDLGFRAME ; Set window width
                shl     ax, 1                           ; frame*2       
                mov     bx, tmetric.tmAveCharWidth      ; width of font
                mov     cl, 4                           ; to shift
                shl     bx, cl                          ; width*16
                add     ax, bx                          ; frame*2 + width*16
                mov     si, pxClient                    ; address to store in
                mov     [si], ax                        ; store

                INVOKE  GetSystemMetrics, SM_CXSCREEN   ; screen x-length
                mov     si, pxClient                    ; window width
                sub     ax, [si]                        ; start=corner-winWdth
                mov     si, pxStart                     ; store result
                mov     [si], ax

                INVOKE  GetSystemMetrics, SM_CYDLGFRAME ; Set Height
                shl     ax, 1                           ; frame*2
                mov     bx, tmetric.tmHeight            ; height*2
                shl     bx, 1
                add     ax, bx                          ; add
                mov     si, pyClient                    ; store in pyClient
                mov     [si], ax

                IF TOP_CORNER                           ; if Top Corner,
                        xor     ax, ax                  ; yStart=0
                ELSE                                    ; else,
                        INVOKE  GetSystemMetrics, SM_CYSCREEN   
                        mov     si, pyClient            ; yStart = ScreenHgth
                        sub     ax, [si]                ; minus yHeight
                ENDIF
                mov     si, pyStart                     ; set yStart
                mov     [si], ax


;
;---- Initialize the Menu
;

                INVOKE CreatePopupMenu
                mov hMenu, ax
                                                ; Date is Initially Enabled
                INVOKE  AppendMenu, hMenu, MF_STRING OR MF_CHECKED, IDM_DATE,
                                    ADDR szDateCmd
                INVOKE  AppendMenu, hMenu, MF_STRING, IDM_ALARM,ADDR szAlarmCmd
                INVOKE  AppendMenu, hMenu, MF_STRING, IDM_SET, ADDR szSetCmd
                INVOKE  AppendMenu, hMenu, MF_SEPARATOR, 0, NULL
                INVOKE  AppendMenu, hMenu, MF_STRING OR MF_CHECKED, IDM_ONTOP,
                                    ADDR szOnTopCmd
                INVOKE  AppendMenu, hMenu, MF_STRING, IDM_MINIMIZE, 
                                    ADDR szMinimizeCmd
                INVOKE  AppendMenu, hMenu, MF_STRING, IDM_EXIT, ADDR szExitCmd
                INVOKE  AppendMenu, hMenu, MF_SEPARATOR, 0, NULL
                INVOKE  AppendMenu, hMenu, MF_STRING, IDM_ABOUT,ADDR szAboutCmd
                ret

Initialize      ENDP

;----------------------------------------------------------------------------;
;                                SetupTimer                                  ;
;----------------------------------------------------------------------------;
;                                                                            ;
; Setup a timer with the specified interval. If we can't set up the timer,   ;
; output a message box and exit the program.                                 ;
;----------------------------------------------------------------------------;

SetupTimer PROC NEAR, hWnd:HWND, Interval:WORD
                ; hWnd is the Handle of the Window to associate the timer with
                ; Interval is the interval in milliseconds

                INVOKE  SetTimer, hWnd, 1, Interval, NULL
                .IF (ax == 0)
                        INVOKE  MessageBox, hWnd,ADDR szTooManyTimers, 
                                            ADDR szAppName,
                                            MB_ICONEXCLAMATION OR MB_OK
                        mov     ax, FALSE
                        INVOKE PostQuitMessage, 0               ; Quit.
                .ENDIF

                ret
SetupTimer ENDP

;----------------------------------------------------------------------------;
;                                AlarmSetup                                  ;
;----------------------------------------------------------------------------;
;                                                                            ;
; If we're going to set the alarm, kill the timer, show the scroll bar, and  ;
; resize the fonts. Enable the Alarm after it has been re-set.               ;
;                                                                            ;
; If we just set up the alarm, get a new timer,                              ;
; check the menu to enable the alarm, hide the scrollbar, resize the fonts   ;
; When creating the top window this is called to set up the initial timer.   ;
;                                                                            ;
;----------------------------------------------------------------------------;

AlarmSetup      PROC,   hWnd:HWND
                ; hWnd is the handle of the window that received WinPaint 


                .IF SetAlarm
                        INVOKE  KillTimer, hWnd, 1
                        INVOKE  Resize, hWnd
                        INVOKE  ShowScrollBar, hWndScrol, SB_CTL, TRUE
                        INVOKE  SetFocus, hWndScrol
                        INVOKE  InvalidateRect, hWnd, NULL, TRUE
                        mov     EnableAlarm, MF_CHECKED
                        mov     TestAlarm, TRUE         

                .ELSE

                        INVOKE  SetupTimer, hWnd, TIMER_SECS
                        INVOKE  CheckMenuItem, hMenu, IDM_ALARM, EnableAlarm
                        INVOKE  ShowScrollBar,  hWndScrol, SB_CTL, FALSE
                        INVOKE  Resize,         hWnd
                        INVOKE  InvalidateRect, hWnd, NULL, TRUE

                .ENDIF          

                ret

AlarmSetup      ENDP
                
        
;----------------------------------------------------------------------------;
;                                    Resize                                  ;
;----------------------------------------------------------------------------;
;                                                                            ;
; Simple resizing, without taking into account aspect ratio.                 ;
; If we're setting the alarm, the scroll bar height will be (client hgt)/16, ;
; the length will be (client lenght)-(2*Scroll Bar Height), and the top will ;
; will start (in Client coordinates), at one SB Height right and 2 SBHeights ;
; up from the left bottom corner. Fonts width will be length/10, height will ;
; be (client height)-(3*Scroll bar height). The Scroll bar is also displayed.;
;                                                                            ;
; If we're not setting the alarm, and we're not minimized, font width will be;
; length/TIME_LEN and height will be either client height or client height/2,;
; depending on the date being enabled or not.                                ;
;                                                                            ;
; If font height is more than MAX_HEIGHT, then height is MAX_HEIGHT, and the ;
; TextRect.top is computed so that Drawing the text on the client area will  ;
; be centered.                                                               ;
;                                                                            ;
; If we're minimized, width=length/ICON_LEN, height is client height.        ;
;                                                                            ;
; The TextRect is used so that it's not recomputed everytime the Window is   ;
; repainted.                                                                 ;
;                                                                            ;
;----------------------------------------------------------------------------;

Resize          PROC,   hWnd:HWND
                ; hWnd is the handle of the window that received WinPaint 
                LOCAL   rect:RECT
                ; holds a rectangle structure

                INVOKE  SetFocus, hWnd  ; take focus out of child window

                INVOKE  GetClientRect, hWnd, ADDR rect ; get new rect.size
                

;---- Find desired Text Height

                .IF SetAlarm    

;---- Calculate New TextRect allowing for Scroll Bar

                        mov     bx, rect.bottom   ; SXstart is length / 8
                        shr     bx, 3
                
                        mov     cx, rect.right    ; SLength=CLenght-2*SHeight
                        sub     cx, bx 
                        sub     cx, bx

                        mov     dx, rect.bottom   ; SYstart will be CHgt-2*SHgt
                        sub     dx, bx
                        sub     dx, bx

                        mov     TextRect.bottom, dx  ; bottom = CHgt - 3*SHgt
                        sub     TextRect.bottom, bx

                        INVOKE  MoveWindow, hWndScrol, bx, dx, cx, bx, FALSE
                        INVOKE  SetScrollPos,hWndScrol,SB_CTL,AlarmTime,TRUE

                        mov     ax,TextRect.bottom   ; Try to use Full Height
                                                     ; for font height

;---- Else (not setting the alarm)

                .ELSE

                        mov     ax, rect.bottom      ; Full or Half Height
                        mov     TextRect.bottom, ax
                        .IF EnableDate && !Iconized
                                shr     ax, 1        ; height/2
                        .ENDIF
                .ENDIF          


;---- Test if desired height is allowed or not
;---- If height>MAX, then height=MAX_HEIGHT. Adjust TextRect.top by
;---- substracting from the bottom the font height (or twice that if Date),
;---- dividing by two, and adding to the TextRect.top.

                .IF (ax > MAX_HEIGHT)   
                        mov     logfont.lfHeight, MAX_HEIGHT
                        mov     ax, TextRect.bottom
                        mov     bx, MAX_HEIGHT
                        .IF EnableDate && !Iconized
                                shl     bx, 1
                        .ENDIF
                        sub     ax, bx
                        shr     ax, 1
                        mov     TextRect.top, ax
                .ELSE
                        mov     logfont.lfHeight, ax
                        mov     TextRect.top, 0

                .ENDIF

                mov     TextRect.left, 0                ; Left is Zero
                mov     ax, rect.right                  ; Same Rect length
                mov     TextRect.right, ax

;---- Set font width according to Iconized or not.

                .IF Iconized    
                        xor     dx, dx
                        mov     bx, ICON_LEN
                        div     bx
                .ELSE
                        shr     ax, 4        ; length/16
                .ENDIF
                mov     logfont.lfWidth, ax

                ret

Resize          ENDP
                
;----------------------------------------------------------------------------;
;                                  PaintAlarm                                ;
;----------------------------------------------------------------------------;
;                                                                            ;
; Painting the alarmtime. Get the hours and minutes from Alarmtime, get AM   ;
; or PM by going into szAMPM either at 0 or 3, to get the appropiate string. ;
; Then we simply draw the text into the TextRect calculated by Resize, with  ;
; the font that we get from using the logfont structure.                     ;
;                                                                            ;
;----------------------------------------------------------------------------;

PaintAlarm      PROC USES si di,  hWnd:HWND, hDC:HDC
                ; hWnd is the handle of the window that received WinPaint
                ; hDC is the Device context of the window

                LOCAL   nLength:SWORD, hFont:HFONT,
                        hour:WORD, minutes:WORD, seconds:WORD
                ; Locals: nLength is the current length of the buffer
                ;         hFont is a handle to a font.  

;---- Get Time from AlarmTime

                xor     dx, dx
                mov     ax, AlarmTime
                mov     bx, 60t
                div     bx                      ; ax holds the hours
                mov     bx, dx                  ; bx holds the minutes

                mov     si, ax                  ; si holds the hours
                xor     dx, dx
                mov     di, 12
                div     di                      ; will have ax=0 or 1 (am/pm)
                xor     dx, dx
                mov     cx, AMPM                ; AMPM = 3: 'am'+\0
                mul     cx
                mov     di, ax
                add     di,offset szAMPM        ; get into di the correct
                                                ; memory address        

                mov     ax, si                  ; ax == tm_hour
                xor     dx, dx
                mov     cx, 12
                div     cx
                .IF (dx == 0)                   ; so we don't have 00:45
                        mov cx, 12
                .ELSE
                        mov cx, dx
                .ENDIF
                
;---- on using wsprintf below: since the wsprintf prototype has VARARG,
;---- we can't tell the assemble the distance of those arguments, so we
;---- have to do a specific far pointer to the data. wsprintf expects all
;---- pointers to be far pointers, no exceptions.

                INVOKE  wsprintf, ADDR cBuffer, ADDR AlarmFmt,
                                  cx, bx, ds::di
                mov     nLength,ax

;---- Set Font & Draw Text

                INVOKE  CreateFontIndirect, ADDR logfont
                mov     hFont, ax
                INVOKE  SelectObject, hDC, ax
                mov     hFont, ax
                INVOKE  DrawText, hDC, ADDR cBuffer, nLength, ADDR TextRect,
                                       (DT_CENTER)
                INVOKE  SelectObject, hDC, hFont
                INVOKE  DeleteObject, ax

                ret

PaintAlarm      ENDP

;----------------------------------------------------------------------------;
;                                  PaintTime                                 ;
;----------------------------------------------------------------------------;
;                                                                            ;
; Painting the time. We get a index to szMonths by multiplying the [0-11]    ;
; month by 4 ('jan'+\0). We print everything to a string and store the length;
; as an index. We do this only if Date's enabled.                            ;
; For the time, we do the same AM/PM thing as in PaintAlarm, and print it to ;
; the same string after the Date's carriage return (included in DateFmt.     ;
; Then we simply draw the text into the TextRect calculated by Resize, with  ;
; the font that we get from using the logfont structure.                     ;
; If we're minimized, we also draw a rectangle around the time. We get a pen ;
; of width 2, black, and a hollow (transparent) brush. We save the pen ID in ;
; the stack so that we can deselect it later.                                ;
; Then, we check to see if we have to spring the alarm. If TestAlarm is not  ;
; enabled, check the time and re-enable TestAlarm if it's NOT the AlarmTime  ;
; (i.e. so that after we ring it it will ring in 24 hours). If TestAlarm is  ;
; set, check if EnableAlarm is set. If it is, multiply the hours by 60, add  ;
; the minutes, compare with AlarmTime. Notice that the 'mov bx, datetime' is ;
; necessary because the wsprintf and DrawText will trash ax, bx, cx. If it's ;
; alarm time, disable TestAlarm, invert the rectangle, sound a beep, revert  ;
; the rect, and do a message box. This way, TestAlarm enables us to always   ;
; have at least one check of the alarm time.                                 ;
;                                                                            ;
;----------------------------------------------------------------------------;

PaintTime       PROC USES si di,  hWnd:HWND, hDC:HDC
                ; hWnd is the handle of the window that received WinPaint
                ; hDC is the Device context of the window

                LOCAL   nLength:SWORD, hFont:HFONT, pen:WORD,
                        hour:WORD, minutes:WORD, seconds:WORD
                ; Locals: nLength is the current length of the buffer
                ;         hFont is a handle to a font.  

;---- Set Date Variables

                .IF (EnableDate && !Iconized) 

                       mov     ah, 2Ah               ; function: Get Date
                       INVOKE  DOS3Call              ; do the interrupt
                                                     ; dh will have months
                                                     ; dl will have days
                                                     ; cx will have years
 
                        mov     al, dh               ; months (1-12)
                        xor     ah, ah
                        xor     dh, dh               ; day-of-month (1-31)
                

                        mov     si, ax               ; (Month-1) * 4
                        dec     si
                        shl     si, 2
                        add     si, offset szMonths

;---- For note on wsprintf below, see PaintAlarm

                        INVOKE  wsprintf, ADDR cBuffer, ADDR DateFmt,
                                  ds::si, dx, cx
                        mov nLength, ax
                .ELSE
                        mov nLength, 0

                .ENDIF ; of EnableDate

;---- Get Time from CPU clock
                xor     dx, dx

                mov     ah, 2Ch                      ; function: Get Time
                INVOKE  DOS3Call                     ; do the interrupt
                                                     ; ch will have hours
                                                     ; cl will have minutes
                                                     ; dh will have seconds

                mov     al, ch                       ; hours (0-23)
                xor     ah, ah
                mov     hour, ax         
                mov     al, cl                       ; minutes (0-59)
                mov     minutes, ax          
                mov     al, dh                       ; seconds (0-59)
                mov     seconds, ax          
  
                mov     ax, hour                     ; divide hour/12, multiply
                xor     dx, dx                       ; by 3 to get offset into
                mov     bx, 12                       ; szAMPM, then add the 
                div     bx                           ; szAMPM offset
                mov     si, dx                       ; dx would have hours
                xor     dx, dx
                mov     cx, AMPM
                mul     cx
                mov     bx, ax
                add     bx, offset szAMPM            ; get into di the correct
                                                     ; memory address
                
                .IF (si == 0)                        ; get hour into cx
                        mov  cx, 12                  ; or 12 if hour=0
                .ELSE
                        mov  cx, si
                .ENDIF
                
                mov     si, nLength
                .IF !Iconized
                        INVOKE  wsprintf, ADDR cBuffer[si], ADDR TimeFmt,
                                          cx, minutes, seconds, ds::bx
                .ELSE
                        INVOKE  wsprintf, ADDR cBuffer[si], ADDR IconFmt,
                                          cx, minutes        
                .ENDIF

                add     nLength, ax

;---- Set Font, Draw the Text

                INVOKE  CreateFontIndirect, ADDR logfont
                mov     hFont, ax
                INVOKE  SelectObject, hDC, ax
                mov     hFont, ax
                INVOKE  DrawText, hDC, ADDR cBuffer, nLength, ADDR TextRect,
                                        DT_NOCLIP OR DT_CENTER
                INVOKE  SelectObject, hDC, hFont
                INVOKE  DeleteObject, ax

;---- If Iconized, draw rectangle with transparent background

                .IF Iconized

                        INVOKE  GetStockObject, HOLLOW_BRUSH
                        INVOKE  SelectObject, hDC, ax

                        INVOKE  CreatePen, PS_SOLID OR PS_INSIDEFRAME, 2, 0
                        INVOKE  SelectObject, hDC, ax
                        push    ax

                        INVOKE  Rectangle, hDC, TextRect.left, TextRect.top,
                                        TextRect.right, TextRect.bottom

                        INVOKE  GetStockObject, HOLLOW_BRUSH
                        INVOKE  SelectObject, hDC, ax
                        INVOKE  DeleteObject, ax

                        pop     ax
                        INVOKE  SelectObject, hDC, ax
                        INVOKE  DeleteObject, ax
                .ENDIF

;---- Check for Alarm

                xor     dx, dx
                mov     ax, hour
                mov     cx, 60t
                imul    cx
                add     ax, minutes          ; ax now holds the time in minutes

                .IF (TestAlarm)
                        .IF (EnableAlarm && (ax == AlarmTime))
                                mov     TestAlarm, FALSE
                                INVOKE  SetFocus, hWnd
                                INVOKE  InvertRect, hDC, ADDR TextRect
                                INVOKE  MessageBeep, MB_ICONASTERISK
                                INVOKE  InvertRect, hDC, ADDR TextRect
                                INVOKE  MessageBox, hWnd, ADDR szAlarmMsg,
                                    ADDR szAppName,MB_ICONEXCLAMATION OR MB_OK
                        .ENDIF
                .ELSE ; of TestAlarm                    ; if TestAlarm=0, means
                        .IF (ax != AlarmTime)           ; we sounded the alarm. 
                                mov     TestAlarm, TRUE ; but, if time 
                        .ENDIF                          ; changed, we should to
                .ENDIF                                  ; check again (allows 
                                                        ; alarm every 24 hours)

                ret

PaintTime       ENDP

;----------------------------------------------------------------------------;
;                                  WndProc                                   ;
;----------------------------------------------------------------------------;
;                                                                            ;
; The routine called on by Windows through WinMain's dispatch message loop.  ;
; Different actions according to messages                                    ;
;       Create: Set the timer with AlarmSetup                                ;
;       Timer: Repaint the window (Invalidate it)                            ;
;       Paint: BeginPaint, call on the correct paint routine                 ;
;       SetFocus: Redraw the Window Frame                                    ;
;       Resize: Resize the fonts and scroll bar, redraw the window           ;
;       Destroy: Close window and exit program                               ;
;       LeftDouble or RightClick: If setting alarm, set it; otherwise pop up ;
;           menu.  Mouse position is in the high & low words of lParam, in   ;
;           client coords. Change them to Screen coords and show menu.       ;
;       LeftClick: Move window by tricking Windows into thinking that we've  ;
;                  hit the Caption Bar of the window. It doesn't matter that ;
;                  there isn't a caption bar.                                ;
;       Commands: Date: Toggle the switch, check the menu, resize and paint  ;
;                 EnableAlarm: Sound the alarm or not                        ;
;                 Set: Start setting the alarm                               ;
;                 About: Display a Message Box. A dialog box is up to you    ;
;                 AlwaysOnTop: Sets the Window Position to be Topmost or not ;
;                 Minimize: make Windows think we hit the 'Minimize' command ;
;                    from the system menu.                                   ;
;                 Exit: Exit program.                                        ;
;       ScrollBar: Page Moves indicate hours, lines minutes. If thumb, the   ;
;                  lParam low word holds the position. Check that we don't   ;
;                  go out of range, set the scroll position, and repaint.    ;
;       Otherwise, call the default window procedure.                        ;
;                                                                            ;
;       Notice that most of the repaints do not erase the backgrnd, only     ;
;               RedrawWindow of Resize and SetFocus. This speeds up exec,    ;
;               and drawtext will erase over everything automatically.       ; 
;                                                                            ;
;----------------------------------------------------------------------------;

WndProc         PROC FAR PASCAL, hWnd:HWND, iMessage:WORD, wParam:SWORD,
                                 lParam:SDWORD
                ; Windows gives us: the handle of the Window, the Message ID,
                ; and two parameters for the message

                LOCAL   hDC:HDC, ps:PAINTSTRUCT, point:POINT
                ; locals: a handle to a device context, a paint structure,
                ;         a point structure

                .IF     (iMessage == WM_CREATE)
                        INVOKE  SetupTimer, hWnd, TIMER_SECS
                        INVOKE  Resize, hWnd
                        INVOKE  InvalidateRect, hWnd, NULL, FALSE

                .ELSEIF (iMessage == WM_TIMER)
                        INVOKE  InvalidateRect, hWnd, NULL, FALSE

                .ELSEIF (iMessage == WM_PAINT)
                        INVOKE  BeginPaint, hWnd, ADDR ps
                        mov     hDC, ax
                        .IF SetAlarm
                                INVOKE  PaintAlarm, hWnd, hDC
                        .ELSE
                                INVOKE  PaintTime, hWnd, hDC
                        .ENDIF
                        INVOKE  EndPaint, hWnd, ADDR ps

                .ELSEIF (iMessage == WM_SETFOCUS)
                        INVOKE  RedrawWindow, hWnd, NULL, NULL, 
                                              RDW_FRAME OR RDW_UPDATENOW

                .ELSEIF (iMessage == WM_SIZE)
                        .IF ((wParam != SIZE_MINIMIZED) && Iconized)
                                mov     Iconized, FALSE
                                INVOKE  KillTimer, hWnd, 1
                                INVOKE  SetupTimer, hWnd, TIMER_SECS
                        .ENDIF
                        INVOKE  Resize, hWnd
                        INVOKE  RedrawWindow, hWnd, NULL, NULL,
                                              RDW_ERASE OR RDW_INVALIDATE
                
                .ELSEIF (iMessage == WM_DESTROY)
                        INVOKE  KillTimer, hWnd, 1
                        INVOKE  PostQuitMessage, 0

                .ELSEIF (iMessage==WM_LBUTTONDBLCLK)||(iMessage==WM_RBUTTONUP)
                        .IF SetAlarm
                                xor SetAlarm, TRUE
                                INVOKE  AlarmSetup, hWnd
                        .ELSE
                                mov     di, word ptr lParam
                                mov     point.x, di
                                mov     di, word ptr (lParam+2)
                                mov     point.y, di
                                INVOKE  ClientToScreen, hWnd, ADDR point
                                INVOKE  TrackPopupMenu, hMenu, TPM_LEFTALIGN,
                                        point.x, point.y, 0, hWnd, NULL          
                                INVOKE  InvalidateRect, hWnd, NULL, TRUE
                        .ENDIF

                .ELSEIF (iMessage == WM_LBUTTONDOWN)
                        INVOKE DefWindowProc, hWnd, WM_NCLBUTTONDOWN, 
                                HTCAPTION, lParam

                .ELSEIF (iMessage == WM_COMMAND)

                        .IF (wParam == IDM_DATE)
                                xor     EnableDate, MF_CHECKED
                                INVOKE  CheckMenuItem,hMenu,wParam,EnableDate
                                INVOKE  Resize, hWnd
                                INVOKE  InvalidateRect, hWnd, NULL, FALSE                       

                        .ELSEIF (wParam == IDM_ALARM)
                                xor     EnableAlarm, MF_CHECKED
                                mov     TestAlarm, TRUE
                                INVOKE  CheckMenuItem,hMenu,wParam,EnableAlarm

                        .ELSEIF (wParam == IDM_SET)
                                mov     SetAlarm, TRUE
                                INVOKE  AlarmSetup, hWnd

                        .ELSEIF (wParam == IDM_ABOUT)
                                INVOKE  MessageBox, hWnd, ADDR szAboutText,
                                     ADDR szAppName, MB_ICONASTERISK OR MB_OK

                        .ELSEIF (wParam == IDM_ONTOP)
                                xor     AlwaysOnTop, MF_CHECKED
                                INVOKE  CheckMenuItem,hMenu,wParam,AlwaysOnTop
                                .IF AlwaysOnTop
                                        mov     ax, HWND_TOPMOST
                                .ELSE
                                        mov     ax, HWND_NOTOPMOST
                                .ENDIF

                                INVOKE  SetWindowPos, hWnd, ax,
                                        0, 0, 0, 0, SWP_NOMOVE OR SWP_NOSIZE
                        
                        .ELSEIF (wParam == IDM_EXIT)
                                INVOKE  KillTimer, hWnd, 1
                                INVOKE  PostQuitMessage, 0

                        .ELSEIF (wParam == IDM_MINIMIZE)
                                mov     Iconized, TRUE
                                INVOKE  KillTimer, hWnd, 1
                                INVOKE  SetupTimer, hWnd, TIMER_MINS
                                INVOKE  DefWindowProc, hWnd, WM_SYSCOMMAND, 
                                                       SC_ICON, NULL

                        .ENDIF
                
                .ELSEIF (iMessage == WM_HSCROLL)
                        .IF (wParam == SB_PAGEDOWN)
                                add     AlarmTime, 10t
                        .ELSEIF (wParam == SB_LINEDOWN)
                                inc     AlarmTime
                        .ELSEIF (wParam == SB_PAGEUP)
                                sub     AlarmTime, 10t
                        .ELSEIF (wParam == SB_LINEUP)
                                dec     AlarmTime
                        .ELSEIF (wParam == SB_TOP)
                                mov     AlarmTime, MAXTIME
                        .ELSEIF (wParam == SB_BOTTOM)
                                mov     AlarmTime, 0t
                        .ELSEIF (wParam == SB_THUMBPOSITION)
                                mov     ax, word ptr lParam
                                mov     AlarmTime, ax
                        .ELSEIF (wParam == SB_THUMBTRACK)
                                mov     ax, word ptr lParam
                                mov     AlarmTime, ax
                        .ELSEIF (wParam == SB_LINEDOWN)
                                mov     ax, word ptr lParam
                                mov     AlarmTime, ax
                        .ENDIF
                                .IF (AlarmTime < 0)
                                        mov     AlarmTime, 0t
                                .ELSEIF (AlarmTime > MAXTIME)
                                        mov     AlarmTime, MAXTIME
                                .ENDIF
                        
                                INVOKE  SetScrollPos, hWndScrol, SB_CTL,
                                        AlarmTime, TRUE
                                INVOKE  InvalidateRect, hWnd,
                                                        ADDR TextRect, FALSE

                .ELSE
                                INVOKE  DefWindowProc, hWnd, iMessage,
                                                       wParam,lParam
                                jmp     doRet

                .ENDIF

                mov ax, 0
                cwd
doRet:
                ret

WndProc         ENDP


                END  __astart   ; so that the code of the application will
                                ; start with the Windows start-up code

