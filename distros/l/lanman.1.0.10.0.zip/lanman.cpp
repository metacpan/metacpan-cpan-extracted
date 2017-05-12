#define WIN32_LEAN_AND_MEAN


#ifndef __LANMAN_CPP
#define __LANMAN_CPP
#endif


#include <windows.h>
#include <lm.h>
#include <lmdfs.h>
#include <wtsapi32.h>
#include <ntsecapi.h>
#include <dsgetdc.h>


//#include "access.h"
#include "addloader.h"
//#include "alert.h"
#include "browse.h"
#include "dfs.h"
#include "domain.h"
#include "ds.h"
#include "eventlog.h"
#include "file.h"
#include "get.h"
#include "group.h"
//#include "handle.h"
#include "lanman.h"
#include "message.h"
#include "misc.h"
#include "plmisc.h"
#include "policy.h"
#include "repl.h"
#include "schedule.h"
#include "server.h"
#include "service.h"
#include "session.h"
#include "share.h"
//#include "stat.h"
#include "termserv.h"
#include "timeofd.h"
#include "wnetwork.h"
#include "workst.h"
#include "wstring.h"
#include "use.h"
#include "user.h"
#include "usererror.h"


///////////////////////////////////////////////////////////////////////////////
//
// defines
//
///////////////////////////////////////////////////////////////////////////////

// compares a string with a name and returns a the value of the string
#define RET_VAL_IF_EQUAL(value, name) if(!strcmp(#value, name))	return value;


///////////////////////////////////////////////////////////////////////////////
//
// globals
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// functions
//
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// constant function for exported definitions (section @EXPORT in *.pm)
//
// param:  name - constant name
//
// return: success - constant name as integer
//         failure - 0
//
///////////////////////////////////////////////////////////////////////////////

