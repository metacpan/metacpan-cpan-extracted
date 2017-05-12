#include <windows.h>
#include <tlhelp32.h>
#include <stdio.h>
#include <stdlib.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

#include "EnvProcess.h"

/* 
   Version 0.06
   
   Limitations:

   Total size of variable names and values: MAXSIZE
   Total number of environment variables:   MAXITEMS/2
   
   Locking: the entire sequence is serial because a named FMO is used.  
        Creating the File Mapping Object(FMO), writing to it,
        and running the DLL in the other process, is protected by a Mutex.
        
        It is therefore possible that calls may block.
        
   If an odd number of items are supplied in the list,  
   the final variable name specified will have no value.
   
   The format of the FMO is 
      Command byte (SETCMD or GETCMD)
      Number of items
      Items
      
   FreeLibrary?  
   This could mean implementing using OO, so a destructor can be used.
   or, is this an issue only with the copy in tests?
   
   Vista

   Bug: non-existent environment variable returns the PID


*/

static void ProcessError(const char *szMessage);
static void SetError (char chErr);
static BOOL FindDll(void);
static int iGetPid (const char *pszExeName);
static char * strtolower (char * szIn);

#define DLLNAME      "EnvProcessDll.dll"
#define MUTEXNAME    "mutexPerlTempEnvVar"
#define MAXPROCESSES 1024
#define DEBUGx
/* ------------------------------------------------------------------ */

static void ProcessError(const char *szMessage)
{
    char* buffer;
    DWORD dwErr = GetLastError();
    
    /* DEBUG */
    PerlIO * debug = PerlIO_open (".\\debug.txt", "a");
    
    FormatMessage( 
                FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
                0,
                dwErr,
                MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // Default language
                (LPTSTR) &buffer,
                0,
                0);
    
    if (dwErr != ERROR_SUCCESS) 
       PerlIO_printf(debug, "%s: %s", szMessage, buffer);
    else
       PerlIO_printf(debug, "%s\n", szMessage);
    
    PerlIO_close (debug);
    
    LocalFree(buffer);
    
    /* APIs above would have reset it */
    SetLastError(dwErr);

}  

/* ------------------------------------------------------------------ */

static void SetError (char chErr)
{
     DWORD dwErr;
       
     switch (chErr)
     {
         case INVALID_CMD:
             dwErr = ERROR_INVALID_FLAG_NUMBER;
             break;
         case VALUE_TOO_BIG:
             dwErr = ERROR_NOT_ENOUGH_MEMORY;
             break;
         case ENVVAR_NOT_FOUND:
             dwErr = ERROR_ENVVAR_NOT_FOUND;
             break;
         case ENV_TOO_MANY:
             dwErr = ERROR_OUTOFMEMORY;
             break;
         default:
             dwErr = ERROR_INVALID_FUNCTION;
             break;
     }

     SetLastError(dwErr);
 
 }    /* SetError */
 
/* ------------------------------------------------------------------ */

static DWORD dwGetOS ()
{
   OSVERSIONINFO OsVer = {0};
   OsVer.dwOSVersionInfoSize = sizeof (OsVer);
   GetVersionEx (&OsVer);

   return OsVer.dwMajorVersion;
}

/* ------------------------------------------------------------------ */

static char * strtolower (char * szIn) {
    char * p;
    
    for (p = szIn; *p; p++) {
        *p = toLOWER(*p);         // perlapi
    }
    return szIn;
}

/* ------------------------------------------------------------------ */

static int getppid(void) {

    HANDLE hToolSnapshot;
    PROCESSENTRY32 Pe32 = {0};
    BOOL bResult;
    DWORD PID;
    DWORD PPID = 0;
    
    PID = GetCurrentProcessId ();

    hToolSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hToolSnapshot == INVALID_HANDLE_VALUE) {
        return 0;
    }

    Pe32.dwSize = sizeof(PROCESSENTRY32); 

    bResult = Process32First(hToolSnapshot, &Pe32); 

    if (!bResult) 
        return 0;
    
    while ( Process32Next(hToolSnapshot, &Pe32) ) {
        if (Pe32.th32ProcessID == PID) {
            PPID = Pe32.th32ParentProcessID;
            break;
        }
    }

    /* Expected */
    if (GetLastError() == ERROR_NO_MORE_FILES) {
        SetLastError(ERROR_SUCCESS);
    }

    return PPID;
}

