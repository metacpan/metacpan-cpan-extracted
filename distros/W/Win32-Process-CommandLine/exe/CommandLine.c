// CommandLine.c
//
//
//
#include "stdafx.h"
#include "CommandLine.h"

#include <stdio.h>
#include <windows.h>

#define ProcessBasicInformation 0
#define BUF_SIZE 512

typedef struct
{
    USHORT Length;
    USHORT MaximumLength;
    PWSTR  Buffer;
} UNICODE_STRING, *PUNICODE_STRING;

typedef struct
{
    ULONG          AllocationSize;
    ULONG          ActualSize;
    ULONG          Flags;
    ULONG          Unknown1;
    UNICODE_STRING Unknown2;
    HANDLE         InputHandle;
    HANDLE         OutputHandle;
    HANDLE         ErrorHandle;
    UNICODE_STRING CurrentDirectory;
    HANDLE         CurrentDirectoryHandle;
    UNICODE_STRING SearchPaths;
    UNICODE_STRING ApplicationName;
    UNICODE_STRING CommandLine;
    PVOID          EnvironmentBlock;
    ULONG          Unknown[9];
    UNICODE_STRING Unknown3;
    UNICODE_STRING Unknown4;
    UNICODE_STRING Unknown5;
    UNICODE_STRING Unknown6;
} PROCESS_PARAMETERS, *PPROCESS_PARAMETERS;

typedef struct
{
    ULONG               AllocationSize;
    ULONG               Unknown1;
    HINSTANCE           ProcessHinstance;
    PVOID               ListDlls;
    PPROCESS_PARAMETERS ProcessParameters;
    ULONG               Unknown2;
    HANDLE              Heap;
} PEB, *PPEB;

typedef struct
{
    DWORD ExitStatus;
    PPEB  PebBaseAddress;
    DWORD AffinityMask;
    DWORD BasePriority;
    ULONG UniqueProcessId;
    ULONG InheritedFromUniqueProcessId;
}   PROCESS_BASIC_INFORMATION;

typedef LONG (WINAPI *PROCNTQSIP)(HANDLE,UINT,PVOID,ULONG,PULONG);

PROCNTQSIP NtQueryInformationProcess;

BOOL GetProcessCmdLine(DWORD dwId,LPWSTR wBuf,DWORD dwBufLen);

int GetPidCommandLine(int pid, char* cmdParameter){
	int    dwBufLen = BUF_SIZE*2;
	WCHAR  wstr[BUF_SIZE]   = {'\0'};
	char   mbch[BUF_SIZE*2] = {'\0'};
	DWORD  nOut, dwMinSize;
	HANDLE hOut;

    //printf("  Call GetPidCommandLine, pid: %i, %i\n", pid, dwBufLen);

    NtQueryInformationProcess = (PROCNTQSIP)GetProcAddress(
                                            GetModuleHandle("ntdll"),
                                            "NtQueryInformationProcess"
                                            );
    if (!NtQueryInformationProcess){ return -1;}

    if (! GetProcessCmdLine(pid, wstr, dwBufLen)){
		cmdParameter = '\0';

		#ifdef _DEBUG
	    printf("  Error: cannot get %i's command line string\n", pid);
		#endif
		return 0;
	}else
		#ifdef _DEBUG
	    wprintf(L"  %i's unicode command line string: %d byte %s\n", pid, wcslen(wstr), wstr);
		#endif

		//count the byte number for second call, dwMinSize is length
		dwMinSize = WideCharToMultiByte(CP_OEMCP, 0, wstr, -1, NULL, 0, NULL, NULL);

		//convert utf16 to multibyte and save to mbch
		dwMinSize = WideCharToMultiByte(CP_OEMCP, 0, (PWSTR)wstr, -1, mbch, dwMinSize, NULL, NULL);

#ifdef _DEBUG
		//write the utf16 string to a file
		hOut = CreateFile("_pidCmdLine.txt", GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
		if (hOut == INVALID_HANDLE_VALUE) {
			printf ("Cannot open output file. Error: %x\n", GetLastError ());
			return -1;
		}

		//make sure no over buffer
		if(wcslen(wstr) < BUF_SIZE){
			if(WriteFile (hOut, wstr, wcslen(wstr) * 2, &nOut, NULL)){
				printf("\n  write %i byte to _pidCmdLine.txt that is in unicode\n", nOut);
			}
		}
		CloseHandle (hOut);
#endif

		//copy to return buffer
		strncpy(cmdParameter, mbch, dwMinSize);

		#ifdef _DEBUG
		printf("  convert unicode to MB string: %s \n", mbch);
		#endif

		return dwMinSize;
}

BOOL GetProcessCmdLine(DWORD dwId,LPWSTR wBuf,DWORD dwBufLen)
{
    LONG                      status;
    HANDLE                    hProcess;
    PROCESS_BASIC_INFORMATION pbi;
    PEB                       Peb;
    PROCESS_PARAMETERS        ProcParam;
    DWORD                     dwDummy;
    DWORD                     dwSize;
    LPVOID                    lpAddress;
    BOOL                      bRet = FALSE;

    // Get process handle
    hProcess = OpenProcess(PROCESS_QUERY_INFORMATION|PROCESS_VM_READ,FALSE,dwId);
    if (!hProcess)
       return FALSE;

    // Retrieve information
    status = NtQueryInformationProcess( hProcess,
                                        ProcessBasicInformation,
                                        (PVOID)&pbi,
                                        sizeof(PROCESS_BASIC_INFORMATION),
                                        NULL
                                      );


    if (status)
       goto cleanup;

    if (!ReadProcessMemory( hProcess,
                            pbi.PebBaseAddress,
                            &Peb,
                            sizeof(PEB),
                            &dwDummy
                          )
       )
       goto cleanup;

    if (!ReadProcessMemory( hProcess,
                            Peb.ProcessParameters,
                            &ProcParam,
                            sizeof(PROCESS_PARAMETERS),
                            &dwDummy
                          )
       )
       goto cleanup;

    lpAddress = ProcParam.CommandLine.Buffer;
    dwSize = ProcParam.CommandLine.Length;

    if (dwBufLen<dwSize)
       goto cleanup;

    if (!ReadProcessMemory( hProcess,
                            lpAddress,
                            wBuf,
                            dwSize,
                            &dwDummy
                          )
       )
       goto cleanup;


    bRet = TRUE;

cleanup:

    CloseHandle (hProcess);


    return bRet;
}

//#ifdef TESTING
int main(int argc, char** argv){
	char  mbChar[ BUF_SIZE *2 ] = {'\0'};
	int dwId;

	if(argc < 2 ) return 1;
	sscanf(argv[1], "%lu" ,&dwId);

	GetPidCommandLine(dwId, mbChar);

	if(strlen(mbChar) > 0) printf("  mb pid command line: %s \n", mbChar);

	return 0;
}
//#endif