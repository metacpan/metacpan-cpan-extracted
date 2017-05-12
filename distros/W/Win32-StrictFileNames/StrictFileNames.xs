#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <windows.h>
#include <ImageHlp.h>
#include <tlhelp32.h>

// ========== Auxiliary debug function

#define MYDEBUG 0

#if (MYDEBUG > 0)
void DEBUGSTR( char * szFormat, ...) {  // sort of OutputDebugStringf
  char szBuffer[1024];
  va_list pArgList;
  va_start(pArgList, szFormat);
  _vsnprintf(szBuffer, sizeof(szBuffer), szFormat, pArgList);
  va_end(pArgList);
  OutputDebugString(szBuffer);
}
#else
#define DEBUGSTR //DEBUGSTR
#endif

// ========== Global variables and constants

// Macro for adding pointers/DWORDs together without C arithmetic interfering
#define MakePtr( cast, ptr, addValue ) (cast)( (DWORD)(ptr)+(DWORD)(addValue))

HINSTANCE hDllInstance;       // Dll instance handle
BOOL      bWarn = FALSE;      // warning status

// ========== Hooking API functions
//
// References about API hooking (and dll injection):
// - Matt Pietrek ~ Windows 95 System Programming Secrets.
// - Jeffrey Richter ~ Programming Applications for Microsoft Windows 4th ed.

//-----------------------------------------------------------------------------
//   HookAPIOneMod
// Substitute a new function in the Import Address Table (IAT) of the
// specified module .
// Return FALSE on error and TRUE on success.
//-----------------------------------------------------------------------------

