

#define WIN32_LEAN_AND_MEAN
#define _ADMINMISC_H_

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
#include <io.h>			//	For the Exists() function.

#if defined( __cplusplus ) && !defined( PERL_OBJECT )
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#if defined( __cplusplus ) && !defined( PERL_OBJECT )
}
#endif

	//	Include the AdminMisc headers
#include "AdminMisc.h"
#include "DNS.h"


//	===============REMOVE BECAUSE IT IS OBSOLETE!
	//	Set up Globals...
//	PHANDLE	phToken = 0 );		//	handle to Token for impersonation!
//	==============================================


	//	Here are the function prototypes that we don't need to bother putting in 
	//	the header because no other file should need this (not DNS.CPP at least).
	SV *MakeSVFromAccount( PERL_OBJECT_PROTO PUSER_INFO_3 puiUser, int iTemp );
	int SetUserInfo( PERL_OBJECT_PROTO PUSER_INFO_3 puiUser, double dValue, char *szValue, int iTemp );
	void AddFileValue( PERL_OBJECT_PROTO DWORD dLang, char *szKey, char *szName, HV *hv, void *pBuffer );


// constant function for exporting NT definitions.

static long constant( PERL_OBJECT_PROTO char *pszName )
{
	int	iTemp; 
	DWORD	dwValue = 0;

    errno = 0;

    switch ( *pszName ) 
	{
		case 'A':
   				if( strEQ( pszName, "AF_OP_PRINT" ) )
			#ifdef AF_OP_PRINT
					return( AF_OP_PRINT );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "AF_OP_COMM" ) )
			#ifdef AF_OP_COMM
					return( AF_OP_COMM );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "AF_OP_SERVER" ) )
			#ifdef AF_OP_SERVER
					return( AF_OP_SERVER );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "AF_OP_ACCOUNTS" ) )
			#ifdef AF_OP_ACCOUNTS
					return( AF_OP_ACCOUNTS );
			#else
					goto not_there;
			#endif
			break;
    
		case 'B':
				if( strEQ( pszName, "BACKGROUND_RED" ) )
			#ifdef BACKGROUND_RED
					return( BACKGROUND_RED );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "BACKGROUND_BLUE" ) )
			#ifdef BACKGROUND_BLUE
					return( BACKGROUND_BLUE );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "BACKGROUND_GREEN" ) )
			#ifdef BACKGROUND_GREEN
					return( BACKGROUND_GREEN );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "BACKGROUND_INTENSITY" ) )
			#ifdef BACKGROUND_INTENSITY
					return( BACKGROUND_INTENSITY );
			#else
					goto not_there;
			#endif

			break;

		case 'C':
				if( strEQ( pszName, "CREATE_DEFAULT_ERROR_MODE" ) )
			#ifdef CREATE_DEFAULT_ERROR_MODE
					return( CREATE_DEFAULT_ERROR_MODE );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "CREATE_NEW_CONSOLE" ) )
			#ifdef CREATE_NEW_CONSOLE
					return( CREATE_NEW_CONSOLE );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "CREATE_NEW_PROCESS_GROUP" ) )
			#ifdef CREATE_NEW_PROCESS_GROUP
					return( CREATE_NEW_PROCESS_GROUP );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "CREATE_SEPARATE_WOW_VDM" ) )
			#ifdef CREATE_SEPARATE_WOW_VDM
					return( CREATE_SEPARATE_WOW_VDM );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "CREATE_SUSPENDED" ) )
			#ifdef CREATE_SUSPENDED
					return( CREATE_SUSPENDED );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "CREATE_UNICODE_ENVIRONMENT" ) )
			#ifdef CREATE_UNICODE_ENVIRONMENT
					return( CREATE_UNICODE_ENVIRONMENT );
			#else
					goto not_there;
			#endif

			
			break;
		case 'D':
				if( strEQ( pszName, "DEBUG_PROCESS" ) )
			#ifdef DEBUG_PROCESS
					return( DEBUG_PROCESS );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "DEBUG_ONLY_THIS_PROCESS" ) )
			#ifdef DEBUG_ONLY_THIS_PROCESS
					return( DEBUG_ONLY_THIS_PROCESS );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "DETACHED_PROCESS" ) )
			#ifdef DETACHED_PROCESS
					return( DETACHED_PROCESS );
			#else
					goto not_there;
			#endif
			
			if( strEQ( pszName, "DRIVE_REMOVABLE" ) )
			#ifdef DRIVE_REMOVABLE
					return( DRIVE_REMOVABLE );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "DRIVE_FIXED" ) )
			#ifdef DRIVE_FIXED
					return( DRIVE_FIXED );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "DRIVE_REMOTE" ) )
			#ifdef DRIVE_REMOTE
					return( DRIVE_REMOTE );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "DRIVE_CDROM" ) )
			#ifdef DRIVE_CDROM
					return( DRIVE_CDROM );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "DRIVE_RAMDISK" ) )
			#ifdef DRIVE_RAMDISK
					return( DRIVE_RAMDISK );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "DOMAIN_GROUP_RID_USERS" ) )
			#ifdef DOMAIN_GROUP_RID_USERS
					return( DOMAIN_GROUP_RID_USERS );
			#else
					goto not_there;
			#endif
			break;
    
		case 'E':
				if( strEQ( pszName, "ENV_SYSTEM" ) )
			#ifdef ENV_SYSTEM
					return( ENV_SYSTEM );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "ENV_USER" ) )
			#ifdef ENV_USER
					return( ENV_USER );
			#else
					goto not_there;
			#endif

					if( strEQ( pszName, "EWX_LOGOFF" ) )
			#ifdef EWX_LOGOFF 
					return( EWX_LOGOFF  );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "EWX_FORCE" ) )
			#ifdef EWX_FORCE
					return( EWX_FORCE );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "EWX_POWEROFF" ) )
			#ifdef EWX_POWEROFF
					return( EWX_POWEROFF );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "EWX_REBOOT" ) )
			#ifdef EWX_REBOOT
					return( EWX_REBOOT );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "EWX_SHUTDOWN" ) )
			#ifdef EWX_SHUTDOWN
					return( EWX_SHUTDOWN );
			#else
					goto not_there;
			#endif
			
			break;
		case 'F':
			if( strEQ( pszName, "FRIDAY" ) )
				return( 0x000010 );

				if( strEQ( pszName, "FOREGROUND_RED" ) )
			#ifdef FOREGROUND_RED
					return( FOREGROUND_RED );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "FOREGROUND_BLUE" ) )
			#ifdef FOREGROUND_BLUE
					return( FOREGROUND_BLUE );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "FOREGROUND_GREEN" ) )
			#ifdef FOREGROUND_GREEN
					return( FOREGROUND_GREEN );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "FOREGROUND_INTENSITY" ) )
			#ifdef FOREGROUND_INTENSITY
					return( FOREGROUND_INTENSITY );
			#else
					goto not_there;
			#endif
			
			break;
		case 'G':

				if( strEQ( pszName, "GROUP_TYPE_ALL" ) )
			#ifdef GROUP_TYPE_ALL
					return( GROUP_TYPE_ALL );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "GROUP_TYPE_LOCAL" ) )
			#ifdef GROUP_TYPE_LOCAL
					return( GROUP_TYPE_LOCAL );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "GROUP_TYPE_GLOBAL" ) )
			#ifdef GROUP_TYPE_GLOBAL
					return( GROUP_TYPE_GLOBAL );
			#else
					goto not_there;
			#endif
			
			break;
		case 'H':
				if( strEQ( pszName, "HIGH_PRIORITY_CLASS" ) )
			#ifdef HIGH_PRIORITY_CLASS
					return( HIGH_PRIORITY_CLASS );
			#else
					goto not_there;
			#endif

			break;
		case 'I':
				if( strEQ( pszName, "IDLE_PRIORITY_CLASS" ) )
			#ifdef IDLE_PRIORITY_CLASS
					return( IDLE_PRIORITY_CLASS );
			#else
					goto not_there;
			#endif

			break;
		case 'J':
				if( strEQ( pszName, "JOB_RUN_PERIODICALLY" ) )
			#ifdef JOB_RUN_PERIODICALLY
					return( JOB_RUN_PERIODICALLY );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "JOB_ADD_CURRENT_DATE" ) )
			#ifdef JOB_ADD_CURRENT_DATE 
					return( JOB_ADD_CURRENT_DATE );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "JOB_RUN_PERIODICALLY" ) )
			#ifdef JOB_RUN_PERIODICALLY
					return( JOB_RUN_PERIODICALLY );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "JOB_EXEC_ERROR" ) )
			#ifdef JOB_EXEC_ERROR
					return( JOB_EXEC_ERROR );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "JOB_RUNS_TODAY" ) )
			#ifdef JOB_RUNS_TODAY
					return( JOB_RUNS_TODAY );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "JOB_NONINTERACTIVE" ) )
			#ifdef JOB_NONINTERACTIVE
					return( JOB_NONINTERACTIVE );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "IDLE_PRIORITY_CLASS" ) )
			#ifdef IDLE_PRIORITY_CLASS
					return( IDLE_PRIORITY_CLASS );
			#else
					goto not_there;
			#endif

			break;

		case 'K':
			break;
    
		case 'L':
				if( strEQ( pszName, "LOGON32_LOGON_BATCH" ) )
			#ifdef LOGON32_LOGON_BATCH
					return( LOGON32_LOGON_BATCH );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "LOGON32_LOGON_INTERACTIVE" ) )
			#ifdef LOGON32_LOGON_INTERACTIVE
					return( LOGON32_LOGON_INTERACTIVE );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "LOGON32_LOGON_SERVICE" ) )
			#ifdef LOGON32_LOGON_SERVICE
					return( LOGON32_LOGON_SERVICE );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "LOGON32_LOGON_NETWORK" ) )
			#ifdef LOGON32_LOGON_NETWORK
					return( LOGON32_LOGON_NETWORK );
			#else
					goto not_there;
			#endif

			break;

		case 'M':
			if( strEQ( pszName, "MONDAY" ) )
				return( 0x000001 );
				break;

		case 'N':
				if( strEQ( pszName, "NORMAL_PRIORITY_CLASS" ) )
			#ifdef NORMAL_PRIORITY_CLASS
					return( NORMAL_PRIORITY_CLASS );
			#else
					goto not_there;
			#endif
			break;
		case 'O':
			break;
		case 'P':
			break;
		case 'Q':
			break;
		case 'R':
				if( strEQ( pszName, "REALTIME_PRIORITY_CLASS" ) )
			#ifdef REALTIME_PRIORITY_CLASS
					return( REALTIME_PRIORITY_CLASS );
			#else
					goto not_there;
			#endif

			break;
		case 'S':
			if( strEQ( pszName, "SATURDAY" ) )
				return( 0x000020 );
			if( strEQ( pszName, "SUNDAY" ) )
				return( 0x000040 );

				if( strEQ( pszName, "SAM_DAYS_PER_WEEK" ) )
			#ifdef SAM_DAYS_PER_WEEK
					return( SAM_DAYS_PER_WEEK );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "SAM_HOURS_PER_WEEK" ) )
			#ifdef SAM_HOURS_PER_WEEK
					return( SAM_HOURS_PER_WEEK );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "STARTF_USESHOWWINDOW" ) )
			#ifdef STARTF_USESHOWWINDOW
					return( STARTF_USESHOWWINDOW );
			#else
					goto not_there;
			#endif

					if( strEQ( pszName, "STARTF_USEPOSITION" ) )
			#ifdef STARTF_USEPOSITION
					return( STARTF_USEPOSITION );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "STARTF_USESIZE" ) )
			#ifdef STARTF_USESIZE
					return( STARTF_USESIZE );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "STARTF_USECOUNTCHARS" ) )
			#ifdef STARTF_USECOUNTCHARS
					return( STARTF_USECOUNTCHARS );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "STARTF_USEFILLATTRIBUTE" ) )
			#ifdef STARTF_USEFILLATTRIBUTE
					return( STARTF_USEFILLATTRIBUTE );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "STARTF_FORCEONFEEDBACK" ) )
			#ifdef STARTF_FORCEONFEEDBACK
					return( STARTF_FORCEONFEEDBACK );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "STARTF_FORCEOFFFEEDBACK" ) )
			#ifdef STARTF_FORCEOFFFEEDBACK
					return( STARTF_FORCEOFFFEEDBACK );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "STARTF_USESTDHANDLES" ) )
			#ifdef STARTF_USESTDHANDLES
					return( STARTF_USESTDHANDLES );
			#else
					goto not_there;
			#endif
					
					if( strEQ( pszName, "SW_HIDE" ) )
			#ifdef SW_HIDE
					return( SW_HIDE );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "SW_MAXIMIZE" ) )
			#ifdef SW_MAXIMIZE
					return( SW_MAXIMIZE );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "SW_MINIMIZE" ) )
			#ifdef SW_MINIMIZE
					return( SW_MINIMIZE );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "SW_RESTORE" ) )
			#ifdef SW_RESTORE
					return( SW_RESTORE );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "SW_SHOW" ) )
			#ifdef SW_SHOW
					return( SW_SHOW );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "SW_SHOWDEFAULT" ) )
			#ifdef SW_SHOWDEFAULT
					return( SW_SHOWDEFAULT );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "SW_SHOWMAXIMIZED" ) )
			#ifdef SW_SHOWMAXIMIZED
					return( SW_SHOWMAXIMIZED );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "SW_SHOWMINIMIZED" ) )
			#ifdef SW_SHOWMINIMIZED
					return( SW_SHOWMINIMIZED );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "SW_SHOWMINNOACTIVE" ) )
			#ifdef SW_SHOWMINNOACTIVE
					return( SW_SHOWMINNOACTIVE );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "SW_SHOWNA" ) )
			#ifdef SW_SHOWNA
					return( SW_SHOWNA );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "SW_SHOWNOACTIVATE" ) )
			#ifdef SW_SHOWNOACTIVATE
					return( SW_SHOWNOACTIVATE );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "SW_SHOWNORMAL" ) )
			#ifdef SW_SHOWNORMAL
					return( SW_SHOWNORMAL );
			#else
					goto not_there;
			#endif


					if( strEQ( pszName, "STD_INPUT_HANDLE" ) )
			#ifdef STD_INPUT_HANDLE
					return( STD_INPUT_HANDLE );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "STD_OUTPUT_HANDLE" ) )
			#ifdef STD_OUTPUT_HANDLE
					return( STD_OUTPUT_HANDLE );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "STD_ERROR_HANDLE" ) )
			#ifdef STD_ERROR_HANDLE
					return( STD_ERROR_HANDLE );
			#else
					goto not_there;
			#endif

					
					break;
 
		case 'T':

			if( strEQ( pszName, "TUESDAY" ) )
				return( 0x000002 );
			if( strEQ( pszName, "THURSDAY" ) )
				return( 0x000008 );
			
				if( strEQ( pszName, "TIMEQ_FOREVER" ) )
			#ifdef TIMEQ_FOREVER
					return( TIMEQ_FOREVER );
			#else
					goto not_there;
			#endif
	   		break;
    
		case 'U':
				if( strEQ( pszName, "UF_TEMP_DUPLICATE_ACCOUNT" ) )
			#ifdef UF_TEMP_DUPLICATE_ACCOUNT
					return( UF_TEMP_DUPLICATE_ACCOUNT );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "UF_NORMAL_ACCOUNT" ) )
			#ifdef UF_NORMAL_ACCOUNT
					return( UF_NORMAL_ACCOUNT );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "UF_INTERDOMAIN_TRUST_ACCOUNT" ) )
			#ifdef UF_INTERDOMAIN_TRUST_ACCOUNT
					return( UF_INTERDOMAIN_TRUST_ACCOUNT );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "UF_WORKSTATION_TRUST_ACCOUNT" ) )
			#ifdef UF_WORKSTATION_TRUST_ACCOUNT
					return( UF_WORKSTATION_TRUST_ACCOUNT );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "UF_SERVER_TRUST_ACCOUNT" ) )
			#ifdef UF_SERVER_TRUST_ACCOUNT
					return( UF_SERVER_TRUST_ACCOUNT );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "UF_MACHINE_ACCOUNT_MASK" ) )
			#ifdef UF_MACHINE_ACCOUNT_MASK
					return( UF_MACHINE_ACCOUNT_MASK );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "UF_ACCOUNT_TYPE_MASK" ) )
			#ifdef UF_ACCOUNT_TYPE_MASK
					return( UF_ACCOUNT_TYPE_MASK );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "UF_DONT_EXPIRE_PASSWD" ) )
			#ifdef UF_DONT_EXPIRE_PASSWD
					return( UF_DONT_EXPIRE_PASSWD );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "UF_SETTABLE_BITS" ) )
			#ifdef UF_SETTABLE_BITS
					return( UF_SETTABLE_BITS );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "UF_SCRIPT" ) )
			#ifdef UF_SCRIPT
					return( UF_SCRIPT );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "UF_ACCOUNTDISABLE" ) )
			#ifdef UF_ACCOUNTDISABLE
					return( UF_ACCOUNTDISABLE );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "UF_HOMEDIR_REQUIRED" ) )
			#ifdef UF_HOMEDIR_REQUIRED
					return( UF_HOMEDIR_REQUIRED );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "UF_LOCKOUT" ) )
			#ifdef UF_LOCKOUT
					return( UF_LOCKOUT );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "UF_PASSWD_NOTREQD" ) )
			#ifdef UF_PASSWD_NOTREQD
					return( UF_PASSWD_NOTREQD );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "UF_PASSWD_CANT_CHANGE" ) )
			#ifdef UF_PASSWD_CANT_CHANGE
					return( UF_PASSWD_CANT_CHANGE );
			#else
					goto not_there;
			#endif
					if( strEQ( pszName, "USE_FORCE" ) )
			#ifdef USE_FORCE
					return( USE_FORCE );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "USE_LOTS_OF_FORCE" ) )
			#ifdef USE_LOTS_OF_FORCE
					return( USE_LOTS_OF_FORCE );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "USE_NOFORCE" ) )
			#ifdef USE_NOFORCE
					return( USE_NOFORCE );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "USER_PRIV_MASK" ) )
			#ifdef USER_PRIV_MASK
					return( USER_PRIV_MASK );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "USER_PRIV_GUEST" ) )
			#ifdef USER_PRIV_GUEST
					return( USER_PRIV_GUEST );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "USER_PRIV_USER" ) )
			#ifdef USER_PRIV_USER
					return( USER_PRIV_USER );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "USER_PRIV_ADMIN" ) )
			#ifdef USER_PRIV_ADMIN
					return( USER_PRIV_ADMIN );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "UNITS_PER_WEEK" ) )
			#ifdef UNITS_PER_WEEK
					return( UNITS_PER_WEEK );
			#else
					goto not_there;
			#endif
				if( strEQ( pszName, "USER_MAXSTORAGE_UNLIMITED" ) )
			#ifdef USER_MAXSTORAGE_UNLIMITED
					return( USER_MAXSTORAGE_UNLIMITED );
			#else
					goto not_there;
			#endif
			break;
		case 'V':
			break;
		case 'W':
			if( strEQ( pszName, "WEDNESDAY" ) )
				return( 0x000004 );

			break;
		case 'X':
			break;
		case 'Y':
			break;
		case 'Z':
			break;

	}

	if( MapNameToConstant( pszName, &dwValue ) )
	{
		return( (long) dwValue );
	}
    
	errno = EINVAL;
    return( 0 );

