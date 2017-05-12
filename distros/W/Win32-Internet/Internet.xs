/*
 * Internet.CPP
 * 07 Nov 96 by Aldo Calpini <dada@perl.it>
 *
 * XS interface to the Win32 Internet Functions (WININET.DLL)
 * based on Registry.CPP written by Jesse Dougherty
 *
 * Version: 0.083 15 Apr 2008
 *
 */

// Basic includes
#define  WIN32_LEAN_AND_MEAN
// #include <math.h>
#include <windows.h>

// Extension specific includes
#include <wininet.h>
#include <winver.h>

#define __TEMP_WORD  WORD	/* perl defines a WORD, yikes! */

// Perl includes
#if (defined(__cplusplus) && !defined(PERL_OBJECT))
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#if (defined(__cplusplus) && !defined(PERL_OBJECT))
}
#endif

#undef WORD
#define WORD __TEMP_WORD

#ifndef PERL_VERSION
#  include "patchlevel.h"
#  define PERL_REVISION		5
#  define PERL_VERSION		PATCHLEVEL
#  define PERL_SUBVERSION	SUBVERSION
#endif

#if PERL_REVISION == 5 && (PERL_VERSION < 4 || \
			   (PERL_VERSION == 4 && PERL_SUBVERSION <= 75))
#  define PL_sv_undef		sv_undef
#  define PL_sv_yes		sv_yes
#  define PL_sv_no		sv_no
#  define PL_na			na
#  define PL_dowarn		dowarn
#endif

// Section for the constant definitions.
#define CROAK croak
#define MAX_LENGTH 2048
#define TMPBUFSZ 1024

// VALUES FILLED IN BY PerlCallback
DWORD status = -1;

static time_t ft2timet(FILETIME *ft)
{
	SYSTEMTIME st;
	struct tm tm;

	FileTimeToSystemTime(ft, &st);
	tm.tm_sec = st.wSecond;
	tm.tm_min = st.wMinute;
	tm.tm_hour = st.wHour;
	tm.tm_mday = st.wDay;
	tm.tm_mon = st.wMonth - 1;
	tm.tm_year = st.wYear - 1900;
	tm.tm_wday = st.wDayOfWeek;
	tm.tm_yday = -1;
	tm.tm_isdst = -1;
	return mktime (&tm);
}

#define SUCCESSRETURNED(x)	(x == ERROR_SUCCESS)
#define INETRETURN(x) XSRETURN_IV(SUCCESSRETURNED(x))

#ifndef XST_mPVn
#define XST_mPVn(i,v,n)  (ST(i) = sv_2mortal(newSVpv((v),(n))))
#endif

