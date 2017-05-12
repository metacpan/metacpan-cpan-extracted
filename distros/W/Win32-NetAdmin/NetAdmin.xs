/* NetAdmin.xs
 *
 *
 * Fixed up 30-Jan-96 michael@ecel.uwa.edu.au
 *
 * Fixed up again 96.10.19 rothd@roth.net
 *
 * Fixed again 97.06.05 S.Bennett@lancaster.ac.uk
 *     Added GetAnyDomainController
 *     Fixed GroupIsMember & LocalGroupIsMember
 *
 * Fixed resumeHandle operation on all Enum calls
 *    97.09.29 jdoss@levi.com
 *
 * Added LocalGroupGetMembersWithDomain
 *    98.02.13 david.gardiner@unisa.edu.au
 *
 * Updated 64-bit data types in Win32 API calls
 *    14.10.21 m.hewitt@computer.org
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <lmcons.h>     /* LAN Manager common definitions */
#include <lmerr.h>      /* LAN Manager network error definitions */
#include <lmUseFlg.h>
#include <lmAccess.h>
#include <lmAPIBuf.h>
#undef LPTSTR
#define LPTSTR LPWSTR
#include <lmServer.h>
#include <lmwksta.h>
#undef LPTSTR
#define LPTSTR LPSTR
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef A2WHELPER
#  define A2WHELPER_LEN(lpa, alen, lpw, nBytes)\
    (lpw[0] = 0, MultiByteToWideChar((IN_BYTES) ? CP_ACP : CP_UTF8, 0, \
				    lpa, alen, lpw, (nBytes/sizeof(WCHAR))))
#  define A2WHELPER(lpa, lpw, nBytes)	A2WHELPER_LEN(lpa, -1, lpw, nBytes)

#  define W2AHELPER_LEN(lpw, wlen, lpa, nChars)\
    (lpa[0] = '\0', WideCharToMultiByte((IN_BYTES) ? CP_ACP : CP_UTF8, 0, \
				       lpw, wlen, (LPSTR)lpa, nChars,NULL,NULL))
#  define W2AHELPER(lpw, lpa, nChars)	W2AHELPER_LEN(lpw, -1, lpa, nChars)
#endif

#include "ppport.h"

#define RETURNRESULT(x)		if ((x)){ XST_mYES(0); }\
                     		else { XST_mNO(0); }\
                     		XSRETURN(1)
#define SETIV(index,value) sv_setiv(ST(index), value)
#define SETPV(index,string) sv_setpv(ST(index), string)

#define PREFLEN 0x20000

/* constant function for exporting NT definitions. */

static long
constant(char *name)
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
	if (strEQ(name, "DOMAIN_ALIAS_RID_ACCOUNT_OPS"))
#ifdef DOMAIN_ALIAS_RID_ACCOUNT_OPS
	    return DOMAIN_ALIAS_RID_ACCOUNT_OPS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DOMAIN_ALIAS_RID_ADMINS"))
#ifdef DOMAIN_ALIAS_RID_ADMINS
	    return DOMAIN_ALIAS_RID_ADMINS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DOMAIN_ALIAS_RID_BACKUP_OPS"))
#ifdef DOMAIN_ALIAS_RID_BACKUP_OPS
	    return DOMAIN_ALIAS_RID_BACKUP_OPS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DOMAIN_ALIAS_RID_GUESTS"))
#ifdef DOMAIN_ALIAS_RID_GUESTS
	    return DOMAIN_ALIAS_RID_GUESTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DOMAIN_ALIAS_RID_POWER_USERS"))
#ifdef DOMAIN_ALIAS_RID_POWER_USERS
	    return DOMAIN_ALIAS_RID_POWER_USERS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DOMAIN_ALIAS_RID_PRINT_OPS"))
#ifdef DOMAIN_ALIAS_RID_PRINT_OPS
	    return DOMAIN_ALIAS_RID_PRINT_OPS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DOMAIN_ALIAS_RID_REPLICATOR"))
#ifdef DOMAIN_ALIAS_RID_REPLICATOR
	    return DOMAIN_ALIAS_RID_REPLICATOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DOMAIN_ALIAS_RID_SYSTEM_OPS"))
#ifdef DOMAIN_ALIAS_RID_SYSTEM_OPS
	    return DOMAIN_ALIAS_RID_SYSTEM_OPS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DOMAIN_ALIAS_RID_USERS"))
#ifdef DOMAIN_ALIAS_RID_USERS
	    return DOMAIN_ALIAS_RID_USERS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DOMAIN_GROUP_RID_ADMINS"))
#ifdef DOMAIN_GROUP_RID_ADMINS
	    return DOMAIN_GROUP_RID_ADMINS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DOMAIN_GROUP_RID_GUESTS"))
#ifdef DOMAIN_GROUP_RID_GUESTS
	    return DOMAIN_GROUP_RID_GUESTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DOMAIN_GROUP_RID_USERS"))
#ifdef DOMAIN_GROUP_RID_USERS
	    return DOMAIN_GROUP_RID_USERS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DOMAIN_USER_RID_ADMIN"))
#ifdef DOMAIN_USER_RID_ADMIN
	    return DOMAIN_USER_RID_ADMIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DOMAIN_USER_RID_GUEST"))
#ifdef DOMAIN_USER_RID_GUEST
	    return DOMAIN_USER_RID_GUEST;
#else
	    goto not_there;
#endif
	break;
    case 'E':
	break;
    case 'F':
	if (strEQ(name, "FILTER_TEMP_DUPLICATE_ACCOUNT"))
#ifdef FILTER_TEMP_DUPLICATE_ACCOUNT
		return FILTER_TEMP_DUPLICATE_ACCOUNT;
#else
		goto not_there;
#endif	
	if (strEQ(name, "FILTER_NORMAL_ACCOUNT"))
#ifdef FILTER_NORMAL_ACCOUNT
		return FILTER_NORMAL_ACCOUNT;
#else
		goto not_there;
#endif	
	if (strEQ(name, "FILTER_INTERDOMAIN_TRUST_ACCOUNT"))
#ifdef FILTER_INTERDOMAIN_TRUST_ACCOUNT
		return FILTER_INTERDOMAIN_TRUST_ACCOUNT;
#else
		goto not_there;
#endif	
	if (strEQ(name, "FILTER_WORKSTATION_TRUST_ACCOUNT"))
#ifdef FILTER_WORKSTATION_TRUST_ACCOUNT
		return FILTER_WORKSTATION_TRUST_ACCOUNT;
#else
		goto not_there;
#endif	
	if (strEQ(name, "FILTER_SERVER_TRUST_ACCOUNT"))
#ifdef FILTER_SERVER_TRUST_ACCOUNT
		return FILTER_SERVER_TRUST_ACCOUNT;
#else
		goto not_there;
#endif	

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
	if (strEQ(name, "SV_TYPE_WORKSTATION"))
#ifdef SV_TYPE_WORKSTATION
	    return SV_TYPE_WORKSTATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_SERVER"))
#ifdef SV_TYPE_SERVER
	    return SV_TYPE_SERVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_SERVER_MFPN"))
#ifdef SV_TYPE_SERVER_MFPN
	    return SV_TYPE_SERVER_MFPN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_SERVER_NT"))
#ifdef SV_TYPE_SERVER_NT
	    return SV_TYPE_SERVER_NT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_SERVER_OSF"))
#ifdef SV_TYPE_SERVER_OSF
	    return SV_TYPE_SERVER_OSF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_SERVER_UNIX"))
#ifdef SV_TYPE_SERVER_UNIX
	    return SV_TYPE_SERVER_UNIX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_SERVER_VMS"))
#ifdef SV_TYPE_SERVER_VMS
	    return SV_TYPE_SERVER_VMS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_WINDOWS"))
#ifdef SV_TYPE_WINDOWS
	    return SV_TYPE_WINDOWS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_DFS"))
#ifdef SV_TYPE_DFS
	    return SV_TYPE_DFS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_ALTERNATE_XPORT"))
#ifdef SV_TYPE_ALTERNATE_XPORT
	    return SV_TYPE_ALTERNATE_XPORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_LOCAL_LIST_ONLY"))
#ifdef SV_TYPE_LOCAL_LIST_ONLY
	    return SV_TYPE_LOCAL_LIST_ONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_SQLSERVER"))
#ifdef SV_TYPE_SQLSERVER
	    return SV_TYPE_SQLSERVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_DOMAIN_CTRL"))
#ifdef SV_TYPE_DOMAIN_CTRL
	    return SV_TYPE_DOMAIN_CTRL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_DOMAIN_BAKCTRL"))
#ifdef SV_TYPE_DOMAIN_BAKCTRL
	    return SV_TYPE_DOMAIN_BAKCTRL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_TIMESOURCE"))
#ifdef SV_TYPE_TIMESOURCE
	    return SV_TYPE_TIMESOURCE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_AFP"))
#ifdef SV_TYPE_AFP
	    return SV_TYPE_AFP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_NOVELL"))
#ifdef SV_TYPE_NOVELL
	    return SV_TYPE_NOVELL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_DOMAIN_MEMBER"))
