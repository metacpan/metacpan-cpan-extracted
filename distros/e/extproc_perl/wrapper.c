/* $Id: wrapper.c,v 1.8 2006/08/01 17:57:12 jeff Exp $ */

#ifdef __cplusplus
extern "C" {
#endif
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <time.h>
#include <oci.h>

/* Perl headers */
#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>

#include "extproc_perl.h"
#ifdef __cplusplus
}
#endif

extern EP_CONTEXT my_context;

int ep_call_func_i(OCIExtProcContext *ctx, OCIInd *ret_ind, char *sub, char *sig, ...)
{
    va_list ap;
    int i, argc, nret, iarg, *piarg;
    EP_CONTEXT *c;
    EP_CODE code;
    SV *sv;
    STRLEN len, *plen, *pmaxlen;
    EP_ARG args[128];
    char *carg, *fqsub;
    OCIInd ind, *pind;
    OCIDate *darg;
    float rarg, *prarg;
    int retval;

    dTHX;
    dSP;

    c = &my_context;
    _ep_init(c, ctx);
    EP_DEBUGF(c, "IN ep_call_func_i(%p, %p, '%s', '%s', ...)", ctx, ret_ind, sub, sig);

    /* count arguments in signature */
    argc = (strlen(sig) - 1) / 2;

    /* start perl interpreter if necessary */
    if (!c->perl) {
        c->perl = pl_startup(c);
        if (!c->perl) {
            *ret_ind = OCI_IND_NULL;
            return(0);
        }
        EP_DEBUG(c, "RETURN ep_call_func_i");
    }
     
    /* set up stack */
    SPAGAIN;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    /* parse arguments and push onto stack */
    va_start(ap, sig);
    for (i = 1; i < strlen(sig); i+=2) {
        char d = sig[i];
        char t = sig[i+1];
        EP_ARG *arg = &args[(i-1)/2];

        arg->type = t;
        arg->direction = d;

        EP_DEBUGF(c, "-- pushing arg %d, sig=%c%c", (i+1)/2, d, t);

        switch(t) {
            case 'i':
                switch(d) {
                    case 'I':
                        iarg = va_arg(ap, int);
                        arg->val = &iarg;
                        ind = va_arg(ap, int);
                        pind = NULL;
                        if (ind == OCI_IND_NULL) {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSViv(iarg));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv);
                        break;
                    case 'B':
                    case 'O':
                        piarg = va_arg(ap, int *);
                        arg->val = piarg;
                        pind = va_arg(ap, OCIInd *);
                        if (*pind == OCI_IND_NULL || t == 'O') {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSViv(*piarg));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv_isobject(sv) ? sv : newRV_noinc(sv));
                        break;
                }
                break;
            case 'r':
                switch(d) {
                    case 'I':
                        rarg = va_arg(ap, double);
                        arg->val = &rarg;
                        ind = va_arg(ap, int);
                        if (ind == OCI_IND_NULL) {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSVnv(rarg));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv);
                        break;
                    case 'B':
                    case 'O':
                        prarg = va_arg(ap, float *);
                        arg->val = prarg;
                        pind = va_arg(ap, OCIInd *);
                        if (*pind == OCI_IND_NULL || t == 'O') {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSVnv(*prarg));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv_isobject(sv) ? sv : newRV_noinc(sv));
                        break;
                }
                break;
            case 'c':
                switch(d) {
                    case 'I':
                        carg = va_arg(ap, char *);
                        arg->val = carg;
                        ind = va_arg(ap, int);
                        len = va_arg(ap, sb4);
                        if (ind == OCI_IND_NULL) {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSVpvn(carg, len));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv);
                        break;
                    case 'B':
                    case 'O':
                        carg = va_arg(ap, char *);
                        arg->val = carg;
                        pind = va_arg(ap, OCIInd *);
                        plen = va_arg(ap, STRLEN *);
                        pmaxlen = va_arg(ap, STRLEN *);
                        if (*pind == OCI_IND_NULL || t == 'O') {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSVpvn(carg, *plen));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv_isobject(sv) ? sv : newRV_noinc(sv));
                        break;
                }
                break;
            case 'd':
                switch(d) {
                    case 'I':
                        darg = va_arg(ap, OCIDate *);
                        arg->val = darg;
                        ind = va_arg(ap, int);
                        sv = sv_newmortal();
                        sv_setref_pv(sv, "ExtProc::DataType::OCIDate", darg);
                        if (ind == OCI_IND_NULL) {
                            set_null(darg);
                        }
                        else {
                            clear_null(darg);
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv);
                        break;
                    case 'B':
                    case 'O':
                        darg = va_arg(ap, OCIDate *);
                        arg->val = darg;
                        pind = va_arg(ap, OCIInd *);
                        sv = sv_newmortal();
                        sv_setref_pv(sv, "ExtProc::DataType::OCIDate", darg);
                        if (*pind == OCI_IND_NULL) {
                            set_null(darg);
                        }
                        else {
                            clear_null(darg);
                        }
                        XPUSHs(sv);
                        break;
                }
                break;
            default: break; /* should NEVER get here */
        }
        arg->sv = sv;
        arg->ind = pind;
        arg->len = plen;
        arg->maxlen = pmaxlen;
    }
    va_end(ap);

    PUTBACK;

    /* parse perl code */
    fqsub = parse_code(c, &code, sub);
    EP_DEBUG(c, "RETURN ep_call_func_i");
    if (!fqsub) {
        *ret_ind = OCI_IND_NULL;
        return(0);
    }

    /* run perl subroutine */
    EP_DEBUG(c, "-- about to call call_pv()");
    nret = call_pv(fqsub, G_SCALAR|G_EVAL);
    EP_DEBUGF(c, "-- call_pv() returned %d", nret);
    if (SvTRUE(ERRSV)) {
        EP_DEBUGF(c, "-- ERRSV is defined: %s", SvPV(ERRSV, PL_na));
        ora_exception(c, SvPV(ERRSV, PL_na));
        return(0);
    }

    SPAGAIN;

    /* copy values back to INOUT & OUT args */
    for (i = 0; i < argc; i++) {
        char *tmp;
        EP_ARG *arg = &args[i];
        if (arg->direction == 'I') continue;

        EP_DEBUGF(c, "-- copying value to arg %d with signature %c%c", i+1, arg->direction, arg->type);

        switch(arg->type) {
            case 'c':
                if (!SvOK(arg->sv)) {
                    *(arg->ind) = OCI_IND_NULL;
                }
                else {
                    *(arg->ind) = OCI_IND_NOTNULL;
                    tmp = SvPV(arg->sv, len);
                    if (len > *(arg->maxlen)) {
                        ora_exception(c, "length of argument exceeds maximum length for parameter");
                        return(0);
                    }
                }
                Copy(tmp, arg->val, len, char);
                *(arg->len) = len;
                break;

            case 'i':
                *((int *)(arg->val)) = SvIV(arg->sv);
                *(arg->ind) = SvOK(arg->sv) ? OCI_IND_NOTNULL : OCI_IND_NULL;
                break;

            case 'r':
                *((float *)(arg->val)) = SvNV(arg->sv);
                *(arg->ind) = SvOK(arg->sv) ? OCI_IND_NOTNULL : OCI_IND_NULL;
                break;
            case 'd':
                *(arg->ind) = SvOK(arg->sv) ? OCI_IND_NOTNULL : OCI_IND_NULL;
                break;
        }
    }

    /* pop return value off the stack */
    sv = POPs;
    retval = SvIV(sv);
    *ret_ind = SvTRUE(sv) ? OCI_IND_NOTNULL : OCI_IND_NULL;

    /* clean up stack and return */
    PUTBACK;
    FREETMPS;
    LEAVE;
    return(retval);
}

