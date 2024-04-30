#ifdef __cplusplus
extern "C" {
#endif

/*
**  It seems that perfection is attained
**  not when there is nothing more to add,
**  but when there is nothing more to remove.
**                -- Antoine de Saint Exupery
*/

#include "ulib/UUID.h"
#include "XSUB.h"
#include "ulib/chacha.h"
#include "ulib/clear.h"
#include "ulib/clock.h"
#include "ulib/compare.h"
#include "ulib/gen.h"
#include "ulib/isnull.h"
#include "ulib/md5.h"
#include "ulib/pack.h"
#include "ulib/parse.h"
#include "ulib/sha1.h"
#include "ulib/splitmix.h"
#include "ulib/unpack.h"
#include "ulib/unparse.h"
#include "ulib/util.h"
#include "ulib/xoshiro.h"

#ifdef __cplusplus
}
#endif

/* 2 hex digits per byte + 4 separators */
#define UUID_BUFFSZ 36


#define MY_CXT_KEY "UUID::_guts" XS_VERSION
/* my_cxt_t global typedef lives in TYPE.h */
START_MY_CXT


#ifdef USE_ITHREADS
# define UMTX_DECL   STATIC perl_mutex UU_LOCK
# define UMTX_INIT   MUTEX_INIT(&UU_LOCK)
# define UMTX_LOCK   MUTEX_LOCK(&UU_LOCK)
# define UMTX_UNLOCK MUTEX_UNLOCK(&UU_LOCK)
#else
# define UMTX_DECL   dNOOP
# define UMTX_INIT   NOOP
# define UMTX_LOCK   NOOP
# define UMTX_UNLOCK NOOP
#endif
UMTX_DECL;


#ifdef PERL_IMPLICIT_CONTEXT
# define dUCXT     dMY_CXT
# define UCXT_INIT MY_CXT_INIT
#else
# define dUCXT     my_cxt_t *my_cxtp = &my_cxt;
# define UCXT_INIT my_cxt_t *my_cxtp = &my_cxt;
#endif

#define UU_GEN_TMPL(ver, out, su, dptr)   \
    SV_CHECK_THINKFIRST_COW_DROP(out);    \
    if (isGV_with_GP(out))                \
        croak("%s", PL_no_modify);        \
    SvUPGRADE(out, SVt_PV);               \
    UMTX_LOCK;                            \
    uu_v ## ver ## gen(aUCXT, &su, dptr); \
    UMTX_UNLOCK;                          \
    dptr = SvGROW(out, sizeof(uu_t)+1);   \
    uu_pack##ver(&su, (U8*)dptr);         \
    dptr[sizeof(uu_t)] = '\0';            \
    SvCUR_set(out, sizeof(uu_t));         \
    (void)SvPOK_only(out);                \
    if (SvTYPE(out) == SVt_PVCV)          \
        CvAUTOLOAD_off(out);

#define UU_ALIAS_GEN_V0(out, su, dptr) UU_GEN_TMPL(0, out, su, dptr)
#define UU_ALIAS_GEN_V1(out, su, dptr) UU_GEN_TMPL(1, out, su, dptr)
#define UU_ALIAS_GEN_V3(out, su, dptr) UU_GEN_TMPL(3, out, su, dptr)
#define UU_ALIAS_GEN_V4(out, su, dptr) UU_GEN_TMPL(4, out, su, dptr)
#define UU_ALIAS_GEN_V5(out, su, dptr) UU_GEN_TMPL(5, out, su, dptr)
#define UU_ALIAS_GEN_V6(out, su, dptr) UU_GEN_TMPL(6, out, su, dptr)
#define UU_ALIAS_GEN_V7(out, su, dptr) UU_GEN_TMPL(7, out, su, dptr)


