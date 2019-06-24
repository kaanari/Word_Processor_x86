        .MODEL small, pascal, os_dos
        INCLUDE demo.inc
        .CODE

;* ReadCharAttr - Reads character and display attribute at cursor location.
;*
;* Shows:   BIOS Interrupt - 10h, Function 8 (Read Character and Attribute
;*                                at Cursor)
;*
;* Uses:    vconfig - Video configuration structure (initialized
;*          by calling the GetVidConfig procedure)
;*
;* Params:  Attr - Pointer to short integer for display attribute
;*
;* Return:  Short integer with ASCII value of character

ReadCharAttr PROC USES di,
        Attr:PWORD

        mov     ah, 8                   ; Function 8
        mov     bh, vconfig.dpage       ; Current page
        int     10h                     ; Read Character and Attribute
        sub     bh, bh
        mov     bl, ah                  ; BX = attribute
        cbw                             ; AX = character
        LoadPtr es, di, Attr            ; ES:DI = pointer to int
        mov     es:[di], bx             ; Copy attribute
        ret

ReadCharAttr ENDP


;* CopyFile - Copies a file from a specified directory to another. Allows
;* two different copy methods. See the OpenFile, CloseFile, ReadFile, and
;* WriteFile procedures for specific examples on opening, closing, reading
;* from, and writing to files.
;*
;* Shows:   DOS Functions - 3Ch (Create File)
;*                          5Bh (Create New File)
;*          Instruction - clc
;*
;* Params:  Imode  - 0 = Create new target file or overwrite existing file
;*                   1 = Abort and return error code if target file already
;*                       exists (for DOS versions 3.0 and higher only)
;*          Fspec1 - Pointer to ASCIIZ source file specification
;*          Fspec2 - Pointer to ASCIIZ target file specification
;*
;* Return:  Short integer with error code
;*          0 if successful
;*          1 if error

        .DATA
Buffer  BYTE    BUFFERSIZE DUP (?)     ; Buffer for diskette read

        .CODE

CopyFile PROC USES ds si di,
        Imode:WORD,
        Fspec1:PBYTE,
        Fspec2:PBYTE

        LOCAL eof_flag:BYTE

; Open source file for read only

        LoadPtr ds, dx, Fspec1          ; Point DS:DX to source file
        mov     ax, 3D00h               ; AH = function #, AL = access code
        int     21h                     ; Open file (for read only)
        jc      exit
        mov     si, ax                  ; SI = file handle for source

; Open target file according to copy mode

        LoadPtr ds, dx, Fspec2          ; Point DS:DX to target file
        .IF     Imode != 1              ; If Imode (DOS Function) is not 1
        mov     ah, 3Ch                 ; Request Create File
        .ELSE

        ; Check DOS version
        INVOKE  GetVer

        cmp     ax, 300                 ; 3.0 or higher?
        jb      close                   ; No?  Abort with error code
        mov     ah, 5Bh                 ; Request Create New File
        .ENDIF
        sub     cx, cx                  ; Normal attribute for target
        int     21h                     ; DOS function for target file
        jc      close                   ; If open error, abort
        mov     di, ax                  ; DI = file handle for target

; Both files successfully opened. Now read from source and copy to target.

        mov     ax, @data
        mov     ds, ax                  ; DS:DX = buffer. Read/write
        mov     dx, OFFSET Buffer       ;   to and from here.
        mov     eof_flag, 0             ; Initialize end-of-file flag

        .REPEAT
        mov     bx, si                  ; Handle for source file
        mov     cx, BUFFERSIZE          ; CX = number of bytes to read
        mov     ah, 3Fh                 ; Request DOS read
        int     21h                     ; Read from file
        jc      close                   ; If error, exit
        .IF     ax != cx                ; If all bytes not read,
        inc     eof_flag                ;   raise end-of-file flag
        .ENDIF                          ;   to end .REPEAT loop
        mov     bx, di                  ; Handle for target file
        mov     cx, ax                  ; Write number of bytes read
        mov     ah, 40h                 ; Request DOS write
        int     21h                     ; Write from buffer to target file
        jc      close                   ; If error, exit
        .UNTIL  eof_flag != 0           ; Loop to read next block
        clc                             ; Clear CY to indicate success
close:
        pushf                           ; Preserve flags while closing
        INVOKE  CloseFile,              ; Close source file
                si                      ; Handle for source
        INVOKE  CloseFile,              ; Close target file
                di                      ; Handle for target
        sub     ax, ax                  ; Error code = 0
        popf                            ; Recover flags
