#include <windows.h>
#ifndef __CYGWIN__
#   include <winsock.h>
#endif
#include <lmcons.h>    /* LAN Manager common definitions */
#include <lmerr.h>    /* LAN Manager network error definitions */
#include <lmUseFlg.h>
#include <lmAccess.h>
#include <lmAPIBuf.h>
#include <lmwksta.h>
#undef LPTSTR
#define LPTSTR LPWSTR
#include <lmServer.h>
#undef LPTSTR

#ifndef __SDDL_H__
WINADVAPI BOOL WINAPI ConvertSidToStringSidA(PSID, LPSTR*);
#endif

/* old versions of lmaccess.h don't include these Windows 2003 additions */
typedef struct {
    LPWSTR   usri4_name;
    LPWSTR   usri4_password;
    DWORD    usri4_password_age;
    DWORD    usri4_priv;
    LPWSTR   usri4_home_dir;
    LPWSTR   usri4_comment;
    DWORD    usri4_flags;
    LPWSTR   usri4_script_path;
    DWORD    usri4_auth_flags;
    LPWSTR   usri4_full_name;
    LPWSTR   usri4_usr_comment;
    LPWSTR   usri4_parms;
    LPWSTR   usri4_workstations;
    DWORD    usri4_last_logon;
    DWORD    usri4_last_logoff;
    DWORD    usri4_acct_expires;
    DWORD    usri4_max_storage;
    DWORD    usri4_units_per_week;
    PBYTE    usri4_logon_hours;
    DWORD    usri4_bad_pw_count;
    DWORD    usri4_num_logons;
    LPWSTR   usri4_logon_server;
    DWORD    usri4_country_code;
    DWORD    usri4_code_page;
    PSID     usri4_user_sid;
    DWORD    usri4_primary_group_id;
    LPWSTR   usri4_profile;
    LPWSTR   usri4_home_dir_drive;
    DWORD    usri4_password_expired;
} MY_USER_INFO_4, *PMY_USER_INFO_4;

typedef struct {
    LPWSTR   usri23_name;
    LPWSTR   usri23_full_name;
    LPWSTR   usri23_comment;
    DWORD    usri23_flags;
    PSID     usri23_user_sid;
} MY_USER_INFO_23, *PMY_USER_INFO_23;

typedef struct {
    LPWSTR   grpi3_name;
    LPWSTR   grpi3_comment;
    PSID     grpi3_group_sid;
    DWORD    grpi3_attributes;
} MY_GROUP_INFO_3, *PMY_GROUP_INFO_3;

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifndef _WIN64
#  define DWORD_PTR DWORD
#endif

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
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
	break;
    case 'E':
	break;
    case 'F':
	if (strEQ(name, "FILTER_TEMP_DUPLICATE_ACCOUNTS"))
#ifdef FILTER_TEMP_DUPLICATE_ACCOUNTS
	    return FILTER_TEMP_DUPLICATE_ACCOUNTS;
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
	if (strEQ(name, "GROUP_ATTRIBUTES_PARMNUM"))
#ifdef GROUP_ATTRIBUTES_PARMNUM
	    return GROUP_ATTRIBUTES_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GROUP_COMMENT_PARMNUM"))
#ifdef GROUP_COMMENT_PARMNUM
	    return GROUP_COMMENT_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GROUP_NAME_PARMNUM"))
#ifdef GROUP_NAME_PARMNUM
	    return GROUP_NAME_PARMNUM;
#else
	    goto not_there;
#endif
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
	if (strEQ(name, "LG_INCLUDE_INDIRECT"))
#ifdef LG_INCLUDE_INDIRECT
	    return LG_INCLUDE_INDIRECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "LOCALGROUP_NAME_PARMNUM"))
#ifdef LOCALGROUP_NAME_PARMNUM
	    return LOCALGROUP_NAME_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "LOCALGROUP_COMMENT_PARMNUM"))
#ifdef LOCALGROUP_COMMENT_PARMNUM
	    return LOCALGROUP_COMMENT_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "LOGON32_LOGON_BATCH"))
#ifdef LOGON32_LOGON_BATCH
	    return LOGON32_LOGON_BATCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "LOGON32_LOGON_INTERACTIVE"))
#ifdef LOGON32_LOGON_INTERACTIVE
	    return LOGON32_LOGON_INTERACTIVE;
#else
	    goto not_there;
#endif
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
/* PRIV MASKS */
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
/* USER_XXX_PARMNUM FIELDS */
	if (strEQ(name, "USER_NAME_PARMNUM"))
#ifdef USER_NAME_PARMNUM
	    return USER_NAME_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_PASSWORD_PARMNUM"))
#ifdef USER_PASSWORD_PARMNUM
	    return USER_PASSWORD_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_PASSWORD_AGE_PARMNUM"))
#ifdef USER_PASSWORD_AGE_PARMNUM
	    return USER_PASSWORD_AGE_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_PRIV_PARMNUM"))
#ifdef USER_PRIV_PARMNUM
	    return USER_PRIV_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_HOME_DIR_PARMNUM"))
#ifdef USER_HOME_DIR_PARMNUM
	    return USER_HOME_DIR_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_COMMENT_PARMNUM"))
#ifdef USER_COMMENT_PARMNUM
	    return USER_COMMENT_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_FLAGS_PARMNUM"))
#ifdef USER_FLAGS_PARMNUM
	    return USER_FLAGS_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_SCRIPT_PATH_PARMNUM"))
#ifdef USER_SCRIPT_PATH_PARMNUM
	    return USER_SCRIPT_PATH_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_AUTH_FLAGS_PARMNUM"))
#ifdef USER_AUTH_FLAGS_PARMNUM
	    return USER_AUTH_FLAGS_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_FULL_NAME_PARMNUM"))
#ifdef USER_FULL_NAME_PARMNUM
	    return USER_FULL_NAME_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_USR_COMMENT_PARMNUM"))
#ifdef USER_USR_COMMENT_PARMNUM
	    return USER_USR_COMMENT_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_PARMS_PARMNUM"))
#ifdef USER_PARMS_PARMNUM
	    return USER_PARMS_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_WORKSTATIONS_PARMNUM"))
#ifdef USER_WORKSTATIONS_PARMNUM
	    return USER_WORKSTATIONS_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_LAST_LOGON_PARMNUM"))
#ifdef USER_LAST_LOGON_PARMNUM
	    return USER_LAST_LOGON_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_LAST_LOGOFF_PARMNUM"))
#ifdef USER_LAST_LOGOFF_PARMNUM
	    return USER_LAST_LOGOFF_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_ACCT_EXPIRES_PARMNUM"))
#ifdef USER_ACCT_EXPIRES_PARMNUM
	    return USER_ACCT_EXPIRES_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_MAX_STORAGE_PARMNUM"))
#ifdef USER_MAX_STORAGE_PARMNUM
	    return USER_MAX_STORAGE_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_UNITS_PER_WEEK_PARMNUM"))
#ifdef USER_UNITS_PER_WEEK_PARMNUM
	    return USER_UNITS_PER_WEEK_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_LOGON_HOURS_PARMNUM"))
#ifdef USER_LOGON_HOURS_PARMNUM
	    return USER_LOGON_HOURS_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_PAD_PW_COUNT_PARMNUM"))
#ifdef USER_PAD_PW_COUNT_PARMNUM
	    return USER_PAD_PW_COUNT_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_NUM_LOGONS_PARMNUM"))
#ifdef USER_NUM_LOGONS_PARMNUM
	    return USER_NUM_LOGONS_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_LOGON_SERVER_PARMNUM"))
#ifdef USER_LOGON_SERVER_PARMNUM
	    return USER_LOGON_SERVER_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_COUNTRY_CODE_PARMNUM"))
#ifdef USER_COUNTRY_CODE_PARMNUM
	    return USER_COUNTRY_CODE_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_CODE_PAGE_PARMNUM"))
#ifdef USER_CODE_PAGE_PARMNUM
	    return USER_CODE_PAGE_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_PRIMARY_GROUP_PARMNUM"))
#ifdef USER_PRIMARY_GROUP_PARMNUM
	    return USER_PRIMARY_GROUP_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_PROFILE_PARMNUM"))
#ifdef USER_PROFILE_PARMNUM
	    return USER_PROFILE_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_PROFILE_PARMNUM"))
#ifdef USER_PROFILE_PARMNUM
	    return USER_PROFILE_PARMNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USER_HOME_DIR_DRIVE_PARMNUM"))
#ifdef USER_HOME_DIR_DRIVE_PARMNUM
	    return USER_HOME_DIR_DRIVE_PARMNUM;
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

#define PREFLEN 0x20000		/* for *Enum() */

/* MultiByte 2 WideChar */

LPWSTR
MBTWC(char* name)
{
    int length;
    LPWSTR lpPtr = NULL;
    
    if (name) { // && *name != '\0') {
	length = (int)strlen(name)+1;
	Newz(0, lpPtr, length, WCHAR);
	MultiByteToWideChar(CP_ACP, 0, name, -1, lpPtr,
				length * sizeof(WCHAR));
    }
    return lpPtr;
}

