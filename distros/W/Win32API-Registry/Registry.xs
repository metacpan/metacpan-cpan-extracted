/* Win32API/Registry.xs */

#ifdef __cplusplus
//extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
/*#include "patchlevel.h"*/

/* Uncomment the next line unless set "WRITE_PERL=>1" in Makefile.PL: */
#define NEED_newCONSTSUB
#include "ppport.h"

#define  WIN32_LEAN_AND_MEAN	/* Tell windows.h to skip much */
#include <windows.h>

#ifdef __cplusplus
//}
#endif

/*CONSTS_DEFINED*/

#define oDWORD	DWORD
#define oHKEY	HKEY

#ifndef UNICODE
/* (Other places in this module probably assume UNICODE not defined.) */
# define ValEntA	VALENT
#else
# define ValEntW	VALENT
#endif

/* Some non-Microsoft compilers don't define VALENTA and VALENTW [they just
 * define VALENT].  The partly-evil C<typedef> prevents us from just using
 * C<#ifdef VALENTA>.  Uncomment the next line if you need to: */
/*#define NO_VALENTA*/
#ifndef NO_VALENTA
# ifndef UNICODE
#  define ValEntW	VALENTW
# else
#  define ValEntA	VALENTA
# endif
#else
    struct rValEnt {
# ifndef UNICODE
#  define ValEntW struct rValEnt
	LPWSTR	ve_valuename;
# else
#  define ValEntA struct rValEnt
	LPSTR	ve_valuename;
# endif
	DWORD	ve_valuelen;
	DWORD	ve_valueptr;
	DWORD	ve_type;
    };
/*# ifdef  */
#endif /* NO_VALENTA */


#ifndef DEBUGGING
# define	Debug(list)	/*Nothing*/
#else
# define	Debug(list)	ErrPrintf list
# include <stdarg.h>
    static void
    ErrPrintf( const char *sFmt, ... )
    {
      va_list aArgs;
      static char *sEnv= NULL;
      DWORD nErr= GetLastError();
	if(  NULL == sEnv  ) {
	    if(  NULL == ( sEnv= getenv("DEBUG_WIN32API_REGISTRY") )  )
		sEnv= "";
	}
	if(  '\0' == *sEnv  )
	    return;
	va_start( aArgs, sFmt );
	vfprintf( stderr, sFmt, aArgs );
	va_end( aArgs );
	SetLastError( nErr );
    }
#endif /* DEBUGGING */


#include "buffers.h"	/* Include this after DEBUGGING setup finished */


static LONG uLastRegErr= 0;

static bool
ErrorRet( DWORD uErr )
{
    if(  ERROR_SUCCESS == uErr  )
	return( TRUE );
    SetLastError( uLastRegErr= uErr );
    return FALSE;
}




MODULE = Win32API::Registry		PACKAGE = Win32API::Registry		

PROTOTYPES: DISABLE


LONG
_regLastError( uError=0 )
	DWORD	uError
    CODE:
	if(  1 <= items  ) {
	    uLastRegErr= uError;
	}
	RETVAL= uLastRegErr;
    OUTPUT:
	RETVAL


bool
AllowPriv( sPrivName, bEnable )
	char *	sPrivName
	BOOL	bEnable
    PREINIT:
	HANDLE			hToken= INVALID_HANDLE_VALUE;
	TOKEN_PRIVILEGES	tokPrivNew;
    CODE:
	tokPrivNew.PrivilegeCount= 1;
	if(  bEnable  ) {
	    tokPrivNew.Privileges[0].Attributes= SE_PRIVILEGE_ENABLED;
	} else {
	    tokPrivNew.Privileges[0].Attributes= 0;
	}
	RETVAL= FALSE;
	if(  OpenProcessToken( GetCurrentProcess(),
	       TOKEN_ADJUST_PRIVILEGES, &hToken )
	 &&  LookupPrivilegeValue( NULL, sPrivName,
	       &tokPrivNew.Privileges[0].Luid )
	) {
	    SetLastError( ERROR_SUCCESS );
	    AdjustTokenPrivileges( hToken, FALSE, &tokPrivNew,
	      0, NULL, NULL );
	    if(  ERROR_SUCCESS == GetLastError()  ) {
		RETVAL= TRUE;
	    }
	}
	if(  ! RETVAL  ) {
	    if(  INVALID_HANDLE_VALUE != hToken  ) {
		DWORD uErr= GetLastError();
		CloseHandle( hToken );
		SetLastError( uErr );
	    }
	    uLastRegErr= GetLastError();
	}
    OUTPUT:
	RETVAL


BOOL
AbortSystemShutdownA( sComputerName )
	char *	sComputerName
    CODE:
	RETVAL= AbortSystemShutdownA( sComputerName );
	if(  ! RETVAL  ) {
	    uLastRegErr= GetLastError();
	}
    OUTPUT:
	RETVAL


BOOL
AbortSystemShutdownW( swComputerName )
	WCHAR *	swComputerName
    CODE:
	RETVAL= AbortSystemShutdownW( swComputerName );
	if(  ! RETVAL  ) {
	    uLastRegErr= GetLastError();
	}
    OUTPUT:
	RETVAL


