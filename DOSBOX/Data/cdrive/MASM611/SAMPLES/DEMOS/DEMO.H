/* Constants */
#define CR 13                           /* ASCII code for ENTER  */
#define ESCAPE 27                       /* ASCII code for ESC key */
#define MDA 0                           /* Adapter constants      */
#define CGA 1
#define MCGA 2
#define EGA 3
#define VGA 4
#define MONO 0                          /* Display constants      */
#define COLOR 1
#define clear_scrn( Attr, Row1, Row2 ) ClearBox( Attr, Row1, 0, Row2, 79 )

/* Structure members at 1-byte boundaries */
#pragma pack( 1 )

/* Video configuration structure */
struct VIDCONFIG
{
    unsigned char mode;         /* Current mode                   */
    unsigned char dpage;        /* Current display page           */
    unsigned char rows;         /* Number of display rows - 1     */
    unsigned char cols;         /* Number of display columns      */
    unsigned char display;      /* Either MONO or COLOR           */
    unsigned char adapter;      /* Adapter code                   */
    unsigned sgmnt;             /* Video segment with page offset */
};
struct VIDCONFIG pascal vconfig;  /* Structure for video configuration */

/* File information returned from FindFirst procedure  */
struct FILEINFO
{
    char pad[21];               /* pad to 43 bytes     */
    char attrib;                /* file attribute      */
    unsigned time;              /* file time           */
    unsigned date;              /* file date           */
    long size;                  /* file size           */
    char filename[13];          /* file name           */
};

/* Disk statistics returned from GetDiskSize procedure */
struct DISKSTAT
{
    unsigned total;             /* total clusters      */
    unsigned avail;             /* available clusters  */
    unsigned sects;             /* sectors per cluster */
    unsigned bytes;             /* bytes per sector    */
};

struct PARMBLK
{
    unsigned env;               /* segment of environment block         */
    char _far *taddr;           /* segment:offset address of tail       */
    char _far *fcb1;            /* segment:offset address of 1st FCB    */
    char _far *fcb2;            /* segment:offset address of 2nd FCB    */
};

/* Reset packing to default */
#pragma pack()

/* Procedure prototypes from COMMON.ASM */
short _pascal GetVer( void );
void  _pascal GetVidConfig( void );
void  _pascal StrWrite( unsigned Row, unsigned Col, char *Sptr );
void  _pascal ClearBox( unsigned Attr, unsigned Row1, unsigned Col1,
                        unsigned Row2, unsigned Col2 );
void  _pascal DisableCga( void );
void  _pascal EnableCga( void );
void  _pascal SetCurPos( unsigned Row, unsigned Col );
short _pascal GetCurPos( void );
short _pascal StrInput( unsigned Row, unsigned Col,
                        unsigned Max, char *Sptr );

/* Procedure prototypes from MISC.ASM */
short    _pascal WinOpen( unsigned Row1, unsigned Col1,
                          unsigned Row2, unsigned Col2, unsigned Attr );
void     _pascal WinClose( unsigned Addr );
void     _pascal SetCurSize( unsigned Scan1, unsigned Scan2 );
unsigned _pascal GetCurSize( void );
unsigned long _pascal GetShift( void );
unsigned long _pascal GetMem( void );
short    _pascal GetKeyClock( unsigned Row, unsigned Col );
short    _pascal VeriAnsi( void );
short    _pascal VeriPrint( void );
short    _pascal VeriCop( void );
short    _pascal SetLineMode( unsigned Line );
void     _pascal Pause( unsigned Duration );
void     _pascal Sound( unsigned Freq, unsigned Duration );
void     _pascal WriteTTY( char *Sptr, unsigned icolor );
void     _pascal Colors( unsigned Logic, unsigned Attr, unsigned Row1,
                         unsigned Col1, unsigned Row2, unsigned Col2 );
short    _pascal Exec( char *Spec, struct PARMBLK *Block,
                       void *CtrBrk, void *CtrlC, void *Criterr );
void     _pascal BinToHex( unsigned Num, char *Sptr );

/* Procedure prototypes from MATH.ASM */
long     _pascal AddLong(  long Long1, long Long2 );
long     _pascal SubLong(  long Long1, long Long2 );
long     _pascal ImulLong( long Long1, long Long2 );
unsigned long *_pascal MulLong( unsigned long Long1, unsigned long Long2 );
short    _pascal IdivLong( long Long1, short Short2, short *Remn );
unsigned _pascal DivLong(  unsigned long Long1,
                           unsigned Short2, unsigned *Remn );
short    _pascal Quadratic( float a, float b, float c,
                            float *R1, float *R2 );

/* Procedure prototypes from FILE.ASM */
void   _pascal ChangeDrive( unsigned Drive );
void   _pascal GetDiskSize( unsigned Drive, struct DISKSTAT *Disk );
void   _pascal SetDta( char far *Dta );
void   _pascal GetDta( char far *Dta );
short  _pascal ReadCharAttr( unsigned *Attr );
short  _pascal GetCurDir( char *Spec );
short  _pascal GetCurDrive( void );
short  _pascal CopyFile( unsigned Imode, char *Fspec1, char *Fspec2 );
short  _pascal DelFile( char *Fspec );
short  _pascal MakeDir( char *Pspec );
short  _pascal RemoveDir( char *Pspec );
short  _pascal ChangeDir( char *Pspec );
short  _pascal GetAttribute( char *Fspec );
short  _pascal SetAttribute( unsigned Attr, char *Fspec );
short  _pascal RenameFile( char *Fspec1, char *Fspec2 );
short  _pascal GetFileTime( unsigned Handle, char *Sptr );
short  _pascal FindFirst( unsigned Attr, char *Fspec,
                          struct FILEINFO *Finfo );
short  _pascal FindNext( struct FILEINFO *Finfo );
short  _pascal UniqueFile( unsigned Attr, char *Pspec );
short  _pascal OpenFile( unsigned Access, char *Fspec );
void   _pascal CloseFile( unsigned Handle );
short  _pascal CreateFile( unsigned Attr, char *Fspec );
short  _pascal CreateNewFile( unsigned Attr, char *Fspec );
short  _pascal ReadFile( unsigned Handle, unsigned Len, char *Pbuff );
short  _pascal WriteFile( unsigned Handle, char *Sptr );
void   _pascal Rewind( unsigned Handle );
unsigned long _pascal GetFileSize( unsigned Handle );
short  _pascal GetStr( char *Strbuf, unsigned Maxlen );
char  *_pascal StrCompare( char *Sptr1, char *Sptr2, unsigned Len );
char  *_pascal StrFindChar( char Ichar, char *Sptr, unsigned Direct );