DWORD
constant(char *name, int arg) {
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
		break;
    case 'G':
		break;
    case 'H':
		if(strncmp(name, "HTTP_", 5) == 0)
			switch(name[5]) {
			case 'A':
				if (strEQ(name, "HTTP_ADDREQ_FLAG_ADD"))
					#ifdef HTTP_ADDREQ_FLAG_ADD
						return HTTP_ADDREQ_FLAG_ADD;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "HTTP_ADDREQ_FLAG_REPLACE"))
					#ifdef HTTP_ADDREQ_FLAG_REPLACE
						return HTTP_ADDREQ_FLAG_REPLACE;
					#else
						goto not_there;
					#endif
				break;
			case 'Q':
				if(strncmp(name, "HTTP_QUERY_", 11) == 0)
					switch(name[11]) {
					case 'A':
						if (strEQ(name, "HTTP_QUERY_ALLOW"))
							#ifdef HTTP_QUERY_ALLOW
								return HTTP_QUERY_ALLOW;
							#else
								goto not_there;
							#endif
						break;
					case 'C':
						if (strEQ(name, "HTTP_QUERY_CONTENT_DESCRIPTION"))
							#ifdef HTTP_QUERY_CONTENT_DESCRIPTION
								return HTTP_QUERY_CONTENT_DESCRIPTION;
							#else
								goto not_there;
							#endif
						if (strEQ(name, "HTTP_QUERY_CONTENT_ID"))
							#ifdef HTTP_QUERY_CONTENT_ID
								return HTTP_QUERY_CONTENT_ID;
							#else
								goto not_there;
							#endif
						if (strEQ(name, "HTTP_QUERY_CONTENT_LENGTH"))
							#ifdef HTTP_QUERY_CONTENT_LENGTH
								return HTTP_QUERY_CONTENT_LENGTH;
							#else
								goto not_there;
							#endif
						if (strEQ(name, "HTTP_QUERY_CONTENT_TRANSFER_ENCODING"))
							#ifdef HTTP_QUERY_CONTENT_TRANSFER_ENCODING
								return HTTP_QUERY_CONTENT_TRANSFER_ENCODING;
							#else
								goto not_there;
							#endif
						if (strEQ(name, "HTTP_QUERY_CONTENT_TYPE"))
							#ifdef HTTP_QUERY_CONTENT_TYPE
								return HTTP_QUERY_CONTENT_TYPE;
							#else
								goto not_there;
							#endif
						if (strEQ(name, "HTTP_QUERY_COST"))
							#ifdef HTTP_QUERY_COST
								return HTTP_QUERY_COST;
							#else
								goto not_there;
							#endif
						if (strEQ(name, "HTTP_QUERY_CUSTOM"))
							#ifdef HTTP_QUERY_CUSTOM
								return HTTP_QUERY_CUSTOM;
							#else
								goto not_there;
							#endif
						break;
					case 'D':
						if (strEQ(name, "HTTP_QUERY_DATE"))
							#ifdef HTTP_QUERY_DATE
								return HTTP_QUERY_DATE;
							#else
								goto not_there;
							#endif
						if (strEQ(name, "HTTP_QUERY_DERIVED_FROM"))
							#ifdef HTTP_QUERY_DERIVED_FROM
								return HTTP_QUERY_DERIVED_FROM;
							#else
								goto not_there;
							#endif
						break;
					case 'E':
						if (strEQ(name, "HTTP_QUERY_EXPIRES"))
							#ifdef HTTP_QUERY_EXPIRES
								return HTTP_QUERY_EXPIRES;
							#else
								goto not_there;
							#endif
						break;
					case 'F':
						if (strEQ(name, "HTTP_QUERY_FLAG_REQUEST_HEADERS"))
							#ifdef HTTP_QUERY_FLAG_REQUEST_HEADERS
								return HTTP_QUERY_FLAG_REQUEST_HEADERS;
							#else
								goto not_there;
							#endif
						if (strEQ(name, "HTTP_QUERY_FLAG_SYSTEMTIME"))
							#ifdef HTTP_QUERY_FLAG_SYSTEMTIME
								return HTTP_QUERY_FLAG_SYSTEMTIME;
							#else
								goto not_there;
							#endif
						break;
					case 'L':
						if (strEQ(name, "HTTP_QUERY_LANGUAGE"))
							#ifdef HTTP_QUERY_LANGUAGE
								return HTTP_QUERY_LANGUAGE;
							#else
								goto not_there;
							#endif
						if (strEQ(name, "HTTP_QUERY_LAST_MODIFIED"))
							#ifdef HTTP_QUERY_LAST_MODIFIED
								return HTTP_QUERY_LAST_MODIFIED;
							#else
								goto not_there;
							#endif
						break;
					case 'M':
						if (strEQ(name, "HTTP_QUERY_MESSAGE_ID"))
							#ifdef HTTP_QUERY_MESSAGE_ID
								return HTTP_QUERY_MESSAGE_ID;
							#else
								goto not_there;
							#endif
						if (strEQ(name, "HTTP_QUERY_MIME_VERSION"))
							#ifdef HTTP_QUERY_MIME_VERSION
								return HTTP_QUERY_MIME_VERSION;
							#else
								goto not_there;
							#endif
						break;
					case 'P':
						if (strEQ(name, "HTTP_QUERY_PRAGMA"))
							#ifdef HTTP_QUERY_PRAGMA
								return HTTP_QUERY_PRAGMA;
							#else
								goto not_there;
							#endif
						if (strEQ(name, "HTTP_QUERY_PUBLIC"))
							#ifdef HTTP_QUERY_PUBLIC
								return HTTP_QUERY_PUBLIC;
							#else
								goto not_there;
							#endif
						break;
					case 'R':
						if (strEQ(name, "HTTP_QUERY_RAW_HEADERS"))
							#ifdef HTTP_QUERY_RAW_HEADERS
								return HTTP_QUERY_RAW_HEADERS;
							#else
								goto not_there;
							#endif
						if (strEQ(name, "HTTP_QUERY_RAW_HEADERS_CRLF"))
							#ifdef HTTP_QUERY_RAW_HEADERS_CRLF
								return HTTP_QUERY_RAW_HEADERS_CRLF;
							#else
								goto not_there;
							#endif
						if (strEQ(name, "HTTP_QUERY_REQUEST_METHOD"))
							#ifdef HTTP_QUERY_REQUEST_METHOD
								return HTTP_QUERY_REQUEST_METHOD;
							#else
								goto not_there;
							#endif
						break;
					case 'S':
						if (strEQ(name, "HTTP_QUERY_SERVER"))
							#ifdef HTTP_QUERY_SERVER
								return HTTP_QUERY_SERVER;
							#else
								goto not_there;
							#endif
						if (strEQ(name, "HTTP_QUERY_STATUS_CODE"))
							#ifdef HTTP_QUERY_STATUS_CODE
								return HTTP_QUERY_STATUS_CODE;
							#else
								goto not_there;
							#endif
						if (strEQ(name, "HTTP_QUERY_STATUS_TEXT"))
							#ifdef HTTP_QUERY_STATUS_TEXT
								return HTTP_QUERY_STATUS_TEXT;
							#else
								goto not_there;
							#endif
						break;
					case 'U':
						if (strEQ(name, "HTTP_QUERY_URI"))
							#ifdef HTTP_QUERY_URI
								return HTTP_QUERY_URI;
							#else
								goto not_there;
							#endif
						if (strEQ(name, "HTTP_QUERY_USER_AGENT"))
							#ifdef HTTP_QUERY_USER_AGENT
								return HTTP_QUERY_USER_AGENT;
							#else
								goto not_there;
							#endif
						break;
					case 'V':
						if (strEQ(name, "HTTP_QUERY_VERSION"))
							#ifdef HTTP_QUERY_VERSION
								return HTTP_QUERY_VERSION;
							#else
								goto not_there;
							#endif
						break;
					case 'W':
						if (strEQ(name, "HTTP_QUERY_WWW_LINK"))
							#ifdef HTTP_QUERY_WWW_LINK
								return HTTP_QUERY_WWW_LINK;
							#else
								goto not_there;
							#endif
						break;
					}
				break;
			}
		break;
    case 'I':
		if(strncmp(name, "ICU_", 4) == 0)
			switch(name[4]) {
			case 'B':
				if(strEQ(name, "ICU_BROWSER_MODE")) 
					#ifdef ICU_BROWSER_MODE
						return ICU_BROWSER_MODE;
					#else
						goto not_there;
					#endif
				break;
			case 'D':
				if(strEQ(name, "ICU_DECODE"))
					#ifdef ICU_DECODE
						return ICU_DECODE;
					#else
						goto not_there;
					#endif
				break;
			case 'E':
				if(strEQ(name, "ICU_ENCODE_SPACES_ONLY")) 
					#ifdef ICU_ENCODE_SPACES_ONLY
						return ICU_ENCODE_SPACES_ONLY;
					#else
						goto not_there;
					#endif
				if(strEQ(name, "ICU_ESCAPE")) 
					#ifdef ICU_ESCAPE
						return ICU_ESCAPE;
					#else
						goto not_there;
					#endif
				break;
			case 'N':
				if(strEQ(name, "ICU_NO_ENCODE")) 
					#ifdef ICU_NO_ENCODE
						return ICU_NO_ENCODE;
					#else
						goto not_there;
					#endif
				if(strEQ(name, "ICU_NO_META")) 
					#ifdef ICU_NO_META
						return ICU_NO_META;
					#else
						goto not_there;
					#endif
				break;
			case 'U':
				if(strEQ(name, "ICU_USERNAME")) 
					#ifdef ICU_USERNAME
						return ICU_USERNAME;
					#else
						goto not_there;
					#endif
				break;
			}
		if(strncmp(name, "INTERNET_", 9) == 0)
			switch(name[9]) {
			case 'F':
				if(strEQ(name, "INTERNET_FLAG_PASSIVE"))
					#ifdef INTERNET_FLAG_PASSIVE
						return INTERNET_FLAG_PASSIVE;
					#else
						goto not_there;
					#endif
				if(strEQ(name, "INTERNET_FLAG_ASYNC"))
					#ifdef INTERNET_FLAG_ASYNC
						return INTERNET_FLAG_ASYNC;
					#else
						goto not_there;
					#endif
				if(strEQ(name, "INTERNET_FLAG_HYPERLINK"))
					#ifdef INTERNET_FLAG_HYPERLINK
						return INTERNET_FLAG_HYPERLINK;
					#else
						goto not_there;
					#endif
				if(strEQ(name, "INTERNET_FLAG_KEEP_CONNECTION"))
					#ifdef INTERNET_FLAG_KEEP_CONNECTION
						return INTERNET_FLAG_KEEP_CONNECTION;
					#else
						goto not_there;
					#endif
				if(strEQ(name, "INTERNET_FLAG_MAKE_PERSISTENT"))
					#ifdef INTERNET_FLAG_MAKE_PERSISTENT
						return INTERNET_FLAG_MAKE_PERSISTENT;
					#else
						goto not_there;
					#endif
				if(strEQ(name, "INTERNET_FLAG_NO_AUTH"))
					#ifdef INTERNET_FLAG_NO_AUTH
						return INTERNET_FLAG_NO_AUTH;
					#else
						goto not_there;
					#endif
				if(strEQ(name, "INTERNET_FLAG_NO_AUTO_REDIRECT"))
					#ifdef INTERNET_FLAG_NO_AUTO_REDIRECT
						return INTERNET_FLAG_NO_AUTO_REDIRECT;
					#else
						goto not_there;
					#endif
				if(strEQ(name, "INTERNET_FLAG_NO_CACHE_WRITE"))
					#ifdef INTERNET_FLAG_NO_CACHE_WRITE
						return INTERNET_FLAG_NO_CACHE_WRITE;
					#else
						goto not_there;
					#endif
				if(strEQ(name, "INTERNET_FLAG_NO_COOKIES"))
					#ifdef INTERNET_FLAG_NO_COOKIES
						return INTERNET_FLAG_NO_COOKIES;
					#else
						goto not_there;
					#endif
				if(strEQ(name, "INTERNET_FLAG_READ_PREFETCH"))
					#ifdef INTERNET_FLAG_READ_PREFETCH
						return INTERNET_FLAG_READ_PREFETCH;
					#else
						goto not_there;
					#endif
				if(strEQ(name, "INTERNET_FLAG_RELOAD"))
					#ifdef INTERNET_FLAG_RELOAD
						return INTERNET_FLAG_RELOAD;
					#else
						goto not_there;
					#endif
				if(strEQ(name, "INTERNET_FLAG_RESYNCHRONIZE"))
					#ifdef INTERNET_FLAG_RESYNCHRONIZE
						return INTERNET_FLAG_RESYNCHRONIZE;
					#else
						goto not_there;
					#endif
				if(strEQ(name, "INTERNET_FLAG_TRANSFER_ASCII"))
					#ifdef INTERNET_FLAG_TRANSFER_ASCII
						return INTERNET_FLAG_TRANSFER_ASCII;
					#else
						goto not_there;
					#endif
				if(strEQ(name, "INTERNET_FLAG_TRANSFER_BINARY"))
					#ifdef INTERNET_FLAG_TRANSFER_BINARY
						return INTERNET_FLAG_TRANSFER_BINARY;
					#else
						goto not_there;
					#endif
				break;
			case 'I':
				if(strEQ(name, "INTERNET_INVALID_PORT_NUMBER"))
					#ifdef INTERNET_INVALID_PORT_NUMBER
						return (DWORD) INTERNET_INVALID_PORT_NUMBER;
					#else
						goto not_there;
					#endif
				if(strEQ(name, "INTERNET_INVALID_STATUS_CALLBACK"))
					#ifdef INTERNET_INVALID_STATUS_CALLBACK
						return (DWORD) INTERNET_INVALID_STATUS_CALLBACK;
					#else
						goto not_there;
					#endif
				break;
			case 'O':
				if(strncmp(name,"INTERNET_OPEN_TYPE_",19) == 0)
					switch(name[19]) {
					case 'D':
						if(strEQ(name, "INTERNET_OPEN_TYPE_DIRECT"))
							#ifdef INTERNET_OPEN_TYPE_DIRECT
								return INTERNET_OPEN_TYPE_DIRECT;
							#else
								goto not_there;
							#endif
						break;
					case 'P':
						if(strEQ(name, "INTERNET_OPEN_TYPE_PROXY"))
							#ifdef INTERNET_OPEN_TYPE_PROXY
								return INTERNET_OPEN_TYPE_PROXY;
							#else
								goto not_there;
							#endif
						if(strEQ(name, "INTERNET_OPEN_TYPE_PROXY_PRECONFIG"))
							#ifdef INTERNET_OPEN_TYPE_PROXY_PRECONFIG
								return INTERNET_OPEN_TYPE_PROXY_PRECONFIG;
							#else
								goto not_there;
							#endif
						break;
					}
				if(strncmp(name,"INTERNET_OPTION_",16) == 0)
					switch(name[16]) {
					case 'C':
						if(strEQ(name, "INTERNET_OPTION_CONNECT_BACKOFF"))
							#ifdef INTERNET_OPTION_CONNECT_BACKOFF
								return INTERNET_OPTION_CONNECT_BACKOFF;
							#else
								goto not_there;
							#endif
						if (strEQ(name, "INTERNET_OPTION_CONNECT_RETRIES"))
							#ifdef INTERNET_OPTION_CONNECT_RETRIES
								return INTERNET_OPTION_CONNECT_RETRIES;
							#else
	    						goto not_there;
							#endif
						if (strEQ(name, "INTERNET_OPTION_CONNECT_TIMEOUT"))
							#ifdef INTERNET_OPTION_CONNECT_TIMEOUT
	    						return INTERNET_OPTION_CONNECT_TIMEOUT;
							#else
	    						goto not_there;
							#endif
						if (strEQ(name, "INTERNET_OPTION_CONTROL_SEND_TIMEOUT"))
							#ifdef INTERNET_OPTION_CONTROL_SEND_TIMEOUT
	    						return INTERNET_OPTION_CONTROL_SEND_TIMEOUT;
							#else
	    						goto not_there;
							#endif
						if (strEQ(name, "INTERNET_OPTION_CONTROL_RECEIVE_TIMEOUT"))
							#ifdef INTERNET_OPTION_CONTROL_RECEIVE_TIMEOUT
	    						return INTERNET_OPTION_CONTROL_RECEIVE_TIMEOUT;
							#else
								goto not_there;
							#endif
						break;
					case 'D':
						if(strEQ(name, "INTERNET_OPTION_DATA_SEND_TIMEOUT"))
							#ifdef INTERNET_OPTION_DATA_SEND_TIMEOUT
								return INTERNET_OPTION_DATA_SEND_TIMEOUT;
							#else
								goto not_there;
							#endif
						if (strEQ(name, "INTERNET_OPTION_DATA_RECEIVE_TIMEOUT"))
								#ifdef INTERNET_OPTION_DATA_RECEIVE_TIMEOUT
									return INTERNET_OPTION_DATA_RECEIVE_TIMEOUT;
								#else
									goto not_there;
								#endif
						break;
					case 'H':
						if(strEQ(name, "INTERNET_OPTION_HANDLE_TYPE"))
							#ifdef INTERNET_OPTION_HANDLE_TYPE
								return INTERNET_OPTION_HANDLE_TYPE;
							#else
								goto not_there;
							#endif
						break;
					case 'L':
						if (strEQ(name, "INTERNET_OPTION_LISTEN_TIMEOUT"))
							#ifdef INTERNET_OPTION_LISTEN_TIMEOUT
								return INTERNET_OPTION_LISTEN_TIMEOUT;
							#else														
								goto not_there;
							#endif
						break;
					case 'P':
						if (strEQ(name, "INTERNET_OPTION_PASSWORD"))
							#ifdef INTERNET_OPTION_PASSWORD
								return INTERNET_OPTION_PASSWORD;
							#else
								goto not_there;
							#endif
						break;
					case 'R':
						if (strEQ(name, "INTERNET_OPTION_READ_BUFFER_SIZE"))
							#ifdef INTERNET_OPTION_READ_BUFFER_SIZE
								return INTERNET_OPTION_READ_BUFFER_SIZE;
							#else
								goto not_there;
							#endif
						break;
					case 'U':
						if (strEQ(name, "INTERNET_OPTION_USERNAME"))
							#ifdef INTERNET_OPTION_USERNAME
								return INTERNET_OPTION_USERNAME;
							#else
								goto not_there;
							#endif
						if (strEQ(name, "INTERNET_OPTION_USER_AGENT"))
							#ifdef INTERNET_OPTION_USER_AGENT
								return INTERNET_OPTION_USER_AGENT;
							#else
								goto not_there;
							#endif
						break;
					case 'V':
						if (strEQ(name, "INTERNET_OPTION_VERSION"))
							#ifdef INTERNET_OPTION_VERSION
								return INTERNET_OPTION_VERSION;
							#else
								goto not_there;
							#endif
						break;
					case 'W':
						if (strEQ(name, "INTERNET_OPTION_WRITE_BUFFER_SIZE"))
							#ifdef INTERNET_OPTION_WRITE_BUFFER_SIZE
								return INTERNET_OPTION_WRITE_BUFFER_SIZE;
							#else
								goto not_there;
							#endif
						break;
					}
				break;
			case 'S':
				if (strEQ(name, "INTERNET_SERVICE_FTP"))
					#ifdef INTERNET_SERVICE_FTP
						return INTERNET_SERVICE_FTP;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "INTERNET_SERVICE_GOPHER"))
					#ifdef INTERNET_SERVICE_GOPHER
						return INTERNET_SERVICE_GOPHER;
					#else
					    goto not_there;
					#endif
				if (strEQ(name, "INTERNET_SERVICE_HTTP"))
					#ifdef INTERNET_SERVICE_HTTP
						return INTERNET_SERVICE_HTTP;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "INTERNET_STATUS_RESOLVING_NAME"))
					#ifdef INTERNET_STATUS_RESOLVING_NAME
						return INTERNET_STATUS_RESOLVING_NAME;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "INTERNET_STATUS_NAME_RESOLVED"))
					#ifdef INTERNET_STATUS_NAME_RESOLVED
						return INTERNET_STATUS_NAME_RESOLVED;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "INTERNET_STATUS_CONNECTING_TO_SERVER"))
					#ifdef INTERNET_STATUS_CONNECTING_TO_SERVER
						return INTERNET_STATUS_CONNECTING_TO_SERVER;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "INTERNET_STATUS_CONNECTED_TO_SERVER"))
					#ifdef INTERNET_STATUS_CONNECTED_TO_SERVER
						return INTERNET_STATUS_CONNECTED_TO_SERVER;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "INTERNET_STATUS_SENDING_REQUEST"))
					#ifdef INTERNET_STATUS_SENDING_REQUEST
						return INTERNET_STATUS_SENDING_REQUEST;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "INTERNET_STATUS_REQUEST_SENT"))
					#ifdef INTERNET_STATUS_REQUEST_SENT
						return INTERNET_STATUS_REQUEST_SENT;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "INTERNET_STATUS_RECEIVING_RESPONSE"))
					#ifdef INTERNET_STATUS_RECEIVING_RESPONSE
						return INTERNET_STATUS_RECEIVING_RESPONSE;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "INTERNET_STATUS_RESPONSE_RECEIVED"))
					#ifdef INTERNET_STATUS_RESPONSE_RECEIVED
						return INTERNET_STATUS_RESPONSE_RECEIVED;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "INTERNET_STATUS_REDIRECT"))
					#ifdef INTERNET_STATUS_REDIRECT
						return INTERNET_STATUS_REDIRECT;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "INTERNET_STATUS_CLOSING_CONNECTION"))
					#ifdef INTERNET_STATUS_CLOSING_CONNECTION
						return INTERNET_STATUS_CLOSING_CONNECTION;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "INTERNET_STATUS_CONNECTION_CLOSED"))
					#ifdef INTERNET_STATUS_CONNECTION_CLOSED
						return INTERNET_STATUS_CONNECTION_CLOSED;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "INTERNET_STATUS_HANDLE_CREATED"))
					#ifdef INTERNET_STATUS_HANDLE_CREATED
						return INTERNET_STATUS_HANDLE_CREATED;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "INTERNET_STATUS_HANDLE_CLOSING"))
					#ifdef INTERNET_STATUS_HANDLE_CLOSING
						return INTERNET_STATUS_HANDLE_CLOSING;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "INTERNET_STATUS_REQUEST_COMPLETE"))
					#ifdef INTERNET_STATUS_REQUEST_COMPLETE
						return INTERNET_STATUS_REQUEST_COMPLETE;
					#else
						goto not_there;
					#endif
				break;
			}
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
		break;
    case 'T':
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
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

