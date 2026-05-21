#ifdef __cplusplus
extern "C" {
#endif

/*
**  It seems that perfection is attained
**  not when there is nothing more to add,
**  but when there is nothing more to remove.
**                -- Antoine de Saint Exupery
*/

#define NO_XSLOCKS
#include "ulib/UUID.h"
#include "XSUB.h"
#include "ulib/chacha.h"
#include "ulib/clock.h"
#include "ulib/compare.h"
#include "ulib/gen.h"
#include "ulib/gettime.h"
#include "ulib/hash.h"
#include "ulib/pack.h"
#include "ulib/parse.h"
#include "ulib/splitmix.h"
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
    UMTX_LOCK {                           \
    uu_gen_v##ver(aUCXT, &su, dptr);      \
    } UMTX_UNLOCK                         \
    dptr = SvGROW(out, sizeof(uu_t)+1);   \
    uu_pack_v##ver(&su, (U8*)dptr);       \
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


#define UU_UNPARSE_TMPL(case, in, out, su, dptr)  \
    if (SvPOK(in)) {                               \
        dptr = SvGROW(in, sizeof(uu_t));            \
        uu_pack_unpack((unsigned char*)dptr, &su);   \
        SV_CHECK_THINKFIRST_COW_DROP(out);            \
        if (isGV_with_GP(out))                        \
            croak("%s", PL_no_modify);                \
        SvUPGRADE(out, SVt_PV);                       \
        SvPOK_only(out);                              \
        dptr = SvGROW(out, UUID_BUFFSZ+1);            \
        uu_parse_unparse_ ## case ## er1(&su, dptr);  \
        dptr[UUID_BUFFSZ] = '\0';                     \
        SvCUR_set(out, UUID_BUFFSZ);                 \
        (void)SvPOK_only(out);                      \
        if (SvTYPE(out) == SVt_PVCV)               \
            CvAUTOLOAD_off(out);                  \
    }

#define UU_ALIAS_UNPARSE_LOWER(in, out, su, dptr) UU_UNPARSE_TMPL(low, in, out, su, dptr)
#define UU_ALIAS_UNPARSE_UPPER(in, out, su, dptr) UU_UNPARSE_TMPL(upp, in, out, su, dptr)


#define UU_UUID_TMPL(ver, su, dptr)  \
    UMTX_LOCK {                       \
    uu_gen_v##ver(aUCXT, &su, dptr);   \
    } UMTX_UNLOCK                       \
    RETVAL = newSV(UUID_BUFFSZ+1);       \
    dptr = SvPVX(RETVAL);                \
    uu_parse_unparse_v##ver(&su, dptr);  \
    dptr[UUID_BUFFSZ] = '\0';            \
    SvCUR_set(RETVAL, UUID_BUFFSZ);     \
    SvPOK_only(RETVAL);

#define UU_ALIAS_UUID0(su, dptr) UU_UUID_TMPL(0, su, dptr)
#define UU_ALIAS_UUID1(su, dptr) UU_UUID_TMPL(1, su, dptr)
#define UU_ALIAS_UUID3(su, dptr) UU_UUID_TMPL(3, su, dptr)
#define UU_ALIAS_UUID4(su, dptr) UU_UUID_TMPL(4, su, dptr)
#define UU_ALIAS_UUID5(su, dptr) UU_UUID_TMPL(5, su, dptr)
#define UU_ALIAS_UUID6(su, dptr) UU_UUID_TMPL(6, su, dptr)
#define UU_ALIAS_UUID7(su, dptr) UU_UUID_TMPL(7, su, dptr)


#define UU_ALIAS_VERSION(in, su, str, len)       \
    RETVAL = -1;                                  \
    if (SvPOK(in)) {                               \
        str = SvPV(in, len);                        \
        if (len == sizeof(uu_t)) {                   \
            uu_pack_unpack((unsigned char*)str, &su); \
            RETVAL = uu_type(&su);                    \
        }                                            \
    }

const struct_uu_t UU_namespace_dns  = {{ 0x6ba7b810, 0x9dad, 0x11d1, 0x80b4, {0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8}}};
const struct_uu_t UU_namespace_url  = {{ 0x6ba7b811, 0x9dad, 0x11d1, 0x80b4, {0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8}}};
const struct_uu_t UU_namespace_oid  = {{ 0x6ba7b812, 0x9dad, 0x11d1, 0x80b4, {0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8}}};
const struct_uu_t UU_namespace_x500 = {{ 0x6ba7b814, 0x9dad, 0x11d1, 0x80b4, {0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8}}};

static void smem_init(pUCXT) {
#if defined(USE_WIN32_NATIVE) || defined(USE_WIN32_ALIEN)
    IV size = sizeof(shared_mem_t);
    SMEM = VirtualAlloc(NULL, size, MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE);
    if (!SMEM) croak("VirtualAlloc: %li\n", GetLastError());
    UCXT.shared_len = size;
#else
    IV pagesz = sysconf(_SC_PAGESIZE);
    IV npages = sizeof(shared_mem_t) / pagesz;
    if (sizeof(shared_mem_t) % pagesz) ++npages;
    IV nbytes = npages * pagesz;
    SMEM = (shared_mem_t*)mmap(NULL, nbytes, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
    if (SMEM == MAP_FAILED) croak("mmap: %s\n", strerror((IV)SMEM));
    UCXT.shared_len = nbytes;
#endif
}


MODULE = UUID		PACKAGE = UUID


BOOT:
    UCXT_INIT;
    smem_init(aUCXT);
    UMTX_INIT;
    UMTX_LOCK {

    /* order important */
    uu_gettime_init(aUCXT);
    uu_clock_init(aUCXT);
    uu_chacha_srand(aUCXT);  /* must be before gen_init, but after clock_init */
    uu_gen_init(aUCXT);

    uu_chacha_rand16(aUCXT, &SMEM->clock_seq);

    } UMTX_UNLOCK


void
_hide_always()
    PROTOTYPE:
    PREINIT:
        dUCXT;
    PPCODE:
        UMTX_LOCK {
        uu_gen_setuniq(aUCXT);
        } UMTX_UNLOCK

void
_hide_mac()
    PROTOTYPE:
    PREINIT:
        dUCXT;
    PPCODE:
        UMTX_LOCK {
        uu_gen_setrand(aUCXT);
        } UMTX_UNLOCK

SV *
_persist(...)
    PROTOTYPE: @
    PREINIT:
        dUCXT;
    INIT:
        char                *ptr;
        SV                  *sv;
        persist_t           persist;
    CODE:
        if (items > 1)
            croak("Usage: _persist([path/to/file])");
        if (items == 0) {
            UMTX_LOCK {
            uu_clock_getpath(aUCXT, &persist);
            } UMTX_UNLOCK
            if (persist.len)
                RETVAL = newSVpvn((char*)persist.path, persist.len);
            else
                RETVAL = newSV(0);
        }
        else { /* items == 1 */
            Zero(&persist, 1, persist_t);
            if (SvTRUE(ST(0))) {
                sv = ST(0);
                ptr = SvPV(sv, persist.len);

                if (persist.len > MAX_PERSIST_LEN)
                    croak("Persist path too long. (max %" UVuf ")", (UV)MAX_PERSIST_LEN);  /* XXX croak() or croak_caller() ? */

                /* includes null */
                Copy(ptr, persist.path, persist.len+1, UCHAR);

                UMTX_LOCK {
                uu_clock_setpath(aUCXT, &persist);
                } UMTX_UNLOCK
            }
            else {
                UMTX_LOCK {
                uu_clock_setpath(aUCXT, &persist);
                } UMTX_UNLOCK
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
        UMTX_LOCK {
        rv = uu_gen_realnode(aUCXT, &su);
        } UMTX_UNLOCK
        if (rv) {
            RETVAL = newSV(UUID_BUFFSZ+1);
            dptr = SvPVX(RETVAL);
            uu_parse_unparse_v0(&su, dptr);
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
            RETVAL = newSVnv(SMEM->clock_defer_100ns / 10000000.0);
        }
        else if (items == 1) {
            duration = ST(0);
            if (!looks_like_number(duration))
                croak_caller("Non-numeric :defer argument");
            UMTX_LOCK {
            SMEM->clock_defer_100ns = (U64)(SvNV(duration) * 10000000.0);
            } UMTX_UNLOCK
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
        (void)my_cxtp; /* silence warning */
        if (SvPOK(in1) && SvPOK(in2)
            && SvCUR(in1) == sizeof(uu_t)
            && SvCUR(in2) == sizeof(uu_t))
            RETVAL = uu_compare_binary(
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
        (void)my_cxtp; /* silence warning */
        if (!SvPOK(in) || SvCUR(in) != sizeof(uu_t))
            uu_clear(&su);
        else
            uu_pack_unpack((U8*)SvPV_force(in, len), &su);
        SV_CHECK_THINKFIRST_COW_DROP(out);
        if (isGV_with_GP(out))
            croak("%s", PL_no_modify);
        SvUPGRADE(out, SVt_PV);
        dptr = SvGROW(out, sizeof(uu_t)+1);
        uu_pack_v1(&su, (U8*)dptr);
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
            uu_pack_unpack((unsigned char*)sptr, &su);
            UU_ALIAS_GEN_V3(out, su, dptr);
        }
        else if (slen > 0  /* ibcmp first appears in v5.7.3 */
            && ( (slen == 3 && !ibcmp(sptr, "dns",  (I32)slen) && CopyD(&UU_namespace_dns,  &su, 1, struct_uu_t))
              || (slen == 3 && !ibcmp(sptr, "url",  (I32)slen) && CopyD(&UU_namespace_url,  &su, 1, struct_uu_t))
              || (slen == 3 && !ibcmp(sptr, "oid",  (I32)slen) && CopyD(&UU_namespace_oid,  &su, 1, struct_uu_t))
              || (slen == 4 && !ibcmp(sptr, "x500", (I32)slen) && CopyD(&UU_namespace_x500, &su, 1, struct_uu_t))
            )
        ) {
            UU_ALIAS_GEN_V3(out, su, dptr);
        }
        else {  /* slen == 0 ; assume url type */
            CopyD(&UU_namespace_url, &su, 1, struct_uu_t);
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
            uu_pack_unpack((unsigned char*)sptr, &su);
            UU_ALIAS_GEN_V5(out, su, dptr);
        }
        else if (slen > 0  /* ibcmp first appears in v5.7.3 */
            && ( (slen == 3 && !ibcmp(sptr, "dns",  (I32)slen) && CopyD(&UU_namespace_dns,  &su, 1, struct_uu_t))
              || (slen == 3 && !ibcmp(sptr, "url",  (I32)slen) && CopyD(&UU_namespace_url,  &su, 1, struct_uu_t))
              || (slen == 3 && !ibcmp(sptr, "oid",  (I32)slen) && CopyD(&UU_namespace_oid,  &su, 1, struct_uu_t))
              || (slen == 4 && !ibcmp(sptr, "x500", (I32)slen) && CopyD(&UU_namespace_x500, &su, 1, struct_uu_t))
            )
        ) {
            UU_ALIAS_GEN_V5(out, su, dptr);
        }
        else {  /* slen == 0 ; assume url type */
            CopyD(&UU_namespace_url, &su, 1, struct_uu_t);
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
        (void)my_cxtp; /* silence warning */
        if (!SvPOK(in))
            RETVAL = 0;
        else if (SvCUR(in) != sizeof(uu_t))
            RETVAL = 0;
        else
            RETVAL = uu_compare_isnull_binary((U8*)SvPV(in, len));
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
        (void)my_cxtp; /* silence warning */
        /* XXX might see uninitialized data */
        RETVAL = -1;
        if (SvPOK(in) && !uu_parse(SvGROW(in, UUID_BUFFSZ+1), &su)) {
            SV_CHECK_THINKFIRST_COW_DROP(out);
            if (isGV_with_GP(out))
                croak("%s", PL_no_modify);
            SvUPGRADE(out, SVt_PV);
            dptr = SvGROW(out, sizeof(uu_t)+1);
            uu_pack_v1(&su, (U8*)dptr);
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
        (void)my_cxtp; /* silence warning */
        RETVAL = 0;
        if (SvPOK(in)) {
            str = SvPV(in, len);
            if (len == sizeof(uu_t)) {
                uu_pack_unpack((U8*)str, &su);
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
        (void)my_cxtp; /* silence warning */
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
        (void)my_cxtp; /* silence warning */
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
        (void)my_cxtp; /* silence warning */
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
        (void)my_cxtp; /* silence warning */
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
            uu_pack_unpack((unsigned char*)sptr, &su);
            UU_ALIAS_UUID3(su, dptr);
        }
        else if (slen > 0  /* ibcmp first appears in v5.7.3 */
            && ( (slen == 3 && !ibcmp(sptr, "dns",  (I32)slen) && CopyD(&UU_namespace_dns,  &su, 1, struct_uu_t))
              || (slen == 3 && !ibcmp(sptr, "url",  (I32)slen) && CopyD(&UU_namespace_url,  &su, 1, struct_uu_t))
              || (slen == 3 && !ibcmp(sptr, "oid",  (I32)slen) && CopyD(&UU_namespace_oid,  &su, 1, struct_uu_t))
              || (slen == 4 && !ibcmp(sptr, "x500", (I32)slen) && CopyD(&UU_namespace_x500, &su, 1, struct_uu_t))
            )
        ) {
            UU_ALIAS_UUID3(su, dptr);
        }
        else {  /* slen == 0 ; assume url type */
            CopyD(&UU_namespace_url, &su, 1, struct_uu_t);
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
            uu_pack_unpack((unsigned char*)sptr, &su);
            UU_ALIAS_UUID5(su, dptr);
        }
        else if (slen > 0  /* ibcmp first appears in v5.7.3 */
            && ( (slen == 3 && !ibcmp(sptr, "dns",  (I32)slen) && CopyD(&UU_namespace_dns,  &su, 1, struct_uu_t))
              || (slen == 3 && !ibcmp(sptr, "url",  (I32)slen) && CopyD(&UU_namespace_url,  &su, 1, struct_uu_t))
              || (slen == 3 && !ibcmp(sptr, "oid",  (I32)slen) && CopyD(&UU_namespace_oid,  &su, 1, struct_uu_t))
              || (slen == 4 && !ibcmp(sptr, "x500", (I32)slen) && CopyD(&UU_namespace_x500, &su, 1, struct_uu_t))
            )
        ) {
            UU_ALIAS_UUID5(su, dptr);
        }
        else {  /* slen == 0 ; assume url type */
            CopyD(&UU_namespace_url, &su, 1, struct_uu_t);
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
        (void)my_cxtp; /* silence warning */
        RETVAL = 0;
        if (SvPOK(in)) {
            str = SvPV(in, len);
            if (len == sizeof(uu_t)) {
                uu_pack_unpack((unsigned char*)str, &su);
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
        (void)my_cxtp; /* silence warning */
        UU_ALIAS_VERSION(in, su, str, len);
    OUTPUT:
        RETVAL


#ifdef ONLY_FOR_DEV
void
_dump_struct()
    PROTOTYPE:
    PREINIT:
        dUCXT;
    INIT:
        my_cxt_t     *cxt  = my_cxtp;
        shared_mem_t *smem = cxt->shared;
    PPCODE:
        UV o = PTR2UV(&smem->LOCK);
        warn("============== shared_mem_t ==============\n");

        warn("LOCK .................. 0x%p %" UVuf "\n", &smem->LOCK               , PTR2UV(&smem->LOCK              ) - o);
        warn("__pad0 ................ 0x%p %" UVuf "\n", &smem->__pad0             , PTR2UV(&smem->__pad0            ) - o);
        UV len0 = sizeof(smem->LOCK) + sizeof(smem->__pad0);
        UV pages0 = len0 / 64; if (len0 % 64) ++pages0;
        warn("---- %" UVuf " bytes ; %" UVuf " * 64 = %" UVuf " bytes ----\n", len0, pages0, pages0*64);

        warn("clock_last ............ 0x%p %" UVuf "\n", &smem->clock_last         , PTR2UV(&smem->clock_last        ) - o);
        warn("  clock_last.tv_sec ... 0x%p %" UVuf "\n", &smem->clock_last.tv_sec  , PTR2UV(&smem->clock_last.tv_sec ) - o);
        warn("  clock_last.tv_usec .. 0x%p %" UVuf "\n", &smem->clock_last.tv_usec , PTR2UV(&smem->clock_last.tv_usec) - o);
        warn("clock_prev_reg ........ 0x%p %" UVuf "\n", &smem->clock_prev_reg     , PTR2UV(&smem->clock_prev_reg    ) - o);
        warn("clock_defer_100ns ..... 0x%p %" UVuf "\n", &smem->clock_defer_100ns  , PTR2UV(&smem->clock_defer_100ns ) - o);
        warn("clock_adj ............. 0x%p %" UVuf "\n", &smem->clock_adj          , PTR2UV(&smem->clock_adj         ) - o);
        warn("clock_seq ............. 0x%p %" UVuf "\n", &smem->clock_seq          , PTR2UV(&smem->clock_seq         ) - o);
        warn("__pad1 ................ 0x%p %" UVuf "\n", &smem->__pad1             , PTR2UV(&smem->__pad1            ) - o);
        UV len1 = sizeof(smem->clock_last) + sizeof(smem->clock_prev_reg) + sizeof(smem->clock_defer_100ns)
            + sizeof(smem->clock_adj) + sizeof(smem->clock_seq) + sizeof(smem->__pad1);
        UV pages1 = len1 / 64; if (len1 % 64) ++pages1;
        warn("---- %" UVuf " bytes ; %" UVuf " * 64 = %" UVuf " bytes ----\n", len1, pages1, pages1*64);

        warn("gen_epoch ............. 0x%p %" UVuf "\n", &smem->gen_epoch          , PTR2UV(&smem->gen_epoch         ) - o);
        warn("gen_node .............. 0x%p %" UVuf "\n", &smem->gen_node           , PTR2UV(&smem->gen_node          ) - o);
        warn("gen_has_real_node ..... 0x%p %" UVuf "\n", &smem->gen_has_real_node  , PTR2UV(&smem->gen_has_real_node ) - o);
        warn("gen_real_node ......... 0x%p %" UVuf "\n", &smem->gen_real_node      , PTR2UV(&smem->gen_real_node     ) - o);
        warn("gen_use_unique ........ 0x%p %" UVuf "\n", &smem->gen_use_unique     , PTR2UV(&smem->gen_use_unique    ) - o);
        warn("__pad2 ................ 0x%p %" UVuf "\n", &smem->__pad2             , PTR2UV(&smem->__pad2            ) - o);
        UV len2 = sizeof(smem->gen_epoch) + sizeof(smem->gen_node) + sizeof(smem->gen_has_real_node)
            + sizeof(smem->gen_real_node) + sizeof(smem->gen_use_unique) + sizeof(smem->__pad2);
        UV pages2 = len2 / 64; if (len2 % 64) ++pages2;
        warn("---- %" UVuf " bytes ; %" UVuf " * 64 = %" UVuf " bytes ----\n", len2, pages2, pages2*64);

        warn("cc .................... 0x%p %" UVuf "\n", &smem->cc                 , PTR2UV(&smem->cc                ) - o);
        warn("  cc.state ............ 0x%p %" UVuf "\n", &smem->cc.state           , PTR2UV(&smem->cc.state          ) - o);
        warn("  cc.buf .............. 0x%p %" UVuf "\n", &smem->cc.buf             , PTR2UV(&smem->cc.buf            ) - o);
        warn("  cc.have ............. 0x%p %" UVuf "\n", &smem->cc.have            , PTR2UV(&smem->cc.have           ) - o);
        warn("  cc.__align .......... 0x%p %" UVuf "\n", &smem->cc.__align         , PTR2UV(&smem->cc.__align        ) - o);
        warn("xo_s .................. 0x%p %" UVuf "\n", &smem->xo_s               , PTR2UV(&smem->xo_s              ) - o);
        warn("sm_x .................. 0x%p %" UVuf "\n", &smem->sm_x               , PTR2UV(&smem->sm_x              ) - o);
        warn("__pad3 ................ 0x%p %" UVuf "\n", &smem->__pad3             , PTR2UV(&smem->__pad3            ) - o);
        UV len3 = sizeof(smem->cc) + sizeof(smem->xo_s) + sizeof(smem->sm_x) + sizeof(smem->__pad3);
        UV pages3 = len3 / 64; if (len3 % 64) ++pages3;
        warn("---- %" UVuf " bytes ; %" UVuf " * 64 = %" UVuf " bytes ----\n", len3, pages3, pages3*64);

        warn("clock_persist ......... 0x%p %" UVuf "\n", &smem->clock_persist      , PTR2UV(&smem->clock_persist     ) - o);
        warn("  clock_persist.len ... 0x%p %" UVuf "\n", &smem->clock_persist.len  , PTR2UV(&smem->clock_persist.len ) - o);
        warn("  clock_persist.path .. 0x%p %" UVuf "\n", &smem->clock_persist.path , PTR2UV(&smem->clock_persist.path) - o);
        UV len4 = sizeof(smem->clock_persist);
        UV pages4 = len4 / 64; if (len4 % 64) ++pages4;
        warn("---- %" UVuf " bytes ; %" UVuf " * 64 = %" UVuf " bytes ----\n", len4, pages4, pages4*64);

        warn("shared_mem_t size : %lu\n\n", sizeof(shared_mem_t));

        warn("============== my_cxt_t ==============\n");
        o = PTR2UV(&cxt->shared);
        warn("shared ................ 0x%p %" UVuf "\n", &cxt->shared             , PTR2UV(&cxt->shared            ) - o);
        warn("shared_len ............ 0x%p %" UVuf "\n", &cxt->shared_len         , PTR2UV(&cxt->shared_len        ) - o);
        warn("clock_state_f ......... 0x%p %" UVuf "\n", &cxt->clock_state_f      , PTR2UV(&cxt->clock_state_f     ) - o);
        warn("clock_state_fd ........ 0x%p %" UVuf "\n", &cxt->clock_state_fd     , PTR2UV(&cxt->clock_state_fd    ) - o);
        warn("__pad5 ................ 0x%p %" UVuf "\n", &cxt->__pad5             , PTR2UV(&cxt->__pad5            ) - o);
        UV len5 = sizeof(cxt->shared) + sizeof(cxt->shared_len) + sizeof(cxt->clock_state_f)
            + sizeof(cxt->clock_state_fd) + sizeof(cxt->__pad5);
        UV pages5 = len5 / 64; if (len5 % 64) ++pages5;
        warn("---- %" UVuf " bytes ; %" UVuf " * 64 = %" UVuf " bytes ----\n", len5, pages5, pages5*64);

        warn("clock_persist ......... 0x%p %" UVuf "\n", &cxt->clock_persist      , PTR2UV(&cxt->clock_persist     ) - o);
        warn("  clock_persist.len ... 0x%p %" UVuf "\n", &cxt->clock_persist.len  , PTR2UV(&cxt->clock_persist.len ) - o);
        warn("  clock_persist.path .. 0x%p %" UVuf "\n", &cxt->clock_persist.path , PTR2UV(&cxt->clock_persist.path) - o);
        UV len6 = sizeof(cxt->clock_persist);
        UV pages6 = len6 / 64; if (len6 % 64) ++pages6;
        warn("---- %" UVuf " bytes ; %" UVuf " * 64 = %" UVuf " bytes ----\n", len6, pages6, pages6*64);

        warn("my_cxt_t size : %lu\n\n", sizeof(my_cxt_t));
        warn("uu_mutex: %lu\n", sizeof(uu_mutex));

#endif
