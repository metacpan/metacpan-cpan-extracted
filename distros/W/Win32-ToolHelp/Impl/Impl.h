#define WIN32_TOOLHELP_IMPL_VER 0.2


#define MAX_PATH 260
#define MAX_MODULE_NAME32 255
//#define INVALID_HANDLE_VALUE ((HANDLE)(LONG_PTR)-1)


//typedef unsigned long DWORD;
typedef unsigned long ULONG_PTR;
//typedef long LONG_PTR;
//typedef long LONG;
//typedef char CHAR;
//typedef unsigned char byte;
//typedef byte BYTE;
//typedef void* HANDLE;


typedef struct tagPROCESSENTRY32
{
	DWORD dwSize;
	DWORD cntUsage;
	DWORD th32ProcessID;
	ULONG_PTR th32DefaultHeapID;
	DWORD th32ModuleID;
	DWORD cntThreads;
	DWORD th32ParentProcessID;
	LONG pcPriClassBase;
	DWORD dwFlags;
	CHAR szExeFile[MAX_PATH];
} PROCESSENTRY32;

typedef struct tagMODULEENTRY32
{
    DWORD dwSize;
    DWORD th32ModuleID;
    DWORD th32ProcessID;
    DWORD GlblcntUsage;
    DWORD ProccntUsage;
    BYTE* modBaseAddr;
    DWORD modBaseSize;
    HMODULE hModule;
    CHAR szModule[MAX_MODULE_NAME32 + 1];
    CHAR szExePath[MAX_PATH];
} MODULEENTRY32;


HANDLE GetFirstProcess(PROCESSENTRY32* pe32);
HANDLE GetNextProcess(HANDLE h, PROCESSENTRY32* pe32);

HANDLE GetFirstModule(DWORD pid, MODULEENTRY32* me32);
HANDLE GetNextModule(HANDLE h, MODULEENTRY32* me32);