#define UU_UNPARSE_TMPL(case, in, out, su, dptr) \
    if (SvPOK(in)) {                             \
        dptr = SvGROW(in, sizeof(uu_t));         \
        uu_unpack((unsigned char*)dptr, &su);    \
        SV_CHECK_THINKFIRST_COW_DROP(out);       \
        if (isGV_with_GP(out))                   \
            croak("%s", PL_no_modify);           \
        SvUPGRADE(out, SVt_PV);                  \
        SvPOK_only(out);                         \
        dptr = SvGROW(out, UUID_BUFFSZ+1);       \
        uu_unparse_ ## case ## er1(&su, dptr);   \
        dptr[UUID_BUFFSZ] = '\0';                \
        SvCUR_set(out, UUID_BUFFSZ);             \
        (void)SvPOK_only(out);                   \
        if (SvTYPE(out) == SVt_PVCV)             \
            CvAUTOLOAD_off(out);                 \
    }

#define UU_ALIAS_UNPARSE_LOWER(in, out, su, dptr) UU_UNPARSE_TMPL(low, in, out, su, dptr)
#define UU_ALIAS_UNPARSE_UPPER(in, out, su, dptr) UU_UNPARSE_TMPL(upp, in, out, su, dptr)


#define UU_UUID_TMPL(ver, su, dptr)       \
    UMTX_LOCK;                            \
    uu_v ## ver ## gen(aUCXT, &su, dptr); \
    UMTX_UNLOCK;                          \
    RETVAL = newSV(UUID_BUFFSZ+1);        \
    dptr = SvPVX(RETVAL);                 \
    uu_unparse##ver(&su, dptr);           \
    dptr[UUID_BUFFSZ] = '\0';             \
    SvCUR_set(RETVAL, UUID_BUFFSZ);       \
    SvPOK_only(RETVAL);

#define UU_ALIAS_UUID0(su, dptr) UU_UUID_TMPL(0, su, dptr)
#define UU_ALIAS_UUID1(su, dptr) UU_UUID_TMPL(1, su, dptr)
#define UU_ALIAS_UUID3(su, dptr) UU_UUID_TMPL(3, su, dptr)
#define UU_ALIAS_UUID4(su, dptr) UU_UUID_TMPL(4, su, dptr)
#define UU_ALIAS_UUID5(su, dptr) UU_UUID_TMPL(5, su, dptr)
#define UU_ALIAS_UUID6(su, dptr) UU_UUID_TMPL(6, su, dptr)
#define UU_ALIAS_UUID7(su, dptr) UU_UUID_TMPL(7, su, dptr)


#define UU_ALIAS_VERSION(in, su, str, len)       \
    RETVAL = -1;                                 \
    if (SvPOK(in)) {                             \
        str = SvPV(in, len);                     \
        if (len == sizeof(uu_t)) {               \
            uu_unpack((unsigned char*)str, &su); \
            RETVAL = uu_type(&su);               \
        }                                        \
    }

const struct_uu_t UU_namespace_dns  = { 0x6ba7b810, 0x9dad, 0x11d1, 0x80b4, {0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8}};
const struct_uu_t UU_namespace_url  = { 0x6ba7b811, 0x9dad, 0x11d1, 0x80b4, {0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8}};
const struct_uu_t UU_namespace_oid  = { 0x6ba7b812, 0x9dad, 0x11d1, 0x80b4, {0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8}};
const struct_uu_t UU_namespace_x500 = { 0x6ba7b814, 0x9dad, 0x11d1, 0x80b4, {0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8}};


MODULE = UUID		PACKAGE = UUID


BOOT:
    UMTX_INIT;
    UMTX_LOCK;
    {
        UCXT_INIT;
        SV **svp;

        UCXT.thread_id = 0;

        svp = hv_fetchs(PL_modglobal, "Time::NVtime", 0);
        if (!svp)         croak("Time::HiRes is required");
        if (!SvIOK(*svp)) croak("Time::NVtime isn't a function pointer");
        UCXT.myNVtime = INT2PTR(NV(*)(), SvIV(*svp));
        /* test
        {
            (*UCXT.myNVtime)(aTHX);
            printf("The current time is: %" NVff "\n", (*MY_CXT.myNVtime)());
        }
        */

        svp = hv_fetchs(PL_modglobal, "Time::U2time", 0);
        if (!svp)         croak("Time::HiRes is required");
        if (!SvIOK(*svp)) croak("Time::U2time isn't a function pointer");
        UCXT.myU2time = INT2PTR(void(*)(pTHX_ UV ret[2]), SvIV(*svp));
        /* test
        {
            UV  xx[2];
            (*UCXT.myU2time)(aTHX_ (UV*)&xx);
            printf("The current seconds are: %u.%06u\n", xx[0], xx[1]);
        }
        */

        sm_srand(aUCXT); /* in    */
        xo_srand(aUCXT); /* this  */
        cc_srand(aUCXT); /* order */

        uu_clock_init(aUCXT); /* after srand */

        uu_gen_init(aUCXT); /* after srand */
    }
    UMTX_UNLOCK;


