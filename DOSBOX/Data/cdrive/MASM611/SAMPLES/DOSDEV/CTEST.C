/*
 * CTEST.C
 *
 * Sample program that uses the Atoms Device Driver (ATMS).
 * The program displays a menu from which you can Write only, Read only,
 * or Quit. Any other key will cause the program to go into the 'Input->
 * Return' mode: It will asked the user for input strings, write them to
 * the device, and immediately read back from the device. To get out of
 * this mode, press return and the menu will come up again
 *
 *	To communicate with the ATMS driver, we first open it as if it were
 * a file, using _sopen. The system will return a handle, with which,
 *	we can begin communicating to the driver.
 *
 *	By passing a null terminated string to _write, you can do the following 
 *        if string =  '<variable>', search for <variable>
 *        if string =  '<variable>=' delete <variable>
 *        if string =  '<variable>=value' insert <variable>
 * This allows us to 'browse' the data stored by ATMS.
 *
 * Calling _read will return the current <variable> text.
 *
 */

#include <stdio.h>
#include <dos.h>
#include <share.h>
#include <fcntl.h>

#define LENGTH 140				// defining the length of the buffers	
#define inLen LENGTH
#define outLen LENGTH
char InBuffer[LENGTH];  		// holds data from keyboard
char OutBuffer[LENGTH];			// holds data from device
  
void 	set_raw_mode(int handle),
		display_menu(int handle),
	  	do_write(int handle),
	  	do_read(int handle),
	  	test_result(int value);


/*
 * main
 *
 * open the device (with sopen, to allow more than one program to open the
 * device at the same time). Set raw mode. Display the menu, allow the user
 * to start there. The infinite loop goes like this: print the input prompt,
 * accept a string from the user. (see do_write below). If count=1, means that
 * only a 'cr' was inputed, so do the menu again. Otherwise, write to the
 * device, first eliminating the last 'cr', and read back from the device.
 * print out what we read from the device. continue the loop.
 */

main(int argc, char **argv, char **envp)
{
	int count, handle, index;	/* count holds length of keyboard input string,
										   handle holds assigned handle to the device */
			
	test_result(handle=_sopen("ATMS",_O_RDWR | _O_BINARY, _SH_DENYNO));
   set_raw_mode(handle);	 /* necessary only if not linking to binmode.obj */


	/* Insert the environment elements */

	for (index=0;envp[index]!=NULL;index++)
	{
		printf("%s\n",envp[index]);
		test_result(_write(handle,envp[index],strlen(envp[index])));
	}	

	/* Insert the command line arguments */
	
	for (index=1; index<argc; index++)
	{
		printf("%s\n",argv[index]);
		test_result(_write(handle,argv[index],strlen(argv[index])));
	}

	display_menu(handle);

	for (;;) 
	{
		printf("Input? ");      
		test_result(count=_read(0,OutBuffer,outLen));
		if (count==1)
			display_menu(handle);
		else
			{
				OutBuffer[--count] = 0;
				test_result(_write(handle,OutBuffer,outLen));
				do_read(handle);
			}
	}

}

/*
 * do_write
 *
 * print the Input prompt. Read from the keyboard. We can't do a scanf
 * because we want to be able to accept white space in the variable values
 * then set the last character of the buffer (which would be a carriage 
 * return, to be null terminated, a 0. If we didn't do that, then variable
 * values would finish with a cr, as would variable names in a search.
 * finally, write the result to the device
 */
 
void do_write(int handle)
{
	int count;

	printf("Input? ");      
	test_result(count=_read(0,OutBuffer,outLen));
	OutBuffer[--count] = 0;
	test_result(_write(handle,OutBuffer,outLen));
}

/*
 * do_read
 *
 *	read from the device into the InBuffer, which has inLen.
 * count will hold the actual number of bytes transferred.
 * print the input buffer out. since count from read include the '\0',
 * decrement count before printing it.
 */

void do_read(int handle)
{
	int count;
	
	test_result(count=_read(handle,InBuffer,inLen));
	printf("\nReturn(%d): %s\n\n",--count,InBuffer);
}

/*
 *	display_menu
 *
 * Displays the simple menu, waits for a character. If 1 or 2, do a Write or
 * a Read only. 0 closes the device and quits. Any other key, return
 */

void display_menu(int handle)
{
	static char *menu ="\n\tATMS device driver Sample\n\tSelect Device Function\
\n\n\t1. Write to Device Only\n\t2. Read from Device Only\n\t0. Quit\n\
\tOther Keys: Write & Read\n\t\t    Until Return\n";
	char ch;

	printf("%s",menu);

	for (;;)
	{
	printf("\n	  Please press a key: ");
	ch=getch();
	printf("%c \n\n",ch);
	switch (ch)
		{
	      case '0':
				test_result(_close(handle));
				exit(0);
				break;
			 case '1':
				do_write(handle);
				break;
			 case '2':
				do_read(handle);
				break;
			default:
				return;
		}
	}
}

/* 
 * test_result
 *
 * since there are so many places that error-checking has to be performed,
 * calling this routine automatically does it, and if there's an error it
 * displays the error string, and exits the program
 */

void test_result(int value)
{
	if (value == -1)					// a value of -1 always indicates error
		{
			perror("ATMS Error");	// using perror display a user-friendly string
			exit(value);
		}
}

/*
 * set_raw_mode
 *
 * cooked (sometimes called text) mode send data to the device one character
 * at a time. we need to be in raw mode. a low-level interrupt accomplishes 
 * this. this is also an example of how to use DOS interrupts in your code
 * the definitions for this routine are in dos.h
 * 
 * this is faster and smaller than linking with binmode.obj
 */ 

void set_raw_mode(int handle)
{
	union REGS regs;

	regs.x.ax=0x4401;					// set to function 0x4401: Set Device Data
	regs.x.bx=handle;					// bx has the handle of the device
	regs.x.dx=0x00a0;					// dx sets bits 7 & 5: device + raw mode
	intdos(&regs,&regs);				// do the interrupt with the registers in regs
											// and the output will also be in regs.	
}