void WINAPI CALLBACK
PerlCallback(HINTERNET h, 
	   DWORD context, 
	   DWORD mystatus, 
	   LPVOID mystatusinfo, 
	   DWORD mystatuslength) {

    DWORD myret;
    HINTERNET myhandle;

/*
    // Tried to simply set a variable in Perl
	// with the status info for this context,
	// but it fails with:
	// Modification of a read-only value attempted at testcallback.pl line 10.

  	char mytmp[80];
	char mystring[80];
	SV* myvar;
	SV* myvarcheck;


  	// ultoa((DWORD) h, mystring, 10);
	// strncat(mystring, ".", 1);
	// ultoa((DWORD) context, mytmp, 10);
	// strcat(mystring, mytmp);
	// // why the handle?
	ultoa((DWORD) context, mystring, 10);
	printf("PerlCallback: got context=%d mystring=%s\n",context,mystring);
	myvar=perl_get_sv(mystring, FALSE);
	if(myvar==NULL) {
		printf("PerlCallback: creating new var...\n");
		myvar=perl_get_sv(mystring, TRUE | 0x02);
	}
	if(!SvOK(myvar)) printf("PerlCallback: var is NOT defined...\n");

	myvarcheck=perl_get_sv(mystring, FALSE);
	if(myvarcheck==NULL) printf("PerlCallback: var does not exist!\n");
    if(myvarcheck==myvar) printf("PerlCallback: var exists...\n");
	printf("PerlCallback: populating var...\n");
	sv_setiv(myvar, mystatus);
	printf("PerlCallback: returning...\n");    
*/


	// Let's try with perl_call_method
	// ...to clarify:
	// a C routine 
	// called from Perl
	// callbacks this C routine 
	// that callbacks a Perl routine.
	// ;)

	// if(mystatus!=status) {
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(sp);
		// XPUSHs(sv_2mortal(newSVpv("Win32::Internet\0",0)));
		XPUSHs(sv_2mortal(newSViv(context)));
		XPUSHs(sv_2mortal(newSViv(mystatus)));
		switch(mystatus) {
		case INTERNET_STATUS_HANDLE_CREATED:
			myhandle=(HINTERNET) *(LPHINTERNET)mystatusinfo;
			XPUSHs(sv_2mortal(newSViv((DWORD) myhandle)));
			break;
		case INTERNET_STATUS_RESPONSE_RECEIVED:
		case INTERNET_STATUS_REQUEST_SENT:
			myret=(DWORD) *(LPDWORD)mystatusinfo;
			// printf("PerlCallback: received/sent(%d) %d bytes\n",mystatus,myret);
			XPUSHs(sv_2mortal(newSViv(myret)));
			break;
		default:
			XPUSHs(sv_2mortal(newSViv(0)));
			break;
		}
		PUTBACK;
		// printf("PerlCallback: calling callback with context=%d, status=%d\n",context,mystatus);
		perl_call_pv("Win32::Internet::callback", G_DISCARD);
		FREETMPS;
		LEAVE;
	// }
	// status=mystatus;
	// return;
}