void
_hide_always()
    PROTOTYPE:
    PREINIT:
        dUCXT;
    PPCODE:
        UMTX_LOCK;
        uu_gen_setuniq(aUCXT);
        UMTX_UNLOCK;

void
_hide_mac()
    PROTOTYPE:
    PREINIT:
        dUCXT;
    PPCODE:
        UMTX_LOCK;
        uu_gen_setrand(aUCXT);
        UMTX_UNLOCK;

SV *
_persist(...)
    PROTOTYPE: @
    PREINIT:
        dUCXT;
    INIT:
        struct_pathlen_t    sp;
        char                *ptr;
        SV                  *sv;
    CODE:
        if (items > 1)
            croak("Usage: _persist([path/to/file])");
        if (items == 0) {
            UMTX_LOCK;
            uu_clock_getpath(aUCXT, &sp);
            UMTX_UNLOCK;
            RETVAL = newSVpvn(sp.path, sp.len);
        }
        else { /* items == 1 */
            if (SvTRUE(ST(0))) {
                sv = ST(0);
                ptr = SvPV(sv, sp.len);
                Newz(0, sp.path, sp.len+1, char);
                Copy(ptr, sp.path, sp.len, char);
                UMTX_LOCK;
                uu_clock_setpath(aUCXT, &sp);
                UMTX_UNLOCK;
            }
            else {
                sp.path = NULL;
                sp.len  = 0;
                UMTX_LOCK;
                uu_clock_setpath(aUCXT, &sp);
                UMTX_UNLOCK;
            }
            RETVAL = &PL_sv_yes;
        }
    OUTPUT:
        RETVAL

SV *
_realnode()
    PROTOTYPE:
    PREINIT:
        dUCXT;
    INIT:
        int             rv;
        char            *dptr;
        struct_uu_t     su;
    CODE:
        UMTX_LOCK;
        rv = uu_realnode(aUCXT, &su);
        UMTX_UNLOCK;
        if (rv) {
            RETVAL = newSV(UUID_BUFFSZ+1);
            dptr = SvPVX(RETVAL);
            uu_unparse0(&su, dptr);
            dptr[UUID_BUFFSZ] = '\0';
            SvCUR_set(RETVAL, UUID_BUFFSZ);
            SvPOK_only(RETVAL);
        }
        else
            RETVAL = &PL_sv_no;
    OUTPUT:
        RETVAL

SV *
_defer(...)
    PROTOTYPE: @
    PREINIT:
        dUCXT;
    INIT:
        SV *duration;
    CODE:
        if (items == 0) {
            RETVAL = newSVnv(UCXT.clock_defer_100ns / 10000000.0);
        }
        else if (items == 1) {
            duration = ST(0);
            if (!looks_like_number(duration))
                croak_caller("Non-numeric :defer argument");
            UMTX_LOCK;
            UCXT.clock_defer_100ns = (U64)(SvNV(duration) * 10000000.0);
            UMTX_UNLOCK;
            RETVAL = &PL_sv_yes;
        }
        else
            croak("Too many arguments for _defer()");
    OUTPUT:
        RETVAL

void
clear(io)
    SV * io
    PROTOTYPE: $
    PREINIT:
        dUCXT;
    INIT:
        struct_uu_t     su;
        char            *dptr = NULL;
    CODE:
        UU_ALIAS_GEN_V0(io, su, dptr);