BOOL
InitiateSystemShutdownA( sComputer, sMessage, uTimeoutSecs, bForce, bReboot )
	char *	sComputer
	char *	sMessage
	DWORD	uTimeoutSecs
	BOOL	bForce
	BOOL	bReboot
    CODE:
	RETVAL= InitiateSystemShutdownA(
	  sComputer, sMessage, uTimeoutSecs, bForce, bReboot );
	if(  ! RETVAL  ) {
	    uLastRegErr= GetLastError();
	}
    OUTPUT:
	RETVAL


BOOL
InitiateSystemShutdownW( swComputer, swMessage, uTimeoutSecs, bForce, bReboot )
	WCHAR *	swComputer
	WCHAR *	swMessage
	DWORD	uTimeoutSecs
	BOOL	bForce
	BOOL	bReboot
    CODE:
	RETVAL= InitiateSystemShutdownW(
	  swComputer, swMessage, uTimeoutSecs, bForce, bReboot );
	if(  ! RETVAL  ) {
	    uLastRegErr= GetLastError();
	}
    OUTPUT:
	RETVAL


bool
RegCloseKey( hKey )
	HKEY	hKey
    CODE:
	RETVAL= ErrorRet(  RegCloseKey( hKey )  );
    OUTPUT:
	RETVAL


bool
RegConnectRegistryA( sComputer, hRootKey, ohKey )
	char *	sComputer
	HKEY	hRootKey
	oHKEY *	ohKey
    CODE:
	RETVAL= ErrorRet(  RegConnectRegistryA(
			     sComputer, hRootKey, ohKey )  );
    OUTPUT:
	RETVAL
	ohKey


bool
RegConnectRegistryW( swComputer, hRootKey, ohKey )
	WCHAR *	swComputer
	HKEY	hRootKey
	HKEY *	ohKey
    CODE:
	RETVAL= ErrorRet(  RegConnectRegistryW(
			     swComputer, hRootKey, ohKey )  );
    OUTPUT:
	RETVAL
	ohKey


bool
RegCreateKeyA( hKey, sSubKey, ohSubKey )
	HKEY	hKey
	char *	sSubKey
	oHKEY *	ohSubKey
    CODE:
	RETVAL= ErrorRet(  RegCreateKeyA( hKey, sSubKey, ohSubKey )  );
    OUTPUT:
	RETVAL
	ohSubKey


bool
RegCreateKeyW( hKey, swSubKey, ohSubKey )
	HKEY	hKey
	WCHAR *	swSubKey
	oHKEY *	ohSubKey
    CODE:
	RETVAL= ErrorRet(  RegCreateKeyW( hKey, swSubKey, ohSubKey )  );
    OUTPUT:
	RETVAL
	ohSubKey


bool
RegCreateKeyExA(hKey,sSubKey,uZero,sClass,uOpts,uAccess,pSecAttr,ohNewKey,ouDisp)
	HKEY		hKey
	char *		sSubKey
	DWORD		uZero
	char *		sClass
	DWORD		uOpts
	REGSAM		uAccess
	void *		pSecAttr
	oHKEY *		ohNewKey
	oDWORD *	ouDisp
    CODE:
	RETVAL= ErrorRet(  RegCreateKeyExA( hKey, sSubKey, uZero,
	  sClass, uOpts, uAccess, (SECURITY_ATTRIBUTES *) pSecAttr,
	  ohNewKey, ouDisp )  );
    OUTPUT:
	RETVAL
	ohNewKey
	ouDisp


bool
RegCreateKeyExW(hKey,swSubKey,uZero,swClass,uOpts,uAccess,pSecAttr,ohNewKey,ouDisp)
	HKEY		hKey
	WCHAR *		swSubKey
	DWORD		uZero
	WCHAR *		swClass
	DWORD		uOpts
	REGSAM		uAccess
	void *		pSecAttr
	oHKEY *		ohNewKey
	oDWORD *	ouDisp
    CODE:
	RETVAL= ErrorRet(  RegCreateKeyExW( hKey, swSubKey, uZero,
	  swClass, uOpts, uAccess, (SECURITY_ATTRIBUTES *) pSecAttr,
	  ohNewKey, ouDisp )  );
    OUTPUT:
	RETVAL
	ohNewKey
	ouDisp


bool
RegDeleteKeyA( hKey, sSubKey )
	HKEY	hKey
	char *	sSubKey
    CODE:
	RETVAL= ErrorRet(  RegDeleteKeyA( hKey, sSubKey )  );
    OUTPUT:
	RETVAL


bool
RegDeleteKeyW( hKey, swSubKey )
	HKEY	hKey
	WCHAR *	swSubKey
    CODE:
	RETVAL= ErrorRet(  RegDeleteKeyW( hKey, swSubKey )  );
    OUTPUT:
	RETVAL


bool
RegDeleteValueA( hKey, sValueName )
	HKEY	hKey
	char *	sValueName
    CODE:
	RETVAL= ErrorRet(  RegDeleteValueA( hKey, sValueName )  );
    OUTPUT:
	RETVAL


bool
RegDeleteValueW( hKey, swValueName )
	HKEY	hKey
	WCHAR *	swValueName


bool
_RegEnumKeyA( hKey, uIndex, osName, ilNameSize )
	HKEY	hKey
	DWORD	uIndex
	char *	osName= NO_INIT
	DWORD	ilNameSize= init_buf_l($arg);
    CODE:
	grow_buf_l( osName,ST(2),char *, ilNameSize,ST(3) );
	RETVAL= ErrorRet(  RegEnumKeyA( hKey, uIndex, osName, ilNameSize )  );
    OUTPUT:
	RETVAL
	osName	trunc_buf_z( RETVAL, osName,ST(2) );