/* ------------------------------------------------------------------ */

static BOOL FindDll(void) 
{
    /* Can we find the DLL? 
       This is not useful for production, since it only tells
       us if Perl can find the Dll, not the other process, 
       which may have a different PATH
    */
    
    BOOL bRetn = TRUE;
    TCHAR tcBuffer[MAX_PATH];
    LPTSTR lpFilePart;
    DWORD dwLen = 
             SearchPath(NULL, DLLNAME, NULL, MAX_PATH, tcBuffer, &lpFilePart);
         
    if ( dwLen == 0 )  {
       bRetn = FALSE;
    }
    
    return bRetn;
}

/* ------------------------------------------------------------------ */

BOOL ConnectToProcess(int nPid) {

   DWORD  dwTid;
   HANDLE hProcess;
   HANDLE hThread;
   void * Remotep = NULL;
   int    cb = strlen(DLLNAME) + 1;
   
   hProcess = OpenProcess (PROCESS_ALL_ACCESS, // PROCESS_CREATE_THREAD,
                           FALSE, nPid);

   if ( hProcess == NULL )
   {
      /*ProcessError("OpenProcess");*/
      return FALSE;
   }

   Remotep = VirtualAllocEx (hProcess, NULL, cb, MEM_COMMIT, 
                             PAGE_READWRITE);

   if ( Remotep == NULL )
   {
      /*ProcessError("VirtualAllocEx");*/
      CloseHandle(hProcess);
      return FALSE;
   }

   if (!WriteProcessMemory (hProcess, Remotep, DLLNAME, cb, NULL))
   {
      /*ProcessError("WriteProcessMemory");*/
      CloseHandle(hProcess);
      return FALSE;   /* Correction version 0.04 */
   }
  
   hThread = CreateRemoteThread (hProcess, NULL, 0, 
                        (LPTHREAD_START_ROUTINE)LoadLibraryA, Remotep, 0, 
                        &dwTid);

   if ( hThread == NULL )
   {
      /*ProcessError("CreateRemoteThread");*/
      VirtualFreeEx(hProcess, Remotep, 0, MEM_RELEASE);   /* v0.04 */
      CloseHandle(hProcess);
      return FALSE;
   }

   WaitForSingleObject (hThread, INFINITE);
   CloseHandle(hThread);
   
   VirtualFreeEx(hProcess, Remotep, 0, MEM_RELEASE);   /* v0.04 */
   CloseHandle(hProcess);

   return TRUE;

}  /* ConnectToProcess */

/* ------------------------------------------------------------------ */


MODULE = Win32::EnvProcess		PACKAGE = Win32::EnvProcess		