BOOL HookAPIOneMod(
    HMODULE hFromModule,        // Handle of the module to intercept calls from
    PSTR    pszFunctionModule,  // Name of the module to intercept calls to
    PSTR    pszOldFunctionName, // Name of the function to intercept calls to
    PROC    pfnNewFunction      // New function (replaces old one)
    )
{
  PROC                      pfnOldFunction;
  PIMAGE_DOS_HEADER         pDosHeader;
  PIMAGE_NT_HEADERS         pNTHeader;
  PIMAGE_IMPORT_DESCRIPTOR  pImportDesc;
  PIMAGE_THUNK_DATA         pThunk;

  // Verify that a valid pfn was passed
  if ( IsBadCodePtr(pfnNewFunction) ) {
    DEBUGSTR("error: %s(%d)", __FILE__, __LINE__);
    return FALSE;
  }

  // Verify that the module and function names passed are valid
  pfnOldFunction = GetProcAddress( GetModuleHandle(pszFunctionModule),
                                   pszOldFunctionName );
  if ( !pfnOldFunction )
  {
    DEBUGSTR("error: %s(%d)", __FILE__, __LINE__);
    return FALSE;
  }

  // Tests to make sure we're looking at a module image (the 'MZ' header)
  pDosHeader = (PIMAGE_DOS_HEADER)hFromModule;
  if ( IsBadReadPtr(pDosHeader, sizeof(IMAGE_DOS_HEADER)) ) {
    DEBUGSTR("error: %s(%d)", __FILE__, __LINE__);
    return FALSE;
  }
  if ( pDosHeader->e_magic != IMAGE_DOS_SIGNATURE ) {
    DEBUGSTR("error: %s(%d)", __FILE__, __LINE__);
    return FALSE;
  }

  // The MZ header has a pointer to the PE header
  pNTHeader = MakePtr(PIMAGE_NT_HEADERS, pDosHeader, pDosHeader->e_lfanew);

  // More tests to make sure we're looking at a "PE" image
  if ( IsBadReadPtr(pNTHeader, sizeof(IMAGE_NT_HEADERS)) ) {
    DEBUGSTR("error: %s(%d)", __FILE__, __LINE__);
    return FALSE;
  }
  if ( pNTHeader->Signature != IMAGE_NT_SIGNATURE ) {
    DEBUGSTR("error: %s(%d)", __FILE__, __LINE__);
    return FALSE;
  }

  // We know have a valid pointer to the module's PE header.
  // Get a pointer to its imports section
  pImportDesc = MakePtr(PIMAGE_IMPORT_DESCRIPTOR,
                        pDosHeader,
                        pNTHeader->OptionalHeader.
                          DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].
                          VirtualAddress);

  // Bail out if the RVA of the imports section is 0 (it doesn't exist)
  if ( pImportDesc == (PIMAGE_IMPORT_DESCRIPTOR)pNTHeader ) {
    return TRUE;
  }

  // Iterate through the array of imported module descriptors, looking
  // for the module whose name matches the pszFunctionModule parameter
  while ( pImportDesc->Name ) {
    PSTR pszModName = MakePtr(PSTR, pDosHeader, pImportDesc->Name);
    if ( stricmp(pszModName, pszFunctionModule) == 0 )
      break;
    pImportDesc++;  // Advance to next imported module descriptor
  }

  // Bail out if we didn't find the import module descriptor for the
  // specified module.  pImportDesc->Name will be non-zero if we found it.
  if ( pImportDesc->Name == 0 )
    return TRUE;

  // Get a pointer to the found module's import address table (IAT)
  pThunk = MakePtr(PIMAGE_THUNK_DATA, pDosHeader, pImportDesc->FirstThunk);

  // Blast through the table of import addresses, looking for the one
  // that matches the address we got back from GetProcAddress above.
  while ( pThunk->u1.Function ) {
         // double cast avoid warning with VC6 and VC7 :-)
    if ( (DWORD) pThunk->u1.Function == (DWORD)pfnOldFunction ) { // We found it!
      DWORD flOldProtect, flNewProtect, flDummy;
      MEMORY_BASIC_INFORMATION mbi;

      // Get the current protection attributes
      VirtualQuery(&pThunk->u1.Function, &mbi, sizeof(mbi));
      // Take the access protection flags
      flNewProtect = mbi.Protect;
      // Remove ReadOnly and ExecuteRead flags
      flNewProtect &= ~(PAGE_READONLY | PAGE_EXECUTE_READ);
      // Add on ReadWrite flag
      flNewProtect |= (PAGE_READWRITE);
      // Change the access protection on the region of committed pages in the
      // virtual address space of the current process
      if( !VirtualProtect(&pThunk->u1.Function, sizeof(PVOID), flNewProtect, &flOldProtect )) {
        DEBUGSTR("...No access (LastError=%d)", GetLastError());
        return TRUE;
      }

      // Overwrite the original address with the address of the new function
      if ( !WriteProcessMemory(GetCurrentProcess(),
                               &pThunk->u1.Function,
                               &pfnNewFunction,
                               sizeof(pfnNewFunction), NULL) ) {
        DEBUGSTR("error: %s(%d) LastError=%d", __FILE__, __LINE__, GetLastError());
        return FALSE;
      }

      // Put the page attributes back the way they were.
      VirtualProtect( &pThunk->u1.Function, sizeof(PVOID), flOldProtect, &flDummy);
      return TRUE;
    }
    pThunk++;     // Advance to next imported function address
  }
  return TRUE;    // Function not found
}

//-----------------------------------------------------------------------------
//   HookAPIAllMod
// Substitute a new function in the Import Address Table (IAT) of all
// the modules in the current process.
// Return FALSE on error and TRUE on success.
//-----------------------------------------------------------------------------

BOOL HookAPIAllMod(
    PSTR    pszFunctionModule,      // Module to intercept calls to
    PSTR    pszOldFunctionName,     // Function to intercept calls to
    PROC    pfnNewFunction          // New function (replaces old function)
    )
{
  HANDLE          hModuleSnap = NULL;
  MODULEENTRY32   me        = {0};
  BOOL fOk;

  // Take a snapshot of all modules in the current process.
  hModuleSnap = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, GetCurrentProcessId());

  if (hModuleSnap == (HANDLE)-1) {
    DEBUGSTR("error: %s(%d)", __FILE__, __LINE__);
    return FALSE;
  }

  // Fill the size of the structure before using it.
  me.dwSize = sizeof(MODULEENTRY32);

  // Walk the module list of the modules
  for (fOk = Module32First(hModuleSnap, &me); fOk; fOk = Module32Next(hModuleSnap, &me) ) {
    // We don't hook functions in our own module
    if (me.hModule != hDllInstance) {
      DEBUGSTR("Hooking in %s", me.szModule);
      // Hook this function in this module
      if (!HookAPIOneMod(me.hModule, pszFunctionModule, pszOldFunctionName, pfnNewFunction) ) {
        CloseHandle (hModuleSnap);
        DEBUGSTR("error: %s(%d)", __FILE__, __LINE__);
        return FALSE;
      }
    }
  }
  CloseHandle (hModuleSnap);
  return TRUE;
}