bool
_RegEnumKeyW( hKey, uIndex, oswName, ilwNameSize )
	HKEY	hKey
	DWORD	uIndex
	WCHAR *	oswName= NO_INIT
	DWORD	ilwNameSize= init_buf_lw($arg);
    CODE:
	grow_buf_lw( oswName,ST(2), ilwNameSize,ST(3) );
	RETVAL= ErrorRet(  RegEnumKeyW( hKey, uIndex, oswName, ilwNameSize )  );
    OUTPUT:
	RETVAL
	oswName	trunc_buf_zw( RETVAL, oswName,ST(2) );


bool
_RegEnumKeyExA(hKey,uIndex,osName,iolName,pNull,osClass,iolClass,opftLastWrite)
	HKEY		hKey
	DWORD		uIndex
	char *		osName= NO_INIT
	DWORD *		iolName= NO_INIT
	DWORD *		pNull
	char *		osClass= NO_INIT
	DWORD *		iolClass= NO_INIT
	FILETIME *	opftLastWrite;
    PREINIT:
	DWORD		uErr;
    CODE:
	init_buf_pl( iolName,ST(3), DWORD * );
	grow_buf_pl( osName,ST(2),char *, iolName,ST(3),DWORD * );
	init_buf_pl( iolClass,ST(6),DWORD * );
	grow_buf_pl( osClass,ST(5),char *, iolClass,ST(6),DWORD * );
	uErr= RegEnumKeyExA( hKey, uIndex, osName, iolName,
	  pNull, osClass, iolClass, opftLastWrite );
	if(  ERROR_MORE_DATA == uErr
	 &&  ( autosize(ST(3)) || autosize(ST(6)) )  ) {
	    grow_buf_pl( osName,ST(2),char *, iolName,ST(3),DWORD * );
	    grow_buf_pl( osClass,ST(5),char *, iolClass,ST(6),DWORD * );
	    uErr= RegEnumKeyExA( hKey, uIndex, osName, iolName,
	      pNull, osClass, iolClass, opftLastWrite );
	}
	RETVAL= ErrorRet( uErr );
    OUTPUT:
	RETVAL
	osName	trunc_buf_pl( RETVAL, osName,ST(2), iolName );
	iolName
	pNull
	osClass	trunc_buf_pl( RETVAL, osClass,ST(5), iolClass );
	iolClass
	opftLastWrite


bool
_RegEnumKeyExW(hKey,uIndex,oswName,iolwName,pNull,oswClass,iolwClass,opftLastWrite)
	HKEY		hKey
	DWORD		uIndex
	WCHAR *		oswName= NO_INIT
	DWORD *		iolwName= NO_INIT
	DWORD *		pNull
	WCHAR *		oswClass= NO_INIT
	DWORD *		iolwClass= NO_INIT
	FILETIME *	opftLastWrite
    PREINIT:
	DWORD		uErr;
    CODE:
	init_buf_plw( iolwName,ST(3),DWORD * );
	grow_buf_plw( oswName,ST(2), iolwName,ST(3),DWORD * );
	init_buf_plw( iolwClass,ST(6),DWORD * );
	grow_buf_plw( oswClass,ST(5), iolwClass,ST(6),DWORD * );
	uErr= RegEnumKeyExW( hKey, uIndex, oswName, iolwName,
	  pNull, oswClass, iolwClass, opftLastWrite );
	if(  ERROR_MORE_DATA == uErr
	 &&  ( autosize(ST(3)) || autosize(ST(6)) )  ) {
	    grow_buf_plw( oswName,ST(2), iolwName,ST(3),DWORD * );
	    grow_buf_plw( oswClass,ST(5), iolwClass,ST(6),DWORD * );
	    uErr= RegEnumKeyExW( hKey, uIndex, oswName, iolwName,
	      pNull, oswClass, iolwClass, opftLastWrite );
	}
	RETVAL= ErrorRet( uErr );
    OUTPUT:
	RETVAL
	oswName		trunc_buf_plw( RETVAL, oswName,ST(2), iolwName );
	iolwName
	pNull
	oswClass	trunc_buf_plw( RETVAL, oswClass,ST(5), iolwClass );
	iolwClass
	opftLastWrite


