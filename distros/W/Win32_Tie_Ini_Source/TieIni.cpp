

#define WIN32_LEAN_AND_MEAN
#define _TieIni_H_

#ifdef __BORLANDC__
typedef wchar_t wctype_t; /* in tchar.h, but unavailable unless _UNICODE */
#endif

#include <windows.h>
#include <winsock.h>
#include <stdio.h>		//	Gurusamy's right, Borland is brain damaged!
#include <math.h>		//	Gurusamy's right, MS is brain damaged!
#include <lmcons.h>     // LAN Manager common definitions
#include <lmerr.h>      // LAN Manager network error definitions
#include <lmUseFlg.h>
#include <lmAccess.h>
#include <lmAPIBuf.h>
#include <lmremutl.h>
#include <lmat.h>
#include <stdio.h>
#include <io.h>			//	For the Exists() function.

#if defined(__cplusplus) && !defined(PERL_OBJECT)
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#if defined(__cplusplus) && !defined(PERL_OBJECT)
}
#endif

	//	Include the AdminMisc headers
#include "TieIni.h"


// constant function for exporting NT definitions.

static char *constant(PERL_OBJECT_PROTO char *szConst)
{
	int	iTemp; 

    errno = 0;

    switch (*szConst) {
    case 'A':
		break;
	case 'B':
		break;
    case 'C':
		break;
    case 'D':
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
		if (strcmp(szConst, "KEYWORD_FILE") == 0)
		#ifdef	KEYWORD_FILE
			return KEYWORD_FILE;
		#else
			goto not_there;
		#endif

		if (strcmp(szConst, "KEYWORD_SECTION") == 0)
		#ifdef	KEYWORD_SECTION
			return KEYWORD_SECTION;
		#else
			goto not_there;
		#endif

		if (strcmp(szConst, "KEYWORD_ARRAY") == 0)
		#ifdef	KEYWORD_ARRAY
			return KEYWORD_ARRAY;
		#else
			goto not_there;
		#endif

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
    return "";

not_there:
    errno = ENOENT;
    return "";
}




#undef malloc
#undef free
void AllocateUnicode(char* szString, LPWSTR &lpPtr)
{
	DWORD	dLength;

	lpPtr = NULL;
	if(szString != NULL)
	{							   
			//	Add one extra for the null!!
		dLength = (strlen(szString) + 1) * sizeof(wctype_t);
		lpPtr = (LPWSTR) new CHAR [dLength];
		if(lpPtr != NULL)
		{
			MultiByteToWideChar(CP_ACP, NULL, szString, -1, lpPtr, dLength);
		}
	}
}

inline void FreeUnicode(LPWSTR lpPtr)
{
	if (lpPtr != NULL)
		free(lpPtr);
}

inline int UnicodeToAnsi(LPWSTR lpwStr, LPSTR lpStr, int size)
{
	*lpStr = '\0';
	return WideCharToMultiByte(CP_ACP, NULL, lpwStr, -1, lpStr, size, NULL, NULL);
}

void FixPath( char *szPath )
{
	if( NULL != szPath )
	{
		int iTemp = strlen( szPath );

		for(; iTemp > -1 ; iTemp--)
		{
			switch( szPath[iTemp] )
			{
				case '/':
					szPath[iTemp] = '\\';
					break;

			}
		}
	}
	return;
}

SV *MakeMagicSectionHash( PERL_OBJECT_PROTO char *szFile, char *szSection)
{
	HV	*hvObject= newHV();
	HV	*hvMagic;
	SV	*svResult = &sv_undef;
	SV	*svBlessed = 0;

	if (szFile)
	{
		hv_store(hvObject, KEYWORD_FILE, strlen(KEYWORD_FILE), newSVpv((char *) szFile, strlen((char *) szFile)), 0);
	}

	if (szSection)
	{
		hv_store(hvObject, KEYWORD_SECTION, strlen(KEYWORD_SECTION), newSVpv((char *) szSection, strlen((char *) szSection)), 0);
	}

	hvMagic = MakeMagicHash( PERL_OBJECT_ARG (SV*) hvObject, EXTENSION_NAMESPACE "::" EXTENSION_NAME );
	SvREFCNT_dec((SV*) hvObject );

	svResult = newRV((SV*) hvMagic);
	SvREFCNT_dec((SV*) hvMagic );

	return svResult;
}

HV *MakeMagicHash( PERL_OBJECT_PROTO SV* svBasedOn, char *szNameSpace)
{
	SV	*svBlessed;
	HV	*hvMagicHash = newHV();

		//	When the reference dies, so should the sv the ref is based on.
	svBlessed = sv_bless(newRV((SV*) svBasedOn), gv_stashpv(szNameSpace, TRUE));
	
	sv_magic((SV*) hvMagicHash, svBlessed, 'P', Nullch, 0);
	SvREFCNT_dec((SV*) svBlessed );

	return hvMagicHash;
}

XS(XS_Win32_Tie_Ini_constant)
{
	dXSARGS;
	char *szConst;
	char *szValue;

	if (items != 2)
	{
		croak("Usage: " EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::constant(name, arg)\n");
    }

	szConst= (char*)SvPV(ST(0),na);
	
	szValue = constant(PERL_OBJECT_ARG szConst);
	ST(0) = sv_2mortal(newSVpv(szValue, strlen(szValue)));

	XSRETURN(1);
}

	
XS(XS_Win32_Tie_Ini_TIE_HASH)
{
	dXSARGS;
	char *szFile;
	char *szExtension;
	HV	*hvObject;
	SV	*svSelf;
	SV	*svResult = 0;
		
	if (items < 2)
	{
		croak("Usage: " EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::TIEHASH($Self, $IniFile)\n");
    }

		
	svSelf = ST(0);
	szFile = SvPV(ST(1),na);
	
	if (hvObject = newHV())
	{
		FixPath( szFile );
		hv_store(hvObject, KEYWORD_FILE, strlen(KEYWORD_FILE), newSVpv((char *) szFile, strlen((char *) szFile)), 0);
		
		svResult = sv_bless(newRV( (SV*) hvObject), gv_stashpv(EXTENSION_NAMESPACE "::" EXTENSION_NAME , TRUE));
	}

	if( NULL != svResult )
	{
		ST(0) = sv_newmortal();
		sv_setsv(ST(0), svResult );
	}
	
	XSRETURN( NULL != svResult );
}

XS(XS_Win32_Tie_Ini_TIE_FETCH)
{
	dXSARGS;
	char	*szSection = 0;
	char	*szKey = 0;
	char	*szFile = "";
	char	*szParam;
	HV	*hvObject;
	HV	*hvSelf;
	SV	*svSelf;
	SV	*svTemp;
	SV	*svResult = 0;
	BOOL bResult = 0;
	
	
	if (items != 2)
	{
		croak("Usage: " EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::TIEFETCH($Self, $Key)\n");
    }
		//	FETCH	
		
	svSelf = ST(0);
	hvSelf = (HV *) SvRV(svSelf);
	szParam = SvPV(ST(1),na);

	if( SV** psvTemp = hv_fetch((HV *) hvSelf, KEYWORD_FILE, strlen(KEYWORD_FILE), 0) )
	{
		szFile = (char *) SvPV( ((SV **) psvTemp)[0], na);
	}

	if( SV** psvTemp = hv_fetch((HV *) hvSelf, KEYWORD_SECTION, strlen(KEYWORD_SECTION), 0) )
	{
		szSection = (char *) SvPV( ((SV **) psvTemp)[0], na);
	}

	if( szSection )
	{
		szKey = szParam;
	}else{
		szSection = szParam;
	}

		//	Test to see if someone is quering one of the speacial keys...	
	if (strcmp(szParam, KEYWORD_SECTION) == 0)
	{
		if (szSection)
		{			
			svResult = newSVpv( szSection, strlen(szSection) ); 
		}
	}else if (strcmp(szParam, KEYWORD_FILE) == 0)
	{
		if (szFile)
		{			
			svResult = newSVpv( szFile, strlen(szFile) ); 
		}
	}else if (strcmp(szParam, KEYWORD_ARRAY) == 0)
	{
		SV	**psvTemp;

		if (psvTemp = hv_fetch((HV *) hvSelf, KEYWORD_ARRAY, strlen(KEYWORD_ARRAY), 0))
		{
			svResult = (SV*) ((SV **) psvTemp)[0];
		}
	}


	if ( NULL == svResult)
	{

		if ( NULL == szKey)
		{
			svResult = MakeMagicSectionHash( PERL_OBJECT_ARG szFile, szSection);
		}else{
			char	szBuffer[BUFFER_SIZE];
			DWORD	dwcbBuffer = sizeof(szBuffer);

			memset(szBuffer, 0, dwcbBuffer);

			if (GetPrivateProfileString(
				szSection,
				szKey,
				"",
				szBuffer,
				dwcbBuffer,
				szFile) )
			{
				svResult = newSVpv( szBuffer, strlen(szBuffer) ); 
			}else{
				svResult = 0;
			}
			
		}
	}					

	if( NULL != svResult )
	{
		ST(0) = sv_newmortal();
		sv_setsv( ST(0), svResult);
	}
		
	XSRETURN( NULL != svResult );
}

XS(XS_Win32_Tie_Ini_TIE_STORE)
{
	dXSARGS;
	char	*szSection = 0;
	char	*szKey = 0;
	char	*szFile = "";
	char	*szValue = "";
	HV	*hvObject;
	HV	*hvSelf;
	SV	*svSelf;
	SV	*svTemp;
	SV	*svResult = 0;
	
	if (items != 3)
	{
		croak("Usage: " EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::TIESTORE($Self, $Key, $Value)\n");
    }

	svSelf = ST(0);
	szKey  = SvPV(ST(1), na);
	szValue= SvPV(ST(2), na);

	hvSelf = (HV *) SvRV(svSelf);
	if (SV** psvTemp = hv_fetch((HV *) hvSelf, KEYWORD_FILE, strlen(KEYWORD_FILE), 0)){
		szFile = (char *) SvPV( ((SV **) psvTemp)[0], na);
	}

	if (SV** psvTemp = hv_fetch((HV *) hvSelf, KEYWORD_SECTION, strlen(KEYWORD_SECTION), 0)){
		szSection = (char *) SvPV( ((SV **) psvTemp)[0], na);
	}

	if (szSection)
	{
		if (WritePrivateProfileString(
			szSection,
			szKey,
			szValue,
			szFile) )
		{
			svResult = 0;
		}
	}

	if( NULL != svResult )
	{
		ST(0) = sv_newmortal();
		sv_setsv( ST(0), svResult );
	}
	
	XSRETURN( NULL != svResult );
}

XS(XS_Win32_Tie_Ini_TIE_FIRSTKEY)
{
	dXSARGS;
	char	*szSection = 0;
	char	*szKey = 0;
	char	*szFile = "";
	char	szBuffer[BUFFER_SIZE];
	DWORD	dwcbBuffer = sizeof(szBuffer);
	
	SV	*svSelf;
	AV	*avSectionList = 0;
	SV	*svResult = 0;
	HV	*hvSelf;
	
	
	if (items != 1)
	{
		croak("Usage: " EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::FIRSTKEY($Self)\n");
    }
		//	FIRSTKEY
	
	svSelf = ST(0);

	hvSelf = (HV *) SvRV(svSelf);
	if (SV** psvTemp = hv_fetch((HV *) hvSelf, KEYWORD_FILE, strlen(KEYWORD_FILE), 0)){
		szFile = (char *) SvPV( ((SV **) psvTemp)[0], na);
	}
		//	Try and get the section name. If it does not exist then the ARRAY created will
		//	be of section names.
	if (SV** psvTemp = hv_fetch((HV *) hvSelf, KEYWORD_SECTION, strlen(KEYWORD_SECTION), 0)){
		szSection = (char *) SvPV( ((SV **) psvTemp)[0], na);
	}

	if (hv_exists((HV *) hvSelf, KEYWORD_ARRAY, strlen(KEYWORD_ARRAY))){
		hv_delete((HV*) hvSelf, KEYWORD_ARRAY, strlen(KEYWORD_ARRAY), G_DISCARD);
	}

	memset(szBuffer, 0, dwcbBuffer);

	if (GetPrivateProfileString(
			szSection,
			szKey,
			"",
			szBuffer,
			dwcbBuffer,
			szFile) )
	{
		if (avSectionList = newAV())
		{
			char	*szTemp = szBuffer;
			SV		**psvTemp;

			while(*szTemp)
			{
				av_push((AV*) avSectionList, newSVpv(szTemp, strlen(szTemp)));
				szTemp = &szTemp[strlen(szTemp) + 1];
			}

			hv_store(hvSelf, KEYWORD_ARRAY, strlen(KEYWORD_ARRAY), (SV*) avSectionList, 0);
			
			if (psvTemp = av_fetch( avSectionList, 0, 0))
			{
				char	*szTemp;

				svResult =  newSVsv( ((SV **) psvTemp)[0]);
			}
		}
	}

	if( NULL != svResult )
	{
		ST(0) = sv_newmortal();
		sv_setsv( ST(0), svResult );
	}

	XSRETURN( NULL != svResult );


}

XS(XS_Win32_Tie_Ini_TIE_NEXTKEY)
{
	dXSARGS;
	char	*szSection = 0;
	char	*szKey = 0;
	char	*szFile = "";
	char	szBuffer[BUFFER_SIZE];
	char	*szPreviousKey;

	DWORD	dwcbBuffer = sizeof(szBuffer);
	SV		**psvTemp;
	SV		*svPrevious = 0;
	SV		*svSelf;
	HV		*hvSelf;
	AV	*avSectionList = 0;
	SV	*svResult = 0;
	
	char *szTempKey;
	int iTotal;
	int iTemp;
	
	if (items != 2)
	{
		croak("Usage: " EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::NEXTKEY($Self, $PreviousKey)\n");
    }

	svSelf = ST(0);
	svPrevious = ST(1);
	szPreviousKey = SvPV(svPrevious, na);

	hvSelf = (HV *) SvRV(svSelf);

	if (psvTemp = hv_fetch((HV *) hvSelf, KEYWORD_FILE, strlen(KEYWORD_FILE), 0)){
		szFile = (char *) SvPV( ((SV **) psvTemp)[0], na);
	}

	if (psvTemp = hv_fetch((HV *) hvSelf, KEYWORD_SECTION, strlen(KEYWORD_SECTION), 0)){
		szSection = (char *) SvPV( ((SV **) psvTemp)[0], na);
	}

	if (hv_exists((HV *) hvSelf, KEYWORD_ARRAY, strlen(KEYWORD_ARRAY)))
	{
		if (psvTemp = hv_fetch((HV *) hvSelf, KEYWORD_ARRAY, strlen(KEYWORD_ARRAY), 0))
		{
			avSectionList = (AV*) ((SV **) psvTemp)[0];
		}
	}

	if (avSectionList)
	{
		iTotal = av_len(avSectionList);
		iTemp = 0;
		SV*	svTemp = 0;
		BOOL	bFlag = FALSE;

		while(iTemp <= iTotal)
		{	
			if (psvTemp = av_fetch(avSectionList, iTemp, 0))
			{
				svTemp = ((SV **) psvTemp)[0];
				szTempKey = SvPV(svTemp, na);
				
				if (bFlag)
				{
					svResult = newSVsv( svTemp );
					break;
				}

					//	We need to make a **case sensitive**
					//	comparison because, oh Lord help us,
					//	when Win32 maps an INI file into the
					//	registry it is case sensitive even though
					//	INI entries are *supposed* to be case
					//	insensitive (as per the GetPrivateProfileString()
					//	documentation)
				if (strcmp(szTempKey, szPreviousKey) == 0)
				{
					bFlag = TRUE;
				}
			}
			iTemp++;
		}
	}

	if( NULL != svResult )
	{
		ST(0) = sv_newmortal();
		sv_setsv( ST(0), svResult );
	}

	XSRETURN( NULL != svResult );
}


XS(XS_Win32_Tie_Ini_TIE_EXISTS)
{
	dXSARGS;
	char	*szSection = 0;
	char	*szKey = "";
	char	*szFile = "";
	char	szBuffer[BUFFER_SIZE];

	DWORD	dwcbBuffer = sizeof(szBuffer);
	SV		**psvTemp;
	SV		*svSelf;
	HV		*hvSelf;

	BOOL	bResult = FALSE;
	
	if (items != 2)
	{
		croak("Usage: " EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::EXISTS($Self, $Key)\n");
    }

	svSelf = ST(0);
	szKey  = SvPV( ST(1), na);

	hvSelf = (HV *) SvRV(svSelf);

	if (psvTemp = hv_fetch((HV *) hvSelf, KEYWORD_FILE, strlen(KEYWORD_FILE), 0)){
		szFile = (char *) SvPV( ((SV **) psvTemp)[0], na);
	}

	if (psvTemp = hv_fetch((HV *) hvSelf, KEYWORD_SECTION, strlen(KEYWORD_SECTION), 0)){
		szSection = (char *) SvPV( ((SV **) psvTemp)[0], na);
	}


	memset(szBuffer, 0, dwcbBuffer);


	if (GetPrivateProfileString(
		szSection,
		0,
		"",
		szBuffer,
		dwcbBuffer,
		szFile) )
	{
		char	*szTemp = szBuffer;

		while(*szTemp)
		{
			if (stricmp(szTemp, szKey) == 0)
			{
				bResult = TRUE;
				break;
			}
			szTemp = &szTemp[strlen(szTemp) + 1];
		}
	}		
	
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV) bResult );
	
	XSRETURN( 1 );
}

XS(XS_Win32_Tie_Ini_TIE_CLEAR)
{
	dXSARGS;
	char	*szSection = 0;
	char	*szFile = "";
	char	*szKey	= 0;
	char	szBuffer[BUFFER_SIZE];
	DWORD	dwcbBuffer = sizeof(szBuffer);

	SV		**psvTemp;
	SV		*svSelf;
	HV		*hvSelf;

	BOOL	bResult = FALSE;
	
	if (items != 1)
	{
		croak("Usage: " EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::CLEAR($Self)\n");
    }

	svSelf = ST(0);

	hvSelf = (HV *) SvRV(svSelf);

	if (psvTemp = hv_fetch((HV *) hvSelf, KEYWORD_FILE, strlen(KEYWORD_FILE), 0)){
		szFile = (char *) SvPV( ((SV **) psvTemp)[0], na);
	}

	if (psvTemp = hv_fetch((HV *) hvSelf, KEYWORD_SECTION, strlen(KEYWORD_SECTION), 0)){
		szSection = (char *) SvPV( ((SV **) psvTemp)[0], na);
	}

	if (bResult = GetPrivateProfileString(
		szSection,
		0,
		"",
		szBuffer,
		dwcbBuffer,
		szFile) )
	{
		char	*szTemp = szBuffer;
		BOOL	bSectionExists = (szSection != 0);
		
		while(*szTemp)
		{
			if (bSectionExists)
			{
				szKey = szTemp;
			}else{
				szSection = szTemp;
			}

			if (!( bResult = WritePrivateProfileString(
				szSection,
				szKey,
				0,
				szFile)))
			{
				break;
			}
			szTemp = &szTemp[strlen(szTemp) + 1];
		}
	}

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV) bResult );
	
	XSRETURN( 1 );
}

XS(XS_Win32_Tie_Ini_TIE_DELETE)
{
	dXSARGS;
	char	*szSection = 0;
	char	*szFile = "";
	char	*szKey = 0;
	char	*szParam;

	SV		**psvTemp;
	SV		*svSelf;
	HV		*hvSelf;

	BOOL	bResult = FALSE;
	
	if (items != 2)
	{
		croak("Usage: " EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::DELETE($Self, $Key)\n");
    }

		//	DELETE	
	svSelf = ST(0);
	hvSelf = (HV *) SvRV(svSelf);

	szParam = SvPV( ST(1), na);


	if (psvTemp = hv_fetch((HV *) hvSelf, KEYWORD_FILE, strlen(KEYWORD_FILE), 0)){
		szFile = (char *) SvPV( ((SV **) psvTemp)[0], na);
	} 

	if (psvTemp = hv_fetch((HV *) hvSelf, KEYWORD_SECTION, strlen(KEYWORD_SECTION), 0)){
		szSection = (char *) SvPV( ((SV **) psvTemp)[0], na);
	}

	if (szSection)
	{
		szKey = szParam;
	}else{
		szSection = szParam;
	}

	bResult = WritePrivateProfileString(
		szSection,
		szKey,
		0,
		szFile);

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV) bResult );
    
    XSRETURN(1);
}

XS(XS_Win32_Tie_Ini_TIE_DESTROY)
{
	dXSARGS;
	char	*szSection = 0;
	char	*szFile = "";
	HV	*hvSelf;
	SV	*svSelf;
	
	if (items != 1)
	{
		croak("Usage: " EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::DESTROY($Self)\n");
    }

		//	DESTROY
	svSelf = ST(0);
	hvSelf = (HV *) SvRV(svSelf);

	if (SV** psvTemp = hv_fetch((HV *) hvSelf, KEYWORD_FILE, strlen(KEYWORD_FILE), 0)){
		szFile = (char *) SvPV( ((SV **) psvTemp)[0], na);
	}
	if (SV** psvTemp = hv_fetch((HV *) hvSelf, KEYWORD_SECTION, strlen(KEYWORD_SECTION), 0)){
		szSection = (char *) SvPV( ((SV **) psvTemp)[0], na);
	}

		//	Do I really need this section???
	if (szSection)
	{
		int	iCount;
		sv_unmagic(svSelf, 'P');
		iCount = SvREFCNT((SV*) svSelf);
		for (; iCount; iCount--)
		{
			SvREFCNT_dec(svSelf);
		}
	
	}
				
	XSRETURN_EMPTY;
}

XS(XS_Win32_Tie_Ini_Version)
{
	dXSARGS;
	
	PUSHMARK(sp);

	XPUSHs( sv_2mortal( newSVpv( (char*) EXTENSION_VERSION, strlen( EXTENSION_VERSION ) ) ) );

	PUTBACK;
}


XS(boot_Win32__Tie__Ini)
{
	dXSARGS;
	char* file = __FILE__;

	newXS( EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::constant",	XS_Win32_Tie_Ini_constant, file);
	newXS( EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::TIEHASH",	XS_Win32_Tie_Ini_TIE_HASH, file);
	newXS( EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::FETCH",		XS_Win32_Tie_Ini_TIE_FETCH, file);
	newXS( EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::STORE",		XS_Win32_Tie_Ini_TIE_STORE, file);
	newXS( EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::FIRSTKEY",	XS_Win32_Tie_Ini_TIE_FIRSTKEY, file);
	newXS( EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::NEXTKEY",	XS_Win32_Tie_Ini_TIE_NEXTKEY, file);
	newXS( EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::EXISTS",		XS_Win32_Tie_Ini_TIE_EXISTS, file);
	newXS( EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::CLEAR",		XS_Win32_Tie_Ini_TIE_CLEAR, file);
	newXS( EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::DELETE",		XS_Win32_Tie_Ini_TIE_DELETE, file);

	newXS( EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::DESTROY",	XS_Win32_Tie_Ini_TIE_DESTROY, file);

	newXS( EXTENSION_NAMESPACE "::" EXTENSION_NAME  "::Version",	XS_Win32_Tie_Ini_Version, file);

	//	End of new Features.
	ST(0) = &sv_yes;
	XSRETURN(1);
}

/* ===============  DLL Specific  Functions  ===================  */

BOOL WINAPI DllMain(HINSTANCE  hinstDLL, DWORD fdwReason, LPVOID  lpvReserved){
	BOOL	bResult = 1;
	switch(fdwReason){
		case DLL_PROCESS_ATTACH:
			ghDLL = hinstDLL;
			break;

			case DLL_THREAD_ATTACH:
				break;

			case DLL_THREAD_DETACH:
					//	Clear the TLS slot for this thread	
				break;
			
		case DLL_PROCESS_DETACH:
			break;

	}
	return bResult;
}