static long constant(PERL_CALL PSTR name)
{
	switch(*name) 
	{
		case 'A':
			RET_VAL_IF_EQUAL(ACCESS_ALL, name);
			RET_VAL_IF_EQUAL(ACCESS_ATRIB, name);
			RET_VAL_IF_EQUAL(ACCESS_CREATE, name);
			RET_VAL_IF_EQUAL(ACCESS_DELETE, name);
			RET_VAL_IF_EQUAL(ACCESS_EXEC, name);
			RET_VAL_IF_EQUAL(ACCESS_PERM, name);
			RET_VAL_IF_EQUAL(ACCESS_READ, name);
			RET_VAL_IF_EQUAL(ACCESS_WRITE, name);

			RET_VAL_IF_EQUAL(AF_OP_ACCOUNTS, name);
			RET_VAL_IF_EQUAL(AF_OP_COMM, name);
			RET_VAL_IF_EQUAL(AF_OP_PRINT, name);
			RET_VAL_IF_EQUAL(AF_OP_SERVER, name);
	
			RET_VAL_IF_EQUAL(ALLOCATE_RESPONSE, name);

			RET_VAL_IF_EQUAL(AuditCategoryAccountLogon, name);
			RET_VAL_IF_EQUAL(AuditCategoryAccountManagement, name);
			RET_VAL_IF_EQUAL(AuditCategoryDetailedTracking, name);
			RET_VAL_IF_EQUAL(AuditCategoryDirectoryServiceAccess, name);
			RET_VAL_IF_EQUAL(AuditCategoryLogon, name);
			RET_VAL_IF_EQUAL(AuditCategoryObjectAccess, name);
			RET_VAL_IF_EQUAL(AuditCategoryPolicyChange, name);
			RET_VAL_IF_EQUAL(AuditCategoryPrivilegeUse, name);
			RET_VAL_IF_EQUAL(AuditCategorySystem, name);

			RET_VAL_IF_EQUAL(AUTH_REQ_ALLOW_ENC_TKT_IN_SKEY, name);
			RET_VAL_IF_EQUAL(AUTH_REQ_ALLOW_FORWARDABLE, name);
			RET_VAL_IF_EQUAL(AUTH_REQ_ALLOW_NOADDRESS, name);
			RET_VAL_IF_EQUAL(AUTH_REQ_ALLOW_POSTDATE, name);
			RET_VAL_IF_EQUAL(AUTH_REQ_ALLOW_PROXIABLE, name);
			RET_VAL_IF_EQUAL(AUTH_REQ_ALLOW_RENEWABLE, name);
			RET_VAL_IF_EQUAL(AUTH_REQ_ALLOW_VALIDATE, name);
			RET_VAL_IF_EQUAL(AUTH_REQ_OK_AS_DELEGATE, name);
			RET_VAL_IF_EQUAL(AUTH_REQ_PREAUTH_REQUIRED, name);
			RET_VAL_IF_EQUAL(AUTH_REQ_VALIDATE_CLIENT, name);
			break;

		case 'B':
			RET_VAL_IF_EQUAL(Batch, name);
			break;

		case 'C':
			RET_VAL_IF_EQUAL(CONNECT_CURRENT_MEDIA, name);
			RET_VAL_IF_EQUAL(CONNECT_DEFERRED, name);
			RET_VAL_IF_EQUAL(CONNECT_INTERACTIVE, name);
			RET_VAL_IF_EQUAL(CONNECT_LOCALDRIVE, name);
			RET_VAL_IF_EQUAL(CONNECT_NEED_DRIVE, name);
			RET_VAL_IF_EQUAL(CONNECT_PROMPT, name);
			RET_VAL_IF_EQUAL(CONNECT_REDIRECT, name);
			RET_VAL_IF_EQUAL(CONNECT_REFCOUNT, name);
			RET_VAL_IF_EQUAL(CONNECT_RESERVED, name);
			RET_VAL_IF_EQUAL(CONNECT_TEMPORARY, name);
			RET_VAL_IF_EQUAL(CONNECT_UPDATE_PROFILE, name);
			RET_VAL_IF_EQUAL(CONNECT_UPDATE_RECENT, name);

			RET_VAL_IF_EQUAL(CONNDLG_CONN_POINT, name);
			RET_VAL_IF_EQUAL(CONNDLG_HIDE_BOX, name);
			RET_VAL_IF_EQUAL(CONNDLG_NOT_PERSIST, name);
			RET_VAL_IF_EQUAL(CONNDLG_PERSIST, name);
			RET_VAL_IF_EQUAL(CONNDLG_RO_PATH, name);
			RET_VAL_IF_EQUAL(CONNDLG_USE_MRU, name);
			break;
			
		case 'D':
			RET_VAL_IF_EQUAL(DACL_SECURITY_INFORMATION, name);

			RET_VAL_IF_EQUAL(DISC_NO_FORCE, name);
			RET_VAL_IF_EQUAL(DISC_UPDATE_PROFILE, name);

			RET_VAL_IF_EQUAL(DEF_MAX_PWHIST, name);

			RET_VAL_IF_EQUAL(DFS_ADD_VOLUME, name);
			RET_VAL_IF_EQUAL(DFS_RESTORE_VOLUME, name);
			RET_VAL_IF_EQUAL(DFS_STORAGE_STATE_ACTIVE, name);
			RET_VAL_IF_EQUAL(DFS_STORAGE_STATE_OFFLINE, name);
			RET_VAL_IF_EQUAL(DFS_STORAGE_STATE_ONLINE, name);
			RET_VAL_IF_EQUAL(DFS_VOLUME_STATE_INCONSISTENT, name);
			RET_VAL_IF_EQUAL(DFS_VOLUME_STATE_OK, name);
			RET_VAL_IF_EQUAL(DFS_VOLUME_STATE_OFFLINE, name);
			RET_VAL_IF_EQUAL(DFS_VOLUME_STATE_ONLINE, name);
			break;

		case 'E':
			RET_VAL_IF_EQUAL(EVENTLOG_BACKWARDS_READ, name);
			RET_VAL_IF_EQUAL(EVENTLOG_FORWARDS_READ, name);
			RET_VAL_IF_EQUAL(EVENTLOG_SEEK_READ, name);
			RET_VAL_IF_EQUAL(EVENTLOG_SEQUENTIAL_READ, name);
	
			RET_VAL_IF_EQUAL(EVENTLOG_AUDIT_FAILURE, name);
			RET_VAL_IF_EQUAL(EVENTLOG_AUDIT_SUCCESS, name);
			RET_VAL_IF_EQUAL(EVENTLOG_ERROR_TYPE, name);
			RET_VAL_IF_EQUAL(EVENTLOG_INFORMATION_TYPE, name);
			RET_VAL_IF_EQUAL(EVENTLOG_WARNING_TYPE, name);
			break;

		case 'F':
			RET_VAL_IF_EQUAL(FILTER_INTERDOMAIN_TRUST_ACCOUNT, name);
			RET_VAL_IF_EQUAL(FILTER_NORMAL_ACCOUNT, name);
			RET_VAL_IF_EQUAL(FILTER_TEMP_DUPLICATE_ACCOUNT, name);
			// removed from the platform sdk file lmaccess.h
			//RET_VAL_IF_EQUAL(FILTER_PROXY_ACCOUNT, name); 
			RET_VAL_IF_EQUAL(FILTER_SERVER_TRUST_ACCOUNT, name);
			RET_VAL_IF_EQUAL(FILTER_WORKSTATION_TRUST_ACCOUNT, name);
			break;

		case 'G':
			RET_VAL_IF_EQUAL(GROUP_SECURITY_INFORMATION, name);
			break;
	
		case 'I':
			RET_VAL_IF_EQUAL(IDASYNC, name);					// WTS
			RET_VAL_IF_EQUAL(IDTIMEOUT, name);				// WTS
			
			RET_VAL_IF_EQUAL(Interactive, name);
			break;

		case 'J':
			RET_VAL_IF_EQUAL(JOB_ADD_CURRENT_DATE, name);
			RET_VAL_IF_EQUAL(JOB_EXEC_ERROR, name);
			RET_VAL_IF_EQUAL(JOB_INPUT_FLAGS, name);
			RET_VAL_IF_EQUAL(JOB_NONINTERACTIVE, name);
			RET_VAL_IF_EQUAL(JOB_OUTPUT_FLAGS, name);
			RET_VAL_IF_EQUAL(JOB_RUN_PERIODICALLY, name);
			RET_VAL_IF_EQUAL(JOB_RUNS_TODAY, name);
			break;

		case 'K':
			RET_VAL_IF_EQUAL(KERB_CHECKSUM_CRC32, name);
			RET_VAL_IF_EQUAL(KERB_CHECKSUM_DES_MAC, name);
			RET_VAL_IF_EQUAL(KERB_CHECKSUM_DES_MAC_MD5, name);
			RET_VAL_IF_EQUAL(KERB_CHECKSUM_HMAC_MD5, name);
			RET_VAL_IF_EQUAL(KERB_CHECKSUM_KRB_DES_MAC, name);
			RET_VAL_IF_EQUAL(KERB_CHECKSUM_LM, name);
			RET_VAL_IF_EQUAL(KERB_CHECKSUM_MD25, name);
			RET_VAL_IF_EQUAL(KERB_CHECKSUM_MD4, name);
			RET_VAL_IF_EQUAL(KERB_CHECKSUM_MD5, name);
			RET_VAL_IF_EQUAL(KERB_CHECKSUM_MD5_DES, name);
			RET_VAL_IF_EQUAL(KERB_CHECKSUM_MD5_HMAC, name);
			RET_VAL_IF_EQUAL(KERB_CHECKSUM_NONE, name);
			RET_VAL_IF_EQUAL(KERB_CHECKSUM_RC4_MD5, name);
			RET_VAL_IF_EQUAL(KERB_CHECKSUM_REAL_CRC32, name);
			RET_VAL_IF_EQUAL(KERB_CHECKSUM_SHA1, name);
			RET_VAL_IF_EQUAL(KERB_DECRYPT_FLAG_DEFAULT_KEY, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_DES_CBC_CRC, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_DES_CBC_MD4, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_DES_CBC_MD5, name);
			// removed from the platform sdk file ntsecapi.h
			//RET_VAL_IF_EQUAL(KERB_ETYPE_DES_CBC_MD5_EXP, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_DES_CBC_MD5_NT, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_DES_PLAIN, name);
			// removed from the platform sdk file ntsecapi.h
			//RET_VAL_IF_EQUAL(KERB_ETYPE_DES_PLAIN_EXP, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_DSA_SIGN, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_NULL, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_PKCS7_PUB, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_RC4_HMAC_NT, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_RC4_HMAC_NT_EXP, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_RC4_HMAC_OLD, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_RC4_HMAC_OLD_EXP, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_RC4_LM, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_RC4_MD4, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_RC4_PLAIN, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_RC4_PLAIN_EXP, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_RC4_PLAIN_OLD, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_RC4_PLAIN_OLD_EXP, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_RC4_PLAIN2, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_RC4_SHA, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_RSA_PRIV, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_RSA_PUB, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_RSA_PUB_MD5, name);
			RET_VAL_IF_EQUAL(KERB_ETYPE_RSA_PUB_SHA1, name);
			// removed from the platform sdk file ntsecapi.h
			//RET_VAL_IF_EQUAL(KERB_LOGON_EMAIL_NAMES, name);
			//RET_VAL_IF_EQUAL(KERB_LOGON_SUBUATH, name);
			//RET_VAL_IF_EQUAL(KERB_LOGON_UPDATE_STATISTICS, name);
			RET_VAL_IF_EQUAL(KERB_RETRIEVE_TICKET_DONT_USE_CACHE, name);
			RET_VAL_IF_EQUAL(KERB_RETRIEVE_TICKET_USE_CACHE_ONLY, name);
			RET_VAL_IF_EQUAL(KERB_WRAP_NO_ENCRYPT, name);
			RET_VAL_IF_EQUAL(KERBEROS_REVISION, name);
			RET_VAL_IF_EQUAL(KERBEROS_VERSION, name);

			RET_VAL_IF_EQUAL(KerbInteractiveLogon, name);
			RET_VAL_IF_EQUAL(KerbSmartCardLogon, name);

			RET_VAL_IF_EQUAL(KerbInteractiveProfile, name);
			RET_VAL_IF_EQUAL(KerbSmartCardProfile, name);
			break;

		case 'L':
			RET_VAL_IF_EQUAL(LG_INCLUDE_INDIRECT, name);
			RET_VAL_IF_EQUAL(LOGON_CACHED_ACCOUNT, name);
			RET_VAL_IF_EQUAL(LOGON_EXTRA_SIDS, name);
			RET_VAL_IF_EQUAL(LOGON_GRACE_LOGON, name);
			RET_VAL_IF_EQUAL(LOGON_GUEST, name);
			RET_VAL_IF_EQUAL(LOGON_NOENCRYPTION, name);
			RET_VAL_IF_EQUAL(LOGON_PROFILE_PATH_RETURNED, name);
			RET_VAL_IF_EQUAL(LOGON_RESOURCE_GROUPS, name);
			RET_VAL_IF_EQUAL(LOGON_SERVER_TRUST_ACCOUNT, name);
			RET_VAL_IF_EQUAL(LOGON_SUBAUTH_SESSION_KEY, name);
			RET_VAL_IF_EQUAL(LOGON_USED_LM_PASSWORD, name);
			RET_VAL_IF_EQUAL(LSA_MODE_INDIVIDUAL_ACCOUNTS, name);
			RET_VAL_IF_EQUAL(LSA_MODE_LOG_FULL, name);
			RET_VAL_IF_EQUAL(LSA_MODE_MANDATORY_ACCESS, name);
			RET_VAL_IF_EQUAL(LSA_MODE_PASSWORD_PROTECTED, name);
			break;

		case 'M':
			RET_VAL_IF_EQUAL(MAJOR_VERSION_MASK, name);

			RET_VAL_IF_EQUAL(MsV1_0InteractiveLogon, name);
			RET_VAL_IF_EQUAL(MsV1_0Lm20Logon, name);
			RET_VAL_IF_EQUAL(MsV1_0NetworkLogon, name);
			RET_VAL_IF_EQUAL(MsV1_0SubAuthLogon, name);

			RET_VAL_IF_EQUAL(MsV1_0InteractiveProfile, name);
			RET_VAL_IF_EQUAL(MsV1_0Lm20LogonProfile, name);
			RET_VAL_IF_EQUAL(MsV1_0SmartCardProfile, name);

			RET_VAL_IF_EQUAL(MsV1_0EnumerateUsers, name);
			RET_VAL_IF_EQUAL(MsV1_0CacheLogon, name);
			RET_VAL_IF_EQUAL(MsV1_0CacheLookup, name);
			RET_VAL_IF_EQUAL(MsV1_0ChangeCachedPassword, name);
			RET_VAL_IF_EQUAL(MsV1_0ChangePassword, name);
			RET_VAL_IF_EQUAL(MsV1_0DeriveCredential, name);
			RET_VAL_IF_EQUAL(MsV1_0GenericPassthrough, name);
			RET_VAL_IF_EQUAL(MsV1_0GetUserInfo, name);
			RET_VAL_IF_EQUAL(MsV1_0Lm20ChallengeRequest, name);
			RET_VAL_IF_EQUAL(MsV1_0Lm20GetChallengeResponse, name);
			RET_VAL_IF_EQUAL(MsV1_0ReLogonUsers, name);
			RET_VAL_IF_EQUAL(MsV1_0SubAuth, name);
	
			RET_VAL_IF_EQUAL(MSV1_0_ALLOW_SERVER_TRUST_ACCOUNT, name);
			RET_VAL_IF_EQUAL(MSV1_0_ALLOW_WORKSTATION_TRUST_ACCOUNT, name);
			RET_VAL_IF_EQUAL(MSV1_0_CHALLENGE_LENGTH, name);
			RET_VAL_IF_EQUAL(MSV1_0_CLEARTEXT_PASSWORD_ALLOWED, name);
			RET_VAL_IF_EQUAL(MSV1_0_CRED_LM_PRESENT, name);
			RET_VAL_IF_EQUAL(MSV1_0_CRED_NT_PRESENT, name);
			RET_VAL_IF_EQUAL(MSV1_0_CRED_VERSION, name);

			// oops, not longer supported
			RET_VAL_IF_EQUAL(MSV1_0_DERIVECRED_TYPE_SHA1, name);
			RET_VAL_IF_EQUAL(MSV1_0_DONT_TRY_GUEST_ACCOUNT, name);
			RET_VAL_IF_EQUAL(MSV1_0_LANMAN_SESSION_KEY_LENGTH, name);
			RET_VAL_IF_EQUAL(MSV1_0_MAX_AVL_SIZE, name);
			RET_VAL_IF_EQUAL(MSV1_0_MAX_NTLM3_LIFE, name);
			RET_VAL_IF_EQUAL(MSV1_0_MNS_LOGON, name);
			RET_VAL_IF_EQUAL(MSV1_0_NTLM3_INPUT_LENGTH, name);
			RET_VAL_IF_EQUAL(MSV1_0_NTLM3_OWF_LENGTH, name);
			RET_VAL_IF_EQUAL(MSV1_0_NTLM3_RESPONSE_LENGTH, name);
			RET_VAL_IF_EQUAL(MSV1_0_OWF_PASSWORD_LENGTH, name);
			RET_VAL_IF_EQUAL(MSV1_0_RETURN_PASSWORD_EXPIRY, name);
			RET_VAL_IF_EQUAL(MSV1_0_RETURN_PROFILE_PATH, name);
			RET_VAL_IF_EQUAL(MSV1_0_RETURN_USER_PARAMETERS, name);
			RET_VAL_IF_EQUAL(MSV1_0_SUBAUTHENTICATION_DLL, name);
			RET_VAL_IF_EQUAL(MSV1_0_SUBAUTHENTICATION_DLL_EX, name);
			RET_VAL_IF_EQUAL(MSV1_0_SUBAUTHENTICATION_DLL_SHIFT, name);
			RET_VAL_IF_EQUAL(MSV1_0_SUBAUTHENTICATION_DLL_IIS, name);
			RET_VAL_IF_EQUAL(MSV1_0_SUBAUTHENTICATION_DLL_RAS, name);
			RET_VAL_IF_EQUAL(MSV1_0_SUBAUTHENTICATION_FLAGS, name);
			RET_VAL_IF_EQUAL(MSV1_0_TRY_GUEST_ACCOUNT_ONLY, name);
			RET_VAL_IF_EQUAL(MSV1_0_TRY_SPECIFIED_DOMAIN_ONLY, name);
			RET_VAL_IF_EQUAL(MSV1_0_UPDATE_LOGON_STATISTICS, name);
			RET_VAL_IF_EQUAL(MSV1_0_USER_SESSION_KEY_LENGTH, name);

			RET_VAL_IF_EQUAL(MsvAvEOL, name);
			RET_VAL_IF_EQUAL(MsvAvNbComputerName, name);
			RET_VAL_IF_EQUAL(MsvAvNbDomainName, name);
			RET_VAL_IF_EQUAL(MsvAvDnsComputerName, name);
			RET_VAL_IF_EQUAL(MsvAvDnsDomainName, name);
			break;

		case 'N':
			RET_VAL_IF_EQUAL(NegCallPackageMax, name);
			RET_VAL_IF_EQUAL(NegEnumPackagePrefixes, name);
			RET_VAL_IF_EQUAL(NEGOTIATE_MAX_PREFIX, name);

			RET_VAL_IF_EQUAL(NET_DFS_SETDC_FLAGS, name);
			RET_VAL_IF_EQUAL(NET_DFS_SETDC_INITPKT, name);
			RET_VAL_IF_EQUAL(NET_DFS_SETDC_TIMEOUT, name);

			RET_VAL_IF_EQUAL(NETLOGON_CONTROL_BACKUP_CHANGE_LOG, name);
			RET_VAL_IF_EQUAL(NETLOGON_CONTROL_BREAKPOINT, name);
			RET_VAL_IF_EQUAL(NETLOGON_CONTROL_FIND_USER, name);
			RET_VAL_IF_EQUAL(NETLOGON_CONTROL_PDC_REPLICATE, name);
			RET_VAL_IF_EQUAL(NETLOGON_CONTROL_QUERY, name);
			RET_VAL_IF_EQUAL(NETLOGON_CONTROL_REDISCOVER, name);
			RET_VAL_IF_EQUAL(NETLOGON_CONTROL_REPLICATE, name);
			RET_VAL_IF_EQUAL(NETLOGON_CONTROL_SET_DBFLAG, name);
			RET_VAL_IF_EQUAL(NETLOGON_CONTROL_SYNCHRONIZE, name);
			RET_VAL_IF_EQUAL(NETLOGON_CONTROL_TC_QUERY, name);
			RET_VAL_IF_EQUAL(NETLOGON_CONTROL_TRANSPORT_NOTIFY, name);
			RET_VAL_IF_EQUAL(NETLOGON_CONTROL_TRUNCATE_LOG, name);
			RET_VAL_IF_EQUAL(NETLOGON_CONTROL_UNLOAD_NETLOGON_DLL, name);
			RET_VAL_IF_EQUAL(NETLOGON_FULL_SYNC_REPLICATION, name);
			RET_VAL_IF_EQUAL(NETLOGON_REDO_NEEDED, name);
			RET_VAL_IF_EQUAL(NETLOGON_REPLICATION_IN_PROGRESS, name);
			RET_VAL_IF_EQUAL(NETLOGON_REPLICATION_NEEDED, name);

			RET_VAL_IF_EQUAL(NETPROPERTY_PERSISTENT, name);

			RET_VAL_IF_EQUAL(Network, name);

			RET_VAL_IF_EQUAL(NetSetupDnsMachine, name);
			RET_VAL_IF_EQUAL(NetSetupDomain, name);
			RET_VAL_IF_EQUAL(NetSetupDomainName, name);
			RET_VAL_IF_EQUAL(NetSetupMachine, name);
			RET_VAL_IF_EQUAL(NetSetupNonExistentDomain, name);
			RET_VAL_IF_EQUAL(NetSetupUnjoined, name);
			RET_VAL_IF_EQUAL(NetSetupUnknown, name);
			RET_VAL_IF_EQUAL(NetSetupUnknownStatus, name);
			RET_VAL_IF_EQUAL(NetSetupWorkgroup, name);
			RET_VAL_IF_EQUAL(NetSetupWorkgroupName, name);

			RET_VAL_IF_EQUAL(NETSETUP_ACCT_CREATE, name);
			RET_VAL_IF_EQUAL(NETSETUP_ACCT_DELETE, name);
			RET_VAL_IF_EQUAL(NETSETUP_DOMAIN_JOIN_IF_JOINED, name);
			RET_VAL_IF_EQUAL(NETSETUP_INSTALL_INVOCATION, name);
			RET_VAL_IF_EQUAL(NETSETUP_JOIN_DOMAIN, name);
			RET_VAL_IF_EQUAL(NETSETUP_JOIN_UNSECURE, name);
			RET_VAL_IF_EQUAL(NETSETUP_WIN9X_UPGRADE, name);

			RET_VAL_IF_EQUAL(NO_PERMISSION_REQUIRED, name);
			break;		
			
		case 'O':
			RET_VAL_IF_EQUAL(ONE_DAY, name);
			RET_VAL_IF_EQUAL(OWNER_SECURITY_INFORMATION, name);
			break;

		case 'P':
			RET_VAL_IF_EQUAL(PERM_FILE_CREATE, name);
			RET_VAL_IF_EQUAL(PERM_FILE_READ, name);
			RET_VAL_IF_EQUAL(PERM_FILE_WRITE, name);

			RET_VAL_IF_EQUAL(POLICY_AUDIT_EVENT_FAILURE, name);
			RET_VAL_IF_EQUAL(POLICY_AUDIT_EVENT_NONE, name);
			RET_VAL_IF_EQUAL(POLICY_AUDIT_EVENT_MASK, name);
			RET_VAL_IF_EQUAL(POLICY_AUDIT_EVENT_NONE, name);
			RET_VAL_IF_EQUAL(POLICY_AUDIT_EVENT_SUCCESS, name);
			RET_VAL_IF_EQUAL(POLICY_AUDIT_EVENT_UNCHANGED, name);

			RET_VAL_IF_EQUAL(POLICY_ALL_ACCESS, name);
			RET_VAL_IF_EQUAL(POLICY_AUDIT_LOG_ADMIN, name);
			RET_VAL_IF_EQUAL(POLICY_CREATE_ACCOUNT, name);
			RET_VAL_IF_EQUAL(POLICY_CREATE_PRIVILEGE, name);
			RET_VAL_IF_EQUAL(POLICY_CREATE_SECRET, name);
			RET_VAL_IF_EQUAL(POLICY_EXECUTE, name);
			RET_VAL_IF_EQUAL(POLICY_GET_PRIVATE_INFORMATION, name);
			RET_VAL_IF_EQUAL(POLICY_LOOKUP_NAMES, name);
			RET_VAL_IF_EQUAL(POLICY_NOTIFICATION, name);
			RET_VAL_IF_EQUAL(POLICY_READ, name);
			RET_VAL_IF_EQUAL(POLICY_SERVER_ADMIN, name);
			RET_VAL_IF_EQUAL(POLICY_SET_AUDIT_REQUIREMENTS, name);
			RET_VAL_IF_EQUAL(POLICY_SET_DEFAULT_QUOTA_LIMITS, name);
			RET_VAL_IF_EQUAL(POLICY_TRUST_ADMIN, name);
			RET_VAL_IF_EQUAL(POLICY_VIEW_AUDIT_INFORMATION, name);
			RET_VAL_IF_EQUAL(POLICY_VIEW_LOCAL_INFORMATION, name);
			RET_VAL_IF_EQUAL(POLICY_WRITE, name);

			RET_VAL_IF_EQUAL(POLICY_QOS_ALLOW_LOCAL_ROOT_CERT_STORE, name);
			RET_VAL_IF_EQUAL(POLICY_QOS_DHCP_SERVER_ALLOWED, name);
			RET_VAL_IF_EQUAL(POLICY_QOS_INBOUND_CONFIDENTIALITY, name);
			RET_VAL_IF_EQUAL(POLICY_QOS_INBOUND_INTEGRITY, name);
			RET_VAL_IF_EQUAL(POLICY_QOS_OUTBOUND_CONFIDENTIALITY, name);
			RET_VAL_IF_EQUAL(POLICY_QOS_OUTBOUND_INTEGRITY, name);
			RET_VAL_IF_EQUAL(POLICY_QOS_RAS_SERVER_ALLOWED, name);
			RET_VAL_IF_EQUAL(POLICY_QOS_SCHANNEL_REQUIRED, name);

			// oops, not longer supported
			RET_VAL_IF_EQUAL(PolicyDomainQualityOfServiceInformation, name);
			RET_VAL_IF_EQUAL(PolicyDomainEfsInformation, name);
			RET_VAL_IF_EQUAL(PolicyDomainKerberosTicketInformation, name);

			RET_VAL_IF_EQUAL(PolicyAccountDomainInformation, name);
			RET_VAL_IF_EQUAL(PolicyAuditEventsInformation, name);
			RET_VAL_IF_EQUAL(PolicyAuditFullQueryInformation, name);
			RET_VAL_IF_EQUAL(PolicyAuditFullSetInformation, name);
			RET_VAL_IF_EQUAL(PolicyAuditLogInformation, name);
			RET_VAL_IF_EQUAL(PolicyDefaultQuotaInformation, name);
			RET_VAL_IF_EQUAL(PolicyDnsDomainInformation, name);
			RET_VAL_IF_EQUAL(PolicyLsaServerRoleInformation, name);
			RET_VAL_IF_EQUAL(PolicyModificationInformation, name);
			RET_VAL_IF_EQUAL(PolicyPdAccountInformation, name);
			RET_VAL_IF_EQUAL(PolicyPrimaryDomainInformation, name);
			RET_VAL_IF_EQUAL(PolicyReplicaSourceInformation, name);

			RET_VAL_IF_EQUAL(PolicyMachinePasswordInformation, name);

			RET_VAL_IF_EQUAL(PolicyNotifyAccountDomainInformation, name);
			RET_VAL_IF_EQUAL(PolicyNotifyAuditEventsInformation, name);
			RET_VAL_IF_EQUAL(PolicyNotifyDnsDomainInformation, name);
			RET_VAL_IF_EQUAL(PolicyNotifyDomainEfsInformation, name);
			RET_VAL_IF_EQUAL(PolicyNotifyDomainKerberosTicketInformation, name);
			RET_VAL_IF_EQUAL(PolicyNotifyMachineAccountPasswordInformation, name);
			RET_VAL_IF_EQUAL(PolicyNotifyServerRoleInformation, name);

			RET_VAL_IF_EQUAL(PolicyServerRoleBackup, name);
			RET_VAL_IF_EQUAL(PolicyServerRolePrimary, name);

			RET_VAL_IF_EQUAL(PolicyServerDisabled, name);
			RET_VAL_IF_EQUAL(PolicyServerEnabled, name);

			RET_VAL_IF_EQUAL(Proxy, name);
			break;
			
		case 'R':
			RET_VAL_IF_EQUAL(REMOTE_NAME_INFO_LEVEL, name);

			RET_VAL_IF_EQUAL(REPL_EXTENT_FILE, name);
			RET_VAL_IF_EQUAL(REPL_EXTENT_TREE, name);
			RET_VAL_IF_EQUAL(REPL_INTEGRITY_FILE, name);
			RET_VAL_IF_EQUAL(REPL_INTEGRITY_TREE, name);
			RET_VAL_IF_EQUAL(REPL_ROLE_BOTH, name);
			RET_VAL_IF_EQUAL(REPL_ROLE_EXPORT, name);
			RET_VAL_IF_EQUAL(REPL_ROLE_IMPORT, name);
			RET_VAL_IF_EQUAL(REPL_STATE_OK, name);
			RET_VAL_IF_EQUAL(REPL_STATE_NO_MASTER, name);
			RET_VAL_IF_EQUAL(REPL_STATE_NO_SYNC, name);
			RET_VAL_IF_EQUAL(REPL_STATE_NEVER_REPLICATED, name);
			RET_VAL_IF_EQUAL(REPL_UNLOCK_FORCE, name);
			RET_VAL_IF_EQUAL(REPL_UNLOCK_NOFORCE, name);

			RET_VAL_IF_EQUAL(RESOURCE_CONNECTED, name);
			RET_VAL_IF_EQUAL(RESOURCE_CONTEXT, name);
			RET_VAL_IF_EQUAL(RESOURCE_GLOBALNET, name);
			RET_VAL_IF_EQUAL(RESOURCE_RECENT, name);
			RET_VAL_IF_EQUAL(RESOURCE_REMEMBERED, name);
			RET_VAL_IF_EQUAL(RESOURCETYPE_ANY, name);
			RET_VAL_IF_EQUAL(RESOURCETYPE_DISK, name);
			RET_VAL_IF_EQUAL(RESOURCETYPE_PRINT, name);
			RET_VAL_IF_EQUAL(RESOURCETYPE_RESERVED, name);
			RET_VAL_IF_EQUAL(RESOURCETYPE_UNKNOWN, name);

			RET_VAL_IF_EQUAL(RESOURCEDISPLAYTYPE_DIRECTORY, name);
			RET_VAL_IF_EQUAL(RESOURCEDISPLAYTYPE_DOMAIN, name);
			RET_VAL_IF_EQUAL(RESOURCEDISPLAYTYPE_FILE, name);
			RET_VAL_IF_EQUAL(RESOURCEDISPLAYTYPE_GENERIC, name);
			RET_VAL_IF_EQUAL(RESOURCEDISPLAYTYPE_GROUP, name);
			RET_VAL_IF_EQUAL(RESOURCEDISPLAYTYPE_NDSCONTAINER, name);
			RET_VAL_IF_EQUAL(RESOURCEDISPLAYTYPE_NETWORK, name);
			RET_VAL_IF_EQUAL(RESOURCEDISPLAYTYPE_ROOT, name);
			RET_VAL_IF_EQUAL(RESOURCEDISPLAYTYPE_SERVER, name);
			RET_VAL_IF_EQUAL(RESOURCEDISPLAYTYPE_SHARE, name);
			RET_VAL_IF_EQUAL(RESOURCEDISPLAYTYPE_SHAREADMIN, name);
			RET_VAL_IF_EQUAL(RESOURCEDISPLAYTYPE_TREE, name);

			RET_VAL_IF_EQUAL(RESOURCEUSAGE_ALL, name);
			RET_VAL_IF_EQUAL(RESOURCEUSAGE_CONNECTABLE, name);
			RET_VAL_IF_EQUAL(RESOURCEUSAGE_CONTAINER, name);
			RET_VAL_IF_EQUAL(RESOURCEUSAGE_ATTACHED, name);
			RET_VAL_IF_EQUAL(RESOURCEUSAGE_NOLOCALDEVICE, name);
			RET_VAL_IF_EQUAL(RESOURCEUSAGE_RESERVED, name);
			RET_VAL_IF_EQUAL(RESOURCEUSAGE_SIBLING, name);
			break;

		case 'S':
			RET_VAL_IF_EQUAL(SACL_SECURITY_INFORMATION, name);

			RET_VAL_IF_EQUAL(SC_ACTION_NONE, name);
			RET_VAL_IF_EQUAL(SC_ACTION_REBOOT, name);
			RET_VAL_IF_EQUAL(SC_ACTION_RESTART, name);
			RET_VAL_IF_EQUAL(SC_ACTION_RUN_COMMAND, name);
			RET_VAL_IF_EQUAL(SC_MANAGER_ALL_ACCESS, name);
			RET_VAL_IF_EQUAL(SC_MANAGER_CONNECT, name);
			RET_VAL_IF_EQUAL(SC_MANAGER_CREATE_SERVICE, name);
			RET_VAL_IF_EQUAL(SC_MANAGER_ENUMERATE_SERVICE, name);
			RET_VAL_IF_EQUAL(SC_MANAGER_LOCK, name);
			RET_VAL_IF_EQUAL(SC_MANAGER_MODIFY_BOOT_CONFIG, name);
			RET_VAL_IF_EQUAL(SC_MANAGER_QUERY_LOCK_STATUS, name);
			RET_VAL_IF_EQUAL(SC_STATUS_PROCESS_INFO, name);
			RET_VAL_IF_EQUAL(SE_GROUP_ENABLED_BY_DEFAULT, name);
			RET_VAL_IF_EQUAL(SE_GROUP_MANDATORY, name);
			RET_VAL_IF_EQUAL(SE_GROUP_OWNER, name);
			RET_VAL_IF_EQUAL(Service, name);
			RET_VAL_IF_EQUAL(SERVICE_ACCEPT_HARDWAREPROFILECHANGE, name);
			RET_VAL_IF_EQUAL(SERVICE_ACCEPT_NETBINDCHANGE, name);
			RET_VAL_IF_EQUAL(SERVICE_ACCEPT_PARAMCHANGE, name);
			RET_VAL_IF_EQUAL(SERVICE_ACCEPT_PAUSE_CONTINUE, name);
			RET_VAL_IF_EQUAL(SERVICE_ACCEPT_POWEREVENT, name);
			RET_VAL_IF_EQUAL(SERVICE_ACCEPT_SHUTDOWN, name);
			RET_VAL_IF_EQUAL(SERVICE_ACCEPT_STOP, name);
			RET_VAL_IF_EQUAL(SERVICE_ACTIVE, name);
			RET_VAL_IF_EQUAL(SERVICE_ADAPTER, name);
			RET_VAL_IF_EQUAL(SERVICE_ALL_ACCESS, name);
			RET_VAL_IF_EQUAL(SERVICE_AUTO_START, name);
			RET_VAL_IF_EQUAL(SERVICE_BOOT_START, name);
			RET_VAL_IF_EQUAL(SERVICE_CHANGE_CONFIG, name);
			RET_VAL_IF_EQUAL(SERVICE_CONFIG_DESCRIPTION, name);
			RET_VAL_IF_EQUAL(SERVICE_CONFIG_FAILURE_ACTIONS, name);
			RET_VAL_IF_EQUAL(SERVICE_CONTINUE_PENDING, name);
			RET_VAL_IF_EQUAL(SERVICE_CONTROL_CONTINUE, name);
			RET_VAL_IF_EQUAL(SERVICE_CONTROL_DEVICEEVENT, name);
			RET_VAL_IF_EQUAL(SERVICE_CONTROL_HARDWAREPROFILECHANGE, name);
			RET_VAL_IF_EQUAL(SERVICE_CONTROL_INTERROGATE, name);
			RET_VAL_IF_EQUAL(SERVICE_CONTROL_NETBINDADD, name);
			RET_VAL_IF_EQUAL(SERVICE_CONTROL_NETBINDDISABLE, name);
			RET_VAL_IF_EQUAL(SERVICE_CONTROL_NETBINDENABLE, name);
			RET_VAL_IF_EQUAL(SERVICE_CONTROL_NETBINDREMOVE, name);
			RET_VAL_IF_EQUAL(SERVICE_CONTROL_PAUSE, name);
			RET_VAL_IF_EQUAL(SERVICE_CONTROL_PARAMCHANGE, name);
			RET_VAL_IF_EQUAL(SERVICE_CONTROL_POWEREVENT, name);
			RET_VAL_IF_EQUAL(SERVICE_CONTROL_SHUTDOWN, name);
			RET_VAL_IF_EQUAL(SERVICE_CONTROL_STOP, name);
			RET_VAL_IF_EQUAL(SERVICE_DEMAND_START, name);
			RET_VAL_IF_EQUAL(SERVICE_DISABLED, name);
			RET_VAL_IF_EQUAL(SERVICE_DRIVER, name);
			RET_VAL_IF_EQUAL(SERVICE_ENUMERATE_DEPENDENTS, name);
			RET_VAL_IF_EQUAL(SERVICE_ERROR_CRITICAL, name);
			RET_VAL_IF_EQUAL(SERVICE_ERROR_IGNORE, name);
			RET_VAL_IF_EQUAL(SERVICE_ERROR_NORMAL, name);
			RET_VAL_IF_EQUAL(SERVICE_ERROR_SEVERE, name);
			RET_VAL_IF_EQUAL(SERVICE_FILE_SYSTEM_DRIVER, name);
			RET_VAL_IF_EQUAL(SERVICE_INACTIVE, name);
			RET_VAL_IF_EQUAL(SERVICE_INTERROGATE, name);
			RET_VAL_IF_EQUAL(SERVICE_KERNEL_DRIVER, name);
			RET_VAL_IF_EQUAL(SERVICE_INTERACTIVE_PROCESS, name);
			RET_VAL_IF_EQUAL(SERVICE_NO_CHANGE, name);
			RET_VAL_IF_EQUAL(SERVICE_PAUSE_CONTINUE, name);
			RET_VAL_IF_EQUAL(SERVICE_PAUSE_PENDING, name);
			RET_VAL_IF_EQUAL(SERVICE_PAUSED, name);
			RET_VAL_IF_EQUAL(SERVICE_QUERY_CONFIG, name);
			RET_VAL_IF_EQUAL(SERVICE_QUERY_STATUS, name);
			RET_VAL_IF_EQUAL(SERVICE_RECOGNIZER_DRIVER, name);
			RET_VAL_IF_EQUAL(SERVICE_RUNNING, name);
			RET_VAL_IF_EQUAL(SERVICE_RUNS_IN_SYSTEM_PROCESS, name);
			RET_VAL_IF_EQUAL(SERVICE_START, name);
			RET_VAL_IF_EQUAL(SERVICE_START_PENDING, name);
			RET_VAL_IF_EQUAL(SERVICE_STATE_ALL, name);
			RET_VAL_IF_EQUAL(SERVICE_STOP, name);
			RET_VAL_IF_EQUAL(SERVICE_STOP_PENDING, name);
			RET_VAL_IF_EQUAL(SERVICE_STOPPED, name);
			RET_VAL_IF_EQUAL(SERVICE_SYSTEM_START, name);
			RET_VAL_IF_EQUAL(SERVICE_TYPE_ALL, name);
			RET_VAL_IF_EQUAL(SERVICE_USER_DEFINED_CONTROL, name);
			RET_VAL_IF_EQUAL(SERVICE_WIN32, name);
			RET_VAL_IF_EQUAL(SERVICE_WIN32_OWN_PROCESS, name);
			RET_VAL_IF_EQUAL(SERVICE_WIN32_SHARE_PROCESS, name);

			RET_VAL_IF_EQUAL(SESS_GUEST, name);
			RET_VAL_IF_EQUAL(SESS_NOENCRYPTION, name);

			RET_VAL_IF_EQUAL(STYPE_DEVICE, name);
			RET_VAL_IF_EQUAL(STYPE_DISKTREE, name);
			RET_VAL_IF_EQUAL(STYPE_IPC, name);
			RET_VAL_IF_EQUAL(STYPE_PRINTQ, name);

			RET_VAL_IF_EQUAL(SUPPORTS_ANY, name);
			RET_VAL_IF_EQUAL(SUPPORTS_LOCAL, name);
			RET_VAL_IF_EQUAL(SUPPORTS_REMOTE_ADMIN_PROTOCOL, name);
			RET_VAL_IF_EQUAL(SUPPORTS_RPC, name);
			RET_VAL_IF_EQUAL(SUPPORTS_SAM_PROTOCOL, name);
			RET_VAL_IF_EQUAL(SUPPORTS_UNICODE, name);

			RET_VAL_IF_EQUAL(SV_HIDDEN, name);
			RET_VAL_IF_EQUAL(SV_MAX_CMD_LEN, name);
			RET_VAL_IF_EQUAL(SV_MAX_SRV_HEUR_LEN, name);
			RET_VAL_IF_EQUAL(SV_PLATFORM_ID_OS2, name);
			RET_VAL_IF_EQUAL(SV_PLATFORM_ID_NT, name);
			RET_VAL_IF_EQUAL(SV_SHARESECURITY, name);

			RET_VAL_IF_EQUAL(SV_TYPE_AFP, name);
			RET_VAL_IF_EQUAL(SV_TYPE_ALL, name);
			RET_VAL_IF_EQUAL(SV_TYPE_ALTERNATE_XPORT, name);
			RET_VAL_IF_EQUAL(SV_TYPE_BACKUP_BROWSER, name);
			RET_VAL_IF_EQUAL(SV_TYPE_CLUSTER_NT, name);
			RET_VAL_IF_EQUAL(SV_TYPE_DCE, name);
			RET_VAL_IF_EQUAL(SV_TYPE_DFS, name);
			RET_VAL_IF_EQUAL(SV_TYPE_DIALIN_SERVER, name);
			RET_VAL_IF_EQUAL(SV_TYPE_DOMAIN_BAKCTRL, name);
			RET_VAL_IF_EQUAL(SV_TYPE_DOMAIN_CTRL, name);
			RET_VAL_IF_EQUAL(SV_TYPE_DOMAIN_ENUM, name);
			RET_VAL_IF_EQUAL(SV_TYPE_DOMAIN_MASTER, name);
			RET_VAL_IF_EQUAL(SV_TYPE_DOMAIN_MEMBER, name);
			RET_VAL_IF_EQUAL(SV_TYPE_LOCAL_LIST_ONLY, name);
			RET_VAL_IF_EQUAL(SV_TYPE_MASTER_BROWSER, name);
			RET_VAL_IF_EQUAL(SV_TYPE_NOVELL, name);
			RET_VAL_IF_EQUAL(SV_TYPE_NT, name);
			RET_VAL_IF_EQUAL(SV_TYPE_POTENTIAL_BROWSER, name);
			RET_VAL_IF_EQUAL(SV_TYPE_PRINTQ_SERVER, name);
			RET_VAL_IF_EQUAL(SV_TYPE_SERVER, name);
			RET_VAL_IF_EQUAL(SV_TYPE_SERVER_MFPN, name);
			RET_VAL_IF_EQUAL(SV_TYPE_SERVER_NT, name);
			RET_VAL_IF_EQUAL(SV_TYPE_SERVER_OSF, name);
			RET_VAL_IF_EQUAL(SV_TYPE_SERVER_UNIX, name);
			RET_VAL_IF_EQUAL(SV_TYPE_SERVER_VMS, name);
			RET_VAL_IF_EQUAL(SV_TYPE_SQLSERVER, name);
			RET_VAL_IF_EQUAL(SV_TYPE_TERMINALSERVER, name);
			RET_VAL_IF_EQUAL(SV_TYPE_TIME_SOURCE, name);
			RET_VAL_IF_EQUAL(SV_TYPE_WFW, name);
			RET_VAL_IF_EQUAL(SV_TYPE_WINDOWS, name);
			RET_VAL_IF_EQUAL(SV_TYPE_WORKSTATION, name);
			RET_VAL_IF_EQUAL(SV_TYPE_XENIX_SERVER, name);
			RET_VAL_IF_EQUAL(SV_USERS_PER_LICENSE, name);
			RET_VAL_IF_EQUAL(SV_USERSECURITY, name);
			RET_VAL_IF_EQUAL(SV_VISIBLE, name);
			RET_VAL_IF_EQUAL(SW_AUTOPROF_LOAD_MASK, name);
			RET_VAL_IF_EQUAL(SW_AUTOPROF_SAVE_MASK, name);
			break;
		
		case 'T':
			RET_VAL_IF_EQUAL(TIMEQ_FOREVER, name);

			RET_VAL_IF_EQUAL(TRUST_ATTRIBUTE_NON_TRANSITIVE, name);

			// oops, not longer supported
			RET_VAL_IF_EQUAL(TRUST_ATTRIBUTE_TREE_PARENT, name);

			// oops, not longer supported
			RET_VAL_IF_EQUAL(TRUST_ATTRIBUTE_TREE_ROOT, name);
			RET_VAL_IF_EQUAL(TRUST_ATTRIBUTE_UPLEVEL_ONLY, name);
			RET_VAL_IF_EQUAL(TRUST_ATTRIBUTES_USER, name);
			RET_VAL_IF_EQUAL(TRUST_ATTRIBUTES_VALID, name);

			RET_VAL_IF_EQUAL(TRUST_AUTH_TYPE_CLEAR, name);
			RET_VAL_IF_EQUAL(TRUST_AUTH_TYPE_NONE, name);
			RET_VAL_IF_EQUAL(TRUST_AUTH_TYPE_NT4OWF, name);
			RET_VAL_IF_EQUAL(TRUST_AUTH_TYPE_VERSION, name);

			RET_VAL_IF_EQUAL(TRUST_DIRECTION_BIDIRECTIONAL, name);
			RET_VAL_IF_EQUAL(TRUST_DIRECTION_DISABLED, name);
			RET_VAL_IF_EQUAL(TRUST_DIRECTION_INBOUND, name);
			RET_VAL_IF_EQUAL(TRUST_DIRECTION_OUTBOUND, name);

			RET_VAL_IF_EQUAL(TRUST_TYPE_DCE, name);	//nt5
			RET_VAL_IF_EQUAL(TRUST_TYPE_DOWNLEVEL, name);
			RET_VAL_IF_EQUAL(TRUST_TYPE_MIT, name);	//nt5
			RET_VAL_IF_EQUAL(TRUST_TYPE_UPLEVEL, name);	//nt5
			
			RET_VAL_IF_EQUAL(TrustedControllersInformation, name);
			RET_VAL_IF_EQUAL(TrustedDomainAuthInformation, name);
			RET_VAL_IF_EQUAL(TrustedDomainFullInformation, name);
			RET_VAL_IF_EQUAL(TrustedDomainInformationBasic, name);
			RET_VAL_IF_EQUAL(TrustedDomainInformationEx, name);
			RET_VAL_IF_EQUAL(TrustedDomainNameInformation, name);
			RET_VAL_IF_EQUAL(TrustedPasswordInformation, name);
			RET_VAL_IF_EQUAL(TrustedPosixOffsetInformation, name);
			break;

		case 'U':
			RET_VAL_IF_EQUAL(UAS_ROLE_STANDALONE, name);
			RET_VAL_IF_EQUAL(UAS_ROLE_MEMBER, name);
			RET_VAL_IF_EQUAL(UAS_ROLE_BACKUP, name);
			RET_VAL_IF_EQUAL(UAS_ROLE_PRIMARY, name);

			RET_VAL_IF_EQUAL(UNIVERSAL_NAME_INFO_LEVEL, name);

			RET_VAL_IF_EQUAL(UF_ACCOUNT_TYPE_MASK, name);
			RET_VAL_IF_EQUAL(UF_ACCOUNTDISABLE, name);
			RET_VAL_IF_EQUAL(UF_DONT_EXPIRE_PASSWD, name);
			RET_VAL_IF_EQUAL(UF_DONT_REQUIRE_PREAUTH, name);
			RET_VAL_IF_EQUAL(UF_ENCRYPTED_TEXT_PASSWORD_ALLOWED, name);
			RET_VAL_IF_EQUAL(UF_HOMEDIR_REQUIRED, name);
			RET_VAL_IF_EQUAL(UF_INTERDOMAIN_TRUST_ACCOUNT, name);
			RET_VAL_IF_EQUAL(UF_LOCKOUT, name);
			RET_VAL_IF_EQUAL(UF_MACHINE_ACCOUNT_MASK, name);
			RET_VAL_IF_EQUAL(UF_MNS_LOGON_ACCOUNT, name);
			RET_VAL_IF_EQUAL(UF_NORMAL_ACCOUNT, name);
			RET_VAL_IF_EQUAL(UF_NOT_DELEGATED, name);
			RET_VAL_IF_EQUAL(UF_PASSWD_CANT_CHANGE, name);
			RET_VAL_IF_EQUAL(UF_PASSWD_NOTREQD, name);
			// only supported by Whistler
			//RET_VAL_IF_EQUAL(UF_PASSWORD_EXPIRED, name);
			RET_VAL_IF_EQUAL(UF_SCRIPT, name);
			RET_VAL_IF_EQUAL(UF_SERVER_TRUST_ACCOUNT, name);
			RET_VAL_IF_EQUAL(UF_SETTABLE_BITS, name);
			RET_VAL_IF_EQUAL(UF_SMARTCARD_REQUIRED, name);
			RET_VAL_IF_EQUAL(UF_TEMP_DUPLICATE_ACCOUNT, name);
			RET_VAL_IF_EQUAL(UF_TRUSTED_FOR_DELEGATION, name);
			RET_VAL_IF_EQUAL(UF_USE_DES_KEY_ONLY, name);
			RET_VAL_IF_EQUAL(UF_WORKSTATION_TRUST_ACCOUNT, name);

			RET_VAL_IF_EQUAL(UNITS_PER_WEEK, name);

			RET_VAL_IF_EQUAL(Unlock, name);

			RET_VAL_IF_EQUAL(USE_SPECIFIC_TRANSPORT, name);

			RET_VAL_IF_EQUAL(USE_FORCE, name);
			RET_VAL_IF_EQUAL(USE_LOTS_OF_FORCE, name);
			RET_VAL_IF_EQUAL(USE_NOFORCE, name);

			RET_VAL_IF_EQUAL(USE_CHARDEV, name);
			RET_VAL_IF_EQUAL(USE_CONN, name);
			RET_VAL_IF_EQUAL(USE_DISCONN, name);
			RET_VAL_IF_EQUAL(USE_DISKDEV, name);
			RET_VAL_IF_EQUAL(USE_IPC, name);
			RET_VAL_IF_EQUAL(USE_NETERR, name);
			RET_VAL_IF_EQUAL(USE_OK, name);
			RET_VAL_IF_EQUAL(USE_PAUSED, name);
			RET_VAL_IF_EQUAL(USE_RECONN, name);
			RET_VAL_IF_EQUAL(USE_SESSLOST, name);
			RET_VAL_IF_EQUAL(USE_SPOOLDEV, name);
			RET_VAL_IF_EQUAL(USE_WILDCARD, name);
			
			RET_VAL_IF_EQUAL(USER_MAXSTORAGE_UNLIMITED, name);
			
			RET_VAL_IF_EQUAL(USER_PRIV_ADMIN, name);
			RET_VAL_IF_EQUAL(USER_PRIV_GUEST, name);
			RET_VAL_IF_EQUAL(USER_PRIV_USER, name);
			break;	

		case 'W':
			RET_VAL_IF_EQUAL(WNCON_DYNAMIC, name);
			RET_VAL_IF_EQUAL(WNCON_FORNETCARD, name);
			RET_VAL_IF_EQUAL(WNCON_NOTROUTED, name);
			RET_VAL_IF_EQUAL(WNCON_SLOWLINK, name);

			RET_VAL_IF_EQUAL(WNNC_CRED_MANAGER, name);
			RET_VAL_IF_EQUAL(WNNC_NET_10NET, name);
			RET_VAL_IF_EQUAL(WNNC_NET_3IN1, name);
			RET_VAL_IF_EQUAL(WNNC_NET_9TILES, name);
			RET_VAL_IF_EQUAL(WNNC_NET_APPLETALK, name);
			RET_VAL_IF_EQUAL(WNNC_NET_AS400, name);
			RET_VAL_IF_EQUAL(WNNC_NET_AVID, name);
			RET_VAL_IF_EQUAL(WNNC_NET_BMC, name);
			RET_VAL_IF_EQUAL(WNNC_NET_BWNFS, name);
			RET_VAL_IF_EQUAL(WNNC_NET_CLEARCASE, name);
			RET_VAL_IF_EQUAL(WNNC_NET_COGENT, name);
			RET_VAL_IF_EQUAL(WNNC_NET_CSC, name);
			RET_VAL_IF_EQUAL(WNNC_NET_DCE, name);
			RET_VAL_IF_EQUAL(WNNC_NET_DECORB, name);
			RET_VAL_IF_EQUAL(WNNC_NET_DISTINCT, name);
			RET_VAL_IF_EQUAL(WNNC_NET_DOCUSPACE, name);
			RET_VAL_IF_EQUAL(WNNC_NET_EXTENDNET, name);
			RET_VAL_IF_EQUAL(WNNC_NET_FARALLON, name);
			RET_VAL_IF_EQUAL(WNNC_NET_FJ_REDIR, name);
			RET_VAL_IF_EQUAL(WNNC_NET_FTP_NFS, name);
			RET_VAL_IF_EQUAL(WNNC_NET_FRONTIER, name);
			RET_VAL_IF_EQUAL(WNNC_NET_HOB_NFS, name);
			RET_VAL_IF_EQUAL(WNNC_NET_IBMAL, name);
			RET_VAL_IF_EQUAL(WNNC_NET_INTERGRAPH, name);
			RET_VAL_IF_EQUAL(WNNC_NET_LANMAN, name);
			RET_VAL_IF_EQUAL(WNNC_NET_LANTASTIC, name);
			RET_VAL_IF_EQUAL(WNNC_NET_LANSTEP, name);
			RET_VAL_IF_EQUAL(WNNC_NET_LIFENET, name);
			RET_VAL_IF_EQUAL(WNNC_NET_LOCUS, name);
			RET_VAL_IF_EQUAL(WNNC_NET_MANGOSOFT, name);
			RET_VAL_IF_EQUAL(WNNC_NET_MASFAX, name);
			RET_VAL_IF_EQUAL(WNNC_NET_MSNET, name);
			RET_VAL_IF_EQUAL(WNNC_NET_NETWARE, name);
			RET_VAL_IF_EQUAL(WNNC_NET_OBJECT_DIRE, name);
			RET_VAL_IF_EQUAL(WNNC_NET_PATHWORKS, name);
			RET_VAL_IF_EQUAL(WNNC_NET_POWERLAN, name);
			RET_VAL_IF_EQUAL(WNNC_NET_PROTSTOR, name);
			RET_VAL_IF_EQUAL(WNNC_NET_RDR2SAMPLE, name);
			RET_VAL_IF_EQUAL(WNNC_NET_SERNET, name);
			RET_VAL_IF_EQUAL(WNNC_NET_SHIVA, name);
			RET_VAL_IF_EQUAL(WNNC_NET_SUN_PC_NFS, name);
			RET_VAL_IF_EQUAL(WNNC_NET_SYMFONET, name);
			RET_VAL_IF_EQUAL(WNNC_NET_TWINS, name);
			RET_VAL_IF_EQUAL(WNNC_NET_VINES, name);

			RET_VAL_IF_EQUAL((long)WTS_CURRENT_SERVER, name);
			RET_VAL_IF_EQUAL((long)WTS_CURRENT_SERVER_HANDLE, name);
			RET_VAL_IF_EQUAL(WTS_CURRENT_SERVER_NAME, name);
			RET_VAL_IF_EQUAL(WTS_CURRENT_SESSION, name);

			RET_VAL_IF_EQUAL(WTS_EVENT_NONE, name);
			RET_VAL_IF_EQUAL(WTS_EVENT_CREATE, name);
			RET_VAL_IF_EQUAL(WTS_EVENT_DELETE, name);
			RET_VAL_IF_EQUAL(WTS_EVENT_RENAME, name);
			RET_VAL_IF_EQUAL(WTS_EVENT_CONNECT, name);
			RET_VAL_IF_EQUAL(WTS_EVENT_DISCONNECT, name);
			RET_VAL_IF_EQUAL(WTS_EVENT_LOGON, name);
			RET_VAL_IF_EQUAL(WTS_EVENT_LOGOFF, name);
			RET_VAL_IF_EQUAL(WTS_EVENT_STATECHANGE, name);
			RET_VAL_IF_EQUAL(WTS_EVENT_LICENSE, name);
			RET_VAL_IF_EQUAL(WTS_EVENT_ALL, name);
			RET_VAL_IF_EQUAL(WTS_EVENT_FLUSH, name);

			RET_VAL_IF_EQUAL(WTS_WSD_FASTREBOOT, name);
			RET_VAL_IF_EQUAL(WTS_WSD_LOGOFF, name);
			RET_VAL_IF_EQUAL(WTS_WSD_POWEROFF, name);
			RET_VAL_IF_EQUAL(WTS_WSD_REBOOT, name);
			RET_VAL_IF_EQUAL(WTS_WSD_SHUTDOWN, name);

			RET_VAL_IF_EQUAL(WTSActive, name);
			RET_VAL_IF_EQUAL(WTSConnected, name);
			RET_VAL_IF_EQUAL(WTSConnectQuery, name);
			RET_VAL_IF_EQUAL(WTSShadow, name);
			RET_VAL_IF_EQUAL(WTSDisconnected, name);
			RET_VAL_IF_EQUAL(WTSIdle, name);
			RET_VAL_IF_EQUAL(WTSListen, name);
			RET_VAL_IF_EQUAL(WTSReset, name);
			RET_VAL_IF_EQUAL(WTSDown, name);
			RET_VAL_IF_EQUAL(WTSInit, name);

			RET_VAL_IF_EQUAL(WTSApplicationName, name);
			RET_VAL_IF_EQUAL(WTSInitialProgram, name);
			RET_VAL_IF_EQUAL(WTSClientAddress, name);
			RET_VAL_IF_EQUAL(WTSClientBuildNumber, name);
			RET_VAL_IF_EQUAL(WTSClientDirectory, name);
			RET_VAL_IF_EQUAL(WTSClientDisplay, name);
			RET_VAL_IF_EQUAL(WTSClientHardwareId, name);
			RET_VAL_IF_EQUAL(WTSClientName, name);
			RET_VAL_IF_EQUAL(WTSClientProductId, name);
			RET_VAL_IF_EQUAL(WTSConnectState, name);
			RET_VAL_IF_EQUAL(WTSDomainName, name);
			RET_VAL_IF_EQUAL(WTSOEMId, name);
			RET_VAL_IF_EQUAL(WTSSessionId, name);
			RET_VAL_IF_EQUAL(WTSUserName, name);
			RET_VAL_IF_EQUAL(WTSWinStationName, name);
			RET_VAL_IF_EQUAL(WTSWorkingDirectory, name);

			RET_VAL_IF_EQUAL(WTSUserConfigInitialProgram, name);
			RET_VAL_IF_EQUAL(WTSUserConfigInitialProgram, name);
			RET_VAL_IF_EQUAL(WTSUserConfigWorkingDirectory, name);
			RET_VAL_IF_EQUAL(WTSUserConfigfInheritInitialProgram, name);
			RET_VAL_IF_EQUAL(WTSUserConfigfAllowLogonTerminalServer, name);
			RET_VAL_IF_EQUAL(WTSUserConfigTimeoutSettingsConnections, name);
			RET_VAL_IF_EQUAL(WTSUserConfigTimeoutSettingsDisconnections, name);
			RET_VAL_IF_EQUAL(WTSUserConfigTimeoutSettingsIdle, name);
			RET_VAL_IF_EQUAL(WTSUserConfigfDeviceClientDrives, name);
			RET_VAL_IF_EQUAL(WTSUserConfigfDeviceClientPrinters, name);
			RET_VAL_IF_EQUAL(WTSUserConfigfDeviceClientDefaultPrinter, name);
			RET_VAL_IF_EQUAL(WTSUserConfigBrokenTimeoutSettings, name);
			RET_VAL_IF_EQUAL(WTSUserConfigReconnectSettings, name);
			RET_VAL_IF_EQUAL(WTSUserConfigModemCallbackSettings, name);
			RET_VAL_IF_EQUAL(WTSUserConfigModemCallbackPhoneNumber, name);
			RET_VAL_IF_EQUAL(WTSUserConfigShadowingSettings, name);
			RET_VAL_IF_EQUAL(WTSUserConfigTerminalServerProfilePath, name);
			RET_VAL_IF_EQUAL(WTSUserConfigTerminalServerHomeDir, name);
			RET_VAL_IF_EQUAL(WTSUserConfigTerminalServerHomeDirDrive, name);
			RET_VAL_IF_EQUAL(WTSUserConfigfTerminalServerRemoteHomeDir, name);
			break;
	}
	
	LastError(ENOENT);
  
  return 0;
}