//-----------------------------------------------------------------------------
//   CaseFileNameOk
// Test if the filename match the filename retained by the system in a
// case-sensitive manner.
// Return TRUE if the filenames match, FALSE otherwise.
// If bWarn == TRUE, the function warns and always returns TRUE.
//-----------------------------------------------------------------------------

BOOL CaseFileNameOk( const char *Path )
{
  TCHAR LongPath[MAX_PATH];
  TCHAR ShortPath[MAX_PATH];
  DWORD len;
  TCHAR *pF, *pL, *pS, *pM;
  int stop;

  len = GetShortPathName(Path, ShortPath, MAX_PATH);
  len = GetLongPathName(ShortPath, LongPath, MAX_PATH);
  len = GetShortPathName(LongPath, ShortPath, MAX_PATH);
  if ( len == 0 ) return FALSE;

  DEBUGSTR("+F=%s", Path);
  DEBUGSTR("+S=%s", ShortPath);
  DEBUGSTR("+L=%s", LongPath);

  pF = (TCHAR *) Path + 2;
  pL = LongPath + 2;
  pS = ShortPath + 2;
  pM = pF;
  stop = 0;
  while(1) {
    while( *++pF == *++pL ) {
      if(*pF == '\\') {
        pM = pF;
        while(*++pS != '\\') {}
        stop = 0;
      }
      if(*pF==0) {
        stop = 0;
        goto end;
      }
    }
    if (stop == 1) {
      goto end;
    }
    else {
      stop = 1;
    }
    pF = pM;
    while ( *++pF == *++pS ) {
      if(*pF == '\\') {
        pM = pF;
        while(*++pL != '\\') {}
        stop = 0;
      }
      if(*pF==0) {
        stop = 0;
        goto end;
      }
    }
    if (stop == 1) {
      goto end;
    }
    else {
      stop = 1;
    }
    pF = pM;
  }

  end:
  if ( stop ) {
    if (bWarn) {
      warn("Warning: case sensitive mismatch between\nFile =%s\nLong =%s\nShort=%s\n ", Path, LongPath, ShortPath);
      return TRUE;
    }
    else {
      return FALSE;
    }
  }
  return TRUE;
}

//-----------------------------------------------------------------------------
//   My_CreateFileA(
// It is the new function that must replace the original CreateFileA( function.
// This function have exactly the same signature as the original one.
//-----------------------------------------------------------------------------

HANDLE
WINAPI
My_CreateFileA(
    LPCSTR lpFileName,
    DWORD dwDesiredAccess,
    DWORD dwShareMode,
    LPSECURITY_ATTRIBUTES lpSecurityAttributes,
    DWORD dwCreationDisposition,
    DWORD dwFlagsAndAttributes,
    HANDLE hTemplateFile
    )
{
  HANDLE hFile;

  hFile = CreateFileA(lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes, dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile);
  if ( !CaseFileNameOk(lpFileName) ) {
    CloseHandle(hFile);
    hFile = INVALID_HANDLE_VALUE;
    SetLastError(ERROR_FILE_NOT_FOUND);
  }
  return hFile;
}

//-----------------------------------------------------------------------------
//   My_stati64
// It is the new function that must replace the original _stati64 function.
// This function have exactly the same signature as the original one.
//-----------------------------------------------------------------------------

__int64 My_stati64( const char *path, struct _stati64 *buffer )
{
  __int64 status;

  status = _stati64( path, buffer );
  DEBUGSTR("_stati64_path=%s status=%d", path, status);
  if ( status == 0 ) { // file-status information is obtained
    if ( !CaseFileNameOk(path) ) {
      status = -1;
      errno = ENOENT;
    }
  }
  return status;
}