not_there:
    errno = ENOENT;
    return( 0 );
}




#undef malloc
#undef free
void AllocateUnicode( char* pszString, LPWSTR &lpPtr )
{
	DWORD	dwLength;

	lpPtr = NULL;

	if( NULL != pszString )	// && *pszName != '\0')
	{							   
			//	Add one extra for the null!!
		dwLength = ( strlen( pszString ) + 1 ) * sizeof( wctype_t );
		lpPtr = (LPWSTR) new CHAR [ dwLength ];
		if( NULL != lpPtr )
		{
			MultiByteToWideChar( CP_ACP, NULL, pszString, -1, lpPtr, dwLength );
		}
	}
}

inline void FreeUnicode( LPWSTR lpPtr )
{
	if( NULL != lpPtr )
	{
		delete [] lpPtr;
	}	
}

inline int UnicodeToAnsi( LPWSTR lpwStr, LPSTR lpStr, int iSize )
{
	*lpStr = '\0';
	return( WideCharToMultiByte( CP_ACP, NULL, lpwStr, -1, lpStr, iSize, NULL, NULL ) );
}

static DWORD dwLastError = 0;


	//	Returns TRUE only if the path was fixed.
///////////////////////////////////////////////////////////////////////
//	FixPath()
///////////////////////////////////////////////////////////////////////
BOOL FixPath( char *pszPath )
{
	BOOL bResult = FALSE;
	
	if( NULL != pszPath )
	{
		while( '\0' != *pszPath )
		{
			switch( *pszPath )
			{
				case '/':
					*pszPath = '\\';

					bResult = TRUE;

				default:
					break;
			}
			pszPath++;
		}
	}
	return( bResult );	
}


	//	GetDC returns 0 if it can not resolve the (P)DC or returns a
	//	char* to the ascii name of the server WHICH NEEDS TO BE DELETED
	//	later!!!!
	//	bPDC == TRUE if requesting a Primary Domain Controler (vs a BDC).
	//	bOnlyDC == TRUE if requesting only a DC, not a server or workstation.
	//
	//	NOTE: If bOnlyDC == FALSE and *IF* pszName does not
	//	start with "//" or "\\\\" then a DC is looked up. If, however,
	//	pszName is empty or does start with "//" or "\\\\" then the slashes are
	//	fixed to be correct and the machine name is returned.
///////////////////////////////////////////////////////////////////////
//	GetDC()
///////////////////////////////////////////////////////////////////////
char *GetDC( char *pszName, BOOL bPDC, BOOL bOnlyDC )
{
	LPWSTR	lpwServer = NULL, lpwDomain = NULL, lpwPrimaryDC = NULL;
	char *pszServer = NULL;
	int	iSize = 50;
	NET_API_STATUS	nResult;
	
	pszServer = new char [ iSize + 1 ];
	if( NULL != pszServer ) 
	{
			//	IF preceded with a \\ or a // then assume it is a computer name otherwise...
		if( NULL != pszName )
		{
			FixPath( pszName );

			if( 0 == strncmp( pszName, "\\\\", 2 ) )
			{
				AllocateUnicode( (char*) pszName, lpwServer );
				lpwDomain = NULL;
			}
			else
			{
				//	...this must be a domain name
				AllocateUnicode( (char*) pszName, lpwDomain );
				lpwServer = NULL;
			}
		}
		else
		{
			lpwServer = NULL;
			lpwDomain = NULL;
		}
		
			//	If we are requesting to resolve only a P/DC OR a domain name
			//	has been specified.
		if( ( TRUE == bOnlyDC ) || ( NULL != lpwDomain ) )
		{
			if( TRUE == bPDC )
			{
				nResult = NetGetDCName( lpwServer, lpwDomain, (LPBYTE *) &lpwPrimaryDC );
			} 
			else
			{
				nResult = NetGetAnyDCName( lpwServer, lpwDomain, (LPBYTE *) &lpwPrimaryDC );
			}
		}
		
		if( NERR_Success == nResult )
		{
			UnicodeToAnsi( lpwPrimaryDC, pszServer, iSize );
			NetApiBufferFree( lpwPrimaryDC );
		}
		else
		{
			if( NULL != lpwServer )
			{
					//	Let's just assume that the name will NEVER be > than
					//	what has been allocated.
				strncpy( pszServer, pszName, iSize );
				
				if( '/' == pszServer[0] ){
					pszServer[0] = '\\';
				}

				if( '/' == pszServer[1] ){
					pszServer[1] = '\\';
				}
			}
			else
			{
				delete [] pszServer;
				pszServer = NULL;
			}
		}
		FreeUnicode( lpwServer );
		FreeUnicode( lpwDomain );
	}
	return( pszServer );
}
/*
	//	GetDC returns 0 if it can not resolve the (P)DC or returns a
	//	char* to the ascii name of the server WHICH NEEDS TO BE DELETED
	//	later!!!!
	//	bFlag == TRUE if requesting a Primary Domain Controler.
char *GetDC(char *szName, BOOL bFlag){
	LPWSTR	lpwServer, lpwDomain, lpwPrimaryDC = 0;
	char *szServer = 0;
	int	iSize = 50;
	NET_API_STATUS	nResult;
	
	if (szServer = new char [iSize + 1]){
			//	IF preceded with a \\ or a // then assume it is a computer name otherwise...
		if (szName){
			for(int iTemp = strlen(szName); iTemp >= 0; iTemp--){
				if (szName[iTemp] == '/'){
					szName[iTemp] = '\\';
				}
			}
			if (strncmp(szName, "\\\\", 2) == 0){
				AllocateUnicode((char*) szName, lpwServer);
				AllocateUnicode((char*) "MICHIGAN", lpwDomain);
				//	lpwDomain = 0;
			}else{
				//	...this must be a domain name
				AllocateUnicode((char*) szName, lpwDomain);
				lpwServer = 0;
			}
		}else{
			lpwServer = 0;
			lpwDomain = 0;
		}
		if (bFlag){
			nResult = NetGetDCName(lpwServer, lpwDomain, (LPBYTE *)&lpwPrimaryDC);
		}else{
			nResult = NetGetAnyDCName(lpwServer, lpwDomain, (LPBYTE *)&lpwPrimaryDC);
		}
		if (nResult == NERR_Success){
			UnicodeToAnsi(lpwPrimaryDC, szServer, iSize);
			NetApiBufferFree(lpwPrimaryDC);
		}else{
			if (lpwServer){
					//	Let's just assume that the name will NEVER be > than
					//	what has been allocated.
				strncpy(szServer, szName, iSize);
				if (szServer[0] == '/') szServer[0] = '\\';
				if (szServer[1] == '/') szServer[1] = '\\';
			}else{
				delete [] szServer;
				szServer = 0;
			}
		}
		FreeUnicode(lpwServer);
		FreeUnicode(lpwDomain);
	}
	return szServer;
}
*/


///////////////////////////////////////////////////////////////////////
//	MapNameToConstant()
///////////////////////////////////////////////////////////////////////
BOOL MapNameToConstant( char *pszString, DWORD *dwValue )
{
	DWORD	dwElement;
	BOOL bReturn = FALSE;

		//	Scan for a name that matches a USER_INFO_3 field name
	for( dwElement = 0; TOTAL_ACCOUNT_INFO > dwElement; dwElement++ )
	{
		if( 0 == ( stricmp( pszString, AccountInfoName[ dwElement ] ) ) )
		{
			*dwValue = dwElement;
			bReturn = TRUE;
			break;
		}
	}
	return( bReturn );
}

///////////////////////////////////////////////////////////////////////
//	AddFileValue()
///////////////////////////////////////////////////////////////////////
void AddFileValue( PERL_OBJECT_PROTO DWORD dwLang, char *pszKey, char *pszName, HV *hv, void *pBuffer )
{
	char	*pszBuffer = NULL;
	SV		*sv = NULL;
	UINT	dwBufSize;
	char	szTemp[50];

	sprintf( szTemp, "\\StringFileInfo\\%08X\\%s", dwLang, pszKey );
	if( VerQueryValue( pBuffer, 
			szTemp, 
			(void **) &pszBuffer, 
			&dwBufSize ) )
	{
		sv = newSVpv( (char *) pszBuffer, strlen( (char *) pszBuffer ) );
		hv_store( hv, pszKey, strlen( pszKey ), sv, 0 );
	}

	return;
}

///////////////////////////////////////////////////////////////////////
//	GetError()
///////////////////////////////////////////////////////////////////////
XS( XS_NT__AdminMisc_GetError )
{
	dSP;
	PUSHMARK( sp );

	XPUSHs( newSViv( dwLastError ) );

	PUTBACK;
}


///////////////////////////////////////////////////////////////////////
//	LogoffImpersonatedUser()
///////////////////////////////////////////////////////////////////////
void LogoffImpersonatedUser( int iSeverity )
{
	PHANDLE	phToken =  (void **) TlsGetValue( gdTlsSlot );

	if( ( NULL != phToken ) || ( 0 != iSeverity ) )
	{
		RevertToSelf();
		if( NULL != phToken )
		{
			CloseHandle( phToken );
		}
		
		phToken = NULL;
		TlsSetValue( gdTlsSlot, phToken );
	}

	return;
}

///////////////////////////////////////////////////////////////////////
//	ShowWindow()
///////////////////////////////////////////////////////////////////////
XS( XS_NT__AdminMisc_ShowWindow )
{
	dXSARGS;
	int	iAttribute;

	if( 1 != items )
	{
		croak( "Usage: " EXTENSION "::ShowWindow( $Attribute )\n" );
	}

	PUSHMARK( sp );


	iAttribute = (int) SvIV( ST( 0 ) );
	
	if( FALSE != ShowWindow( GetWindow, iAttribute ) )
	{ 
		XPUSHs( newSViv( (long) 1 ) );
	}
	else
	{
		XPUSHs( newSViv( (long) 0 ) );
	}

	PUTBACK;
}


///////////////////////////////////////////////////////////////////////
//	ShowWindow()
///////////////////////////////////////////////////////////////////////
XS( XS_NT__AdminMisc_GetWindows )
{
	dXSARGS;
	HWND hWindow = 0;
	int	iAttribute;
	SV  *sv = NULL;
	HV  *hv = NULL;

	if( 1 != items )
	{
		croak( "Usage: " EXTENSION "::ShowWindow( \\%List )\n" );
	}

	PUSHMARK( sp );


	iAttribute = (int) SvIV( ST( 0 ) );
	
	hWindow = GetDesktopWindow();

	if( NULL != hWindow )
	{ 
		XPUSHs( newSViv( (long) 1 ) );
	}
	else
	{
		XPUSHs( newSViv( (long) 0 ) );
	}

	PUTBACK;
}

///////////////////////////////////////////////////////////////////////
//	GetStdHandle
///////////////////////////////////////////////////////////////////////
XS( XS_NT__AdminMisc_GetStdHandle )
{
	dXSARGS;
	HANDLE	hResult;

	if( 1 != items )
	{
		croak( "Usage: " EXTENSION "::GetStdHandle( $StdType )\n" );
	}

	PUSHMARK( sp );

	hResult = GetStdHandle( (DWORD) SvIV( ST( 0 ) ) );
	
	if( INVALID_HANDLE_VALUE == hResult )
	{
		XPUSHs( &sv_undef );
	}
	else
	{
		XPUSHs( newSViv( (long) hResult ) );
	}

	PUTBACK;
}