MODULE = Win32::Internet	PACKAGE = Win32::Internet

PROTOTYPES: DISABLE

DWORD
constant(name,arg)
    char *name
    int arg
CODE:
    RETVAL = constant(name, arg);
OUTPUT:
    RETVAL


long
InternetSetStatusCallback(handle)
    HINTERNET handle
CODE:
    RETVAL = (long)InternetSetStatusCallback(handle, PerlCallback);
OUTPUT:
    RETVAL


HINTERNET
InternetOpen(agent,type,proxy,proxybypass,flags)
    LPCTSTR agent
    DWORD type
    LPCTSTR proxy
    LPCTSTR proxybypass
    DWORD flags
CODE:
    RETVAL = InternetOpen(agent,type,proxy,proxybypass,flags);
OUTPUT:
    RETVAL

void
InternetGetLastResponseInfo()
PPCODE:
    DWORD myerrnum;
    unsigned char mybuf[TMPBUFSZ*2];
    DWORD mybufsz = sizeof(mybuf);

    if (InternetGetLastResponseInfo(&myerrnum, (LPTSTR) &mybuf, &mybufsz)) {
	// printf("InternetGetLastResponseInfo: myerrnum=%d\n",myerrnum);
	// printf("InternetGetLastResponseInfo: mybuf=%s\n",mybuf);
	XPUSHs(sv_2mortal(newSViv(myerrnum)));
	XPUSHs(sv_2mortal(newSVpv((char *) &mybuf,0)));
    }
    else {
	XPUSHs(&PL_sv_no);
    }


