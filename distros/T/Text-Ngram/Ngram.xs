/* -*- C -*- */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

void _process_buffer(pTHX_ SV* sv, unsigned int window, HV** counts_hv) {
    HV*    counts;
    STRLEN len;
    char*  buffer = SvPV(sv, len);

    if (!counts_hv || !*counts_hv)
        *counts_hv = (HV*)sv_2mortal((SV*)newHV());
    counts = *counts_hv;

    if (DO_UTF8(sv)) {
        char* next, * cur;
        unsigned int c;
        len = sv_len_utf8(sv);
        unsigned int windows = (len < window) ? 0 : len - window + 1;

        while (windows--) {
            cur = next = buffer + UTF8SKIP(buffer);
            for (c = window - 1;  c--; cur += UTF8SKIP(cur)) ;
            sv_inc(*hv_fetch(counts, buffer, -(cur - buffer), TRUE));
            buffer = next;
        }
    }
    else {
        unsigned int windows = (len < window) ? 0 : len - window + 1;
        while (windows--) {
            sv_inc(*hv_fetch(counts, buffer++, window, TRUE));
        }
    }
}

MODULE = Text::Ngram            PACKAGE = Text::Ngram

PROTOTYPES: DISABLE

HV*
_process_buffer(buffer, window)
    SV*          buffer
    unsigned int window
    CODE:
    {
        HV* newhv = NULL;
        _process_buffer(aTHX_ buffer, window, &newhv);
        RETVAL=newhv;
    }
    OUTPUT:
        RETVAL

void
_process_buffer_incrementally(buffer, window, hash)
    SV*          buffer
    unsigned int window
    HV* hash
    CODE:
        _process_buffer(aTHX_ buffer, window, &hash);