///////////////////////////////////////////////////////////////////////
//	GetLogonName()
///////////////////////////////////////////////////////////////////////
XS( XS_NT__AdminMisc_GetLogonName )
{
	dXSARGS;
	char szName[ 128 ];
	unsigned long len;
	
	dwLastError = 0;

	if( 0 != items )
	{
		croak( "Usage: " EXTENSION "::GetLogonName()\n" );
	}

	PUSHMARK( sp );

	len = sizeof( szName );

	if( 0 == ( dwLastError = GetUserName( (LPTSTR) szName, &len ) ) )
	{ 
			//	Return value of 0 is an error
		strcpy( szName, "" );
	}
	else
	{
		XPUSHs( newSVpv( szName, strlen( szName ) ) );
	}

	PUTBACK;
}


///////////////////////////////////////////////////////////////////////
//	GetComputerName()
///////////////////////////////////////////////////////////////////////
XS( XS_NT__AdminMisc_GetComputerName )
{
	dXSARGS;
	char szName[ MAX_COMPUTERNAME_LENGTH + 1 ];
	unsigned long len;
	BOOL bResult = FALSE;

	if( 0 != items )
	{
		croak( "Usage: " EXTENSION "::GetComputerName()\n" );
	}

	PUSHMARK( sp );

	len = sizeof( szName );

	bResult = GetComputerName( (LPTSTR) szName, &len );

	if( FALSE != bResult )
	{
		XPUSHs( newSVpv( szName, strlen( szName ) ) );
	}
	else
	{
		XPUSHs( &sv_undef );
	}

	PUTBACK;
}

///////////////////////////////////////////////////////////////////////
//	SetComputerName()
///////////////////////////////////////////////////////////////////////
XS( XS_NT__AdminMisc_SetComputerName )
{
	dXSARGS;
	char *pszName = NULL;
	WCHAR	*pszwName = NULL;
	unsigned long len;
	BOOL	bResult = FALSE;

	if (items != 1){
		croak("Usage: " EXTENSION "::SetComputerName($Name)\n");
	}

	PUSHMARK( sp );

	pszName = SvPV( ST( 0 ), na );

	if( MAX_COMPUTERNAME_LENGTH >= strlen( pszName ) )
	{
		AllocateUnicode( pszName, pszwName );
		bResult = SetComputerName( (LPCTSTR) pszwName );
		FreeUnicode( pszwName );
	}

	if( FALSE != bResult )
	{
		XPUSHs( newSVpv( pszName, strlen( pszName ) ) );
	}
	else
	{
		XPUSHs( &sv_undef );
	}

	PUTBACK;
}


///////////////////////////////////////////////////////////////////////
//	LogoffAsUser()
///////////////////////////////////////////////////////////////////////
XS( XS_NT__AdminMisc_LogoffAsUser )
{
	dXSARGS;
	int	iSeverity = 0;

	if( 1 < items )
	{
		croak( "Usage: " EXTENSION "::LogoffAsUser( [ $Severity ] )\n" );
	}

	if( 0 != items )
	{
		iSeverity = SvIV( ST( 0 ) );
	}

	LogoffImpersonatedUser( iSeverity );

	RETURNRESULT(1);
}


	//	A domain name of "." will choose the computer's local database. A NULL will
	//	search local database then any trust until the username is found.
///////////////////////////////////////////////////////////////////////
//	LogonAsUser()
///////////////////////////////////////////////////////////////////////
XS( XS_NT__AdminMisc_LogonAsUser )
{
 	dXSARGS;
	LPTSTR	pszUser = NULL, pszDomain = NULL, pszPassword = NULL;
	DWORD dwType = LOGON32_LOGON_INTERACTIVE;
	DWORD dwLen = 0;
	PHANDLE	phToken = (void **) TlsGetValue( gdTlsSlot );
	BOOL bResult = TRUE;

	if( ( 4 < items ) || ( 3 > items ) )
	{
		croak( "Usage: " EXTENSION "::LogonAsUser( $Domain, $UserName, $Password [, $LogonType ] )\n" );
	}

	dwLastError = 0;

	pszDomain = (LPTSTR) SvPV( ST( 0 ), na );
	
	dwLen = strlen( pszDomain );
	if( 0 == dwLen )
	{
		pszDomain = NULL;
	}
	else
	{
		FixPath( pszDomain );
	}

	pszUser     = (LPTSTR) SvPV( ST( 1 ), na );
	pszPassword = (LPTSTR) SvPV( ST( 2 ), na );

	if( 4 == items )
	{
		dwType = SvIV( ST( 3 ) );
	}
		//	If we are already logged on, log us out first!
	if( NULL != phToken )
	{
		LogoffImpersonatedUser( 0 );
		phToken = NULL;
	}								  
			//	Log on as the User...
 	dwLastError = LogonUser( pszUser, pszDomain, pszPassword, dwType, LOGON32_PROVIDER_DEFAULT, (PHANDLE) &phToken );

	if( 0 != dwLastError )
	{
			//	Now impersonate the User...
		if( 0 == ( dwLastError = ImpersonateLoggedOnUser( phToken ) ) )
		{
				//	If ImpersonateLoggedOnUser() returned a 0 then it failed.
			LogoffImpersonatedUser( 0 );
			phToken = NULL;
			bResult = FALSE;
		}
	}
	else
	{
		phToken = NULL;
	}
		//	Save the thread specific token
	TlsSetValue( gdTlsSlot, phToken );

	RETURNRESULT( bResult );
}

///////////////////////////////////////////////////////////////////////
//	UserCheckPassword()
///////////////////////////////////////////////////////////////////////
XS( XS_NT__AdminMisc_UserCheckPassword )
{
	dXSARGS;

	if( 3 != items )
	{
		croak( "Usage: " EXTENSION "::UserCheckPassword( $Domain, $UserName, $Password )\n" );
	}

	dwLastError = ChangePassword( (char*) SvPV( ST( 0 ), na ), (char*) SvPV( ST( 1 ), na ), (char*) SvPV( ST( 2 ), na ), (char*) SvPV( ST( 2 ), na ) ); 

	RETURNRESULT( NERR_Success == dwLastError );
}	

///////////////////////////////////////////////////////////////////////
//	UserChangePassword()
///////////////////////////////////////////////////////////////////////
XS( XS_NT__AdminMisc_UserChangePassword )
{
	dXSARGS;
	char *pszServer = NULL;

	if( 4 != items )
	{
		croak( "Usage: " EXTENSION "::UserChangePassword( $Domain, $UserName, $OldPassword, $NewPassword )\n" );
	}

		//	Get a PDC of the domain passed in or if the domain is really a computer name then 
		//	keep the computer name.
	pszServer = GetDC( SvPV( ST( 0 ), na ), TRUE, FALSE ); 

	dwLastError = ChangePassword( (char*) SvPV( ST( 0 ), na ), (char*) SvPV( ST( 1 ), na ), (char*) SvPV( ST( 2 ), na ), (char*) SvPV( ST( 3 ), na ) ); 

	RETURNRESULT( NERR_Success == dwLastError );
}		
	
///////////////////////////////////////////////////////////////////////
//	ChangePassword()
///////////////////////////////////////////////////////////////////////
NET_API_STATUS ChangePassword( char *pszDomain, char *pszUser, char *pszOldPassword, char *pszNewPassword )
{
	LPWSTR lpwDomain = NULL, lpwUser = NULL;
	LPWSTR lpwOldPassword = NULL, lpwNewPassword = NULL;
	NET_API_STATUS	nasResult = 0;
	BOOL bResult = FALSE;

	AllocateUnicode( pszDomain, lpwDomain );
	AllocateUnicode( pszUser,   lpwUser );
	AllocateUnicode( pszOldPassword, lpwOldPassword );
	AllocateUnicode( pszNewPassword, lpwNewPassword );

	nasResult = NetUserChangePassword( lpwDomain, lpwUser, lpwOldPassword, lpwNewPassword );
	
	FreeUnicode( lpwDomain );
	FreeUnicode( lpwUser );
	FreeUnicode( lpwOldPassword );
	FreeUnicode( lpwNewPassword );
		
	return( nasResult );
}

XS(XS_NT__AdminMisc_CreateProcessAsUser)
{
	dXSARGS;

	DWORD dwResult;

	if( 0 > items )
	{
		croak( "Usage: " EXTENSION "::CreateProcessAsUser( $CommandString [, $DefaultDirectory ] [, %Config ] )\n" );
	}

	dwResult = CreateNewProcess( PERL_OBJECT_ARG TRUE );

	PUSHMARK( sp );

	XPUSHs( sv_2mortal( newSViv( (long) dwResult ) ) );

	PUTBACK;
}

XS(XS_NT__AdminMisc_CreateProcess)
{
	dXSARGS;

	DWORD dwResult;

	if( 0 > items )
	{
		croak( "Usage: " EXTENSION "::CreateProcess( $CommandString [, $DefaultDirectory ] [, %Config ] )\n" );
	}

	dwResult = CreateNewProcess( PERL_OBJECT_ARG FALSE);

	PUSHMARK( sp );

	XPUSHs( sv_2mortal( newSViv( (long) dwResult ) ) );

	PUTBACK;
}



DWORD CreateNewProcess( PERL_OBJECT_PROTO BOOL bCreateAsUser )
{
	dXSARGS;
	DWORD	dwResult = 0;
	DWORD	dwFlags = 0;
	DWORD	dwPriority = NORMAL_PRIORITY_CLASS;
	BOOL	bInherit = FALSE;
	int		iNum = 0;
	char	*pszCommand = NULL, *pszDefaultDir = NULL;
	STARTUPINFO 		pStartup;
	PROCESS_INFORMATION	pProcInfo;
	HANDLE	hClientToken = 0;
	PHANDLE	phToken = (void **) TlsGetValue( gdTlsSlot );
	
	dwLastError = 0;

//	IF WE perform the LogonUser() without using the logon type of
//	LOGON32_LOGON_NETWORK, the token *should* be a primary token so
//	any process spawned by the impersonating process should be
//	run under the auspices of the impersonated user.
	
/*
	//	Remark out this function to test if it works without a problem 
	//	since DuplicateTokenEx() requires NT 4.0.

	if (DuplicateTokenEx(	phToken,
							MAXIMUM_ALLOWED,
							NULL,
							SecurityImpersonation,
							TokenPrimary,
							&hClientToken)){
*/
		//	Next line assignes the ClientToken handle instead of using the
		//	the DupliateTokenEx() function.
	if( bCreateAsUser )
	{
		hClientToken = phToken;
	}
		
			//spawn
			//	PROCESS_INFORMATION stProcInfo;
			// initialize the STARTUP_INFO structure for the new process.

	ZeroMemory( (void *) &pStartup, sizeof( pStartup ) );

	pStartup.cb = sizeof( STARTUPINFO );
	pStartup.lpDesktop = "winsta0\\default";

/*
	pStartup.lpReserved=NULL;
	pStartup.lpTitle = NULL; 
	pStartup.dwX = 0; 
	pStartup.dwY = 0; 
	pStartup.dwXSize = 0; 
	pStartup.dwYSize = 0; 
	pStartup.dwXCountChars = 0; 
	pStartup.dwYCountChars = 0; 
	pStartup.dwFillAttribute = NULL; 
	pStartup.dwFlags = NULL; 
	pStartup.wShowWindow = NULL; 
	pStartup.cbReserved2 = NULL; 
	pStartup.lpReserved2 = NULL; 
	pStartup.hStdInput = NULL; 
	pStartup.hStdOutput = NULL; 
	pStartup.hStdError = NULL; 
*/

	pszCommand = (char *) SvPV( ST( 0 ), na );
	iNum = 0;
	
		//	If there are more than 1 items *AND* the total number of times is even...
	if( ( 1 < items ) && ( !( items & 1 ) ) )
	{
		pszDefaultDir = (char *) SvPV( ST( 1 ), na );
		iNum++;
	}
		
		//	IF there are more than 1 parameter then let's assume that variables are being
		//	passed in and let's process them...
	if( 2 < items )
	{
		char	*pszString;
		
		while( ++iNum < items )
		{
			pszString = SvPV( ST( iNum ), na );

			if( ++iNum > items )
			{
				continue;
			}

			if( 0 == stricmp( "StdInput", pszString ) )
			{
				pStartup.hStdInput = (HANDLE) SvIV( ST( iNum ) );
				pStartup.dwFlags |= STARTF_USESTDHANDLES;
				bInherit = TRUE;
			}
			else if( 0 == stricmp( "StdOutput", pszString ) )
			{
				pStartup.hStdOutput = (HANDLE) SvIV( ST( iNum ) );
				pStartup.dwFlags |= STARTF_USESTDHANDLES;
				bInherit = TRUE;
			}
			else if( 0 == stricmp( "StdError", pszString ) )
			{
				pStartup.hStdError = (HANDLE) SvIV( ST( iNum ) );
				pStartup.dwFlags |= STARTF_USESTDHANDLES;
				bInherit = TRUE;
			} 
			else if( 0 == stricmp( "Desktop", pszString ) )
			{
				pStartup.lpDesktop = (LPTSTR) SvPV( ST( iNum ), na );
			}
			else if( 0 == stricmp( "Title", pszString ) )
			{
				pStartup.lpTitle = (LPTSTR) SvPV( ST( iNum ), na );
			}
			else if( 0 == stricmp( "X", pszString ) )
			{
				pStartup.dwX = (DWORD) SvIV( ST( iNum ) );
				pStartup.dwFlags |= STARTF_USEPOSITION;
			}
			else if( 0 == stricmp( "Y", pszString ) )
			{
				pStartup.dwY = (DWORD) SvIV( ST( iNum ) );
				pStartup.dwFlags |= STARTF_USEPOSITION;
			}
			else if( 0 == stricmp( "XSize", pszString ) )
			{
				pStartup.dwXSize = (DWORD) SvIV( ST( iNum ) );
				pStartup.dwFlags |= STARTF_USESIZE;
			}
			else if( 0 == stricmp( "YSize", pszString ) )
			{
				pStartup.dwYSize = (DWORD) SvIV( ST( iNum ) );
				pStartup.dwFlags |= STARTF_USESIZE;
			}
			else if( 0 == stricmp( "XBuffer", pszString ) )
			{
				pStartup.dwXCountChars = (DWORD) SvIV( ST( iNum ) );
				pStartup.dwFlags |= STARTF_USECOUNTCHARS;
			}
			else if( 0 == stricmp( "YBuffer", pszString ) )
			{
				pStartup.dwYCountChars = (DWORD) SvIV( ST( iNum ) );
				pStartup.dwFlags |= STARTF_USECOUNTCHARS;
			}
			else if( 0 == stricmp( "Fill", pszString ) )
			{
				pStartup.dwFillAttribute = (DWORD) SvIV( ST( iNum ) );
				pStartup.dwFlags |= STARTF_USEFILLATTRIBUTE;
			}
			else if( 0 == stricmp( "Priority", pszString ) )
			{
				dwPriority = (DWORD) SvIV( ST( iNum ) );
			}
			else if( 0 == stricmp( "Flags", pszString ) )
			{
					//	Let's assume these flags are for
					//	the creation process for now. If we want
					//	to use "flags" for the STARTUP stucture
					//	let's use someother keyword.
				dwFlags |= (DWORD) SvIV( ST( iNum ) );
			}
			else if( 0 == stricmp( "Show", pszString ) )
			{
				pStartup.wShowWindow = SvIV( ST( iNum ) );
				pStartup.dwFlags |= STARTF_USESHOWWINDOW;
			}
			else if( 0 == stricmp( "Inherit", pszString ) )
			{
				bInherit = (BOOL) ( SvIV( ST( iNum ) )? 1:0 );
			}
			else if( 0 == stricmp( "Directory", pszString ) )
			{
				pszDefaultDir = (char *) SvPV( ST( iNum ), na );
			}
		}
	}

	if( 0 != hClientToken )
	{
		if( CreateProcessAsUser( hClientToken, 
								NULL, 
								pszCommand, 
								NULL, 
								NULL, 
								bInherit, 
								dwFlags | dwPriority, 
								NULL, 
								pszDefaultDir, 
								&pStartup, 
								&pProcInfo ) )
		{
			
			dwResult = pProcInfo.dwProcessId;
		}
	}
	else
	{
		if( CreateProcess(		NULL, 
								pszCommand, 
								NULL, 
								NULL, 
								bInherit, 
								dwFlags | dwPriority, 
								NULL, 
								pszDefaultDir, 
								&pStartup, 
								&pProcInfo ) )
		{
			
			dwResult = pProcInfo.dwProcessId;
		}
	}

/*	
	//	Remark out to test if we can live without the DuplicateTokenEx() call
	//	since it requires NT 4.0

		CloseHandle(hClientToken);
	}
*/
	
	return( dwResult );
}