///////////////////////////////////////////////////////////////////////////////
//
// maps an string value to an integer; will be called automatically, if you 
// access a value form section @EXPORT in *.pm
//
// param:  name - constant name
//         arg  - argument
//
// return: success - constant name as integer
//         failure - 0
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_constant)
{
	dXSARGS;

	// reset last error
	LastError(0);

	if(items == 2)
	{
		PSTR name = (PSTR)SvPV(ST(0), PL_na);
		ST(0) = sv_newmortal();
		sv_setiv(ST(0), constant(P_PERL name));
	}
	else
		croak("Usage: Win32::Lanman::constant(name, arg)\n");

	XSRETURN(1);
}

///////////////////////////////////////////////////////////////////////////////
//
// gets the last error code
//
// param:  nothing
//
// return: last error code
//
// note:   you can call this function to get an specific error code from the
//         last failure; if a function from this module returns 0, you should
//         call GetLastError() to get the error code; the error code will be 
//         reset to null on each function entry
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_GetLastError)
{
	dXSARGS;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), LastError());

	XSRETURN(1);
}

///////////////////////////////////////////////////////////////////////////////
//
// sets the last error code
//
// param:  nothing
//
// return: last error code
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_SetLastError)
{
	dXSARGS;

	LastError(SvIV(ST(0)));

	XSRETURN(1);
}

