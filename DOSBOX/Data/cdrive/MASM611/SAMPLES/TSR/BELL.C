/* BELL.C - Beeps speaker at preset time. Illustrates how to create
 * a TSR in a high-level language using the TSR library of assembly
 * routines. Also shows how to write a time-activated TSR by passing
 * hour and minute arguments to the Install procedure.
 *
 * To install BELL, include argument hhmm = hour:minute for activation.
 * Argument must be in military format (1855 for 6:55 P.M., for example)
 * and must consist of 4 digits. To activate BELL at 8:30 A.M., enter
 *     BELL 0830
 *
 * Some differences exist between BELL.C and the ALARM.ASM program
 * presented in Chapter 11 of the Programmer's Guide. The C version
 * requires more memory and does not allow multiple installations since
 * it calls the multiplex handler to check for prior residency. BELL
 * is deinstallable at any time, however, by entering
 *     BELL /D
 * at the command line. To reset the number of times BELL beeps the
 * speaker, enter
 *     BELL /Cx
 * where x = desired number of beeps.
 */


void far  Beeper( void );       /* Main TSR code */
void near ErrorExit( int );     /* Exit routine  */

#include <dos.h>
#include <stdlib.h>
#include <stdio.h>
#include "tsr.h"
#include "..\demos\demo.h"

int BeepCount = 1;              /* Global variable  = number of beeps      */

void main( int argc, char *argv[] )
{
    char c;                             /* Character                       */
    int Err, Hour, Minute, Time;        /* Error code, activation hour:min */
    int far *BeepCountPtr;              /* Pointer to shared memory        */

    /* Initialize data before calling other TSR library routines.
     * Pass far address of identifier string unique to this TSR.
     * Pass far address of global variable BeepCount as address
     * of shared memory. This allows a subsequent execution of
     * the program to locate the resident BeepCount and reset it
     * to a new value. See comments below describing /C switch.
     */
    Err = InitTsr( _psp, (char far *)"BELL DEMO TSR", &BeepCount );

    /* Argument required */
    if( argc == 1 )
    {
        puts( "Requires argument for time = hhmm,\n"
              "deinstallation = /D, or\n"
              "new beep count = /Cx" );
        exit( 1 );
    }

    /* Check for /D or /C arguments. Do this block if argument
     * begins with '/' or '-' prefix. Otherwise, assume argument
     * specifies alarm setting hhmm and skip to next section.
     */
    c = *argv[1];
    if( c == '/' || c == '-' )
    {
        c = (char)toupper( *(++argv[1]) );

        /* If /D argument, deinstall resident TSR and exit */
        if( c == 'D' )
        {
            Err = Deinstall();
            if( Err <= BAD_ARGUMENT )
                ErrorExit( Err );
            ErrorExit( FreeTsr( Err ) );
        }

        /* If /Cx ("change") argument, call multiplex handler to
         * locate resident BeepCount, rewrite BeepCount with new
         * value specified by integer x, and exit.
         */
        if( c != 'C' )
            ErrorExit( BAD_ARGUMENT );
        if( CallMultiplexC( 2, &BeepCountPtr ) != IS_INSTALLED )
            ErrorExit( CANT_ACCESS );
        *BeepCountPtr = atoi( ++argv[1] );
        ErrorExit( OK_ACCESS );
    }

    /* Do this section if argument is not preceded by '/' or '-'
     * prefix. Assume argument specifies TSR activation time in
     * military format hhmm, where hh = hour and mm = minute.
     * Install TSR to activate at this time.
     */
    Time   = atoi( argv[1] );
    Hour   = Time / 100;
    Minute = Time - (Hour * 100);

    /* Call Install procedure with first argument = 0. This
     * signals procedure that TSR is to be time activated at
     * hour:minute given by second and third arguments. The fourth
     * argument gives the far address of the main body of the
     * TSR that executes at the specified time -- in this case
     * the function Beeper.
     */
    Err = Install( 0, Hour, Minute, Beeper );
    if( Err )
        ErrorExit( Err );
    _dos_keep( 0, (unsigned)GetResidentSize( _psp ) );
}

/* _nullcheck - used to disable the C-Runtime null pointer check. */
void _nullcheck()
{
        return;
}


/* ErrorExit - Displays appropriate exit message and exits program. */
void ErrorExit( int Err )
{
    extern char *MSGTBL[];

    puts( MSGTBL[ Err ] );
    exit( Err );
}
    

/* ILLEGAL C FUNCTIONS
 * -------------------
 * Use of certain C library functions in a resident program is either
 * illegal or ill advised. These functions include:
 *
 *     exec/spawn functions such as execv(), spawnv(), and system()
 *     environment functions such as getenv(), _searchenv(), and putenv()
 *
 *
 * USING THE HEAP IN A RESIDENT PROGRAM
 * ------------------------------------
 * Functions that use heap space require additional caution. The assembly
 * procedure GetResidentSize returns the amount of memory in paragraphs
 * required by the _TEXT and _DATA segments. It allows a C program to
 * discard segments unused during residency -- segments such as INSTALLCODE,
 * INSTALLDATA, and _STACK. It also truncates the memory occupied by the
 * program's heap.
 *
 * Therefore, if your program uses GetResidentSize to determine its memory
 * requirements, the resident portion of the program must not call functions
 * that make use of the heap. These include:
 *
 *     allocate functions such as malloc()
 *     strdup functions
 *     directory functions such as getcwd() and _getdcwd()
 *     miscellaneous functions such as _fullpath() and tempnam()
 *
 * Note that stream I/O functions such as fputs() also allocate heap space
 * unless a static buffer is provided through the function setvbuf().
 *
 * If you wish to make the heap resident, request a stack size large enough
 * to accommodate the installation code and no more. The _STACK segment
 * below the heap is wasted memory during the program's resident phase.
 *
 *
 * FLOATING-POINT CALCULATIONS
 * ---------------------------
 * For floating-point math operations, specify the alternate math package.
 * This prevents your program from setting up interrupt handlers at startup.
 *
 *
 * STACK-CHECKING
 * --------------
 * Turn off stack-checking for resident function(s) as follows:
 */

#pragma check_stack ( off )

/* This is necessary because the Activate procedure in HANDLERS.ASM
 * switches stacks. To adjust the size of the TSR's stack, reset the
 * constant STACK_SIZ in the file TSR.INC and rebuild the program by
 * assembling the HANDLERS.ASM module and relinking.
 */


/* Beeper - Writes ASCII character 07 (bell character) to the
 * screen to beep the speaker. Iterates BeepCount times.
 *
 * Params:  None
 *
 * Return:  None
 */
void far Beeper( void )
{
    int i;
    for( i = 0; i < BeepCount; ++i )
    {
        _asm
        {
            mov ax, 0E07h               ; Request function 0Eh
            int 10h                     ; Write char 7 (bell) to screen
        }
    }
}