bool
_RegEnumValueA(hKey,uIndex,osName,iolName,pNull,ouType,opData,iolData)
	HKEY		hKey
	DWORD		uIndex
	char *		osName= NO_INIT
	DWORD *		iolName= NO_INIT
	DWORD *		pNull
	oDWORD *	ouType
	BYTE *		opData= NO_INIT
	DWORD *		iolData= NO_INIT
    PREINIT:
	DWORD	uErr;
    CODE:
	init_buf_pl( iolName,ST(3),DWORD * );
	grow_buf_pl( osName,ST(2),char *, iolName,ST(3),DWORD * );
	init_buf_pl( iolData,ST(7),DWORD * );
	grow_buf_pl( opData,ST(6),BYTE *, iolData,ST(7),DWORD * );
	if(  NULL == ouType  &&  NULL != opData  &&  null_arg(ST(7))  )
	    ouType= (DWORD *) TempAlloc( sizeof(DWORD) );
	uErr= RegEnumValueA( hKey, uIndex, osName,
	  iolName, pNull, ouType, opData, iolData );
	if(  ERROR_MORE_DATA == uErr
	 &&  ( autosize(ST(3)) || autosize(ST(7)) )  ) {
	    grow_buf_pl( osName,ST(2),char *, iolName,ST(3),DWORD * );
	    grow_buf_pl( opData,ST(6),BYTE *, iolData,ST(7),DWORD * );
	    uErr= RegEnumValueA( hKey, uIndex, osName,
	      iolName, pNull, ouType, opData, iolData );
	}
	RETVAL= ErrorRet( uErr );
	/* Traim trailing '\0' from REG*_SZ values if iolData was C<[]>: */
	if(  RETVAL  &&  NULL != opData  &&  NULL != ouType
	 &&  ( REG_SZ == *ouType || REG_EXPAND_SZ == *ouType )
	 &&  null_arg(ST(7))  &&  '\0' == opData[*iolData-1]  )
	    --*iolData;
    OUTPUT:
	RETVAL
	osName		trunc_buf_pl( RETVAL, osName,ST(2), iolName );
	iolName
	pNull
	ouType
	opData		trunc_buf_pl( RETVAL, opData,ST(6), iolData );
	iolData


bool
_RegEnumValueW(hKey,uIndex,oswName,iolwName,pNull,ouType,opData,iolData)
	HKEY		hKey
	DWORD		uIndex
	WCHAR *		oswName= NO_INIT
	DWORD *		iolwName= NO_INIT
	DWORD *		pNull
	oDWORD *	ouType
	BYTE *		opData= NO_INIT
	DWORD *		iolData= NO_INIT
    PREINIT:
	DWORD	uErr;
    CODE:
	init_buf_plw( iolwName,ST(3),DWORD * );
	grow_buf_plw( oswName,ST(2), iolwName,ST(3),DWORD * );
	init_buf_pl( iolData,ST(7),DWORD * );
	grow_buf_pl( opData,ST(6),BYTE *, iolData,ST(7),DWORD * );
	if(  NULL == ouType  &&  NULL != opData  &&  null_arg(ST(7))  )
	    ouType= (DWORD *) TempAlloc( sizeof(DWORD) );
	uErr= RegEnumValueW( hKey, uIndex, oswName, iolwName,
	  pNull, ouType, opData, iolData );
	if(  ERROR_MORE_DATA == uErr
	 &&  ( autosize(ST(3)) || autosize(ST(7)) )  ) {
	    grow_buf_plw( oswName,ST(2), iolwName,ST(3),DWORD * );
	    grow_buf_pl( opData,ST(6),BYTE *, iolData,ST(7),DWORD * );
	    uErr= RegEnumValueW( hKey, uIndex, oswName, iolwName,
	      pNull, ouType, opData, iolData );
	}
	RETVAL= ErrorRet( uErr );
	/* Traim trailing L'\0' from REG*_SZ values if iolData was C<[]>: */
	if(  RETVAL  &&  NULL != opData  &&  NULL != ouType
	 &&  ( REG_SZ == *ouType || REG_EXPAND_SZ == *ouType )
	 &&  null_arg(ST(7))
	 &&  L'\0' == ((WCHAR *)opData)[(*iolData/sizeof(WCHAR))-1]  )
	    *iolData -= sizeof(WCHAR);
    OUTPUT:
	RETVAL
	oswName		trunc_buf_plw( RETVAL, oswName,ST(2), iolwName );
	iolwName
	pNull
	ouType
	opData		trunc_buf_pl( RETVAL, opData,ST(6), iolData );
	iolData


bool
RegFlushKey( hKey )
	HKEY	hKey
    CODE:
	RETVAL= ErrorRet(  RegFlushKey( hKey )  );
    OUTPUT:
	RETVAL


bool
_RegGetKeySecurity( hKey, uSecInfo, opSecDesc, iolSecDesc )
	HKEY			hKey
	SECURITY_INFORMATION	uSecInfo
	SECURITY_DESCRIPTOR *	opSecDesc= NO_INIT
	DWORD *			iolSecDesc= NO_INIT
    PREINIT:
	DWORD			uErr;
    CODE:
	init_buf_pl( iolSecDesc,ST(3),DWORD * );
	grow_buf_pl( opSecDesc,ST(2),SECURITY_DESCRIPTOR *,
	  iolSecDesc,ST(3),DWORD * );
	uErr= RegGetKeySecurity( hKey, uSecInfo, opSecDesc, iolSecDesc );
	if(  ERROR_INSUFFICIENT_BUFFER == uErr  &&  autosize(ST(3))  ) {
	    grow_buf_pl( opSecDesc,ST(2),SECURITY_DESCRIPTOR *,
	      iolSecDesc,ST(3),DWORD * );
	    uErr= RegGetKeySecurity( hKey, uSecInfo, opSecDesc, iolSecDesc );
	}
	RETVAL= ErrorRet( uErr );
	if(  RETVAL  &&  NULL != iolSecDesc  )
	    *iolSecDesc= GetSecurityDescriptorLength(opSecDesc);
    OUTPUT:
	RETVAL
	opSecDesc	trunc_buf_pl( RETVAL, opSecDesc,ST(2), iolSecDesc );
	iolSecDesc


bool
RegLoadKeyA( hKey, sSubKey, sFileName )
	HKEY	hKey
	char *	sSubKey
	char *	sFileName
    CODE:
	RETVAL= ErrorRet(  RegLoadKeyA( hKey, sSubKey, sFileName )  );
    OUTPUT:
	RETVAL


