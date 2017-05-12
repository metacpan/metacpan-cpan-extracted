#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Win32::Process::Memory		PACKAGE = Win32::Process::Memory		

int
_OpenByPid(nPid, nDesiredAccess)
	int nPid
	int nDesiredAccess
 CODE:
	RETVAL = (int)OpenProcess((DWORD)nDesiredAccess, 0, (DWORD)nPid);
 OUTPUT:
	RETVAL

int
_CloseProcess(hProcess)
	int hProcess
 CODE:
	RETVAL = (int)CloseHandle((HANDLE)hProcess);
 OUTPUT:
	RETVAL

int
_ReadMemory(hProcess, nOffset, nLen, sv)
	int hProcess
	int nOffset
	int nLen
	SV *sv
 PREINIT:
	SIZE_T nBytesRead;
 CODE:
	SvUPGRADE(sv, SVt_PV);
	SvUTF8_off(sv);
	SvGROW(sv, (STRLEN)nLen);
	if( !ReadProcessMemory((HANDLE)hProcess, (LPCVOID)nOffset,
		(LPVOID)SvPV_nolen(sv), (SIZE_T)nLen, &nBytesRead) ) { /* Fail */
		nBytesRead=0;
	}
	SvCUR_set(sv, (STRLEN)nBytesRead);
	SvPOK_on(sv);
	RETVAL = (int)nBytesRead;
 OUTPUT:
    sv
    RETVAL

int
_WriteMemory(hProcess, nOffset, sv)
	int hProcess
	int nOffset
	SV *sv
 PREINIT:
	SIZE_T nBytesWrite;
	STRLEN nLen;
	char *pStr;
 CODE:
	pStr=SvPV(sv, nLen);
	if( !WriteProcessMemory((HANDLE)hProcess, (LPVOID)nOffset,
		(LPVOID)pStr, (SIZE_T)nLen, &nBytesWrite) ) { /* Fail */
		nBytesWrite=0; /*(SIZE_T)GetLastError();*/
	}
	RETVAL = (int)nBytesWrite;
 OUTPUT:
    RETVAL

void
_GetMemoryList(hProcess)
	int hProcess
 PREINIT:
	LPVOID lpAddr;
	MEMORY_BASIC_INFORMATION mbi;
 PPCODE:
	lpAddr=0;
	while( VirtualQueryEx((HANDLE)hProcess, (LPCVOID)lpAddr, &mbi, sizeof(mbi)) ) {
		if( mbi.State & MEM_COMMIT ) {
			XPUSHs(sv_2mortal(newSVuv((unsigned)mbi.BaseAddress)));
			XPUSHs(sv_2mortal(newSVuv((unsigned)mbi.RegionSize)));
		}
		lpAddr = (LPVOID)((unsigned)mbi.BaseAddress + (unsigned)mbi.RegionSize);
	}