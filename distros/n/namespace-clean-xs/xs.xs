#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "xs/compat.h"

#define MY_CXT_KEY "namespace::clean::xs::_guts" XS_VERSION
typedef struct {
#ifdef USE_ITHREADS
    tTHX owner;
#endif
    SV* storage_key;
} my_cxt_t;

START_MY_CXT;

#define NCX_STORAGE "__NAMESPACE_CLEAN_STORAGE_XS"
#define NCX_REMOVE (&PL_sv_yes)
#define NCX_EXCLUDE (&PL_sv_no)

typedef struct {
    HV* storage;
    SV* marker;
} fn_marker;

static int NCX_on_scope_end_normal(pTHX_ SV* sv, MAGIC* mg);
static MGVTBL vtscope_normal = {
    NULL, NULL, NULL, NULL, NCX_on_scope_end_normal
};

static int NCX_on_scope_end_list(pTHX_ SV* sv, MAGIC* mg);
static MGVTBL vtscope_list = {
    NULL, NULL, NULL, NULL, NCX_on_scope_end_list
};

static inline GV*
NCX_storage_glob(pTHX_ HV* stash) {
    dMY_CXT;
    SV** svp = (SV**)hv_fetch_sv_flags(stash, MY_CXT.storage_key, HV_FETCH_JUST_SV | HV_FETCH_LVALUE);

    if (!isGV(*svp)) {
        gv_init_sv((GV*)*svp, stash, MY_CXT.storage_key, GV_ADDMULTI);
    }

    return (GV*)*svp;
}

static inline HV*
NCX_storage_hv(pTHX_ HV* stash) {
    GV* glob = NCX_storage_glob(aTHX_ stash);
    return GvHVn(glob);
}

static void
NCX_foreach_sub(pTHX_ HV* stash, void (cb)(pTHX_ HE*, void*), void* data) {
    STRLEN hvmax = HvMAX(stash);
    HE** hvarr = HvARRAY(stash);
    assert(hvarr);

    HE* he;
    STRLEN bucket_num;
    for (bucket_num = 0; bucket_num <= hvmax; ++bucket_num) {
        for (he = hvarr[bucket_num]; he; he = HeNEXT(he)) {
            if (HeVAL(he) == &PL_sv_placeholder) continue;

            GV* gv = (GV*)HeVAL(he);
            if (!isGV(gv) || (GvCV(gv) && !GvCVGEN(gv))) {
                cb(aTHX_ he, data);
            }
        }
    }
}

static void
NCX_cb_get_functions(pTHX_ HE* slot, void* hv) {
    GV* gv = (GV*)HeVAL(slot);

    if (isGV(gv)) {
        hv_storehek((HV*)hv, HeKEY_hek(slot), newRV_inc((SV*)GvCV(gv)));
    } else {
        hv_storehek((HV*)hv, HeKEY_hek(slot), SvREFCNT_inc_NN(gv));
    }
}