bool
RegLoadKeyW( hKey, swSubKey, swFileName )
	HKEY	hKey
	WCHAR *	swSubKey
	WCHAR *	swFileName
    CODE:
	RETVAL= ErrorRet(  RegLoadKeyW( hKey, swSubKey, swFileName )  );
    OUTPUT:
	RETVAL


bool
RegNotifyChangeKeyValue( hKey, bWatchSubtree, uNotifyFilter, hEvent, bAsync )
	HKEY	hKey
	BOOL	bWatchSubtree
	DWORD	uNotifyFilter
	HANDLE	hEvent
	BOOL	bAsync
    CODE:
	RETVAL= ErrorRet(  RegNotifyChangeKeyValue(
	  hKey, bWatchSubtree, uNotifyFilter, hEvent, bAsync )  );
    OUTPUT:
	RETVAL


bool
RegOpenKeyA( hKey, sSubKey, ohSubKey )
	HKEY	hKey
	char *	sSubKey
	oHKEY *	ohSubKey
    CODE:
	RETVAL= ErrorRet(  RegOpenKeyA( hKey, sSubKey, ohSubKey )  );
    OUTPUT:
	RETVAL
	ohSubKey


bool
RegOpenKeyW( hKey, swSubKey, ohSubKey )
	HKEY	hKey
	WCHAR *	swSubKey
	oHKEY *	ohSubKey
    CODE:
	RETVAL= ErrorRet(  RegOpenKeyW( hKey, swSubKey, ohSubKey )  );
    OUTPUT:
	RETVAL
	ohSubKey


bool
RegOpenKeyExA( hKey, sSubKey, uOptions, uAccess, ohSubKey )
	HKEY	hKey
	char *	sSubKey
	DWORD	uOptions
	REGSAM	uAccess
	oHKEY *	ohSubKey
    CODE:
	RETVAL= ErrorRet(  RegOpenKeyExA(
	  hKey, sSubKey, uOptions, uAccess, ohSubKey )  );
    OUTPUT:
	RETVAL
	ohSubKey


bool
RegOpenKeyExW( hKey, swSubKey, uOptions, uAccess, ohSubKey )
	HKEY	hKey
	WCHAR *	swSubKey
	DWORD	uOptions
	REGSAM	uAccess
	oHKEY *	ohSubKey
    CODE:
	RETVAL= ErrorRet(  RegOpenKeyExW(
	  hKey, swSubKey, uOptions, uAccess, ohSubKey )  );
    OUTPUT:
	RETVAL
	ohSubKey


bool
_RegQueryInfoKeyA( hKey, osClass, iolClass, pNull, ocSubKeys, olSubKey, olSubClass, ocValues, olValName, olValData, olSecDesc, opftTime )
	HKEY		hKey
	char *		osClass= NO_INIT
	DWORD *		iolClass= NO_INIT
	DWORD *		pNull
	oDWORD *	ocSubKeys
	oDWORD *	olSubKey
	oDWORD *	olSubClass
	oDWORD *	ocValues
	oDWORD *	olValName
	oDWORD *	olValData
	oDWORD *	olSecDesc
	FILETIME *	opftTime
    PREINIT:
	DWORD		uErr;
    CODE:
	init_buf_pl( iolClass,ST(2),DWORD * );
	grow_buf_pl( osClass,ST(1),char *, iolClass,ST(2),DWORD * );
	uErr= RegQueryInfoKeyA( hKey, osClass, iolClass,
	  pNull, ocSubKeys, olSubKey, olSubClass, ocValues,
	  olValName, olValData, olSecDesc, opftTime );
	if(  ERROR_MORE_DATA == uErr  &&  autosize(ST(2))  ) {
	    grow_buf_pl( osClass,ST(1),char *, iolClass,ST(2),DWORD * );
	    uErr= RegQueryInfoKeyA( hKey, osClass, iolClass,
	      pNull, ocSubKeys, olSubKey, olSubClass, ocValues,
	      olValName, olValData, olSecDesc, opftTime );
	}
	RETVAL= ErrorRet( uErr );
    OUTPUT:
	RETVAL
	osClass		trunc_buf_pl( RETVAL, osClass,ST(1), iolClass );
	iolClass
	pNull
	ocSubKeys
	olSubKey
	olSubClass
	ocValues
	olValName
	olValData
	olSecDesc
	opftTime


