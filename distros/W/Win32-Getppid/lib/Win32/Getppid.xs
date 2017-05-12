#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "windows.h"
#include "tlhelp32.h"

MODULE = Win32::Getppid PACKAGE = Win32::Getppid

unsigned int
getppid()
  PROTOTYPE:
  PREINIT:
    HANDLE snapshot;
    DWORD parentpid, pid;
    BOOL good;
    PROCESSENTRY32 pe;
    int found;
  CODE:
    pid = GetCurrentProcessId();
    found = 0;
    snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    
    if(snapshot != INVALID_HANDLE_VALUE)
    {
      pe.dwSize = sizeof(pe);
      good = Process32First(snapshot, &pe);
      while(good)
      {
        if(pid == pe.th32ProcessID)
        {
          RETVAL = pe.th32ParentProcessID;
          found = 1;
          break;
        }
        good = Process32Next(snapshot, &pe);
      }
    }
    
    if(!found)
      croak("Unable to find parent process");
    
  OUTPUT:
    RETVAL
    