#ifdef SV_TYPE_DOMAIN_MEMBER
	    return SV_TYPE_DOMAIN_MEMBER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_PRINT"))
#ifdef SV_TYPE_PRINTQ_SERVER
	    return SV_TYPE_PRINTQ_SERVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_PRINTQ_SERVER"))
#ifdef SV_TYPE_PRINTQ_SERVER
	    return SV_TYPE_PRINTQ_SERVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_DIALIN"))
#ifdef SV_TYPE_DIALIN_SERVER
	    return SV_TYPE_DIALIN_SERVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_DIALIN_SERVER"))
#ifdef SV_TYPE_DIALIN_SERVER
	    return SV_TYPE_DIALIN_SERVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_XENIX_SERVER"))
#ifdef SV_TYPE_XENIX_SERVER
	    return SV_TYPE_XENIX_SERVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_NT"))
#ifdef SV_TYPE_NT
	    return SV_TYPE_NT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_WFW"))
#ifdef SV_TYPE_WFW
	    return SV_TYPE_WFW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_POTENTIAL_BROWSER"))
#ifdef SV_TYPE_POTENTIAL_BROWSER
	    return SV_TYPE_POTENTIAL_BROWSER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_BACKUP_BROWSER"))
#ifdef SV_TYPE_BACKUP_BROWSER
	    return SV_TYPE_BACKUP_BROWSER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_MASTER_BROWSER"))
#ifdef SV_TYPE_MASTER_BROWSER
	    return SV_TYPE_MASTER_BROWSER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_DOMAIN_MASTER"))
#ifdef SV_TYPE_DOMAIN_MASTER
	    return SV_TYPE_DOMAIN_MASTER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_DOMAIN_ENUM"))
#ifdef SV_TYPE_DOMAIN_ENUM
	    return SV_TYPE_DOMAIN_ENUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SV_TYPE_ALL"))
#ifdef SV_TYPE_ALL
	    return SV_TYPE_ALL;
#else
	    goto not_there;
#endif
	break;
    case 'T':
	break;
    case 'U':
	if (strEQ(name, "UF_TEMP_DUPLICATE_ACCOUNT"))
#ifdef UF_TEMP_DUPLICATE_ACCOUNT
	    return UF_TEMP_DUPLICATE_ACCOUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "UF_NORMAL_ACCOUNT"))
#ifdef UF_NORMAL_ACCOUNT
	    return UF_NORMAL_ACCOUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "UF_INTERDOMAIN_TRUST_ACCOUNT"))
#ifdef UF_INTERDOMAIN_TRUST_ACCOUNT
	    return UF_INTERDOMAIN_TRUST_ACCOUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "UF_WORKSTATION_TRUST_ACCOUNT"))
#ifdef UF_WORKSTATION_TRUST_ACCOUNT
	    return UF_WORKSTATION_TRUST_ACCOUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "UF_SERVER_TRUST_ACCOUNT"))
#ifdef UF_SERVER_TRUST_ACCOUNT
	    return UF_SERVER_TRUST_ACCOUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "UF_MACHINE_ACCOUNT_MASK"))
#ifdef UF_MACHINE_ACCOUNT_MASK
	    return UF_MACHINE_ACCOUNT_MASK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "UF_ACCOUNT_TYPE_MASK"))
#ifdef UF_ACCOUNT_TYPE_MASK
	    return UF_ACCOUNT_TYPE_MASK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "UF_DONT_EXPIRE_PASSWD"))
#ifdef UF_DONT_EXPIRE_PASSWD
	    return UF_DONT_EXPIRE_PASSWD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "UF_SETTABLE_BITS"))
#ifdef UF_SETTABLE_BITS
	    return UF_SETTABLE_BITS;
#else
	    goto not_there;
#endif

	if (strEQ(name, "UF_SCRIPT"))
#ifdef UF_SCRIPT
	    return UF_SCRIPT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "UF_ACCOUNTDISABLE"))
#ifdef UF_ACCOUNTDISABLE
	    return UF_ACCOUNTDISABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "UF_HOMEDIR_REQUIRED"))
#ifdef UF_HOMEDIR_REQUIRED
	    return UF_HOMEDIR_REQUIRED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "UF_LOCKOUT"))
#ifdef UF_LOCKOUT
	    return UF_LOCKOUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "UF_PASSWD_NOTREQD"))
#ifdef UF_PASSWD_NOTREQD
	    return UF_PASSWD_NOTREQD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "UF_PASSWD_CANT_CHANGE"))
#ifdef UF_PASSWD_CANT_CHANGE
	    return UF_PASSWD_CANT_CHANGE;
#else
	    goto not_there;
#endif

	if (strEQ(name, "USE_FORCE"))
#ifdef USE_FORCE
	    return USE_FORCE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USE_LOTS_OF_FORCE"))
#ifdef USE_LOTS_OF_FORCE
	    return USE_LOTS_OF_FORCE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USE_NOFORCE"))
#ifdef USE_NOFORCE
	    return USE_NOFORCE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_PRIV_MASK"))
#ifdef USER_PRIV_MASK
	    return USER_PRIV_MASK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_PRIV_GUEST"))
#ifdef USER_PRIV_GUEST
	    return USER_PRIV_GUEST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_PRIV_USER"))
#ifdef USER_PRIV_USER
	    return USER_PRIV_USER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_PRIV_ADMIN"))
#ifdef USER_PRIV_ADMIN
	    return USER_PRIV_ADMIN;
#else
	    goto not_there;
#endif
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

LPWSTR
_AllocWideName(char* name)
{
    int length;
    LPWSTR lpPtr = NULL;

    if (name != NULL && *name != '\0') {
	length = (strlen(name)+1) * sizeof(WCHAR);
	lpPtr = (LPWSTR)malloc(length);
	if (lpPtr != NULL)
	    MultiByteToWideChar(CP_ACP, 0, name, -1, lpPtr, length);
    }
    return lpPtr;
}

#define AllocWideName(n,wn) (wn = _AllocWideName(n))

void
FreeWideName(LPWSTR lpPtr)
{
    if (lpPtr != NULL)
	free(lpPtr);
}

int
WCTMB(LPWSTR lpwStr, LPSTR lpStr, int size)
{
    *lpStr = '\0';
    return WideCharToMultiByte(CP_ACP, 0, lpwStr, -1, lpStr, size, NULL, 0);
}

/*
void AddStringToHV(HV *hv, char *key, char *value)
{
    char buffer[256];
    if (value)
	strcpy(buffer, value );
    else
	*buffer = '\0';
    hv_store(hv, key, strlen(key), newSVpv(buffer, strlen(buffer)), 0);
    return;
}

void AddWCStringToHV(HV *hv, char *key, LPWSTR value)
{
    char buffer[UNLEN+2];
    WCTMB(value, buffer, sizeof(buffer));
    AddStringToHV(hv, key, buffer);
}

void AddDwordToHV(HV *hv, char *key, DWORD value )
{
    hv_store(hv, key, strlen(key), newSVnv((double)value), 0);
    return;
}
*/

DWORD GetAccountSIDA(LPCSTR lpSystemName, LPCSTR lpAccountName, PSID *pSid)
{
    DWORD sidSize;
    char refDomain[256];
    DWORD refDomainSize;
    DWORD returnValue;
    SID_NAME_USE snu;

    sidSize = 0;
    refDomainSize=255;
    LookupAccountNameA(lpSystemName, lpAccountName, *pSid,
		      &sidSize, refDomain,
		      &refDomainSize, &snu);
    returnValue = GetLastError();
    if(ERROR_INSUFFICIENT_BUFFER != returnValue)
	return returnValue;

    *pSid = (PSID)malloc(sidSize);
    refDomainSize = 255;
    if (!LookupAccountNameA(lpSystemName, lpAccountName, *pSid, &sidSize, 
                            refDomain, &refDomainSize, &snu)) 
    {
	free(*pSid);
	return GetLastError();
    }

    return ERROR_SUCCESS;
}

DWORD GetAccountSIDW(LPCWSTR lpSystemName, LPCWSTR lpAccountName, PSID *pSid)
{
    DWORD sidSize;
    WCHAR refDomain[256];
    DWORD refDomainSize;
    DWORD returnValue;
    SID_NAME_USE snu;

    sidSize = 0;
    refDomainSize=255;
    LookupAccountNameW(lpSystemName, lpAccountName, *pSid,
		      &sidSize, refDomain,
		      &refDomainSize, &snu);
    returnValue = GetLastError();
    if(ERROR_INSUFFICIENT_BUFFER != returnValue)
	return returnValue;

    *pSid = (PSID)malloc(sidSize);
    refDomainSize = 255;
    if (!LookupAccountNameW(lpSystemName, lpAccountName, *pSid, &sidSize, 
                            refDomain, &refDomainSize, &snu)) 
    {
	free(*pSid);
	return GetLastError();
    }

    return ERROR_SUCCESS;
}