bool
_RegQueryInfoKeyW( hKey, oswClass, iolwClass, pNull, ocSubKeys, olwSubKey, olwSubClass, ocValues, olwValName, olValData, olSecDesc, opftTime )
	HKEY		hKey
	WCHAR *		oswClass= NO_INIT
	DWORD *		iolwClass= NO_INIT
	DWORD *		pNull
	oDWORD *	ocSubKeys
	oDWORD *	olwSubKey
	oDWORD *	olwSubClass
	oDWORD *	ocValues
	oDWORD *	olwValName
	oDWORD *	olValData
	oDWORD *	olSecDesc
	FILETIME *	opftTime
    PREINIT:
	DWORD		uErr;
    CODE:
	init_buf_plw( iolwClass,ST(2),DWORD * );
	grow_buf_plw( oswClass,ST(1), iolwClass,ST(2),DWORD * );
	uErr= RegQueryInfoKeyW( hKey, oswClass, iolwClass,
	  pNull, ocSubKeys, olwSubKey, olwSubClass, ocValues,
	  olwValName, olValData, olSecDesc, opftTime );
	if(  ERROR_MORE_DATA == uErr  &&  autosize(ST(2))  ) {
	    grow_buf_plw( oswClass,ST(1), iolwClass,ST(2),DWORD * );
	    uErr= RegQueryInfoKeyW( hKey, oswClass, iolwClass,
	      pNull, ocSubKeys, olwSubKey, olwSubClass, ocValues,
	      olwValName, olValData, olSecDesc, opftTime );
	}
	RETVAL= ErrorRet( uErr );
    OUTPUT:
	RETVAL
	oswClass	trunc_buf_plw( RETVAL, oswClass,ST(1), iolwClass );
	iolwClass
	pNull
	ocSubKeys
	olwSubKey
	olwSubClass
	ocValues
	olwValName
	olValData
	olSecDesc
	opftTime

bool
_RegQueryMultipleValuesA(hKey,ioarValueEnts,icValueEnts,opBuffer,iolBuffer)
	HKEY		hKey
	ValEntA *	ioarValueEnts
	DWORD		icValueEnts
	char *		opBuffer= NO_INIT
	DWORD *		iolBuffer= NO_INIT
    PREINIT:
	DWORD		uErr;
    CODE:
	if(  NULL != ioarValueEnts  ) {
	    if(  0 == icValueEnts  ) {
		icValueEnts= SvCUR(ST(1)) / sizeof(ValEntA);
	    }
	    if(  SvCUR(ST(1)) < icValueEnts * sizeof(ValEntA)  ) {
		croak( "%s: %s (%d bytes < %d * %d)",
		  "Win32API::Registry::_RegQueryMultipleValuesA",
		  "ioarValueEnts shorter than specified",
		  SvCUR(ST(1)), icValueEnts, sizeof(ValEntA) );
	    }
	}
	init_buf_pl( iolBuffer,ST(4),DWORD * );
	grow_buf_pl( opBuffer,ST(3),char *, iolBuffer,ST(4),DWORD * );
	uErr= RegQueryMultipleValuesA(
	  hKey, ioarValueEnts, icValueEnts, opBuffer, iolBuffer );
	if(  ERROR_MORE_DATA == uErr  &&  autosize(ST(4))  ) {
	    grow_buf_pl( opBuffer,ST(3),char *, iolBuffer,ST(4),DWORD * );
	    uErr= RegQueryMultipleValuesA(
	      hKey, ioarValueEnts, icValueEnts, opBuffer, iolBuffer );
	}
	RETVAL= ErrorRet( uErr );
    OUTPUT:
	RETVAL
	opBuffer	trunc_buf_pl( RETVAL, opBuffer,ST(3), iolBuffer );
	iolBuffer


bool
_RegQueryMultipleValuesW(hKey,ioarValueEnts,icValueEnts,opBuffer,iolBuffer)
	HKEY		hKey
	ValEntW *	ioarValueEnts
	DWORD		icValueEnts
	WCHAR *		opBuffer= NO_INIT
	DWORD *		iolBuffer= NO_INIT
    PREINIT:
	DWORD		uErr;
    CODE:
	if(  NULL != ioarValueEnts  ) {
	    if(  0 == icValueEnts  ) {
		icValueEnts= SvCUR(ST(1)) / sizeof(ValEntW);
	    }
	    if(  SvCUR(ST(1)) < icValueEnts * sizeof(ValEntW)  ) {
		croak( "%s: %s (%d bytes < %d * %d)",
		  "Win32API::Registry::_RegQueryMultipleValuesW",
		  "ioarValueEnts shorter than specified",
		  SvCUR(ST(1)), icValueEnts, sizeof(ValEntW) );
	    }
	}
	init_buf_pl( iolBuffer,ST(4),DWORD * );
	grow_buf_pl( opBuffer,ST(3),WCHAR *, iolBuffer,ST(4),DWORD * );
	uErr= RegQueryMultipleValuesW(
	  hKey, ioarValueEnts, icValueEnts, opBuffer, iolBuffer );
	if(  ERROR_MORE_DATA == uErr  &&  autosize(ST(4))  ) {
	    grow_buf_pl( opBuffer,ST(3),WCHAR *, iolBuffer,ST(4),DWORD * );
	    uErr= RegQueryMultipleValuesW(
	      hKey, ioarValueEnts, icValueEnts, opBuffer, iolBuffer );
	}
	RETVAL= ErrorRet( uErr );
    OUTPUT:
	RETVAL
	opBuffer	trunc_buf_pl( RETVAL, opBuffer,ST(3), iolBuffer );
	iolBuffer


bool
_RegQueryValueA( hKey, sSubKey, osValueData, iolValueData )
	HKEY	hKey
	char *	sSubKey
	char *	osValueData= NO_INIT
	LONG *	iolValueData= NO_INIT
    PREINIT:
	DWORD	uErr;
    CODE:
	init_buf_pl( iolValueData,ST(3),LONG * );
	grow_buf_pl( osValueData,ST(2),char *, iolValueData,ST(3),LONG * );
	uErr= RegQueryValueA( hKey, sSubKey, osValueData, iolValueData );
	if(  ERROR_MORE_DATA == uErr  &&  autosize(ST(3))  ) {
	    grow_buf_pl( osValueData,ST(2),char *, iolValueData,ST(3),LONG * );
	    uErr= RegQueryValueA( hKey, sSubKey, osValueData, iolValueData );
	}
	RETVAL= ErrorRet( uErr );
    OUTPUT:
	RETVAL
	osValueData	trunc_buf_pl( RETVAL, osValueData,ST(2), iolValueData );
	iolValueData