float ep_call_func_r(OCIExtProcContext *ctx, OCIInd *ret_ind, char *sub, char *sig, ...)
{
    va_list ap;
    int i, argc, nret, iarg, *piarg;
    EP_CONTEXT *c;
    EP_CODE code;
    SV *sv;
    STRLEN len, *plen, *pmaxlen;
    EP_ARG args[128];
    char *carg, *fqsub;
    OCIInd ind, *pind;
    OCIDate *darg;
    float rarg, *prarg;
    float retval;

    dTHX;
    dSP;

    c = &my_context;
    _ep_init(c, ctx);
    EP_DEBUGF(c, "IN ep_call_func_r(%p, %p, '%s', '%s', ...)", ctx, ret_ind, sub, sig);

    /* count arguments in signature */
    argc = (strlen(sig) - 1) / 2;

    /* start perl interpreter if necessary */
    if (!c->perl) {
        c->perl = pl_startup(c);
        if (!c->perl) {
            *ret_ind = OCI_IND_NULL;
            return(0);
        }
        EP_DEBUG(c, "RETURN ep_call_func_r");
    }
     
    /* set up stack */
    SPAGAIN;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    /* parse arguments and push onto stack */
    va_start(ap, sig);
    for (i = 1; i < strlen(sig); i+=2) {
        char d = sig[i];
        char t = sig[i+1];
        EP_ARG *arg = &args[(i-1)/2];

        arg->type = t;
        arg->direction = d;

        EP_DEBUGF(c, "-- pushing arg %d, sig=%c%c", (i+1)/2, d, t);

        switch(t) {
            case 'i':
                switch(d) {
                    case 'I':
                        iarg = va_arg(ap, int);
                        arg->val = &iarg;
                        ind = va_arg(ap, int);
                        pind = NULL;
                        if (ind == OCI_IND_NULL) {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSViv(iarg));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv);
                        break;
                    case 'B':
                    case 'O':
                        piarg = va_arg(ap, int *);
                        arg->val = piarg;
                        pind = va_arg(ap, OCIInd *);
                        if (*pind == OCI_IND_NULL || t == 'O') {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSViv(*piarg));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv_isobject(sv) ? sv : newRV_noinc(sv));
                        break;
                }
                break;
            case 'r':
                switch(d) {
                    case 'I':
                        rarg = va_arg(ap, double);
                        arg->val = &rarg;
                        ind = va_arg(ap, int);
                        if (ind == OCI_IND_NULL) {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSVnv(rarg));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv);
                        break;
                    case 'B':
                    case 'O':
                        prarg = va_arg(ap, float *);
                        arg->val = prarg;
                        pind = va_arg(ap, OCIInd *);
                        if (*pind == OCI_IND_NULL || t == 'O') {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSVnv(*prarg));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv_isobject(sv) ? sv : newRV_noinc(sv));
                        break;
                }
                break;
            case 'c':
                switch(d) {
                    case 'I':
                        carg = va_arg(ap, char *);
                        arg->val = carg;
                        ind = va_arg(ap, int);
                        len = va_arg(ap, sb4);
                        if (ind == OCI_IND_NULL) {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSVpvn(carg, len));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv);
                        break;
                    case 'B':
                    case 'O':
                        carg = va_arg(ap, char *);
                        arg->val = carg;
                        pind = va_arg(ap, OCIInd *);
                        plen = va_arg(ap, STRLEN *);
                        pmaxlen = va_arg(ap, STRLEN *);
                        if (*pind == OCI_IND_NULL || t == 'O') {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSVpvn(carg, *plen));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv_isobject(sv) ? sv : newRV_noinc(sv));
                        break;
                }
                break;
            case 'd':
                switch(d) {
                    case 'I':
                        darg = va_arg(ap, OCIDate *);
                        arg->val = darg;
                        ind = va_arg(ap, int);
                        sv = sv_newmortal();
                        sv_setref_pv(sv, "ExtProc::DataType::OCIDate", darg);
                        if (ind == OCI_IND_NULL) {
                            set_null(darg);
                        }
                        else {
                            clear_null(darg);
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv);
                        break;
                    case 'B':
                    case 'O':
                        darg = va_arg(ap, OCIDate *);
                        arg->val = darg;
                        pind = va_arg(ap, OCIInd *);
                        sv = sv_newmortal();
                        sv_setref_pv(sv, "ExtProc::DataType::OCIDate", darg);
                        if (*pind == OCI_IND_NULL) {
                            set_null(darg);
                        }
                        else {
                            clear_null(darg);
                        }
                        XPUSHs(sv);
                        break;
                }
                break;
            default: break; /* should NEVER get here */
        }
        arg->sv = sv;
        arg->ind = pind;
        arg->len = plen;
        arg->maxlen = pmaxlen;
    }
    va_end(ap);

    PUTBACK;

    /* parse perl code */
    fqsub = parse_code(c, &code, sub);
    EP_DEBUG(c, "RETURN ep_call_func_r");
    if (!fqsub) {
        *ret_ind = OCI_IND_NULL;
        return(0);
    }

    /* run perl subroutine */
    EP_DEBUG(c, "-- about to call call_pv()");
    nret = call_pv(fqsub, G_SCALAR|G_EVAL);
    EP_DEBUGF(c, "-- call_pv() returned %d", nret);
    if (SvTRUE(ERRSV)) {
        EP_DEBUGF(c, "-- ERRSV is defined: %s", SvPV(ERRSV, PL_na));
        ora_exception(c, SvPV(ERRSV, PL_na));
        return(0);
    }

    SPAGAIN;

    /* copy values back to INOUT & OUT args */
    for (i = 0; i < argc; i++) {
        char *tmp;
        EP_ARG *arg = &args[i];
        if (arg->direction == 'I') continue;

        EP_DEBUGF(c, "-- copying value to arg %d with signature %c%c", i+1, arg->direction, arg->type);

        switch(arg->type) {
            case 'c':
                if (!SvOK(arg->sv)) {
                    *(arg->ind) = OCI_IND_NULL;
                }
                else {
                    *(arg->ind) = OCI_IND_NOTNULL;
                    tmp = SvPV(arg->sv, len);
                    if (len > *(arg->maxlen)) {
                        ora_exception(c, "length of argument exceeds maximum length for parameter");
                        return(0);
                    }
                }
                Copy(tmp, arg->val, len, char);
                *(arg->len) = len;
                break;

            case 'i':
                *((int *)(arg->val)) = SvIV(arg->sv);
                *(arg->ind) = SvOK(arg->sv) ? OCI_IND_NOTNULL : OCI_IND_NULL;
                break;

            case 'r':
                *((float *)(arg->val)) = SvNV(arg->sv);
                *(arg->ind) = SvOK(arg->sv) ? OCI_IND_NOTNULL : OCI_IND_NULL;
                break;
            case 'd':
                *(arg->ind) = SvOK(arg->sv) ? OCI_IND_NOTNULL : OCI_IND_NULL;
                break;
        }
    }

    /* pop return value off the stack */
    sv = POPs;
    retval = SvNV(sv);
    *ret_ind = SvTRUE(sv) ? OCI_IND_NOTNULL : OCI_IND_NULL;

    /* clean up stack and return */
    PUTBACK;
    FREETMPS;
    LEAVE;
    return(retval);
}