void
InternetQueryDataAvailable(handle)
    HINTERNET handle
PPCODE:
    DWORD mydatalen;
    if (InternetQueryDataAvailable(handle, &mydatalen, 0, 0))
        XSRETURN_IV((long) mydatalen);
    else
	XSRETURN_NO;

void
InternetReadFile(handle,size)
    HINTERNET handle
    DWORD size
PPCODE:
    char *mybuf;
    DWORD myread;
    mybuf=(char *)safemalloc(size+1);
    if (InternetReadFile(handle, mybuf, size, &myread))
	XPUSHs(sv_2mortal(newSVpv(mybuf,myread)));
    else
	XPUSHs(&PL_sv_no);
    safefree(mybuf);


void
InternetDllVersion()
PPCODE:
    DWORD infosize;
    DWORD zero;
    void *ver;
    void *verbuf;
    BOOL myerror;

    // Attempting to get WININET.DLL true version
    infosize = GetFileVersionInfoSize("WININET.DLL\0",&zero);
    // printf("InternetQueryVersion: GetFileVersionInfoSize.result=%d\n",infosize);

    ver = (void *)safemalloc(infosize);
    myerror = GetFileVersionInfo("WININET.DLL\0",zero,infosize,(LPVOID)ver);
    // printf("InternetQueryVersion: GetFileVersionInfo.result=%d\n",myerror);
    if (VerQueryValue(ver, 
                     TEXT("\\StringFileInfo\\040904B0\\FileVersion"), 
                     &verbuf, 
                     (PUINT) &infosize))
    { 
	// TEXT("\\VarFileInfo\\Translation"), // returns 040904B0, hope it is always true
	// printf("InternetQueryVersion: VerQueryValue.result=%d\n",myerror);
	// printf("InternetQueryVersion: infosize=%d\n",infosize);
	// printf("InternetQueryVersion: verbuf=%s\n",verbuf);
	XPUSHs(sv_2mortal(newSVpv((char *)verbuf,infosize)));
    } else {
	XPUSHs(&PL_sv_no);
    }
    safefree((char *)ver);


void
InternetQueryOption(handle,option)
    HINTERNET handle
    DWORD option
PPCODE:
    char *mybuf;
    long mybufsz = 16000;
    DWORD mynum;
    unsigned char myc;
    int i;

    mybuf=(char *)safemalloc(mybufsz);

    if (InternetQueryOption(handle, option, mybuf, (DWORD*)&mybufsz)) {
        switch (option) {
	case INTERNET_OPTION_VERSION:
	    // returns an array
	    XST_mIV(0,((LPINTERNET_VERSION_INFO)mybuf)->dwMajorVersion);
	    XST_mIV(1,((LPINTERNET_VERSION_INFO)mybuf)->dwMinorVersion);
	    safefree((char *)mybuf);
	    XSRETURN(2);
	    break;
	case INTERNET_OPTION_CONNECT_TIMEOUT:
	case INTERNET_OPTION_CONNECT_RETRIES:
	case INTERNET_OPTION_CONNECT_BACKOFF:
	case INTERNET_OPTION_CONTROL_RECEIVE_TIMEOUT:
	case INTERNET_OPTION_CONTROL_SEND_TIMEOUT:
	case INTERNET_OPTION_DATA_RECEIVE_TIMEOUT:
	case INTERNET_OPTION_DATA_SEND_TIMEOUT:
	case INTERNET_OPTION_LISTEN_TIMEOUT:
	case INTERNET_OPTION_HANDLE_TYPE:
	case INTERNET_OPTION_READ_BUFFER_SIZE:
	case INTERNET_OPTION_WRITE_BUFFER_SIZE:
	    // returns a number
	    // printf("InternetQueryOption: mybufsz=%d\n",mybufsz);
	    mynum=0;
	    for (i=0;i<4;i++) {
		myc=*(mybuf+i);
		mynum+=myc*( i>0? 256*i : 1);
            }			
	    XST_mIV(0,mynum);
	    // ST(0)=sv_2mortal(newSViv((DWORD) *mybuf));
	    safefree((char *)mybuf);
	    XSRETURN(1);
	    break;
	default:
	    // returns a string
	    XST_mPV(0,mybuf);
	    safefree((char *)mybuf);
	    XSRETURN(1);
	    break;
	}
    } else {
	safefree((char *)mybuf);
	XSRETURN_NO;
    }