IV
compare(in1, in2)
    SV * in1
    SV * in2
    PROTOTYPE: $$
    PREINIT:
        dUCXT;
    INIT:
        STRLEN  len1, len2;
    CODE:
        if (SvPOK(in1) && SvPOK(in2)
            && SvCUR(in1) == sizeof(uu_t)
            && SvCUR(in2) == sizeof(uu_t))
            RETVAL = uu_cmp_binary(
                (U8*)SvPV_force(in1, len1),
                (U8*)SvPV_force(in2, len2)
            );
        else if (!SvOK(in1))
            RETVAL = SvOK(in2) ? -1 : 0;
        else if (!SvOK(in2))
            RETVAL = 1;
        else
            RETVAL = sv_cmp(in1, in2);
    OUTPUT:
        RETVAL

void
copy(out, in)
    SV * out
    SV * in
    PROTOTYPE: $$
    PREINIT:
        dUCXT;
    INIT:
        struct_uu_t     su;
        STRLEN          len;
        char            *dptr;
    CODE:
        if (!SvPOK(in) || SvCUR(in) != sizeof(uu_t))
            uu_clear(&su);
        else
            uu_unpack((U8*)SvPV_force(in, len), &su);
        SV_CHECK_THINKFIRST_COW_DROP(out);
        if (isGV_with_GP(out))
            croak("%s", PL_no_modify);
        SvUPGRADE(out, SVt_PV);
        dptr = SvGROW(out, sizeof(uu_t)+1);
        uu_pack1(&su, (U8*)dptr);
        dptr[sizeof(uu_t)] = '\0';
        SvCUR_set(out, sizeof(uu_t));
        (void)SvPOK_only(out);
        if (SvTYPE(out) == SVt_PVCV)
            CvAUTOLOAD_off(out);

void
generate(out)
    SV * out
    PROTOTYPE: $
    PREINIT:
        dUCXT;
    INIT:
        char            *dptr = NULL;
        struct_uu_t     su;
    CODE:
        UU_ALIAS_GEN_V4(out, su, dptr);

void
generate_random(out)
    SV * out
    PROTOTYPE: $
    PREINIT:
        dUCXT;
    INIT:
        char            *dptr = NULL;
        struct_uu_t     su;
    CODE:
        UU_ALIAS_GEN_V4(out, su, dptr);

void
generate_time(out)
    SV * out
    PROTOTYPE: $
    PREINIT:
        dUCXT;
    INIT:
        char            *dptr = NULL;
        struct_uu_t     su;
    CODE:
        UU_ALIAS_GEN_V1(out, su, dptr);

void
generate_v0(out)
    SV * out
    PROTOTYPE: $
    PREINIT:
        dUCXT;
    INIT:
        char            *dptr = NULL;
        struct_uu_t     su;
    CODE:
        UU_ALIAS_GEN_V0(out, su, dptr);

void
generate_v1(out)
    SV * out
    PROTOTYPE: $
    PREINIT:
        dUCXT;
    INIT:
        char            *dptr = NULL;
        struct_uu_t     su;
    CODE:
        UU_ALIAS_GEN_V1(out, su, dptr);

void
generate_v3(out, namespace, name)
    SV * out
    SV * namespace
    SV * name
    PROTOTYPE: $$$
    PREINIT:
        dUCXT;
    INIT:
        char            *dptr, *sptr;
        STRLEN          dlen, slen;
        struct_uu_t     su;
    CODE:
        SvUPGRADE(namespace, SVt_PV);
        SvUPGRADE(name,      SVt_PV);
        sptr = SvPV(namespace, slen);
        dptr = SvPV(name,      dlen);

        if (slen == 36 && !uu_parse(sptr, &su)) {
            /* uuid string */
            UU_ALIAS_GEN_V3(out, su, dptr);
        }
        else if (slen == 16) {
            /* assume binary uuid */
            uu_unpack((unsigned char*)sptr, &su);
            UU_ALIAS_GEN_V3(out, su, dptr);
        }
        else if (slen > 0 /* ibcmp first appears in v5.7.3 */
            && ( slen == 3 && !ibcmp(sptr, "dns",  (I32)slen) && CopyD(&UU_namespace_dns,  &su, 1, struct_uu_t)
              || slen == 3 && !ibcmp(sptr, "url",  (I32)slen) && CopyD(&UU_namespace_url,  &su, 1, struct_uu_t)
              || slen == 3 && !ibcmp(sptr, "oid",  (I32)slen) && CopyD(&UU_namespace_oid,  &su, 1, struct_uu_t)
              || slen == 4 && !ibcmp(sptr, "x500", (I32)slen) && CopyD(&UU_namespace_x500, &su, 1, struct_uu_t)
            )
        ) {
            UU_ALIAS_GEN_V3(out, su, dptr);
        }