char *ep_call_func_c(OCIExtProcContext *ctx, OCIInd *ret_ind, char *sub, char *sig, ...)
{
    va_list ap;
    int i, argc, nret, iarg, *piarg;
    EP_CONTEXT *c;
    EP_CODE code;
    SV *sv;
    STRLEN len, *plen, *pmaxlen;
    EP_ARG args[128];
    char *carg, *fqsub, *tmp;
    OCIInd ind, *pind;
    OCIDate *darg;
    float rarg, *prarg;
    char *retval;

    dTHX;
    dSP;

    c = &my_context;
    _ep_init(c, ctx);
    EP_DEBUGF(c, "IN ep_call_func_c(%p, %p, '%s', '%s', ...)", ctx, ret_ind, sub, sig);

    /* count arguments in signature */
    argc = (strlen(sig) - 1) / 2;

    /* start perl interpreter if necessary */
    if (!c->perl) {
        c->perl = pl_startup(c);
        if (!c->perl) {
            *ret_ind = OCI_IND_NULL;
            return(0);
        }
        EP_DEBUG(c, "RETURN ep_call_func_c");
    }
     
    /* set up stack */
    SPAGAIN;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    /* parse arguments and push onto stack */
    va_start(ap, sig);
    for (i = 1; i < strlen(sig); i+=2) {
        char d = sig[i];
        char t = sig[i+1];
        EP_ARG *arg = &args[(i-1)/2];

        arg->type = t;
        arg->direction = d;

        EP_DEBUGF(c, "-- pushing arg %d, sig=%c%c", (i+1)/2, d, t);

        switch(t) {
            case 'i':
                switch(d) {
                    case 'I':
                        iarg = va_arg(ap, int);
                        arg->val = &iarg;
                        ind = va_arg(ap, int);
                        pind = NULL;
                        if (ind == OCI_IND_NULL) {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSViv(iarg));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv);
                        break;
                    case 'B':
                    case 'O':
                        piarg = va_arg(ap, int *);
                        arg->val = piarg;
                        pind = va_arg(ap, OCIInd *);
                        if (*pind == OCI_IND_NULL || t == 'O') {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSViv(*piarg));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv_isobject(sv) ? sv : newRV_noinc(sv));
                        break;
                }
                break;
            case 'r':
                switch(d) {
                    case 'I':
                        rarg = va_arg(ap, double);
                        arg->val = &rarg;
                        ind = va_arg(ap, int);
                        if (ind == OCI_IND_NULL) {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSVnv(rarg));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv);
                        break;
                    case 'B':
                    case 'O':
                        prarg = va_arg(ap, float *);
                        arg->val = prarg;
                        pind = va_arg(ap, OCIInd *);
                        if (*pind == OCI_IND_NULL || t == 'O') {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSVnv(*prarg));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv_isobject(sv) ? sv : newRV_noinc(sv));
                        break;
                }
                break;
            case 'c':
                switch(d) {
                    case 'I':
                        carg = va_arg(ap, char *);
                        arg->val = carg;
                        ind = va_arg(ap, int);
                        len = va_arg(ap, sb4);
                        if (ind == OCI_IND_NULL) {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSVpvn(carg, len));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv);
                        break;
                    case 'B':
                    case 'O':
                        carg = va_arg(ap, char *);
                        arg->val = carg;
                        pind = va_arg(ap, OCIInd *);
                        plen = va_arg(ap, STRLEN *);
                        pmaxlen = va_arg(ap, STRLEN *);
                        if (*pind == OCI_IND_NULL || t == 'O') {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSVpvn(carg, *plen));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv_isobject(sv) ? sv : newRV_noinc(sv));
                        break;
                }
                break;
            case 'd':
                switch(d) {
                    case 'I':
                        darg = va_arg(ap, OCIDate *);
                        arg->val = darg;
                        ind = va_arg(ap, int);
                        sv = sv_newmortal();
                        sv_setref_pv(sv, "ExtProc::DataType::OCIDate", darg);
                        if (ind == OCI_IND_NULL) {
                            set_null(darg);
                        }
                        else {
                            clear_null(darg);
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv);
                        break;
                    case 'B':
                    case 'O':
                        darg = va_arg(ap, OCIDate *);
                        arg->val = darg;
                        pind = va_arg(ap, OCIInd *);
                        sv = sv_newmortal();
                        sv_setref_pv(sv, "ExtProc::DataType::OCIDate", darg);
                        if (*pind == OCI_IND_NULL) {
                            set_null(darg);
                        }
                        else {
                            clear_null(darg);
                        }
                        XPUSHs(sv);
                        break;
                }
                break;
            default: break; /* should NEVER get here */
        }
        arg->sv = sv;
        arg->ind = pind;
        arg->len = plen;
        arg->maxlen = pmaxlen;
    }
    va_end(ap);

    PUTBACK;

    /* parse perl code */
    fqsub = parse_code(c, &code, sub);
    EP_DEBUG(c, "RETURN ep_call_func_c");
    if (!fqsub) {
        *ret_ind = OCI_IND_NULL;
        return(0);
    }

    /* run perl subroutine */
    EP_DEBUG(c, "-- about to call call_pv()");
    nret = call_pv(fqsub, G_SCALAR|G_EVAL);
    EP_DEBUGF(c, "-- call_pv() returned %d", nret);
    if (SvTRUE(ERRSV)) {
        EP_DEBUGF(c, "-- ERRSV is defined: %s", SvPV(ERRSV, PL_na));
        ora_exception(c, SvPV(ERRSV, PL_na));
        return(0);
    }

    SPAGAIN;

    /* copy values back to INOUT & OUT args */
    for (i = 0; i < argc; i++) {
        EP_ARG *arg = &args[i];
        if (arg->direction == 'I') continue;

        EP_DEBUGF(c, "-- copying value to arg %d with signature %c%c", i+1, arg->direction, arg->type);

        switch(arg->type) {
            case 'c':
                if (!SvOK(arg->sv)) {
                    *(arg->ind) = OCI_IND_NULL;
                }
                else {
                    *(arg->ind) = OCI_IND_NOTNULL;
                    tmp = SvPV(arg->sv, len);
                    if (len > *(arg->maxlen)) {
                        ora_exception(c, "length of argument exceeds maximum length for parameter");
                        return(0);
                    }
                }
                Copy(tmp, arg->val, len, char);
                *(arg->len) = len;
                break;

            case 'i':
                *((int *)(arg->val)) = SvIV(arg->sv);
                *(arg->ind) = SvOK(arg->sv) ? OCI_IND_NOTNULL : OCI_IND_NULL;
                break;

            case 'r':
                *((float *)(arg->val)) = SvNV(arg->sv);
                *(arg->ind) = SvOK(arg->sv) ? OCI_IND_NOTNULL : OCI_IND_NULL;
                break;
            case 'd':
                *(arg->ind) = SvOK(arg->sv) ? OCI_IND_NOTNULL : OCI_IND_NULL;
                break;
        }
    }

    /* pop return value off the stack */
    sv = POPs;
    if (SvOK(sv)) {
        tmp = SvPV(sv, len);
        New(0, retval, len+1, char);
        Copy(tmp, retval, len, char);
        retval[len] = '\0';
        *ret_ind = OCI_IND_NOTNULL;
    }
    else {
        *ret_ind = OCI_IND_NULL;
    }

    /* clean up stack and return */
    PUTBACK;
    FREETMPS;
    LEAVE;
    return(retval);
}

