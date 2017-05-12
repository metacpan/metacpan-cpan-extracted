#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

OP* (*orig_op_fork)(pTHX);

void find_and_exec(pTHX)
{
    SV* sva;
    GV* method;
    HV* stash;
    dSP;
    for (sva = PL_sv_arenaroot; sva; sva = (SV*)SvANY(sva)) {
        register const SV* const svend = &sva[SvREFCNT(sva)];
        SV* svi;
        for (svi = sva + 1; svi < svend; ++svi) {
            if (SvTYPE(svi) != SVTYPEMASK && SvREFCNT(svi)) {
                if (SvOBJECT(svi)) {
                    stash = SvSTASH(svi);
                    method = gv_fetchmethod_autoload(stash, "AFTER_FORK_OBJ", 0);
                    if (method) {
                        ENTER;
                        SAVETMPS;
                        PUSHMARK(SP);
                        XPUSHs(sv_2mortal(newRV_inc(svi)));
                        PUTBACK;
                        call_sv((SV*)GvCV(method), G_DISCARD | G_VOID);
                        FREETMPS;
                        LEAVE;
                    }
                }
                else if (SvTYPE(svi) == SVt_PVHV) {
                    if (HvNAME((HV*)svi)) {
                        method = gv_fetchmethod_autoload((HV*)svi, "AFTER_FORK", 0);
                        if (method) {
                            PUSHMARK(SP);
                            call_sv((SV*)GvCV(method), G_DISCARD | G_NOARGS | G_VOID);
                        }
                    }
                }
            }
        }
    }
}

static OP* pp_fork_hook(pTHX)
{
    dMARK;
    dAX;
    OP* op = CALL_FPTR(orig_op_fork)(aTHX);
    if (SvIOK(ST(0)) && (SvIV(ST(0)) == 0)) {
        find_and_exec(aTHX);
    }
    return op;
}

MODULE = fork::hook     PACKAGE = fork::hook

PROTOTYPES: DISABLE

BOOT:
    orig_op_fork = PL_ppaddr[OP_FORK];
    PL_ppaddr[OP_FORK] = pp_fork_hook;
