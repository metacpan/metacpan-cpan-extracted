/*
        +==========================================================+
        |                                                          |
        |              ODBC extension for Win32 Perl               |
        |              -----------------------------               |
        |                                                          |
        |            by Dave Roth (rothd@infowire.com)             |
        |                                                          |
        |                  version v960522 (hack)                  |
        |                                                          |
        |    Copyright (c) 1996 Dave Roth. All rights reserved.    |
        |   This program is free software; you can redistribute    |
        | it and/or modify it under the same terms as Perl itself. |
        |                                                          |
        +==========================================================+


          based on original code by Dan DeMaggio (dmag@umich.edu)

   Use under GNU General Public License or Larry Wall's "Artistic License"
*/

#define WIN32_LEAN_AND_MEAN
#include <stdlib.h>
#include <math.h>
#include <windows.h>

#if defined(__cplusplus)
extern "C" {
#endif

#include <EXTERN.h>
#include "perl.h"
#include "XSub.h"
#include "patchlevel.h"

#if (PATCHLEVEL < 5) && !defined(PL_sv_undef)
# define PL_sv_undef sv_undef
#endif

#if defined(__cplusplus)
}
#endif

#include "cpipe.hpp"
#include "pipe.h"

char gszError[ERROR_TEXT_SIZE];
int	giError = 0;



/*----------------------- P E R L   F U N C T I O N S -------------------*/