///////////////////////////////////////////////////////////////////////
//	constant()
///////////////////////////////////////////////////////////////////////
XS( XS_NT__AdminMisc_constant )
{
	dXSARGS;
	char *pszName = NULL;

	if( 2 != items )
	{
		croak( "Usage: " EXTENSION "::constant( $Name, $Arg )\n" );
    }

	pszName = (char*) SvPV( ST( 0 ), na );
	ST( 0 ) = sv_newmortal();
	sv_setiv( ST( 0 ), constant( PERL_OBJECT_ARG pszName ) );

	XSRETURN( 1 );
}


///////////////////////////////////////////////////////////////////////
//	UserGetAttributes()
///////////////////////////////////////////////////////////////////////
XS( XS_NT__AdminMisc_UserGetAttributes )
{
	dXSARGS;
	char pszBuffer[ UNLEN + 1 ];
	LPWSTR lpwServer = NULL, lpwUser = NULL;
	char *pszServer = NULL;
	PUSER_INFO_2 puiUser = NULL;

	if( 10 != items )
	{
		croak( "Usage: " EXTENSION "::UserGetAttributes( $Server, $UserName, $UserFullName, $Password, $PasswordAge,\
					$Privilege, $HomeDir, $Comment, $Flags, $ScriptPath )\n" );
    }

	pszServer = GetDC( SvPV( ST( 0 ), na ), FALSE, FALSE);

	AllocateUnicode( (char*) pszServer, lpwServer );
	AllocateUnicode( (char*) SvPV( ST( 1 ), na ), lpwUser );

	dwLastError = NetUserGetInfo( lpwServer, lpwUser, 2, (LPBYTE*) &puiUser );
	
	if( NERR_Success == dwLastError )
	{
		UnicodeToAnsi( puiUser->usri2_full_name, pszBuffer , sizeof( pszBuffer  ) );
		SETPV( 2, pszBuffer );

		UnicodeToAnsi( puiUser->usri2_password,  pszBuffer , sizeof( pszBuffer ) );
		SETPV(3,  pszBuffer );

		SETIV( 4, puiUser->usri2_password_age );
		SETIV( 5, puiUser->usri2_priv );
		
		UnicodeToAnsi( puiUser->usri2_home_dir,  pszBuffer , sizeof( pszBuffer ) );
		SETPV( 6,  pszBuffer );
		
		UnicodeToAnsi( puiUser->usri2_comment,  pszBuffer , sizeof( pszBuffer ) );
		SETPV( 7,  pszBuffer );
		SETIV( 8, puiUser->usri2_flags );
		
		UnicodeToAnsi( puiUser->usri2_script_path,  pszBuffer , sizeof( pszBuffer ) );
		SETPV( 9,  pszBuffer );
	}
	
	FreeUnicode( lpwServer );
	FreeUnicode( lpwUser );

	NetApiBufferFree( puiUser );

	if( NULL != pszServer )
	{
		delete [] pszServer;
	}

	RETURNRESULT( 0 == dwLastError );
}

///////////////////////////////////////////////////////////////////////
//	UserSetAttributes()
///////////////////////////////////////////////////////////////////////
XS( XS_NT__AdminMisc_UserSetAttributes )
{
	dXSARGS;
	LPWSTR lpwServer = NULL, lpwUser = NULL;
	char *pszServer = NULL;
	USER_INFO_2 uiUser;
	PUSER_INFO_2 puiUser = NULL;

	if( 10 != items )
	{
		croak( "Usage: " EXTENSION "::UserSetAttributes( $Server, $UserName, $UserFullName, $Password, $PasswordAge,\
					$Privilege, $HomeDir, $Comment, $Flags, $ScriptPath )\n" );
    }

	pszServer = GetDC( (char *) SvPV( ST( 0 ), na ), FALSE, FALSE );

	AllocateUnicode( (char*) pszServer, lpwServer );
	AllocateUnicode( (char*) SvPV( ST( 1 ), na), lpwUser );
	
	dwLastError = NetUserGetInfo( lpwServer, lpwUser, 2, (LPBYTE*) &puiUser );
	
	if( 0 == dwLastError )
	{
		memcpy( &uiUser, puiUser, sizeof( USER_INFO_2 ) );
		
		AllocateUnicode( (char*) SvPV( ST( 2 ), na ), uiUser.usri2_full_name );
		AllocateUnicode( (char*) SvPV( ST( 3 ), na ), uiUser.usri2_password );
		uiUser.usri2_password_age	= SvIV( ST( 4 ) );
		uiUser.usri2_priv			= SvIV( ST( 5 ) );
		AllocateUnicode( (char*) SvPV( ST( 6 ), na ), uiUser.usri2_home_dir );
		AllocateUnicode( (char*) SvPV( ST( 7 ), na ), uiUser.usri2_comment );
		uiUser.usri2_flags			= SvIV( ST( 8 ) );
		AllocateUnicode( (char*) SvPV( ST( 9 ), na ), uiUser.usri2_script_path );
		
		dwLastError = NetUserSetInfo( lpwServer, lpwUser, 2, (LPBYTE) &uiUser, NULL );
			
		FreeUnicode( uiUser.usri2_full_name );
		FreeUnicode( uiUser.usri2_password );
		FreeUnicode( uiUser.usri2_home_dir );
		FreeUnicode( uiUser.usri2_comment );
		FreeUnicode( uiUser.usri2_script_path );
	}

	FreeUnicode( lpwUser );
	FreeUnicode( lpwServer );
	
	NetApiBufferFree( puiUser );
	
	if( NULL != pszServer )
	{
		delete [] pszServer;
	}

	RETURNRESULT( 0 == dwLastError );
}

///////////////////////////////////////////////////////////////////////
//	GetHostName()
///////////////////////////////////////////////////////////////////////
XS( XS_NT__AdminMisc_GetHostName )
{
	dXSARGS;
	char	*pszIP = NULL;
	char	*pszHost = NULL;

	if( 1 != items )
	{
		croak( "Usage: " EXTENSION "::GetHostName( $IPAddress )\n" );
    }

	pszIP = SvPV( ST( 0 ), na );

	PUSHMARK( sp );
	
	if( NULL != ( pszHost = ResolveSiteName( pszIP ) ) )
	{
		XPUSHs( sv_2mortal( newSVpv( pszHost, strlen( pszHost ) ) ) );
	}
	else 
	{
		XPUSHs( sv_2mortal( newSVnv( (double) 0 ) ) );
	}

	PUTBACK;
}

///////////////////////////////////////////////////////////////////////
//	GetHostAddress
///////////////////////////////////////////////////////////////////////
XS(XS_NT__AdminMisc_GetHostAddress)
{
	dXSARGS;
	char	*pszIP = NULL;
	char	*pszHost = NULL;

	if( 1 != items )
	{
		croak( "Usage: " EXTENSION "::GetHostAddress( $HostName )\n" );
    }

	pszHost = SvPV( ST( 0 ), na );

	PUSHMARK( sp );
	
	if( NULL != ( pszIP = ResolveSiteName( pszHost ) ) ) 
	{
		XPUSHs( sv_2mortal( newSVpv( pszIP, strlen( pszIP ) ) ) );
	}
	else
	{
		XPUSHs( sv_2mortal( newSVnv( (double) 0 ) ) );
	}

	PUTBACK;
}

///////////////////////////////////////////////////////////////////////
//	DNSCache()
///////////////////////////////////////////////////////////////////////
XS( XS_NT__AdminMisc_DNSCache )
{
	dXSARGS;
	int	iTemp = iEnableDNSCache;

	if( 1 < items )
	{
		croak( "Usage: " EXTENSION "::DNSCache( [ 1 | 0 ] )\n" );
    }

	if( 0 != items )
	{
		iTemp = SvIV( ST( 0 ) );
		iEnableDNSCache = ( 0 == iTemp)? 0:1;
	}

	PUSHMARK( sp );

	XPUSHs( sv_2mortal( newSVnv( (double) iEnableDNSCache ) ) );
	
	PUTBACK;
}

///////////////////////////////////////////////////////////////////////
//	DNSCacheSize()
///////////////////////////////////////////////////////////////////////
XS( XS_NT__AdminMisc_DNSCacheSize )
{
	dXSARGS;
	int iTemp = iDNSCacheLimit;

	if( 1 < items )
	{
		croak( "Usage: $Size = " EXTENSION "::DNSCacheSize( [ $Size ] )\n" );
    }

	if( 0 !=items )
	{
		iTemp = SvIV( ST( 0 ) );
		if( 0 > iTemp )
		{
			iTemp = 0;
		}
		iEnableDNSCache = (iTemp)? 1:0;
		ResetDNSCache();
		iDNSCacheLimit = iTemp;
	}
	PUSHMARK( sp );

	XPUSHs( sv_2mortal( newSVnv( (double) iDNSCacheLimit ) ) );

	PUTBACK;
}

XS(XS_NT__AdminMisc_DNSCacheCount)
{
	dXSARGS;
	int		iTemp = iDNSCacheLimit;

	if (items > 1)
	{
		croak("Usage: $Size = " EXTENSION "::DNSCacheCount()\n");
    }
	PUSHMARK( sp );

	XPUSHs(sv_2mortal(newSVnv((double)iDNSCacheCount)));

	PUTBACK;
}


XS(XS_NT__AdminMisc_UserGetMiscAttributes)
{
	dXSARGS;
	char 	buffer[UNLEN+1];
	LPWSTR 	lpwServer, lpwUser;
	PUSER_INFO_3 puiUser;
	SV 		*sv, *nSv;
	int		iTemp;
	char	*szServer = 0;
	int		iError = 0;

	if (items != 3){
		croak("Usage: " EXTENSION "::UserGetMiscAttributes($Domain, $User, \\%Attribs)\n");
    }
 	
	szServer = GetDC((char *)SvPV(ST(0), na), FALSE, FALSE);
	AllocateUnicode((char*) szServer, lpwServer);
	AllocateUnicode((char*)SvPV(ST(1),na), lpwUser);
	sv = ST(2);
	if(SvROK(sv))
	{
		sv = SvRV(sv);
	}
	if(SvTYPE(sv) == SVt_PVHV)
	{
		hv_clear((HV*)sv);
	
		dwLastError = NetUserGetInfo(lpwServer, lpwUser, 3, (LPBYTE*)&puiUser);
		if(dwLastError == 0)
		{
			SV	*svTemp;

			for (iTemp = 0; iTemp < TOTAL_ACCOUNT_INFO; iTemp++){
				svTemp = MakeSVFromAccount(PERL_OBJECT_ARG puiUser, iTemp);

				iError += !(hv_store((HV *)sv, AccountInfoName[iTemp], strlen(AccountInfoName[iTemp]), svTemp, 0));
			}
			NetApiBufferFree(puiUser);
		}
		FreeUnicode(lpwUser);
		FreeUnicode(lpwServer);
   
	}
	if (szServer){
		delete [] szServer;
	}
	RETURNRESULT(dwLastError == 0);
}

XS(XS_NT__AdminMisc_UserSetMiscAttributes)
{
	dXSARGS;
	
	char	*pszServer = NULL;
	char	*pszValue = NULL;
	LPWSTR lpwServer, lpwUser;
	DWORD	dwValue = 0;
	DWORD	dwAttrib = 0;
	DWORD	dwError = 0;
	SV		*sv, *nSv;
	int		iTemp;
	BOOL	bError = FALSE;
	PUSER_INFO_3 puiUser;

	if( ( 3 > items ) || ( 1 & items ) )
	{
		croak("Usage: " EXTENSION "::UserSetMiscAttributes($Domain, $User, $Attribute, $Value[, $Attribute, $Value]...\n");
    }
	
	{
	
		pszServer = GetDC( (char*) SvPV( ST( 0 ), na), FALSE, FALSE );
		AllocateUnicode( (char*) pszServer, lpwServer );
		AllocateUnicode( (char*) SvPV( ST( 1 ), na ), lpwUser );

		iTemp = 1;
		{
			dwLastError = NetUserGetInfo(lpwServer, lpwUser, 3, (LPBYTE*)&puiUser);
			if( NERR_Success == dwLastError )
			{
				while( ( ++iTemp < items ) && ( FALSE == bError ) )
				{
					if( SvNIOK( ST( iTemp ) ) )
					{
						dwAttrib = (DWORD) SvNV( ST( iTemp ) );
					}
					else
					{
						if( 0 == ( MapNameToConstant( SvPV( ST( iTemp), na), &dwAttrib ) ) )
						{
							bError = TRUE;
							continue;
						}
					}
					if( SvPOK( ST( ++iTemp ) ) )
					{
						pszValue = (char *) SvPV( ST( iTemp ), na );
					}
					else
					{				
						dwValue = (DWORD) SvNV( ST( iTemp ) );
					}
					bError = !( SetUserInfo( PERL_OBJECT_ARG puiUser, dwValue, pszValue, (int) dwAttrib ) );
				}

				if( FALSE != bError )
				{
					dwLastError = 1;
				}
				else
				{
					dwLastError = NetUserSetInfo( lpwServer, lpwUser, 3, (LPBYTE) puiUser, &dwError );
				}
				FreeUnicode( lpwServer );
				FreeUnicode( lpwUser );

				NetApiBufferFree( puiUser );
			}
		}
		if( pszServer )
		{
			delete [] pszServer;
		}
	}
	RETURNRESULT( NERR_Success == dwLastError );
}