//-----------------------------------------------------------------------------
//   My_stat
// It is the new function that must replace the original _stat function.
// This function have exactly the same signature as the original one.
//-----------------------------------------------------------------------------

int My_stat( const char *path, struct _stat *buffer )
{
  int status;

  DEBUGSTR("_stat_path=%s", path);
  status = _stat( path, buffer );
  if ( status == 0 ) { // file-status information is obtained
    if ( !CaseFileNameOk(path) ) {
      status = -1;
      errno = ENOENT;
    }
  }
  return status;
}

//-----------------------------------------------------------------------------
//   My_GetFileAttributesA
// It is the new function that must replace the original GetFileAttributesA function.
// This function have exactly the same signature as the original one.
//-----------------------------------------------------------------------------

DWORD
WINAPI
My_GetFileAttributesA( LPCTSTR lpFileName )
{
  DWORD result;
  DEBUGSTR("GetFileAttributes_path=%s", lpFileName);
  result = GetFileAttributesA(lpFileName);
  if ( !CaseFileNameOk(lpFileName) ) {
    result = 0xFFFFFFFF;
    SetLastError(ERROR_FILE_NOT_FOUND);
    }
  return result;
}

//-----------------------------------------------------------------------------
//   My_rmdir
// It is the new function that must replace the original _rmdir function.
// This function have exactly the same signature as the original one.
//-----------------------------------------------------------------------------

int
My_rmdir( const char *dirname )
{
  int result;
  DEBUGSTR("_rmdir_path=%s", dirname);
  if ( !CaseFileNameOk(dirname) ) {
    result = -1;
    errno = ENOENT;
    }
  else {
    result = _rmdir(dirname);
  }
  return result;
}

//-----------------------------------------------------------------------------
//   My_chdir
// It is the new function that must replace the original _chdir function.
// This function have exactly the same signature as the original one.
//-----------------------------------------------------------------------------

int
My_chdir( const char *dirname )
{
  int result;
  DEBUGSTR("_chdir_path=%s", dirname);
  if ( !CaseFileNameOk(dirname) ) {
    result = -1;
    errno = ENOENT;
    }
  else {
    result = _chdir(dirname);
  }
  return result;
}

// ========== Initialisation

//-----------------------------------------------------------------------------
//   DllMain()
// Function called by the system when processes and threads are initialized
// and terminated.
//-----------------------------------------------------------------------------

BOOL WINAPI DllMain(HINSTANCE hInstance, DWORD dwReason, LPVOID lpReserved)
{
  BOOL bResult = TRUE;
  int i;
  char szMsvcrt[3][16] = {
                           "MSVCRT.dll",
                           "MSVCRT70.dll",
                           "MSVCRT71.dll"
                         };

  switch( dwReason )
  {
    case DLL_PROCESS_ATTACH:
      hDllInstance = hInstance;  // save Dll instance handle
      DEBUGSTR("hDllInstance = 0x%.8x", hDllInstance);
      bResult &= HookAPIAllMod("KERNEL32.dll", "CreateFileA", (PROC)My_CreateFileA);
      DEBUGSTR("CreateFileA = %d", bResult);

      bResult &= HookAPIAllMod("KERNEL32.dll", "GetFileAttributesA", (PROC)My_GetFileAttributesA);
      DEBUGSTR("GetFileAttributesA = %d", bResult);

      for (i=0; i<3; i++) {
        if ( GetModuleHandle(szMsvcrt[i]) ) {
          bResult &= HookAPIAllMod(szMsvcrt[i], "_stati64", (PROC)My_stati64);
          bResult &= HookAPIAllMod(szMsvcrt[i], "_stat", (PROC)My_stat);
          bResult &= HookAPIAllMod(szMsvcrt[i], "_rmdir", (PROC)My_rmdir);
          bResult &= HookAPIAllMod(szMsvcrt[i], "_chdir", (PROC)My_chdir);
          DEBUGSTR("%s functions = %d", szMsvcrt[i], bResult);
        }
      }

    case DLL_PROCESS_DETACH:
      break;
  }
  return (bResult);
}

MODULE = Win32::StrictFileNames   PACKAGE = Win32::StrictFileNames

void
_warn_on()
  CODE:
    bWarn = TRUE;