// constant function for exporting NT definitions.
static long constant(char *name)
{
    errno = 0;
    switch (*name) {
        case 'A':
			break;
    	case 'B':
			break;
    	case 'C':
			break;
    	case 'D':
            if (strEQ(name, "DEFAULT_WAIT_TIME"))
#ifdef DEFAULT_WAIT_TIME
                return DEFAULT_WAIT_TIME;
#else
            goto not_there;
#endif
			break;
    	case 'E':
			break;
	    case 'F':
			break;
	    case 'G':
			break;
	    case 'H':
			break;
	    case 'I':
			break;
	    case 'J':
			break;
	    case 'K':
			break;
	    case 'L':
			break;
	    case 'M':
			break;
	    case 'N':
			break;
	    case 'O':
			break;
	    case 'P':
			break;
	    case 'Q':
			break;
	    case 'R':
			break;
	    case 'S':
 			break;
	    case 'T':
			break;
	    case 'U':
			break;
	    case 'V':
			break;
	    case 'W':
			break;
	    case 'X':
			break;
	    case 'Y':
			break;
	    case 'Z':
			break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

XS(XS_WIN32__Pipe_Constant)
{
	dXSARGS;
	if (items != 2)
	{
		croak("Usage: Win23::Pipe::Constant(name, arg)\n");
    }
	{
	        STRLEN n_a;
		char* name = (char*)SvPV(ST(0),n_a);
		ST(0) = sv_newmortal();
		sv_setiv(ST(0), constant(name));
	}
	XSRETURN(1);
}


/*----------------------- M I S C   F U N C T I O N S -------------------*/
int	Error(int iErrorNum, char *szErrorText){
	strncpy((char *)gszError, szErrorText, ERROR_TEXT_SIZE);
	gszError[ERROR_TEXT_SIZE] = '\0';
	giError = iErrorNum;
	return giError;
}		


/*------------------- P E R L   O D B C   F U N C T I O N S ---------------*/

XS(XS_WIN32__Pipe_Create)
{
	dXSARGS;
	
	UCHAR	*szName = 0;
	DWORD	dWait = DEFAULT_WAIT_TIME;
	CPipe	*Pipe = 0;
	STRLEN  n_a;

	if(items != 2){
		CROAK("usage: Create(\"$Name\", $TimeToWait);\n");
	}
	szName = (UCHAR *)SvPV(ST(0), n_a);
	dWait = (DWORD)SvIV(ST(1));

	PUSHMARK(sp);

	if (strlen((const char *)szName) > 255){
		Error(ERROR_NAME_TOO_LONG);
	}else{
		Pipe = new CPipe((char *)szName, dWait);
	}

	if (Pipe){
		if (Pipe->iError){
			giError = Pipe->iError;
			strcpy(gszError, (const char *)Pipe->szError);
			delete Pipe;
			Pipe = 0;
		}
	}
	if (Pipe){ // everything is happy
#ifdef _WIN64
		XPUSHs(sv_2mortal(newSViv((DWORD_PTR)Pipe)));
#else
		XPUSHs(sv_2mortal(newSViv((DWORD)Pipe)));
#endif
	}else{
		XPUSHs(sv_2mortal(newSViv(0)));
	}
	PUTBACK;
} 

XS(XS_WIN32__Pipe_Close)
{
	dXSARGS;
	CPipe	*Pipe;

	if(items != 1){
		CROAK("usage: Close($PipeHandle);\n");
	}
	Pipe = INT2PTR(class CPipe *, SvIV(ST(0)));

	PUSHMARK(sp);
	
	if (Pipe){
		delete Pipe;
	}

	XPUSHs(sv_2mortal(newSViv(0)));
	PUTBACK;
} 

XS(XS_WIN32__Pipe_Write)
{
	dXSARGS;
	CPipe	*Pipe = 0;
	void	*vpData = 0;
	int		iResult = 0;
	STRLEN	dDataLen;

	if(items != 2){
		CROAK("usage: Write($PipeHandle, $Data);\n");
	}
	Pipe = INT2PTR(class CPipe *, SvIV(ST(0)));
	vpData = (void *)SvPV(ST(1), dDataLen);

	PUSHMARK(sp);
	
	if (Pipe){
		iResult = Pipe->Write((void *)vpData, (DWORD)dDataLen);
	}

	XPUSHs(sv_2mortal(newSViv(iResult)));
	PUTBACK;
} 

XS(XS_WIN32__Pipe_Read)
{
	dXSARGS;
	CPipe	*Pipe = 0;
	int		iFlag = 1;
	DWORD	dLen = 0;
	void	*vpData = 0;

	if(items != 1){
		CROAK("usage: Read($PipeHandle);\n");
	}
	Pipe = INT2PTR(class CPipe *, SvIV(ST(0)));

	PUSHMARK(sp);
	
	if (Pipe){
		while(iFlag){
			vpData = Pipe->Read(&dLen);
			iFlag = 0;				
				//	If we have more data to read then for God's sake, do it!

				//	I don't know if this will work ... it would return an
				//	array. This may not be good. Hmmmm.
			if(!vpData && GetLastError() == ERROR_MORE_DATA){
				iFlag = 1;
			}				

			if(dLen){
				XPUSHs(sv_2mortal(newSVpv((char *)vpData, dLen)));
			}else{
				sv_setsv(ST(0), (SV*) &PL_sv_undef);
			}
		}
	}
	PUTBACK;
} 

XS(XS_WIN32__Pipe_Connect)
{
	dXSARGS;
	CPipe	*Pipe;
	int		iResult = 0;

	if(items != 1){
		CROAK("usage: Connect($PipeHandle);\n");
	}
	Pipe = INT2PTR(class CPipe *, SvIV(ST(0)));

	PUSHMARK(sp);
	
	if (Pipe){
		iResult = Pipe->Connect();
	}

	XPUSHs(sv_2mortal(newSViv((long)iResult)));
	PUTBACK;
} 

XS(XS_WIN32__Pipe_Disconnect)
{
	dXSARGS;
	CPipe	*Pipe;
	int		iResult = 0;
	int		iPurge = 0;

	if(items > 0 && items < 3){
		CROAK("usage: Disconnect($PipeHandle [, $iPurge]);\n");
	}
	Pipe = INT2PTR(class CPipe *, SvIV(ST(0)));
	if (items == 2){
		iPurge = (int) SvIV(ST(1));
	}

	PUSHMARK(sp);
	
	if (Pipe){
		iResult = Pipe->Disconnect(iPurge);
	}

	XPUSHs(sv_2mortal(newSViv((long)iResult)));
	PUTBACK;
} 

XS(XS_WIN32__Pipe_ResizeBuffer)
{
	dXSARGS;
	CPipe	*Pipe = 0;
	DWORD	dResult = 0;
	DWORD	dSize;
	
	if(items != 2){
		CROAK("usage: ResizeBuffer($PipeHandle, $Size);\n");
	}
	Pipe = INT2PTR(class CPipe *, SvIV(ST(0)));
	dSize = (DWORD)SvIV(ST(1));

	PUSHMARK(sp);
	
	if (Pipe){
		dResult = Pipe->ResizeBuffer(dSize);
	}

	XPUSHs(sv_2mortal(newSViv((long)dResult)));
	PUTBACK;
} 

XS(XS_WIN32__Pipe_BufferSize)
{
	dXSARGS;
	CPipe	*Pipe = 0;
	DWORD	dResult = 0;
	
	if(items != 1){
		CROAK("usage: BufferSize($PipeHandle);\n");
	}
	Pipe = INT2PTR(class CPipe *, SvIV(ST(0)));

	PUSHMARK(sp);
	
	if (Pipe){
		dResult = Pipe->BufferSize();
	}

	XPUSHs(sv_2mortal(newSViv((long)dResult)));
	PUTBACK;
} 


XS(XS_WIN32__Pipe_Error)
{
	dXSARGS;
	CPipe	*Pipe = 0;
	int		iResult = 0;
	char	*szError = 0;
	int		iError = 0;
	
	if(items > 1){
		CROAK("usage: Error([$PipeHandle]);\n");
	}
	if (items == 1){
		Pipe = INT2PTR(class CPipe *, SvIV(ST(0)));
	}

	PUSHMARK(sp);
	
	if (Pipe){
		iError = Pipe->iError;
		szError = (char *)Pipe->szError;
	}else{
		iError = giError;
		szError = gszError;
	}

	XPUSHs(sv_2mortal(newSViv((long)iError)));
	XPUSHs(sv_2mortal(newSVpv((char *)szError, strlen(szError))));
	PUTBACK;
} 


XS(XS_WIN32__Pipe_Info) 
{
	dXSARGS;

	if(items > 0){
		CROAK("usage: ($ExtName, $Version, $Date, $Author, $CompileDate, $Credits) = Info()\n");
	}
	
	PUSHMARK(sp);
	
	XPUSHs(sv_2mortal(newSVpv(VERNAME, strlen(VERNAME))));
	XPUSHs(sv_2mortal(newSVpv(VERSION, strlen(VERSION))));
	XPUSHs(sv_2mortal(newSVpv(VERDATE, strlen(VERDATE))));
	XPUSHs(sv_2mortal(newSVpv(VERAUTH, strlen(VERAUTH))));
	XPUSHs(sv_2mortal(newSVpv(__DATE__, strlen(__DATE__))));
	XPUSHs(sv_2mortal(newSVpv(__TIME__, strlen(__TIME__))));
	XPUSHs(sv_2mortal(newSVpv(VERCRED, strlen(VERCRED))));

	PUTBACK;
}


#if defined(__cplusplus)
extern "C"
#endif
XS(boot_Win32__Pipe)
{
	dXSARGS;
	char* file = __FILE__;

	giError = 0;
	memset((void *)gszError, 0, ERROR_TEXT_SIZE);

	newXS("Win32::Pipe::constant",				XS_WIN32__Pipe_Constant, file);
	newXS("Win32::Pipe::PipeCreate",			XS_WIN32__Pipe_Create,  file);
	newXS("Win32::Pipe::PipeClose",				XS_WIN32__Pipe_Close,  file);
	newXS("Win32::Pipe::PipeWrite",				XS_WIN32__Pipe_Write,  file);
	newXS("Win32::Pipe::PipeRead",				XS_WIN32__Pipe_Read,  file);
	newXS("Win32::Pipe::PipeConnect",			XS_WIN32__Pipe_Connect,  file);
	newXS("Win32::Pipe::PipeDisconnect",		XS_WIN32__Pipe_Disconnect,  file);
	newXS("Win32::Pipe::PipeError",				XS_WIN32__Pipe_Error,  file);
	newXS("Win32::Pipe::PipeResizeBuffer",		XS_WIN32__Pipe_ResizeBuffer,  file);
	newXS("Win32::Pipe::PipeBufferSize",		XS_WIN32__Pipe_BufferSize,  file);
	newXS("Win32::Pipe::Info",					XS_WIN32__Pipe_Info, file);

	XSRETURN_YES;
}



