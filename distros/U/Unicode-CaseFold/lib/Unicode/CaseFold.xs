#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

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
      to_utf8_fold(ptr, folded, &folded_len);
      sv_catpvn(RETVAL, folded, folded_len);
    }
  OUTPUT:
    RETVAL