void
InternetSetOption(handle,option,value)
    HINTERNET handle
    DWORD option
    SV * value
PPCODE:
    DWORD mysize;
    void *mybuf;
    DWORD mynum;
    BOOL myretval;
    STRLEN len;

    switch (option) {
    case INTERNET_OPTION_CONNECT_TIMEOUT:
    case INTERNET_OPTION_CONNECT_RETRIES:
    case INTERNET_OPTION_CONNECT_BACKOFF:
    case INTERNET_OPTION_CONTROL_RECEIVE_TIMEOUT:
    case INTERNET_OPTION_CONTROL_SEND_TIMEOUT:			 
    case INTERNET_OPTION_DATA_RECEIVE_TIMEOUT:
    case INTERNET_OPTION_DATA_SEND_TIMEOUT:
    case INTERNET_OPTION_LISTEN_TIMEOUT:
    case INTERNET_OPTION_READ_BUFFER_SIZE:
    case INTERNET_OPTION_WRITE_BUFFER_SIZE:
	// sets a number
	mynum = SvIV(value);
	mysize = sizeof(mynum);
	myretval = InternetSetOption(handle, option, (LPVOID)&mynum, mysize);
	break;
    default:
	// sets a packed string
	mybuf = (LPVOID) SvPV(value,len);
	mysize = len;
	myretval = InternetSetOption(handle, option, mybuf, mysize);
	break;
    }
    if (myretval)
	XSRETURN_YES;
    else
	XSRETURN_NO;

void
InternetTimeFromSystemTime(second,minute,hour,day,month,year,dayofweek,RFC)
    WORD second
    WORD minute
    WORD hour
    WORD day
    WORD month
    WORD year
    WORD dayofweek
    DWORD RFC
PPCODE:
    SYSTEMTIME st;
    char mybuffer[1024];
    st.wSecond       = second;
    st.wMinute       = minute;
    st.wHour         = hour;
    st.wDay          = day;
    st.wMonth        = month;
    st.wYear         = year;
    st.wDayOfWeek    = dayofweek;
    st.wMilliseconds = 0;
    // printf("ITFST %d:%d:%d %d/%d/%d %d %d\n",st.wHour,st.wMinute,st.wSecond,
    //		st.wDay, st.wMonth, st.wYear, st.wDayOfWeek,RFC;

    if (InternetTimeFromSystemTime((CONST SYSTEMTIME *)&st,
				  RFC,
				  (LPSTR)&mybuffer,
				  (DWORD)sizeof(mybuffer)))
    {
	XST_mPV(0,mybuffer);
	XSRETURN(1);
    } else {
	XSRETURN_NO;
    }


void
InternetTimeToSystemTime(time)
    LPCTSTR time
PPCODE:
    SYSTEMTIME st;
    if (InternetTimeToSystemTime(time, &st, 0)) {
	EXTEND(SP,7);
	XST_mIV(0,st.wSecond);
	XST_mIV(1,st.wMinute);
	XST_mIV(2,st.wHour);
	XST_mIV(3,st.wDay);
	XST_mIV(4,st.wMonth);
	XST_mIV(5,st.wYear);
	XST_mIV(6,st.wDayOfWeek);
	XSRETURN(7);
    }
    else
	XSRETURN_NO;

void
InternetCrackUrl(URL,flags)
    SV * URL
    DWORD flags
PPCODE:
    URL_COMPONENTS myURL;
    LPCSTR mystring;
    DWORD mysize;
    STRLEN len;
 
    mystring = SvPV(URL, len);
    mysize = len;

    myURL.dwStructSize=sizeof(myURL);
    myURL.lpszScheme=(char *)safemalloc(mysize);
    myURL.dwSchemeLength=mysize;
    myURL.lpszHostName=(char *)safemalloc(mysize);
    myURL.dwHostNameLength=mysize;
    myURL.nPort=(INTERNET_PORT)mysize;
    myURL.lpszUserName=(char *)safemalloc(mysize);
    myURL.dwUserNameLength=mysize;
    myURL.lpszPassword=(char *)safemalloc(mysize);
    myURL.dwPasswordLength=mysize;
    myURL.lpszUrlPath=(char *)safemalloc(mysize);
    myURL.dwUrlPathLength=mysize;
    myURL.lpszExtraInfo=(char *)safemalloc(mysize);
    myURL.dwExtraInfoLength=mysize;

    if (InternetCrackUrl(mystring, mysize,flags, (LPURL_COMPONENTS)&myURL)) {
	EXTEND(SP,7);
	XST_mPVn(0,myURL.lpszScheme,myURL.dwSchemeLength);
	XST_mPVn(1,myURL.lpszHostName,myURL.dwHostNameLength);
	XST_mIV(2,myURL.nPort);
	XST_mPVn(3,myURL.lpszUserName,myURL.dwUserNameLength);
	XST_mPVn(4,myURL.lpszPassword,myURL.dwPasswordLength);
	XST_mPVn(5,myURL.lpszUrlPath,myURL.dwUrlPathLength);
	XST_mPVn(6,myURL.lpszExtraInfo,myURL.dwExtraInfoLength); 
	XSRETURN(7);
    } else {
	XSRETURN_NO;
    }


void
InternetCreateUrl(scheme,hostname,port,username,password,path,extrainfo,flags)
    SV *scheme
    SV *hostname
    DWORD port
    SV *username
    SV *password
    SV *path
    SV *extrainfo
    DWORD flags
PPCODE:
    URL_COMPONENTS myURL;	
    char *mybuf;
    DWORD mybuflen = 16000;
    STRLEN len;

    mybuf=(char *)safemalloc(mybuflen);
    myURL.dwStructSize=sizeof(myURL);
    myURL.lpszScheme	= SvPV(scheme, len); myURL.dwSchemeLength = len;
    myURL.lpszHostName	= SvPV(hostname, len); myURL.dwHostNameLength = len;
    myURL.nPort		= (INTERNET_PORT)port;
    myURL.lpszUserName	= SvPV(username, len); myURL.dwUserNameLength = len;
    myURL.lpszPassword	= SvPV(password, len); myURL.dwPasswordLength = len;
    myURL.lpszUrlPath	= SvPV(path, len); myURL.dwUrlPathLength = len;
    myURL.lpszExtraInfo	= SvPV(extrainfo, len); myURL.dwExtraInfoLength = len;
    if (InternetCreateUrl((LPURL_COMPONENTS) &myURL,
	                  flags,
			  (LPSTR) mybuf,
			  (LPDWORD) &mybuflen))
	XPUSHs(sv_2mortal(newSVpv(mybuf,mybuflen))); 
    else
	XPUSHs(&PL_sv_no);
    safefree((char *)mybuf);


void
InternetCanonicalizeUrl(URL,flags)
    LPCTSTR URL
    DWORD flags