int 
SetEnvProcess(nPid, ...)
    int nPid;
   
    PROTOTYPE: $@

    CODE:

    DWORD  dwRetn;
    HANDLE hMutex; 
    HANDLE hMap; 
    char *p = NULL;
    char *p2;
    int i;
    int NumVars = 0;   /* Used for a return code */
    int NumSent;
    
    /* Default return value - false (On error) */
    RETVAL = 0; 

    /* Was a PID supplied? */
    if (nPid == 0)
    {
       nPid = getppid();
       if (!nPid)
           XSRETURN_UNDEF;
    }
 
    /* 'items' is the number of arguments, placed by perl */
   
    if ( items < 2 ) {
       XSRETURN_UNDEF;
    }
      
    /* Can we find the DLL? */
    if (!FindDll())
        XSRETURN_UNDEF;

        
    /* Create and grab the mutex */
    hMutex = CreateMutex (NULL, FALSE, MUTEXNAME);
   
    if (hMutex == NULL) {
       /* ProcessError("CreateMutex"); */
       XSRETURN_UNDEF;
    }
  
    dwRetn = WaitForSingleObject (hMutex, INFINITE);
    
    if (dwRetn != WAIT_OBJECT_0) {
       /* If we get back WAIT_ABANDONED then we exit anyway */
       /* Any others waiting will also get WAIT_ABANDONED   */
       CloseHandle (hMutex);
       XSRETURN_UNDEF;
    }
  
    /* Create the shared memory area */

    p = NULL;

    hMap = CreateFileMapping (INVALID_HANDLE_VALUE, NULL, PAGE_READWRITE,
                              0, MAXSIZE, FMONAME);

    if (hMap)
        p = MapViewOfFile (hMap, FILE_MAP_ALL_ACCESS, 0, 0, 0);

    if (p == NULL) {
        CloseHandle (hMap);
        ReleaseMutex(hMutex);     
        CloseHandle(hMutex);
        XSRETURN_UNDEF;
    }

    p2 = p+2;   /* Reserve the first two bytes */
    
    for (i = 1; i < items; i++) {
       STRLEN n_a;
       strcpy (p2, (char *)SvPV(ST(i), n_a));       
       p2 += strlen(p2)+1;
       
       /* avoid overflowing the shared area */
       if ((p2 - p) >= MAXSIZE || i >= MAXITEMS) {   
          break;
       }
    }
    
    /* Tweek the number of items */
    NumVars = i - 1;
    if ( NumVars > MAXITEMS )
       NumVars = MAXITEMS;
    
    /* Check for variables with no value */
    if (NumVars % 2) {
        /* Add an extra NULL value */
        p2 = '\0';
        NumVars++;
    }
    
    /* Set the command in the first byte  */
    p[0] = SETCMD;
    /* Place the count in the second byte */
    p[1] = NumVars;
       
    /* Loose the arguments on the stack */
    for ( i = 0; i < items; i++)
        POPs;  
         
   /* Find the other process */
   if (!ConnectToProcess(nPid))
   {
      UnmapViewOfFile (p);
      CloseHandle (hMap);

      ReleaseMutex(hMutex);     
      CloseHandle(hMutex);
      XSRETURN_UNDEF;
   }

   /* Read the results */
   p2 = p + 2;
   NumVars /= 2;
   NumSent = NumVars;
   
   for (i = 0; i < NumSent; i++) {
      BOOL bResult = (BOOL)*p2;
      
      if (!bResult) NumVars--;
      p2 += sizeof(BOOL);
   }

   UnmapViewOfFile (p);
   CloseHandle (hMap);

   /* Mutex release moved in v.0.05 */
   ReleaseMutex(hMutex);
   CloseHandle(hMutex);

   RETVAL = (int)NumVars;
   
   OUTPUT:
         RETVAL



