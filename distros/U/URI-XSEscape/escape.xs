#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* #include <strings.h> */
#include "buffer.h"
#include "uri.h"

MODULE = URI::XSEscape        PACKAGE = URI::XSEscape
PROTOTYPES: DISABLE

#################################################################

SV*
uri_escape(SV* string, ...)
  PREINIT:
    Buffer answer;
    STRLEN slen = 0;
    const char* sstr = 0;
    Buffer sbuf;
    SV* escape = 0;
    STRLEN elen = 0;
    const char* estr = 0;
    Buffer ebuf;
  CODE:
    buffer_init(&answer, 0);
    do {
        if (!string || !SvOK(string) || SvROK(string)) {
            croak("uri_escape's mandatory first argument must be a string or number");
            break;
        }
        if (items > 2) {
            croak("uri_escape called with too many arguments");
            break;
        }

        sstr = SvPVbyte(string, slen);
        buffer_wrap(&sbuf, sstr, slen);

        if (items == 1) {
            uri_encode(&sbuf, slen, &answer);
            break;
        }

        escape = ST(1);
        if (!escape || !SvOK(escape) || !SvPOK(escape)) {
            croak("uri_escape's optional second argument must be a string");
            break;
        }

        estr = SvPVbyte(escape, elen);
        buffer_wrap(&ebuf, estr, elen);

        uri_encode_matrix(&sbuf, slen, &ebuf, &answer);
    } while (0);
    RETVAL = newSVpv(answer.data, answer.pos);
    buffer_fini(&answer);
  OUTPUT: RETVAL

SV*
uri_unescape(SV* string)
  PREINIT:
    Buffer answer;
    STRLEN slen = 0;
    const char* sstr = 0;
    Buffer sbuf;
  CODE:
    buffer_init(&answer, 0);
    do {
        if (!string || !SvOK(string) || !SvPOK(string)) {
            croak("uri_unescape's mandatory first argument must be a string");
            break;
        }

        sstr = SvPV_const(string, slen);
        buffer_wrap(&sbuf, sstr, slen);

        uri_decode(&sbuf, slen, &answer);
    } while (0);
    RETVAL = newSVpv(answer.data, answer.pos);
    buffer_fini(&answer);
  OUTPUT: RETVAL
