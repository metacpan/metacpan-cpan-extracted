/* $Id: StringSearch.xs,v 1.2 2005/07/31 22:50:46 kiesling Exp $  */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>
#include <errno.h>

extern int errno;

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = EINVAL;
    return 0;
}

/* 
   Search_buffer () uses the Boyer-Moore algorithm's technique 
   of searching from the rightmost character of the pattern 
   string.  It does not maintain a skip table due to the 
   overhead of Perl memory allocation.

   Returns a -1 terminated array of match positions in the offets
   argument.
*/
void
search_buffer (char *pattern, char *buffer, long long *offsets) {

  int s, skip;
  long long n;
  int n_offsets;
  int buffer_length, searchable_length;
  int pattern_length;
  char *p, c;

  buffer_length = strlen (buffer) - 1;
  pattern_length = strlen (pattern) - 1;
  if (buffer_length < pattern_length) {
    offsets[0] = -1L;
    return;
  }
  searchable_length = buffer_length - pattern_length;

  n_offsets = 0;
  n = 0L;
  while (n <= searchable_length) {
    skip = 0;
    for (s = pattern_length; s >= 0; s--) {
      if (pattern[s] == buffer[n + s]) {
	++skip;
      } else {
	++n;
	break;
      }
    }
    if (s < 0) {
      offsets[n_offsets++] = n;
      offsets[n_offsets] = -1;
    }
    n += skip;
  }
}

MODULE = OnSearch::StringSearch	   PACKAGE = OnSearch::StringSearch
PROTOTYPES: ENABLE


double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL

SV *
_strindex (pattern, buffer)
        char *pattern = SvPV (ST(0), PL_na);
        char *buffer = SvPV (ST(1), PL_na);
	PREINIT:
        long long offsets[0xFFFF];
        char nbuf[64];
	CODE:
        offsets[0] = -1;
        search_buffer (pattern, buffer, offsets);
        if (offsets[0] == -1) 
	    XSRETURN_UNDEF;
	else 
            sprintf (nbuf, "%ld", offsets[0]);
	    RETVAL = newSVpv (nbuf, strlen(nbuf));
        OUTPUT:
	    RETVAL

AV *
_search_string (pattern, buffer)
        char *pattern = SvPV (ST(0), PL_na);
        char *buffer = SvPV (ST(1), PL_na);
	PREINIT:
  	    int n;
            long long offsets[0xFFFF];
	    char nbuf[32];
	CODE:
	  RETVAL = newAV();
	  offsets[0] = -1;
          search_buffer (pattern, buffer, offsets);
          if (offsets[0] >= 0) {
              for (n = 0; offsets[n] >= 0; n++) {
              sprintf (nbuf, "%ld", offsets[n]);
	      av_push (RETVAL, newSVpv (nbuf, strlen(nbuf)));
              }
	  }
	OUTPUT:
	  RETVAL
        CLEANUP:
          SvREFCNT_dec (RETVAL);
          

AV *
_search_file (pattern, fn)
     char *pattern = SvPV (ST(0), PL_na);
     char *fn = SvPV (ST(1), PL_na);
     PREINIT:
       int n, a, pattern_length, overlap;
       long long bufstart, offsets[0xFFFF];
       FILE *f;
       char buf[0xFFFF], nbuf[64];
       int r;
     CODE:
       RETVAL = newAV();
       pattern_length = strlen (pattern);
       overlap = 0;
       a = 0;
       bufstart = 0L;
       if ((f = fopen (fn, "r")) != NULL) {
	 while (!feof(f)) {
	   r = fread (&buf[overlap], sizeof (char), 0xFFFF - overlap, f);
           if (!r) break;
           offsets[0] = -1L;
	   search_buffer (pattern, buf, offsets);
           for (n = 0; offsets[n] >= 0L; n++, a++) {
	     sprintf (nbuf, "%ld", offsets[n] + bufstart - overlap);
	     av_push (RETVAL, newSVpv (nbuf, strlen (nbuf)));
           }
	   memmove (buf, &buf[r - overlap], overlap*sizeof(char));
	   bufstart += (long long)r;
	   offsets[0] = -1L;
	   overlap = pattern_length;
	 }
	 fclose (f);
       } else {
	 XSRETURN_UNDEF;
       }
     OUTPUT:
       RETVAL
     CLEANUP:
       SvREFCNT_dec (RETVAL);