OCIDate *ep_call_func_d(OCIExtProcContext *ctx, OCIInd *ret_ind, char *sub, char *sig, ...)
{
    va_list ap;
    int i, argc, nret, iarg, *piarg;
    EP_CONTEXT *c;
    EP_CODE code;
    SV *sv;
    STRLEN len, *plen, *pmaxlen;
    EP_ARG args[128];
    char *carg, *fqsub, *tmp;
    OCIInd ind, *pind;
    OCIDate *darg;
    float rarg, *prarg;
    OCIDate *retval;

    dTHX;
    dSP;

    c = &my_context;
    _ep_init(c, ctx);
    EP_DEBUGF(c, "IN ep_call_func_d(%p, %p, '%s', '%s', ...)", ctx, ret_ind, sub, sig);

    /* count arguments in signature */
    argc = (strlen(sig) - 1) / 2;

    /* start perl interpreter if necessary */
    if (!c->perl) {
        c->perl = pl_startup(c);
        if (!c->perl) {
            *ret_ind = OCI_IND_NULL;
            return(0);
        }
        EP_DEBUG(c, "RETURN ep_call_func_d");
    }
     
    /* set up stack */
    SPAGAIN;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    /* parse arguments and push onto stack */
    va_start(ap, sig);
    for (i = 1; i < strlen(sig); i+=2) {
        char d = sig[i];
        char t = sig[i+1];
        EP_ARG *arg = &args[(i-1)/2];

        arg->type = t;
        arg->direction = d;

        EP_DEBUGF(c, "-- pushing arg %d, sig=%c%c", (i+1)/2, d, t);

        switch(t) {
            case 'i':
                switch(d) {
                    case 'I':
                        iarg = va_arg(ap, int);
                        arg->val = &iarg;
                        ind = va_arg(ap, int);
                        pind = NULL;
                        if (ind == OCI_IND_NULL) {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSViv(iarg));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv);
                        break;
                    case 'B':
                    case 'O':
                        piarg = va_arg(ap, int *);
                        arg->val = piarg;
                        pind = va_arg(ap, OCIInd *);
                        if (*pind == OCI_IND_NULL || t == 'O') {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSViv(*piarg));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv_isobject(sv) ? sv : newRV_noinc(sv));
                        break;
                }
                break;
            case 'r':
                switch(d) {
                    case 'I':
                        rarg = va_arg(ap, double);
                        arg->val = &rarg;
                        ind = va_arg(ap, int);
                        if (ind == OCI_IND_NULL) {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSVnv(rarg));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv);
                        break;
                    case 'B':
                    case 'O':
                        prarg = va_arg(ap, float *);
                        arg->val = prarg;
                        pind = va_arg(ap, OCIInd *);
                        if (*pind == OCI_IND_NULL || t == 'O') {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSVnv(*prarg));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv_isobject(sv) ? sv : newRV_noinc(sv));
                        break;
                }
                break;
            case 'c':
                switch(d) {
                    case 'I':
                        carg = va_arg(ap, char *);
                        arg->val = carg;
                        ind = va_arg(ap, int);
                        len = va_arg(ap, sb4);
                        if (ind == OCI_IND_NULL) {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSVpvn(carg, len));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv);
                        break;
                    case 'B':
                    case 'O':
                        carg = va_arg(ap, char *);
                        arg->val = carg;
                        pind = va_arg(ap, OCIInd *);
                        plen = va_arg(ap, STRLEN *);
                        pmaxlen = va_arg(ap, STRLEN *);
                        if (*pind == OCI_IND_NULL || t == 'O') {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSVpvn(carg, *plen));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv_isobject(sv) ? sv : newRV_noinc(sv));
                        break;
                }
                break;
            case 'd':
                switch(d) {
                    case 'I':
                        darg = va_arg(ap, OCIDate *);
                        arg->val = darg;
                        ind = va_arg(ap, int);
                        sv = sv_newmortal();
                        sv_setref_pv(sv, "ExtProc::DataType::OCIDate", darg);
                        if (ind == OCI_IND_NULL) {
                            set_null(darg);
                        }
                        else {
                            clear_null(darg);
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv);
                        break;
                    case 'B':
                    case 'O':
                        darg = va_arg(ap, OCIDate *);
                        arg->val = darg;
                        pind = va_arg(ap, OCIInd *);
                        sv = sv_newmortal();
                        sv_setref_pv(sv, "ExtProc::DataType::OCIDate", darg);
                        if (*pind == OCI_IND_NULL) {
                            set_null(darg);
                        }
                        else {
                            clear_null(darg);
                        }
                        XPUSHs(sv);
                        break;
                }
                break;
            default: break; /* should NEVER get here */
        }
        arg->sv = sv;
        arg->ind = pind;
        arg->len = plen;
        arg->maxlen = pmaxlen;
    }
    va_end(ap);

    PUTBACK;

    /* parse perl code */
    fqsub = parse_code(c, &code, sub);
    EP_DEBUG(c, "RETURN ep_call_func_d");
    if (!fqsub) {
        *ret_ind = OCI_IND_NULL;
        return(0);
    }

    /* run perl subroutine */
    EP_DEBUG(c, "-- about to call call_pv()");
    nret = call_pv(fqsub, G_SCALAR|G_EVAL);
    EP_DEBUGF(c, "-- call_pv() returned %d", nret);
    if (SvTRUE(ERRSV)) {
        EP_DEBUGF(c, "-- ERRSV is defined: %s", SvPV(ERRSV, PL_na));
        ora_exception(c, SvPV(ERRSV, PL_na));
        return(0);
    }

    SPAGAIN;

    /* copy values back to INOUT & OUT args */
    for (i = 0; i < argc; i++) {
        EP_ARG *arg = &args[i];
        if (arg->direction == 'I') continue;

        EP_DEBUGF(c, "-- copying value to arg %d with signature %c%c", i+1, arg->direction, arg->type);

        switch(arg->type) {
            case 'c':
                if (!SvOK(arg->sv)) {
                    *(arg->ind) = OCI_IND_NULL;
                }
                else {
                    *(arg->ind) = OCI_IND_NOTNULL;
                    tmp = SvPV(arg->sv, len);
                    if (len > *(arg->maxlen)) {
                        ora_exception(c, "length of argument exceeds maximum length for parameter");
                        return(0);
                    }
                }
                Copy(tmp, arg->val, len, char);
                *(arg->len) = len;
                break;

            case 'i':
                *((int *)(arg->val)) = SvIV(arg->sv);
                *(arg->ind) = SvOK(arg->sv) ? OCI_IND_NOTNULL : OCI_IND_NULL;
                break;

            case 'r':
                *((float *)(arg->val)) = SvNV(arg->sv);
                *(arg->ind) = SvOK(arg->sv) ? OCI_IND_NOTNULL : OCI_IND_NULL;
                break;
            case 'd':
                *(arg->ind) = SvOK(arg->sv) ? OCI_IND_NOTNULL : OCI_IND_NULL;
                break;
        }
    }

    /* pop return value off the stack */
    sv = POPs;
    if (SvOK(sv)) {
        retval = (OCIDate *)SvIV(SvRV(sv));
        *ret_ind = is_null(sv) ? OCI_IND_NULL : OCI_IND_NOTNULL;
    }
    else {
        *ret_ind = OCI_IND_NULL;
    }

    /* clean up stack and return */
    PUTBACK;
    FREETMPS;
    LEAVE;
    return(retval);
}