exit:
        .IF     carry?                  ; If carry set,
        mov     ax, 1                   ;   error code = 1
        .ENDIF
        ret

CopyFile ENDP


;* ChangeDrive - Changes default drive.
;*
;* Shows:   DOS Function - 0Eh (Select Disk)
;*
;* Params:  Drive - Uppercase letter designation for new drive
;*
;* Return:  None

ChangeDrive PROC,
        Drive:WORD

        mov     ah, 0Eh                 ; DOS Function 0Eh
        mov     dx, Drive               ; Drive designation in DL,
        sub     dl, 'A'                 ;   0=A, 1=B, 2=C, etc.
        int     21h                     ; Select Disk
        ret

ChangeDrive ENDP


;* GetCurDrive - Gets designation of current drive.
;*
;* Shows:   DOS Function - 19h (Get Current Disk)
;*          Instruction - cbw
;*
;* Params:  None
;*
;* Return:  Short integer with drive designation
;*          0 = A, 1 = B, 2 = C, etc.

GetCurDrive PROC

        mov     ah, 19h                 ; DOS Function 19h
        int     21h                     ; Get Current Disk
        cbw                             ; AX = drive designation
        ret

GetCurDrive ENDP


;* SetDTA - Sets address for new Disk Transfer Area.
;*
;* Shows:   DOS Function - 1Ah (Set DTA Address)
;*
;* Params:  Dta - Far pointer to new transfer address
;*
;* Return:  None

SetDTA  PROC USES ds,
        Dta:FPBYTE

        lds     dx, [Dta]               ; Point DS:DX to DTA
        mov     ah, 1Ah                 ; DOS Function 1Ah
        int     21h                     ; Set DTA Address
        ret

SetDTA  ENDP


;* GetDTA - Gets address of current Disk Transfer Area.
;*
;* Shows:   DOS Function - 2Fh (Get DTA Address)
;*
;* Params:  Dta - Far pointer to receive transfer address
;*
;* Return:  None

GetDTA  PROC,
        Dta:FPBYTE

        mov     ah, 2Fh                 ; DOS Function 2Fh
        int     21h                     ; Get DTA Address in ES:BX
        mov     ax, es                  ; Save DTA segment
        mov     dx, bx                  ; Save DTA offset
        les     bx, Dta                 ; Now ES:BX points to variable
        mov     es:[bx], dx             ; Copy DTA address to
        mov     es:[bx+2], ax           ;   dta variable
        ret

GetDTA  ENDP


;* CreateFile - Creates file with specified attribute.
;*
;* Shows:   DOS Function - 3Ch (Create File)
;*
;* Params:  Attr - Attribute code:  0 = normal        8 = volume label
;*                                  1 = read only    16 = subdirectory
;*                                  2 = hidden       32 = archive
;*                                  4 = system
;*          Fspec - Pointer to ASCIIZ file specification
;*
;* Return:  Short integer with file handle or -1 for error

CreateFile PROC USES ds,
        Attr:WORD, Fspec:PBYTE

        LoadPtr ds, dx, Fspec           ; Point DS:DX to file spec
        mov     cx, Attr                ; CX = attribute
        mov     ah, 3Ch                 ; AH = function number
        int     21h                     ; Create file
        .IF     carry?
        mov     ax, -1                  ; Set error code
        .ENDIF
        ret

CreateFile ENDP


;* OpenFile - Opens specified file for reading or writing. See the CopyFile
;* procedure for another example of using DOS Function 3Dh to open files.
;*
;* Shows:   DOS Function - 3Dh (Open File)
;*
;* Params:  Access - Access code:  0 = read    1 = write    2 = read/write
;*          Fspec - Pointer to ASCIIZ file specification
;*
;* Return:  Short integer with file handle or -1 for error

OpenFile PROC USES ds,
        Access:WORD, Fspec:PBYTE

        LoadPtr ds, dx, Fspec           ; Point DS:DX to file spec
        mov     ax, Access              ; AL = access code
        mov     ah, 3Dh                 ; AH = function number
        int     21h                     ; Open file
        .IF     carry?
        mov     ax, -1                  ; Set error code
        .ENDIF
        ret

OpenFile ENDP