/* The following MACROs assume that the following are in scope
 * hv        - HV*, the hv into/from which information is placed/extracted
 * svPtr    - temporary SV** for intermediate SV ** values
 * uiX        - LPBYTE alloc'ed appropriate to CAST
 * tmpBuf    - char * for temporary string values
 */

#define HV_GET_PV(CAST, field, name) \
    STMT_START {							\
	if ((svPtr = hv_fetch((HV*)hv, name, (I32)strlen(name), 0)) == NULL)	\
	    croak("Required argument not supplied (%s),", name);	\
	if (SvOK(*svPtr))						\
	    ((CAST)uiX)->field = MBTWC(SvPV_nolen(*svPtr));		\
	else /* fields set to "undef" pass NULL to underlying API */	\
	    ((CAST)uiX)->field = (LPWSTR)NULL;				\
    } STMT_END

#define HV_GET_IV(CAST, field, name) \
    STMT_START {							\
	if ((svPtr = hv_fetch((HV*)hv, name, (I32)strlen(name), 0)) == NULL)	\
	    croak("Required argument not supplied (%s),", name);	\
	if (!SvIOK(*svPtr))						\
	    croak("Bad data for %s, ", name);				\
	((CAST)uiX)->field = (DWORD)SvIV(*svPtr);			\
    } STMT_END

#define HV_GET_AV(CAST, field, name, n) \
    STMT_START {							\
	int i = 0;							\
	SV **svTmp, *svPtrIndirect;					\
	Newz(0, ((CAST)uiX)->field, n, BYTE);				\
	if ((svPtr = hv_fetch((HV*)hv, name, (I32)strlen(name), 0)) == NULL)	\
	    croak("Required argument not supplied (%s), ", name);	\
	if (!(SvROK(*svPtr) && (svPtrIndirect = SvRV(*svPtr))		\
		&& SvTYPE(svPtrIndirect) == SVt_PVAV))			\
	    croak("Value in logonHours should be an array reference,");	\
	while (i < n) {							\
	    if ((svTmp = av_fetch((AV*)svPtrIndirect, i, 0)) != NULL)	\
		(((CAST)uiX)->field)[i] = (BYTE)SvIV(*svTmp);		\
	    else							\
		(((CAST)uiX)->field)[i] = 0;				\
	    i++;							\
	}								\
    } STMT_END

#define uiX_INIT(t) \
    STMT_START {							\
	if (!uiX) {							\
	    Newc(0,uiX,1,t,LPBYTE);					\
	    memzero((char*)uiX,sizeof(t));				\
	}								\
    } STMT_END

LPBYTE *
allocUserInfoX(int level, HV *hv)
{
    LPBYTE	*uiX = NULL;
    SV		**svPtr;
    dTHX;

    switch (level) {
    case 3:
	uiX_INIT(USER_INFO_3);
	HV_GET_IV(PUSER_INFO_3, usri3_password_expired,     "passwordExpired");
	HV_GET_PV(PUSER_INFO_3, usri3_home_dir_drive,       "homeDirDrive");
	HV_GET_PV(PUSER_INFO_3, usri3_profile,              "profile");
	HV_GET_IV(PUSER_INFO_3, usri3_primary_group_id,     "primaryGroupId");
	HV_GET_IV(PUSER_INFO_3, usri3_user_id,              "userId");
	/* fall through to 2... */
    case 2:
	uiX_INIT(USER_INFO_2);
	HV_GET_IV(PUSER_INFO_2, usri2_code_page,            "codePage");
	HV_GET_IV(PUSER_INFO_2, usri2_country_code,         "countryCode");
	HV_GET_PV(PUSER_INFO_2, usri2_logon_server,         "logonServer");
	HV_GET_IV(PUSER_INFO_2, usri2_num_logons,           "numLogons");
	HV_GET_IV(PUSER_INFO_2, usri2_bad_pw_count,         "badPwCount");
	HV_GET_AV(PUSER_INFO_2, usri2_logon_hours,          "logonHours", 21);
	HV_GET_IV(PUSER_INFO_2, usri2_units_per_week,       "unitsPerWeek");
	HV_GET_IV(PUSER_INFO_2, usri2_max_storage,          "maxStorage");
	HV_GET_IV(PUSER_INFO_2, usri2_acct_expires,         "acctExpires");
	HV_GET_IV(PUSER_INFO_2, usri2_last_logoff,          "lastLogoff");
	HV_GET_IV(PUSER_INFO_2, usri2_last_logon,           "lastLogon");
	HV_GET_PV(PUSER_INFO_2, usri2_workstations,         "workstations");
	HV_GET_PV(PUSER_INFO_2, usri2_parms,                "parms");
	HV_GET_PV(PUSER_INFO_2, usri2_usr_comment,          "usrComment");
	HV_GET_PV(PUSER_INFO_2, usri2_full_name,            "fullName");
	HV_GET_IV(PUSER_INFO_2, usri2_auth_flags,           "authFlags");
	/* fall through to 1... */
    case 1:
	uiX_INIT(USER_INFO_1);
	HV_GET_PV(PUSER_INFO_1, usri1_script_path,          "scriptPath");
	HV_GET_IV(PUSER_INFO_1, usri1_flags,                "flags");
	HV_GET_PV(PUSER_INFO_1, usri1_comment,              "comment");
	HV_GET_PV(PUSER_INFO_1, usri1_home_dir,             "homeDir");
	HV_GET_IV(PUSER_INFO_1, usri1_priv,                 "priv");
	HV_GET_IV(PUSER_INFO_1, usri1_password_age,         "passwordAge");
	HV_GET_PV(PUSER_INFO_1, usri1_password,             "password");
	/* fall through to 0... */
    case 0:
	uiX_INIT(USER_INFO_0);
	HV_GET_PV(PUSER_INFO_0, usri0_name,                 "name");
	break;
    case 11:
	uiX_INIT(USER_INFO_11);
	HV_GET_IV(PUSER_INFO_11, usri11_code_page,          "codePage");
	HV_GET_AV(PUSER_INFO_11, usri11_logon_hours,        "logonHours", 21);
	HV_GET_IV(PUSER_INFO_11, usri11_units_per_week,     "unitsPerWeek");
	HV_GET_IV(PUSER_INFO_11, usri11_max_storage,        "maxStorage");
	HV_GET_PV(PUSER_INFO_11, usri11_workstations,       "workstations");
	HV_GET_IV(PUSER_INFO_11, usri11_country_code,       "countryCode");
	HV_GET_PV(PUSER_INFO_11, usri11_logon_server,       "logonServer");
	HV_GET_IV(PUSER_INFO_11, usri11_num_logons,         "numLogons");
	HV_GET_IV(PUSER_INFO_11, usri11_bad_pw_count,       "badPwCount");
	HV_GET_IV(PUSER_INFO_11, usri11_last_logoff,        "lastLogoff");
	HV_GET_IV(PUSER_INFO_11, usri11_last_logon,         "lastLogon");
	HV_GET_PV(PUSER_INFO_11, usri11_parms,              "parms");
	HV_GET_PV(PUSER_INFO_11, usri11_home_dir,           "homeDir");
	HV_GET_IV(PUSER_INFO_11, usri11_password_age,       "passwordAge");
	HV_GET_IV(PUSER_INFO_11, usri11_auth_flags,         "authFlags");
	HV_GET_IV(PUSER_INFO_11, usri11_priv,               "priv");
	/* fall through to 10... */
    case 10:
	uiX_INIT(USER_INFO_10);
	HV_GET_PV(PUSER_INFO_10, usri10_full_name,          "fullName");
	HV_GET_PV(PUSER_INFO_10, usri10_usr_comment,        "usrComment");
	HV_GET_PV(PUSER_INFO_10, usri10_comment,            "comment");
	HV_GET_PV(PUSER_INFO_10, usri10_name,               "name");
	break;
    case 20:
	uiX_INIT(USER_INFO_20);
	HV_GET_IV(PUSER_INFO_20, usri20_user_id,            "userId");
	HV_GET_IV(PUSER_INFO_20, usri20_flags,              "flags");
	HV_GET_PV(PUSER_INFO_20, usri20_comment,            "comment");
	HV_GET_PV(PUSER_INFO_20, usri20_full_name,          "fullName");
	HV_GET_PV(PUSER_INFO_20, usri20_name,               "name");
	break;
    case 21:
    case 22:
	croak("level %d not yet implemented for User*() functions\n");
    case 1003:
	/* need to put a value in (can't rely on Get) */
	uiX_INIT(USER_INFO_1003);
	HV_GET_PV(PUSER_INFO_1003, usri1003_password,       "password");
	break;
    case 1005:
	uiX_INIT(USER_INFO_1005);
	HV_GET_IV(PUSER_INFO_1005, usri1005_priv,           "priv");
	break;
    case 1006:
	uiX_INIT(USER_INFO_1006);
	HV_GET_PV(PUSER_INFO_1006, usri1006_home_dir,       "homeDir");
	break;
    case 1007:
	uiX_INIT(USER_INFO_1007);
	HV_GET_PV(PUSER_INFO_1007, usri1007_comment, "comment");
	break;
    case 1008:
	uiX_INIT(USER_INFO_1008);
	HV_GET_IV(PUSER_INFO_1008, usri1008_flags, "flags");
	break;
    case 1009:
	uiX_INIT(USER_INFO_1009);
	HV_GET_PV(PUSER_INFO_1009, usri1009_script_path, "scriptPath");
	break;
    case 1010:
	uiX_INIT(USER_INFO_1010);
	HV_GET_IV(PUSER_INFO_1010, usri1010_auth_flags, "authFlags");
	break;
    case 1011:
	uiX_INIT(USER_INFO_1011);
	HV_GET_PV(PUSER_INFO_1011, usri1011_full_name, "fullName");
	break;
    case 1012:
	uiX_INIT(USER_INFO_1012);
	HV_GET_PV(PUSER_INFO_1012, usri1012_usr_comment, "usrComment");
	break;
    case 1013:
	uiX_INIT(USER_INFO_1013);
	HV_GET_PV(PUSER_INFO_1013, usri1013_parms, "parms");
	break;
    case 1014:
	uiX_INIT(USER_INFO_1014);
	HV_GET_PV(PUSER_INFO_1014, usri1014_workstations, "workstations");
	break;
    case 1017:
	uiX_INIT(USER_INFO_1017);
	HV_GET_IV(PUSER_INFO_1017, usri1017_acct_expires, "acctExpires");
	break;
    case 1018:
	uiX_INIT(USER_INFO_1018);
	HV_GET_IV(PUSER_INFO_1018, usri1018_max_storage, "maxStorage");
	break;
    case 1020:
	uiX_INIT(USER_INFO_1020);
	HV_GET_IV(PUSER_INFO_1020, usri1020_units_per_week, "unitsPerWeek");
	HV_GET_AV(PUSER_INFO_1020, usri1020_logon_hours, "logonHours", 21);
	break;
    case 1023:
	uiX_INIT(USER_INFO_1023);
	HV_GET_PV(PUSER_INFO_1023, usri1023_logon_server, "logonServer");
	break;
    case 1024:
	uiX_INIT(USER_INFO_1024);
	HV_GET_IV(PUSER_INFO_1024, usri1024_country_code, "countryCode");
	break;
    case 1025:
	uiX_INIT(USER_INFO_1025);
	HV_GET_IV(PUSER_INFO_1025, usri1025_code_page, "codePage");
	break;
    case 1051:
	uiX_INIT(USER_INFO_1051);
	HV_GET_IV(PUSER_INFO_1051, usri1051_primary_group_id, "primaryGroupId");
	break;
    case 1052:
	uiX_INIT(USER_INFO_1052);
	HV_GET_PV(PUSER_INFO_1052, usri1052_profile, "profile");
	break;
    case 1053:
	uiX_INIT(USER_INFO_1053);
	HV_GET_PV(PUSER_INFO_1053, usri1053_home_dir_drive, "homeDirDrive");
	break;
    default:
	croak("Level %d is not a valid level for NetUser functions\n", level);
	break;
    }
    
    return uiX;
}

