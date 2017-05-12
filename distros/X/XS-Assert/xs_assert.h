/*
    xs_assert.h - Provides assertion macros for XS

    This header file is a part of the XS::Assert distribution.
*/

#ifndef P5_XS_ASSERT_H
#define P5_XS_ASSERT_H

#if defined(XS_ASSERT) || defined(DEBUGGING)

#undef  assert
#define assert(expr) ((expr) ? (void)0 : croak("XS::Assert %s failed (%s:%d)", #expr, __FILE__, __LINE__))

#define sv_dump_to_stderr(sv)  STMT_START{                    \
        dTHX;                                                 \
        assert_not_null(sv);                                  \
        if(SvROK((sv))){                                      \
            do_sv_dump(0, PerlIO_stderr(), (sv), 0, 4, 0, 0); \
        }                                                     \
        else {                                                \
            do_sv_dump(0, PerlIO_stderr(), (sv), 0, 0, 0, 0); \
        }                                                     \
    } STMT_END


#define assert_sv_type_is(_sv, _t) STMT_START{    \
        assert_not_null(_sv);                     \
        if(!(SvTYPE(_sv) == (_t))){               \
            sv_dump_to_stderr(_sv);               \
            assert(SvTYPE(_sv) == (_t));          \
        }                                         \
    } STMT_END


#define assert_sv_xok(_sv, _ok_macro) STMT_START{   \
            assert_not_null(_sv);                   \
            if(!_ok_macro(_sv)){                    \
                sv_dump_to_stderr(_sv);             \
                assert(_ok_macro(_sv));             \
            }                                       \
    } STMT_END

#else /* !(defined(XS_ASSERT) || defined(DEBUGGING)) */

#define assert_not_null(_expr)        NOOP
#define assert_sv_type_is(_sv, _t)    STMT_START{ NOOP; } STMT_END
#define assert_sv_xok(_sv, _ok_macro) STMT_START{ NOOP; } STMT_END


#endif /* defined(XS_ASSERT) || defined(DEBUGGING) */

#define assert_not_null(sv) assert(sv != NULL)

#define assert_sv_is_av(sv) assert_sv_type_is(sv, SVt_PVAV)
#define assert_sv_is_hv(sv) assert_sv_type_is(sv, SVt_PVHV)
#define assert_sv_is_cv(sv) assert_sv_type_is(sv, SVt_PVCV)
#define assert_sv_is_gv(sv) assert_sv_type_is(sv, SVt_PVGV)

#define assert_sv_ok(sv)    assert_sv_xok(sv, SvOK)
#define assert_sv_pok(sv)   assert_sv_xok(sv, SvPOKp)
#define assert_sv_iok(sv)   assert_sv_xok(sv, SvIOKp)
#define assert_sv_nok(sv)   assert_sv_xok(sv, SvNOKp)
#define assert_sv_rok(sv)   assert_sv_xok(sv, SvROK)

#define assert_sv_is_xref(sv, t) STMT_START{ assert_sv_rok(sv); assert_sv_type_is(SvRV(sv), (t)); } STMT_END
#define assert_sv_is_avref(sv)  assert_sv_is_xref(sv, SVt_PVAV)
#define assert_sv_is_hvref(sv)  assert_sv_is_xref(sv, SVt_PVHV)
#define assert_sv_is_cvref(sv)  assert_sv_is_xref(sv, SVt_PVCV)
#define assert_sv_is_gvref(sv)  assert_sv_is_xref(sv, SVt_PVGV)
#define assert_sv_is_object(sv) STMT_START{ assert_sv_rok(sv); assert_sv_xok(SvRV(sv), SvOBJECT); } STMT_END


#endif /* !P5_XS_ASSERT_H */
