// ----------------------------------------------------------------------------------
//  EnvProcessDll.dll
// Used by the Perl XS module Win32::EnvProcess
// Version 0.05
// ----------------------------------------------------------------------------------

#include <windows.h>
#include <stdio.h>
#define UNICODE
#include "EnvProcess.h"

void MapEnv    (void);
void SetEnv    (char *p);
void GetEnv    (char *p);
void DelEnv    (char *p);
void GetAllEnv (char *p);

/*
   It would be nicer here to avoid the temporary fixed-length arrays.
   The problem is that the target process might be linked to a
   single threaded RTL, so use of the heap would be dangerous.
*/

//--------------------------------------------------------------------
//   DLL Main
//--------------------------------------------------------------------

BOOL WINAPI DllMain(HINSTANCE hInstDLL, DWORD fdwReason, LPVOID LPReserved)
{

   switch(fdwReason)
   {
     case DLL_PROCESS_ATTACH:
     	/* This will be executed the first time we attach to a process */
        MapEnv();

        // Did not really want to do this, but can see no alternative
         FreeLibraryAndExitThread(hInstDLL, 0);

        break;
     case DLL_THREAD_ATTACH:
        /* This will be executed each time a new thread is created */
        MapEnv();
        break;
     case DLL_PROCESS_DETACH:
        break;
     case DLL_THREAD_DETACH:
        break;
     default:
        break;
  }

  return 1;
}

// -------------------------------------------------------------------

void MapEnv (void)
{
    char *p = NULL;

    HANDLE hMap = OpenFileMapping (FILE_MAP_WRITE, FALSE, FMONAME);

	if (hMap)
	   p = (char *)MapViewOfFile (hMap, FILE_MAP_WRITE, 0, 0, 0);

    if (p == NULL) {
       CloseHandle (hMap);
       return;
    }

    /* Get the command */
    if (p[0] == SETCMD)
       SetEnv(p);
    else
    if (p[0] == GETCMD)
       GetEnv(p);
    else
    if (p[0] == DELCMD)
       DelEnv(p);
    else
    if (p[0] == GETALLCMD)
       GetAllEnv(p);
    else
       p[0] = INVALID_CMD;

    UnmapViewOfFile (p);
    CloseHandle (hMap);
}

// -------------------------------------------------------------------

void SetEnv (char *p)
{
    char *p2;
    char *pszName;
    char *pszValue;
    int count;
    int i;
    BOOL bResults[MAXITEMS] = {0};

    /* Get the number of pairs */
    count = (int)p[1]/2;

    p2 = p + 2;
    for (i = 0; i < count; i++) {
       pszName = p2;
       pszValue = pszName + strlen(pszName) + 1;
       bResults[i] = SetEnvironmentVariable (pszName, pszValue);
       p2 = pszValue + strlen(pszValue) + 1;
    }

    /* Return the results */
    p2 = p + 2;
    memcpy (p2, bResults, count * sizeof(BOOL));

}  /* SetEnv */

// -------------------------------------------------------------------

void DelEnv (char *p)
{
    char *p2;
    char *pszName;
    int count;
    int i;
    BOOL bResults[MAXITEMS] = {0};

    /* Get the number of names */
    count = (int)p[1];

    p2 = p + 2;
    for (i = 0; i < count; i++) {
       pszName = p2;
       bResults[i] = SetEnvironmentVariable (pszName, NULL);
       p2 += strlen(pszName) + 1;
    }

    /* Return the results */
    p2 = p + 2;
    memcpy (p2, bResults, count * sizeof(BOOL));

}  /* DelEnv */

// -------------------------------------------------------------------
/*
   It would be nicer here to avoid the temporary array Names.
   The problem is that the target process might be linked to a
   single threaded RTL, so use of the heap would be dangerous.
*/

void GetEnv (char *p)
{
    char Names[MAXSIZE] = {0};
    char *p2;           /* pointer within FMO */
    char *pszName;      /* Pointer within local copy */
    int count;
    int i;
    DWORD dwlen;

    /* Get the number of variable names */
    count = (int)p[1];

    /* Make a copy of the names */
    p2 = p + 2;
    pszName = Names;

    for (i = 0; i < count; i++) {
	    strcpy (pszName, p2);

        dwlen = strlen(p2) + 1;
	    pszName += dwlen;
	    p2 += dwlen;
	}

    /* Get the values */
    p2 = p + 2;
    pszName = Names;

    dwlen = MAXSIZE - 2;  /* How many bytes do we have remaining? */

    for (i = 0; i < count; i++) {
       DWORD dwSize = GetEnvironmentVariable (pszName, p2, dwlen);

	   if (dwSize > dwlen) {
		   *p2 = '\0';
		   p[0] = VALUE_TOO_BIG;
		   break;
       }

	   if (dwSize == 0 ) {
		   *p2 = '\0';

		   if (GetLastError() == ERROR_ENVVAR_NOT_FOUND)
		       p[0] = ENVVAR_NOT_FOUND;
       }

	   pszName += strlen(pszName) + 1;
	   p2      += dwSize + 1;
       dwlen   -= dwSize + 1;    /* 0.05 change */
    }


}  /* GetEnv */

// -------------------------------------------------------------------

void GetAllEnv (char *p)
{
    char *p2;          /* pointer within FMO */
    int count = 0;     /* Number of items found */
    size_t len;        /* Number of bytes remaining */

    LPTSTR lpszVariable;
    LPVOID lpvEnv;

    // Get a pointer to the environment block.

    lpvEnv = GetEnvironmentStrings();

    // If the returned pointer is NULL, exit.
    if (lpvEnv == NULL) {
        p[0] = ENVVAR_NOT_FOUND;
        p[1] = '\0';
        return;
    }

	/* Get the values */
	p2 = p + 2;

	len = MAXSIZE - 2;  /* How many bytes do we have remaining? */

    // Variable strings are separated by NULL byte, and the block is
    // terminated by a NULL byte.

    for (lpszVariable = (LPTSTR)lpvEnv; *lpszVariable; /* no-op */)
	{
	    size_t dwSize = strlen(lpszVariable);

	    if (dwSize > len) {
    	    *p2 = '\0';
    	    p[0] = VALUE_TOO_BIG;
    	    break;
        }

        if (count >= MAXITEMS / 2) {
		    p[0] = ENV_TOO_MANY;
		    break;
	    }

	    if (dwSize == 0 ) {
		    *p2 = '\0';
        }
        else {
	        strcpy (p2, lpszVariable);
	        lpszVariable += dwSize + 1;
	        count++;
	    }

	    p2  += dwSize + 1;
        len -= dwSize + 1;  /* 0.05 change */
    }

    p[1] = count;
    FreeEnvironmentStrings(lpvEnv);

}   // GetAllEnv

// -------------------------------------------------------------------