void
generate_v4(out)
    SV * out
    PROTOTYPE: $
    PREINIT:
        dUCXT;
    INIT:
        char            *dptr = NULL;
        struct_uu_t     su;
    CODE:
        UU_ALIAS_GEN_V4(out, su, dptr);

void
generate_v5(out, namespace, name)
    SV * out
    SV * namespace
    SV * name
    PROTOTYPE: $$$
    PREINIT:
        dUCXT;
    INIT:
        char            *dptr, *sptr;
        STRLEN          dlen, slen;
        struct_uu_t     su;
    CODE:
        SvUPGRADE(namespace, SVt_PV);
        SvUPGRADE(name,      SVt_PV);
        sptr = SvPV(namespace, slen);
        dptr = SvPV(name,      dlen);

        if (slen == 36 && !uu_parse(sptr, &su)) {
            /* uuid string */
            UU_ALIAS_GEN_V5(out, su, dptr);
        }
        else if (slen == 16) {
            /* assume binary uuid */
            uu_unpack((unsigned char*)sptr, &su);
            UU_ALIAS_GEN_V5(out, su, dptr);
        }
        else if (slen > 0 /* ibcmp first appears in v5.7.3 */
            && ( slen == 3 && !ibcmp(sptr, "dns",  (I32)slen) && CopyD(&UU_namespace_dns,  &su, 1, struct_uu_t)
              || slen == 3 && !ibcmp(sptr, "url",  (I32)slen) && CopyD(&UU_namespace_url,  &su, 1, struct_uu_t)
              || slen == 3 && !ibcmp(sptr, "oid",  (I32)slen) && CopyD(&UU_namespace_oid,  &su, 1, struct_uu_t)
              || slen == 4 && !ibcmp(sptr, "x500", (I32)slen) && CopyD(&UU_namespace_x500, &su, 1, struct_uu_t)
            )
        ) {
            UU_ALIAS_GEN_V5(out, su, dptr);
        }

void
generate_v6(out)
    SV * out
    PROTOTYPE: $
    PREINIT:
        dUCXT;
    INIT:
        char            *dptr = NULL;
        struct_uu_t     su;
    CODE:
        UU_ALIAS_GEN_V6(out, su, dptr);

void
generate_v7(out)
    SV * out
    PROTOTYPE: $
    PREINIT:
        dUCXT;
    INIT:
        char            *dptr = NULL;
        struct_uu_t     su;
    CODE:
        UU_ALIAS_GEN_V7(out, su, dptr);

IV
is_null(in)
    SV * in
    PROTOTYPE: $
    PREINIT:
        dUCXT;
    INIT:
        STRLEN  len;
    CODE:
        if (!SvPOK(in))
            RETVAL = 0;
        else if (SvCUR(in) != sizeof(uu_t))
            RETVAL = 0;
        else
            RETVAL = uu_isnull_binary((U8*)SvPV(in, len));
    OUTPUT:
        RETVAL

IV
parse(in, out)
    SV * in
    SV * out
    PROTOTYPE: $$
    PREINIT:
        dUCXT;
    INIT:
        char            *dptr;
        struct_uu_t     su;
    CODE:
        /* XXX might see uninitialized data */
        RETVAL = -1;
        if (SvPOK(in) && !uu_parse(SvGROW(in, UUID_BUFFSZ+1), &su)) {
            SV_CHECK_THINKFIRST_COW_DROP(out);
            if (isGV_with_GP(out))
                croak("%s", PL_no_modify);
            SvUPGRADE(out, SVt_PV);
            dptr = SvGROW(out, sizeof(uu_t)+1);
            uu_pack1(&su, (U8*)dptr);
            dptr[sizeof(uu_t)] = '\0';
            SvCUR_set(out, sizeof(uu_t));
            (void)SvPOK_only(out);
            if (SvTYPE(out) == SVt_PVCV)
                CvAUTOLOAD_off(out);
            RETVAL = 0;
        }
    OUTPUT:
    RETVAL

