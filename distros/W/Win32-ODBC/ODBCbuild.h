
// #include "build.h"

#define	Win32ODBC	100

#ifndef	NT_BUILD_NUMBER
	#define PERLVER	"5.001m build 110"
#else
	#define PERLVER "Win32 Perl build " NT_BUILD_NUMBER
#endif

	//	This should be the VERSION_NUM in hex/dword format
#define	VERSION_HI		"970208"
#define	VERSION_LO		"300"
#define	VERSION_TYPE	"Beta"

#if _DEBUG
	#define	DEBUGGING	"Debug"
#else
	#define	DEBUGGING	""
#endif

#define	VER_FILEVERSION	HIWORD(VERSION_HI),LOWORD(VERSION_HI), HIWORD(VERSION_LO), LOWORD(VERSION_LO)
#define	VER_PRODVERSION	HIWORD(VERSION_HI),LOWORD(VERSION_HI), HIWORD(VERSION_LO), LOWORD(VERSION_LO)

#define INTERNALNAME	"Win32::ODBC"

#define	VERNAME			"ODBC extension for Win32 Perl"
#define VERSION_NUM		VERSION_HI
#undef VERSION
#define	VERSION			VERSION_NUM " " VERSION_TYPE
#define VERDATE			__DATE__
#define VERTIME			__TIME__
#define VERAUTH     	"Dave Roth <rothd@roth.net>"
#define VERCRED			"Copyright (c) 1996-1997 " VERAUTH ".\nBased on original code by Dan DeMaggio <dmag@umich.edu>."	
#define VERCOMMENT		"This version requires " PERLVER "."

#define RC_COMMENTS		VERNAME "\r\n----\r\n" VERCOMMENT "\0"
#define	RC_COMPANY		"Roth Consulting\r\nhttp://www.roth.net/\0"
#define	RC_FILEDESC		INTERNALNAME " (for " PERLVER ")\0"
#define RC_FILEVER		VERSION "\0"
#define	RC_INTNAME		INTERNALNAME " " DEBUGGING "\0"
#define	RC_COPYRIGHT	"\251 1996-1997 by " VERAUTH "\0"
#define	RC_FILENAME		"ODBC.PLL\0"
#define	RC_PBUILD		VERSION_NUM " " VERSION_TYPE " " DEBUGGING "\0"
#define	RC_PRODNAME		VERNAME "\0"
#define	RC_PRODVER		VERSION "\0"			  

