#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "const-c.inc"

#include "stdafx.h"
#include "CommandLine.h"

#include <stdio.h>
#include <windows.h>

#define ProcessBasicInformation 0

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

BOOL GetProcessCmdLine(DWORD dwId,LPWSTR *wBuf);

int GetPidCommandLine(int pid, SV *cmdParameter){
	DWORD dwMinSize;
#ifdef _DEBUG
	HANDLE hOut;
	DWORD  nOut;
#endif
	LPWSTR  wstr = 0;
	char   *mbch = 0;

    //printf("  Call GetPidCommandLine, pid: %i, %i\n", pid, dwBufLen);

    NtQueryInformationProcess = (PROCNTQSIP)GetProcAddress(
                                            GetModuleHandle("ntdll"),
                                            "NtQueryInformationProcess"
                                            );
    if (!NtQueryInformationProcess){ return -1;}

    if (! GetProcessCmdLine(pid, &wstr)){
		return -1;

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
		mbch = (char*) malloc(dwMinSize);
		if (!mbch) return -1;

		dwMinSize = WideCharToMultiByte(CP_OEMCP, 0, (PWSTR)wstr, -1, mbch, dwMinSize, NULL, NULL);

#ifdef _DEBUG
		//write the utf16 string to a file
		hOut = CreateFile("_pidCmdLine.txt", GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
		if (hOut == INVALID_HANDLE_VALUE) {
			printf ("Cannot open output file. Error: %x\n", GetLastError ());
			return -1;
		}

		if(WriteFile (hOut, wstr, wcslen(wstr) * 2, &nOut, NULL)){
			printf("\n  write %i byte to _pidCmdLine.txt that is in unicode\n", nOut);
		}
		CloseHandle (hOut);
#endif

		#ifdef _DEBUG
		printf("  convert unicode to MB string: %s \n", mbch);
		#endif

		//copy to return buffer
		sv_setpv(cmdParameter, mbch);
		free(mbch);
		free(wstr);
		return dwMinSize;
}

BOOL GetProcessCmdLine(DWORD dwId, LPWSTR *wBuf)
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
	*wBuf = 0;

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
	// Add two bytes for the nulls (unicode character is 2 bytes, i think).
	*wBuf = (LPWSTR)malloc(dwSize+2);

    if (!*wBuf)
       goto cleanup;
    /* write command line into wBuf */
    if (!ReadProcessMemory( hProcess,
                            lpAddress,
                            *wBuf,
                            dwSize,
                            &dwDummy
                          )
       )
       goto cleanup;
    ((char*)(*wBuf))[dwSize] = '\0';
    ((char*)(*wBuf))[dwSize+1] = '\0';
    bRet = TRUE;

cleanup:

    CloseHandle (hProcess);


    return bRet;
}
// Ddreyfus. changed from char*cmdParameter to char&cmdParameter

MODULE = Win32::Process::CommandLine		PACKAGE = Win32::Process::CommandLine		

INCLUDE: const-xs.inc

int
GetPidCommandLine(pid, cmdParameter)
INPUT:
	int pid
	SV* cmdParameter;
CODE:
    /* initialize to undefined */
    sv_setsv(cmdParameter, newSV(0));
	RETVAL 	= GetPidCommandLine(pid, cmdParameter);
OUTPUT:
	cmdParameter
	RETVAL