void
freeWideName(LPWSTR lpPtr)
{
    Safefree(lpPtr);
}

#define WCFREE(CAST, field) freeWideName(((CAST)uiX)->field)
#define PBFREE(CAST, field) Safefree(((CAST)uiX)->field)

void
freeUserInfoX(LPBYTE *uiX, int level)
{
    dTHX;
    switch (level) {
    case 3:
	WCFREE(PUSER_INFO_3, usri3_home_dir_drive);
	WCFREE(PUSER_INFO_3, usri3_profile);
	/* fall through to 2... */
    case 2:
	WCFREE(PUSER_INFO_2, usri2_logon_server);
	PBFREE(PUSER_INFO_2, usri2_logon_hours);
	WCFREE(PUSER_INFO_2, usri2_workstations);
	WCFREE(PUSER_INFO_2, usri2_parms);
	WCFREE(PUSER_INFO_2, usri2_usr_comment);
	WCFREE(PUSER_INFO_2, usri2_full_name);
	/* fall through to 1... */
    case 1:
	WCFREE(PUSER_INFO_1, usri1_script_path);
	WCFREE(PUSER_INFO_1, usri1_comment);
	WCFREE(PUSER_INFO_1, usri1_home_dir);
	WCFREE(PUSER_INFO_1, usri1_password);
    case 0:
	WCFREE(PUSER_INFO_0, usri0_name);
	break;
    case 11:
	PBFREE(PUSER_INFO_11, usri11_logon_hours);
	WCFREE(PUSER_INFO_11, usri11_workstations);
	WCFREE(PUSER_INFO_11, usri11_logon_server);
	WCFREE(PUSER_INFO_11, usri11_parms);
	WCFREE(PUSER_INFO_11, usri11_home_dir);
	/* fall through to 10... */
    case 10:
	WCFREE(PUSER_INFO_10, usri10_full_name);
	WCFREE(PUSER_INFO_10, usri10_usr_comment);
	WCFREE(PUSER_INFO_10, usri10_comment);
	WCFREE(PUSER_INFO_10, usri10_name);
	break;
    case 20:
	WCFREE(PUSER_INFO_20, usri20_comment);
	WCFREE(PUSER_INFO_20, usri20_full_name);
	WCFREE(PUSER_INFO_20, usri20_name);
	break;
    case 1003:
	/* need to put a value in (can't rely on Get) */
	WCFREE(PUSER_INFO_1003, usri1003_password);
	break;
    case 1005:
	break;
    case 1006:
	WCFREE(PUSER_INFO_1006, usri1006_home_dir);
	break;
    case 1007:
	WCFREE(PUSER_INFO_1007, usri1007_comment);
    case 1008:
	break;
    case 1009:
	WCFREE(PUSER_INFO_1009, usri1009_script_path);
	break;
    case 1010:
	break;
    case 1011:
	WCFREE(PUSER_INFO_1011, usri1011_full_name);
	break;
    case 1012:
	WCFREE(PUSER_INFO_1012, usri1012_usr_comment);
	break;
    case 1013:
	WCFREE(PUSER_INFO_1013, usri1013_parms);
	break;
    case 1014:
	WCFREE(PUSER_INFO_1014, usri1014_workstations);
	break;
    case 1017:
	break;
    case 1018:
	break;
    case 1020:
	PBFREE(PUSER_INFO_1020, usri1020_logon_hours);
	break;
    case 1023:
	WCFREE(PUSER_INFO_1023, usri1023_logon_server);
	break;
    case 1024:
	break;
    case 1025:
	break;
    case 1051:
	break;
    case 1052:
	WCFREE(PUSER_INFO_1052, usri1052_profile);
	break;
    case 1053:
	WCFREE(PUSER_INFO_1053, usri1053_home_dir_drive);
	break;
    case 21:
    default:
	croak("unhandled level in free     CODE\n");
    }
}

LPBYTE *
allocGroupInfoX(int level, HV *hv)
{
    LPBYTE	*uiX = NULL;
    SV		**svPtr;
    dTHX;
    
    switch (level) {
    case 2:
	uiX_INIT(GROUP_INFO_2);
	HV_GET_IV(PGROUP_INFO_2, grpi2_attributes,    "attributes");
	HV_GET_IV(PGROUP_INFO_2, grpi2_group_id,        "group_id");
	/* fall through to 1 */
    case 1:
	uiX_INIT(GROUP_INFO_1);
	HV_GET_PV(PGROUP_INFO_1, grpi1_comment,     "comment");
	/* fall through to 0 */
    case 0:
	uiX_INIT(GROUP_INFO_0);
	HV_GET_PV(PGROUP_INFO_0, grpi0_name,            "name");
	break;
    case 1002:
	uiX_INIT(GROUP_INFO_1002);
	HV_GET_PV(PGROUP_INFO_1002, grpi1002_comment,    "comment");
	break;
    case 1005:
	uiX_INIT(GROUP_INFO_1005);
	HV_GET_IV(PGROUP_INFO_1005, grpi1005_attributes,    "attributes");
	break;
    default:
	break;
    }
    
    return uiX;
}

void
freeGroupInfoX(int level, LPBYTE *uiX)
{
    switch (level) {
    case 2:
	/* fall through to 1 */
    case 1:
	WCFREE(PGROUP_INFO_1, grpi1_comment);
	/* fall through to 0 */
    case 0:
	WCFREE(PGROUP_INFO_0, grpi0_name);
	break;
    case 1002:
	WCFREE(PGROUP_INFO_1002, grpi1002_comment);
	break;
    case 1005:
	break;
    default:
	break;
    }
}

