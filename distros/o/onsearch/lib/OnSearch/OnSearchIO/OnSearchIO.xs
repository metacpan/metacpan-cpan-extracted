
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef PERLIO_LAYERS

#include "perliol.h"

#define USE_STDIO
#include <perlio.h>
#include <stdio.h>

#include <errno.h>
#include <string.h>

extern int errno;

typedef struct _PerlIOOnSearch {
	struct _PerlIO base;
	SV *var;
	Off_t posn;
} PerlIOOnSearch;

PerlIO *
PerlIOOnSearch_open (pTHX_ PerlIO_funcs * self, 
		     PerlIO_list_t *layers,
		     IV n,
		     const char *mode,
		     int fd,
		     int imode,
		     int perm,
		     PerlIO *f,
		     int narg,
		     SV **args) {
  SV *arg = (narg > 0) ? *args : PerlIOArg;
  if (SvROK(arg) || SvPOK(arg)) {
    PerlIO *pf;
    FILE *f;
    if ((f = fopen (SvPV (arg, PL_na), mode)) == NULL) {
      die ("open %s: %s.", SvPV (arg, PL_na), strerror (errno));
      return NULL;
    }
    PerlIO_printf (PerlIO_stderr (), "%d\n\n", fileno (f));
    pf = PerlIO_importFILE (f, mode);
	
    if (pf = PerlIO_push (aTHX_ pf, self, mode, arg)) {
      char *t = mode;
      PerlIOBase(pf) -> flags |= PERLIO_F_OPEN;
      switch (*t++) {
      case 'r':
	PerlIOBase(pf) -> flags |= PERLIO_F_CANREAD;
	break;
      case 'w':
	PerlIOBase(pf) -> flags |= PERLIO_F_CANWRITE;
	break;
      case 'a':
	PerlIOBase(pf) -> flags |= PERLIO_F_APPEND;
	break;
      case '+':
	PerlIOBase(pf) -> flags |= 
	  (PERLIO_F_CANWRITE | PERLIO_F_CANREAD);
	break;
      }
    }
    return pf;
  }
  return NULL;
}

SSize_t PerlIOOnSearch_read (pTHX_ PerlIO *f,
			     void *vbuf,
			     Size_t count) {
  size_t i = -1;
  FILE *os_fp = PerlIO_exportFILE (f, NULL); /* Mode from PerlIO *f. */
  i = fread (vbuf, sizeof (char), count, os_fp);
  if (i < 0)
    warn ("read: %s.", strerror (errno));
  if (i != count) 
    PerlIOBase (f) -> flags |= PERLIO_F_EOF;
  return i;
}
			     
PerlIO_funcs PerlIO_onsearch = {
  sizeof (PerlIO_funcs),
  "onsearch",
  sizeof (PerlIOOnSearch),
  PERLIO_K_BUFFERED,
  PerlIOBase_pushed,
  PerlIOBase_popped,
  PerlIOOnSearch_open,
  PerlIOBase_binmode,
  NULL,                     /* Getarg */
  PerlIOBase_fileno,
  PerlIOBase_dup,
  PerlIOOnSearch_read,
  PerlIOBase_unread,
  NULL,                     /* Write */
  NULL,                     /* Seek */
  NULL,                     /* Tell */
  PerlIOBase_close,
  NULL,                     /* Flush */
  NULL,                     /* Fill */
  PerlIOBase_eof,
  PerlIOBase_error,
  PerlIOBase_clearerr,
  PerlIOBase_setlinebuf,
  NULL,                     /* Get_base   */
  NULL,                     /* Get_bufsiz */
  NULL,                     /* Get_ptr    */
  NULL,                     /* Get_cnt    */
  NULL,                     /* Set_ptrcnt */
};

#endif

MODULE = PerlIO::OnSearchIO	   PACKAGE = PerlIO::OnSearchIO
PROTOTYPES: ENABLE


BOOT: 
{
#ifdef PERLIO_LAYERS
 PerlIO_define_layer(aTHX_ &PerlIO_onsearch);
#endif
}


