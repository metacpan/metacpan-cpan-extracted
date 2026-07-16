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
#define fetch_report HV *report = get_hv("Test2::Plugin::Cover::REPORT", GV_ADDMULTI);
#define fetch_opens AV *opens = get_av("Test2::Plugin::Cover::OPENS", GV_ADDMULTI);
#define fetch_from SV *from = get_sv("Test2::Plugin::Cover::FROM", 0);
#define fetch_root SV *root = get_sv("Test2::Plugin::Cover::ROOT", 0);
#define fetch_enabled SV *enabled = get_sv("Test2::Plugin::Cover::ENABLED", 0);
#define fetch_trace_opens SV *trace_opens = get_sv("Test2::Plugin::Cover::TRACE_OPENS", 0);
#else
HV *report;
AV *opens;
// Cache the GVs, not the SVs, so local() (which swaps the SV in the glob)
// still resolves to the live value.
GV *from_gv;
GV *root_gv;
GV *enabled_gv;
GV *trace_opens_gv;
#define fetch_report NOOP
#define fetch_opens NOOP
#define fetch_from SV *from = GvSV(from_gv);
#define fetch_root SV *root = GvSV(root_gv);
#define fetch_enabled SV *enabled = GvSV(enabled_gv);
#define fetch_trace_opens SV *trace_opens = GvSV(trace_opens_gv);
#endif

void add_entry(char *fname, STRLEN fnamelen, char *sname, STRLEN snamelen) {
    fetch_report;
    HV *file = NULL;
    SV **existing_file = hv_fetch(report, fname, fnamelen, 0);
    if (existing_file) {
        file = (HV *)SvRV(*existing_file);
    }
    else {
        file = newHV();
        hv_store(report, fname, fnamelen, newRV_noinc((SV *)file), 0);
    }

    HV *sub = NULL;
    SV **existing_sub = hv_fetch(file, sname, snamelen, 0);
    if (existing_sub) {
        sub = (HV *)SvRV(*existing_sub);
    }
    else {
        sub = newHV();
        hv_store(file, sname, snamelen, newRV_noinc((SV *)sub), 0);
    }

    fetch_from;
    if (!(from && SvOK(from))) {
        if (!hv_exists(sub, "*", 1)) {
            from = newSVpv("*", 1);
            hv_store_ent(sub, from, from, 0);
        }
    }
    else if (!hv_exists_ent(sub, from, 0)) {
        from = sv_mortalcopy(from);
        SvREFCNT_inc(from);
        hv_store_ent(sub, from, from, 0);
    }

    return;
}