bool
_RegQueryValueW( hKey, swSubKey, oswValueData, iolValueData )
	HKEY	hKey
	WCHAR *	swSubKey
	WCHAR *	oswValueData= NO_INIT
	LONG *	iolValueData= NO_INIT
    PREINIT:
	DWORD	uErr;
    CODE:
	init_buf_pl( iolValueData,ST(3),LONG * );
	grow_buf_pl( oswValueData,ST(2),WCHAR *, iolValueData,ST(3),LONG * );
	uErr= RegQueryValueW( hKey, swSubKey, oswValueData, iolValueData );
	if(  ERROR_MORE_DATA == uErr  &&  autosize(ST(3))  ) {
	    grow_buf_pl( oswValueData,ST(2),WCHAR *,
	      iolValueData,ST(3),LONG * );
	    uErr= RegQueryValueW( hKey, swSubKey, oswValueData, iolValueData );
	}
	RETVAL= ErrorRet( uErr );
    OUTPUT:
	RETVAL
	oswValueData	trunc_buf_pl(RETVAL,oswValueData,ST(2),iolValueData);
	iolValueData


bool
_RegQueryValueExA( hKey, sName, pNull, ouType, opData, iolData )
	HKEY		hKey
	char *		sName
	DWORD *		pNull
	oDWORD *	ouType
	BYTE *		opData= NO_INIT
	DWORD *		iolData= NO_INIT
    PREINIT:
	DWORD	uErr;
    CODE:
	if(  NULL == ouType  &&  null_arg(ST(5))  )
	    ouType= (DWORD *) TempAlloc( sizeof(DWORD) );
	init_buf_pl( iolData,ST(5),DWORD * );
	grow_buf_pl( opData,ST(4),BYTE *, iolData,ST(5),DWORD * );
	uErr= RegQueryValueExA(
	  hKey, sName, pNull, ouType, opData, iolData );
	if(  ERROR_MORE_DATA == uErr  &&  autosize(ST(5))  ) {
	    grow_buf_pl( opData,ST(4),BYTE *, iolData,ST(5),DWORD * );
	    uErr= RegQueryValueExA(
	      hKey, sName, pNull, ouType, opData, iolData );
	}
	RETVAL= ErrorRet( uErr );
	/* Traim trailing '\0' from REG*_SZ values if iolData was C<[]>: */
	if(  RETVAL  &&  NULL != opData  &&  NULL != ouType
	 &&  ( REG_SZ == *ouType || REG_EXPAND_SZ == *ouType )
	 &&  *iolData >= 1  /* RT#37750 */
	 &&  null_arg(ST(5))  &&  '\0' == opData[*iolData-1]  )
	    --*iolData;
    OUTPUT:
	RETVAL
	pNull
	ouType
	opData	trunc_buf_pl( RETVAL, opData,ST(4), iolData );
	iolData


bool
_RegQueryValueExW( hKey, swName, pNull, ouType, opData, iolData )
	HKEY		hKey
	WCHAR *		swName
	DWORD *		pNull
	oDWORD *	ouType
	BYTE *		opData= NO_INIT
	DWORD *		iolData= NO_INIT
    PREINIT:
	DWORD	uErr;
    CODE:
	if(  NULL == ouType  &&  null_arg(ST(5))  )
	    ouType= (DWORD *) TempAlloc( sizeof(DWORD) );
	init_buf_pl( iolData,ST(5),DWORD * );
	grow_buf_pl( opData,ST(4),BYTE *, iolData,ST(5),DWORD * );
	uErr= RegQueryValueExW(
	  hKey, swName, pNull, ouType, opData, iolData );
	if(  ERROR_MORE_DATA == uErr  &&  autosize(ST(5))  ) {
	    grow_buf_pl( opData,ST(4),BYTE *, iolData,ST(5),DWORD * );
	    uErr= RegQueryValueExW(
	      hKey, swName, pNull, ouType, opData, iolData );
	}
	RETVAL= ErrorRet( uErr );
	/* Traim trailing L'\0' from REG*_SZ vals if iolData was C<[]>: */
	if(  RETVAL  &&  NULL != opData  &&  NULL != ouType
	 &&  ( REG_SZ == *ouType || REG_EXPAND_SZ == *ouType )
	 &&  null_arg(ST(5))
	 &&  *iolData >= sizeof(WCHAR) /* RT#37750 */
	 &&  L'\0' == ((WCHAR *)opData)[(*iolData/sizeof(WCHAR))-1]  )
	    *iolData -= sizeof(WCHAR);
    OUTPUT:
	RETVAL
	pNull
	ouType
	opData	trunc_buf_pl( RETVAL, opData,ST(4), iolData );
	iolData


bool
RegReplaceKeyA( hKey, sSubKey, sNewFile, sOldFile )
	HKEY	hKey
	char *	sSubKey
	char *	sNewFile
	char *	sOldFile
    CODE:
	RETVAL= ErrorRet(
	  RegReplaceKeyA( hKey, sSubKey, sNewFile, sOldFile )  );
    OUTPUT:
	RETVAL