int ep_call_proc(OCIExtProcContext *ctx, char *sub, char *sig, ...)
{
    va_list ap;
    int i, argc, nret, iarg, *piarg;
    EP_CONTEXT *c;
    EP_CODE code;
    SV *sv;
    STRLEN len, *plen, *pmaxlen;
    EP_ARG args[128];
    char *carg, *fqsub;
    OCIInd ind, *pind;
    OCIDate *darg;
    float rarg, *prarg;

    dTHX;
    dSP;

    c = &my_context;
    _ep_init(c, ctx);
    EP_DEBUGF(c, "IN ep_call_proc(%p, '%s', '%s', ...)", ctx, sub, sig);

    /* count arguments in signature */
    argc = (strlen(sig) - 1) / 2;

    /* start perl interpreter if necessary */
    if (!c->perl) {
        c->perl = pl_startup(c);
        if (!c->perl) {
            return;
        }
        EP_DEBUG(c, "RETURN ep_call_proc");
    }
     
    /* set up stack */
    SPAGAIN;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    /* parse arguments and push onto stack */
    va_start(ap, sig);
    for (i = 1; i < strlen(sig); i+=2) {
        OCIInd ind, *pind;
        STRLEN *plen;
        int iarg, *piarg;
        char *carg;
        OCIDate *darg;
        float rarg, *prarg;
        char d = sig[i];
        char t = sig[i+1];
        EP_ARG *arg = &args[(i-1)/2];

        arg->type = t;
        arg->direction = d;

        EP_DEBUGF(c, "-- pushing arg %d, sig=%c%c", (i+1)/2, d, t);

        switch(t) {
            case 'i':
                switch(d) {
                    case 'I':
                        iarg = va_arg(ap, int);
                        arg->val = &iarg;
                        ind = va_arg(ap, int);
                        pind = NULL;
                        if (ind == OCI_IND_NULL) {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSViv(iarg));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv);
                        break;
                    case 'B':
                    case 'O':
                        piarg = va_arg(ap, int *);
                        arg->val = piarg;
                        pind = va_arg(ap, OCIInd *);
                        if (*pind == OCI_IND_NULL || t == 'O') {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSViv(*piarg));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv_isobject(sv) ? sv : newRV_noinc(sv));
                        break;
                }
                break;
            case 'r':
                switch(d) {
                    case 'I':
                        rarg = va_arg(ap, double);
                        arg->val = &rarg;
                        ind = va_arg(ap, int);
                        if (ind == OCI_IND_NULL) {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSVnv(rarg));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv);
                        break;
                    case 'B':
                    case 'O':
                        prarg = va_arg(ap, float *);
                        arg->val = prarg;
                        pind = va_arg(ap, OCIInd *);
                        if (*pind == OCI_IND_NULL || t == 'O') {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSVnv(*prarg));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv_isobject(sv) ? sv : newRV_noinc(sv));
                        break;
                }
                break;
            case 'c':
                switch(d) {
                    case 'I':
                        carg = va_arg(ap, char *);
                        arg->val = carg;
                        ind = va_arg(ap, int);
                        len = va_arg(ap, sb4);
                        if (ind == OCI_IND_NULL) {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSVpvn(carg, len));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv);
                        break;
                    case 'B':
                    case 'O':
                        carg = va_arg(ap, char *);
                        arg->val = carg;
                        pind = va_arg(ap, OCIInd *);
                        plen = va_arg(ap, STRLEN *);
                        pmaxlen = va_arg(ap, STRLEN *);
                        if (*pind == OCI_IND_NULL || t == 'O') {
                            sv = sv_2mortal(newSVsv(&PL_sv_undef));
                        }
                        else {
                            sv = sv_2mortal(newSVpvn(carg, *plen));
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv_isobject(sv) ? sv : newRV_noinc(sv));
                        break;
                }
                break;
            case 'd':
                switch(d) {
                    case 'I':
                        darg = va_arg(ap, OCIDate *);
                        arg->val = darg;
                        ind = va_arg(ap, int);
                        sv = sv_newmortal();
                        sv_setref_pv(sv, "ExtProc::DataType::OCIDate", darg);
                        if (ind == OCI_IND_NULL) {
                            set_null(darg);
                        }
                        else {
                            clear_null(darg);
                        }
                        if (c->tainting) {
                            SvTAINTED_on(sv);
                        }
                        XPUSHs(sv);
                        break;
                    case 'B':
                    case 'O':
                        darg = va_arg(ap, OCIDate *);
                        arg->val = darg;
                        pind = va_arg(ap, OCIInd *);
                        sv = sv_newmortal();
                        sv_setref_pv(sv, "ExtProc::DataType::OCIDate", darg);
                        if (*pind == OCI_IND_NULL) {
                            set_null(darg);
                        }
                        else {
                            clear_null(darg);
                        }
                        XPUSHs(sv);
                        break;
                }
                break;
            default: break; /* should NEVER get here */
        }

        /* save argument attributes for IN OUT & OUT parameters */
        if (d == 'B' || d == 'O') {
            arg->sv = sv;
            arg->ind = pind;
            arg->len = plen;
            arg->maxlen = pmaxlen;
        }
    }
    va_end(ap);

    PUTBACK;

    /* parse perl code */
    fqsub = parse_code(c, &code, sub);
    EP_DEBUG(c, "RETURN ep_call_proc");
    if (!fqsub) {
        return;
    }

    /* run perl subroutine */
    EP_DEBUG(c, "-- about to call call_pv()");
    nret = call_pv(fqsub, G_SCALAR|G_EVAL);
    EP_DEBUGF(c, "-- call_pv() returned %d", nret);
    if (SvTRUE(ERRSV)) {
        EP_DEBUGF(c, "-- ERRSV is defined: %s", SvPV(ERRSV, PL_na));
        ora_exception(c, SvPV(ERRSV, PL_na));
        return;
    }

    SPAGAIN;

    /* copy values back to INOUT & OUT args */
    for (i = 0; i < argc; i++) {
        char *tmp;
        EP_ARG *arg = &args[i];
        if (arg->direction == 'I') continue;

        EP_DEBUGF(c, "-- copying value to arg %d with signature %c%c", i+1, arg->direction, arg->type);

        switch(arg->type) {
            case 'c':
                if (!SvOK(arg->sv)) {
                    *(arg->ind) = OCI_IND_NULL;
                }
                else {
                    *(arg->ind) = OCI_IND_NOTNULL;
                    tmp = SvPV(arg->sv, len);
                    if (len > *(arg->maxlen)) {
                        ora_exception(c, "length of argument exceeds maximum length for parameter");
                        return;
                    }
                }
                Copy(tmp, arg->val, len, char);
                *(arg->len) = len;
                break;

            case 'i':
                *((int *)(arg->val)) = SvIV(arg->sv);
                *(arg->ind) = SvOK(arg->sv) ? OCI_IND_NOTNULL : OCI_IND_NULL;
                break;

            case 'r':
                *((float *)(arg->val)) = SvNV(arg->sv);
                *(arg->ind) = SvOK(arg->sv) ? OCI_IND_NOTNULL : OCI_IND_NULL;
                break;
            case 'd':
                *(arg->ind) = SvOK(arg->sv) ? OCI_IND_NOTNULL : OCI_IND_NULL;
                break;
        }
    }

    /* clean up stack and return */
    PUTBACK;
    FREETMPS;
    LEAVE;
}