static void
NCX_cb_add_marker(pTHX_ HE* slot, void* data) {
    fn_marker* m = (fn_marker*)data;

    HE* he = (HE*)hv_fetchhek_flags(m->storage, HeKEY_hek(slot), HV_FETCH_EMPTY_HE | HV_FETCH_LVALUE);

#ifndef NO_HV_FETCH_EMPTY_HE
    if (HeVAL(he) == NULL) {
#else
    if (!SvOK(HeVAL(he))) {
        SvREFCNT_dec_NN(HeVAL(he));
#endif
        HeVAL(he) = m->marker;
    }
}

static void
NCX_single_marker(pTHX_ HV* storage, SV* name, SV* marker) {
    HE* he = (HE*)hv_fetch_sv_flags(storage, name, HV_FETCH_EMPTY_HE | HV_FETCH_LVALUE);

#ifndef NO_HV_FETCH_EMPTY_HE
    if (HeVAL(he) == NULL) {
#else
    if (!SvOK(HeVAL(he))) {
        SvREFCNT_dec_NN(HeVAL(he));
#endif
        HeVAL(he) = marker;
    }
}

#ifdef DEBUGGER_NEEDS_CV_RENAME
static void
NCX_fake_subname(pTHX_ HV* fake_stash, GV* gv) {
    if (!PL_DBsub) return;

    hv_storehek(fake_stash, GvNAME_HEK(gv), (SV*)gv);
    GvSTASH(gv) = fake_stash;
}

static HV*
NCX_debugger_fake_stash(pTHX_ HV* old_stash) {
    HEK* orig_hek = HvNAME_HEK(old_stash);
    assert(orig_hek);

    #define FAKE_PREFIX "namespace::clean::xs::d::"

    char* full_name;
    Newx(full_name, HEK_LEN(orig_hek) + strlen(FAKE_PREFIX) + 1, char);

    memcpy(full_name, FAKE_PREFIX, strlen(FAKE_PREFIX));
    memcpy(full_name + strlen(FAKE_PREFIX), HEK_KEY(orig_hek), HEK_LEN(orig_hek) + 1);
    assert(full_name[HEK_LEN(orig_hek) + strlen(FAKE_PREFIX)] == '\0');

    HV* fake_stash = gv_stashpvn(full_name, HEK_LEN(orig_hek) + strlen(FAKE_PREFIX), GV_ADD | HEK_UTF8(orig_hek));
    assert(fake_stash);

    Safefree(full_name);
    #undef FAKE_PREFIX

    return fake_stash;
}

#define GLOB_NO_NONSUB(gv) (0)
#define DEBUGGER_FAKE_STASH \
    HV* fake_stash = NCX_debugger_fake_stash(aTHX_ stash);
#define NCX_replace_glob_sv(...) NCX_replace_glob_sv_impl(__VA_ARGS__, fake_stash)
#define NCX_replace_glob_hek(...) NCX_replace_glob_hek_impl(__VA_ARGS__, fake_stash)

#else

#define NCX_fake_subname(...)
#define GLOB_NO_NONSUB(gv) \
    !GvSV(gv) && !GvAV(gv) && !GvHV(gv) && !GvIOp(gv) && !GvFORM(gv)
#define DEBUGGER_FAKE_STASH
#define NCX_replace_glob_sv NCX_replace_glob_sv_impl
#define NCX_replace_glob_hek NCX_replace_glob_hek_impl

#endif

#define NCX_REPLACE_PRE         \
    GV* old_gv = (GV*)HeVAL(he);\
                                \
    if (!isGV(old_gv) || GLOB_NO_NONSUB(old_gv)) {      \
        hv_deletehek(stash, HeKEY_hek(he), G_DISCARD);  \
        return;                 \
    }                           \
                                \
    CV* cv = GvCVu(old_gv);     \
    if (!cv) return;            \
                                \
    GV* new_gv = (GV*)newSV(0); \

#define NCX_REPLACE_POST            \
    HeVAL(he) = (SV*)new_gv;        \
                                    \
    if (GvSV(old_gv)) GvSV(new_gv) = (SV*)SvREFCNT_inc_NN(GvSV(old_gv));         \
    if (GvAV(old_gv)) GvAV(new_gv) = (AV*)SvREFCNT_inc_NN(GvAV(old_gv));         \
    if (GvHV(old_gv)) GvHV(new_gv) = (HV*)SvREFCNT_inc_NN(GvHV(old_gv));         \
    if (GvIOp(old_gv)) GvIOp(new_gv) = (IO*)SvREFCNT_inc_NN(GvIOp(old_gv));      \
    if (GvFORM(old_gv)) GvFORM(new_gv) = (CV*)SvREFCNT_inc_NN(GvFORM(old_gv));   \
                                    \
    GvCV_set(old_gv, cv);           \
    GvCV_set(new_gv, NULL);         \
    NCX_fake_subname(aTHX_ fake_stash, old_gv); \

static void
#ifdef DEBUGGER_NEEDS_CV_RENAME
NCX_replace_glob_sv_impl(pTHX_ HV* stash, SV* name, HV* fake_stash) {
#else
NCX_replace_glob_sv_impl(pTHX_ HV* stash, SV* name) {
#endif
    HE* he = hv_fetch_ent(stash, name, 0, 0);
    if (!he) return;

    NCX_REPLACE_PRE;

    gv_init_sv(new_gv, stash, name, GV_ADDMULTI);

    NCX_REPLACE_POST;
}

static void
#ifdef DEBUGGER_NEEDS_CV_RENAME
NCX_replace_glob_hek_impl(pTHX_ HV* stash, HEK* hek, HV* fake_stash) {
#else
NCX_replace_glob_hek_impl(pTHX_ HV* stash, HEK* hek) {
#endif
    HE* he = (HE*)hv_fetchhek_flags(stash, hek, 0);
    if (!he) return;

    NCX_REPLACE_PRE;

    gv_init_pvn(new_gv, stash, HEK_KEY(hek), HEK_LEN(hek), GV_ADDMULTI | HEK_UTF8(hek));

    NCX_REPLACE_POST;
}

static int
NCX_on_scope_end_normal(pTHX_ SV* sv, MAGIC* mg) {
    HV* stash = (HV*)(mg->mg_obj);
    GV* storage_gv = NCX_storage_glob(aTHX_ stash);

    HV* storage = GvHV(storage_gv);
    if (!storage) return 0;

    STRLEN hvmax = HvMAX(storage);
    HE** hvarr = HvARRAY(storage);
    if (!hvarr) return 0;

    SV* pl_remove = NCX_REMOVE;

    DEBUGGER_FAKE_STASH;

    HE* he;
    STRLEN bucket_num;
    for (bucket_num = 0; bucket_num <= hvmax; ++bucket_num) {
        for (he = hvarr[bucket_num]; he; he = HeNEXT(he)) {
            assert(HeVAL(he) == NCX_REMOVE || HeVAL(he) == NCX_EXCLUDE);

            if (HeVAL(he) == pl_remove) {
                NCX_replace_glob_hek(aTHX_ stash, HeKEY_hek(he));
            }
        }
    }

    mro_method_changed_in(stash);

    SvREFCNT_dec_NN(storage);
    GvHV(storage_gv) = NULL;

    return 0;
}

static void
NCX_register_hook_normal(pTHX_ HV* stash) {
    SV* hints = (SV*)GvHV(PL_hintgv);
    assert(hints);

    if (SvRMAGICAL(hints)) {
        MAGIC* mg;
        for (mg = SvMAGIC(hints); mg; mg = mg->mg_moremagic) {
            if (mg->mg_virtual == &vtscope_normal && mg->mg_obj == (SV*)stash) {
                return;
            }
        }
    }

    sv_magicext(hints, (SV*)stash, PERL_MAGIC_ext, &vtscope_normal, NULL, 0);
    PL_hints |= HINT_LOCALIZE_HH;
}

static int
NCX_on_scope_end_list(pTHX_ SV* sv, MAGIC* mg) {
    HV* stash = (HV*)(mg->mg_obj);
    AV* list = (AV*)(mg->mg_ptr);
    assert(stash && list);

    SV** items = AvARRAY(list);
    SSize_t fill = AvFILLp(list);
    assert(items && fill >= 0);

    DEBUGGER_FAKE_STASH;

    while (fill-- >= 0) {
        NCX_replace_glob_sv(aTHX_ stash, *items++);
    }

    mro_method_changed_in(stash);

    return 0;
}

static void
NCX_register_hook_list(pTHX_ HV* stash, AV* list) {
    sv_magicext((SV*)GvHV(PL_hintgv), (SV*)stash, PERL_MAGIC_ext, &vtscope_list, (const char *)list, HEf_SVKEY);
    PL_hints |= HINT_LOCALIZE_HH;
}

MODULE = namespace::clean::xs     PACKAGE = namespace::clean::xs
PROTOTYPES: DISABLE

BOOT:
{
    MY_CXT_INIT;
    MY_CXT.storage_key = newSVpvn_share(NCX_STORAGE, strlen(NCX_STORAGE), 0);
#ifdef USE_ITHREADS
    MY_CXT.owner = aTHX;
#endif
}

void
import(SV* self, ...)
PPCODE:
{
    HV* stash = CopSTASH(PL_curcop);

    ++SP;
    SV* except = NULL;
    SSize_t processed;

    for (processed = 1; processed < items; processed += 2) {
        SV* arg = *++SP;
        if (!SvPOK(arg)) break;

        const char* buf = SvPVX_const(arg);
        if (!SvCUR(arg) || buf[0] != '-') break;

        if (processed + 1 > items) {
            croak("Not enough arguments for %s option in import() call", buf);
        }

        if (strEQ(buf, "-cleanee")) {
            stash = gv_stashsv(*++SP, GV_ADD);

        } else if (strEQ(buf, "-except")) {
            except = *++SP;

        } else {
            croak("Unknown argument %s in import() call", buf);
        }
    }

    if (processed < items) {
        AV* list = newAV();
        av_extend(list, items - processed - 1);
        AvFILLp(list) = items - processed - 1;

        SV** list_data = AvARRAY(list);
        while (++processed <= items) {
            *list_data++ = SvREFCNT_inc_NN(*SP++);
        }

        NCX_register_hook_list(aTHX_ stash, list);
        SvREFCNT_dec_NN(list); /* refcnt owned by magic now */

    } else {
        HV* storage = NCX_storage_hv(aTHX_ stash);
        if (except) {
            if (SvROK(except) && SvTYPE(SvRV(except)) == SVt_PVAV) {
                AV* except_av = (AV*)SvRV(except);
                SSize_t len = av_len(except_av);

                SSize_t i;
                for (i = 0; i <= len; ++i) {
                    SV** svp = av_fetch(except_av, i, 0);
                    if (svp) NCX_single_marker(aTHX_ storage, *svp, NCX_EXCLUDE);
                }

            } else {
                NCX_single_marker(aTHX_ storage, except, NCX_EXCLUDE);
            }
        }

        fn_marker m = {storage, NCX_REMOVE};

        NCX_foreach_sub(aTHX_ stash, NCX_cb_add_marker, &m);
        NCX_register_hook_normal(aTHX_ stash);
    }

    XSRETURN_YES;
}

void
unimport(SV* self, ...)
PPCODE:
{
    HV* stash;
    if (items > 2) {
        ++SP;
        SV* arg = *++SP;

        if (SvPOK(arg) && strEQ(SvPVX(arg), "-cleanee")) {
            stash = gv_stashsv(*++SP, 0);
        } else {
            croak("Unknown argument %s in unimport() call", SvPV_nolen(arg));
        }
    } else {
        stash = CopSTASH(PL_curcop);
    }

    if (stash) {
        HV* storage = NCX_storage_hv(aTHX_ stash);
        fn_marker m = {storage, NCX_EXCLUDE};

        NCX_foreach_sub(aTHX_ stash, NCX_cb_add_marker, &m);
    }

    XSRETURN_YES;
}

void
clean_subroutines(SV* self, SV* package, ...)
PPCODE:
{
    HV* stash = gv_stashsv(package, 0);
    if (stash && --items > 1) {
        SP += 2;

        DEBUGGER_FAKE_STASH;

        while (--items > 0) {
            NCX_replace_glob_sv(aTHX_ stash, *++SP);
        }

        mro_method_changed_in(stash);
    }

    XSRETURN_UNDEF;
}

void
get_functions(SV* self, SV* package)
PPCODE:
{
    HV* hv = newHV();
    
    HV* stash = gv_stashsv(package, 0);
    if (stash) {
        NCX_foreach_sub(aTHX_ stash, NCX_cb_get_functions, hv);
    }

    PUSHs(sv_2mortal(newRV_noinc((SV*)hv)));
    XSRETURN(1);
}

void
get_class_store(SV* self, SV* package)
PPCODE:
{
    HV* hv = newHV();

    HV* stash = gv_stashsv(package, 0);
    if (stash) {
        HV* storage = NCX_storage_hv(aTHX_ stash);

        HV* exclude = newHV();
        hv_store(hv, "exclude", 7, newRV_noinc((SV*)exclude), 0);

        HV* remove = newHV();
        hv_store(hv, "remove", 6, newRV_noinc((SV*)remove), 0);

        hv_iterinit(storage);
        HE* he;
        while ((he = hv_iternext(storage))) {
            assert(HeVAL(he) == NCX_EXCLUDE || HeVAL(he) == NCX_REMOVE);
            hv_storehek(HeVAL(he) == NCX_EXCLUDE ? exclude : remove, HeKEY_hek(he), &PL_sv_undef);
        }
    }

    PUSHs(sv_2mortal(newRV_noinc((SV*)hv)));
    XSRETURN(1);
}

#ifdef USE_ITHREADS

void
CLONE(...)
PPCODE:
{
    SV* cloned;

    {
        dMY_CXT;
        CLONE_PARAMS params = {NULL, 0, MY_CXT.owner};

        cloned = sv_dup_inc(MY_CXT.storage_key, &params);
    }

    {
        MY_CXT_CLONE;
        MY_CXT.owner            = aTHX;
        MY_CXT.storage_key      = cloned;
    }

    XSRETURN_UNDEF;
}

#endif /* USE_ITHREADS */