static void SetNetAdminLastError(DWORD dwError)
{
    SV* sv = get_sv("Win32::NetAdmin::__lastError", FALSE);
    if (sv) {
	sv_setiv(sv, (IV)dwError);
    }
}

XS(XS_NT__NetAdmin_GetDomainController)
{
    dXSARGS;
    char buffer[512];
    DWORD lastError = 0;
    LPWSTR lpwServer = NULL, lpwDomain = NULL, lpwPrimaryDC = NULL;

    if (items != 3) {
	croak("Usage: Win32::NetAdmin::GetDomainController(server, domain, returnedName)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), lpwDomain);
	lastError = NetGetDCName(lpwServer, lpwDomain, (LPBYTE *)&lpwPrimaryDC);
	if (lastError == 0) {
	    W2AHELPER(lpwPrimaryDC, buffer, sizeof(buffer));
	    SETPV(2, buffer);
	    NetApiBufferFree(lpwPrimaryDC);
	}
	FreeWideName(lpwServer);
	FreeWideName(lpwDomain);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_GetAnyDomainController)
{
    dXSARGS;
    char buffer[512];
    DWORD lastError = 0;
    LPWSTR lpwServer, lpwDomain, lpwAnyDC = NULL;

    if (items != 3) {
	croak("Usage: Win32::NetAdmin::GetAnyDomainController(server, domain, returnedName)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), lpwDomain);
	lastError = NetGetAnyDCName(lpwServer, lpwDomain, (LPBYTE *)&lpwAnyDC);
	if (lastError == 0) {
	    W2AHELPER(lpwAnyDC, buffer, sizeof(buffer));
	    SETPV(2, buffer);
	    NetApiBufferFree(lpwAnyDC);
	}
	FreeWideName(lpwServer);
	FreeWideName(lpwDomain);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_constant)
{
    dXSARGS;

    if (items < 1) {
	croak("Usage: Win32::NetAdmin::constant(name)\n");
    }
    {
	STRLEN n_a;
	char* name = (char*)SvPV(ST(0),n_a);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), constant(name));
    }
    XSRETURN(1);
}

XS(XS_NT__NetAdmin_UserCreate)
{
    dXSARGS;
    LPWSTR lpwServer;
    USER_INFO_1 uiUser;
    DWORD lastError = 0;

    if (items != 9) {
	croak("Usage: Win32::NetAdmin::UserCreate(server, userName, password, "
	      "passwordAge, privilege, homeDir, comment, flags, scriptPath)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), uiUser.usri1_name);
	AllocWideName((char*)SvPV(ST(2),n_a), uiUser.usri1_password);
	uiUser.usri1_password_age		= SvIV(ST(3));
	uiUser.usri1_priv			= SvIV(ST(4));
	AllocWideName((char*)SvPV(ST(5),n_a), uiUser.usri1_home_dir);
	AllocWideName((char*)SvPV(ST(6),n_a), uiUser.usri1_comment);
	uiUser.usri1_flags			= SvIV(ST(7));
	AllocWideName((char*)SvPV(ST(8),n_a), uiUser.usri1_script_path);
	lastError = NetUserAdd(lpwServer, 1, (LPBYTE)&uiUser, NULL);
	FreeWideName(lpwServer);
	FreeWideName(uiUser.usri1_name);
	FreeWideName(uiUser.usri1_password);
	FreeWideName(uiUser.usri1_home_dir);
	FreeWideName(uiUser.usri1_comment);
	FreeWideName(uiUser.usri1_script_path);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_UserDelete)
{
    dXSARGS;
    LPWSTR lpwServer, lpwUser;
    DWORD lastError = 0;

    if (items != 2) {
	croak("Usage: Win32::NetAdmin::UserDelete(server, user)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), lpwUser);
	lastError = NetUserDel(lpwServer, lpwUser);
	FreeWideName(lpwServer);
	FreeWideName(lpwUser);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}


XS(XS_NT__NetAdmin_UserGetAttributes)
{
    dXSARGS;
    char buffer[UNLEN+1];
    LPWSTR lpwServer, lpwUser;
    PUSER_INFO_1 puiUser;
    DWORD lastError = 0;

    if (items != 9) {
	croak("Usage: Win32::NetAdmin::UserGetAttributes(server, userName, "
	      "password, passwordAge, privilege, homeDir, comment, flags, "
	      "scriptPath)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), lpwUser);
	lastError = NetUserGetInfo(lpwServer, lpwUser, 1, (LPBYTE*)&puiUser);
	if (lastError == 0) {
	    W2AHELPER(puiUser->usri1_password, buffer, sizeof(buffer));
	    SETPV(2, buffer);
	    SETIV(3, puiUser->usri1_password_age);
	    SETIV(4, puiUser->usri1_priv);
	    W2AHELPER(puiUser->usri1_home_dir, buffer, sizeof(buffer));
	    SETPV(5, buffer);
	    W2AHELPER(puiUser->usri1_comment, buffer, sizeof(buffer));
	    SETPV(6, buffer);
	    SETIV(7, puiUser->usri1_flags);
	    W2AHELPER(puiUser->usri1_script_path, buffer, sizeof(buffer));
	    SETPV(8, buffer);
	    NetApiBufferFree(puiUser);
	}
	FreeWideName(lpwServer);
	FreeWideName(lpwUser);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_UserSetAttributes)
{
    dXSARGS;
    LPWSTR lpwServer;
    USER_INFO_1 uiUser;
    DWORD lastError = 0;

    if (items != 9) {
	croak("Usage: Win32::NetAdmin::UserSetAttributes(server, userName, "
	      "password, passwordAge, privilege, homeDir, comment, flags, "
	      "scriptPath)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), uiUser.usri1_name);
	AllocWideName((char*)SvPV(ST(2),n_a), uiUser.usri1_password);
	uiUser.usri1_password_age		= SvIV(ST(3));
	uiUser.usri1_priv			= SvIV(ST(4));
	AllocWideName((char*)SvPV(ST(5),n_a), uiUser.usri1_home_dir);
	AllocWideName((char*)SvPV(ST(6),n_a), uiUser.usri1_comment);
	uiUser.usri1_flags			= SvIV(ST(7));
	AllocWideName((char*)SvPV(ST(8),n_a), uiUser.usri1_script_path);
	lastError = NetUserSetInfo(lpwServer, uiUser.usri1_name, 1, (LPBYTE)&uiUser, NULL);
	FreeWideName(lpwServer);
	FreeWideName(uiUser.usri1_name);
	FreeWideName(uiUser.usri1_password);
	FreeWideName(uiUser.usri1_home_dir);
	FreeWideName(uiUser.usri1_comment);
	FreeWideName(uiUser.usri1_script_path);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_UserChangePassword)
{
    dXSARGS;
    LPWSTR lpwDomain;
    LPWSTR lpwUserName;
    LPWSTR lpwOldPassword;
    LPWSTR lpwNewPassword;
    DWORD lastError = 0;

    if (items != 4) {
	croak("Usage: Win32::NetAdmin::UserChangePassword(domainname, "
	      "username, oldpassword, newpassword)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwDomain);
	AllocWideName((char*)SvPV(ST(1),n_a), lpwUserName);
	AllocWideName((char*)SvPV(ST(2),n_a), lpwOldPassword);
	AllocWideName((char*)SvPV(ST(3),n_a), lpwNewPassword);
	lastError = NetUserChangePassword(lpwDomain, lpwUserName, lpwOldPassword,lpwNewPassword);
	FreeWideName(lpwDomain);
	FreeWideName(lpwUserName);
	FreeWideName(lpwOldPassword);
	FreeWideName(lpwNewPassword);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_UsersExist)
{
    dXSARGS;
    LPWSTR lpwServer, lpwUser;
    PUSER_INFO_0 puiUser;
    BOOL bReturn = FALSE;
    DWORD lastError = 0;

    if (items != 2) {
	croak("Usage: Win32::NetAdmin::UsersExist(server, userName)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), lpwUser);
	lastError = NetUserGetInfo(lpwServer, lpwUser, 0, (LPBYTE*)&puiUser);
	if (lastError == 0) {
	    bReturn = TRUE;
	    NetApiBufferFree(puiUser);
	}
	FreeWideName(lpwServer);
	FreeWideName(lpwUser);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(bReturn);
}

XS(XS_NT__NetAdmin_GetUsers)
{
    dXSARGS;
    LPWSTR lpwServer;
    char buffer[UNLEN+1];
    char buffer1[UNLEN+1];
    PUSER_INFO_0 pwzUsers;
    PUSER_INFO_10 pwzUsers10;
    DWORD filter, entriesRead, totalEntries;
    DWORD_PTR resumeHandle = 0;
    DWORD index;
    SV *sv;
    DWORD lastError = 0;

    if (items != 3) {
	croak("Usage: Win32::NetAdmin::GetUsers(server, filter, userRef)\n");
    }
    {	
	STRLEN n_a;
	filter = SvIV(ST(1));
	sv = ST(2);
	if (SvROK(sv)) {
	    sv = SvRV(sv);
	}
	if (SvTYPE(sv) == SVt_PVAV) {
	    av_clear((AV*)sv);
	    AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	    do {
		lastError = NetUserEnum(lpwServer, 0, filter,
					(LPBYTE*)&pwzUsers, PREFLEN,
					&entriesRead, &totalEntries,
					&resumeHandle);
		if (lastError != 0 && lastError != ERROR_MORE_DATA)
		    break;
		for (index = 0; index < entriesRead; ++index) {
		    W2AHELPER(pwzUsers[index].usri0_name, buffer, sizeof(buffer));
		    av_push((AV*)sv, newSVpv(buffer, 0));
		}
		NetApiBufferFree(pwzUsers);
	    } while(lastError == ERROR_MORE_DATA);
	    FreeWideName(lpwServer);
	}
	else if( SvTYPE(sv) == SVt_PVHV) {
	    hv_clear((HV*)sv);
	    AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	    do {
		lastError = NetUserEnum(lpwServer,10, filter,
					(LPBYTE*)&pwzUsers10, PREFLEN,
					&entriesRead, &totalEntries,
					&resumeHandle);
		if (lastError != 0 && lastError != ERROR_MORE_DATA)
		    break;
		for (index = 0; index < entriesRead; ++index) {
		    W2AHELPER(pwzUsers10[index].usri10_name, buffer, sizeof(buffer));
		    W2AHELPER(pwzUsers10[index].usri10_full_name, buffer1,
			  sizeof(buffer1));
		    hv_store((HV*)sv, buffer, strlen(buffer),
			     newSVpv(buffer1,0), 0 );
		}
		NetApiBufferFree(pwzUsers10);
	    } while(lastError == ERROR_MORE_DATA);
	    FreeWideName(lpwServer);
	}
	else {
	    croak("Usage: Win32::NetAdmin::GetUsers(server, filter, "
		  "$userRef)\nuserRef was not an array or an hash\n");
	}
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_GetTransports)
{
    dXSARGS;
    LPWSTR lpwServer;
    char buffer[UNLEN+1];
    char buffer1[UNLEN+1];
    PWKSTA_TRANSPORT_INFO_0 pws;
    DWORD entriesRead, totalEntries;
    DWORD_PTR resumeHandle = 0;
    DWORD index;
    SV *sv;
    HV *hvTemp;
    DWORD lastError = 0;

    if (items != 2) {
	croak("Usage: Win32::NetAdmin::GetTransport(server, transportRef)\n");
    }
    {
	STRLEN n_a;
	sv = ST(1);
	if (SvROK(sv)) {
	    sv = SvRV(sv);
	}
	if (SvTYPE(sv) == SVt_PVAV) {
	    av_clear((AV*)sv);
	    AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	    do {
		lastError = NetWkstaTransportEnum(lpwServer, 0,
					  (LPBYTE*) &pws,
					  PREFLEN, &entriesRead,
					  &totalEntries, &resumeHandle);
		if (lastError != 0 && lastError != ERROR_MORE_DATA)
		    break;
		for (index = 0; index < entriesRead; ++index) {
		    W2AHELPER(pws[index].wkti0_transport_name, buffer,
			  sizeof(buffer));
		    av_push((AV*)sv, newSVpv(buffer, 0));
		}
		NetApiBufferFree(pws);
	    } while(lastError == ERROR_MORE_DATA);
	    FreeWideName(lpwServer);
	}
	else if( SvTYPE(sv) == SVt_PVHV) {
	    hv_clear((HV*)sv);
	    AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	    do {
		lastError = NetWkstaTransportEnum(lpwServer, 0,
						  (LPBYTE*) &pws,
						  PREFLEN, &entriesRead,
						  &totalEntries, &resumeHandle);
		if (lastError != 0 && lastError != ERROR_MORE_DATA)
		    break;
		for (index = 0; index < entriesRead; ++index) {
		    hvTemp = newHV();
		    hv_store(hvTemp,
			     "quality_of_service",
			     strlen("quality_of_service"),
			     newSViv((long)pws[index].wkti0_quality_of_service), 0);
		    hv_store(hvTemp,
			     "number_of_vcs",
			     strlen("number_of_vcs"),
			     newSViv((long)pws[index].wkti0_number_of_vcs), 0);
		    W2AHELPER(pws[index].wkti0_transport_name, buffer, sizeof(buffer));
		    hv_store(hvTemp,
			     "transport_name",
			     strlen("transport_name"),
			     newSVpv((char*) buffer, strlen((char *)buffer)), 0);
		    W2AHELPER(pws[index].wkti0_transport_address,buffer1,sizeof(buffer1));
		    hv_store(hvTemp,
			     "transport_address",
			     strlen("transport_address"),
			     newSVpv((char*) buffer1, strlen((char *)buffer1)), 0);
		    hv_store(hvTemp,"wan_ish", strlen("wan_ish"),
			     newSViv((bool)pws[index].wkti0_wan_ish), 0);
		    sprintf(buffer, "%d", pws[index].wkti0_quality_of_service);
		    hv_store((HV*)sv, buffer, strlen(buffer),
			     (SV*)newRV((SV*)hvTemp), 0 );
		}
		NetApiBufferFree(pws);
	    } while(lastError == ERROR_MORE_DATA);
	    FreeWideName(lpwServer);
	}
	else {
	    croak("Usage: Win32::NetAdmin::GetTransport(server, "
		  "$transportRef)\ntransportRef was not an array or hash\n");
	}
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_LoggedOnUsers)
{
    dXSARGS;
    LPWSTR lpwServer;
    char buffer[UNLEN+1];
    char buffer1[UNLEN+1];
    char logon_domain[UNLEN+1];
    char logon_server[UNLEN+1];
    PWKSTA_USER_INFO_0 pwzUser0;
    PWKSTA_USER_INFO_1 pwzUser1;
    DWORD entriesRead, totalEntries;
    DWORD_PTR resumeHandle = 0;
    DWORD index;
    SV *sv;
    DWORD lastError = 0;

    if (items != 2) {
	croak("Usage: Win32::NetAdmin::LoggedOnUsers(server, $userRef)\n");
    }
    {	
	STRLEN n_a;
	sv = ST(1);
	if (SvROK(sv)) {
	    sv = SvRV(sv);
	}
	if (SvTYPE(sv) == SVt_PVAV) {
	    av_clear((AV*)sv);
	    AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	    do {
		lastError = NetWkstaUserEnum(lpwServer, 0,
					(LPBYTE*)&pwzUser0, PREFLEN,
					&entriesRead, &totalEntries,
					&resumeHandle);
		if (lastError != 0 && lastError != ERROR_MORE_DATA)
		    break;
		for (index = 0; index < entriesRead; ++index) {
		    W2AHELPER(pwzUser0[index].wkui0_username, buffer, sizeof(buffer));
		    av_push((AV*)sv, newSVpv(buffer, 0));
		}
		NetApiBufferFree(pwzUser0);
	    } while(lastError == ERROR_MORE_DATA);
	    FreeWideName(lpwServer);
	}
	else if( SvTYPE(sv) == SVt_PVHV) {
	    hv_clear((HV*)sv);
	    AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	    do {
		lastError = NetWkstaUserEnum(lpwServer,1,
					     (LPBYTE*)&pwzUser1, PREFLEN,
					     &entriesRead, &totalEntries,
					     &resumeHandle);
		if (lastError != 0 && lastError != ERROR_MORE_DATA)
		    break;
		for (index = 0; index < entriesRead; ++index) {
		    W2AHELPER(pwzUser1[index].wkui1_username, buffer, sizeof(buffer));
		    W2AHELPER(pwzUser1[index].wkui1_logon_domain, logon_domain,
			  sizeof(logon_domain));
		    W2AHELPER(pwzUser1[index].wkui1_logon_server, logon_server,
			  sizeof(logon_server));
		    sprintf(buffer1,"%s;%s;%s", buffer, logon_domain,
			    logon_server);
		    sprintf(buffer, "%d", index);
		    hv_store((HV*)sv, buffer, strlen(buffer),
			     newSVpv(buffer1,0), 0 );
		}
		NetApiBufferFree(pwzUser1);
	    } while(lastError == ERROR_MORE_DATA);
	    FreeWideName(lpwServer);
	}
	else {
	    croak("Usage: Win32::NetAdmin::LoggedOnUsers(server, "
		  "$userRef)\nuserRef was not an array or an hash\n");
	}
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_GroupCreate)
{
    dXSARGS;
    LPWSTR lpwServer;
    GROUP_INFO_1 groupInfo;
    DWORD lastError = 0;

    if (items != 3) {
	croak("Usage: Win32::NetAdmin::GroupCreate(server, group, comment)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), groupInfo.grpi1_name);
	AllocWideName((char*)SvPV(ST(2),n_a), groupInfo.grpi1_comment);
	lastError = NetGroupAdd(lpwServer, 1, (LPBYTE)&groupInfo, NULL);
	FreeWideName(lpwServer);
	FreeWideName(groupInfo.grpi1_name);
	FreeWideName(groupInfo.grpi1_comment);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_GroupDelete)
{
    dXSARGS;
    LPWSTR lpwServer, lpwGroup;
    DWORD lastError = 0;

    if (items != 2) {
	croak("Usage: Win32::NetAdmin::GroupDelete(server, group)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), lpwGroup);
	lastError = NetGroupDel(lpwServer, lpwGroup);
	FreeWideName(lpwServer);
	FreeWideName(lpwGroup);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_GroupGetAttributes)
{
    dXSARGS;
    char buffer[UNLEN+1];
    LPWSTR lpwServer, lpwGroup;
    PGROUP_INFO_2 pgroupInfo;
    DWORD lastError = 0;

    if (items != 3) {
	croak("Usage: Win32::NetAdmin::GroupGetAttributes(server, groupName, comment)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), lpwGroup);
	lastError = NetGroupGetInfo(lpwServer, lpwGroup, 2,
				    (LPBYTE*)&pgroupInfo);
	if (lastError == 0) {
	    W2AHELPER(pgroupInfo->grpi2_comment, buffer, sizeof(buffer));
	    SETPV(2, buffer);
	    NetApiBufferFree(pgroupInfo);
	}
	FreeWideName(lpwServer);
	FreeWideName(lpwGroup);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_GroupSetAttributes)
{
    dXSARGS;
    LPWSTR lpwServer;
    GROUP_INFO_2 groupInfo;
    DWORD lastError = 0;

    if (items != 3) {
	croak("Usage: Win32::NetAdmin::GroupSetAttributes(server, groupName, comment)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), groupInfo.grpi2_name);
	AllocWideName((char*)SvPV(ST(2),n_a), groupInfo.grpi2_comment);
	groupInfo.grpi2_group_id		= 0;
	groupInfo.grpi2_attributes		= 0;
	lastError = NetGroupSetInfo(lpwServer, groupInfo.grpi2_name,
				    2, (LPBYTE)&groupInfo, NULL);
	FreeWideName(lpwServer);
	FreeWideName(groupInfo.grpi2_name);
	FreeWideName(groupInfo.grpi2_comment);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_GroupAddUsers)
{
    dXSARGS;
    LPWSTR lpwServer, lpwGroup;
    WCHAR wzUser[UNLEN+2];
    int count, index;
    SV *sv, **psv;
    DWORD lastError = 0;

    if (items != 3) {
	croak("Usage: Win32::NetAdmin::GroupAddUsers(server, groupName, users)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), lpwGroup);
	sv = ST(2);
	if (SvROK(sv)) {
	    sv = SvRV(sv);
	}
	switch (SvTYPE(sv))
	{
	case SVt_PVAV:
	    count = av_len((AV*)sv);
	    for (index = 0; index <= count; ++index) {
		psv = av_fetch((AV*)sv, index, 0);
		if (psv != NULL) {
		    MultiByteToWideChar(CP_ACP, 0, (char*)SvPV(*psv,n_a),
					-1, wzUser, sizeof(wzUser));
		    lastError = NetGroupAddUser(lpwServer, lpwGroup, wzUser);
		    if (lastError != 0)
			break;
		}
	    }
	    break;
	default:
	    MultiByteToWideChar(CP_ACP, 0, (char*)SvPV(sv,n_a),
				-1, wzUser, sizeof(wzUser));
	    lastError = NetGroupAddUser(lpwServer, lpwGroup, wzUser);
	    break;
	}
	FreeWideName(lpwServer);
	FreeWideName(lpwGroup);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_GroupDeleteUsers)
{
    dXSARGS;
    LPWSTR lpwServer, lpwGroup;
    WCHAR wzUser[UNLEN+2];
    int count, index;
    SV *sv, **psv;
    DWORD lastError = 0;

    if (items != 3) {
	croak("Usage: Win32::NetAdmin::GroupDeleteUsers(server, groupName, users)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), lpwGroup);
	sv = ST(2);
	if (SvROK(sv)) {
	    sv = SvRV(sv);
	}
	switch(SvTYPE(sv)) {
	case SVt_PVAV:
	    count = av_len((AV*)sv);
	    for (index = 0; index <= count; ++index) {
		psv = av_fetch((AV*)sv, index, 0);
		if (psv != NULL) {
		    MultiByteToWideChar(CP_ACP, 0, (char*)SvPV(*psv,n_a),
					-1, wzUser, sizeof(wzUser));
		    lastError = NetGroupDelUser(lpwServer, lpwGroup, wzUser);
		    if (lastError != 0)
		    	break;
		}
	    }
	    break;
	default:
	    MultiByteToWideChar(CP_ACP, 0, (char*)SvPV(sv,n_a),
				-1, wzUser, sizeof(wzUser));
	    lastError = NetGroupDelUser(lpwServer, lpwGroup, wzUser);
	    break;
	}
	FreeWideName(lpwServer);
	FreeWideName(lpwGroup);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_GroupIsMember)
{
    dXSARGS;
    LPWSTR lpwServer, lpwGroup, lpwUser;
    PGROUP_USERS_INFO_0 pwzGroupUsers;
    DWORD entriesRead, totalEntries;
    DWORD_PTR resumeHandle = 0;
    DWORD index;
    BOOL bReturn = FALSE;
    DWORD lastError = 0;

    if (items != 3) {
	croak("Usage: Win32::NetAdmin::GroupIsMember(server, groupName, user)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), lpwGroup);
	AllocWideName((char*)SvPV(ST(2),n_a), lpwUser);
#if 0
	do {
	    lastError = NetGroupGetUsers(lpwServer, lpwGroup, 0,
					 (LPBYTE*)&pwzGroupUsers,
		    			 PREFLEN, &entriesRead,
					 &totalEntries, &resumeHandle);
	    if (lastError != 0 && lastError != ERROR_MORE_DATA)
		break;
	    for (index = 0; index < entriesRead; ++index)
		if (lstrcmpiW(lpwUser, pwzGroupUsers[index].grui0_name) == 0) {
		    bReturn = TRUE;
		    break;
		}

	    NetApiBufferFree(pwzGroupUsers);
	} while(bReturn == FALSE && lastError == ERROR_MORE_DATA);
#else
	lastError = NetUserGetGroups(lpwServer, lpwUser, 0,
				     (LPBYTE*)&pwzGroupUsers, PREFLEN,
				     &entriesRead, &totalEntries);
	if (lastError == 0)	{
	    // should check that entriesRead == totalEntries and redo if not
	    // but 'this should not happen' if PREFLEN is sufficiently large...
	    PGROUP_USERS_INFO_0 lpGroupInfo = pwzGroupUsers;
	    for (index = 0; index < entriesRead; index++, lpGroupInfo++) {
		if (lstrcmpiW(lpwGroup, lpGroupInfo->grui0_name) == 0) {
		    bReturn = TRUE;
		    break;
		}
	    }
	    NetApiBufferFree(pwzGroupUsers);
	}
#endif
	FreeWideName(lpwServer);
	FreeWideName(lpwGroup);
	FreeWideName(lpwUser);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(bReturn);
}

XS(XS_NT__NetAdmin_GroupGetMembers)
{
    dXSARGS;
    LPWSTR lpwServer, lpwGroup;
    char buffer[UNLEN+1];
    PGROUP_USERS_INFO_0 pwzGroupUsers;
    DWORD entriesRead, totalEntries;
    DWORD_PTR resumeHandle = 0;
    DWORD index;
    SV *sv;
    DWORD lastError = 0;

    if (items != 3) {
	croak("Usage: Win32::NetAdmin::GroupGetMembers(server, groupName, \\@userArray)\n");
    }
    {
	STRLEN n_a;
	sv = ST(2);
	if (SvROK(sv)) {
	    sv = SvRV(sv);
	}
	if (SvTYPE(sv) == SVt_PVAV) {
	    av_clear((AV*)sv);
	    AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	    AllocWideName((char*)SvPV(ST(1),n_a), lpwGroup);
	    do {
		lastError = NetGroupGetUsers(lpwServer, lpwGroup, 0,
					     (LPBYTE*)&pwzGroupUsers, PREFLEN,
					     &entriesRead, &totalEntries,
					     &resumeHandle);
		if (lastError != 0 && lastError != ERROR_MORE_DATA)
		    break;
		for (index = 0; index < entriesRead; ++index) {
		    W2AHELPER(pwzGroupUsers[index].grui0_name,
			  buffer, sizeof(buffer));
		    av_push((AV*)sv, newSVpv(buffer, 0));
		}
		NetApiBufferFree(pwzGroupUsers);
	    } while(lastError == ERROR_MORE_DATA);
	    FreeWideName(lpwServer);
	    FreeWideName(lpwGroup);
	}
	else {
	    croak("Usage: Win32::NetAdmin::GroupGetMembers(server, groupName, "
		  "\\@userArray)\nuserArray was not an array\n");
	}
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_LocalGroupCreate)
{
    dXSARGS;
    LPWSTR lpwServer;
    LOCALGROUP_INFO_1 groupInfo;
    DWORD lastError = 0;

    if (items != 3) {
	croak("Usage: Win32::NetAdmin::LocalGroupCreate(server, group, comment)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), groupInfo.lgrpi1_name);
	AllocWideName((char*)SvPV(ST(2),n_a), groupInfo.lgrpi1_comment);
	lastError = NetLocalGroupAdd(lpwServer, 1, (LPBYTE)&groupInfo, NULL);
	FreeWideName(lpwServer);
	FreeWideName(groupInfo.lgrpi1_name);
	FreeWideName(groupInfo.lgrpi1_comment);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_LocalGroupDelete)
{
    dXSARGS;
    LPWSTR lpwServer, lpwGroup;
    DWORD lastError = 0;

    if (items != 2) {
	croak("Usage: Win32::NetAdmin::LocalGroupDelete(server, group)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), lpwGroup);
	lastError = NetLocalGroupDel(lpwServer, lpwGroup);
	FreeWideName(lpwServer);
	FreeWideName(lpwGroup);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_LocalGroupGetAttributes)
{
    dXSARGS;
    char buffer[UNLEN+1];
    LPWSTR lpwServer, lpwGroup;
    PLOCALGROUP_INFO_1 pgroupInfo;
    DWORD lastError = 0;

    if (items != 3) {
	croak("Usage: Win32::NetAdmin::LocalGroupGetAttributes(server, groupName, comment)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), lpwGroup);
	lastError = NetLocalGroupGetInfo(lpwServer, lpwGroup, 1, (LPBYTE*)&pgroupInfo);
	if (lastError == 0) {
	    W2AHELPER(pgroupInfo->lgrpi1_comment, buffer, sizeof(buffer));
	    SETPV(2, buffer);
	    NetApiBufferFree(pgroupInfo);
	}
	FreeWideName(lpwServer);
	FreeWideName(lpwGroup);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_LocalGroupSetAttributes)
{
    dXSARGS;
    LPWSTR lpwServer;
    LOCALGROUP_INFO_1 groupInfo;
    DWORD lastError = 0;

    if (items != 3) {
	croak("Usage: Win32::NetAdmin::LocalGroupSetAttributes(server, groupName, comment)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), groupInfo.lgrpi1_name);
	AllocWideName((char*)SvPV(ST(2),n_a), groupInfo.lgrpi1_comment);
	lastError = NetLocalGroupSetInfo(lpwServer, groupInfo.lgrpi1_name, 1, (LPBYTE)&groupInfo, NULL);
	FreeWideName(lpwServer);
	FreeWideName(groupInfo.lgrpi1_name);
	FreeWideName(groupInfo.lgrpi1_comment);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_LocalGroupAddUsers)
{
    dXSARGS;
    LPWSTR lpwServer, lpwGroup;
    LOCALGROUP_MEMBERS_INFO_3 lgmi3MembersInfo;
    WCHAR wzUser[UNLEN+2];
    int count, index;
    SV *sv, **psv;
    DWORD lastError = 0;

    if (items != 3) {
	croak("Usage: Win32::NetAdmin::LocalGroupAddUsers(server, groupName, users)\n");
    }
    {
	STRLEN n_a;
	lgmi3MembersInfo.lgrmi3_domainandname = wzUser;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), lpwGroup);
	sv = ST(2);
	if (SvROK(sv)) {
	    sv = SvRV(sv);
	}
	switch(SvTYPE(sv)) {
	case SVt_PVAV:
	    count = av_len((AV*)sv);
	    for (index = 0; index <= count; ++index) {
		psv = av_fetch((AV*)sv, index, 0);
		if (psv != NULL) {
		    MultiByteToWideChar(CP_ACP, 0, (char*)SvPV(*psv,n_a),
					-1, wzUser, sizeof(wzUser));
		    lastError = NetLocalGroupAddMembers(lpwServer, lpwGroup, 3,
							(LPBYTE)&lgmi3MembersInfo, 1);
		    if (lastError != 0)
		    	break;
		}
	    }
	    break;
	default:
	    MultiByteToWideChar(CP_ACP, 0, (char*)SvPV(sv,n_a), -1,
				wzUser, sizeof(wzUser));
	    lastError = NetLocalGroupAddMembers(lpwServer, lpwGroup, 3,
						(LPBYTE)&lgmi3MembersInfo, 1);
	    break;
	}
	FreeWideName(lpwServer);
	FreeWideName(lpwGroup);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_LocalGroupDeleteUsers)
{
    dXSARGS;
    LPWSTR lpwServer, lpwGroup;
    LOCALGROUP_MEMBERS_INFO_3 lgmi3MembersInfo;
    WCHAR wzUser[UNLEN+2];
    int count, index;
    SV *sv, **psv;
    DWORD lastError = 0;

    if (items != 3) {
	croak("Usage: Win32::NetAdmin::LocalGroupDeleteUsers(server, groupName, users)\n");
    }
    {
	STRLEN n_a;
	lgmi3MembersInfo.lgrmi3_domainandname = wzUser;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), lpwGroup);
	sv = ST(2);
	if (SvROK(sv)) {
	    sv = SvRV(sv);
	}
	switch(SvTYPE(sv)) {
	case SVt_PVAV:
	    count = av_len((AV*)sv);
	    for (index = 0; index <= count; ++index) {
		psv = av_fetch((AV*)sv, index, 0);
		if (psv != NULL) {
		    MultiByteToWideChar(CP_ACP, 0, (char*)SvPV(*psv,n_a),
					-1, wzUser, sizeof(wzUser));
		    lastError = NetLocalGroupDelMembers(lpwServer, lpwGroup, 3,
							(LPBYTE)&lgmi3MembersInfo, 1);
		    if (lastError != 0)
			break;
		}
	    }
	    break;
	default:
	    MultiByteToWideChar(CP_ACP, 0, (char*)SvPV(sv,n_a), -1,
				wzUser, sizeof(wzUser));
	    lastError = NetLocalGroupDelMembers(lpwServer, lpwGroup, 3,
						(LPBYTE)&lgmi3MembersInfo, 1);
	    break;
	}
	FreeWideName(lpwServer);
	FreeWideName(lpwGroup);
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_LocalGroupIsMember)
{
    dXSARGS;
    LPWSTR lpwServer, lpwGroup;
    DWORD entriesRead, totalEntries;
    DWORD_PTR resumeHandle = 0;
    DWORD index;
    BOOL bReturn = FALSE;
    DWORD lastError = 0;

    if (items != 3) {
	croak("Usage: Win32::NetAdmin::LocalGroupIsMember(server, groupName, user)\n");
    }
    {
	STRLEN n_a;
#if 1
	PSID pSid;
        lastError = GetAccountSIDA((LPCTSTR)SvPV(ST(0),n_a),
                                   (LPCTSTR)SvPV(ST(2),n_a),
                                   &pSid);
	if(ERROR_SUCCESS != lastError)
	    XSRETURN_NO;

	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), lpwGroup);
	do {
	    PLOCALGROUP_MEMBERS_INFO_0 pwzMembersInfo;
	    lastError = NetLocalGroupGetMembers(lpwServer, lpwGroup, 0,
						(LPBYTE*)&pwzMembersInfo,
		    				PREFLEN, &entriesRead,
						&totalEntries, &resumeHandle);
	    if (lastError != 0 && lastError != ERROR_MORE_DATA)
		break;
	    for (index = 0; index < entriesRead; ++index)
		if (EqualSid(pSid, pwzMembersInfo[index].lgrmi0_sid) != 0){
		    bReturn = TRUE;
		    break;
		}

	    NetApiBufferFree(pwzMembersInfo);
	} while(bReturn == FALSE &&
		(lastError == ERROR_MORE_DATA ||  resumeHandle != 0));

	free(pSid);
	FreeWideName(lpwServer);
	FreeWideName(lpwGroup);
#else
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	AllocWideName((char*)SvPV(ST(1),n_a), lpwGroup);
	AllocWideName((char*)SvPV(ST(2),n_a), lpwUser);
	{
	    PLOCALGROUP_USERS_INFO_0 pwzGroupUsers, lpGroupInfo;
	    lastError = NetUserGetLocalGroups(lpwServer, lpwUser, 0,
					      LG_INCLUDE_INDIRECT,
					      (LPBYTE*)&pwzGroupUsers, PREFLEN,
					      &entriesRead, &totalEntries);
	    if (lastError == 0) {
		// should check that entriesRead == totalEntries and redo if not
		// but 'this should not happen' if PREFLEN is sufficiently large
		lpGroupInfo = pwzGroupUsers;
		for (index = 0; index < entriesRead; index++, lpGroupInfo++) {
		    if (lstrcmpiW(lpwGroup, lpGroupInfo->lgrui0_name) == 0) {
			bReturn = TRUE;
			break;
		    }
		}
		NetApiBufferFree(pwzGroupUsers);
	    }
	}
	FreeWideName(lpwServer);
	FreeWideName(lpwGroup);
	FreeWideName(lpwUser);
#endif
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(bReturn);
}

XS(XS_NT__NetAdmin_LocalGroupGetMembers)
{
    dXSARGS;
    LPWSTR lpwServer, lpwGroup;
    char buffer[UNLEN+1];
    PLOCALGROUP_MEMBERS_INFO_1 pwzMembersInfo;
    DWORD entriesRead, totalEntries;
    DWORD_PTR resumeHandle = 0;
    DWORD index;
    SV *sv;
    DWORD lastError = 0;

    if (items != 3) {
	croak("Usage: Win32::NetAdmin::LocalGroupGetMembers(server, groupName, \\@userArray)\n");
    }
    {
	STRLEN n_a;
	sv = ST(2);
	if (SvROK(sv)) {
	    sv = SvRV(sv);
	}
	if (SvTYPE(sv) == SVt_PVAV) {
	    av_clear((AV*)sv);
	    AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	    AllocWideName((char*)SvPV(ST(1),n_a), lpwGroup);
	    do {
		lastError = NetLocalGroupGetMembers(lpwServer, lpwGroup, 1,
						    (LPBYTE*)&pwzMembersInfo,
						    PREFLEN, &entriesRead,
						    &totalEntries,
						    &resumeHandle);
		if (lastError != 0 && lastError != ERROR_MORE_DATA)
		    break;
		for (index = 0; index < entriesRead; ++index) {
		    W2AHELPER(pwzMembersInfo[index].lgrmi1_name, buffer,
			  sizeof(buffer));
		    av_push((AV*)sv, newSVpv(buffer, 0));
		}
		NetApiBufferFree(pwzMembersInfo);
	    } while (lastError == ERROR_MORE_DATA || resumeHandle != 0);
	    FreeWideName(lpwServer);
	    FreeWideName(lpwGroup);
	}
	else {
	    croak("Usage: Win32::NetAdmin::LocalGroupGetMembers(server, "
		  "groupName, \\@userArray)\nuserArray was not an array\n");
	}
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

/* Retrieve username with domain prepended */
XS(XS_NT__NetAdmin_LocalGroupGetMembersWithDomain)
{
    dXSARGS;
    LPWSTR lpwServer, lpwGroup;
    char buffer[UNLEN+1];
    char buffer1[UNLEN+1];
    PLOCALGROUP_MEMBERS_INFO_2 pwzMembersInfo;
    DWORD entriesRead, totalEntries;
    DWORD_PTR resumeHandle = 0;
    DWORD index;
    SV *sv;
    DWORD lastError = 0;

    if (items != 3) {
	croak("Usage: Win32::NetAdmin::LocalGroupGetMembersWithDomain(server, groupName, userRef)\n");
    }
    {
	STRLEN n_a;
	sv = ST(2);
	if (SvROK(sv)) {
	    sv = SvRV(sv);
	}
	if (SvTYPE(sv) == SVt_PVAV) {
	    av_clear((AV*)sv);
	    AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	    AllocWideName((char*)SvPV(ST(1),n_a), lpwGroup);
	    do {
		lastError = NetLocalGroupGetMembers(lpwServer, lpwGroup, 2,
						    (LPBYTE*)&pwzMembersInfo,
						    PREFLEN, &entriesRead,
						    &totalEntries,
						    &resumeHandle);
		if (lastError != 0 && lastError != ERROR_MORE_DATA)
		    break;
		for (index = 0; index < entriesRead; ++index) {
		    W2AHELPER(pwzMembersInfo[index].lgrmi2_domainandname, buffer,
			  sizeof(buffer));
		    av_push((AV*)sv, newSVpv(buffer, 0));
		}
		NetApiBufferFree(pwzMembersInfo);
	    } while (lastError == ERROR_MORE_DATA || resumeHandle != 0);
	    FreeWideName(lpwServer);
	    FreeWideName(lpwGroup);
	}
	else if( SvTYPE(sv) == SVt_PVHV) {
	    hv_clear((HV*)sv);
	    AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	    AllocWideName((char*)SvPV(ST(1),n_a), lpwGroup);
	    do {
		lastError = NetLocalGroupGetMembers(lpwServer, lpwGroup, 2,
						    (LPBYTE*)&pwzMembersInfo,
						    PREFLEN, &entriesRead,
						    &totalEntries,
						    &resumeHandle);
		if (lastError != 0 && lastError != ERROR_MORE_DATA)
		    break;
		for (index = 0; index < entriesRead; ++index) {
		    W2AHELPER(pwzMembersInfo[index].lgrmi2_domainandname, buffer,
			  sizeof(buffer));
		    sprintf(buffer1, "%d", pwzMembersInfo[index].lgrmi2_sidusage );
		    hv_store((HV*)sv, buffer, strlen(buffer),
			     newSViv((DWORD)pwzMembersInfo[index].lgrmi2_sidusage),0);
		}
		NetApiBufferFree(pwzMembersInfo);
	    } while (lastError == ERROR_MORE_DATA || resumeHandle != 0);
	    FreeWideName(lpwServer);
	    FreeWideName(lpwGroup);
	}
	else {
	    croak("Usage: Win32::NetAdmin::LocalGroupGetMembersWithDomain(server, "
		  "groupName, userRef)\nuserRef was not an array or hash reference\n");
	}
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_GetServers)
{
    dXSARGS;
    LPWSTR lpwServer, lpwDomain;
    char buffer[UNLEN+1];
    char buffer1[UNLEN+1];
    PSERVER_INFO_100 pwzServerInfo;
    PSERVER_INFO_101 pwzServerInfo101;
    DWORD entriesRead, totalEntries;
    DWORD_PTR resumeHandle = 0;
    DWORD index;
    SV *sv;
    DWORD lastError = 0;

    if (items != 4) {
	croak("Usage: Win32::NetAdmin::GetServers(server, domain, flags, "
	      "$serverRef)\n");
    }
    {
	STRLEN n_a;
	sv = ST(3);
	if (SvROK(sv)) {
	    sv = SvRV(sv);
	}
	if (SvTYPE(sv) == SVt_PVAV) {
	    av_clear((AV*)sv);
	    AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	    AllocWideName((char*)SvPV(ST(1),n_a), lpwDomain);
	    do {
		lastError = NetServerEnum(lpwServer, 100,
					  (LPBYTE*) &pwzServerInfo,
					  PREFLEN, &entriesRead,
					  &totalEntries, (DWORD)SvIV(ST(2)),
					  lpwDomain, &resumeHandle);
		if (lastError != 0 && lastError != ERROR_MORE_DATA)
		    break;
		for (index = 0; index < entriesRead; ++index) {
		    W2AHELPER(pwzServerInfo[index].sv100_name, buffer,
			  sizeof(buffer));
		    av_push((AV*)sv, newSVpv(buffer, 0));
		}
		NetApiBufferFree(pwzServerInfo);
	    } while(lastError == ERROR_MORE_DATA);
	    FreeWideName(lpwServer);
	    FreeWideName(lpwDomain);
	}
	else if( SvTYPE(sv) == SVt_PVHV) {
	    hv_clear((HV*)sv);
	    AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	    AllocWideName((char*)SvPV(ST(1),n_a), lpwDomain);
	    do {
		lastError = NetServerEnum(lpwServer, 101,
					  (LPBYTE*) &pwzServerInfo101,
					  PREFLEN, &entriesRead,
					  &totalEntries, (DWORD)SvIV(ST(2)),
					  lpwDomain, &resumeHandle);
		if (lastError != 0 && lastError != ERROR_MORE_DATA)
		    break;
		for (index = 0; index < entriesRead; ++index) {
		    W2AHELPER(pwzServerInfo101[index].sv101_name, buffer,
			  sizeof(buffer));
		    W2AHELPER(pwzServerInfo101[index].sv101_comment, buffer1,
			  sizeof(buffer1));
		    hv_store((HV*)sv, buffer, strlen(buffer),
			     newSVpv(buffer1,0), 0 );
		}
		NetApiBufferFree(pwzServerInfo101);
	    } while(lastError == ERROR_MORE_DATA);
	    FreeWideName(lpwServer);
	    FreeWideName(lpwDomain);
	}
	else {
	    croak("Usage: Win32::NetAdmin::GetServers(server, domain, flags, "
		  "$serverRef)\nserverRef was not an array or hash\n");
	}
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}

XS(XS_NT__NetAdmin_GetServerDisks)
{
    dXSARGS;
    LPWSTR lpwServer;
    char buffer[256];
    LPWSTR disks;
    LPWSTR p;
    DWORD entriesRead, totalEntries;
    DWORD_PTR resumeHandle = 0;
    DWORD index;
    SV *sv;
    DWORD lastError = 0;

    if (items != 2) {
	croak("Usage: Win32::NetAdmin::GetServerDisks(server, \\@diskArray)\n");
    }
    {
	STRLEN n_a;
	sv = ST(1);
	if (SvROK(sv)) {
	    sv = SvRV(sv);
	}
	if (SvTYPE(sv) == SVt_PVAV) {
	    av_clear((AV*)sv);
	    AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	    do {
		lastError = NetServerDiskEnum(lpwServer, 0,
						    (LPBYTE*)&disks,
						    PREFLEN, &entriesRead,
						    &totalEntries,
						    &resumeHandle);
		if (lastError != 0 && lastError != ERROR_MORE_DATA)
		    break;
		p = disks;
		for (index = 0; index < entriesRead; ++index) {
		    W2AHELPER(p, buffer, sizeof(buffer));
		    av_push((AV*)sv, newSVpv(buffer, strlen(buffer)));
		    p += 3;
		}
		NetApiBufferFree(disks);
	    } while (lastError == ERROR_MORE_DATA || resumeHandle != 0);
	    FreeWideName(lpwServer);
	}
	else {
	    croak("Usage: Win32::NetAdmin::GetServerDisks(server, "
		  "\\@diskArray)\ndiskArray was not an array\n");
	}
    }
    SetNetAdminLastError(lastError);
    RETURNRESULT(lastError == 0);
}


XS(XS_NT__NetAdmin_GetAliasFromRID)
{
    dXSARGS;
    char buffer[512];
    SID_NAME_USE snu;
    PSID pSid;
    WCHAR DomainName[DNLEN+2];
    WCHAR Name[UNLEN+2];
    DWORD chName = UNLEN+2;
    BOOL bSuccess = FALSE;
    DWORD rid = 0;
    LPWSTR lpwServer = NULL;
    DWORD cchDomainName = DNLEN+2;
    SID_IDENTIFIER_AUTHORITY sia = SECURITY_NT_AUTHORITY;

    if (items != 3) {
	croak("Usage: Win32::NetAdmin::GetAliasFromRID(server, RID, returnedName)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	rid = (DWORD)SvIV(ST(1));
	if(AllocateAndInitializeSid( &sia, 2, SECURITY_BUILTIN_DOMAIN_RID,
				     rid, 0, 0, 0, 0, 0, 0, &pSid ))
	{
	    bSuccess = LookupAccountSidW( lpwServer, pSid,
					  (LPWSTR)Name,
					  &chName, DomainName, &cchDomainName,
					  &snu );
	    FreeSid(pSid);
	}
	if(bSuccess)
	{
	    W2AHELPER(Name, buffer, sizeof(buffer));
	    SETPV(2,buffer);
	}
	FreeWideName(lpwServer);
    }

    RETURNRESULT(bSuccess);
}

XS(XS_NT__NetAdmin_GetUserGroupFromRID)
{
    dXSARGS;
    char buffer[512];
    PUSER_MODALS_INFO_2 umi2;
    NET_API_STATUS nas;

    UCHAR SubAuthorityCount;
    PSID pSid;
    SID_NAME_USE snu;

    WCHAR DomainName[DNLEN+2];
    DWORD cchDomainName = DNLEN+2;
    WCHAR Name[UNLEN+2];
    DWORD chName = UNLEN+2;
    BOOL bSuccess = FALSE; /* assume failure */
    DWORD rid = 0;
    LPWSTR lpwServer = NULL;
	

    if (items != 3) {
	croak("Usage: Win32::NetAdmin::GetUserGroupFromRID(server, RID, returnedName)\n");
    }
    {
	STRLEN n_a;
	AllocWideName((char*)SvPV(ST(0),n_a), lpwServer);
	rid = (DWORD)SvIV(ST(1));

	nas = NetUserModalsGet(lpwServer, 2, (LPBYTE *)&umi2);

	if(nas != NERR_Success) {
	    SetLastError(nas);
	    RETURNRESULT(FALSE);
	}

	SubAuthorityCount = *GetSidSubAuthorityCount(umi2->usrmod2_domain_id);

	pSid =
	    (PSID)malloc(GetSidLengthRequired((UCHAR)(SubAuthorityCount + 1)));

	if (pSid != NULL) {
	    if (InitializeSid(pSid,
			     GetSidIdentifierAuthority(umi2->usrmod2_domain_id),
			     (BYTE)(SubAuthorityCount+1)))
	    {
		DWORD SubAuthIndex = 0;
				
		/*
		 * copy existing subauthorities from account domain Sid into
		 * new Sid
		 */
		
		for( ; SubAuthIndex < SubAuthorityCount ; SubAuthIndex++) {
		    *GetSidSubAuthority(pSid, SubAuthIndex) =
			*GetSidSubAuthority(umi2->usrmod2_domain_id, SubAuthIndex);
		}
				
		/*
		 * append Rid to new Sid
		 */
				
		*GetSidSubAuthority(pSid, SubAuthorityCount) = rid;
		
		bSuccess = LookupAccountSidW(lpwServer,
					     pSid,
					     Name,
					     &chName,
					     DomainName,
					     &cchDomainName,
					     &snu);
	    }
	    free(pSid);
	}
	NetApiBufferFree(umi2);
	if(bSuccess)
	{
	    W2AHELPER(Name, buffer, sizeof(buffer));
	    SETPV(2,buffer);
	}
	FreeWideName(lpwServer);
    }

    RETURNRESULT(bSuccess);
}

XS(boot_Win32__NetAdmin)
{
    dXSARGS;
    char* file = __FILE__;

    newXS("Win32::NetAdmin::constant", XS_NT__NetAdmin_constant, file);
    newXS("Win32::NetAdmin::GetDomainController", XS_NT__NetAdmin_GetDomainController, file);
    newXS("Win32::NetAdmin::GetAnyDomainController", XS_NT__NetAdmin_GetAnyDomainController, file);
    newXS("Win32::NetAdmin::UserCreate", XS_NT__NetAdmin_UserCreate, file);
    newXS("Win32::NetAdmin::UserDelete", XS_NT__NetAdmin_UserDelete, file);
    newXS("Win32::NetAdmin::UserGetAttributes", XS_NT__NetAdmin_UserGetAttributes, file);
    newXS("Win32::NetAdmin::UserSetAttributes", XS_NT__NetAdmin_UserSetAttributes, file);
    newXS("Win32::NetAdmin::UsersExist", XS_NT__NetAdmin_UsersExist, file);
    newXS("Win32::NetAdmin::GetUsers", XS_NT__NetAdmin_GetUsers, file);
    newXS("Win32::NetAdmin::LoggedOnUsers", XS_NT__NetAdmin_LoggedOnUsers, file);
    newXS("Win32::NetAdmin::GroupCreate", XS_NT__NetAdmin_GroupCreate, file);
    newXS("Win32::NetAdmin::GroupDelete", XS_NT__NetAdmin_GroupDelete, file);
    newXS("Win32::NetAdmin::GroupGetAttributes", XS_NT__NetAdmin_GroupGetAttributes, file);
    newXS("Win32::NetAdmin::GroupSetAttributes", XS_NT__NetAdmin_GroupSetAttributes, file);
    newXS("Win32::NetAdmin::GroupAddUsers", XS_NT__NetAdmin_GroupAddUsers, file);
    newXS("Win32::NetAdmin::GroupDeleteUsers", XS_NT__NetAdmin_GroupDeleteUsers, file);
    newXS("Win32::NetAdmin::GroupIsMember", XS_NT__NetAdmin_GroupIsMember, file);
    newXS("Win32::NetAdmin::GroupGetMembers", XS_NT__NetAdmin_GroupGetMembers, file);
    newXS("Win32::NetAdmin::LocalGroupCreate", XS_NT__NetAdmin_LocalGroupCreate, file);
    newXS("Win32::NetAdmin::LocalGroupDelete", XS_NT__NetAdmin_LocalGroupDelete, file);
    newXS("Win32::NetAdmin::LocalGroupGetAttributes", XS_NT__NetAdmin_LocalGroupGetAttributes, file);
    newXS("Win32::NetAdmin::LocalGroupSetAttributes", XS_NT__NetAdmin_LocalGroupSetAttributes, file);

    newXS("Win32::NetAdmin::LocalGroupAddUsers", XS_NT__NetAdmin_LocalGroupAddUsers, file);
    newXS("Win32::NetAdmin::LocalGroupDeleteUsers", XS_NT__NetAdmin_LocalGroupDeleteUsers, file);
    newXS("Win32::NetAdmin::UserChangePassword", XS_NT__NetAdmin_UserChangePassword, file);

    newXS("Win32::NetAdmin::LocalGroupIsMember", XS_NT__NetAdmin_LocalGroupIsMember, file);
    newXS("Win32::NetAdmin::LocalGroupGetMembers", XS_NT__NetAdmin_LocalGroupGetMembers, file);
    newXS("Win32::NetAdmin::LocalGroupGetMembersWithDomain", XS_NT__NetAdmin_LocalGroupGetMembersWithDomain, file);
    newXS("Win32::NetAdmin::GetServers", XS_NT__NetAdmin_GetServers, file);
    newXS("Win32::NetAdmin::GetServerDisks", XS_NT__NetAdmin_GetServerDisks, file);
    newXS("Win32::NetAdmin::GetTransports", XS_NT__NetAdmin_GetTransports, file);
    newXS("Win32::NetAdmin::GetAliasFromRID", XS_NT__NetAdmin_GetAliasFromRID, file);
    newXS("Win32::NetAdmin::GetUserGroupFromRID", XS_NT__NetAdmin_GetUserGroupFromRID, file);
    XSRETURN_YES;
}

