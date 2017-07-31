#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
    PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
    (PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#if PERL_VERSION_GE(5,25,9)
#define foldit(p,e,s,l) toFOLD_utf8_safe(p,e,s,l)
#else
// toFOLD_utf8 only became a valid synonym during 5.15, but to_utf8_fold
// works from 5.8 through 5.24.
#define foldit(p,e,s,l) to_utf8_fold(p,s,l)
#endif

MODULE = Unicode::CaseFold    PACKAGE = Unicode::CaseFold

PROTOTYPES: DISABLE

SV *
case_fold(str)
    SV *str
  CODE:
    STRLEN input_len, folded_len;
    U8 *in = SvPVutf8(str, input_len),
      *ptr,
      folded[UTF8_MAXBYTES + 1];

    RETVAL = newSV(input_len); /* We may need more, but we won't need less. */
    SvPOK_only(RETVAL);
    SvUTF8_on(RETVAL);

    for ( ptr = in ; ptr < in + input_len ; ptr += UTF8SKIP(ptr) ) {
      foldit(ptr, in + input_len, folded, &folded_len);
      sv_catpvn(RETVAL, folded, folded_len);
    }
  OUTPUT:
    RETVAL
