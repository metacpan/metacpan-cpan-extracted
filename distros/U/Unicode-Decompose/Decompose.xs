#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static HV* compat;
static HV* canon;

MODULE = Unicode::Decompose		PACKAGE = Unicode::Decompose		

BOOT:
compat = get_hv("Unicode::Decompose::compat", 0);
canon  = get_hv("Unicode::Decompose::canon", 0);

void
_decompose(input, method)
    SV* input
    char* method
    char* s = NO_INIT
    STRLEN len = NO_INIT
    char* outbuf = NO_INIT
    HV* decomp = NO_INIT
    char* d = NO_INIT

    CODE:
        s = SvPVutf8_force(input, len);
        New(123, outbuf, len * 3, char);
        d = outbuf;

        if (strEQ(method, "canon"))
            decomp = canon;
        else if (strEQ(method, "compat")) 
            decomp = compat;
        else
            Perl_croak(aTHX_ "Bad method: must be compat or canon");

        while (len) {
            STRLEN ulen = UTF8SKIP(s);
            SV** decomposition = hv_fetch(decomp, s, -ulen, 0);
            len -= ulen;
            if (decomposition) {
                STRLEN outlen;
                char *dec = SvPV(*decomposition, outlen);

                for (;outlen; outlen--)
                    *d++ = *dec++;
                s += ulen;
            } else {
                STRLEN copylen = ulen;
                for (;copylen; copylen--)
                    *d++ = *s++;
            }
        }
        *d = '\0';
        sv_setpvn(input, outbuf, d-outbuf);

