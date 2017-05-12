#define	NULL_VALUE	""

#ifndef _WIN64
#  ifndef SQLLEN
#    define	SQLLEN	SDWORD
#  endif
#  ifndef SQLULEN
#    define	SQLULEN	UDWORD
#  endif
#endif

struct ODBC_Conn;

class CResults{
	public:
		CResults(ODBC_Conn *hODBC);
		~CResults();
		char *operator[](int iElement);
		SDWORD  Size(int iElement);
		SDWORD	ReturnSize(int iElement);
		SWORD	NumOfCols();
		DWORD	RowSetSize();
		void	Clean();


	private:
		void	RemoveBuffers();
		SQLLEN  *dSize;
		char	**szColumn;
		SQLLEN	*dReturnSize;
		SWORD	sNumOfCols;
 		DWORD	dRowSetSize;
		int		iODBC;

};

