#include <windows.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"


MODULE = Win32::SearchPath		PACKAGE = Win32::SearchPath			


SV *
SearchPath(szName, ...)
   const char *szName;

   PROTOTYPE: $;$

   CODE:
      DWORD dwRetn;
      char *pEnd  = NULL;
      char *pPath = NULL;
      char  szOutPath[MAX_PATH+1];

      if ( items > 1 )
      {
         STRLEN n_a;
         pPath = (char *)SvPV(ST(1), n_a);
      }
      /* MSDN bug: Q115826 in SearchPath*/
      SetLastError (NO_ERROR);

      dwRetn = SearchPath (pPath, szName, ".exe", MAX_PATH, szOutPath, &pEnd);
      if (!dwRetn)        
          XSRETURN_UNDEF;          /* Return undef */
      
      RETVAL = newSVpvn (szOutPath, strlen(szOutPath));

   OUTPUT:
      RETVAL