static OP* my_subhandler(pTHX) {
    dSP;
    // Grab the sub SV before running the original handler, an XS call may
    // overwrite this stack slot with a return value.
    SV *sub_sv = *SP;
    OP* out = orig_subhandler(aTHX);

    fetch_enabled;
    if (!SvTRUE(enabled)) {
        return out;
    }

    if (out != NULL && (out->op_type == OP_NEXTSTATE || out->op_type == OP_DBSTATE)) {
        char *fname = CopFILE(cCOPx(out));
        STRLEN namelen = strlen(fname);

        // Check for absolute paths and reject them. This is a very
        // unix-oriented optimization.
        if (!strncmp(fname, "/", 1)) {
            fetch_root;

            if (root != NULL && SvPOK(root)) {
                STRLEN len;
                char *rt = NULL;
                rt = SvPV(root, len);

                if (namelen < len) return out;

                if (strncmp(fname, rt, len)) {
                    return out;
                }
            }
        }

        char *subname = NULL;
        STRLEN sublen = 0;

        GV *my_gv = sub_to_gv(aTHX_ sub_sv);
        if (my_gv != NULL) {
            subname = GvNAME(my_gv);
            sublen = strlen(subname);
        }
        else {
            subname = "*";
            sublen = 1;
        }

        add_entry(fname, namelen, subname, sublen);
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
                char *sym = NULL;

                if (sv == &PL_sv_yes) {           /* unfound import, ignore */
                    return NULL;
                }
                if (SvGMAGICAL(sv)) {
                    // pp_entersub already ran get-magic; use the cached value.
                    // Calling mg_get() here would re-run FETCH (arbitrary perl
                    // code) from inside the op hook.
                    if (SvROK(sv))
                        goto got_rv;
                    sym = SvPOKp(sv) ? SvPVX(sv) : Nullch;
                }
                // else {
                    // This causes the warnings from issue #2 https://github.com/Test-More/Test2-Plugin-Cover/issues/2
                    //sym = SvPV_nolen(sv);
                // }

                if (!sym)
                    return NULL;
                if (PL_op->op_private & HINT_STRICT_REFS)
                    return NULL;
                cv = get_cv(sym, TRUE);
                break;
            }
            got_rv:
            // No amagic (&{} overload) dereference here, pp_entersub already
            // did it and re-invoking it would run arbitrary perl code from
            // inside the op hook. Non-CV refs just fall through to NULL.
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

void _sv_file_handler(SV *filename) {
    if (filename == NULL) return;
    if (!SvPOKp(filename)) return;

    STRLEN namelen = 0;
    char *fname = SvPV(filename, namelen);

    add_entry(fname, namelen, "<>", 2);

    fetch_trace_opens;
    if (!SvTRUE(trace_opens)) return;

    const PERL_CONTEXT* cx = cxstack;
    AV* row  = newAV();

    av_push(row, newSVpvn(fname, namelen));
    av_push(row, newSVpv(OutCopFILE(PL_curcop), 0));
    av_push(row, newSViv(CopLINE(PL_curcop)));

    SV* package = newSVpv(CopSTASHPV(PL_curcop), 0);
    av_push(row, package);

    fetch_opens;
    av_push(opens, newRV_noinc((SV *)row));
}

static OP* my_openhandler(pTHX) {
    dSP;

    fetch_enabled;
    if (SvTRUE(enabled)) {
        SV **mark = PL_stack_base + TOPMARK;
        I32 items = (I32)(sp - mark);

        // Only grab for 2-arg or 3-arg form
        if (items == 2 || items == 3) {
            _sv_file_handler(TOPs);
        }
    }

    return orig_openhandler(aTHX);
}

static OP* my_sysopenhandler(pTHX) {
    dSP;

    fetch_enabled;
    if (SvTRUE(enabled)) {
        // pp_sysopen is fixed-arity, its pushmark is nulled at compile time,
        // so TOPMARK belongs to an enclosing op and cannot be used to find
        // the args (doing so read arbitrary stack slots and could segv).
        // Index from the stack top instead: gv, filename, mode, [perms].
        I32 args = MAXARG;
        if (args >= 3) {
            _sv_file_handler(*(sp - (args - 2)));
        }
    }

    return orig_sysopenhandler(aTHX);
}

MODULE = Test2::Plugin::Cover PACKAGE = Test2::Plugin::Cover

PROTOTYPES: ENABLE

BOOT:
    {
        // If the module is reloaded (%INC cleared + re-required) BOOT runs
        // again; without this guard the second run captures our own handlers
        // as "orig" and the next sub call recurses infinitely (segfault).
        static int booted = 0;
        if (!booted) {
            booted = 1;

            //Initialize the global files HV, but only if we are not a threaded perl
#ifndef USE_ITHREADS
            report = get_hv("Test2::Plugin::Cover::REPORT", GV_ADDMULTI);
            SvREFCNT_inc(report);
            opens = get_av("Test2::Plugin::Cover::OPENS", GV_ADDMULTI);
            SvREFCNT_inc(opens);

            from_gv        = gv_fetchpv("Test2::Plugin::Cover::FROM", GV_ADDMULTI, SVt_PV);
            root_gv        = gv_fetchpv("Test2::Plugin::Cover::ROOT", GV_ADDMULTI, SVt_PV);
            enabled_gv     = gv_fetchpv("Test2::Plugin::Cover::ENABLED", GV_ADDMULTI, SVt_PV);
            trace_opens_gv = gv_fetchpv("Test2::Plugin::Cover::TRACE_OPENS", GV_ADDMULTI, SVt_PV);
            SvREFCNT_inc((SV *)from_gv);
            SvREFCNT_inc((SV *)root_gv);
            SvREFCNT_inc((SV *)enabled_gv);
            SvREFCNT_inc((SV *)trace_opens_gv);
#endif

            orig_subhandler = PL_ppaddr[OP_ENTERSUB];
            PL_ppaddr[OP_ENTERSUB] = my_subhandler;

            orig_openhandler = PL_ppaddr[OP_OPEN];
            PL_ppaddr[OP_OPEN] = my_openhandler;

            orig_sysopenhandler = PL_ppaddr[OP_SYSOPEN];
            PL_ppaddr[OP_SYSOPEN] = my_sysopenhandler;
        }
    }
