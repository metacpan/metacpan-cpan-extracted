#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <stdio.h>

static GV *sub_to_gv(pTHX_ SV *sv);
Perl_ppaddr_t orig_subhandler;
Perl_ppaddr_t orig_openhandler;
Perl_ppaddr_t orig_sysopenhandler;

// If we do not use threads we will make this global
// The performance impact of fetching it each time is significant, so avoid it
// if we can.
#ifdef USE_ITHREADS
#define fetch_touched AV *touched = get_av("Test2::Plugin::Cover::TOUCHED", GV_ADDMULTI);
#define fetch_opened  HV *opened  = get_av("Test2::Plugin::Cover::OPENED",  GV_ADDMULTI);
#else
AV *touched;
AV *opened;
#define fetch_touched NOOP
#define fetch_opened NOOP
#endif

#define fetch_from SV *from = get_sv("Test2::Plugin::Cover::FROM", 0);

static OP* my_subhandler(pTHX) {
    dSP;
    OP* out = orig_subhandler(aTHX);

    if (out != NULL && (out->op_type == OP_NEXTSTATE || out->op_type == OP_DBSTATE)) {
        SV *subname = NULL;

        GV *my_gv = sub_to_gv(aTHX_ *SP);
        if (my_gv != NULL) {
            subname = newSVpv(GvNAME(my_gv), 0);
        }

        HV *item = newHV();

        SV *file = newSVpv(CopFILE(cCOPx(out)), 0);
        hv_store(item, "file", 4, file, 0);

        fetch_from;
        if (from && SvOK(from)) {
            SV *from_val = sv_mortalcopy(from);
            SvREFCNT_inc(from_val);
            hv_store(item, "called_by", 9, from_val, 0);
        }

        if (subname) {
            hv_store(item, "sub_name", 8, subname, 0);
        }

        fetch_touched;
        av_push(touched, newRV((SV *)item));
    }

    return out;
}

// Copied and modified from Devel::NYTProf
static GV *sub_to_gv(pTHX_ SV *sv) {
    CV *cv = NULL;

    /* copied from top of perl's pp_entersub */
    /* modified to return either CV or else a GV */
    /* or a NULL in cases that pp_entersub would croak */
    switch (SvTYPE(sv)) {
        default:
            if (!SvROK(sv)) {
                char *sym;

                if (sv == &PL_sv_yes) {           /* unfound import, ignore */
                    return NULL;
                }
                if (SvGMAGICAL(sv)) {
                    mg_get(sv);
                    if (SvROK(sv))
                        goto got_rv;
                    sym = SvPOKp(sv) ? SvPVX(sv) : Nullch;
                }
                else
                    // This causes the warnings from issue #2 https://github.com/Test-More/Test2-Plugin-Cover/issues/2
                    //sym = SvPV_nolen(sv);
                if (!sym)
                    return NULL;
                if (PL_op->op_private & HINT_STRICT_REFS)
                    return NULL;
                cv = get_cv(sym, TRUE);
                break;
            }
            got_rv:
            {
                SV **sp = &sv;                    /* Used in tryAMAGICunDEREF macro. */
                tryAMAGICunDEREF(to_cv);
            }
            cv = (CV*)SvRV(sv);
            if (SvTYPE(cv) == SVt_PVCV)
                break;

            /* FALL THROUGH */
        case SVt_PVHV:
        case SVt_PVAV:
            return NULL;

        case SVt_PVCV:
            cv = (CV*)sv;
            break;

        case SVt_PVGV:
            if (!(isGV_with_GP(sv) && (cv = GvCVu((GV*)sv)))) {
                HV *stash = NULL;
                GV *gv = NULL;
                cv = sv_2cv(sv, &stash, &gv, FALSE);

                if (gv) {
                    return gv;
                }
            }

            if (!cv) {                            /* would autoload in this situation */
                return NULL;
            }

            break;
    }

    if (cv) {
        GV *out = CvGV(cv);
        if (out && isGV_with_GP(out)) {
            return out;
        }
    }

    return NULL;
}

void _sv_file_handler(SV *file) {
    if (file != NULL && SvPOKp(file)) {
        fetch_opened;

        AV *item = newAV();
        av_push(item, file);
        SvREFCNT_inc(file);
        av_push(opened, newRV((SV *)item));

        fetch_from;
        if (from && SvOK(from)) {
            SV *from_val = sv_mortalcopy(from);
            SvREFCNT_inc(from_val);
            av_push(item, from_val);
        }
    }
}

static OP* my_openhandler(pTHX) {
    dSP;
    SV **mark = PL_stack_base + TOPMARK;
    I32 items = (I32)(sp - mark);

    // Only grab for 2-arg or 3-arg form
    if (items == 2 || items == 3) {
        _sv_file_handler(TOPs);
    }

    return orig_openhandler(aTHX);
}

static OP* my_sysopenhandler(pTHX) {
    dSP;
    SV **mark = PL_stack_base + TOPMARK;
    I32 ax    = (I32)(mark - PL_stack_base + 1);
    I32 items = (I32)(sp - mark);

    if (items >= 2) {
        _sv_file_handler(PL_stack_base[ax + (1)]);
    }

    return orig_sysopenhandler(aTHX);
}

MODULE = Test2::Plugin::Cover PACKAGE = Test2::Plugin::Cover

PROTOTYPES: ENABLE

BOOT:
    {
        //Initialize the global files HV, but only if we are not a threaded perl
#ifndef USE_ITHREADS
        touched = get_av("Test2::Plugin::Cover::TOUCHED", GV_ADDMULTI);
        opened  = get_av("Test2::Plugin::Cover::OPENED",  GV_ADDMULTI);
        SvREFCNT_inc(touched);
        SvREFCNT_inc(opened);
#endif

        orig_subhandler = PL_ppaddr[OP_ENTERSUB];
        PL_ppaddr[OP_ENTERSUB] = my_subhandler;

        orig_openhandler = PL_ppaddr[OP_OPEN];
        PL_ppaddr[OP_OPEN] = my_openhandler;

        //orig_sysopenhandler = PL_ppaddr[OP_SYSOPEN];
        //PL_ppaddr[OP_SYSOPEN] = my_sysopenhandler;
    }