PPCODE:
    char *myURL;
    DWORD myURLlen = 16000;

    myURL=(char *)safemalloc(myURLlen);
    if (InternetCanonicalizeUrl(URL, myURL, &myURLlen, flags))
	XPUSHs(sv_2mortal(newSVpv(myURL,myURLlen)));
    else
	XPUSHs(&PL_sv_no);
    safefree((char *)myURL);


void
InternetCombineUrl(baseURL,relativeURL,flags)
    LPCTSTR baseURL
    LPCTSTR relativeURL
    DWORD flags
PPCODE:
    char *myURL;
    DWORD myURLlen = 16000;

    myURL=(char *)safemalloc(myURLlen);
    if (InternetCombineUrl(baseURL, relativeURL, myURL, &myURLlen, flags))
	XPUSHs(sv_2mortal(newSVpv(myURL,myURLlen)));
    else
	XPUSHs(&PL_sv_no);
    safefree((char *)myURL);


void
InternetOpenUrl(session,url,headers,length,flags,context)
    HINTERNET session
    LPCTSTR url
    LPCTSTR headers
    DWORD length
    DWORD flags
    DWORD context
PPCODE:
    HINTERNET myhandle;
    if (myhandle = InternetOpenUrl(session,url,headers,length,flags,context))
	XSRETURN_IV((long) myhandle);
    else
	XSRETURN_NO;

void
InternetConnect(session,server,port,user,pass,service,flags,context)
    HINTERNET session
    LPCTSTR server
    DWORD port
    LPCTSTR user
    LPCTSTR pass
    DWORD service
    DWORD flags
    DWORD context
PPCODE:
    HINTERNET myhandle;
    /*char mystring[80];
    SV* myvar;*/

    myhandle = InternetConnect(session, server, (INTERNET_PORT)port,
                               user, pass, service, flags, context);
    if (myhandle) {
	/*if((DWORD) SvIV(ST(7))>0) {
	    ultoa((DWORD) myhandle, mystring, 10);
	    strncpy((char *) &mystring+strlen(mystring), ".", 1);
		
	    ultoa((DWORD) SvIV(ST(7)), (char *) &mystring+strlen(mystring), 10);
	    printf("InternetConnect: mystring=%s\n",mystring);
	    myvar=perl_get_sv(mystring, FALSE);
	    if(myvar==NULL) myvar=perl_get_sv(mystring, TRUE);
	}*/
	XSRETURN_IV((long) myhandle);
    }
    else {
	XSRETURN_NO;
    }


void
InternetCloseHandle(handle)
    HINTERNET handle
PPCODE:
    if (InternetCloseHandle(handle))
	XSRETURN_YES;
    else
	XSRETURN_NO;


#
#
# FTP FUNCTIONS
#
#

void
FtpGetCurrentDirectory(handle)
    HINTERNET handle
PPCODE:
    char mybuf[MAX_PATH];
    DWORD mybufsz = sizeof(mybuf);
    if (FtpGetCurrentDirectory(handle, mybuf, &mybufsz))
	XSRETURN_PV(mybuf);
    else
	XSRETURN_NO;


void
FtpSetCurrentDirectory(handle,path)
    HINTERNET handle
    LPCTSTR path
PPCODE:
    if (FtpSetCurrentDirectory(handle, path))
	XSRETURN_YES;
    else
	XSRETURN_NO;


void
FtpFindFirstFile(handle,pattern,flags,context)
    HINTERNET handle
    LPCTSTR pattern
    DWORD flags
    DWORD context
PPCODE:
    HINTERNET myhandle;
    WIN32_FIND_DATA myfile;
    SYSTEMTIME mytime;
    unsigned long myFileSize;	

    if (myhandle = FtpFindFirstFile(handle, pattern,
				    (LPWIN32_FIND_DATA) &myfile,
                                    flags, context))
    {
	myFileSize = myfile.nFileSizeLow + 
		     (myfile.nFileSizeHigh << sizeof(myfile.nFileSizeLow));
	EXTEND(SP,23);
	XST_mIV(0,(long) myhandle);
	XST_mPV(1,myfile.cFileName);
	XST_mPV(2,myfile.cAlternateFileName);
	XST_mIV(3,myFileSize);
	XST_mIV(4,myfile.dwFileAttributes);

	FileTimeToSystemTime(&myfile.ftCreationTime,(LPSYSTEMTIME) &mytime);	
	XST_mIV(5,mytime.wSecond);
	XST_mIV(6,mytime.wMinute);
	XST_mIV(7,mytime.wHour);
	XST_mIV(8,mytime.wDay);
	XST_mIV(9,mytime.wMonth);
	XST_mIV(10,mytime.wYear);

	FileTimeToSystemTime(&myfile.ftLastAccessTime,(LPSYSTEMTIME) &mytime);	
	XST_mIV(11,mytime.wSecond);
	XST_mIV(12,mytime.wMinute);
	XST_mIV(13,mytime.wHour);
	XST_mIV(14,mytime.wDay);
	XST_mIV(15,mytime.wMonth);
	XST_mIV(16,mytime.wYear);

	FileTimeToSystemTime(&myfile.ftLastWriteTime,(LPSYSTEMTIME) &mytime);	
	XST_mIV(17,mytime.wSecond);
	XST_mIV(18,mytime.wMinute);
	XST_mIV(19,mytime.wHour);
	XST_mIV(20,mytime.wDay);
	XST_mIV(21,mytime.wMonth);
	XST_mIV(22,mytime.wYear);
        XSRETURN(23);
    } else {
	XSRETURN_NO;
    }


void
InternetFindNextFile(handle)
    HINTERNET handle
PPCODE:
    WIN32_FIND_DATA myfile;
    SYSTEMTIME mytime;
    unsigned long myFileSize;	

    if (InternetFindNextFile(handle, &myfile)) {
	myFileSize = myfile.nFileSizeLow + 
	        (myfile.nFileSizeHigh << sizeof(myfile.nFileSizeLow));
	EXTEND(SP,23);
	XST_mIV(0,1);
	XST_mPV(1,myfile.cFileName);
	XST_mPV(2,myfile.cAlternateFileName);
	XST_mIV(3,myFileSize);
	XST_mIV(4,myfile.dwFileAttributes);

	FileTimeToSystemTime(&myfile.ftCreationTime,(LPSYSTEMTIME) &mytime);	
	XST_mIV(5,mytime.wSecond);
	XST_mIV(6,mytime.wMinute);
	XST_mIV(7,mytime.wHour);
	XST_mIV(8,mytime.wDay);
	XST_mIV(9,mytime.wMonth);
	XST_mIV(10,mytime.wYear);

	FileTimeToSystemTime(&myfile.ftLastAccessTime,(LPSYSTEMTIME) &mytime);	
	XST_mIV(11,mytime.wSecond);
	XST_mIV(12,mytime.wMinute);
	XST_mIV(13,mytime.wHour);
	XST_mIV(14,mytime.wDay);
	XST_mIV(15,mytime.wMonth);
	XST_mIV(16,mytime.wYear);

	FileTimeToSystemTime(&myfile.ftLastWriteTime,(LPSYSTEMTIME) &mytime);	
	XST_mIV(17,mytime.wSecond);
	XST_mIV(18,mytime.wMinute);
	XST_mIV(19,mytime.wHour);
	XST_mIV(20,mytime.wDay);
	XST_mIV(21,mytime.wMonth);
	XST_mIV(22,mytime.wYear);
        XSRETURN(23);
    } else {
	XSRETURN_NO;
    }


