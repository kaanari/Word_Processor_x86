/* Assembly library prototypes */

int  pascal far Install( int Param1, int Param2,
                         int Param3, void (far *Param4)() );
int  pascal far Deinstall( void );
int  pascal far InitTsr( int PspParam, char far *StrParam,
                         void far *ShrParam );
void pascal far KeepTsr( int ParaNum );
int  pascal far FreeTsr( int PspSeg );
int  pascal far CallMultiplexC( int FuncNum, void far *RecvPtr );
int  pascal far GetResidentSize( int PspSeg );
void pascal far FatalError( int Err );

/* Constants */

#define NOT_INSTALLED           0       /* TSR not installed               */
#define IS_INSTALLED            1       /* TSR is installed                */
#define ALREADY_INSTALLED       2       /* TSR already installed           */
#define UNKNOWN_PROBLEM         3       /* Can't install                   */
#define FLAGS_NOT_FOUND         4       /* InDos / CritErr flags not found */
#define CANT_DEINSTALL          5       /* Can't deinstall                 */
/*                              6          Wrong DOS not possible in C     */
#define MCB_DESTROYED           7       /* Memory control block problem    */
#define NO_IDNUM                8       /* No identity numbers available   */
#define INVALID_ADDR            9       /* Free memory block problem       */
#define OK_ACCESS               10      /* TSR accessed successfully       */
#define CANT_ACCESS             11      /* TSR not installed: can't access */
#define BAD_ARGUMENT            12      /* Unrecognized argument           */
#define NO_ARGUMENT             13      /* No argument in command line     */
#define OK_ARGUMENT             14      /* Okay argument in command line   */
