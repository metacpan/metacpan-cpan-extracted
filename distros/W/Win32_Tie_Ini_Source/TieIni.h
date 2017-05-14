#ifdef	PERL_OBJECT
	#define		PERL_OBJECT_PROTO	CPerl *pPerl,
	#define		PERL_OBJECT_ARG		pPerl,
#else	//	PERL_OBJECT
	#define		PERL_OBJECT_PROTO	
	#define		PERL_OBJECT_ARG		
#endif	//	PERL_OBJECT



#define VERSION		"980311"		



	//	Begin resource compiler macro block
#define	EXTENSION_NAMESPACE		"Win32::Tie"
#define	EXTENSION_NAME			"Ini"
#define	EXTENSION_FILE_NAME		EXTENSION_NAME

#define	EXTENSION_VERSION		VERSION
#define	EXTENSION_AUTHOR		"Dave Roth <rothd@roth.net>"

#define	COPYRIGHT_YEAR			"1998"
#define	COPYRIGHT_NOTICE		"Copyright (c) " COPYRIGHT_YEAR

#define COMPANY_NAME			"Roth Consulting\r\nhttp://www.roth.net/consult"

#define	VERSION_TYPE			"Release"
	//	End resource compiler macro block

		
#define	KEYWORD_FILE	"..~~" EXTENSION_NAMESPACE " RequestFile~~.."
#define	KEYWORD_SECTION	"..~~" EXTENSION_NAMESPACE " RequestSection~~.."
#define	KEYWORD_ARRAY	"..~~" EXTENSION_NAMESPACE " RequestArray~~.."

#define	BUFFER_SIZE		4096	

#define RETURNRESULT(x)		if((x)){ XST_mYES(0); }\
	                     		else { XST_mNO(0); }\
	                     		XSRETURN(1)


#define SETIV(index,value) sv_setiv(ST(index), value)
#define SETPV(index,string) sv_setpv(ST(index), string)

	//	For the LSA stuff
#ifndef	STATUS_SUCCESS
	#define	STATUS_SUCCESS	((NTSTATUS) 0x00000000L)
#endif


	HINSTANCE	ghDLL;
	DWORD		gdTlsSlot;

	BOOL WINAPI DllMain(HINSTANCE  hinstDLL, DWORD fdwReason, LPVOID  lpvReserved);
	static char *constant(PERL_OBJECT_PROTO char *szConst);
	HV *MakeMagicHash( PERL_OBJECT_PROTO SV* svBasedOn, char *szNameSpace);
	SV *MakeMagicSectionHash( PERL_OBJECT_PROTO char *szFile, char *szSection);
	void FixPath( char *szPath );