;* CloseFile - Closes an open file specified by handle. See the CopyFile
;* procedure for another example of using DOS Function 3Eh to close files.
;*
;* Shows:   DOS Function - 3EH (Close File)
;*
;* Params:  Handle - File handle
;*
;* Return:  None

CloseFile PROC,
        Handle:WORD

        mov     bx, Handle              ; BX = file handle
        mov     ah, 3Eh                 ; DOS Function 3Eh
        int     21h                     ; Close file
        ret

CloseFile ENDP


;* ReadFile - Read from open file to specified buffer. See the CopyFile
;* procedure for another example of using DOS Function 3Fh to read files.
;*
;* Shows:   DOS Function - 3Fh (Read File or Device)
;*
;* Params:  Handle - File handle
;*          Len - Number of bytes to read
;*          Pbuff - Pointer to buffer
;*
;* Return:  Short integer with number of bytes read, or 0 if read error

ReadFile PROC USES ds di,
        Handle:WORD, Len:WORD, Pbuff:PBYTE

        LoadPtr ds, dx, Pbuff           ; Point DS:DX to buffer
        mov     di, dx                  ; Keep string offset in DI
        mov     bx, Handle              ; BX = handle
        mov     cx, Len                 ; CX = number of bytes to read
        mov     ah, 3Fh                 ; Request DOS read
        int     21h                     ; Read File
        .IF     carry?
        sub     ax, ax                  ; Set error code
        .ENDIF
        ret
        
ReadFile ENDP


;* WriteFile - Write ASCIIZ string to file. If Handle = 0, the string is
;* written to STDOUT (console). See the CopyFile procedure for another
;* example of using DOS Function 40h to write to files.
;*
;* Shows:   DOS Function - 40h (Write File or Device)
;*          Instructions - inc      dec
;*
;* Params:  Handle - File handle
;*          SPtr - Pointer to ASCIIZ string
;*
;* Return:  Short integer with error code
;*          0 if successful
;*          1 if write error
;*          2 if number of bytes written not equal to string length

WriteFile PROC USES ds di,
        Handle:WORD, Sptr:PBYTE

        LoadPtr es, di, Sptr            ; Point ES:DI to string
        push    di                      ; Hold on to string pointer
        mov     cx, -1                  ; Set CX to maximum
        sub     al, al                  ; AL = 0
        repne   scasb                   ; Scan string for NULL
        pop     dx                      ; Recover string pointer
        dec     di
        sub     di, dx                  ; Get string length (w/o NULL)
        mov     cx, di                  ; Put it into CX
        mov     bx, Handle              ; Load BX with handle
        push    es                      ; Set DS to ES to ensure
        pop     ds                      ;   DS:DX points to string
        mov     ah, 40h                 ; Request DOS write
        int     21h                     ; Write File or Device
        mov     bx, ax                  ; Get number of bytes written
        mov     ax, 0                   ; Set error code, preserve carry
        .IF     carry?                  ; If carry,
        inc     ax                      ;   increment once for write error
        .ENDIF  ; carry
        .IF     bx != cx                ; If bytes not all written,
        inc     ax                      ;   increment twice
        .ENDIF  ; bx ! cx
        ret

WriteFile ENDP


;* GetDiskSize - Gets size information from specified disk.
;*
;* Shows:   DOS Function - 36h (Get Drive Allocation Information)
;*
;* Params:  Drive - Drive code (0 = default, 1 = A, 2 = B, etc.)
;*          Disk  - Pointer to a structure with 4 short integer members:
;*                      Member 1 - Total clusters on disk
;*                      Member 2 - Number of available clusters
;*                      Member 3 - Sectors/cluster (-1 if invalid drive)
;*                      Member 4 - Bytes/sector
;*
;* Return:  None

GetDiskSize PROC USES di,
        Drive:WORD, Disk:PDISKSTAT

        mov     dx, Drive               ; DL = drive code
        mov     ah, 36h                 ; DOS Function 36h
        int     21h                     ; Get Drive Allocation Information
        LoadPtr es, di, Disk            ; ES:DI = disk structure
        mov     (DISKSTAT PTR es:[di]).\
                total, dx               ; DX = total clusters
        mov     (DISKSTAT PTR es:[di]).\
                avail, bx               ; BX = number of free clusters
        mov     (DISKSTAT PTR es:[di]).\
                sects, ax               ; AX = sectors/cluster
        mov     (DISKSTAT PTR es:[di]).\
                bytes, cx               ; CX = bytes/sector
        ret

