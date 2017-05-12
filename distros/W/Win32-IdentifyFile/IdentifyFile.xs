#include <windows.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* Global Data */

#define MY_CXT_KEY "Win32::IdentifyFile::_guts" XS_VERSION

typedef struct {
    /* Put Global Data in here */
    AV *Handles;
} my_cxt_t;

START_MY_CXT

#include "const-c.inc"
      
MODULE = Win32::IdentifyFile		PACKAGE = Win32::IdentifyFile		

INCLUDE: const-xs.inc

BOOT:
{
    MY_CXT_INIT;
    /* If any of the fields in the my_cxt_t struct need
       to be initialised, do it here.
     */
    MY_CXT.Handles = newAV();
}

int
CloseIdentifyFile()
   
   PROTOTYPE: 
   
   CODE:
   
     dMY_CXT;
     
     while (1)
     {
         HANDLE hFile;
     
         SV *sv = av_shift(MY_CXT.Handles);
         if (sv == &PL_sv_undef) break;
         
         hFile = (HANDLE)SvIV(sv);
         
         if (!CloseHandle(hFile))
            XSRETURN(0);
     }
     
     RETVAL = 1;
     
  OUTPUT:
     RETVAL  



SV *
IdentifyFile(szName)
   const char *szName;

   PROTOTYPE: $
   
   CODE:
   
      HANDLE hFile;
      DWORD dwAttributes;
      int i;

      BY_HANDLE_FILE_INFORMATION Info = {0};
      char c_buffer[257];
      
      /* DEBUG 
      PerlIO * debug = PerlIO_open ("debug.txt", "a");
      PerlIO_printf(debug, "\nEntry, File: %s\n", szName);
      */
      
      /* Loose the arguments on the stack */
      for ( i = 0; i < items; i++)
         POPs;  

      /* Sanity check - probably over the top */
      /*
      {
         char szVolumeName[MAX_PATH] = {0};
         char osVolName   [MAX_PATH] = {0};
         char osFsType    [MAX_PATH] = {0};
         BOOL GetVolumePathName(szFile, szVolumeName, MAX_PATH);
	   
         strcat(szVolumeName, "\\");

         GetVolumeInformation( VolumeName, osVolName, MAX_PATH, 
                               NULL, NULL, NULL, osFsType, MAX_PATH);
         if(strcmp(osFsType, "NTFS")) {
            XSRETURN(0)
         }

      }
      */
      
      /* Might be nice to allow a file handle to be passed instead of
         a name, but would that be useful?  Probably not. */
         
      /* Test file type */
      dwAttributes = GetFileAttributes(szName);
            
      if (dwAttributes == INVALID_FILE_ATTRIBUTES)
      {
         /* Error should be in $^E */
         XSRETURN(0);   /* Return an empty list, */
      }
      
      /* Directory support */
      if (dwAttributes & FILE_ATTRIBUTE_DIRECTORY)
      {
         /* Note FILE_FLAG_BACKUP_SEMANTICS, which is the strange
            attribute required to get a handle to a directory.  */ 
            
         hFile = CreateFile (szName, FILE_LIST_DIRECTORY,
                             FILE_SHARE_READ|FILE_SHARE_DELETE, NULL, OPEN_EXISTING,  
                             FILE_FLAG_BACKUP_SEMANTICS, NULL);
      }
      else
      {
         hFile = CreateFile (szName, GENERIC_READ, 
                             FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
      }
      
      {
          /* Save the handle for later */
          dMY_CXT;
          sprintf (c_buffer, "%d", hFile);
          av_push (MY_CXT.Handles, newSVpvn (c_buffer, strlen (c_buffer)));
      }
      
      if (!GetFileInformationByHandle(hFile, &Info))
      {
         /* On error, calls SetLastError, which sets $^E */
             
         /* DEBUG 
         PerlIO_printf (debug, "INVALID_HANDLE_VALUE\n");
         PerlIO_close (debug);
         */
               
         XSRETURN(0);   /* Return an empty list, */
      }
      
      
      if (GIMME == G_SCALAR) { 
                
         sprintf (c_buffer, "%d", Info.dwVolumeSerialNumber);           
         sprintf (c_buffer, "%s:%d", c_buffer, Info.nFileIndexHigh );           
         sprintf (c_buffer, "%s:%d", c_buffer, Info.nFileIndexLow);
      
         RETVAL = newSVpvn (c_buffer, strlen(c_buffer));
      }
      else {
         int iArgs = 0;
         size_t iLen = 0;
         
         /* Info.dwVolumeSerialNumber */
         sprintf (c_buffer, "%d", Info.dwVolumeSerialNumber);
         iLen = strlen (c_buffer);            
         XPUSHs(sv_2mortal(newSVpvn (c_buffer, iLen))); 
         iArgs++;
      
         /* Info.nFileIndexHigh */
         sprintf (c_buffer, "%d", Info.nFileIndexHigh );
         iLen = strlen (c_buffer);            
         XPUSHs(sv_2mortal(newSVpvn (c_buffer, iLen))); 
         iArgs++;
      
         /* Info.nFileIndexLow */
         sprintf (c_buffer, "%d", Info.nFileIndexLow);
         iLen = strlen (c_buffer);            
         XPUSHs(sv_2mortal(newSVpvn (c_buffer, iLen))); 
         iArgs++;
      
         /* Return the list on the stack */
         XSRETURN(iArgs);
      }
   
   OUTPUT:
         RETVAL
      