XS(XS_NT__Lanman_test)
{
	dXSARGS;
/*
	static count = 0;

	AV *test1 = NULL;

	if(items == 1 && CHK_ASSIGN_AREF(test1, ST(0)))
	{
		printf(".");
		// clear hash
		AV_CLEAR(test1);

		for(int i = 0; i < 1; i++, count++)
		{
			HV *prop = NewHV;

			// decrement reference count
			SvREFCNT_dec(prop);
			
			//A_STORE_REF(test1, prop);
			
			//A_STORE_INT(test1, count);
		}
	}
	else
		croak("Usage: Win32::Lanman::test(\\@test)\n");
*/
	RETURNRESULT(LastError() == 0);
}

///////////////////////////////////////////////////////////////////////////////
//
// export function to perl; all calls to the module are defined here
//
///////////////////////////////////////////////////////////////////////////////

XS(boot_Win32__Lanman)
{
	dXSARGS;
	PSTR file = __FILE__;

	//newXS("Win32::Lanman::test", XS_NT__Lanman_test, file);

	newXS("Win32::Lanman::constant", XS_NT__Lanman_constant, file);
	newXS("Win32::Lanman::GetLastError", XS_NT__Lanman_GetLastError, file);
	newXS("Win32::Lanman::SetLastError", XS_NT__Lanman_SetLastError, file);

	// not complete function group
	//newXS("Win32::Lanman::NetAlertRaise", XS_NT__Lanman_NetAlertRaise, file);
	//newXS("Win32::Lanman::I_BrowserServerEnum", XS_NT__Lanman_I_BrowserServerEnum, file);

	// dfs
	newXS("Win32::Lanman::NetDfsAdd", XS_NT__Lanman_NetDfsAdd, file);
	newXS("Win32::Lanman::NetDfsEnum", XS_NT__Lanman_NetDfsEnum, file);
	newXS("Win32::Lanman::NetDfsGetInfo", XS_NT__Lanman_NetDfsGetInfo, file);
	newXS("Win32::Lanman::NetDfsRemove", XS_NT__Lanman_NetDfsRemove, file);
	newXS("Win32::Lanman::NetDfsSetInfo", XS_NT__Lanman_NetDfsSetInfo, file);
	// currently not supported
	newXS("Win32::Lanman::NetDfsRename", XS_NT__Lanman_NetDfsRename, file);
	// currently not supported
	newXS("Win32::Lanman::NetDfsMove", XS_NT__Lanman_NetDfsMove, file);

	// logon
	newXS("Win32::Lanman::NetEnumerateTrustedDomains",
				XS_NT__Lanman_NetEnumerateTrustedDomains, file);
	newXS("Win32::Lanman::I_NetLogonControl", XS_NT__Lanman_I_NetLogonControl, file);
	newXS("Win32::Lanman::I_NetLogonControl2", XS_NT__Lanman_I_NetLogonControl2, file);
	newXS("Win32::Lanman::I_NetGetDCList", XS_NT__Lanman_I_NetGetDCList, file);

	// file
	newXS("Win32::Lanman::NetFileEnum", XS_NT__Lanman_NetFileEnum, file);
	newXS("Win32::Lanman::NetFileGetInfo", XS_NT__Lanman_NetFileGetInfo, file);
	newXS("Win32::Lanman::NetFileClose", XS_NT__Lanman_NetFileClose, file);

	// get
	newXS("Win32::Lanman::MultinetGetConnectionPerformance", 
				XS_NT__Lanman_MultinetGetConnectionPerformance, file);
	newXS("Win32::Lanman::NetGetAnyDCName", XS_NT__Lanman_NetGetAnyDCName, file);
	newXS("Win32::Lanman::NetGetDCName", XS_NT__Lanman_NetGetDCName, file);
	newXS("Win32::Lanman::NetGetDisplayInformationIndex", 
				XS_NT__Lanman_NetGetDisplayInformationIndex, file);
	newXS("Win32::Lanman::NetQueryDisplayInformation", 
				XS_NT__Lanman_NetQueryDisplayInformation, file);

	// group
	newXS("Win32::Lanman::NetGroupAdd", XS_NT__Lanman_NetGroupAdd, file);
	newXS("Win32::Lanman::NetGroupAddUser", XS_NT__Lanman_NetGroupAddUser, file);
	newXS("Win32::Lanman::NetGroupDel", XS_NT__Lanman_NetGroupDel, file);
	newXS("Win32::Lanman::NetGroupDelUser", XS_NT__Lanman_NetGroupDelUser, file);
	newXS("Win32::Lanman::NetGroupEnum", XS_NT__Lanman_NetGroupEnum, file);
	newXS("Win32::Lanman::NetGroupGetInfo", XS_NT__Lanman_NetGroupGetInfo, file);
	newXS("Win32::Lanman::NetGroupGetUsers", XS_NT__Lanman_NetGroupGetUsers, file);
	newXS("Win32::Lanman::NetGroupSetInfo", XS_NT__Lanman_NetGroupSetInfo, file);
	newXS("Win32::Lanman::NetGroupSetUsers", XS_NT__Lanman_NetGroupSetUsers, file);
	newXS("Win32::Lanman::NetLocalGroupAdd", XS_NT__Lanman_NetLocalGroupAdd, file);
	newXS("Win32::Lanman::NetLocalGroupAddMember", 
				XS_NT__Lanman_NetLocalGroupAddMember, file);
	newXS("Win32::Lanman::NetLocalGroupAddMembers", 
				XS_NT__Lanman_NetLocalGroupAddMembers, file);
	newXS("Win32::Lanman::NetLocalGroupAddMembersBySid", 
				XS_NT__Lanman_NetLocalGroupAddMembersBySid, file);
	newXS("Win32::Lanman::NetLocalGroupDel", XS_NT__Lanman_NetLocalGroupDel, file);
	newXS("Win32::Lanman::NetLocalGroupDelMember", 
				XS_NT__Lanman_NetLocalGroupDelMember, file);
	newXS("Win32::Lanman::NetLocalGroupDelMembers", 
				XS_NT__Lanman_NetLocalGroupDelMembers, file);
	newXS("Win32::Lanman::NetLocalGroupDelMembersBySid", 
				XS_NT__Lanman_NetLocalGroupDelMembersBySid, file);
	newXS("Win32::Lanman::NetLocalGroupEnum",	XS_NT__Lanman_NetLocalGroupEnum, file);
	newXS("Win32::Lanman::NetLocalGroupGetInfo", 
				XS_NT__Lanman_NetLocalGroupGetInfo, file);
	newXS("Win32::Lanman::NetLocalGroupGetMembers", 
				XS_NT__Lanman_NetLocalGroupGetMembers, file);
	newXS("Win32::Lanman::NetLocalGroupSetInfo", XS_NT__Lanman_NetLocalGroupSetInfo, file);
	newXS("Win32::Lanman::NetLocalGroupSetMembers", 
				XS_NT__Lanman_NetLocalGroupSetMembers, file);
	newXS("Win32::Lanman::NetLocalGroupSetMembersBySid", 
				XS_NT__Lanman_NetLocalGroupSetMembersBySid, file);

	// message
	newXS("Win32::Lanman::NetMessageBufferSend", 
				XS_NT__Lanman_NetMessageBufferSend, file);
	newXS("Win32::Lanman::NetMessageNameAdd", XS_NT__Lanman_NetMessageNameAdd, file);
	newXS("Win32::Lanman::NetMessageNameDel", XS_NT__Lanman_NetMessageNameDel, file);
	newXS("Win32::Lanman::NetMessageNameEnum", XS_NT__Lanman_NetMessageNameEnum, file);
	newXS("Win32::Lanman::NetMessageNameGetInfo", 
				XS_NT__Lanman_NetMessageNameGetInfo, file);

	// time and support
	newXS("Win32::Lanman::NetRemoteTOD", XS_NT__Lanman_NetRemoteTOD, file);
	newXS("Win32::Lanman::NetRemoteComputerSupports", 
				XS_NT__Lanman_NetRemoteComputerSupports, file);

	// replicator
	newXS("Win32::Lanman::NetReplExportDirAdd", XS_NT__Lanman_NetReplExportDirAdd, file);
	newXS("Win32::Lanman::NetReplExportDirDel", XS_NT__Lanman_NetReplExportDirDel, file);
	newXS("Win32::Lanman::NetReplExportDirEnum", XS_NT__Lanman_NetReplExportDirEnum, file);
	newXS("Win32::Lanman::NetReplExportDirGetInfo", 
				XS_NT__Lanman_NetReplExportDirGetInfo, file);
	newXS("Win32::Lanman::NetReplExportDirLock", XS_NT__Lanman_NetReplExportDirLock, file);
	newXS("Win32::Lanman::NetReplExportDirSetInfo", 
				XS_NT__Lanman_NetReplExportDirSetInfo, file);
	newXS("Win32::Lanman::NetReplExportDirUnlock", 
				XS_NT__Lanman_NetReplExportDirUnlock, file);
	newXS("Win32::Lanman::NetReplGetInfo", XS_NT__Lanman_NetReplGetInfo, file);
	newXS("Win32::Lanman::NetReplImportDirAdd", XS_NT__Lanman_NetReplImportDirAdd, file);
	newXS("Win32::Lanman::NetReplImportDirDel", XS_NT__Lanman_NetReplImportDirDel, file);
	newXS("Win32::Lanman::NetReplImportDirEnum", XS_NT__Lanman_NetReplImportDirEnum, file);
	newXS("Win32::Lanman::NetReplImportDirGetInfo", 
				XS_NT__Lanman_NetReplImportDirGetInfo, file);
	newXS("Win32::Lanman::NetReplImportDirLock", XS_NT__Lanman_NetReplImportDirLock, file);
	newXS("Win32::Lanman::NetReplImportDirUnlock", 
				XS_NT__Lanman_NetReplImportDirUnlock, file);
	newXS("Win32::Lanman::NetReplSetInfo", XS_NT__Lanman_NetReplSetInfo, file);

	// scheduler
	newXS("Win32::Lanman::NetScheduleJobAdd", XS_NT__Lanman_NetScheduleJobAdd, file);
	newXS("Win32::Lanman::NetScheduleJobDel", XS_NT__Lanman_NetScheduleJobDel, file);
	newXS("Win32::Lanman::NetScheduleJobEnum", XS_NT__Lanman_NetScheduleJobEnum, file);
	newXS("Win32::Lanman::NetScheduleJobGetInfo", 
				XS_NT__Lanman_NetScheduleJobGetInfo, file);

	// server
	newXS("Win32::Lanman::NetServerDiskEnum", XS_NT__Lanman_NetServerDiskEnum, file);
	newXS("Win32::Lanman::NetServerEnum", XS_NT__Lanman_NetServerEnum, file);
	newXS("Win32::Lanman::NetServerGetInfo", XS_NT__Lanman_NetServerGetInfo, file);
	newXS("Win32::Lanman::NetServerSetInfo", XS_NT__Lanman_NetServerSetInfo, file);
	newXS("Win32::Lanman::NetServerTransportAdd", 
				XS_NT__Lanman_NetServerTransportAdd, file);
	newXS("Win32::Lanman::NetServerTransportDel", 
				XS_NT__Lanman_NetServerTransportDel, file);
	newXS("Win32::Lanman::NetServerTransportEnum", 
				XS_NT__Lanman_NetServerTransportEnum, file);

	//session
	newXS("Win32::Lanman::NetSessionDel", XS_NT__Lanman_NetSessionDel, file);
	newXS("Win32::Lanman::NetSessionEnum", XS_NT__Lanman_NetSessionEnum, file);
	newXS("Win32::Lanman::NetSessionGetInfo", XS_NT__Lanman_NetSessionGetInfo, file);

	// share
	newXS("Win32::Lanman::NetShareAdd", XS_NT__Lanman_NetShareAdd, file);
	newXS("Win32::Lanman::NetShareCheck", XS_NT__Lanman_NetShareCheck, file);
	newXS("Win32::Lanman::NetShareDel", XS_NT__Lanman_NetShareDel, file);
	newXS("Win32::Lanman::NetShareEnum", XS_NT__Lanman_NetShareEnum, file);
	newXS("Win32::Lanman::NetShareGetInfo", XS_NT__Lanman_NetShareGetInfo, file);
	newXS("Win32::Lanman::NetShareSetInfo", XS_NT__Lanman_NetShareSetInfo, file);
	newXS("Win32::Lanman::NetConnectionEnum", XS_NT__Lanman_NetConnectionEnum, file);

	// user
	newXS("Win32::Lanman::NetUserAdd", XS_NT__Lanman_NetUserAdd, file);
	newXS("Win32::Lanman::NetUserChangePassword", 
				XS_NT__Lanman_NetUserChangePassword, file);
	newXS("Win32::Lanman::NetUserDel", XS_NT__Lanman_NetUserDel, file);
	newXS("Win32::Lanman::NetUserEnum", XS_NT__Lanman_NetUserEnum, file);
	newXS("Win32::Lanman::NetUserGetGroups", XS_NT__Lanman_NetUserGetGroups, file);
	newXS("Win32::Lanman::NetUserGetInfo", XS_NT__Lanman_NetUserGetInfo, file);
	newXS("Win32::Lanman::NetUserGetLocalGroups", 
				XS_NT__Lanman_NetUserGetLocalGroups, file);
	newXS("Win32::Lanman::NetUserSetGroups", XS_NT__Lanman_NetUserSetGroups, file);
	newXS("Win32::Lanman::NetUserSetInfo", XS_NT__Lanman_NetUserSetInfo, file);
	newXS("Win32::Lanman::NetUserSetProp", XS_NT__Lanman_NetUserSetProp, file);
	newXS("Win32::Lanman::NetUserModalsGet", XS_NT__Lanman_NetUserModalsGet, file);
	newXS("Win32::Lanman::NetUserModalsSet", XS_NT__Lanman_NetUserModalsSet, file);
	newXS("Win32::Lanman::NetUserCheckPassword", XS_NT__Lanman_NetUserCheckPassword, file);

	// wnetwork
	newXS("Win32::Lanman::WNetAddConnection", XS_NT__Lanman_WNetAddConnection, file);
	newXS("Win32::Lanman::WNetCancelConnection", XS_NT__Lanman_WNetCancelConnection, file);
	newXS("Win32::Lanman::WNetEnumResource", XS_NT__Lanman_WNetEnumResource, file);
	newXS("Win32::Lanman::WNetConnectionDialog", XS_NT__Lanman_WNetConnectionDialog, file);
	newXS("Win32::Lanman::WNetDisconnectDialog", XS_NT__Lanman_WNetDisconnectDialog, file);
	newXS("Win32::Lanman::WNetGetConnection", XS_NT__Lanman_WNetGetConnection, file);
	newXS("Win32::Lanman::WNetGetNetworkInformation", XS_NT__Lanman_WNetGetNetworkInformation, file);
	newXS("Win32::Lanman::WNetGetProviderName", XS_NT__Lanman_WNetGetProviderName, file);
	
	newXS("Win32::Lanman::WNetGetResourceInformation", XS_NT__Lanman_WNetGetResourceInformation, file);
	newXS("Win32::Lanman::WNetGetResourceParent", XS_NT__Lanman_WNetGetResourceParent, file);
	newXS("Win32::Lanman::WNetGetUniversalName", XS_NT__Lanman_WNetGetUniversalName, file);

	newXS("Win32::Lanman::WNetGetUser", XS_NT__Lanman_WNetGetUser, file);
	newXS("Win32::Lanman::WNetUseConnection", XS_NT__Lanman_WNetUseConnection, file);

	// workstation
	newXS("Win32::Lanman::NetWkstaGetInfo", XS_NT__Lanman_NetWkstaGetInfo, file);
	newXS("Win32::Lanman::NetWkstaSetInfo", XS_NT__Lanman_NetWkstaSetInfo, file);
	newXS("Win32::Lanman::NetWkstaTransportAdd", XS_NT__Lanman_NetWkstaTransportAdd, file);
	newXS("Win32::Lanman::NetWkstaTransportDel", XS_NT__Lanman_NetWkstaTransportDel, file);
	newXS("Win32::Lanman::NetWkstaTransportEnum", 
				XS_NT__Lanman_NetWkstaTransportEnum, file);
	newXS("Win32::Lanman::NetWkstaUserGetInfo", XS_NT__Lanman_NetWkstaUserGetInfo, file);
	newXS("Win32::Lanman::NetWkstaUserSetInfo", XS_NT__Lanman_NetWkstaUserSetInfo, file);
	newXS("Win32::Lanman::NetWkstaUserEnum", XS_NT__Lanman_NetWkstaUserEnum, file);

	// use
	newXS("Win32::Lanman::NetUseAdd", XS_NT__Lanman_NetUseAdd, file);
	newXS("Win32::Lanman::NetUseDel", XS_NT__Lanman_NetUseDel, file);
	newXS("Win32::Lanman::NetUseEnum", XS_NT__Lanman_NetUseEnum, file);
	newXS("Win32::Lanman::NetUseGetInfo", XS_NT__Lanman_NetUseGetInfo, file);

	// lsa
	newXS("Win32::Lanman::GrantPrivilegeToAccount", 
				XS_NT__Lanman_GrantPrivilegeToAccount, file);
	newXS("Win32::Lanman::RevokePrivilegeFromAccount", 
				XS_NT__Lanman_RevokePrivilegeFromAccount, file);
	newXS("Win32::Lanman::EnumAccountPrivileges", 
				XS_NT__Lanman_EnumAccountPrivileges, file);
	newXS("Win32::Lanman::EnumPrivilegeAccounts", 
				XS_NT__Lanman_EnumPrivilegeAccounts, file);
	newXS("Win32::Lanman::LsaQueryInformationPolicy", 
				XS_NT__Lanman_LsaQueryInformationPolicy, file);
	newXS("Win32::Lanman::LsaSetInformationPolicy", 
				XS_NT__Lanman_LsaSetInformationPolicy, file);
	newXS("Win32::Lanman::LsaEnumerateTrustedDomains", 
				XS_NT__Lanman_LsaEnumerateTrustedDomains, file);
	newXS("Win32::Lanman::LsaLookupNames", XS_NT__Lanman_LsaLookupNames, file);
	newXS("Win32::Lanman::LsaLookupNamesEx", XS_NT__Lanman_LsaLookupNamesEx, file);
	newXS("Win32::Lanman::LsaLookupSids", XS_NT__Lanman_LsaLookupSids, file);
	newXS("Win32::Lanman::LsaEnumerateAccountsWithUserRight", 
				XS_NT__Lanman_LsaEnumerateAccountsWithUserRight, file);
	newXS("Win32::Lanman::LsaEnumerateAccountRights", 
				XS_NT__Lanman_LsaEnumerateAccountRights, file);
	newXS("Win32::Lanman::LsaAddAccountRights", XS_NT__Lanman_LsaAddAccountRights, file);
	newXS("Win32::Lanman::LsaRemoveAccountRights", 
				XS_NT__Lanman_LsaRemoveAccountRights, file);
	newXS("Win32::Lanman::LsaQueryTrustedDomainInfo", 
				XS_NT__Lanman_LsaQueryTrustedDomainInfo, file);
	newXS("Win32::Lanman::LsaSetTrustedDomainInformation", 
				XS_NT__Lanman_LsaSetTrustedDomainInformation, file);
	newXS("Win32::Lanman::LsaRetrievePrivateData", XS_NT__Lanman_LsaRetrievePrivateData, file);
	newXS("Win32::Lanman::LsaStorePrivateData", XS_NT__Lanman_LsaStorePrivateData, file);

	// services
	newXS("Win32::Lanman::StartService", XS_NT__Lanman_StartService, file);
	newXS("Win32::Lanman::StopService", XS_NT__Lanman_StopService, file);
	newXS("Win32::Lanman::PauseService", XS_NT__Lanman_PauseService, file);
	newXS("Win32::Lanman::ContinueService", XS_NT__Lanman_ContinueService, file);
	newXS("Win32::Lanman::InterrogateService", XS_NT__Lanman_InterrogateService, file);
	newXS("Win32::Lanman::ControlService", XS_NT__Lanman_ControlService, file);
	newXS("Win32::Lanman::CreateService", XS_NT__Lanman_CreateService, file);
	newXS("Win32::Lanman::DeleteService", XS_NT__Lanman_DeleteService, file);
	newXS("Win32::Lanman::EnumServicesStatus", XS_NT__Lanman_EnumServicesStatus, file);
	newXS("Win32::Lanman::EnumDependentServices", 
				XS_NT__Lanman_EnumDependentServices, file);
	newXS("Win32::Lanman::ChangeServiceConfig", XS_NT__Lanman_ChangeServiceConfig, file);
	newXS("Win32::Lanman::GetServiceDisplayName", 
				XS_NT__Lanman_GetServiceDisplayName, file);
	newXS("Win32::Lanman::GetServiceKeyName", XS_NT__Lanman_GetServiceKeyName, file);
	newXS("Win32::Lanman::LockServiceDatabase", XS_NT__Lanman_LockServiceDatabase, file);
	newXS("Win32::Lanman::UnlockServiceDatabase", 
				XS_NT__Lanman_UnlockServiceDatabase, file);
	newXS("Win32::Lanman::QueryServiceLockStatus", 
				XS_NT__Lanman_QueryServiceLockStatus, file);
	newXS("Win32::Lanman::QueryServiceConfig", XS_NT__Lanman_QueryServiceConfig, file);
	newXS("Win32::Lanman::QueryServiceStatus", XS_NT__Lanman_QueryServiceStatus, file);
	newXS("Win32::Lanman::QueryServiceObjectSecurity", 
				XS_NT__Lanman_QueryServiceObjectSecurity, file);
	newXS("Win32::Lanman::SetServiceObjectSecurity", 
				XS_NT__Lanman_SetServiceObjectSecurity, file);

	// eventlog
	newXS("Win32::Lanman::ReadEventLog", XS_NT__Lanman_ReadEventLog, file);
	newXS("Win32::Lanman::GetEventDescription", XS_NT__Lanman_GetEventDescription, file);
	newXS("Win32::Lanman::BackupEventLog", XS_NT__Lanman_BackupEventLog, file);
	newXS("Win32::Lanman::ClearEventLog", XS_NT__Lanman_ClearEventLog, file);
	newXS("Win32::Lanman::ReportEvent", XS_NT__Lanman_ReportEvent, file);
	newXS("Win32::Lanman::GetNumberOfEventLogRecords", 
				XS_NT__Lanman_GetNumberOfEventLogRecords, file);
	newXS("Win32::Lanman::GetOldestEventLogRecord", 
				XS_NT__Lanman_GetOldestEventLogRecord, file);
	newXS("Win32::Lanman::NotifyChangeEventLog", 
				XS_NT__Lanman_NotifyChangeEventLog, file);
		
	// wts
	newXS("Win32::Lanman::WTSEnumerateServers", XS_NT__Lanman_WTSEnumerateServers, file);
	newXS("Win32::Lanman::WTSOpenServer", XS_NT__Lanman_WTSOpenServer, file);
	newXS("Win32::Lanman::WTSCloseServer", XS_NT__Lanman_WTSCloseServer, file);
	newXS("Win32::Lanman::WTSEnumerateSessions", 
				XS_NT__Lanman_WTSEnumerateSessions, file);
	newXS("Win32::Lanman::WTSEnumerateProcesses", 
				XS_NT__Lanman_WTSEnumerateProcesses, file);
	newXS("Win32::Lanman::WTSTerminateProcess", 
				XS_NT__Lanman_WTSTerminateProcess, file);
	newXS("Win32::Lanman::WTSQuerySessionInformation", 
				XS_NT__Lanman_WTSQuerySessionInformation, file);
	newXS("Win32::Lanman::WTSQueryUserConfig", XS_NT__Lanman_WTSQueryUserConfig, file);
	newXS("Win32::Lanman::WTSSetUserConfig", XS_NT__Lanman_WTSSetUserConfig, file);
	newXS("Win32::Lanman::WTSSendMessage", XS_NT__Lanman_WTSSendMessage, file);
	newXS("Win32::Lanman::WTSDisconnectSession", 
				XS_NT__Lanman_WTSDisconnectSession, file);
	newXS("Win32::Lanman::WTSLogoffSession", XS_NT__Lanman_WTSLogoffSession, file);
	newXS("Win32::Lanman::WTSShutdownSystem", XS_NT__Lanman_WTSShutdownSystem, file);
	newXS("Win32::Lanman::WTSWaitSystemEvent", XS_NT__Lanman_WTSWaitSystemEvent, file);

	// ds (w2k)
	newXS("Win32::Lanman::NetGetJoinableOUs", XS_NT__Lanman_NetGetJoinableOUs, file);
	newXS("Win32::Lanman::NetGetJoinInformation", 
				XS_NT__Lanman_NetGetJoinInformation, file);
	newXS("Win32::Lanman::NetJoinDomain", XS_NT__Lanman_NetJoinDomain, file);
	newXS("Win32::Lanman::NetRenameMachineInDomain", 
				XS_NT__Lanman_NetRenameMachineInDomain, file);
	newXS("Win32::Lanman::NetUnjoinDomain", XS_NT__Lanman_NetUnjoinDomain, file);
	newXS("Win32::Lanman::NetValidateName", XS_NT__Lanman_NetValidateName, file);
	newXS("Win32::Lanman::NetRegisterDomainNameChangeNotification", 
				XS_NT__Lanman_NetRegisterDomainNameChangeNotification, file);
	newXS("Win32::Lanman::NetUnregisterDomainNameChangeNotification", 
				XS_NT__Lanman_NetUnregisterDomainNameChangeNotification, file);

	// dfs (w2k)
	newXS("Win32::Lanman::NetDfsAddFtRoot", XS_NT__Lanman_NetDfsAddFtRoot, file);
	newXS("Win32::Lanman::NetDfsRemoveFtRoot", XS_NT__Lanman_NetDfsRemoveFtRoot, file);
	newXS("Win32::Lanman::NetDfsRemoveFtRootForced", 
				XS_NT__Lanman_NetDfsRemoveFtRootForced, file);
	newXS("Win32::Lanman::NetDfsAddStdRoot", XS_NT__Lanman_NetDfsAddStdRoot, file);
	newXS("Win32::Lanman::NetDfsAddStdRootForced", 
				XS_NT__Lanman_NetDfsAddStdRootForced, file);
	newXS("Win32::Lanman::NetDfsRemoveStdRoot", XS_NT__Lanman_NetDfsRemoveStdRoot, file);
	newXS("Win32::Lanman::NetDfsManagerInitialize", 
				XS_NT__Lanman_NetDfsManagerInitialize, file);
	newXS("Win32::Lanman::NetDfsGetClientInfo", XS_NT__Lanman_NetDfsGetClientInfo, file);
	newXS("Win32::Lanman::NetDfsSetClientInfo", XS_NT__Lanman_NetDfsSetClientInfo, file);
	newXS("Win32::Lanman::NetDfsGetDcAddress", XS_NT__Lanman_NetDfsGetDcAddress, file);

	// services (w2k)
	newXS("Win32::Lanman::ChangeServiceConfig2", XS_NT__Lanman_ChangeServiceConfig2, file);
	newXS("Win32::Lanman::QueryServiceConfig2", XS_NT__Lanman_QueryServiceConfig2, file);
	newXS("Win32::Lanman::QueryServiceStatusEx", XS_NT__Lanman_QueryServiceStatusEx, file);
	newXS("Win32::Lanman::EnumServicesStatusEx", XS_NT__Lanman_EnumServicesStatusEx, file);

	ST(0) = &PL_sv_yes;
	
	XSRETURN(1);
}

///////////////////////////////////////////////////////////////////////////////
//
// library main function; there are no special things to do
//
///////////////////////////////////////////////////////////////////////////////

BOOL WINAPI DllMain(HINSTANCE  hinstDLL, DWORD reason, LPVOID  reserved)
{
	BOOL result = 1;

	switch(reason)
	{
		case DLL_PROCESS_ATTACH:
			if((LastErrorTlsIndex = TlsAlloc()) == TLS_OUT_OF_INDEXES)
				return 0;
			
//			CARE_INIT_CRIT_SECT(&LastErrorCritSection);
			
			InitAddDlls();
			InitWTSDll();
			break;

		case DLL_THREAD_ATTACH:
			break;

		case DLL_THREAD_DETACH:
			break;
			
		case DLL_PROCESS_DETACH:
			ReleaseAddDlls();
			ReleaseWTSDll();

//			CARE_DEL_CRIT_SECT(&LastErrorCritSection);
			
			TlsFree(LastErrorTlsIndex);
			break;
	}

	return result;
}