SV *MakeSVFromAccount(PERL_OBJECT_PROTO PUSER_INFO_3 puiUser, int iTemp){
	SV*	sv = 0;
	char *szBuffer = 0;
	
	if (!(szBuffer = new char [TMP_BUFFER_SIZE])){
		return 0;
	}

	switch(iTemp){ 
		case 0:
			UnicodeToAnsi(puiUser->usri3_name, szBuffer, TMP_BUFFER_SIZE);
			sv = newSVpv(szBuffer, strlen(szBuffer));
			break;

		case 1:
			UnicodeToAnsi(puiUser->usri3_password, szBuffer, TMP_BUFFER_SIZE);
			sv = newSVpv(szBuffer, strlen(szBuffer));
			break;

		case 2:
			sv = newSVnv((double)puiUser->usri3_password_age);
			break;

		case 3:
			sv = newSVnv((double)puiUser->usri3_priv);
			break;

		case 4:
			UnicodeToAnsi(puiUser->usri3_home_dir, szBuffer, TMP_BUFFER_SIZE);
			sv = newSVpv(szBuffer, strlen(szBuffer));
			break;
		
		case 5:
			UnicodeToAnsi(puiUser->usri3_comment, szBuffer, TMP_BUFFER_SIZE);
			sv = newSVpv(szBuffer, strlen(szBuffer));
			break;
		
		case 6:
			sv = newSVnv((double)puiUser->usri3_flags); 
			break;

		case 7:
			UnicodeToAnsi(puiUser->usri3_script_path, szBuffer, TMP_BUFFER_SIZE);
			sv = newSVpv(szBuffer, strlen(szBuffer));
			break;
		
		case 8:
			sv = newSVnv((double)puiUser->usri3_auth_flags);
			break;
		
		case 9:
			UnicodeToAnsi(puiUser->usri3_full_name, szBuffer, TMP_BUFFER_SIZE);
			sv = newSVpv(szBuffer, strlen(szBuffer));
  			break;
		
		case 10:
			UnicodeToAnsi(puiUser->usri3_usr_comment, szBuffer, TMP_BUFFER_SIZE);
			sv = newSVpv(szBuffer, strlen(szBuffer));
  			break;
		
		case 11:
			UnicodeToAnsi(puiUser->usri3_parms, szBuffer, TMP_BUFFER_SIZE);
			sv = newSVpv(szBuffer, strlen(szBuffer));
  			break;
		
		case 12:
			UnicodeToAnsi(puiUser->usri3_workstations, szBuffer, TMP_BUFFER_SIZE);
			sv = newSVpv(szBuffer, strlen(szBuffer));
  			break;
		
		case 13:
			sv = newSVnv((double)puiUser->usri3_last_logon);
  			break;
		
		case 14:
			sv = newSVnv((double)puiUser->usri3_last_logoff);
  			break;
		
		case 15:
			sv = newSVnv((double)puiUser->usri3_acct_expires);
  			break;
		
		case 16:
			sv = newSVnv((double)puiUser->usri3_max_storage);
  			break;
		
		case 17:
			sv = newSVnv((double)puiUser->usri3_units_per_week);
  			break;
		
		case 18:
			sv = newSVnv((double) *puiUser->usri3_logon_hours);
  			break;
		
		case 19:
			sv = newSVnv((double)puiUser->usri3_bad_pw_count);
  			break;
						 
		case 20:
			sv = newSVnv((double)puiUser->usri3_num_logons);
  			break;
		
		case 21:
			UnicodeToAnsi(puiUser->usri3_logon_server, szBuffer, TMP_BUFFER_SIZE);
			sv = newSVpv(szBuffer, strlen(szBuffer));
  			break;
		
		case 22:
			sv = newSVnv((double)puiUser->usri3_country_code);
  			break;
		
		case 23:
			sv = newSVnv((double)puiUser->usri3_code_page);
  			break;
		
		case 24:
			sv = newSVnv((double)puiUser->usri3_user_id);
  			break;
		
		case 25:
			sv = newSVnv((double)puiUser->usri3_primary_group_id);
  			break;
		
		case 26:
			UnicodeToAnsi(puiUser->usri3_profile, szBuffer, TMP_BUFFER_SIZE);
			sv = newSVpv(szBuffer, strlen(szBuffer));
  			break;
		
		case 27:
			UnicodeToAnsi(puiUser->usri3_home_dir_drive, szBuffer, TMP_BUFFER_SIZE);
			sv = newSVpv(szBuffer, strlen(szBuffer));
  			break;
		
		case 28:
			sv = newSVnv((double)puiUser->usri3_password_expired);
			break;
	}
	if (szBuffer){
		delete [] szBuffer;
	}
	return sv;
}

int SetUserInfo(PERL_OBJECT_PROTO PUSER_INFO_3 puiUser, double dwValue, char *szValue, int iTemp){
	LPWSTR lpwTemp = 0;
	int		iResult = 1;

	if (szValue){
		AllocateUnicode((char*)szValue, lpwTemp);
	}
	switch(iTemp){ 
		case 0:
			puiUser->usri3_name = lpwTemp;
			break;

		case 1:
			puiUser->usri3_password = lpwTemp;
			break;

		case 2:
			puiUser->usri3_password_age = (DWORD) dwValue;
			break;

		case 3:
			puiUser->usri3_priv = (DWORD) dwValue;
			break;

		case 4:
			puiUser->usri3_home_dir = lpwTemp;
			break;
		
		case 5:
			puiUser->usri3_comment = lpwTemp;
			break;
		
		case 6:
			puiUser->usri3_flags = (DWORD) dwValue;
			break;

		case 7:
			puiUser->usri3_script_path = lpwTemp;
			break;
		
		case 8:
			puiUser->usri3_auth_flags = (DWORD) dwValue;
			break;
		
		case 9:
			puiUser->usri3_full_name = lpwTemp;
  			break;
		
		case 10:
			puiUser->usri3_usr_comment = lpwTemp;
  			break;
		
		case 11:
			puiUser->usri3_parms = lpwTemp;
  			break;
		
		case 12:
			puiUser->usri3_workstations = lpwTemp;
			break;
		
		case 13:
			puiUser->usri3_last_logon = (DWORD) dwValue;
  			break;
		
		case 14:
			puiUser->usri3_last_logoff = (DWORD) dwValue;
  			break;
		
		case 15:
			puiUser->usri3_acct_expires = (DWORD) dwValue;
  			break;
		
		case 16:
			puiUser->usri3_max_storage = (DWORD) dwValue;
  			break;
		
		case 17:
			puiUser->usri3_units_per_week = (DWORD) dwValue;
  			break;
		
		case 18:
			 *puiUser->usri3_logon_hours = (DWORD) dwValue;
  			break;
		
		case 19:
			puiUser->usri3_bad_pw_count = (DWORD) dwValue;
  			break;
						 
		case 20:
			puiUser->usri3_num_logons = (DWORD) dwValue;
  			break;
		
		case 21:
			puiUser->usri3_logon_server = lpwTemp;
  			break;
		
		case 22:
			puiUser->usri3_country_code = (DWORD) dwValue;
  			break;
		
		case 23:
			puiUser->usri3_code_page = (DWORD) dwValue;
  			break;
		
		case 24:
			puiUser->usri3_user_id = (DWORD) dwValue;
  			break;
		
		case 25:
			puiUser->usri3_primary_group_id = (DWORD) dwValue;
  			break;
		
		case 26:
			puiUser->usri3_profile = lpwTemp;
  			break;
		
		case 27:
			puiUser->usri3_home_dir_drive = lpwTemp;
  			break;
		
		case 28:
			puiUser->usri3_password_expired = (DWORD) dwValue;
			break;

		default:
			if (lpwTemp){
				FreeUnicode(lpwTemp);
			}
			iResult = 0;
			break;
	}
/*		These blocks of memory must remain until commited so don't free them now.

	if (lpwTemp){
		FreeUnicode(lpwTemp);
	}
*/
	return iResult;
}


XS(XS_NT__AdminMisc_GetProcessorInfo)
{
	dXSARGS;
	SYSTEM_INFO	sInfo;

	if ((items)){
		croak("Usage: " EXTENSION "::GetProcessorInfo()\n");
    }
	PUSHMARK( sp );
	GetSystemInfo(&sInfo);

	XPUSHs(sv_2mortal(newSVpv("OEMID", strlen("OEMID"))));
	XPUSHs(sv_2mortal(newSVnv((double)sInfo.dwOemId)));

	XPUSHs(sv_2mortal(newSVpv("ProcessorNum", strlen("ProcessorNum"))));
	XPUSHs(sv_2mortal(newSVnv((double)sInfo.dwNumberOfProcessors)));

	XPUSHs(sv_2mortal(newSVpv("ProcessorType", strlen("ProcessorType"))));
	XPUSHs(sv_2mortal(newSVnv((double)sInfo.dwProcessorType)));

	XPUSHs(sv_2mortal(newSVpv("PageSize", strlen("PageSize"))));
	XPUSHs(sv_2mortal(newSVnv((double)sInfo.dwPageSize)));

	XPUSHs(sv_2mortal(newSVpv("ProcessorLevel", strlen("ProcessorLevel"))));
	XPUSHs(sv_2mortal(newSVnv((double)sInfo.wProcessorLevel)));

	XPUSHs(sv_2mortal(newSVpv("ProcessorRevision", strlen("ProcessorRevision"))));
	XPUSHs(sv_2mortal(newSVnv((double)sInfo.wProcessorRevision)));

	PUTBACK;
}

XS(XS_NT__AdminMisc_GetMemoryInfo)
{
	dXSARGS;
	MEMORYSTATUS	sInfo;

	if ((items)){
		croak("Usage: " EXTENSION "::GetMemoryInfo()\n");
    }
	PUSHMARK( sp );
	GlobalMemoryStatus(&sInfo);

	XPUSHs(sv_2mortal(newSVpv("Load", strlen("Load"))));
	XPUSHs(sv_2mortal(newSVnv((double)sInfo.dwMemoryLoad)));

	XPUSHs(sv_2mortal(newSVpv("RAMTotal", strlen("RAMTotal"))));
	XPUSHs(sv_2mortal(newSVnv((double)sInfo.dwTotalPhys)));

	XPUSHs(sv_2mortal(newSVpv("RAMAvail", strlen("RAMAvail"))));
	XPUSHs(sv_2mortal(newSVnv((double)sInfo.dwAvailPhys)));

	XPUSHs(sv_2mortal(newSVpv("PageTotal", strlen("PageTotal"))));
	XPUSHs(sv_2mortal(newSVnv((double)sInfo.dwTotalPageFile)));

	XPUSHs(sv_2mortal(newSVpv("PageAvail", strlen("PageAvail"))));
	XPUSHs(sv_2mortal(newSVnv((double)sInfo.dwAvailPageFile)));

	XPUSHs(sv_2mortal(newSVpv("VirtTotal", strlen("VirtTotal"))));
	XPUSHs(sv_2mortal(newSVnv((double)sInfo.dwTotalVirtual)));

	XPUSHs(sv_2mortal(newSVpv("VirtAvail", strlen("VirtAvail"))));
	XPUSHs(sv_2mortal(newSVnv((double)sInfo.dwAvailVirtual)));

	PUTBACK;
}

									
XS(XS_NT__AdminMisc_GetDriveSpace)
{
	dXSARGS;
	char	*szDrive;
	OSVERSIONINFO	sInfo;
	BOOL	bFlag = TRUE;

	if ((items != 1)){
		croak("Usage: " EXTENSION "::GetDriveSpace($Drive)\n");
    }
	szDrive = SvPV(ST(0),na);
	PUSHMARK( sp );

	sInfo.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);

		//	We have to check that we are running either NT or 
		//	Win 95 OEM Service Release 2 (OSR2) or higher to use
		//	GetDiskFreeSpaceEx()
	if (GetVersionEx(&sInfo)){
		if (sInfo.dwPlatformId == VER_PLATFORM_WIN32_WINDOWS){
			unsigned int wBuild;
			wBuild = sInfo.dwBuildNumber & 0x0000ffff;
			if (wBuild <= 1000){
					//	This is a pre OSR2 Win 95 machine!
				bFlag = FALSE;
			}
		}
	}

	if (bFlag){
		ULARGE_INTEGER	ulFreeBytesAvailableToCaller;
		ULARGE_INTEGER	ulTotalNumberOfBytes;
		ULARGE_INTEGER	ulTotalNumberOfFreeBytes;
		HINSTANCE		hDll;
		
		typedef BOOL (CALLBACK *Function) (
								char *zzDrive, 
								PULARGE_INTEGER	ulFreeBytesAvailableToCaller,
								PULARGE_INTEGER	ulTotalNumberOfBytes,
								PULARGE_INTEGER	ulTotalNumberOfFreeBytes);
		Function pGetDiskFreeSpaceEx;

			//	We can not rely on Win 95 (pre OSR2) to load up the KERNEL32.DLL
			//	and map to the GetDiskFreeSpaceEx() function. If we statically link to 
			//	this function it would error upon loading the extension.
			//	Since we can not rely on this we must check to make sure that we can use
			//	this function (hence the above checking code) then load the DLL and get
			//	the address to the function.
		if (hDll = LoadLibrary("Kernel32.dll")){
			if (pGetDiskFreeSpaceEx = (Function) GetProcAddress(hDll, "GetDiskFreeSpaceExA")){
				if ((*pGetDiskFreeSpaceEx)( 
						szDrive,
						(PULARGE_INTEGER) &ulFreeBytesAvailableToCaller, 
						(PULARGE_INTEGER) &ulTotalNumberOfBytes, 
						(PULARGE_INTEGER) &ulTotalNumberOfFreeBytes 
						)){
					char	szValue[20];

						//	Report Total Drive Size...
					sprintf(szValue, "%I64u", ulTotalNumberOfBytes.QuadPart);
					XPUSHs(sv_2mortal(newSVpv((char *) szValue, strlen(szValue))));
						//	Report Free Space...
					sprintf(szValue, "%I64u", ulTotalNumberOfFreeBytes.QuadPart);
					XPUSHs(sv_2mortal(newSVpv((char *) szValue, strlen(szValue))));
				}
			}
			FreeLibrary(hDll);
		}
	}else{
		DWORD	dSectorPerCluster;
		DWORD	dBytePerSector;
		DWORD	dFreeCluster;
		DWORD	dTotalCluster;
		if (GetDiskFreeSpace(
						szDrive, 
						&dSectorPerCluster, 
						&dBytePerSector,
						&dFreeCluster, 
						&dTotalCluster)){

				//	Report Total Drive Size...
			XPUSHs(sv_2mortal(newSViv((long)(dTotalCluster * dSectorPerCluster * dBytePerSector))));
				//	Report Free Space...
			XPUSHs(sv_2mortal(newSViv((long)(dFreeCluster * dSectorPerCluster * dBytePerSector))));
		}
	}
	PUTBACK;
}

XS(XS_NT__AdminMisc_GetDriveGeometry)
{
	dXSARGS;
	char	*szDrive;
	int		iTemp;
	DWORD	dResults[4];

	if ((items != 1)){
		croak("Usage: " EXTENSION "::GetDriveGeometry($Drive)\n");
    }
		//	This returns:
		//	(sectors/cluster, bytes/sector, free clusters, total clusters)

	szDrive = SvPV(ST(0),na);
	PUSHMARK( sp );
	if (GetDiskFreeSpace(szDrive, &dResults[0], &dResults[1],
								  &dResults[2], &dResults[3])){

			//	Report Total Drive Size...
		for (iTemp = 0; iTemp < 4; iTemp++){
			XPUSHs(sv_2mortal(newSVnv((double)dResults[iTemp])));
		}
	}
	PUTBACK;
}

XS(XS_NT__AdminMisc_GetDriveType)
{
	dXSARGS;
	char	*szDrive;

	if ((items != 1)){
		croak("Usage: " EXTENSION "::GetDriveType($Drive)\n");
    }
	szDrive = SvPV(ST(0),na);
	PUSHMARK( sp );
	XPUSHs(sv_2mortal(newSVnv((double)GetDriveType(szDrive))));
	PUTBACK;
}

XS(XS_NT__AdminMisc_GetDrives)
{
	dXSARGS;
	DWORD	dSize = (26 * 4);	//	26 drive letters * "x:\<NULL>"
	char	*szBuffer = 0;
	UINT	uiType;

	if ((items > 1)){
		croak("Usage: " EXTENSION "::GetDrives([$DriveType])\n");
    }
	PUSHMARK( sp );
	if (items){
		uiType = (UINT) SvNV(ST(0));
	}
	if (szBuffer = new char [dSize + 1]){
		if (GetLogicalDriveStrings(dSize, szBuffer)){
			UINT	uiTemp;
			char	*szDrive = szBuffer;

			while(*szDrive){
				uiTemp = GetDriveType(szDrive);		
				if ((!items) || (items && (uiTemp == uiType))){
					XPUSHs(sv_2mortal(newSVpv(szDrive, strlen(szDrive))));
				}
				szDrive = &szDrive[(strlen(szDrive) + 1)];
			}
		}
		delete [] szBuffer;
	}
	PUTBACK;
}