GetDiskSize ENDP


;* MakeDir - Creates a specified subdirectory.
;*
;* Shows:   DOS Function - 39h (Create Directory)
;*
;* Params:  Pspec - Pointer to ASCIIZ pathname of new subdirectory
;*
;* Return:  Short integer with error code
;*          0 if successful
;*          1 if create error

MakeDir PROC USES ds,
        Pspec:PBYTE

        LoadPtr ds, dx, Pspec           ; Point DS:DX to path spec
        mov     ah, 39h                 ; DOS Function 39h
        int     21h                     ; Create Directory
        mov     ax, 0                   ; Set error code, keep flags
        .IF     carry?
        inc     ax                      ; Set error code to 1
        .ENDIF
        ret

MakeDir ENDP


;* RemoveDir - Removes a specified subdirectory.
;*
;* Shows:   DOS Function - 3Ah (Delete Directory)
;*
;* Params:  Pspec - Pointer to ASCIIZ pathname of subdirectory
;*
;* Return:  Short integer with error code
;*          0 if successful
;*          1 if delete error or subdirectory not empty

RemoveDir PROC USES ds,
        Pspec:PBYTE

        LoadPtr ds, dx, Pspec           ; Point DS:DX to path spec
        mov     ah, 3Ah                 ; DOS Function 3Ah
        int     21h                     ; Delete Directory
        mov     ax, 0                   ; Set error code, keep flags
        .IF     carry?
        inc     ax                      ; Set error code to 1
        .ENDIF
        ret

RemoveDir ENDP


;* ChangeDir - Changes current (default) directory.
;*
;* Shows:   DOS Function - 3Bh (Set Current Directory)
;*
;* Params:  Pspec - Pointer to ASCIIZ pathname of target subdirectory
;*
;* Return:  Short integer with error code
;*          0 if successful
;*          1 if delete error or subdirectory not empty

ChangeDir PROC USES ds,
        Pspec:PBYTE

        LoadPtr ds, dx, Pspec           ; Point DS:DX to path spec
        mov     ah, 3Bh                 ; DOS Function 3Bh
        int     21h                     ; Set Current Directory
        mov     ax, 0                   ; Set error code, keep flags
        .IF     carry?
        inc     ax                      ; Set error code to 1
        .ENDIF
        ret

ChangeDir ENDP


;* DelFile - Deletes a specified file.
;*
;* Shows:   DOS Function - 41h (Delete File)
;*
;* Params:  Fspec - Pointer to ASCIIZ file specification
;*
;* Return:  Short integer with error code
;*          0 if successful
;*          1 if delete error

DelFile PROC USES ds,
        Fspec:PBYTE

        LoadPtr ds, dx, Fspec           ; Point DS:DX to file spec
        mov     ah, 41h                 ; DOS Function 41h
        int     21h                     ; Delete File
        mov     ax, 0                   ; Set error code, keep flags
        .IF     carry?
        inc     ax                      ; Set error code to 1
        .ENDIF
        ret

DelFile ENDP


;* Rewind - Rewinds an open file specified by handle. See the GetFileSize
;* procedure for an example of using Function 42h to determine file size.
;*
;* Shows:   DOS Function - 42h (Set File Pointer)
;*
;* Params:  Handle - File handle
;*
;* Return:  None

Rewind  PROC,
        Handle:WORD

        mov     bx, Handle              ; BX = file handle
        mov     ax, 4200h               ; AH = function #,
                                        ; AL = move to beginning of
        sub     cx, cx                  ;      file plus offset
        sub     dx, dx                  ; CX:DX = offset (zero)
        int     21h                     ; Set File Pointer
        ret

Rewind  ENDP


;* GetFileSize - Gets the size of an open file specified by handle.
;*
;* Shows:   DOS Function - 42h (Set File Pointer)
;*
;* Params:  Handle - File handle
;*
;* Return:  Long integer with file size in bytes

GetFileSize PROC,
        Handle:WORD

        mov     bx, Handle              ; BX = file handle
        mov     ax, 4202h               ; AH = function #,
                                        ; AL = move to end of
        sub     cx, cx                  ;      file plus offset
        sub     dx, dx                  ; CX:DX = offset (zero)
        int     21h                     ; Set File Pointer
        mov     ax, dx                  ; Set DX:AX = file size in
        mov     dx, cx                  ;   bytes, return long int
        ret

