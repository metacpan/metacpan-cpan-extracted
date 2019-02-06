#include "next.h"
#include <string>
#include <stdexcept>

namespace xs {

static MGVTBL c3_marker;

#ifndef FORCEINLINE
#    if defined(_MSC_VER)
#        define FORCEINLINE __forceinline
#    elif defined(__GNUC_) && _GNUC__ > 3
#        define FORCEINLINE inline _attribute_ ((_always_inline_))
#    else
#        define FORCEINLINE inline
#    endif
#endif

static FORCEINLINE I32 __dopoptosub_at (const PERL_CONTEXT* cxstk, I32 startingblock) {
    I32 i;
    for (i = startingblock; i >= 0; --i) if (CxTYPE(cxstk+i) == CXt_SUB) return i;
    return i;
}

// finds the contextually-enclosing fully-qualified subname, much like looking at (caller($i))[3] until you find a real sub that isn't ANON, etc
static FORCEINLINE GV* _find_sub (pTHX_ SV** fqnp) {
    const PERL_SI* top_si = PL_curstackinfo;
    const PERL_CONTEXT* ccstack = cxstack;
    I32 cxix = __dopoptosub_at(ccstack, cxstack_ix);

    for (;;) {
        /* we may be in a higher stacklevel, so dig down deeper */
        while (cxix < 0) {
            if (top_si->si_type == PERLSI_MAIN) throw std::logic_error("next::method/next::can/maybe::next::method must be used in method context");
            top_si = top_si->si_prev;
            ccstack = top_si->si_cxstack;
            cxix = __dopoptosub_at(ccstack, top_si->si_cxix);
        }

        if (PL_DBsub && GvCV(PL_DBsub)) {
            if (ccstack[cxix].blk_sub.cv == GvCV(PL_DBsub)) {
                cxix = __dopoptosub_at(ccstack, cxix - 1);
                continue;
            }
            const I32 dbcxix = __dopoptosub_at(ccstack, cxix - 1);
            if (dbcxix >= 0 && ccstack[dbcxix].blk_sub.cv == GvCV(PL_DBsub)) {
                if (CxTYPE((PERL_CONTEXT*)(&ccstack[dbcxix])) != CXt_SUB) {
                    cxix = dbcxix;
                    continue;
                }
            }
        }

        /* we found a real sub here */
        CV* cv = ccstack[cxix].blk_sub.cv;
        GV* gv = CvGV(cv);
        HV* stash = GvSTASH(gv);

        MAGIC* mg = mg_findext((SV*)gv, PERL_MAGIC_ext, &c3_marker);
        if (mg && (HV*)mg->mg_ptr == stash) {
            *fqnp = mg->mg_obj;
            return gv;
        }

        if (!stash || !HvNAME(stash) || (GvNAMELEN(gv) == 8 && !memcmp(GvNAME(gv), "__ANON__", 8))) { // ANON sub
            cxix = __dopoptosub_at(ccstack, cxix - 1);
            continue;
        }

        return gv;
    }
}

static FORCEINLINE SV* _make_shared_fqn (pTHX_ GV* gv) {
    HV* stash = GvSTASH(gv);
    STRLEN pkglen = HvNAMELEN(stash);
    STRLEN fqnlen = pkglen + GvNAMELEN(gv) + 2;
    char fqn[fqnlen+1];
    memcpy(fqn, HvNAME(stash), pkglen);
    fqn[pkglen] = ':';
    fqn[pkglen+1] = ':';
    memcpy(fqn + pkglen + 2, GvNAME(gv), GvNAMELEN(gv));
    fqn[fqnlen] = 0;
    return newSVpvn_share(fqn, (HvNAMEUTF8(stash) || GvNAMEUTF8(gv)) ? -(I32)fqnlen : (I32)fqnlen, 0);
}

static FORCEINLINE void _throw_no_next_method (HV* selfstash, GV* context) {
    std::string subname(GvNAME(context), GvNAMELEN(context));
    std::string stashname(HvNAME(selfstash), HvNAMELEN(selfstash));
    throw std::logic_error(std::string("No next::method '") + subname + "' found for " + stashname);
}

static FORCEINLINE CV* _method (pTHX_ HV* selfstash, GV* context, SV* fqnsv) {
    if (!fqnsv) { // cache FQN SV with shared COW hash of current sub in magic to perform hash lookup with precomputed hash
        HV* stash = GvSTASH(context);
        MAGIC* mg = mg_findext((SV*)context, PERL_MAGIC_ext, &c3_marker);
        if (!mg || (HV*)mg->mg_ptr != stash) {
            if (mg) sv_unmagicext((SV*)context, PERL_MAGIC_ext, &c3_marker);
            bool had_magic = SvRMAGICAL(context);
            fqnsv = _make_shared_fqn(aTHX_ context);
            mg = sv_magicext((SV*)context, fqnsv, PERL_MAGIC_ext, &c3_marker, (const char*)stash, 0);
            mg->mg_flags |= MGf_REFCOUNTED;
            if (!had_magic) SvRMAGICAL_off(context);
        }
        fqnsv = mg->mg_obj;
    }

    struct mro_meta* selfmeta = HvMROMETA(selfstash);
    HV* nmcache = selfmeta->mro_nextmethod;
    if (nmcache) { // Use the cached coderef if it exists
        HE* he = hv_fetch_ent(nmcache, fqnsv, 0, 0);
        if (he) {
            SV* const val = HeVAL(he);
            return val == &PL_sv_undef ? NULL : (CV*)val;
        }
    }
    else nmcache = selfmeta->mro_nextmethod = newHV(); //Initialize the next::method cache for this stash if necessary

    /* beyond here is just for cache misses, so perf isn't as critical */
    HV* stash = GvSTASH(context);
    char* subname = GvNAME(context);
    STRLEN subname_len = GvNAMELEN(context);
    bool subname_utf8 = GvNAMEUTF8(context);
    char* stashname = HvNAME(stash);
    STRLEN stashname_len = HvNAMELEN(stash);

    /* has ourselves at the top of the list */
    const mro_alg*const algo = Perl_mro_get_from_name(aTHX_ sv_2mortal(newSVpvs("c3")));
    AV* linear_av = algo->resolve(aTHX_ selfstash, 0);
    SV** linear_svp = AvARRAY(linear_av);
    I32 entries = AvFILLp(linear_av) + 1;

    /* Walk down our MRO, skipping everything up to the contextually enclosing class */
    while (entries--) {
        SV*const linear_sv = *linear_svp++;
        assert(linear_sv);
        if (SvCUR(linear_sv) == stashname_len && !memcmp(SvPVX(linear_sv), stashname, stashname_len)) break;
    }

    /* Now search the remainder of the MRO for the same method name as the contextually enclosing method */
    if (entries > 0) {
        while (entries--) {
            SV*const linear_sv = *linear_svp++;
            assert(linear_sv);
            HV* curstash = gv_stashsv(linear_sv, 0);

            if (!curstash) {
                if (ckWARN(WARN_SYNTAX)) Perl_warner(aTHX_
                    packWARN(WARN_SYNTAX), "Can't locate package %" SVf " for @%" HEKf "::ISA",
                    (void*)linear_sv, HEKfARG( HvNAME_HEK(selfstash) )
                );
                continue;
            }

            GV** gvp = (GV**)hv_fetch(curstash, subname, subname_utf8 ? -(I32)subname_len : (I32)subname_len, 0);
            if (!gvp) continue;

            GV* candidate = *gvp;
            assert(candidate);

            if (SvTYPE(candidate) != SVt_PVGV)
                gv_init_pvn(candidate, curstash, subname, subname_len, GV_ADDMULTI|(subname_utf8 ? SVf_UTF8 : 0));

            /* Notably, we only look for real entries, not method cache
               entries, because in C3 the method cache of a parent is not
               valid for the child */
            CV* cand_cv;
            if (SvTYPE(candidate) == SVt_PVGV && (cand_cv = GvCV(candidate)) && !GvCVGEN(candidate)) {
                SvREFCNT_inc_simple_void_NN(MUTABLE_SV(cand_cv));
                hv_store_ent(nmcache, fqnsv, MUTABLE_SV(cand_cv), 0);
                return cand_cv;
            }
        }
    }

    hv_store_ent(nmcache, fqnsv, &PL_sv_undef, 0);
    return NULL;
}

CV* next::method (pTHX_ HV* selfstash) {
    SV* fqn = NULL;
    GV* context = _find_sub(aTHX_ &fqn);
    return _method(aTHX_ selfstash, context, fqn);
}

CV* next::method_strict (pTHX_ HV* selfstash) {
    SV* fqn = NULL;
    GV* context = _find_sub(aTHX_ &fqn);
    CV* ret = _method(aTHX_ selfstash, context, fqn);
    if (!ret) _throw_no_next_method(selfstash, context);
    return ret;
}

CV* next::method (pTHX_ HV* selfstash, GV* context) { return _method(aTHX_ selfstash, context, NULL); }

CV* next::method_strict (pTHX_ HV* selfstash, GV* context) {
    CV* ret = _method(aTHX_ selfstash, context, NULL);
    if (!ret) _throw_no_next_method(selfstash, context);
    return ret;
}

static FORCEINLINE CV* _super_method (pTHX_ HV* selfstash, GV* context) {
    //omit comparing strings for speed
    if (HvMROMETA(selfstash)->mro_which->length != 3) return _method(aTHX_ selfstash, context, NULL); // C3
    // DFS
    HV* stash = GvSTASH(context);
    HEK* hek = GvNAME_HEK(context);
    HV* cache = HvMROMETA(stash)->super;
    if (cache) {
        const HE* const he = (HE*)hv_common(cache, NULL, HEK_KEY(hek), HEK_LEN(hek), HEK_UTF8(hek), 0, NULL, HEK_HASH(hek));
        if (he) {
            GV* gv = MUTABLE_GV(HeVAL(he));
            if (isGV(gv) && (!GvCVGEN(gv) || GvCVGEN(gv) == (PL_sub_generation + HvMROMETA(stash)->cache_gen))) return GvCV(gv);
        }
    }
    GV* ret = gv_fetchmethod_pvn_flags(stash, HEK_KEY(hek), HEK_LEN(hek), GV_AUTOLOAD|GV_SUPER);
    return ret ? (isGV(ret) ? GvCV(ret) : (CV*)ret) : NULL;
}

CV* super::method (pTHX_ HV* selfstash, GV* context) { return _super_method(aTHX_ selfstash, context); }

CV* super::method_strict (pTHX_ HV* selfstash, GV* context) {
    CV* ret = _super_method(aTHX_ selfstash, context);
    if (!ret) {
        std::string subname(GvNAME(context), GvNAMELEN(context));
        std::string stashname(HvNAME(selfstash), HvNAMELEN(selfstash));
        throw std::logic_error(std::string("No super::") + subname + " found for " + stashname);
    }
    return ret;
}

}
