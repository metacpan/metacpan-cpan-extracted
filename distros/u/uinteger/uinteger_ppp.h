#ifndef UINTEGER_PPP_H
#define UINTEGER_PPP_H

/* functions which should be in ppport.h */

#ifndef rpp_try_AMAGIC_1
#define rpp_try_AMAGIC_1(method, flags) \
  Perl_rpp_try_AMAGIC_1(aTHX_ method, flags)

PERL_STATIC_INLINE bool
Perl_rpp_try_AMAGIC_1(pTHX_ int method, int flags)
{
    return    UNLIKELY((SvFLAGS(*PL_stack_sp) & (SVf_ROK|SVs_GMG)))
           && Perl_try_amagic_un(aTHX_ method, flags);
}

#endif

#ifndef rpp_try_AMAGIC_2
#define rpp_try_AMAGIC_2(method, flags) \
  Perl_rpp_try_AMAGIC_2(aTHX_ method, flags)

PERL_STATIC_INLINE bool
Perl_rpp_try_AMAGIC_2(pTHX_ int method, int flags)
{
    return    UNLIKELY(((SvFLAGS(PL_stack_sp[-1])|SvFLAGS(PL_stack_sp[0]))
                     & (SVf_ROK|SVs_GMG)))
           && Perl_try_amagic_bin(aTHX_ method, flags);
}

#endif

#ifndef rpp_replace_1_1_NN
#define rpp_replace_1_1_NN(sv) Perl_rpp_replace_1_1_NN(aTHX_ sv)

PERL_STATIC_INLINE void
Perl_rpp_replace_1_1_NN(pTHX_ SV *sv)
{
    assert(sv);
    assert(*PL_stack_sp);
    *PL_stack_sp = sv;
}

#endif

#ifndef rpp_replace_2_1_COMMON
#define rpp_replace_2_1_COMMON(sv) Perl_rpp_replace_2_1_COMMON(aTHX_ sv)

PERL_STATIC_INLINE void
Perl_rpp_replace_2_1_COMMON(pTHX_ SV *sv)
{

    assert(sv);
    *--PL_stack_sp = sv;
}

#endif

#ifndef rpp_replace_2_1_NN
#define rpp_replace_2_1_NN(sv) Perl_rpp_replace_2_1_NN(aTHX_ sv)

PERL_STATIC_INLINE void
Perl_rpp_replace_2_1_NN(pTHX_ SV *sv)
{
    //PERL_ARGS_ASSERT_RPP_REPLACE_2_1_NN;

    assert(sv);
#ifdef PERL_RC_STACK
    SvREFCNT_inc_simple_void_NN(sv);
#endif
    rpp_replace_2_1_COMMON(sv);
}

#endif

#ifndef TAINT_get

#define TAINT_get (cBOOL(UNLIKELY(PL_tainted)))

#endif

#ifndef TARGu
/* set TARG to the UV value u. If do_taint is false,
 * assume that PL_tainted can never be true */
#define TARGu(u, do_taint) \
    STMT_START {                                                        \
        UV TARGu_uv = u;                                                \
        if (LIKELY(                                                     \
              ((SvFLAGS(TARG) & (SVTYPEMASK|SVf_THINKFIRST|SVf_IVisUV)) == SVt_IV) \
            & (do_taint ? !TAINT_get : 1)                               \
            & (TARGu_uv <= (UV)IV_MAX)))                                \
        {                                                               \
            /* Cheap SvIOK_only().                                      \
             * Assert that flags which SvIOK_only() would test or       \
             * clear can't be set, because we're SVt_IV */              \
            assert(!(SvFLAGS(TARG) &                                    \
                (SVf_OOK|SVf_UTF8|(SVf_OK & ~(SVf_IOK|SVp_IOK)))));     \
            SvFLAGS(TARG) |= (SVf_IOK|SVp_IOK);                         \
            /* SvIV_set() where sv_any points to head */                \
            TARG->sv_u.svu_iv = TARGu_uv;                               \
        }                                                               \
        else                                                            \
            sv_setuv_mg(targ, TARGu_uv);                                \
    } STMT_END
#endif

#endif