XS(XS_NT__AdminMisc_GetVolumeInfo)
{
	dXSARGS;
	char	szVolume[ 256 ], szFSName[ 25 ], szDrive[ MAX_PATH + 1 ];
	DWORD	dwSize;
	DWORD	dwSerial = 0, dwMaxLen = 0, dwSysFlag = 0;
	char	*pszDrive;

	if ((items != 1)){
		croak("Usage: " EXTENSION "::GetVolumeInfo( $DriveType )\n");
    }
	PUSHMARK( sp );

	
	ZeroMemory( szVolume, sizeof( szVolume ) );
	ZeroMemory( szFSName, sizeof( szFSName ) );
	ZeroMemory( szDrive, sizeof( szDrive ) );
	
	pszDrive = SvPV( ST(0), na);
	strncpy( szDrive, pszDrive, sizeof( szDrive ) - 1 );
	dwSize = strlen( szDrive );

	pszDrive = szDrive;
	while( '\0' != *pszDrive )
	{
		if( '/' == *pszDrive )
		{
			*pszDrive = '\\';
		}
		pszDrive++;
	}

	if( GetVolumeInformation(	
		szDrive, 
		szVolume,
		sizeof( szVolume ),
		&dwSerial,
		&dwMaxLen,
		&dwSysFlag,
		szFSName,
		sizeof( szFSName ) ) )
	{

		XPUSHs( sv_2mortal( newSVpv( "Volume", strlen( "Volume" ) ) ) );
		XPUSHs( sv_2mortal( newSVpv( szVolume, strlen( szVolume ) ) ) );

		XPUSHs( sv_2mortal( newSVpv( "Serial", strlen( "Serial" ) ) ) );
		XPUSHs( sv_2mortal( newSVnv( dwSerial ) ) );

		XPUSHs( sv_2mortal( newSVpv( "MaxFileNameLength", strlen( "MaxFileNameLength" ) ) ) );
		XPUSHs( sv_2mortal( newSVnv( dwMaxLen ) ) );

		XPUSHs( sv_2mortal( newSVpv( "SystemFlags", strlen( "SystemFlags" ) ) ) );
		XPUSHs( sv_2mortal( newSVnv( dwSysFlag ) ) );

		XPUSHs( sv_2mortal( newSVpv( "FileSystemName", strlen( "FileSystemName" ) ) ) );
		XPUSHs( sv_2mortal( newSVpv( szFSName, strlen( szFSName ) ) ) );

	}
	
	PUTBACK;
}

XS(XS_NT__AdminMisc_SetVolumeLabel)
{
	dXSARGS;
	char	szVolume[ 256 ], szFSName[ 25 ], szDrive[ MAX_PATH + 1 ];
	DWORD	dwSize;
	char	*pszDrive, *pszLabel;
	BOOL	bResult = FALSE;

	if ((items != 2)){
		croak("Usage: " EXTENSION "::SetVolumeLabel( $DriveType, $Label )\n");
    }
	PUSHMARK( sp );

	ZeroMemory( szDrive, sizeof( szDrive ) );
	
	pszDrive = SvPV( ST(0), na);
	pszLabel = SvPV( ST(1), na);

	pszDrive = SvPV( ST(0), na);
	strncpy( szDrive, pszDrive, sizeof( szDrive ) - 1 );
	dwSize = strlen( szDrive );

	pszDrive = szDrive;
	while( '\0' != *pszDrive )
	{
		if( '/' == *pszDrive )
		{
			*pszDrive = '\\';
		}
		pszDrive++;
	}	
	
	if( 0 != SetVolumeLabel(	
		szDrive, 
		pszLabel) )
	{

		bResult = TRUE;
		XPUSHs( sv_2mortal( newSVnv( 1 ) ) );
	}
	else
	{
		XPUSHs( sv_2mortal( newSVnv( 0 ) ) );
	}
	
	PUTBACK;
	
}


XS(XS_NT__AdminMisc_GetWinVersion)
{
	dXSARGS;
	char *szTemp;
	OSVERSIONINFO	sInfo;

	if ((items)){
		croak("Usage: " EXTENSION "::GetWinVersion()\n");
    }
	PUSHMARK( sp );
	sInfo.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
	if (GetVersionEx(&sInfo)){

		XPUSHs(sv_2mortal(newSVpv("Major", strlen("Major"))));
		XPUSHs(sv_2mortal(newSVnv((double)sInfo.dwMajorVersion)));

		XPUSHs(sv_2mortal(newSVpv("Minor", strlen("Minor"))));
		XPUSHs(sv_2mortal(newSVnv((double)sInfo.dwMinorVersion)));

		XPUSHs(sv_2mortal(newSVpv("Build", strlen("Build"))));
		XPUSHs(sv_2mortal(newSVnv((double)sInfo.dwBuildNumber)));

		switch(sInfo.dwPlatformId){
			case VER_PLATFORM_WIN32s:
				szTemp = "Win32s";
				break;
			
			case VER_PLATFORM_WIN32_WINDOWS:
				szTemp = "Win32_95";
				break;

			case VER_PLATFORM_WIN32_NT:
				szTemp = "Win32_NT";
				break;

			default:
				szTemp = "Not available";
		}
		XPUSHs(sv_2mortal(newSVpv("Platform", strlen("Platform"))));
		XPUSHs(sv_2mortal(newSVpv(szTemp, strlen(szTemp))));

		XPUSHs(sv_2mortal(newSVpv("CSD", strlen("CSD"))));
		XPUSHs(sv_2mortal(newSVpv((char *)sInfo.szCSDVersion, strlen((char *)sInfo.szCSDVersion))));
	}
	PUTBACK;
}

XS(XS_NT__AdminMisc_GetDC)
{
	dXSARGS;
	char	*szMachine = 0;

	if ((items > 1)){
		croak("Usage: " EXTENSION "::GetDC([$domain | $Server])\n");
    }
	PUSHMARK( sp );
	
	if (szMachine = GetDC((char *) (items)? SvPV(ST(0),na):0, FALSE, TRUE)){
		XPUSHs(sv_2mortal(newSVpv(szMachine, strlen(szMachine))));
		delete [] szMachine;
	}else{
		XPUSHs((SV *) &sv_undef);
	}

	PUTBACK;
}

XS(XS_NT__AdminMisc_GetPDC)
{
	dXSARGS;
	char	*szMachine;

	if ((items > 1)){
		croak("Usage: " EXTENSION "::GetPDC([$domain | $Server])\n");
    }
	PUSHMARK( sp );
	
	if (szMachine = GetDC((char *) (items)? SvPV(ST(0),na):0, TRUE, TRUE)){
		XPUSHs(sv_2mortal(newSVpv(szMachine, strlen(szMachine))));
		delete [] szMachine;
	}else{
		XPUSHs((SV *) &sv_undef);
	}

	PUTBACK;
}


XS(XS_NT__AdminMisc_ExitWindows)
{
	dXSARGS;
	BOOL	bResult;
	UINT	uFlags;
    HANDLE hToken;
    TOKEN_PRIVILEGES tkp;
	OSVERSIONINFO osviVerInfo;

	if ((items != 1)){
		croak("Usage: " EXTENSION "::ExitWindows($Flags)\n");
    }
	PUSHMARK( sp );
	
	uFlags = (UINT) SvIV(ST(0));

	osviVerInfo.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
	GetVersionEx(&osviVerInfo);
		//	Next code segment borrowed from the Microsoft Win32 SDK
	if ( ( osviVerInfo.dwPlatformId == VER_PLATFORM_WIN32_NT) && ((uFlags & EWX_REBOOT) || (uFlags & EWX_SHUTDOWN))){
		if (OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &hToken)){

			// Get the LUID for shutdown privilege
			if(LookupPrivilegeValue(NULL, TEXT("SeShutdownPrivilege"), &tkp.Privileges[0].Luid)){
				tkp.PrivilegeCount = 1;  // one privilege to set
				tkp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
	
				// Get shutdown privilege for this process.
				AdjustTokenPrivileges(hToken, FALSE, &tkp, 0, (PTOKEN_PRIVILEGES)NULL, 0);
			}
		}
    }

	bResult = ExitWindowsEx( uFlags, NULL);
	XPUSHs(newSViv((long) bResult));
	PUTBACK;
}


XS(XS_NT__AdminMisc_GetIdInfo)
{
	dXSARGS;
	char	*szCommandLine = GetCommandLine();
	DWORD	dBasePriority;
	int		dThreadPriority;

	
	if ((items)){
		croak("Usage: ($PID, $TID, $PIDPriority, $TIDPriority, $CommandLine) = " EXTENSION "::GetIDInfo()\n");
    }
	if (! szCommandLine){
		szCommandLine = "";
	}
	
	PUSHMARK( sp );
	
	XPUSHs(sv_2mortal(newSViv((long)GetCurrentProcessId())));
	XPUSHs(sv_2mortal(newSViv((long)GetCurrentThreadId())));
	
		//	These next two are not correct priority values and need to be
		//	modified!!!		roth	970529
	dBasePriority = GetPriorityClass(GetCurrentProcess());
	dThreadPriority = GetThreadPriority(GetCurrentThread());

	XPUSHs(sv_2mortal(newSViv((long) dBasePriority)));
	XPUSHs(sv_2mortal(newSViv((long) dThreadPriority)));

	XPUSHs(sv_2mortal(newSVpv((char *)szCommandLine, strlen(szCommandLine))));
	
		
	PUTBACK;
}


XS(XS_NT__AdminMisc_ReadINI)
{
	dXSARGS;
	char	*pszString[4];
	char	*pszBuffer;
	int		iTemp;
	DWORD	dwSize = 10240;
	BOOL	bFlag = FALSE;

	if( ( 1 > items ) || ( 3 < items ) )
	{
		croak( "Usage: " EXTENSION "::ReadINI($File, [$Section [, $Key]])\n" );
    }
	
	PUSHMARK( sp );

	pszBuffer = new char [ dwSize ];
	if( NULL != pszBuffer )
	{
		for( iTemp = 0; 3 > iTemp; iTemp++ )
		{
				//	In case a param was left out then assume it was NULL
			if( iTemp >= items )
			{
				pszString[ iTemp ] = NULL;
			}
			else
			{
					//	If the param is an undef then we need to set it
					//	to null
				if( ST( iTemp ) == &sv_undef )
				{
					pszString[ iTemp ] = NULL;
				} 
				else
				{
					pszString[ iTemp ] = SvPV( ST( iTemp ), na );
				}
				//	if (! strlen(szString[iTemp])) szString[iTemp] = 0;
			}
		}
		if( pszString[ 0 ] )
		{
			for( iTemp = strlen( pszString[ 0 ] ); iTemp >= 0; iTemp-- )
			{
				if( '/' == pszString[ 0 ][ iTemp ] ) pszString[ 0 ][ iTemp ] = '\\';
			}
			if( GetPrivateProfileString( pszString[ 1 ], pszString[ 2 ], "", pszBuffer, dwSize, pszString[ 0 ] ) )
			{	
				char	*pszTemp = pszBuffer;
				bFlag = TRUE;
				while( '\0' != *pszTemp )
				{
					XPUSHs( sv_2mortal( newSVpv((char *) pszTemp, strlen( pszTemp ) ) ) );

						//	Move to the end of this string.  This puts us on the terminating NUL so
						//	add one more to move on to the next string.  If THAT is NUL also then
						//	we are at the end of the data.
					pszTemp += strlen( pszTemp ) + 1;
				}
			}
		}
	}
	if( NULL != pszBuffer )
	{
		delete [] pszBuffer;
	}
	PUTBACK;
}

XS(XS_NT__AdminMisc_WriteINI)
{
	dXSARGS;
	char	*szString[4];
	int		iTemp;
	BOOL	bFlag = FALSE;

		//	You must supply the name of the section as well as the file name
	if ((items < 2 || items > 4)){
		croak("Usage: " EXTENSION "::WriteProfileString($File, $Section [, $Key [, $Data]])\n");
    }
	
	PUSHMARK( sp );

	for(iTemp = 0; iTemp < 4; iTemp++){
		//	In case a param was left out then assume it was NULL
		if (iTemp >= items)
		{
			szString[iTemp] = 0;
		}else{
				//	If the param is an undef then we need to set it
				//	to null
			if (ST(iTemp) == &sv_undef)
			{
				szString[iTemp] = 0;
			}else{
				szString[iTemp] = SvPV(ST(iTemp), na);
			}
		}
	}

	if (szString[0]){
		for (iTemp = strlen(szString[0]); iTemp >= 0; iTemp--){
			if (szString[0][iTemp] == '/') szString[0][iTemp] = '\\';
		}

		if (WritePrivateProfileString(szString[1], szString[2], szString[3], szString[0])){	
			bFlag = TRUE;
		}
	}
	if (bFlag){
		XPUSHs(sv_2mortal(newSViv((long) 1)));
	}else{
		XPUSHs(&sv_undef);
	}

	PUTBACK;
}


XS(XS_NT__AdminMisc_SetPassword)
{
	dXSARGS;
	LPWSTR lpwServer, lpwUser;
	char	*szServer = 0;
	char	*szUser = 0;
	USER_INFO_1003 uiUser;
	DWORD	dError  = 0;

	if (items != 3)
	{
		croak("Usage: " EXTENSION "::SetPassword(server, userName, password)\n");
    }
	{
		szServer = SvPV(ST(0), na);
		if (!strlen(szServer)){
			szServer = 0;
		}
			//	Specify the flag as TRUE since we want to grab the PDC!
		szServer = GetDC(szServer, TRUE, TRUE);		
		AllocateUnicode((char*) szServer, lpwServer);
		AllocateUnicode((char*)SvPV(ST(1),na), lpwUser);
		
		memset(&uiUser, 0, sizeof(USER_INFO_1003));
			
		AllocateUnicode((char*)SvPV(ST(2),na), uiUser.usri1003_password);
			
		dwLastError = NetUserSetInfo(lpwServer, lpwUser, 1003, (LPBYTE)&uiUser, &dError);
				
		FreeUnicode(uiUser.usri1003_password);
		FreeUnicode(lpwUser);
		FreeUnicode(lpwServer);
		if (szServer){
			delete [] szServer;
		}
	}
	RETURNRESULT(dwLastError == 0);
}

XS(XS_NT__AdminMisc_GetTOD)
{
	dXSARGS;
	LPWSTR lpwMachine;
	char	*szMachine = 0;
	TIME_OF_DAY_INFO	*sTime;
	DWORD	dError  = 0;
	NET_API_STATUS	nasResult;

	if (items != 1)
	{
		croak("Usage: " EXTENSION "::GetTOD($Machine)\n");
    }
	{
		PUSHMARK( sp );

		szMachine = SvPV(ST(0), na);
		if (!strlen(szMachine)){
			szMachine = 0;
		}
		AllocateUnicode((char*) szMachine, lpwMachine);

		nasResult = NetRemoteTOD(lpwMachine, (LPBYTE *) &sTime);

		if (nasResult == NERR_Success){
			DWORD	dTZDelta;
			DWORD	dHour;

			//	dTotalSec = sTime->tod_elapsedt - ((sTime->tod_timezone == -1)? 0:(sTime->tod_timezone * 60));

				//	A timezone of -1 means the timezone is undefined.
			if (sTime->tod_timezone != -1){
					//	tod_timezone is a + or - value of minutes the
					//	timezone is off from GMT
				dTZDelta = (sTime->tod_timezone / 60);
			}
			dHour = sTime->tod_hours - dTZDelta;
			if (dHour < 0){
				dHour += 23;
			}
			if (dHour > 23){
				dHour -= 24;
			}
			/*
			if (GIMME_V == G_ARRAY){
				XPUSHs(newSViv(sTime->tod_secs));
				XPUSHs(newSViv(sTime->tod_mins));
				XPUSHs(newSViv(dHour));
				XPUSHs(newSViv(sTime->tod_day));
				XPUSHs(newSViv(sTime->tod_month - 1));
				XPUSHs(newSViv(sTime->tod_year - 1900));
				XPUSHs(newSViv(0));
				XPUSHs(newSViv(0));
			}else{
			*/
				XPUSHs(newSViv(	sTime->tod_elapsedt ));
			//	}
			NetApiBufferFree(sTime);
		}else{
			XPUSHs(&sv_undef);
		}
		FreeUnicode(lpwMachine);
		PUTBACK;
	}
}