bool
RegReplaceKeyW( hKey, swSubKey, swNewFile, swOldFile )
	HKEY	hKey
	WCHAR *	swSubKey
	WCHAR *	swNewFile
	WCHAR *	swOldFile
    CODE:
	RETVAL= ErrorRet(
	  RegReplaceKeyW( hKey, swSubKey, swNewFile, swOldFile )  );
    OUTPUT:
	RETVAL


bool
RegRestoreKeyA( hKey, sFileName, uFlags )
	HKEY	hKey
	char *	sFileName
	DWORD	uFlags
    CODE:
	RETVAL= ErrorRet(  RegRestoreKeyA( hKey, sFileName, uFlags )  );
    OUTPUT:
	RETVAL


bool
RegRestoreKeyW( hKey, swFileName, uFlags )
	HKEY	hKey
	WCHAR *	swFileName
	DWORD	uFlags
    CODE:
	RETVAL= ErrorRet(  RegRestoreKeyW( hKey, swFileName, uFlags )  );
    OUTPUT:
	RETVAL


bool
RegSaveKeyA( hKey, sFileName, pSecAttr )
	HKEY			hKey
	char *			sFileName
	SECURITY_ATTRIBUTES *	pSecAttr
    CODE:
	RETVAL= ErrorRet(  RegSaveKeyA( hKey, sFileName, pSecAttr )  );
    OUTPUT:
	RETVAL


bool
RegSaveKeyW( hKey, swFileName, pSecAttr )
	HKEY			hKey
	WCHAR *			swFileName
	SECURITY_ATTRIBUTES *	pSecAttr
    CODE:
	RETVAL= ErrorRet(  RegSaveKeyW( hKey, swFileName, pSecAttr )  );
    OUTPUT:
	RETVAL


bool
RegSetKeySecurity( hKey, uSecInfo, pSecDesc )
	HKEY			hKey
	SECURITY_INFORMATION	uSecInfo
	SECURITY_DESCRIPTOR *	pSecDesc
    CODE:
	RETVAL= ErrorRet(  RegSetKeySecurity( hKey, uSecInfo, pSecDesc )  );
    OUTPUT:
	RETVAL


bool
_RegSetValueA( hKey, sSubKey, uType, sValueData, lValueData )
	HKEY	hKey
	char *	sSubKey
	DWORD	uType
	char *	sValueData
	DWORD	lValueData
    CODE:
	if(  0 == lValueData  )
	    lValueData= SvCUR( ST(3) );
	RETVAL= ErrorRet(
	  RegSetValueA( hKey, sSubKey, uType, sValueData, lValueData )  );
    OUTPUT:
	RETVAL


bool
_RegSetValueW( hKey, swSubKey, uType, swValueData, lValueData )
	HKEY	hKey
	WCHAR *	swSubKey
	DWORD	uType
	WCHAR *	swValueData
	DWORD	lValueData
    CODE:
	if(  0 == lValueData  )
	    lValueData= SvCUR( ST(3) ) / sizeof(WCHAR);
	RETVAL= ErrorRet(
	  RegSetValueW( hKey, swSubKey, uType, swValueData, lValueData )  );
    OUTPUT:
	RETVAL


bool
_RegSetValueExA( hKey, sName, uZero, uType, pData, lData )
	HKEY	hKey
	char *	sName
	DWORD	uZero
	DWORD	uType
	BYTE *	pData
	DWORD	lData
    CODE:
	if(  0 == lData  ) {
	    lData= SvCUR( ST(4) );
	    if(  ( REG_SZ == uType || REG_EXPAND_SZ == uType )
	     &&  '\0' != pData[lData-1]  ) {
		pData[lData++]= '\0';	/* Should already be '\0', though. */
	    }
	}
	RETVAL= ErrorRet(  RegSetValueExA(
	  hKey, sName, uZero, uType, pData, lData )  );
    OUTPUT:
	RETVAL


bool
_RegSetValueExW( hKey, swName, uZero, uType, pData, lData )
	HKEY	hKey
	WCHAR *	swName
	DWORD	uZero
	DWORD	uType
	BYTE *	pData
	DWORD	lData
    CODE:
	if(  0 == lData  ) {
	    lData= SvCUR( ST(4) );
	    if(  ( REG_SZ == uType || REG_EXPAND_SZ == uType )
	     &&  L'\0' != ((WCHAR *)pData)[(lData/sizeof(WCHAR))-1]  ) {
		pData[lData/sizeof(WCHAR)]= L'\0'; /* Should already be L'\0' */
		lData += sizeof(WCHAR);
	    }
	}
	RETVAL= ErrorRet(  RegSetValueExW(
	  hKey, swName, uZero, uType, pData, lData )  );
    OUTPUT:
	RETVAL


bool
RegUnLoadKeyA( hKey, sSubKey )
	HKEY	hKey
	char *	sSubKey
    CODE:
	RETVAL= ErrorRet(  RegUnLoadKeyA( hKey, sSubKey )  );
    OUTPUT:
	RETVAL


bool
RegUnLoadKeyW( hKey, swSubKey )
	HKEY	hKey
	WCHAR *	swSubKey
    CODE:
	RETVAL= ErrorRet(  RegUnLoadKeyW( hKey, swSubKey )  );
    OUTPUT:
	RETVAL


BOOT:
#include "cRegistry.h"