GetFileSize ENDP


;* GetAttribute - Gets the attribute(s) of a specified file.
;*
;* Shows:   DOS Function - 43h (Get or Set File Attributes)
;*
;* Params:  Fspec - Pointer to ASCIIZ file specification
;*
;* Return:  Short integer with file attribute bits set as follows:
;*                bit 0 = read only              bit 3 = volume label
;*                bit 1 = hidden                 bit 4 = subdirectory
;*                bit 2 = system                 bit 5 = archive
;*          0 indicates normal data file
;*          -1 indicates error

GetAttribute PROC USES ds,
        Fspec:PBYTE

        LoadPtr ds, dx, Fspec           ; DS:DX = file specification
        mov     ax, 4300h               ; AH = function #
                                        ; AL = 0 (return attribute)
        int     21h                     ; Get File Attributes
        mov     ax, -1                  ; Set code, keep flags
        .IF     !carry?
        mov     ax, cx                  ; Return with file attribute bits
        .ENDIF
        ret

GetAttribute ENDP


;* SetAttribute - Sets the attribute(s) of a specified file.
;*
;* Shows:   DOS Function - 43h (Get or Set File Attributes)
;*
;* Params:  Attr - Attribute bits set as follows:
;*                        bit 0 = read only      bit 3 = volume label
;*                        bit 1 = hidden         bit 4 = subdirectory
;*                        bit 2 = system         bit 5 = archive
;*                 (Attr = 0 for normal data file)
;*          Fspec - Pointer to ASCIIZ file specification
;*
;* Return:  Short integer with error code
;*          0 if successful
;*          1 if delete error

SetAttribute PROC USES ds,
        Attr:WORD,
        Fspec:PBYTE

        LoadPtr ds, dx, Fspec           ; DS:DX = file specification
        mov     cx, Attr                ; Put attribute code in CX
        mov     ax, 4301h               ; AH = function #
                                        ; AL = 1 (set attribute)
        int     21h                     ; Set File Attributes
        mov     ax, 0                   ; Clear code, keep flags
        .IF     carry?
        inc     ax                      ; Set error code to 1
        .ENDIF
        ret

SetAttribute ENDP


;* GetCurDir - Gets the current directory of default drive.
;*
;* Shows:   DOS Function - 47h (Get Current Directory)
;*
;* Params:  Spec - Pointer to 64-byte buffer to receive directory
;*          path. Path terminates with 0 but does not include
;*          drive and does not begin with backslash.
;*
;* Return:  Short integer with error code
;*          0 if successful
;*          1 if delete error or subdirectory not empty

GetCurDir PROC USES ds si,
        Spec:PBYTE

        LoadPtr ds, si, Spec            ; DS:SI = spec address
        mov     ah, 47h                 ; AH = function number
        sub     dl, dl                  ; DL = current drive (0)
        int     21h                     ; Get Current Directory
        mov     ax, 0                   ; Set error code, keep flags
        .IF     carry?
        inc     ax                      ; Set error code to 1
        .ENDIF
        ret

GetCurDir ENDP


;* FindFirst - Finds first entry in given directory matching specification.
;*
;* Shows:   DOS Function - 4Eh (Find First File)
;*          Instructions - pushf    popf
;*
;* Params:  Attr - Attribute code (see header comments for CreateFile)
;*          Fspec - Pointer to ASCIIZ file specification
;*          Finfo - Pointer to 43-byte buffer to receive
;*                      data from matched entry
;*
;* Return:  Short integer with error code
;*          0 if successful
;*          1 if no match found

        .DATA
OldDta  FPVOID  ?                       ; Storage for old DTA address

        .CODE

FindFirst PROC USES ds,
        Attr:WORD,
        Fspec:PBYTE,
        Finfo:PFILEINFO

        ; Get current DTA address, pass address of pointer to hold value
        INVOKE  GetDTA,
                ADDR OldDta

        mov     cx, Attr                ; Load CX with file attribute

        ; Set DTA address, pass pointer to structure
        INVOKE  SetDTA,
                Finfo

        LoadPtr ds, dx, Fspec           ; Point DS:DX to file spec
        mov     ah, 4Eh                 ; AH = function number
        int     21h                     ; Find First File

        pushf                           ; Preserve flags

        ; Restore DTA address, pass pointer
        INVOKE  SetDTA,
                OldDta

        sub     ax, ax                  ; Set error code
        popf                            ; Recover flags
        .IF     carry?
        inc     ax                      ; Set error code to 1
        .ENDIF
        ret

