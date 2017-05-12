#define _WIN32_WINNT 0x0500
#include <windows.h>
#include <shellapi.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Win32::Exe::InsertResourceSection      PACKAGE = Win32::Exe::InsertResourceSection 

PROTOTYPES: DISABLE

void
_insert_resource_section( szFileName, lpData, cbData  )
    LPCSTR szFileName
    LPVOID lpData
    DWORD cbData
  PPCODE:
    BOOL bDeleteExistingResources = FALSE;
    LPCTSTR lpType = RT_VERSION;
    LPCTSTR lpName = RT_VERSION;
    WORD wLanguage = MAKELANGID(LANG_NEUTRAL, SUBLANG_NEUTRAL);
    BOOL ok;
    BOOL fDiscard;
    
    HANDLE hUpdate = BeginUpdateResource(szFileName, bDeleteExistingResources);
    
    if (hUpdate == NULL) XSRETURN_UNDEF;
    
    ok = UpdateResource(hUpdate, lpType, lpName, wLanguage, lpData, cbData);
    
    fDiscard = ( ok ) ? FALSE : TRUE;
    
    if (!EndUpdateResource(hUpdate, fDiscard)) XSRETURN_UNDEF;
    
    if (!ok) XSRETURN_UNDEF;
    
    XSRETURN_YES;