NV
time(in)
    SV * in
    PROTOTYPE: $
    PREINIT:
        dUCXT;
    INIT:
        struct_uu_t     su;
        char            *str;
        STRLEN          len;
    CODE:
        RETVAL = 0;
        if (SvPOK(in)) {
            str = SvPV(in, len);
            if (len == sizeof(uu_t)) {
                uu_unpack((U8*)str, &su);
                RETVAL = uu_time(&su);
            }
        }
    OUTPUT:
        RETVAL

IV
type(in)
    SV * in
    PROTOTYPE: $
    PREINIT:
        dUCXT;
    INIT:
        struct_uu_t     su;
        char            *str;
        STRLEN          len;
    CODE:
        UU_ALIAS_VERSION(in, su, str, len);
    OUTPUT:
        RETVAL

void
unparse(in, out)
    SV * in
    SV * out
    PROTOTYPE: $$
    PREINIT:
        dUCXT;
    INIT:
        struct_uu_t     su;
        char            *dptr = NULL;
    CODE:
        UU_ALIAS_UNPARSE_LOWER(in, out, su, dptr);

void
unparse_lower(in, out)
    SV * in
    SV * out
    PROTOTYPE: $$
    PREINIT:
        dUCXT;
    INIT:
        struct_uu_t     su;
        char            *dptr = NULL;
    CODE:
        UU_ALIAS_UNPARSE_LOWER(in, out, su, dptr);

void
unparse_upper(in, out)
    SV * in
    SV * out
    PROTOTYPE: $$
    PREINIT:
        dUCXT;
    INIT:
        struct_uu_t     su;
        char            *dptr = NULL;
    CODE:
        UU_ALIAS_UNPARSE_UPPER(in, out, su, dptr);

SV *
uuid()
    PROTOTYPE:
    PREINIT:
        dUCXT;
    INIT:
        char            *dptr = NULL;
        struct_uu_t     su;
    CODE:
        UU_ALIAS_UUID4(su, dptr);
    OUTPUT:
        RETVAL

SV *
uuid0()
    PROTOTYPE:
    PREINIT:
        dUCXT;
    INIT:
        char            *dptr = NULL;
        struct_uu_t     su;
    CODE:
        UU_ALIAS_UUID0(su, dptr);
    OUTPUT:
        RETVAL

SV *
uuid1()
    PROTOTYPE:
    PREINIT:
        dUCXT;
    INIT:
        char            *dptr = NULL;
        struct_uu_t     su;
    CODE:
        UU_ALIAS_UUID1(su, dptr);
    OUTPUT:
        RETVAL

SV *
uuid3(namespace, name)
    SV * namespace
    SV * name
    PROTOTYPE: $$
    PREINIT:
        dUCXT;
    INIT:
        char            *dptr, *sptr;
        STRLEN          dlen, slen;
        struct_uu_t     su;
    CODE:
        SvUPGRADE(namespace, SVt_PV);
        SvUPGRADE(name,      SVt_PV);
        sptr = SvPV(namespace, slen);
        dptr = SvPV(name,      dlen);

        if (slen == 36 && !uu_parse(sptr, &su)) {
            /* uuid string */
            UU_ALIAS_UUID3(su, dptr);
        }
        else if (slen == 16) {
            /* assume binary uuid */
            uu_unpack((unsigned char*)sptr, &su);
            UU_ALIAS_UUID3(su, dptr);
        }
        else if (slen > 0 /* ibcmp first appears in v5.7.3 */
            && ( slen == 3 && !ibcmp(sptr, "dns",  (I32)slen) && CopyD(&UU_namespace_dns,  &su, 1, struct_uu_t)
              || slen == 3 && !ibcmp(sptr, "url",  (I32)slen) && CopyD(&UU_namespace_url,  &su, 1, struct_uu_t)
              || slen == 3 && !ibcmp(sptr, "oid",  (I32)slen) && CopyD(&UU_namespace_oid,  &su, 1, struct_uu_t)
              || slen == 4 && !ibcmp(sptr, "x500", (I32)slen) && CopyD(&UU_namespace_x500, &su, 1, struct_uu_t)
            )
        ) {
            UU_ALIAS_UUID3(su, dptr);
        }
    OUTPUT:
        RETVAL