int
WCTMB(LPWSTR lpwStr, LPSTR lpStr, int size)
{
    *lpStr = '\0';
    return WideCharToMultiByte(CP_ACP, 0, lpwStr, -1, lpStr, size,
			       NULL, NULL);
}

/* The following MACROs assume that the following are in scope
 * hv      - HV*, the hashRef into/from which information is placed/extracted
 * sv      - temporary SV* for intermediate SV * values
 * uiX     - LPBYTE alloc'ed appropriate to CAST
 * tmpBuf  - char * for temporary string values
 */

#define HV_STORE_PV(CAST, field, name) \
    STMT_START {							\
	WCTMB(((CAST)uiX)->field, tmpBuf, sizeof(tmpBuf));		\
	sv = newSVpv(tmpBuf, (I32)strlen(tmpBuf));			\
	hv_store((HV*)hv, name, (I32)strlen(name), sv, 0);		\
    } STMT_END

#define HV_STORE_IV(CAST, field, name) \
    STMT_START {							\
	sv = newSViv(((CAST)uiX)->field);				\
	hv_store((HV*)hv, name, (I32)strlen(name), sv, 0);		\
    } STMT_END

#define HV_STORE_AV(CAST, field, name, n) \
    STMT_START {							\
	int i = 0;							\
	AV *av;								\
	av = newAV();							\
	while (i < n) {							\
	    sv = newSViv((BYTE)(((CAST)uiX)->field)[i++]);		\
	    av_push(av, sv);						\
	}								\
	hv_store((HV*)hv, name, (I32)strlen(name), newRV_noinc((SV*)av), 0);	\
    } STMT_END

void
fillUserHash(HV *hv, int level, LPBYTE *uiX)
{
    SV *sv;
    char tmpBuf[UNLEN+1];
    dTHX;
    
    switch (level) {
    case 3:
    case 4:
    if( 3 == level )
    {
        HV_STORE_IV(PUSER_INFO_3, usri3_password_expired,    "passwordExpired");
        HV_STORE_PV(PUSER_INFO_3, usri3_home_dir_drive,      "homeDirDrive");
        HV_STORE_PV(PUSER_INFO_3, usri3_profile,             "profile");
        HV_STORE_IV(PUSER_INFO_3, usri3_primary_group_id,    "primaryGroupId");
        HV_STORE_IV(PUSER_INFO_3, usri3_user_id,             "userId");
    }
    else
    {
        LPTSTR sStringSid = NULL;
        if( ConvertSidToStringSidA( ((PMY_USER_INFO_4)uiX)->usri4_user_sid, &sStringSid ) )
        {
            sv = newSVpv( sStringSid, (I32)(strlen(sStringSid)) );
            hv_store( hv, "userSid", (I32)(strlen("userSid")), sv, 0 );
            LocalFree(sStringSid);
        }
        HV_STORE_IV(PMY_USER_INFO_4, usri4_password_expired, "passwordExpired");
        HV_STORE_PV(PMY_USER_INFO_4, usri4_home_dir_drive,   "homeDirDrive");
        HV_STORE_PV(PMY_USER_INFO_4, usri4_profile,          "profile");
        HV_STORE_IV(PMY_USER_INFO_4, usri4_primary_group_id, "primaryGroupId");
    }
	/* fall through to 2... */
    case 2:
	HV_STORE_IV(PUSER_INFO_2, usri2_code_page,           "codePage");
	HV_STORE_IV(PUSER_INFO_2, usri2_country_code,        "countryCode");
	HV_STORE_PV(PUSER_INFO_2, usri2_logon_server,        "logonServer");
	HV_STORE_IV(PUSER_INFO_2, usri2_num_logons,          "numLogons");
	HV_STORE_IV(PUSER_INFO_2, usri2_bad_pw_count,        "badPwCount");
	HV_STORE_AV(PUSER_INFO_2, usri2_logon_hours,         "logonHours", 21);
	HV_STORE_IV(PUSER_INFO_2, usri2_units_per_week,      "unitsPerWeek");
	HV_STORE_IV(PUSER_INFO_2, usri2_max_storage,         "maxStorage");
	HV_STORE_IV(PUSER_INFO_2, usri2_acct_expires,        "acctExpires");
	HV_STORE_IV(PUSER_INFO_2, usri2_last_logoff,         "lastLogoff");
	HV_STORE_IV(PUSER_INFO_2, usri2_last_logon,          "lastLogon");
	HV_STORE_PV(PUSER_INFO_2, usri2_workstations,        "workstations");
	HV_STORE_PV(PUSER_INFO_2, usri2_parms,               "parms");
	HV_STORE_PV(PUSER_INFO_2, usri2_usr_comment,         "usrComment");
	HV_STORE_PV(PUSER_INFO_2, usri2_full_name,           "fullName");
	HV_STORE_IV(PUSER_INFO_2, usri2_auth_flags,          "authFlags");
	/* fall through to 1... */
    case 1:
	HV_STORE_PV(PUSER_INFO_1, usri1_script_path,         "scriptPath");
	HV_STORE_IV(PUSER_INFO_1, usri1_flags,               "flags");
	HV_STORE_PV(PUSER_INFO_1, usri1_comment,             "comment");
	HV_STORE_PV(PUSER_INFO_1, usri1_home_dir,            "homeDir");
	HV_STORE_IV(PUSER_INFO_1, usri1_priv,                "priv");
	HV_STORE_IV(PUSER_INFO_1, usri1_password_age,        "passwordAge");
	HV_STORE_PV(PUSER_INFO_1, usri1_password,            "password");
	/* fall through to 0... */
    case 0:
	HV_STORE_PV(PUSER_INFO_0, usri0_name,                "name");
	break;
    case 11:
	HV_STORE_IV(PUSER_INFO_11, usri11_code_page,         "codePage");
	HV_STORE_AV(PUSER_INFO_11, usri11_logon_hours,       "logonHours", 21);
	HV_STORE_IV(PUSER_INFO_11, usri11_units_per_week,    "unitsPerWeek");
	HV_STORE_IV(PUSER_INFO_11, usri11_max_storage,       "maxStorage");
	HV_STORE_PV(PUSER_INFO_11, usri11_workstations,      "workstations");
	HV_STORE_IV(PUSER_INFO_11, usri11_country_code,      "countryCode");
	HV_STORE_PV(PUSER_INFO_11, usri11_logon_server,      "logonServer");
	HV_STORE_IV(PUSER_INFO_11, usri11_num_logons,        "numLogons");
	HV_STORE_IV(PUSER_INFO_11, usri11_bad_pw_count,      "badPwCount");
	HV_STORE_IV(PUSER_INFO_11, usri11_last_logoff,       "lastLogoff");
	HV_STORE_IV(PUSER_INFO_11, usri11_last_logon,        "lastLogon");
	HV_STORE_PV(PUSER_INFO_11, usri11_parms,             "parms");
	HV_STORE_PV(PUSER_INFO_11, usri11_home_dir,          "homeDir");
	HV_STORE_IV(PUSER_INFO_11, usri11_password_age,      "passwordAge");
	HV_STORE_IV(PUSER_INFO_11, usri11_auth_flags,        "authFlags");
	HV_STORE_IV(PUSER_INFO_11, usri11_priv,              "priv");
	/* fall through to 10... */
    case 10:
	HV_STORE_PV(PUSER_INFO_10, usri10_full_name,         "fullName");
	HV_STORE_PV(PUSER_INFO_10, usri10_usr_comment,       "usrComment");
	HV_STORE_PV(PUSER_INFO_10, usri10_comment,           "comment");
	HV_STORE_PV(PUSER_INFO_10, usri10_name,              "name");
	break;
    case 20:
	HV_STORE_IV(PUSER_INFO_20, usri20_user_id,           "userId");
	HV_STORE_IV(PUSER_INFO_20, usri20_flags,             "flags");
	HV_STORE_PV(PUSER_INFO_20, usri20_comment,           "comment");
	HV_STORE_PV(PUSER_INFO_20, usri20_full_name,         "fullName");
	HV_STORE_PV(PUSER_INFO_20, usri20_name,              "name");
	break;
    case 21:
	HV_STORE_AV(PUSER_INFO_21, usri21_password,          "password", ENCRYPTED_PWLEN);
    break;
    case 22:
	HV_STORE_PV(PUSER_INFO_22, usri22_name,              "name");
	HV_STORE_AV(PUSER_INFO_22, usri22_password,          "password", ENCRYPTED_PWLEN);
	HV_STORE_IV(PUSER_INFO_22, usri22_password_age,      "passwordAge");
	HV_STORE_IV(PUSER_INFO_22, usri22_priv,              "priv");
	HV_STORE_PV(PUSER_INFO_22, usri22_home_dir,          "homeDir");
	HV_STORE_PV(PUSER_INFO_22, usri22_comment,           "comment");
	HV_STORE_IV(PUSER_INFO_22, usri22_flags,             "flags");
	HV_STORE_PV(PUSER_INFO_22, usri22_script_path,       "scriptPath");
	HV_STORE_IV(PUSER_INFO_22, usri22_auth_flags,        "authFlags");
	HV_STORE_PV(PUSER_INFO_22, usri22_full_name,         "fullName");
	HV_STORE_PV(PUSER_INFO_22, usri22_usr_comment,       "usrComment");
	HV_STORE_PV(PUSER_INFO_22, usri22_parms,             "parms");
	HV_STORE_PV(PUSER_INFO_22, usri22_workstations,      "workstations");
	HV_STORE_IV(PUSER_INFO_22, usri22_last_logon,        "lastLogon");
	HV_STORE_IV(PUSER_INFO_22, usri22_last_logoff,       "lastLogoff");
	HV_STORE_IV(PUSER_INFO_22, usri22_acct_expires,      "acctExpires");
	HV_STORE_IV(PUSER_INFO_22, usri22_max_storage,       "maxStorage");
	HV_STORE_IV(PUSER_INFO_22, usri22_units_per_week,    "unitsPerWeek");
	HV_STORE_AV(PUSER_INFO_22, usri22_logon_hours,       "logonHours", 21);
	HV_STORE_IV(PUSER_INFO_22, usri22_bad_pw_count,      "badPwCount");
	HV_STORE_IV(PUSER_INFO_22, usri22_num_logons,        "numLogons");
	HV_STORE_PV(PUSER_INFO_22, usri22_logon_server,      "logonServer");
	HV_STORE_IV(PUSER_INFO_22, usri22_country_code,      "countryCode");
	HV_STORE_IV(PUSER_INFO_22, usri22_code_page,         "codePage");
    break;
    case 23:
    {
        LPTSTR sStringSid = NULL;
        if( ConvertSidToStringSidA( ((PMY_USER_INFO_23)uiX)->usri23_user_sid, &sStringSid ) )
        {
            sv = newSVpv( sStringSid, (I32)(strlen(sStringSid)) );
            hv_store( hv, "userSid", (I32)(strlen("userSid")), sv, 0 );
            LocalFree(sStringSid);
        }
    }
	HV_STORE_IV(PMY_USER_INFO_23, usri23_flags,          "flags");
	HV_STORE_PV(PMY_USER_INFO_23, usri23_comment,        "comment");
	HV_STORE_PV(PMY_USER_INFO_23, usri23_full_name,      "fullName");
	HV_STORE_PV(PMY_USER_INFO_23, usri23_name,           "name");
	break;
    case 1003:
    case 1005:
    case 1006:
    case 1007:
    case 1008:
    case 1009:
    case 1010:
    case 1011:
    case 1012:
    case 1013:
    case 1014:
    case 1017:
    case 1018:
    case 1020:
    case 1023:
    case 1024:
    case 1025:
    case 1051:
    case 1052:
    case 1053:
    default:
	croak("fillUserHash: Level %d not implemented!\n", level);
	break;
    }
}

