/* VMS::FindFile - Implements some simple hooks to give VMS perl
** a function similar to DCL's f$search().
**
** Copyright (c) 2002 by Forrest Cahoon (forrest@cpan.org).
**
** This source code is free software; you can redistribute it and/or modify
** it under the same terms as Perl itself. 
**
** The routines here are used internally by FindFile.pm.  You
** probably don't want to call them directly (although I certainly
** won't stop you).
**
** Version 0.1 written 21-SEP-2000
**
** Version 0.9 04-DEC-2000
**    Corrected error handling.
** 
** Version 0.91 25-OCT-2002 First CPAN version.  Uses ppport.h.
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#if defined(__DECC) || defined(__DECCXX)
#  include <lib$routines.h>
#  include <starlet.h>
#endif

#include <descrip.h>
#include <ssdef.h>

MODULE = VMS::FindFile     PACKAGE = VMS::FindFile     PREFIX=vmsff
PROTOTYPES: DISABLE

SV *
vmsff_find_file(filespec, context)
   char *filespec;
   int context;

   PREINIT:
   struct dsc$descriptor_s filespec_dsc;
   char resultant[4096]; /* NAML$C_MAXRSS + 1 */
   struct dsc$descriptor_s resultant_dsc;
   int status, i;
   PPCODE:
   
   filespec_dsc.dsc$w_length=strlen(filespec);
   filespec_dsc.dsc$b_dtype=DSC$K_DTYPE_T;
   filespec_dsc.dsc$b_class=DSC$K_CLASS_S;
   filespec_dsc.dsc$a_pointer=filespec;

   resultant_dsc.dsc$w_length=sizeof(resultant)-1;
   resultant_dsc.dsc$b_dtype=DSC$K_DTYPE_T;
   resultant_dsc.dsc$b_class=DSC$K_CLASS_S;
   resultant_dsc.dsc$a_pointer=resultant;

   status=lib$find_file(&filespec_dsc,&resultant_dsc,&context,
                        0,0,0,0);

   if (!(status & 1)) {
      set_errno(EVMSERR);
      set_vaxc_errno(status);
      lib$find_file_end(&context);
      resultant[0] = '\0';
      context = 0;
   } else {
      i = resultant_dsc.dsc$w_length;
      while (i > 0 && resultant[--i] == ' ');
      if (i == 0) i--;
      resultant[i+1] = '\0';
   }

   EXTEND(SP,2);
   PUSHs(sv_2mortal(newSVpv(resultant,0)));
   PUSHs(sv_2mortal(newSViv(context)));

void
vmsff_find_file_end(context)

   int context;

   CODE:
   lib$find_file_end(&context);
