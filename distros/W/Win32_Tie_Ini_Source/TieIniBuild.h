
	//	THIS MAY NEED TO BE REMOVED IF YOU ARE USING THE CORE DISTRIBUTION

#include "TieIni.h"

#ifndef CORE
#include "build.h"
#endif	//	CORE
	
//	+----------------------------------------------------------------+


#define	VERSION_HI		EXTENSION_VERSION

#define	TieIni	100

#ifdef	CORE
	#undef		PERLVER
	#define		PERLVER	"the Core Distribution of Win32 Perl"
	#define		FILE_EXTENSION	"DLL"
#else	//	CORE
	#define		FILE_EXTENSION	"PLL"
	#ifndef		NT_BUILD_NUMBER
		#define		PERLVER	"Win32 Perl"
	#else
		#define		PERLVER "Win32 Perl build " NT_BUILD_NUMBER
	#endif
#endif	//	CORE

#ifdef	NT_BUILD_NUMBER
#define		VERSION_LO	NT_BUILD_NUMBER
#else
#define		VERSION_LO		"XXX"
#endif	//	NT_BUILD_NUMBER

#ifndef VERSION_TYPE
	#ifdef	VERSION_RELEASE
		#define		VERSION_TYPE	"Release"
	#else
		#define		VERSION_TYPE	"Beta"
	#endif	//	VERSION_RELEASE

	#ifdef	VERSION_BETA
		#define		VERSION_TYPE	"Beta"
	#endif
#endif // VERSION_TYPE

#if _DEBUG
#define		DEBUGGING	"Debug"
#else
#define		DEBUGGING	""
#endif

#define	VER_FILEVERSION	HIWORD(VERSION_HI),LOWORD(VERSION_HI), HIWORD(VERSION_LO), LOWORD(VERSION_LO)
#define	VER_PRODVERSION	HIWORD(VERSION_HI),LOWORD(VERSION_HI), HIWORD(VERSION_LO), LOWORD(VERSION_LO)

#define INTERNALNAME	EXTENSION_NAMESPACE "::" EXTENSION_NAME

#define	VERNAME			EXTENSION_NAMESPACE "::" EXTENSION_NAME " extension for Win32 Perl"
#define VERSION_NUM		VERSION_HI
#define	VERSION_TEXT	VERSION_NUM " " VERSION_TYPE
#define VERDATE			__DATE__
#define VERTIME			__TIME__
#define VERAUTH     	EXTENSION_AUTHOR 
#define VERCRED			COPYRIGHT_NOTICE " " VERAUTH "."	
#define VERCOMMENT		"This version requires " PERLVER "."

#define RC_COMMENTS		VERNAME "\r\n----\r\n" VERCOMMENT "\0"
#define	RC_COMPANY		COMPANY_NAME "\0"
#define	RC_FILEDESC		INTERNALNAME " for " PERLVER "\0"
#define RC_FILEVER		VERSION_TEXT "\0"
#define	RC_INTNAME		INTERNALNAME " " DEBUGGING "\0"
#define	RC_COPYRIGHT	"\251 " COPYRIGHT_YEAR " by " VERAUTH "\0"
#define	RC_FILENAME		EXTENSION_FILE_NAME "." FILE_EXTENSION "\0"
#define	RC_PBUILD		VERSION_NUM " " VERSION_TYPE " " DEBUGGING "\0"
#define	RC_PRODNAME		INTERNALNAME "\0"
#define	RC_PRODVER		VERSION "\0"			  