void
fillGroupHash(HV *hv, int level, LPBYTE *uiX)
{
    SV *sv;
    char tmpBuf[UNLEN+1];
    dTHX;
    
    switch (level) {
	case 3:
	case 2:
    if( 2 == level )
    {
        HV_STORE_IV(PGROUP_INFO_2, grpi2_group_id,	 "groupId");
        HV_STORE_IV(PGROUP_INFO_2, grpi2_attributes, "attributes");
    }
    else
    {
        LPTSTR sStringSid = NULL;
        if( ConvertSidToStringSidA( ((PMY_GROUP_INFO_3)uiX)->grpi3_group_sid, &sStringSid ) )
        {
            sv = newSVpv( sStringSid, (I32)(strlen(sStringSid)) );
            hv_store( hv, "groupSid", (I32)(strlen("groupSid")), sv, 0 );
            LocalFree(sStringSid);
        }
        HV_STORE_IV(PMY_GROUP_INFO_3, grpi3_attributes, "attributes");
    }
	
	/* fall through to 1 */
    case 1:
	HV_STORE_PV(PGROUP_INFO_1, grpi1_comment,    "comment");
	/* fall through to 0 */
    case 0:
	HV_STORE_PV(PGROUP_INFO_0, grpi0_name,        "name");
	break;
    case 1002:
    case 1005:
    default:
	croak("fillGroupHash: Level %d not implemented!\n", level);
    }
}

LPBYTE *
allocLocalGroupInfoX(int level, HV *hv)
{
    LPBYTE	*uiX = NULL;
    SV		**svPtr;
    dTHX;
    
    switch (level) {
    case 1:
	uiX_INIT(LOCALGROUP_INFO_1);
	HV_GET_PV(PLOCALGROUP_INFO_1, lgrpi1_comment,        "comment");
	/* fall through to 0 */
    case 0:
	uiX_INIT(LOCALGROUP_INFO_0);
	HV_GET_PV(PLOCALGROUP_INFO_0, lgrpi0_name,            "name");
	break;
    case 1002:
	uiX_INIT(LOCALGROUP_INFO_1002);
	HV_GET_PV(PLOCALGROUP_INFO_1002, lgrpi1002_comment,    "comment");
	break;
    default:
	break;
    }
    
    return uiX;
}

void
fillLocalGroupHash(HV *hv, int level, LPBYTE *uiX)
{
    SV *sv;
    char tmpBuf[UNLEN+1];
    dTHX;
    
    switch (level) {
    case 1:
	HV_STORE_PV(PLOCALGROUP_INFO_1, lgrpi1_comment, "comment");
	/* fall through to 0 */
    case 0:
	HV_STORE_PV(PLOCALGROUP_INFO_0, lgrpi0_name,        "name");
	break;
    case 1002:
	HV_STORE_PV(PLOCALGROUP_INFO_1002, lgrpi1002_comment,    "comment");
	break;
    default:
	croak("fillLocalGroupHash: Level %d not implemented!\n", level);
    }
}

void
freeLocalGroupInfoX(int level, LPBYTE *uiX)
{
    dTHX;
    switch (level) {
    case 1:
	WCFREE(PLOCALGROUP_INFO_1, lgrpi1_comment);
	/* fall through to 0 */
    case 0:
	WCFREE(PLOCALGROUP_INFO_0, lgrpi0_name);
	break;
    case 1002:
	WCFREE(PLOCALGROUP_INFO_1002, lgrpi1002_comment);
	break;
    default:
	break;
    }
    Safefree(uiX);
}

MODULE = Win32API::Net        PACKAGE = Win32API::Net        PREFIX = Win32API
PROTOTYPES: ENABLE

double
constant(name, arg)
    char *name;
    int arg;

int
UserAdd(server, level, hash, fie)
    char *server;
    int    level;
    SV        *hash;
    int    fie;
PROTOTYPE: $$$$
CODE:
    {
	LPBYTE *uiX = NULL;
	DWORD  error;
	LPWSTR lpwServer = MBTWC(server);
	DWORD lastError = 0;

	if (!(hash && SvROK(hash) &&
	     (hash = SvRV(hash)) && SvTYPE(hash) == SVt_PVHV))
	    croak("Third argument to UserAdd() must be a hash reference,");
	
	uiX = allocUserInfoX(level, (HV*)hash);
	
	lastError = NetUserAdd(lpwServer, level, (LPBYTE)uiX, &error);
	fie = error;
	RETVAL = (lastError == NERR_Success);
	
	freeUserInfoX(uiX, level);
	freeWideName(lpwServer);
    }
OUTPUT:
    fie
    RETVAL

int
UserChangePassword(server, user, oldPassword, newPassword)
    char *server;
    char *user;
    char *oldPassword;
    char *newPassword;
PROTOTYPE: $$$$
CODE:
    {
	LPWSTR lpwServer = MBTWC(server);
	LPWSTR lpwUser = MBTWC(user);
	LPWSTR lpwOldPassword = MBTWC(oldPassword);
	LPWSTR lpwNewPassword = MBTWC(newPassword);
	DWORD lastError = 0;

	lastError = NetUserChangePassword(lpwServer, lpwUser, lpwOldPassword,
					  lpwNewPassword);

	RETVAL = (lastError == NERR_Success);

	freeWideName(lpwNewPassword);
	freeWideName(lpwOldPassword);
	freeWideName(lpwUser);
	freeWideName(lpwServer);
    }
OUTPUT:
    RETVAL

int
UserDel(server, user)
    char *server;
    char *user;
PROTOTYPE: $$
CODE:
    {
	LPWSTR lpwServer = MBTWC(server);
	LPWSTR lpwUser = MBTWC(user);
	DWORD lastError = 0;

	lastError = NetUserDel(lpwServer, lpwUser);

	RETVAL = (lastError == NERR_Success);

	freeWideName(lpwUser);
	freeWideName(lpwServer);
    }
OUTPUT:
    RETVAL

int
UserEnum(server, array, ...)
    char    *server
    SV        *array
PROTOTYPE: $$;$
PREINIT:
    int    filter = FILTER_NORMAL_ACCOUNT;