FindFirst ENDP


;* FindNext - Finds next entry in given directory matching specification.
;* (Should be called only after successfully calling the FindFirst procedure.)
;*
;* Shows:   DOS Function - 4Fh (Find Next File)
;*          Operator - OFFSET
;*
;* Params:  Finfo - Pointer to 43-byte buffer. This must be the same buffer
;*                      (or a duplicate) returned from the FindFirst procedure.
;*
;* Return:  Short integer with error code
;*          0 if successful
;*          1 if no more matches found

FindNext PROC USES ds,
        Finfo:PFILEINFO

        ; Get current DTA address, pass address of pointer to hold value
        INVOKE  GetDTA,
                ADDR OldDta

        ; Set DTA address, pass pointer to structure
        INVOKE  SetDTA,
                Finfo

        mov     ah, 4Fh                 ; AH = function number
        int     21h                     ; Find Next File

        pushf                           ; Preserve flags

        ; Restore DTA address, pass pointer
        INVOKE  SetDTA,
                OldDta

        sub     ax, ax                  ; Set error code
        popf                            ; Recover flags
        .IF     carry?
        inc     ax                      ; Set error code to 1
        .ENDIF
        ret

FindNext ENDP


;* RenameFile - Renames specified file.
;*
;* Shows:   DOS Function - 56h (Rename File)
;*
;* Params:  Fspec1 - Pointer to old ASCIIZ file specification
;*          Fspec2 - Pointer to new ASCIIZ file specification
;*
;*          The drive must be the same for both arguments, but the path
;*          does not. This allows files to be moved between directories.
;*
;* Return:  Short integer with error code
;*          0 if successful
;*          1 if error

RenameFile PROC USES ds di,
        Fspec1:PBYTE,
        Fspec2:PBYTE

        LoadPtr ds, dx, Fspec1          ; Point DS:DX to old file spec
        LoadPtr es, di, Fspec2          ; Point ES:DI to new file spec
        mov     ah, 56h                 ; AH = function number
        int     21h                     ; Rename File
        mov     ax, 0                   ; Clear error code, keep flags
        .IF     carry?
        inc     ax                      ; Set error code to 1
        .ENDIF
        ret

RenameFile ENDP


;* GetFileTime - Gets date/time for open file specified by handle.
;*
;* Shows:   DOS Function - 57h (Get or Set File Date and Time)
;*          Instructions - shl     shr
;*
;* Params:  Handle - Handle of open file
;*          Sptr - Pointer to 18-byte buffer to receive date/time
;*
;* Return:  Short integer with error code
;*          0 if successful
;*          1 if error

GetFileTime PROC USES di,
        Handle:WORD,
        Sptr:PBYTE

        mov     ax, 5700h               ; AH = function number
                                        ; AL = get request
        mov     bx, Handle              ; BX = file handle
        int     21h                     ; Get File Date and Time
        mov     ax, 1                   ; Set error code, keep flags
        .IF     !carry?                 ; If not carry, continue
        mov     bx, cx                  ; Else save time in BX
        mov     al, bl                  ; Get low byte of time
        and     al, 00011111y           ; Mask to get 2-second incrs,
        shl     al, 1                   ;   convert to seconds
        push    ax                      ; Save seconds
        mov     cl, 5
        shr     bx, cl                  ; Shift minutes into low byte
        mov     al, bl                  ; Get new low byte
        and     al, 00111111y           ; Mask to get minutes
        push    ax                      ; Save minutes
        mov     cl, 6
        shr     bx, cl                  ; Shift hours into low byte
        push    bx                      ; Save hours

        mov     bl, dl                  ; Get low byte of date
        and     bl, 00011111y           ; Mask to get day in BX
        mov     cl, 5
        shr     dx, cl                  ; Shift month into low byte
        mov     al, dl                  ; Get new low byte
        and     al, 00001111y           ; Mask to get month
        mov     cl, 4
        shr     dx, cl                  ; Shift year into low byte
        add     dx, 80                  ; Year is relative to 1980
        push    dx                      ; Save year
        push    bx                      ; Save day
        push    ax                      ; Save month

        LoadPtr es, di, Sptr            ; Point ES:DI to 18-byte
        mov     cx, 6                   ;   string

        .REPEAT
        pop     ax                      ; Get 6 numbers sequentially in AL
        aam                             ; Convert to unpacked BCD
        xchg    al, ah                  ; Switch bytes for word move
        or      ax, '00'                ; Make ASCII numerals
        stosw                           ; Copy to string
        mov     al, '-'                 ; Separator for date text
        cmp     cl, 4                   ; First 3 iters are for date
        jg      @F                      ; If CX=6 or 5, insert hyphen
        mov     al, ' '                 ; Separator date and time
        je      @F                      ; If CX = 4, insert hyphen
        mov     al, ':'                 ; Separator for time text
        .IF     cl != 1
