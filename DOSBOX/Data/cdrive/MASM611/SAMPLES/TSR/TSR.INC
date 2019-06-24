COMMENT +

To force TSR to set up its own disk transfer area, define the equate 
constant DTA_SIZ with the desired buffer size in bytes.  (See section 
"Preserving Existing Data" in Chapter 11 of the Programmer's Guide.)
DTA_SIZ                 EQU     40      ; DTA size in bytes

        +

STACK_SIZ               EQU     400h    ; Stack size in bytes
STR_LEN                 EQU     20      ; Max length of multiplex ID string

TRUE                    EQU     -1
FALSE                   EQU     0
NULL                    EQU     0
TAB                     EQU     09      ; ASCII code for TAB key
LF                      EQU     10      ; ASCII code for line feed
CR                      EQU     13      ; ASCII code for ENTER key
ESCAPE                  EQU     27      ; ASCII code for ESCAPE key
SHFT_STAT               EQU     417h    ; Offset of shift-key status mask at
                                        ;   0:417h in the ROM BIOS data area

; Return codes used by procedures in HANDLERS and INSTALL modules
NOT_INSTALLED           EQU     0       ; TSR not installed
IS_INSTALLED            EQU     1       ; TSR is installed
ALREADY_INSTALLED       EQU     2       ; TSR already installed
UNKNOWN_PROBLEM         EQU     3       ; Can't install
FLAGS_NOT_FOUND         EQU     4       ; InDos / CritErr flags not found
CANT_DEINSTALL          EQU     5       ; Can't deinstall
WRONG_DOS               EQU     6       ; Can't handle DOS 1.x
MCB_DESTROYED           EQU     7       ; Memory control block problem
NO_IDNUM                EQU     8       ; No identity numbers available
INVALID_ADDR            EQU     9       ; Free memory block problem
OK_ACCESS               EQU     10      ; TSR accessed successfully
CANT_ACCESS             EQU     11      ; TSR not installed: can't access
BAD_ARGUMENT            EQU     12      ; Unrecognized argument
NO_ARGUMENT             EQU     13      ; No argument in command line
OK_ARGUMENT             EQU     14      ; Okay argument in command line

IFNDEF  FPVOID                          ; Already in DEMO.INC
FPVOID  TYPEDEF FAR  PTR                ; Type for far pointer to void
ENDIF

INTR            STRUCT                  ; Structure of handler information
  Num           BYTE    ?               ; Interrupt number
  Flag          BYTE    ?               ; Active flag (for device interrupts)
  OldHand       FPVOID  ?               ; Address of original handler routine
  NewHand       FPVOID  ?               ; Address of TSR's handler
INTR            ENDS

ERRINFO         STRUCT                  ; Structure of extended error
  AxReg         WORD    ?               ;   information (see "Preserving
  BxReg         WORD    ?               ;   Existing Data" in Chapter 11
  CxReg         WORD    ?               ;   of Programmer's Guide)
  DxReg         WORD    ?
  SiReg         WORD    ?
  DiReg         WORD    ?
  DsReg         WORD    ?
  EsReg         WORD    ?
  ErrResrv      WORD    3 DUP (0)
ERRINFO         ENDS

; Prototypes
Install         PROTO FAR PASCAL,
                Param1:WORD, Param2:WORD, Param3:WORD, Param4:FAR PTR FAR

Deinstall       PROTO FAR
                ; No arguments

InitTsr         PROTO FAR PASCAL,
                PspParam:WORD, StrParam:FPVOID, ShrParam:FPVOID

KeepTsr         PROTO FAR PASCAL ParaNum:WORD

FreeTsr         PROTO FAR PASCAL PspSeg:WORD

CallMultiplex   PROTO FAR
                ; AL = Function number for multiplex handler

CallMultiplexC  PROTO FAR PASCAL FuncNum:WORD, RecvPtr:FPVOID

GetResidentSize PROTO FAR PASCAL PspSeg:WORD

FatalError      PROTO FAR PASCAL Err:WORD

GetOptions      PROTO NEAR
                ; ES = Segment of Program Segment Prefix
                ; AL = Argument character for which to scan