CODE:
    {
	LPWSTR lpwServer = MBTWC(server);
	PUSER_INFO_0 pwzUsers = NULL;
	DWORD entriesRead = 0, totalEntries = 0;
        DWORD_PTR resumeHandle = 0;
	DWORD index;
	DWORD lastError = 0;
	char tmpBuf[UNLEN+1];

	if (items > 2)    filter = (int)SvIV(ST(2));
	
	if (!(array && SvROK(array) &&
	     (array = SvRV(array)) && SvTYPE(array) == SVt_PVAV))
	    croak("Second argument to UserEnum() must be an array reference,");

	av_clear((AV*)array);

	do    {
	    lastError = NetUserEnum(lpwServer, 0, filter, (LPBYTE*)&pwzUsers,
				    PREFLEN, &entriesRead, &totalEntries,
				    &resumeHandle);

	    if (lastError != ERROR_MORE_DATA && lastError != NERR_Success)
		break;			/* we have a failure */

	    if (entriesRead == 0)
		break;			/* 1st pass got them all */

	    for (index = 0; index < entriesRead; ++index) {
		WCTMB(pwzUsers[index].usri0_name,(LPSTR)tmpBuf,sizeof(tmpBuf));
		av_push((AV*)array, newSVpv(tmpBuf, 0));
	    }
	    NetApiBufferFree(pwzUsers);
	} while (entriesRead != totalEntries && resumeHandle != 0);

	freeWideName(lpwServer);

	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    RETVAL

int
UserGetGroups(server, user, array)
    char    *server
    char    *user
    SV        *array;
PROTOTYPE: $$$
CODE:
    {
	LPWSTR lpwServer = MBTWC(server);
	LPWSTR lpwUser = MBTWC(user);
	PGROUP_INFO_0 pwzGroups;
	DWORD entriesRead = 0, totalEntries = 0;
        DWORD index;
	int len = PREFLEN;
	DWORD lastError = 0;
	char tmpBuf[UNLEN+1];

	if (!(array && SvROK(array) &&
	     (array = SvRV(array)) && SvTYPE(array) == SVt_PVAV))
	    croak("Third argument to UserGetGroups() must be an array reference,");

	av_clear((AV*)array);

	do {
	    lastError = NetUserGetGroups(lpwServer, lpwUser, 0,
					 (LPBYTE*)&pwzGroups, len,
					 &entriesRead,
					 &totalEntries);

	    if (lastError == ERROR_MORE_DATA) {
		len *= 2;
		NetApiBufferFree(pwzGroups);
	    }
	    else if (lastError != NERR_Success)
		 break; /* get out - something else is wrong! */
	} while (lastError == ERROR_MORE_DATA);

	if (lastError == NERR_Success) {
	    for (index = 0; index < entriesRead; index++) {
		WCTMB(pwzGroups[index].grpi0_name, tmpBuf, sizeof(tmpBuf));
		av_push((AV*)array, newSVpv(tmpBuf, 0));
	    }
	    NetApiBufferFree(pwzGroups);
	}

	freeWideName(lpwServer);
	freeWideName(lpwUser);

	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    RETVAL

int
UserGetInfo(server, user, level, hash)
    char    *server;
    char    *user;
    int    level;
    SV    *hash;
PROTOTYPE: $$$$
CODE:
    {
	LPBYTE *uiX = NULL;
	LPWSTR lpwServer, lpwUser;
	SV *sv;
	DWORD lastError = 0;

	if (!(hash && SvROK(hash) &&
	     (hash = SvRV(hash)) && SvTYPE(hash) == SVt_PVHV))
	    croak("Fourth argument to UserGetInfo() must be a hash reference,");

	lpwServer = MBTWC(server);
	lpwUser = MBTWC(user);

	hv_clear((HV*)hash);
	lastError = NetUserGetInfo(lpwServer, lpwUser, level, (LPBYTE*)&uiX);

	freeWideName(lpwServer);
	freeWideName(lpwUser);

	if (lastError == NERR_Success) {
	    fillUserHash((HV *)hash, level, uiX);
	    sv = newSVpv(user, (I32)strlen(user));
	    hv_store((HV*)hash, "name", 4, sv, 0);            
	    NetApiBufferFree(uiX);
	}

	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    RETVAL

int
UserGetLocalGroups(server, user, array, ...)
    char    *server
    char    *user
    SV        *array
PROTOTYPE: $$$;$
PREINIT:
    int flags = 0;
CODE:
    {
	LPWSTR lpwServer = MBTWC(server);
	LPWSTR lpwUser = MBTWC(user);
	LPLOCALGROUP_USERS_INFO_0 pwzLocalGroupUsers=NULL;
	DWORD entriesRead = 0, totalEntries = 0;
        DWORD index;
	int len = PREFLEN;
	char tmpBuf[UNLEN+1];
	DWORD lastError = 0;

	if (items > 3) flags = (int)SvIV(ST(3));
	
	if (!(array && SvROK(array) &&
	     (array = SvRV(array)) && (SvTYPE(array) == SVt_PVAV)))
	    croak("Third argument to UserGetLocalGroups() must be an array reference,");

	av_clear((AV*)array);

	do {
	    lastError = NetUserGetLocalGroups(lpwServer, lpwUser, 0, flags,
					      (LPBYTE*)&pwzLocalGroupUsers,
					      len, &entriesRead, &totalEntries);
	    /* this could fail is PREFLEN is not big enough... */
	    if (lastError == ERROR_MORE_DATA) {
		len *= 2;
		NetApiBufferFree(pwzLocalGroupUsers);
	    }
	    else if (lastError != NERR_Success)
		 break; /* don't know whats going on - get out */
	} while (lastError == ERROR_MORE_DATA);

	if (lastError == NERR_Success) {
	    for (index = 0; index < entriesRead; index++) {
		WCTMB(pwzLocalGroupUsers[index].lgrui0_name,
		      (LPSTR)tmpBuf, sizeof(tmpBuf));
		av_push((AV*)array, newSVpv(tmpBuf, 0));
	    }
	    NetApiBufferFree(pwzLocalGroupUsers);
	}

	freeWideName(lpwServer);
	freeWideName(lpwUser); 

	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    RETVAL

int
UserSetGroups(server, user, ...)
    char    *server;
    char    *user;
PROTOTYPE: $$@
CODE:
    {
	LPWSTR lpwServer = MBTWC(server);
	LPWSTR lpwUser = MBTWC(user);
	int i;
	DWORD lastError = 0;

	GROUP_INFO_0    *groups;

	Newz(0, groups, items, GROUP_INFO_0);

	for (i=2; i<items; i++) 
	    groups[i-2].grpi0_name = MBTWC(SvPV_nolen(ST(i)));

	lastError = NetUserSetGroups(lpwServer, lpwUser, 0,
				     (LPBYTE)groups, items-2);

	for (i=2; i<items; i++)
	    freeWideName(groups[i-2].grpi0_name);
	Safefree(groups);
	freeWideName(lpwServer);
	freeWideName(lpwUser);
	
	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    RETVAL

int
UserSetInfo(server, user, level, hash, fie)
    char    *server
    char    *user
    int    level
    SV    *hash
    int    fie
PROTOTYPE: $$$$$
CODE:
    {
	DWORD    error;
	LPWSTR lpwServer = MBTWC(server);
	LPWSTR lpwUser = MBTWC(user);
	LPBYTE *uiX = NULL;
	DWORD lastError = 0;

	if (!(hash && SvROK(hash) &&
	     (hash = SvRV(hash)) && SvTYPE(hash) == SVt_PVHV))
	    croak("Fourth argument to UserSetInfo() must be a hash reference,");

	uiX = allocUserInfoX(level, (HV*)hash);
	
	lastError = NetUserSetInfo(lpwServer, lpwUser, level,
				   (LPBYTE)uiX, &error);
	fie = error;

	RETVAL = (lastError == NERR_Success);

	freeUserInfoX(uiX, level);
	freeWideName(lpwServer);
	freeWideName(lpwUser);
    }
OUTPUT:
    fie
    RETVAL

int
GroupAdd(server, level, hash, fie)
    char    *server
    int    level
    SV        *hash
    int    fie
PROTOTYPE: $$$$
CODE:
    {
	DWORD    error;
	LPWSTR lpwServer = MBTWC(server);
	LPBYTE *giX;
	DWORD lastError = 0;

	if (!(hash && SvROK(hash) &&
	     (hash = SvRV(hash)) && SvTYPE(hash) == SVt_PVHV))
	    croak("Third argument to GroupAdd() must be a hash reference,");

	giX = allocGroupInfoX(level, (HV*)hash);
	lastError = NetGroupAdd(lpwServer, level, (LPBYTE)giX, &error);
	fie = error;

	freeGroupInfoX(level, giX);
	freeWideName(lpwServer);

	/*warn("lastError=%d\n", lastError);*/
	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    fie
    RETVAL
    
int
GroupAddUser(server, group, user)
    char    *server
    char    *group
    char    *user
PROTOTYPE: $$$
CODE:
    {
	LPWSTR lpwServer = MBTWC(server);
	LPWSTR lpwGroup = MBTWC(group);
	LPWSTR lpwUser = MBTWC(user);
	DWORD lastError = 0;

	lastError = NetGroupAddUser(lpwServer, lpwGroup, lpwUser);

	freeWideName(lpwUser);
	freeWideName(lpwGroup);
	freeWideName(lpwServer);

	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    RETVAL

int
GroupDel(server, group)
    char    *server
    char    *group
PROTOTYPE: $$
CODE:
    {
	LPWSTR lpwServer = MBTWC(server);
	LPWSTR lpwGroup = MBTWC(group);
	DWORD lastError = 0;

	lastError = NetGroupDel(lpwServer, lpwGroup);

	freeWideName(lpwGroup);
	freeWideName(lpwServer);

	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    RETVAL

int
GroupDelUser(server, group, user)
    char    *server
    char    *group
    char    *user
PROTOTYPE: $$$
CODE:
    {
	LPWSTR lpwServer = MBTWC(server);
	LPWSTR lpwGroup = MBTWC(group);
	LPWSTR lpwUser = MBTWC(user);
	DWORD lastError = 0;

	lastError = NetGroupDelUser(lpwServer, lpwGroup, lpwUser);

	freeWideName(lpwUser);
	freeWideName(lpwGroup);
	freeWideName(lpwServer);

	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    RETVAL

int
GroupEnum(server, array)
    char    *server
    SV        *array
PROTOTYPE: $$
CODE:
    {
	LPWSTR lpwServer = MBTWC(server);
	PGROUP_INFO_0 pwzGroups;
	DWORD entriesRead = 0, totalEntries = 0;
        DWORD_PTR resumeHandle = 0;
        DWORD index;
	DWORD lastError = 0;
	char tmpBuf[UNLEN+1];
	
	if (!(array && SvROK(array) &&
	     (array = SvRV(array)) && SvTYPE(array) == SVt_PVAV))
	    croak("Third argument to GroupEnum() must be a array reference,");

	av_clear((AV*)array);
	
	do    {
	    lastError = NetGroupEnum(lpwServer, 0, (LPBYTE*)&pwzGroups,
				     PREFLEN, &entriesRead, &totalEntries,
				     &resumeHandle);

	    if (lastError != ERROR_MORE_DATA &&
		 lastError != NERR_Success) break;

	    for (index = 0; index < entriesRead; ++index) {
		WCTMB(pwzGroups[index].grpi0_name,(LPSTR)tmpBuf,sizeof(tmpBuf));
		av_push((AV*)array, newSVpv(tmpBuf, 0));
	    }
	    NetApiBufferFree(pwzGroups);
	} while (resumeHandle != 0);

	freeWideName(lpwServer);

	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    RETVAL

int
GroupGetInfo(server, group, level, hash)
    char    *server
    char    *group
    int    level
    SV        *hash
PROTOTYPE: $$$$
CODE:
    {
	LPWSTR lpwServer = MBTWC(server);
	LPWSTR lpwGroup = MBTWC(group);
	LPBYTE *groupInfo = NULL;
	DWORD lastError = 0;
	
	if (!(hash && SvROK(hash) &&
	     (hash = SvRV(hash)) && SvTYPE(hash) == SVt_PVHV))
	    croak("Fourth argument to GroupGetInfo() must be a hash reference,");

	hv_clear((HV*)hash);
	
	lastError = NetGroupGetInfo(lpwServer, lpwGroup, level, (LPBYTE*)&groupInfo);

	if (lastError == NERR_Success)
	    fillGroupHash((HV*)hash, level, groupInfo);

	NetApiBufferFree(groupInfo);
	freeWideName(lpwGroup);
	freeWideName(lpwServer);
	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    RETVAL

int
GroupGetUsers(server, group, array)
    char    *server
    char    *group
    SV        *array
PROTOTYPE: $$$
CODE:
    {
	LPWSTR lpwServer = MBTWC(server);
	LPWSTR lpwGroup = MBTWC(group);
	PGROUP_USERS_INFO_0 pwzGroupUsers;
	DWORD entriesRead = 0, totalEntries = 0;
        DWORD_PTR resumeHandle = 0;
        DWORD index;
	DWORD lastError = 0;
	char tmpBuf[UNLEN+1];
	
	if (!(array && SvROK(array) &&
	     (array = SvRV(array)) && SvTYPE(array) == SVt_PVAV))
	    croak("Third argument to GroupGetUsers() must be an array reference,");

	av_clear((AV*)array);
	
	do {
	    lastError = NetGroupGetUsers(lpwServer, lpwGroup, 0,
					 (LPBYTE*)&pwzGroupUsers, PREFLEN,
					 &entriesRead, &totalEntries,
					 &resumeHandle);

	    if (lastError != ERROR_MORE_DATA &&
		 lastError != NERR_Success) break;
		
	    for (index = 0; index < entriesRead; index++) {
		WCTMB(pwzGroupUsers[index].grui0_name, (LPSTR)tmpBuf,
		      sizeof(tmpBuf));
		if (entriesRead == 1 && (strcmp(tmpBuf, "None") == 0)) break;
		av_push((AV*)array, newSVpv(tmpBuf, 0));
	    }
	    NetApiBufferFree(pwzGroupUsers);
	} while (resumeHandle != 0);
	
	freeWideName(lpwServer);
	freeWideName(lpwGroup);

	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    RETVAL

int
GroupSetInfo(server, group, level, hash, fie)
    char    *server
    char    *group
    int    level
    SV        *hash
    int    fie
PROTOTYPE: $$$$$
CODE:
    {
	DWORD    error;
	LPWSTR lpwServer = MBTWC(server);
	LPWSTR lpwGroup = MBTWC(group);
	LPBYTE *giX;
	DWORD lastError = 0;

	if (!(hash && SvROK(hash) &&
	     (hash = SvRV(hash)) && SvTYPE(hash) == SVt_PVHV))
	    croak("Fourth argument to GroupsetInfo() must be a hash reference,");

	giX = allocGroupInfoX(level, (HV*)hash);
	lastError = NetGroupSetInfo(lpwServer, lpwGroup, level,
				    (LPBYTE)giX, &error);

	fie = error;
	freeGroupInfoX(level, giX);
	freeWideName(lpwGroup);
	freeWideName(lpwServer);

	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    fie
    RETVAL

int
GroupSetUsers(server, group, array)
    char    *server
    char    *group
    SV        *array
PROTOTYPE: $$$
CODE:
    {
	LPWSTR lpwServer = MBTWC(server);
	LPWSTR lpwGroup = MBTWC(group);
	int    i, numUsers;
	STRLEN pl_na;
	GROUP_USERS_INFO_0    *users;
	SV        **svTmp;
	DWORD lastError = 0;
	
	if (!(array && SvROK(array) &&
	     (array = SvRV(array)) && SvTYPE(array) == SVt_PVAV))
	    croak("Third argument to GroupSetUsers() must be an array reference,");

	numUsers = av_len((AV*)array)+1;

	Newz(0, users, numUsers, GROUP_USERS_INFO_0);

	for (i=0; i<numUsers; i++) {
	    svTmp = av_fetch((AV*)array, i, 0);
	    if (*svTmp)
	    users[i].grui0_name = MBTWC(SvPV(*svTmp, pl_na));
	}

	lastError = NetGroupSetUsers(lpwServer, lpwGroup, 0,
				   (LPBYTE)users, numUsers);

	for (i=0; i<numUsers; i++) freeWideName(users[i].grui0_name);
	freeWideName(lpwGroup);
	freeWideName(lpwServer);

	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    RETVAL

int
LocalGroupAdd(server, level, hash, fie)
    char    *server
    int    level
    SV        *hash
    int    fie
PROTOTYPE: $$$$
PREINIT:
    LPBYTE *giX;
CODE:
    {
	DWORD error;
	DWORD lastError = 0;

    LPWSTR lpwServer = MBTWC(server);

	if (!(hash && SvROK(hash) &&
	     (hash = SvRV(hash)) && SvTYPE(hash) == SVt_PVHV))
	    croak("Third argument to LocalGroupAdd() must be a hash reference,");

	giX = allocLocalGroupInfoX(level, (HV*)hash);
	lastError = NetLocalGroupAdd(lpwServer, level, (LPBYTE)giX, &error);
	fie = error;

	freeLocalGroupInfoX(level, giX);
	freeWideName(lpwServer);

	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    fie
    RETVAL
    
int
LocalGroupAddMembers(server, group, array)
    char    *server
    char    *group
    SV        *array
PROTOTYPE: $$$
CODE:
    {
	LPWSTR lpwServer = MBTWC(server);
	LPWSTR lpwGroup = MBTWC(group);
	LOCALGROUP_MEMBERS_INFO_3    *members;
	int i, len;
	STRLEN pl_na;
	SV    **svTmp;
	DWORD lastError = 0;

	if (!(array && SvROK(array) &&
	     (array = SvRV(array)) && SvTYPE(array) == SVt_PVAV))
	    croak("Third argument to LocalGroupAddMembers() must be an array reference,");

	len = av_len((AV*)array)+1;

	Newz(0, members, len, LOCALGROUP_MEMBERS_INFO_3);

	for (i=0; i<len; i++) {
	    svTmp = av_fetch((AV*)array, i, 0);
	    if (*svTmp)
		members[i].lgrmi3_domainandname = MBTWC(SvPV(*svTmp, pl_na));
	}
	
	lastError = NetLocalGroupAddMembers(lpwServer, lpwGroup, 3,
					    (LPBYTE)members, len);

	for (i=0; i<len; i++) freeWideName(members[i].lgrmi3_domainandname);
	freeWideName(lpwGroup);
	freeWideName(lpwServer);
	Safefree(members);

	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    RETVAL

int
LocalGroupDel(server, group)
    char    *server
    char    *group
PROTOTYPE: $$
CODE:
    {
	LPWSTR lpwServer = MBTWC(server);
	LPWSTR lpwGroup = MBTWC(group);
	DWORD lastError = 0;

	lastError = NetLocalGroupDel(lpwServer, lpwGroup);

	freeWideName(lpwGroup);
	freeWideName(lpwServer);

	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    RETVAL

int
LocalGroupDelMembers(server, group, array)
    char    *server
    char    *group
    SV        *array
PROTOTYPE: $$$
CODE:
    {
	LPWSTR lpwServer = MBTWC(server);
	LPWSTR lpwGroup = MBTWC(group);
	LOCALGROUP_MEMBERS_INFO_3    *members;
	int totalEntries = items-2;
	int i, len;
	STRLEN pl_na;
	SV    **svTmp;
	DWORD lastError = 0;

	if (!(array && SvROK(array) &&
	     (array = SvRV(array)) && SvTYPE(array) == SVt_PVAV))
	    croak("Third argument to LocalGroupDelMembers() must be an array reference,");

	len = av_len((AV*)array)+1;
	
	Newz(0, members, len, LOCALGROUP_MEMBERS_INFO_3);

	for (i=0; i<len; i++) {
	    svTmp = av_fetch((AV*)array, i, 0);
	    if (*svTmp)
		members[i].lgrmi3_domainandname = MBTWC(SvPV(*svTmp, pl_na));
	}
	
	lastError = NetLocalGroupDelMembers(lpwServer, lpwGroup, 3,
					    (LPBYTE)members, totalEntries);

	for (i; i<len; i++) freeWideName(members[i].lgrmi3_domainandname);
	freeWideName(lpwGroup);
	freeWideName(lpwServer);
	Safefree(members);

	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    RETVAL

int
LocalGroupEnum(server, array)
    char    *server
    SV        *array
PROTOTYPE: $$
CODE:
    {
	LPWSTR lpwServer = MBTWC(server);
	PLOCALGROUP_INFO_0 pwzLocalGroups;
	DWORD entriesRead = 0, totalEntries = 0;
        DWORD_PTR resumeHandle = 0;
	DWORD index;
	DWORD lastError = 0;
	char tmpBuf[UNLEN+1];

	if (!(SvROK(array) && (array = SvRV(array))
	      && SvTYPE(array) == SVt_PVAV))
	    croak("Second argument to LocalGroupEnum() must be an array reference,");

	av_clear((AV*)array);
	
	do {
	    lastError = NetLocalGroupEnum(lpwServer, 0,
					  (LPBYTE*)&pwzLocalGroups,
					  PREFLEN, &entriesRead,
					  &totalEntries, &resumeHandle);

	    if (lastError != ERROR_MORE_DATA && lastError != NERR_Success)
		break;

	    for (index = 0; index < entriesRead; ++index) {
		WCTMB(pwzLocalGroups[index].lgrpi0_name,
		      (LPSTR)tmpBuf, sizeof(tmpBuf));
		if (entriesRead == 1 && (strcmp(tmpBuf, "None") == 0))
		    break;
		av_push((AV*)array, newSVpv(tmpBuf, 0));
	    }
	    NetApiBufferFree(pwzLocalGroups);
	} while (resumeHandle != 0);

	freeWideName(lpwServer);

	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    RETVAL

int
LocalGroupGetInfo(server, group, level, hash)
    char    *server
    char    *group
    int    level
    SV        *hash
PROTOTYPE: $$$$
CODE:
    {
	LPWSTR lpwServer = MBTWC(server);
	LPWSTR lpwGroup = MBTWC(group);
	LPBYTE *groupInfo = NULL;
	DWORD lastError = 0;
	
	if (!(hash && SvROK(hash) &&
	     (hash = SvRV(hash)) && SvTYPE(hash) == SVt_PVHV))
	    croak("Fourth argument to LocalGroupGetInfo() must be a hash reference,");

	hv_clear((HV*)hash);

	lastError = NetLocalGroupGetInfo(lpwServer, lpwGroup, level,
					 (LPBYTE*)&groupInfo);

	if (lastError == NERR_Success)
	    fillLocalGroupHash((HV*)hash, level, groupInfo);

	NetApiBufferFree(groupInfo);
	freeWideName(lpwGroup);
	freeWideName(lpwServer);
	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    RETVAL

int
LocalGroupGetMembers(server, group, array)
    char    *server
    char    *group
    SV        *array
PROTOTYPE: $$$
CODE:
    {
	LPWSTR lpwServer = MBTWC(server);
	LPWSTR lpwGroup = MBTWC(group);
	PLOCALGROUP_MEMBERS_INFO_1 pwzMembersInfo;
	DWORD entriesRead = 0, totalEntries = 0;
        DWORD_PTR resumeHandle = 0;
	DWORD index;
	DWORD lastError = 0;
	char tmpBuf[UNLEN+1];

	if (!(array && SvROK(array) &&
	     (array = SvRV(array)) && SvTYPE(array) == SVt_PVAV))
	    croak("Third argument to LocalGroupGetMembers() must be a array reference,");

	av_clear((AV*)array);
	
	do {
	    lastError = NetLocalGroupGetMembers(lpwServer, lpwGroup, 1,
						(LPBYTE*)&pwzMembersInfo,
						PREFLEN, &entriesRead,
						&totalEntries, &resumeHandle);

	    if (lastError != ERROR_MORE_DATA && lastError != NERR_Success)
		break;        /* we have a failure */
		
	    for (index = 0; index < entriesRead; index++) {
		WCTMB(pwzMembersInfo[index].lgrmi1_name,tmpBuf,sizeof(tmpBuf));
		av_push((AV*)array, newSVpv(tmpBuf, 0));
	    }
	    NetApiBufferFree(pwzMembersInfo);
	} while (resumeHandle != 0);
	
	freeWideName(lpwServer);
	freeWideName(lpwGroup);

	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    RETVAL

int
LocalGroupSetInfo(server, group, level, hash, fie)
    char    *server
    char    *group
    int    level
    SV        *hash
    int    fie
PROTOTYPE: $$$$$
CODE:
    {
	DWORD    error;
	LPWSTR lpwServer = MBTWC(server);
	LPWSTR lpwGroup = MBTWC(group);
	LPBYTE *lgiX;
	DWORD lastError = 0;

	if (!(hash && SvROK(hash) &&
	     (hash = SvRV(hash)) && SvTYPE(hash) == SVt_PVHV))
	    croak("Third argument to LocalGroupSetInfo() must be a hash reference,");

	lgiX = allocLocalGroupInfoX(level, (HV*)hash);

	lastError = NetLocalGroupSetInfo(lpwServer, lpwGroup, level,
				       (LPBYTE)lgiX, &error);
	fie = error;
	freeGroupInfoX(level, lgiX);
	freeWideName(lpwGroup);
	freeWideName(lpwServer);

	RETVAL = (lastError == NERR_Success);
    }
OUTPUT:
    fie
    RETVAL

int
GetDCName(server, domain, primaryDC)
    char *server
    char *domain
    char *primaryDC
PROTOTYPE: $$$
CODE:
    {
	LPWSTR lpwServer = MBTWC(server);
	LPWSTR lpwDomain = MBTWC(domain);
	LPWSTR lpwPrimaryDC = NULL;
	DWORD lastError = 0;
	char tmpBuf[UNLEN+1];

	lastError = NetGetDCName(lpwServer, lpwDomain, (LPBYTE *)&lpwPrimaryDC);

	RETVAL = (lastError == NERR_Success);
	
	WCTMB(lpwPrimaryDC, (LPSTR)tmpBuf, sizeof(tmpBuf));

	primaryDC = tmpBuf;
	
	NetApiBufferFree(lpwPrimaryDC);
	freeWideName(lpwServer);
	freeWideName(lpwDomain);
    }
OUTPUT:
    primaryDC
    RETVAL