@@:     stosb                           ; Copy separator to string
        .ENDIF
        .UNTILCXZ

        sub     ax, ax                  ; Clear return code
        stosb                           ; Terminate string with null
        .ENDIF                          ;   to make ASCIIZ
        ret

GetFileTime ENDP


;* UniqueFile - Creates and opens a new file with a name unique to the
;* specified directory. The name is manufactured from the current time,
;* making it useful for temporary files. For DOS versions 3.0 and higher.
;*
;* Shows:   DOS Function - 5Ah (Create Temporary File)
;*
;* Params:  Attr - Attribute code (see header comments for CreateFile)
;*          Pspec - Pointer to ASCIIZ path specification
;*
;* Return:  Short integer with file handle or -1 for error

UniqueFile PROC USES ds,
        Attr:WORD,
        Pspec:PBYTE

        ; Get DOS version
        INVOKE  GetVer

        cmp     ax, 300                 ; 3.0 or higher?
        jb      e_exit                  ; No?  Quit with error
        LoadPtr ds, dx, Pspec           ; Point DS:DX to path spec
        mov     cx, Attr                ; CX = attribute
        mov     ah, 5Ah                 ; AH = function number
        int     21h                     ; Create Temporary File
        .IF     carry?
e_exit: mov     ax, -1                  ; Set error code
        .ENDIF
        ret

UniqueFile ENDP


;* CreateNewFile - Creates a new file with specified attribute. Differs
;* from the CreateFile procedure in that it returns an error if file
;* already exists. For DOS versions 3.0 and higher.
;*
;* Shows:   DOS Function - 5Bh (Create New File)
;*
;* Params:  Attr - Attribute code (see header comments for CreateFile)
;*          Fspec - Pointer to ASCIIZ file specification
;*
;* Return:  Short integer with file handle or -1 for error

CreateNewFile PROC USES ds,
        Attr:WORD,
        Fspec:PBYTE

        LoadPtr ds, dx, Fspec           ; Point DS:DX to file spec
        mov     cx, Attr                ; CX = attribute
        mov     ah, 5Bh                 ; AH = function number
        int     21h                     ; Create New File
        .IF     carry?
        mov     ax, -1                  ; Set error code
        .ENDIF
        ret

CreateNewFile ENDP


;* StrCompare - Compares two strings for equality. See StrWrite, StrFindChar,
;* WinOpen, and WinClose procedures for other examples of string instructions.
;*
;* Shows:   Instructions - cmpsb     cmpsw     repe     jcxz
;*
;* Params:  Sptr1 - Pointer to first string
;*          Sptr2 - Pointer to second string
;*          Len  - Length in bytes for comparison. Strings need not be of
;*                 equal length; however if len is an even number, comparison
;*                 is made on a word-by-word basis and thus is more efficient.
;*
;* Return:  Null pointer if strings match; else pointer to string #1 where
;*          match failed.

StrCompare PROC USES ds di si,
        Sptr1:PBYTE,
        Sptr2:PBYTE,
        Len:WORD

        LoadPtr es, di, Sptr1           ; ES:DI points to string #1
        LoadPtr ds, si, Sptr2           ; DS:SI points to string #2
        mov     cx, Len                 ; Length of search in bytes
        and     al, 0                   ; Set ZR flag in case CX = 0
        .IF     cx != 0                 ; If length is not 0:
        .IF     !(cl & 1)               ; If not even number,
        repe    cmpsb                   ;   compare byte-by-byte
        .ELSE                           ; Else compare word-by-word
        shr     cx, 1                   ; Decrease count by half
        repe    cmpsw                   ; Compare word-by-word
        sub     di, 2                   ; Back up 2 characters
        sub     si, 2
        cmpsb                           ; Match?
        .IF     zero?                   ; No?  Then failure
        cmpsb                           ; Compare last characters
        .ENDIF  ; zero
        .ENDIF  ; cl & 1
        .ENDIF  ; cx != 0

        mov     ax, 0                   ; Set null pointer without
        mov     dx, 0                   ;   disturbing flags
        .IF     !zero?                  ; If no match,
        dec     di                      ;   point to failure
        mov     ax, di
        mov     dx, es
        .ENDIF
        ret

