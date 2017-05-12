#define PIPE_NAME_PREFIX	"\\\\.\\pipe\\"
#define	PIPE_NAME_SIZE		256
	
#define	BUFFER_SIZE			512
#define	ERROR_TEXT_SIZE		128

#define ERROR_NAME_TOO_LONG 100, "Pipe Name is too long"

#define	DEFAULT_WAIT_TIME	10000
#define	WAIT_FOR_PIPE		1
#define	DONT_WAIT_FOR_PIPE	0

#define	CLIENT				1
#define SERVER				2

class CPipe {
	public:
		CPipe(char *szPipeName, DWORD dWait = DEFAULT_WAIT_TIME);
		CPipe(char *szServer, char *szPipeName);
		~CPipe();
		int	Write(void *vBuffer, DWORD dSize);
		char *Read(DWORD *dLen);
		int	Error(int iErrorNum, char *szErrorText);
		int	EndOfFile();
		int Connect();
		int	Disconnect(int iPurge);
		DWORD BufferSize();
		DWORD ResizeBuffer(DWORD dNewSize);

		CHAR	*cBuffer;
		DWORD	dBufferSize;
		int		iError;
		LPSTR	szError[ERROR_TEXT_SIZE];


	private:

		HANDLE	hPipe;
  		LPSTR	lpName[257];						// address of pipe name 
    	DWORD	dwOpenMode;
    	DWORD	dwPipeMode;
    	DWORD	nMaxInstances;					// maximum number of instances  
    	DWORD	nOutBufferSize;
    	DWORD	nInBufferSize;
    	DWORD	nDefaultTimeOut;					// time-out time, in milliseconds 
    	LPSECURITY_ATTRIBUTES  lpSecurityAttributes;
	
		int		iPipeType;					//	Type of connection.
		DWORD	dBytes;
};
		

