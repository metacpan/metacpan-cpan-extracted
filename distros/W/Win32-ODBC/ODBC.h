
#define	SYNTAX_ERROR	999
#define CROAK(xxxx)                                  \
  PUSHMARK(sp);                                      \
  XPUSHs(sv_2mortal(newSVnv((double)SYNTAX_ERROR))); \
  XPUSHs(sv_2mortal(newSVpv(xxxx, strlen(xxxx))));   \
  PUTBACK;                                           \
  return;                                            \

#define	DEBUG_DUMP(xxx);		                                 \
/*
  {                                                                      \
  char szBuff[512];                                                      \
  sprintf(szBuff, "=== %s (Thread: %04i)\n", xxx, GetCurrentThreadId()); \
  DebugPrint(szBuff);                                                    \
  }
 */

#define MAX_DATA_BUF_SIZE	0x7FFFFFFE	//	Largest value for a SDWORD ( -1 for a string terminating null)	
#define	MAX_DATA_ASSUME_SIZE	0x20000000	//	Largest size a field can specify before we assume that it is not accurate
#define DEFAULT_DATA_BUF_SIZE	10240
#define	DEFAULTCOLSIZE		20		//	Start with DEFAULTCOLSIZE number of chars per column.


#define	COMMAND_LENGTH			1024
#define	DSN_LENGTH			1024
#define	DS_DESCRIPTION_LENGTH		2048

#define ODBC_BUFF_SIZE 			1024
#define	SQL_STATE_SIZE			10

#define	QUERY_TIMEOUT_VALUE		120
#define	LOGIN_TIMEOUT_VALUE		20

#define	TABLE_COMMAND_STRING	"%s(\"%s\", \"%s\", \"%s\", \"%s\")"

#define	DEFAULT_STMT_CLOSE_TYPE		SQL_DROP

//	Define ODBCList as a Macro for backward compatiblility.
#define	THREAD_MOM	( (CMom *) ::cMom->operator[](GetCurrentThreadId()))
#define	ODBCLIST	( (ODBC_TYPE *) (THREAD_MOM)->operator[]((DWORD)0))


class CResults;

struct	ODBC_hdbc{
	HDBC	hdbc;				//	Handle to the ODBC connection
	int	iConnected;			//	Is this HDBC actually connected to a database?
	int	iCount;				//	How many ODBC objects are using this?
} typedef ODBC_HDBC;

struct ODBCError{
	char	szError[ODBC_BUFF_SIZE];	//	Last Error Message
	UCHAR	szSqlState[SQL_STATE_SIZE];	//	Last ODBC SQL State
	char	szFunction[50];			//	What Function generated the error?
	char	szFunctionLevel[10];		//	What level within the Function?
	long	ErrNum;				//	Last error number
	int	EOR;				//	End of Records (no more left)
} typedef ODBC_ERROR;

struct	ODBC_Conn{
	int	conn;				//	connection number
	HENV	henv;  				//	Environment (reflection of ghEnv)
	HSTMT	hstmt;				//	Our very own hstmt
	ODBC_HDBC	*hdbc;			//	Pointer to our connection info.
	CResults	*Results;		//	Pointer to result set data
	ODBCError	*Error;			//	Pointer to error structure
	UWORD	uStmtCloseType;			//  Type of closing to perform on a FreeStmt()
	long	iMaxBufSize;			//	Max memory buffer size for this connection.
	int	numcols;  			//	for storing btwn Execute and Fetch
	DWORD	dNumOfRows;			//	Number of rows already retrieved
	int	iDebug;				//	Is debugging active?
	HANDLE	hDebug;				//	Handle to console for debugging
	char	szUserDSN[DSN_LENGTH];		//	DSN for this connection(Specified by the user);
	char	*szDSN;				//	DSN for this connection (specified by ODBC);
	char	*szCommand;			//	Last issued SQL or other command.
} typedef ODBC_TYPE;


#ifdef __WIN32_ODBC__

	#define	ReturnError(xx)																\
		{ 																					\
			char *szError = "No connections exist";											\
			if (h){																			\
				szError = h->Error->szError;												\
			}																				\
			XPUSHs(sv_2mortal(newSVnv((double)1)));											\
			XPUSHs(sv_2mortal(newSVnv((double)((h)? h->Error->ErrNum:0))));					\
			XPUSHs(sv_2mortal(newSVpv((char *)szError, strlen((char *)szError))));			\
		}

	ODBC_TYPE	*ODBCList = 0;
	int		ODBC_Conn_Number = 0;  
	int		ODBCTotal = 1;

	HENV            ghEnv = 0;

	char            ODBC_errorstring[ODBC_BUFF_SIZE];
	int             ODBC_errornum;

	HINSTANCE	ghDLL 	= 0;
	HANDLE		ghDebug = 0;
	HANDLE		ghFile 	= 0;
	char		*gszFile = 0;
	int		giDebug = 0;
	int		giDebugGlobal = 0;
	int		giThread = 0;
	CRITICAL_SECTION gDCS;
	CRITICAL_SECTION gCS;	// A critical section handle
							// is used to protect global
							// state properties


#else

	extern ODBC_TYPE	*ODBCList;
	extern	int		ODBC_Conn_Number;  
	extern	int		ODBCTotal;

	extern	HENV	ghEnv;

	extern	char	ODBC_errorstring[ODBC_BUFF_SIZE];
	extern	int		ODBC_errornum;

	extern	HINSTANCE	ghDLL;
	extern	HANDLE		ghDebug;
	extern	HANDLE		ghFile;
	extern	char		*gszFile;
	extern	int			giDebug;
	extern	int			giDebugGlobal;
	extern	int			giThread;
	extern	CRITICAL_SECTION 	gDCS;
	extern	CRITICAL_SECTION	gCS;
#endif

ODBC_TYPE *NewODBC();
ODBC_TYPE *CleanODBC(ODBC_TYPE *h);
ODBC_TYPE * _NT_ODBC_Verify(int iODBC);
ODBC_TYPE *ODBCError(char *szString, ODBC_TYPE *h, char *szFunction, char *szFunctionLevel);
int DeleteConn(int iODBC);
void _NT_ODBC_Error(ODBC_Conn * h, char *szFunction, char *szFunctionLevel);
int FreeODBC(ODBC_TYPE *h);
RETCODE ResetStmt(ODBC_TYPE *h);
char *MapCloseType(UWORD uCloseType);
void CleanError(ODBC_ERROR *h);
int	ColNameToNum(ODBC_TYPE *h, char *szName);
// void ReturnError(ODBC_TYPE *h);
void AddDebug(ODBC_TYPE *h);
void RemoveDebug(ODBC_TYPE *h);
RETCODE TableColList(int iType);
void TerminateThread();
int InitExtension();

#ifdef new
	#undef new
#endif
#define	new	::new

#if _DEBUG
	void DebugDumpError(ODBC_TYPE *h);
	void DebugConnection(char *szString, ODBC_TYPE *h);
	void DebugDump(char *szString);
	void DebugPrint(char *szString);
#endif