SV * 
GetEnvProcess(nPid, ...)
    int nPid;
   
    PROTOTYPE: $@

    CODE:

    DWORD  dwRetn;
    HANDLE hMutex; 
    HANDLE hMap; 
    char *p;
    char *p2;
    int i;
    int NumVars = 0;       /* Used for a return code */
    BOOL bGetAll = FALSE;  /* A bit of a hack */

    /* Default return value - false (On error) */
    RETVAL = 0; 
      
    /* Can we find the DLL? 
       Removed in v0.06
    if (!FindDll())
        XSRETURN_UNDEF;  */
   
    /* Was a PID supplied? */
    if (nPid == 0)
    {
       nPid = getppid();
       if (!nPid)
           XSRETURN_UNDEF;
    }
    
    /* Create and grab the mutex */
    hMutex = CreateMutex (NULL, FALSE, MUTEXNAME);
   
    if (hMutex == NULL) {
       /*ProcessError("CreateMutex");*/
       XSRETURN_UNDEF;
    }
  
    /* 0.06 change */
    if (GetLastError() == ERROR_ALREADY_EXISTS) {
        SetLastError(ERROR_SUCCESS);
    }

    dwRetn = WaitForSingleObject (hMutex, INFINITE);
    
    if (dwRetn != WAIT_OBJECT_0) {
       /* If we get back WAIT_ABANDONED then we exit anyway */
       /* Any others waiting will also get WAIT_ABANDONED   */
       /* ProcessError("WaitForSingleObject"); */
       CloseHandle (hMutex);
       XSRETURN_UNDEF;
    }
  
    /* Create the shared memory area */

    p = NULL;

    hMap = CreateFileMapping (INVALID_HANDLE_VALUE, NULL, PAGE_READWRITE,
                 0, MAXSIZE, FMONAME);

    if (hMap)
        p = MapViewOfFile (hMap, FILE_MAP_ALL_ACCESS, 0, 0, 0);

    if (p == NULL) {
        /* ProcessError("CreateFileMapping/MVOF"); */
        CloseHandle (hMap);
        ReleaseMutex(hMutex);     
        CloseHandle(hMutex);
        XSRETURN_UNDEF;
    }
    
     /*
     if (GetLastError() != ERROR_SUCCESS) {
         ProcessError("CreateFileMapping/MVOF test");      
     }
    */
    
    p2 = p+2;   /* Reserve the first two bytes */
    
    if (items > 1) {
    
       for (i = 1; i < items; i++) {
          STRLEN n_a;
          strcpy (p2, (char *)SvPV(ST(i), n_a));       
          p2 += strlen(p2)+1;
       
          /* avoid overflowing the shared area */
          if ((p2 - p) >= MAXSIZE || i >= MAXITEMS) {   
             break;
          }
       }
    
       /* Tweek the number of items */
       NumVars = i - 1;
       if ( NumVars > MAXITEMS )
          NumVars = MAXITEMS;
        
       /* Set the command in the first byte  */
       p[0] = GETCMD;
       /* Place the count in the second byte */
       p[1] = NumVars;
    }
    else {
       /* Set the command in the first byte  */
       p[0] = GETALLCMD;
       p[1] = 0;
       bGetAll = TRUE;
    }
    
    /* Loose the arguments on the stack */
    for ( i = 0; i < items; i++)
        POPs;  
         
   /* Find the other process */
   if (!ConnectToProcess(nPid))
   {
      /* ProcessError("ConnectToProcess"); */
      UnmapViewOfFile (p);
      CloseHandle (hMap);

      ReleaseMutex(hMutex);     
      CloseHandle(hMutex);
      XSRETURN_UNDEF;
   }
 
   /* Pick up the first byte of the FMO, which may contain an error code */
   if (p[0] != GETCMD && p[0] != GETALLCMD) {      
       SetError (p[0]);		      
   }
   
   /* Get the number of variables from the FMO */
   if (bGetAll) {
       NumVars = p[1];
   }
   
   /* Read the returned variables and place them on the stack */
   p2 = p + 2;
      
   for (i = 0; i < NumVars; i++) {   
      
      /* 0.04 change */
      if (*p2) {
          int iLen = strlen(p2);
          XPUSHs(sv_2mortal(newSVpvn (p2, iLen))); 
          p2 += iLen + 1;
       }
       else {   /* 0.05 change */
          XPUSHs(sv_2mortal(newSVpvn (p2, 0)));
          p2++;
       }
   }
   
   UnmapViewOfFile (p);
   CloseHandle (hMap);

   /* 0.06 change, moved these statements later */
   ReleaseMutex(hMutex);   
   CloseHandle(hMutex);
   
   /*
   if (GetLastError() != ERROR_SUCCESS) {
       ProcessError("On Exit");
   }
   */
   
   /* Return the list on the stack */
   XSRETURN(NumVars);

   OUTPUT:
         RETVAL