StrCompare ENDP


;* StrFindChar - Finds first occurrence of character in given ASCIIZ string,
;* searching either from beginning or end of string. See StrWrite, WinOpen,
;* WinClose, and StrCompare procedures for other examples of string
;* instructions.
;*
;* Shows:   Instructions - repne     scasb    cld     std
;*
;* Params:  Ichar - Character to search for
;*          Sptr - Pointer to ASCIIZ string in which to search
;*          Direct - Direction flag:
;*                       0 = search from start to end
;*                       1 = search from end to start
;*
;* Return:  Null pointer if character not found, else pointer to string where
;*          character first encountered

StrFindChar PROC USES ds di si,
        IChar:SBYTE,
        Sptr:PBYTE,
        Direct:WORD

        LoadPtr es, di, Sptr            ; ES:DI points to string
        LoadPtr ds, si, Sptr            ;   as does DS:SI
        mov     cx, -1                  ; Set scan counter to maximum
        mov     bx, cx                  ; BX = max string tail
        cld                             ; Assume head-to-tail search

        .IF     Direct != 0             ; If assumption correct:
        mov     bx, di                  ; Set BX to byte before
        dec     bx                      ;   string head and scan
        sub     al, al                  ;   string for null terminator
        push    cx                      ;   to find string tail
        repne   scasb
        pop     cx                      ; Recover scan counter
        dec     di                      ; Backup pointer to last
        dec     di                      ;   character in string and
        mov     si, di                  ;   begin search from there
        std                             ; Set direction flag
        .ENDIF

        .REPEAT
        lodsb                           ; Get first char from string
        .IF     (si == bx) || (al == 0) ; If at head or tail limit,
        sub     ax, ax                  ;   no match
        sub     dx, dx                  ; Set null pointer
        jmp     exit
        .ENDIF
        .UNTILCXZ al == IChar

        mov     ax, si                  ; Match, so point to first
        dec     ax                      ;   occurrence
        .IF     Direct != 0             ; If head-to-tail search:
        inc     ax                      ; Adjust pointer forward
        inc     ax
        mov     dx, ds                  ; Pointer segment
        .ENDIF
exit:
        ret

StrFindChar ENDP


;* GetStr - Gets a string of up to 128 characters from the user. Since
;* this function uses the DOS input mechanism, it can use the DOS editing
;* keys or the keys of a DOS command-line editor if one is loaded.
;*
;* Shows:   DOS Function - 0Ah (Buffered Keyboard Input)
;*          Directive    - EQU
;*
;* Params:  Strbuf - Pointer to area where input string will be placed
;*          Maxlen - Maximum length (up to 128 characters) of string
;*
;* Return:  0 if successful, 1 if error (Maxlen is too long)

        .DATA
MAXSTR  EQU     128
max     BYTE    MAXSTR
actual  BYTE    ?
string  BYTE    MAXSTR DUP (?)

        .CODE
GetStr  PROC USES si di,
        Strbuf:PBYTE,
        Maxlen:WORD

        mov     ax, 1                   ; Assume error
        mov     cx, Maxlen              ; Copy length to register

        .IF (cx != 0) && (cx <= MAXSTR) ; Error if 0 or too long
        mov     max, cl                 ; Load maximum length
        mov     ah, 0Ah                 ; Request DOS Function 0Ah
        mov     dx, OFFSET max          ; Load offset of string
        int     21h                     ; Buffered Keyboard Input

        mov     bl, actual              ; Put number of characters read
        sub     bh, bh                  ;   in BX
        mov     string[bx], 0           ; Null-terminate string
        mov     cx, bx                  ; Put count in CX
        inc     cx                      ; Plus one for the null terminator

        LoadPtr es, di, Strbuf          ; ES:DI points to destination buffer
        mov     si, OFFSET string       ; DS:SI points to source string
        rep     movsb                   ; Copy source to destination
        sub     ax, ax                  ; Return 0 for success
        .ENDIF

        ret

GetStr  ENDP

        END
