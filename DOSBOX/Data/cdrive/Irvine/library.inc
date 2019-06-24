; LIBRARY.INC - include file for Irvine.lib

extrn Clrscr:proc, Crlf:proc, Delay_seconds:proc, Get_time:proc, Gotoxy:proc, \
   Readchar:proc, Readkey:proc, Scroll:proc, Seconds_today:proc, Set_videoseg:proc

extrn Show_time:proc, Waitchar:proc, Writestring_direct:proc, Writechar_direct:proc, \
   PackedToBin:proc, Readint:proc, Readlong:proc, Writebcd:proc

extrn Writeint:proc, Writeint_signed:proc, Writelong:proc, Random_range:proc, \
   Random32:proc, Randomize:proc

extrn Readstring:proc, Str_copy:proc, Str_length:proc, Str_ucase:proc,   \
   Writestring:proc, Write_errorstr:proc

extrn DOS_error:proc, Seek_record:proc, Read_record:proc, \
   Seek_eof:proc, Create_file:proc, Open_infile:proc, \
   Open_outfile:proc, Close_file:proc