SV *
uuid4()
    PROTOTYPE:
    PREINIT:
        dUCXT;
    INIT:
        char            *dptr = NULL;
        struct_uu_t     su;
    CODE:
        UU_ALIAS_UUID4(su, dptr);
    OUTPUT:
        RETVAL

SV *
uuid5(namespace, name)
    SV * namespace
    SV * name
    PROTOTYPE: $$
    PREINIT:
        dUCXT;
    INIT:
        char            *dptr, *sptr;
        STRLEN          dlen, slen;
        struct_uu_t     su;
    CODE:
        SvUPGRADE(namespace, SVt_PV);
        SvUPGRADE(name,      SVt_PV);
        sptr = SvPV(namespace, slen);
        dptr = SvPV(name,      dlen);

        if (slen == 36 && !uu_parse(sptr, &su)) {
            /* uuid string */
            UU_ALIAS_UUID5(su, dptr);
        }
        else if (slen == 16) {
            /* assume binary uuid */
            uu_unpack((unsigned char*)sptr, &su);
            UU_ALIAS_UUID5(su, dptr);
        }
        else if (slen > 0 /* ibcmp first appears in v5.7.3 */
            && ( slen == 3 && !ibcmp(sptr, "dns",  (I32)slen) && CopyD(&UU_namespace_dns,  &su, 1, struct_uu_t)
              || slen == 3 && !ibcmp(sptr, "url",  (I32)slen) && CopyD(&UU_namespace_url,  &su, 1, struct_uu_t)
              || slen == 3 && !ibcmp(sptr, "oid",  (I32)slen) && CopyD(&UU_namespace_oid,  &su, 1, struct_uu_t)
              || slen == 4 && !ibcmp(sptr, "x500", (I32)slen) && CopyD(&UU_namespace_x500, &su, 1, struct_uu_t)
            )
        ) {
            UU_ALIAS_UUID5(su, dptr);
        }
    OUTPUT:
        RETVAL

SV *
uuid6()
    PROTOTYPE:
    PREINIT:
        dUCXT;
    INIT:
        char            *dptr = NULL;
        struct_uu_t     su;
    CODE:
        UU_ALIAS_UUID6(su, dptr);
    OUTPUT:
        RETVAL

SV *
uuid7()
    PROTOTYPE:
    PREINIT:
        dUCXT;
    INIT:
        char            *dptr = NULL;
        struct_uu_t     su;
    CODE:
        UU_ALIAS_UUID7(su, dptr);
    OUTPUT:
        RETVAL

UV
variant(in)
    SV * in
    PROTOTYPE: $
    PREINIT:
        dUCXT;
    INIT:
        struct_uu_t     su;
        char            *str;
        STRLEN          len;
    CODE:
        RETVAL = 0;
        if (SvPOK(in)) {
            str = SvPV(in, len);
            if (len == sizeof(uu_t)) {
                uu_unpack((unsigned char*)str, &su);
                RETVAL = uu_variant(&su);
            }
        }
    OUTPUT:
        RETVAL

IV
version(in)
    SV * in
    PROTOTYPE: $
    PREINIT:
        dUCXT;
    INIT:
        struct_uu_t     su;
        char            *str;
        STRLEN          len;
    CODE:
        UU_ALIAS_VERSION(in, su, str, len);
    OUTPUT:
        RETVAL

#ifdef WE_DONT_NEED_NO_STINKIN_BADGES
 #
 # CLONE'ing.
 #   It has been deemed appropriate to maintain the
 #   default behavior, which is to share the initial
 #   context between all threads.
 #
 #   Without sharing the context, each thread becomes an
 #   independent generator and would need some other
 #   (shared) method to keep it from trampling on the
 #   others.
 #
#if defined(USE_ITHREADS) && defined(MY_CXT_KEY)

void
CLONE(...)
    CODE:
        MY_CXT_CLONE;
        ++UCXT.thread_id;

#endif
#endif