XS(XS_NT__AdminMisc_RenameUser)
{
	dXSARGS;
	char buffer[UNLEN+1];
	LPWSTR lpwServer, lpwUser, lpwNewUserName;
	char	*szValue = 0;
	DWORD	dValue, dAttrib = 0;
	USER_INFO_0 uiUser;
	char	*szServer = 0;
	DWORD	dError = 0;
	
	if (items != 3){
		croak("Usage: " EXTENSION "::RenameUser($Domain, $Account, $NewAccountName)\n");
    }
	
	{
		szServer = GetDC((char *)SvPV(ST(0), na), FALSE, FALSE);
		AllocateUnicode((char*) szServer, lpwServer);
		AllocateUnicode((char*)SvPV(ST(1),na), lpwUser);
		AllocateUnicode((char*)SvPV(ST(2),na), lpwNewUserName);

		uiUser.usri0_name = lpwNewUserName;
		dwLastError = NetUserSetInfo(lpwServer, lpwUser, 0, (LPBYTE) &uiUser, &dError);
		
		FreeUnicode(lpwServer);
		FreeUnicode(lpwUser);
		FreeUnicode(lpwNewUserName);

		if (szServer){
			delete [] szServer;
		}
	}
	RETURNRESULT(dwLastError == 0);
}

char *ResolveFromSeconds(DWORD dTime){
	char	*szBuffer;
	int		iHour, iMin, iSec;

	if (szBuffer = new char [9]){
		iHour = dTime / 3600;
		dTime -= iHour * 3600;

		iMin  = (dTime / 60);
		dTime -= iMin * 60;

		iSec  = dTime;
		sprintf(szBuffer, "%02d:%02d:%02d", iHour, iMin, iSec);
	}
	return szBuffer;
}


DWORD ResolveNumToSeconds( DWORD dTime)
{
	if (dTime > 24 * (60 * 60) )
	{
		struct tm *today;

		today =  localtime( (const time_t *) &dTime);
			//	Convert the passed in time to time after midnight
		dTime =  today->tm_hour * 60 * 60;
		dTime += today->tm_min * 60;
		dTime += today->tm_sec;
	}

	return dTime;
}

DWORD ResolveStringToSeconds(char *szTime)
{
	DWORD	dTime = 0;
	char	szBuffer[50];
	char	*szTemp = 0;
	int		iHour = 0, iMin = 0, iSec = 0;

	memset(szBuffer, 0, 50);
	if (szTime){
		BOOL	bString = FALSE;

		strncpy((char *) szBuffer, szTime, 49);

		for(int iTemp = strlen((char *) szBuffer); iTemp; iTemp--){
			if ( ! isdigit(szBuffer[iTemp - 1]) )
			{
				bString = TRUE;
				szBuffer[iTemp - 1] = tolower((int) szBuffer[iTemp - 1]);
			}
		}
		if (bString)
		{
			sscanf((char *) szBuffer, "%d:%d:%d", &iHour, &iMin, &iSec);
			if (strchr((char *) szBuffer, 'p') && iHour <= 12){
				iHour += 12;
			}
			dTime = (iHour * 60 * 60) + (iMin * 60) + iSec;
		}else{
			dTime = ResolveNumToSeconds( atol(szBuffer) );
		}
	}
	return dTime;
}

//	Test string:	p " EXTENSION "::ScheduleAdd('', "9:40pm", 1, 3, 17, "dir")
		
XS(XS_NT__AdminMisc_ScheduleAdd)
{
	dXSARGS;
	LPWSTR	lpwMachine, lpwCommand;
	AT_INFO	atInfo;
	char	*szCommand = 0, *szMachine = 0;
	DWORD	dJob= 0;
	DWORD	dError = TRUE;
	DWORD	dTime = 0;
	
	if (items != 6){
		croak("Usage: " EXTENSION "::ScheduleAdd($Server, $Time, $DOM, $DOW, $Flags, $Command)\n");
    }
	
	PUSHMARK( sp );
	szMachine = (char *)SvPV(ST(0), na);
	AllocateUnicode((char*) szMachine, lpwMachine);
	if (SvTYPE(ST(1)) == SVt_IV ){
		dTime = ResolveNumToSeconds( (DWORD) SvIV(ST(1)) );
			//	if the time specified was larger than the seconds since midnight
			//	then assume that it is a time since January 1, 1970
		
	}else{
		dTime = ResolveStringToSeconds(SvPV(ST(1),na));
	}
		
		//	Make sure that the time is converted to milliseconds
	atInfo.JobTime = ((DWORD) dTime) * 1000;
	atInfo.DaysOfMonth = (DWORD) SvIV(ST(2));
	atInfo.DaysOfWeek = (DWORD) SvIV(ST(3));
	atInfo.Flags = (UCHAR) SvIV(ST(4));

	szCommand = (char *) SvPV(ST(5),na);
	AllocateUnicode((char*) szCommand, lpwCommand);
	atInfo.Command = lpwCommand;

	dError = NetScheduleJobAdd( lpwMachine, (BYTE*) &atInfo, &dJob);
	
	FreeUnicode(lpwMachine);
	FreeUnicode(lpwCommand);

	if (dError){
		XPUSHs(&sv_undef);
	}else{
		XPUSHs(sv_2mortal(newSViv((long)dJob)));
	}
	PUTBACK;
}

XS(XS_NT__AdminMisc_ScheduleDel)
{
	dXSARGS;
	LPWSTR	lpwMachine;
	char	*szMachine = 0;
	DWORD	dJobMin = 0, dJobMax = 0;
	DWORD	dError = TRUE;
	
	if (items < 2 || items > 3){
		croak("Usage: " EXTENSION "::ScheduleDel($Server, $JobNum [, $MaxJobNum])\n");
    }
	
	{

		szMachine = (char *)SvPV(ST(0), na);
		AllocateUnicode((char*) szMachine, lpwMachine);
		dJobMin = (DWORD) SvIV(ST(1));
		if (items == 3){
			dJobMax = (DWORD) SvIV(ST(2));
		}else{
			dJobMax = dJobMin;
		}

		dError = NetScheduleJobDel(	lpwMachine, 
			(dJobMin < dJobMax)? dJobMin:dJobMax,
			(dJobMin < dJobMax)? dJobMax:dJobMin);
		
		FreeUnicode(lpwMachine);
	}
	RETURNRESULT(dError == 0);
}

XS(XS_NT__AdminMisc_ScheduleGet)
{
	dXSARGS;
	LPWSTR	lpwMachine;
	char	*szValue = 0;
	PAT_INFO	atInfo;
	char	szCommand[2048], *szMachine = 0;
	DWORD	dJob= 0;
	HV		*hv = 0;
	DWORD	dError = TRUE;
	
	if (items != 3){
		croak("Usage: " EXTENSION "::ScheduleGet($Server, $JobNum, \\%Job)\n");
    }
	
	{
		hv = (HV*) ST(2);
		if(SvROK(hv)){
			hv = (HV*) SvRV((SV*) hv);
		}
		if(SvTYPE(hv) == SVt_PVHV){
			char	*szTemp;
			hv_clear((HV*) hv);
		
			szMachine = (char *)SvPV(ST(0), na);
			AllocateUnicode((char*) szMachine, lpwMachine);
			dJob = (DWORD) SvIV(ST(1));			

			dError = NetScheduleJobGetInfo( lpwMachine, dJob, (LPBYTE*) &atInfo);

			if (dError == 0 && atInfo){
				if (szTemp = ResolveFromSeconds(atInfo->JobTime/1000)){
					hv_store(hv, "Time", strlen("Time"), newSVpv(szTemp, strlen(szTemp)), 0);
				}else{
					hv_store(hv, "Time", strlen("Time"), newSVpv("N/A", 3), 0);
				}
				
				hv_store(hv, "DOM", strlen("DOM"), newSViv((long) atInfo->DaysOfMonth), 0);
				hv_store(hv, "DOW", strlen("DOW"), newSViv((long) atInfo->DaysOfWeek), 0);
				hv_store(hv, "Flags", strlen("Flags"), newSViv((long) atInfo->Flags), 0);

				UnicodeToAnsi(atInfo->Command, szCommand, 2048);
				hv_store(hv, "Command", strlen("Command"), newSVpv((char*) szCommand, na), 0);

				FreeUnicode(lpwMachine);
				NetApiBufferFree(atInfo);
				if (szTemp) delete [] szTemp;
			}
		}
	}
	RETURNRESULT( dError == 0);
}

XS(XS_NT__AdminMisc_ScheduleList)
{
	dXSARGS;
	LPWSTR	lpwMachine;												   
	char	*szValue = 0;
	PAT_ENUM	atInfo;
	char	*szCommand[2048], *szMachine = 0;
	DWORD	dJob= 0, dRead = 0, dRemain = 0, dTotal = 0, dResume = 0;
	HV	*hv = NULL;
	DWORD	dError = TRUE;
	
	if (items < 1 || items > 2){
		croak("Usage: " EXTENSION "::ScheduleList($Server [, \\%hash])\n");
    }
	
	PUSHMARK( sp );

	{
		szMachine = (char *)SvPV(ST(0), na);
		AllocateUnicode((char*) szMachine, lpwMachine);

		
		if (items == 2){
			hv = (HV*) ST(1);
			if(SvROK(hv)){
				hv = (HV*) SvRV((SV*) hv);
			}
			if(SvTYPE(hv) == SVt_PVHV){
				hv_clear((HV*) hv);
			}
		}
		do{
			dError = NetScheduleJobEnum( lpwMachine, (LPBYTE *) &atInfo, 4096, &dRead, &dRemain, &dResume);
			if (dError == 0 && atInfo){
				while(dRead--){
					dTotal++;
					if (hv){
						char	*szTemp;
						HV		*hvTemp = newHV();
						if (szTemp = ResolveFromSeconds(atInfo[dRead].JobTime/1000)){
							hv_store(hvTemp, "Time", strlen("Time"), newSVpv(szTemp, strlen(szTemp)), 0);
						}else{
							hv_store(hvTemp, "Time", strlen("Time"), newSVpv("N/A", 3), 0);
						}
						hv_store(hvTemp, "DOM", strlen("DOM"), newSViv((long) atInfo[dRead].DaysOfMonth), 0);
						hv_store(hvTemp, "DOW", strlen("DOW"), newSViv((long) atInfo[dRead].DaysOfWeek), 0);
						hv_store(hvTemp, "Flags", strlen("Flags"), newSViv((long) atInfo[dRead].Flags), 0);

						UnicodeToAnsi(atInfo[dRead].Command, (char *)szCommand, 2048);
						hv_store(hvTemp, "Command", strlen("Command"), newSVpv((char*) szCommand, strlen((char *)szCommand)), 0);

						sprintf((char *)szCommand, "%d", atInfo[dRead].JobId);
						hv_store(hv, (char *) szCommand, strlen((char *) szCommand), (SV*) newRV((SV*) hvTemp), 0);
						
						if (szTemp) delete [] szTemp;
					}
				}
				NetApiBufferFree(atInfo);
			}
		}while(dResume);

		FreeUnicode(lpwMachine);
	}
	if ((dError != 0) && (! dTotal)){
		XPUSHs((SV*) &sv_undef);
	}else{
		XPUSHs(newSViv(dTotal));
	}
	PUTBACK;
}

/*
	//	This is not needed any longer since the Win32 exist flag was
	//	fixed (now it detects UNC roots correctly).
XS(XS_NT__AdminMisc_Exist)
{
	dXSARGS;
	char	*szPath, *szTemp;
	int		iError = -1;
	
	if (items != 1){
		croak("Usage: " EXTENSION "::Exist($File)\n");
    }
	
	{

		szTemp = szPath = (char *)SvPV(ST(0), na);
		while(*szTemp){
			if (*szTemp == '/'){
				*szTemp = '\\';
			}
			szTemp++;
		}
		iError = _access( szPath, 0);
	}
	RETURNRESULT(iError == 0);
}
*/

XS(XS_NT__AdminMisc_GetFileInfo)
{
	dXSARGS;
	char	*szPath, *szTemp;
	int		iError = -1;
	DWORD	dTemp, dSize;
	void	*pBuffer;
	HV		*hv = 0;
	BOOL	bResult = FALSE;
	
	if (items != 2){
		croak("Usage: " EXTENSION "::GetFileInfo($File, \\%Info)\n");
    }
	
	szTemp = szPath = (char *)SvPV(ST(0), na);
	hv = (HV*) ST(1);
	if(SvROK(hv)){
		hv = (HV*) SvRV((SV*) hv);
	}
	if(SvTYPE(hv) == SVt_PVHV){
		hv_clear((HV*) hv);
	}

	if (hv){
		while(*szTemp){
			if (*szTemp == '/'){
				*szTemp = '\\';
			}
			szTemp++;
		}
		if (dSize = GetFileVersionInfoSize( szPath, &dTemp)){
			if (pBuffer = new char [dSize]){
				if (GetFileVersionInfo(szPath, dTemp, dSize, pBuffer)){
					UINT	dBufSize;
					char	*szBuffer;
					char	szTemp[50];					
					SV		*sv;

					if (VerQueryValue(pBuffer, 
							TEXT( "\\VarFileInfo\\Translation"), 
							(void **) &szBuffer, 
							&dBufSize)){
						dTemp = (((PWORD) szBuffer)[0]) << 16;
						dTemp |= ((PWORD) szBuffer)[1];

						AddFileValue( PERL_OBJECT_ARG dTemp, "CompanyName", "Company", hv, pBuffer);
						AddFileValue( PERL_OBJECT_ARG dTemp, "FileVersion", "Version", hv, pBuffer);
						AddFileValue( PERL_OBJECT_ARG dTemp, "InternalName", "InternalName", hv, pBuffer);
						AddFileValue( PERL_OBJECT_ARG dTemp, "LegalCopyright", "Copyright", hv, pBuffer);
						AddFileValue( PERL_OBJECT_ARG dTemp, "OriginalFilename", "OriginalFilename", hv, pBuffer);
						AddFileValue( PERL_OBJECT_ARG dTemp, "ProductName", "ProductName", hv, pBuffer);
						AddFileValue( PERL_OBJECT_ARG dTemp, "ProductVersion", "ProductVersion", hv, pBuffer);

							//	Grab the Language specific stuff
							//	Thanks to "Jutta M. Klebe" <jmk@exc.bybyte.de> ( 980607 )
 						sprintf(szTemp, "0x%04x", (((PWORD) szBuffer)[0]) );
 						sv = newSVpv( (char *) szTemp, strlen( (char *) szTemp ) );
 						hv_store( hv, "LangID", strlen( "LangID" ), sv, 0 );
 						if( VerLanguageName( (((PWORD) szBuffer)[0]), szTemp, 50) )
 						{
 							sv = newSVpv( (char *) szTemp, strlen( (char *) szTemp ) );
 							hv_store( hv, "Language", strlen( "Language" ), sv, 0 );
 						}
							//	End Language specific stuff
 
						bResult = TRUE;
					}
				}
			}
		}
	}
	RETURNRESULT( bResult );
}