void
FtpCreateDirectory(handle,directory)
    HINTERNET handle
    LPCTSTR directory
PPCODE:
    if (FtpCreateDirectory(handle, directory))
	XSRETURN_YES;
    else
	XSRETURN_NO;


void
FtpRemoveDirectory(handle,directory)
    HINTERNET handle
    LPCTSTR directory
PPCODE:
    if (FtpRemoveDirectory(handle, directory))
	XSRETURN_YES;
    else
	XSRETURN_NO;

void
FtpGetFile(handle,remotefile,localfile,replace,attr,flags,context)
    HINTERNET handle
    LPCTSTR remotefile
    LPCTSTR localfile
    BOOL replace
    DWORD attr
    DWORD flags
    DWORD context
PPCODE:
    if (FtpGetFile(handle,remotefile,localfile,replace,attr,flags,context))
	XSRETURN_YES;
    else
	XSRETURN_NO;


void
FtpPutFile(handle,localfile,remotefile,flags,context)
    HINTERNET handle
    LPCTSTR localfile
    LPCTSTR remotefile
    DWORD flags
    DWORD context
PPCODE:
    if (FtpPutFile(handle,localfile,remotefile,flags,context))
	XSRETURN_YES;
    else
	XSRETURN_NO;


void
FtpRenameFile(handle,oldname,newname)
    HINTERNET handle
    LPCTSTR oldname
    LPCTSTR newname
PPCODE:
    if (FtpRenameFile(handle,oldname,newname))
	XSRETURN_YES;
    else
	XSRETURN_NO;


void
FtpDeleteFile(handle,filename)
    HINTERNET handle
    LPCTSTR filename
PPCODE:
    if (FtpDeleteFile(handle,filename))
	XSRETURN_YES;
    else
	XSRETURN_NO;


#
#
# HTTP FUNCTIONS
#
#

void
HttpOpenRequest(handle,verb,object,version,referer,accept,flags,context)
    HINTERNET handle
    LPCTSTR verb
    LPCTSTR object
    LPCTSTR version
    LPCTSTR referer
    LPCTSTR accept
    DWORD flags
    DWORD context
PPCODE:
    HINTERNET myhandle;
    LPCTSTR buf[10];
    LPCTSTR *accept_ary = buf;
    LPCTSTR ptr = accept;
    size_t i = 0;
    size_t accept_ary_size = sizeof(buf)/sizeof(buf[0]);

    while (*ptr) {
	if (i >= accept_ary_size-1) {
	    if (accept_ary != buf) {
		New(0, accept_ary, accept_ary_size*2, LPCTSTR);
		Copy(buf, accept_ary, 1, buf);
	    }
	    else {
		Renew(accept_ary, accept_ary_size*2, LPCTSTR);
	    }
	    accept_ary_size *= 2;
	}
	accept_ary[i++] = ptr;
	ptr += strlen(ptr)+1;
    }
    accept_ary[i] = NULL;
    myhandle = HttpOpenRequest(handle,verb,object,version,referer,
				accept_ary,flags,context);
    if (accept_ary != buf)
        Safefree(accept_ary);
    if (myhandle)
	XSRETURN_IV((long) myhandle);
    else
	XSRETURN_NO;

void
HttpSendRequest(handle,headers_sv,postdata_sv)
    HINTERNET handle
    SV *headers_sv
    SV *postdata_sv
PPCODE:
    STRLEN headers_len;
    STRLEN postdata_len;
    char *headers = SvPV(headers_sv, headers_len);
    char *postdata = SvPV(postdata_sv, postdata_len);
    if (HttpSendRequest(handle, headers, headers_len,
			postdata, postdata_len))
	XSRETURN_YES;
    else
	XSRETURN_NO;


void
HttpQueryInfo(handle,flags,header)
    HINTERNET handle
    DWORD flags
    LPCTSTR header
PPCODE:
    LPVOID mybuf;
    DWORD mysize=16000;
    DWORD myindex=0;
    mybuf=(void *)safemalloc(mysize);

    // printf("HttpQueryInfo: got flags=%u (header=%s)\n",
    //		flags,(char *) SvPV(ST(2),na)); 

    if (flags == HTTP_QUERY_CUSTOM) {
	strcpy((char *) mybuf, header);
	mysize=strlen(header);
	// printf("HttpQueryInfo: requesting CUSTOM header '%s' (len=%d)...\n",
	//	  (char *) mybuf, mysize);
    }

    if (HttpQueryInfo(handle,flags,mybuf,&mysize,&myindex)) {
	if(flags & HTTP_QUERY_FLAG_SYSTEMTIME) {
	    EXTEND(SP,6);
	    // printf("HttpQueryInfo: requested SYSTEMTIME (date is %d/%d/%d)\n",
	    //	      ((LPSYSTEMTIME) mybuf)->wDay,
	    //	      ((LPSYSTEMTIME) mybuf)->wMonth,
	    //	      ((LPSYSTEMTIME) mybuf)->wYear);
	    XST_mIV(0,((LPSYSTEMTIME) mybuf)->wSecond);
	    XST_mIV(1,((LPSYSTEMTIME) mybuf)->wMinute);
	    XST_mIV(2,((LPSYSTEMTIME) mybuf)->wHour);
	    XST_mIV(3,((LPSYSTEMTIME) mybuf)->wDay);
	    XST_mIV(4,((LPSYSTEMTIME) mybuf)->wMonth);
	    XST_mIV(5,((LPSYSTEMTIME) mybuf)->wYear);
	    safefree((char *)mybuf);
	    XSRETURN(6);
	}
	else {
	    ST(0) = sv_2mortal(newSVpv((char *)mybuf,mysize));
	    safefree((char *)mybuf);
	    XSRETURN(1);
	}
    }
    else {
	safefree((char *)mybuf);
	XSRETURN_NO;
    }


void
HttpAddRequestHeaders(handle,header,flags)
    HINTERNET handle
    LPCTSTR header
    DWORD flags
PPCODE:
    if (HttpAddRequestHeaders(handle,header,(DWORD)-1,flags))
	XSRETURN_YES;
    else
	XSRETURN_NO;

void
FormatMessage(error)
    int error
PPCODE:
    char message[1024];
    if (FormatMessage(FORMAT_MESSAGE_FROM_HMODULE,
		      GetModuleHandle("WININET"),
		      error, 0, message, sizeof(message), NULL))
    {
	XST_mPV(0,message);
	XSRETURN(1);
    }
    else
	XSRETURN_NO;

