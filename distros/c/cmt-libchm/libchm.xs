#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "chm_lib.h"
#include "const-c.inc"
/* #include <xsutil.h> */

/*
typedef unsigned int        chm_ulong_t; 
typedef int                 chm_long; 
*/

#define hv_set(hv, k, v)    hv_store(hv, k, strlen(k), v, 0)

typedef struct chmFile *    PCHMFILE; 
typedef struct chmUnitInfo *PCHMUNITINFO; 

static SV *mortal_pv(void *ptr) {
    SV *mortal = sv_2mortal(newSViv(0)); 
    sv_setref_pv(mortal, Nullch, ptr); 
    return mortal; 
}

static int
_chm_enumerator(PCHMFILE h, PCHMUNITINFO ui, SV **recall) {
    SV *cb; 
    SV *context; 
    int ret;
    dSP;
    cb = recall[0];
    context = recall[1];
    PUSHMARK(SP);
        XPUSHs(mortal_pv(h));
        XPUSHs(mortal_pv(ui));
        XPUSHs(context);
    PUTBACK;
        if (call_sv(cb, G_SCALAR) != 1)
            croak("the enumerator should return a scalar value"); 
    SPAGAIN;
        ret = POPi;
    PUTBACK;
    return ret;
}

MODULE = cmt::libchm		PACKAGE = cmt::libchm		

INCLUDE: const-xs.inc

PCHMFILE
chm_open(filename)
        const char *filename
    PROTOTYPE: $
    CODE: 
        RETVAL = chm_open(filename); 
    OUTPUT: 
        RETVAL

void
chm_close(h)
        PCHMFILE h
    PROTOTYPE: $
    CODE: 
        chm_close(h); 

void
chm_set_param(h, paramType, paramVal)
        PCHMFILE h
        int paramType
        int paramVal
    PROTOTYPE: $$$
    CODE: 
        chm_set_param(h, paramType, paramVal); 

int
chm_resolve_object(h, objPath, ui)
        PCHMFILE h
        const char *objPath
        PCHMUNITINFO ui
    PROTOTYPE: $$$
    CODE: 
        RETVAL = chm_resolve_object(h, objPath, ui); 
    OUTPUT: 
        RETVAL

SV  *
chm_retrieve_object(h, ui, addr, len)
        PCHMFILE h
        PCHMUNITINFO ui
        unsigned long addr
        long len
    PROTOTYPE: $$;$$
    INIT: 
        unsigned char *_buf; 
        int cb;
    CODE: 
        _buf = (unsigned char *)malloc((size_t) len); 
        /* assert _buf */
        cb = chm_retrieve_object(h, ui, _buf, 
            (LONGUINT64) addr, (LONGINT64) len); 
        RETVAL = newSVpvn(_buf, cb); 
        free(_buf); 
    OUTPUT: 
        RETVAL

int
chm_enumerate(h, what, cb, context)
        PCHMFILE h
        int what
        SV *cb
        SV *context
    PROTOTYPE: $$&;$
    INIT: 
        SV *recall[2];
    CODE: 
        /* chm_enumerate(h, what, ENUM, context); */
        recall[0] = cb; 
        recall[1] = context; 
        RETVAL = chm_enumerate(h, what, 
            (CHM_ENUMERATOR)_chm_enumerator, recall);
    OUTPUT: 
        RETVAL

int
chm_enumerate_dir(h, prefix, what, cb, context)
        PCHMFILE h
        const char *prefix
        int what
        SV *cb
        SV *context
    PROTOTYPE: $$$&;$
    INIT: 
        SV *recall[2]; 
    CODE: 
        /* chm_enumerate_dir(h, prefix, what, cb, context) */
        recall[0] = cb; 
        recall[1] = context; 
        RETVAL = chm_enumerate_dir(h, prefix, what, 
            (CHM_ENUMERATOR)_chm_enumerator, recall);
    OUTPUT: 
        RETVAL

HV *
dumpUnitInfo(ui)
        PCHMUNITINFO ui
    PROTOTYPE: $
    INIT: 
        HV *hash; 
    CODE: 
        hash = newHV(); 
        hv_set(hash, "start",   newSVuv((unsigned long) ui->start));
        hv_set(hash, "length",  newSVuv((unsigned long) ui->length));
        hv_set(hash, "space",   newSVuv((long) ui->space));
        hv_set(hash, "flags",   newSVuv((long) ui->flags));
        hv_set(hash, "path",    newSVpv(ui->path, 0));
        RETVAL = hash;
    OUTPUT: 
        RETVAL

void
getUnitInfo(ui)
        PCHMUNITINFO ui
    PROTOTYPE: $
    PPCODE: 
        XPUSHs(sv_2mortal(newSVpv(ui->path, 0)));
        XPUSHs(newSVuv((long) ui->flags));
        XPUSHs(newSVuv((unsigned long) ui->start));
        XPUSHs(newSVuv((unsigned long) ui->length));
        XPUSHs(newSVuv((long) ui->space));