int 
DelEnvProcess (nPid, ...)
    int nPid;
   
    PROTOTYPE: $@

    CODE:

    DWORD  dwRetn;
    HANDLE hMutex;
    HANDLE hMap; 
    char *p;
    char *p2;
    int i;
    int NumVars = 0;   /* Used for a return code */
    int NumSent;
    
    /* Default return value - false (On error) */
    RETVAL = 0; 

    /* Was a PID supplied? */
    if (nPid == 0)
    {
       nPid = getppid();
       if (!nPid)
           XSRETURN_UNDEF;
    }

    /* 'items' is the number of arguments, placed by perl */
   
    if ( items < 2 ) {
       XSRETURN_UNDEF;
    }
      
    /* Can we find the DLL? */
    if (!FindDll())
        XSRETURN_UNDEF;
        
    /* Create and grab the mutex */
    hMutex = CreateMutex (NULL, FALSE, MUTEXNAME);
   
    if (hMutex == NULL) {
       XSRETURN_UNDEF;
    }
  
    dwRetn = WaitForSingleObject (hMutex, INFINITE);
    
    if (dwRetn != WAIT_OBJECT_0) {
       /* If we get back WAIT_ABANDONED then we exit anyway */
       /* Any others waiting will also get WAIT_ABANDONED   */
       CloseHandle (hMutex);
       XSRETURN_UNDEF;
    }
  
    /* Create the shared memory area */

    p = NULL;

    hMap = CreateFileMapping (INVALID_HANDLE_VALUE, NULL, PAGE_READWRITE,
                              0, MAXSIZE, FMONAME);

    if (hMap)
        p = MapViewOfFile (hMap, FILE_MAP_ALL_ACCESS, 0, 0, 0);

    if (p == NULL) {
        CloseHandle (hMap);
        ReleaseMutex(hMutex);     
        CloseHandle(hMutex);
        XSRETURN_UNDEF;
    }

    p2 = p+2;   /* Reserve the first two bytes */
    
    for (i = 1; i < items; i++) {
       STRLEN n_a;
       strcpy (p2, (char *)SvPV(ST(i), n_a));       
       p2 += strlen(p2)+1;
       
       /* avoid overflowing the shared area */
       if ((p2 - p) >= MAXSIZE || i >= MAXITEMS) {   
          break;
       }
    }
    
    /* Tweek the number of items */
    NumVars = i - 1;
    if ( NumVars > MAXITEMS )
       NumVars = MAXITEMS;
    
    /* Set the command in the first byte  */
    p[0] = DELCMD;
    /* Place the count in the second byte */
    p[1] = NumVars;
       
    /* Loose the arguments on the stack */
    for ( i = 0; i < items; i++)
        POPs;  
         
   /* Find the other process */
   if (!ConnectToProcess(nPid))
   {
      UnmapViewOfFile (p);
      CloseHandle (hMap);
      ReleaseMutex(hMutex);     
      CloseHandle(hMutex);
      XSRETURN_UNDEF;
   }

   /* Read the results */
   p2 = p + 2;
   NumSent = NumVars;
   
   for (i = 0; i < NumSent; i++) {
      BOOL bResult = (BOOL)*p2;
      
      if (!bResult) NumVars--;
      p2 += sizeof(BOOL);
   }

   /* Mutex release moved in v.0.05 */
   ReleaseMutex(hMutex);
   CloseHandle(hMutex);

   UnmapViewOfFile (p);
   CloseHandle (hMap);

   RETVAL = (int)NumVars;
   
   OUTPUT:
         RETVAL


SV * 
GetPids(...)

    CODE:

    DWORD dwRetn = 0;
    int PIDs = 0;
    size_t i;
    char szExeName[MAX_PATH];
    HANDLE hToolSnapshot;
    PROCESSENTRY32 Pe32 = {0};
    BOOL bResult;
        
    if ( items == 0 ) {
        PIDs = getppid();
        /* Place the PID on the stack */
        XPUSHs(sv_2mortal(newSVuv(PIDs))); 
        XSRETURN(1);
    }
    
    {
        /* Convert to lowercase for the comparison */
        STRLEN n_a;
        strcpy (szExeName, (char *)SvPV(ST(0), n_a));
        strtolower (szExeName);
    }
    
    /* Loose the arguments on the stack */
    for ( i = 0; i < (size_t)items; i++)
        POPs;  


    hToolSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hToolSnapshot == INVALID_HANDLE_VALUE) {
       XSRETURN_UNDEF;
    }

    Pe32.dwSize = sizeof(PROCESSENTRY32); 

    bResult = Process32First(hToolSnapshot, &Pe32); 

    if (!bResult) {
       XSRETURN_UNDEF;
    }
    
    while ( Process32Next(hToolSnapshot, &Pe32) ) {

        strtolower (Pe32.szExeFile);
      
        if (!strcmp(Pe32.szExeFile, szExeName)) {
           /* Place the PID on the stack */
           XPUSHs(sv_2mortal(newSVuv(Pe32.th32ProcessID))); 
           PIDs++;
        }
    }

    /* Expected */
    if (GetLastError() == ERROR_NO_MORE_FILES) {
        SetLastError(ERROR_SUCCESS);
    }

    XSRETURN(PIDs);
    
    /* RETVAL=PIDs; */

    OUTPUT:
         RETVAL
