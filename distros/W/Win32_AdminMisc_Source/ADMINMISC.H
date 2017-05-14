	//	Begin resource compiler macro block

#define VERSION			"980511"		

#define	EXTENSION_NAMESPACE		"Win32"
#define	EXTENSION_NAME			"AdminMisc"
#define	EXTENSION_FILE_NAME		EXTENSION_NAME

#define	EXTENSION_VERSION		VERSION
#define	EXTENSION_AUTHOR		"Dave Roth <rothd@roth.net>"

#define	COPYRIGHT_YEAR			"1996 - 1998"
#define	COPYRIGHT_NOTICE		"Copyright (c) " COPYRIGHT_YEAR

#define COMPANY_NAME			"Roth Consulting\r\nhttp://www.roth.net/consult"

#define	VERSION_TYPE			"Release"
	//	End resource compiler macro block


#ifdef _ADMINMISC_H_

	#ifdef	PERL_OBJECT
		#define		PERL_OBJECT_PROTO	CPerl *pPerl,
		#define		PERL_OBJECT_ARG		pPerl,
	#else	//	PERL_OBJECT
		#define		PERL_OBJECT_PROTO	
		#define		PERL_OBJECT_ARG		
	#endif	//	PERL_OBJECT


	#define	EXTENSION				EXTENSION_NAMESPACE "::" EXTENSION_NAME

	#define	ENV_SYSTEM				0x00
	#define	ENV_USER				0x01

	#define	ENV_MODIFY				0x10
	#define	ENV_DELETE				0x11
	#define	ENV_QUERY				0x12

	#define	ENV_BUFFER_SIZE			1024
	#define	ENV_SYSTEM_PATH			"SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment"
	#define	ENV_USER_PATH			"Environment"


	#define RETURNRESULT(x)		if((x)){ XST_mYES(0); }\
	                     		else { XST_mNO(0); }\
	                     		XSRETURN(1)

	#define	TOTAL_ACCOUNT_INFO	29		//	0-28
	#define	TMP_BUFFER_SIZE		512		//	Temporary buffer for Unicode->ANSI conversion

	#define	ACCT_BYTE		01
	#define	ACCT_NUMBER		02
	#define	ACCT_STRING		03

	#define GROUP_TYPE_ALL		0x00
	#define GROUP_TYPE_LOCAL	0x01
	#define GROUP_TYPE_GLOBAL	0x02

	#define SETIV(index,value) sv_setiv(ST(index), value)
	#define SETPV(index,string) sv_setpv(ST(index), string)

		//	For the LSA stuff
	#ifndef	STATUS_SUCCESS
		#define	STATUS_SUCCESS	((NTSTATUS) 0x00000000L)
	#endif


	HINSTANCE	ghDLL;
	int			iWinsockActive = 0;
	int			wsErrorStatus;
	WSADATA		wsaData;
	DWORD		gdTlsSlot;

	char	*AccountInfoName[] = 
			{
			"USER_NAME",		  		//		0
			"USER_PASSWORD",			//		1
			"USER_PASSWORD_AGE",		//		2
			"USER_PRIV",				//		3
			"USER_HOME_DIR",			//		4
			"USER_COMMENT",				//		5
			"USER_FLAGS",				//		6
			"USER_SCRIPT_PATH",			//		7
			"USER_AUTH_FLAGS",			//		8
			"USER_FULL_NAME",			//		9
			"USER_USR_COMMENT",			//		10
			"USER_PARMS",				//		11
			"USER_WORKSTATIONS",		//		12
			"USER_LAST_LOGON",			//		13
			"USER_LAST_LOGOFF",			//		14
			"USER_ACCT_EXPIRES",		//		15
			"USER_MAX_STORAGE",			//		16
			"USER_UNITS_PER_WEEK",		//		17
			"USER_LOGON_HOURS",			//		18
			"USER_BAD_PW_COUNT",		//		19
			"USER_NUM_LOGONS",			//		20
			"USER_LOGON_SERVER",		//		21
			"USER_COUNTRY_CODE",		//		22
			"USER_CODE_PAGE",			//		23
			"USER_USER_ID",				//		24
			"USER_PRIMARY_GROUP_ID",	//		25
			"USER_PROFILE",				//		26
			"USER_HOME_DIR_DRIVE",		//		27
			"USER_PASSWORD_EXPIRED"		//		28
			};


	DWORD CreateNewProcess( PERL_OBJECT_PROTO BOOL bCreateAsUser );

#else

	extern	HINSTANCE	ghDLL;
	extern	int			iWinsockActive;
	extern	int			wsErrorStatus;
	extern	WSADATA		wsaData;
	extern	char	*AccountInfoName[];

#endif

	DWORD ChangePassword(char *szDomain, char *szUser, char *szOldPassword, char *szNewPassword);
	BOOL WINAPI DllMain(HINSTANCE  hinstDLL, DWORD fdwReason, LPVOID  lpvReserved);
	char *GetDC(char *szName, BOOL bPDC, BOOL bOnlyDC);
	BOOL  MapNameToConstant(char *szString, DWORD *dValue);
	void GetUserAndDomain(char *szString, char *szDomain, char *szUser);
	DWORD ResolveStringToSeconds(char *szTime);
	DWORD ResolveNumToSeconds(DWORD dTime);
	char *ResolveFromSeconds(DWORD dTime);
	BOOL ProcessEnvVar(int iFunction, int iType, char *szName, char *szValue, DWORD dTime);
	BOOL FixPath( char *pszPath );