XS(XS_NT__AdminMisc_SetEnvVar)
{
	dXSARGS;
	int		iType = ENV_SYSTEM;
	BOOL	bResult = FALSE;
	DWORD	dTime = 5000;		//	Default to 5 seconds timeout
	
	if (items < 2 || items > 4){
		croak("Usage: " EXTENSION "::SetEnvVar($Name, $Value [, $Type [, $Timeout]])\n");
    }
	
	if (items > 2){
		iType = (int) SvIV(ST(2));
	}
	if (items > 3){
		dTime = (DWORD) SvIV(ST(3));
	}
	bResult = ProcessEnvVar(ENV_MODIFY, iType, (char *) SvPV(ST(0), na), (char *) SvPV(ST(1), na), dTime);

	RETURNRESULT( bResult );
}
	
XS(XS_NT__AdminMisc_DelEnvVar)
{
	dXSARGS;
	int		iType = ENV_SYSTEM;
	BOOL	bResult = FALSE;
	DWORD	dTime = 0;
	
	if (items < 1 || items > 3){
		croak("Usage: " EXTENSION "::DelEnvVar($Name [, $Type [, $Timeout]])\n");
    }

	if (items > 1){
		iType = (int) SvIV(ST(1));
	}
	if (items > 2){
		iType = (DWORD) SvIV(ST(2));
	}

	bResult = ProcessEnvVar(ENV_DELETE, iType, (char *) SvPV(ST(0), na), 0, dTime);

	RETURNRESULT( bResult );
}
	
XS(XS_NT__AdminMisc_GetEnvVar)
{
	dXSARGS;
	int		iType = ENV_SYSTEM;
	char	szValue[ENV_BUFFER_SIZE] = { 0 };
	BOOL	bResult = FALSE;
	
	if (items < 1 || items > 2){
		croak("Usage: " EXTENSION "::GetEnvVar($Name [, $Type])\n");
    }

	PUSHMARK( sp );

	if (items > 1){
		iType = (int) SvIV(ST(1));
	}

	bResult = ProcessEnvVar(ENV_QUERY, iType, (char *) SvPV(ST(0), na), szValue, 0);
	
	if (bResult){
		XPUSHs(sv_2mortal(newSVpv(szValue, strlen(szValue))));
	}else{
		XPUSHs(&sv_undef);
	}

	PUTBACK;
//	RETURNRESULT( bResult );
}


BOOL ProcessEnvVar(int iFunction, int iType, char *szName, char *szValue, DWORD dTime)
{
	char	*szKey = 0;
	HKEY	hRoot = 0, hKey = 0;
	BOOL	bResult = FALSE, bUpdate = FALSE;
	DWORD	dResult;
	DWORD	dTimeout = 5000;	//	We will default to waiting 5 seconds.
	
	switch(iType){
		case ENV_SYSTEM:
			hRoot = HKEY_LOCAL_MACHINE;
			szKey = ENV_SYSTEM_PATH;
			break;
		case ENV_USER:
			hRoot = HKEY_CURRENT_USER;
			szKey = ENV_USER_PATH;
			break;

		default:
			hRoot = 0;
			szKey = 0;
	}
	if (dTime != 0){
			//	We want to round up to the next second.
		dTimeout = dTime * 1000;
	}
	
	if (hRoot){
		int	iTemp, iCount = 0;

		if (RegOpenKeyEx(hRoot, szKey, 0, KEY_SET_VALUE | KEY_QUERY_VALUE, &hKey) == ERROR_SUCCESS){
			switch (iFunction){
				case ENV_DELETE:
					if (RegDeleteValue(hKey, szName) == ERROR_SUCCESS){
						bUpdate = bResult = TRUE;
					}
					break;

				case ENV_MODIFY:
					
					for(iTemp = strlen(szValue); iTemp; iTemp--){
						if (szValue[iTemp - 1] == '%') ++iCount;
					}

					if (RegSetValueEx(hKey, szName, 0, (iCount)? REG_EXPAND_SZ:REG_SZ, (BYTE *) szValue, strlen(szValue) + 1) == ERROR_SUCCESS){
						bUpdate = bResult = TRUE;
					}
					break;

				case ENV_QUERY:
					{
						DWORD	dType, dSize = ENV_BUFFER_SIZE;
						if (RegQueryValueEx(hKey, szName, 0, &dType, (LPBYTE) szValue, &dSize) == ERROR_SUCCESS){
							bResult = TRUE;
						}
					}

				default:
					break;
			}
		}
	}
	if (bUpdate){
		SendMessageTimeout(	HWND_BROADCAST, 
							WM_WININICHANGE, 
							0, 
							(LPARAM) "Environment",
							SMTO_ABORTIFHUNG,
							dTimeout,
							&dResult);
	}

	return bResult;
}



XS(XS_NT__AdminMisc_GetGroups)
{
	dXSARGS;
	LPWSTR	lpwMachine;												   
	char	*pszMachine = NULL;
	BYTE	*pBuffer = NULL;
	DWORD	dwGroupType = GROUP_TYPE_ALL;
	DWORD	dwRead = 0, dwRemain = 0, dwTotal = 0, dwResume = 0;
	char	szBuffer[ 2048 ];
	AV	*av = NULL;
	SV	*sv = NULL;
	DWORD	dwError = 0;
	BOOL bContinue = TRUE;

	if( 3 != items )
	{
		croak( "Usage: " EXTENSION "::GetGroups( $Server, $GroupType, \\@List )\n" );
    }
	
	PUSHMARK( sp );

	pszMachine = GetDC( (char *) SvPV( ST( 0 ), na ), FALSE, FALSE );
	AllocateUnicode( (char*) pszMachine, lpwMachine );

	dwGroupType = SvIV( ST( 1 ) );

	av = (AV*) ST( 2 );
	if( SvROK( av ) )
	{
		av = (AV*) SvRV( (SV*) av );
	}

	if( SVt_PVAV == SvTYPE( av ) )
	{
		av_clear( (AV*) av );
	}

	do{
		if( ( GROUP_TYPE_ALL == dwGroupType ) || ( GROUP_TYPE_LOCAL == dwGroupType ) )
		{
			dwError = NetLocalGroupEnum( lpwMachine,
										 1,
										 (LPBYTE *) &pBuffer,
										 4096,					//	This should be a good amount
										 &dwRead,
										 &dwRemain,
										 &dwResume );
		}
		else
		{
					dwError = NetGroupEnum( lpwMachine,
										 1,
										 (LPBYTE *) &pBuffer,
										 4096,					//	This should be a good amount
										 &dwRead,
										 &dwRemain,
										 &dwResume );
		}
	

		if( NERR_Success == dwError )
		{
			GROUP_INFO_1 *pGroupInfo = (GROUP_INFO_1 *) pBuffer;

			while( dwRead-- )
			{
				dwTotal++;
				if(NULL != av )
				{

					UnicodeToAnsi( pGroupInfo[ dwRead ].grpi1_name, (char *) szBuffer, sizeof( szBuffer ) );
					av_push( (AV*) av, newSVpv( szBuffer, 0 ) );
				}
			}
			NetApiBufferFree( pBuffer );
			pBuffer = NULL;
		}
		else
		{
			dwResume = 0;
		}

		if( 0 == dwResume )
		{
			bContinue = FALSE;
		}

		if( ( 0 == dwResume ) && ( dwGroupType == GROUP_TYPE_ALL ) )
		{
			dwGroupType = GROUP_TYPE_GLOBAL;
			bContinue = TRUE;
		}
	}
	while( TRUE == bContinue );

	FreeUnicode( lpwMachine );

	if( ( NERR_Success != dwError ) && ( 0 != dwTotal ) )
	{
		XPUSHs( (SV*) &sv_undef );
	}
	else
	{
		XPUSHs( newSViv( dwTotal ) );
	}

	PUTBACK;
}

XS( XS_NT__AdminMisc_GetVersion )
{
	dXSARGS;
	PUSHMARK( sp );

	XPUSHs( sv_2mortal( newSVpv( VERSION, strlen( VERSION ) ) ) );
	
	PUTBACK;
}



XS(boot_Win32__AdminMisc)
{
	dXSARGS;
	char* file = __FILE__;

	newXS( EXTENSION "::constant", XS_NT__AdminMisc_constant, file);
	newXS( EXTENSION "::GetError", XS_NT__AdminMisc_GetError, file);
	newXS( EXTENSION "::UserGetAttributes", XS_NT__AdminMisc_UserGetAttributes, file);
	newXS( EXTENSION "::UserSetAttributes", XS_NT__AdminMisc_UserSetAttributes, file);

	newXS( EXTENSION "::GetLogonName", XS_NT__AdminMisc_GetLogonName, file);
	newXS( EXTENSION "::LogoffAsUser", XS_NT__AdminMisc_LogoffAsUser, file);
	newXS( EXTENSION "::LogonAsUser", XS_NT__AdminMisc_LogonAsUser, file);
	newXS( EXTENSION "::UserCheckPassword", XS_NT__AdminMisc_UserCheckPassword, file);
	newXS( EXTENSION "::UserChangePassword", XS_NT__AdminMisc_UserChangePassword, file);
	newXS( EXTENSION "::CreateProcessAsUser", XS_NT__AdminMisc_CreateProcessAsUser, file);

	newXS( EXTENSION "::GetHostName",			XS_NT__AdminMisc_GetHostName, file);
	newXS( EXTENSION "::gethostbyname",		XS_NT__AdminMisc_GetHostName, file);
	newXS( EXTENSION "::GetHostAddress",		XS_NT__AdminMisc_GetHostName, file);
	newXS( EXTENSION "::gethostbyaddr",		XS_NT__AdminMisc_GetHostName, file);
	newXS( EXTENSION "::DNSCache",				XS_NT__AdminMisc_DNSCache, file);
	newXS( EXTENSION "::DNSCacheSize",			XS_NT__AdminMisc_DNSCacheSize, file);
	newXS( EXTENSION "::DNSCacheCount", 		XS_NT__AdminMisc_DNSCacheCount, file);

	newXS( EXTENSION "::UserGetMiscAttributes",XS_NT__AdminMisc_UserGetMiscAttributes, file);
	newXS( EXTENSION "::UserSetMiscAttributes",XS_NT__AdminMisc_UserSetMiscAttributes, file);

	newXS( EXTENSION "::GetDriveSpace",		XS_NT__AdminMisc_GetDriveSpace, file);
	newXS( EXTENSION "::GetDrives",			XS_NT__AdminMisc_GetDrives, file);
	newXS( EXTENSION "::GetDriveGeometry",	XS_NT__AdminMisc_GetDriveGeometry, file);
	newXS( EXTENSION "::GetDriveType",		XS_NT__AdminMisc_GetDriveType, file);
	newXS( EXTENSION "::GetProcessorInfo",	XS_NT__AdminMisc_GetProcessorInfo, file);
	newXS( EXTENSION "::GetMemoryInfo",		XS_NT__AdminMisc_GetMemoryInfo, file);
	newXS( EXTENSION "::GetDC",				XS_NT__AdminMisc_GetDC, file);
	newXS( EXTENSION "::GetPDC",			XS_NT__AdminMisc_GetPDC, file);
	newXS( EXTENSION "::GetWinVersion",		XS_NT__AdminMisc_GetWinVersion, file);
	newXS( EXTENSION "::GetIdInfo",			XS_NT__AdminMisc_GetIdInfo, file);
	newXS( EXTENSION "::ExitWindows",		XS_NT__AdminMisc_ExitWindows, file);
	newXS( EXTENSION "::WriteINI",			XS_NT__AdminMisc_WriteINI, file);
	newXS( EXTENSION "::ReadINI",			XS_NT__AdminMisc_ReadINI, file);

	newXS( EXTENSION "::ShowWindow",		XS_NT__AdminMisc_ShowWindow, file);
	newXS( EXTENSION "::GetStdHandle",		XS_NT__AdminMisc_GetStdHandle, file);

	newXS( EXTENSION "::SetPassword",		XS_NT__AdminMisc_SetPassword, file);
	newXS( EXTENSION "::GetComputerName",	XS_NT__AdminMisc_GetComputerName, file);
	newXS( EXTENSION "::SetComputerName",	XS_NT__AdminMisc_SetComputerName, file);
	newXS( EXTENSION "::GetTOD",			XS_NT__AdminMisc_GetTOD, file);
	newXS( EXTENSION "::RenameUser",		XS_NT__AdminMisc_RenameUser, file);
	newXS( EXTENSION "::ScheduleAdd",		XS_NT__AdminMisc_ScheduleAdd, file);
	newXS( EXTENSION "::ScheduleDel",		XS_NT__AdminMisc_ScheduleDel, file);
	newXS( EXTENSION "::ScheduleGet",		XS_NT__AdminMisc_ScheduleGet, file);
	newXS( EXTENSION "::ScheduleList",		XS_NT__AdminMisc_ScheduleList, file);
	newXS( EXTENSION "::GetFileInfo",		XS_NT__AdminMisc_GetFileInfo, file);
	newXS( EXTENSION "::SetEnvVar",			XS_NT__AdminMisc_SetEnvVar, file);
	newXS( EXTENSION "::DelEnvVar",			XS_NT__AdminMisc_DelEnvVar, file);
	newXS( EXTENSION "::GetEnvVar",				XS_NT__AdminMisc_GetEnvVar, file);

	newXS( EXTENSION "::GetVolumeInfo",			XS_NT__AdminMisc_GetVolumeInfo, file);
	newXS( EXTENSION "::SetVolumeLabel",		XS_NT__AdminMisc_SetVolumeLabel, file);

	newXS( EXTENSION "::GetGroups"	,			XS_NT__AdminMisc_GetGroups, file);
	newXS( EXTENSION "::GetVersion",            XS_NT__AdminMisc_GetVersion, file);

	newXS( EXTENSION "::CreateProcess", XS_NT__AdminMisc_CreateProcess, file);


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
				/*
					Initialize the Winsock
				*/
			if (wsErrorStatus = WSAStartup(0x0101, &wsaData)){
				iWinsockActive = 0;
			}else{
				iWinsockActive = 1;
				ResetDNSCache();
			}
				//	Allocate a TLS slot and check for an error.
			if ((gdTlsSlot = TlsAlloc()) == 0xFFFFFFFF){
				bResult = FALSE;
			}

			break;

			case DLL_THREAD_ATTACH:
				TlsSetValue(gdTlsSlot, 0);
				break;

			case DLL_THREAD_DETACH:
					//	Clear the TLS slot for this thread	
				TlsSetValue(gdTlsSlot, 0);
				break;
			
		case DLL_PROCESS_DETACH:
			if (TlsGetValue(gdTlsSlot)){
				LogoffImpersonatedUser(0);
			}
			if (iWinsockActive){
				WSACleanup();
			}
			ResetDNSCache();
			TlsFree(gdTlsSlot);
			break;

	}
	return bResult;
}



/*

  TODO:
	-	Activeware MUST remove the "<Unknown>" domain when Win32::DomainName()
		is called and you are unable to determine the domain name.

	-	Test on a live domain connection:
		- The result of Get(P)DC() with '', domain and a server name.

*/
