/* -*- Mode: C -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#if (defined(I64TYPE) && (I64SIZE == 8) && (IVSIZE >= 8))

static void init_quad_support(pTHX) {}

#else

#define USE_PERL_MATH_INT64

/* define int64_t and uint64_t when using MinGW compiler */
#ifdef __MINGW32__
#include <stdint.h>
#endif

/* define int64_t and uint64_t when using MS compiler */
#ifdef _MSC_VER
#include <stdlib.h>
typedef __int64 int64_t;
typedef unsigned __int64 uint64_t;
#endif

#include "perl_math_int64.h"

static int perl_math_int64_loaded = 0;
static void init_quad_support(pTHX) {
    if (!perl_math_int64_loaded) {
        PERL_MATH_INT64_LOAD_OR_CROAK;
        perl_math_int64_loaded = 1;
    }
}

#endif /* USE_PERL_MATH_INT64 */


#if ((LONGSIZE >= 8) &&  ((__GNUC__ > 4) || (__GNUC__ == 4 && __GNUC_MINOR__ >= 4)))

#define USE_PERL_MATH_INT128

#if __GNUC__ == 4 && __GNUC_MINOR__ < 6

/* workaroung for gcc 4.4/4.5 - see http://gcc.gnu.org/gcc-4.4/changes.html */
typedef int int128_t __attribute__ ((__mode__ (TI)));
typedef unsigned int uint128_t __attribute__ ((__mode__ (TI)));

#else

typedef __int128 int128_t;
typedef unsigned __int128 uint128_t;

#endif

#include "perl_math_int128.h"

static int perl_math_int128_loaded = 0;
static void init_int128_support(pTHX) {
    if (!perl_math_int128_loaded) {
        PERL_MATH_INT128_LOAD_OR_CROAK;
        perl_math_int128_loaded = 1;
    }
}

#endif /* USE_PERL_MATH_INT128 */

#include <string.h>
#include <limits.h>

#define TPA_MAGIC "TPA"

#define RESERVE_BEFORE ((((size) >> 3) + 8) * (esize))
#define RESERVE_AFTER ((((size) >> 2) + 8) * (esize))

#define MySvGROW(sv, req) (SvLEN(sv) < (req) ? sv_grow((sv), (req) + RESERVE_AFTER ) : SvPVX(sv))

struct tpa_vtbl {
    char magic[4];
    UV element_size;
    void (*set)(pTHX_ void *, SV *);
    SV *(*get)(pTHX_ void *);
    int (*cmp)(pTHX_ void *, void *);
    char * packer;
};

static int
tpa_cmp_le(void *ap, void *bp, int size) {
    unsigned char *apu = (unsigned char *)ap;
    unsigned char *bpu = (unsigned char *)bp;
    while (size--) {
        if (apu[size] < bpu[size]) return -1;
        if (apu[size] > bpu[size]) return  1;
    }
    return 0;
}

static int
tpa_cmp_be(void *ap, void *bp, int size) {
    return memcmp(ap, bp, size);
}

#define MAKE_CMP(name, type)                             \
    static int                                           \
    tpa_cmp_ ## name(pTHX_ void *ap, void *bp) {         \
        type a = *(type *)ap;                            \
        type b = *(type *)bp;                            \
        return (a < b ? -1 : a > b ?  1 : 0);            \
    }

#define MAKE_CMP_LE(type)                                       \
    static int                                                  \
    tpa_cmp_ ## type(pTHX_ void *ap, void *bp) {                \
        return tpa_cmp_le(ap, bp, sizeof(type));                \
    }

#define MAKE_CMP_BE(type)                                       \
    static int                                                  \
    tpa_cmp_ ## type(pTHX_ void *ap, void *bp) {                \
        return tpa_cmp_be(ap, bp, sizeof(type));                \
    }


static void
tpa_set_char(pTHX_ char *ptr, SV *sv) {
    *ptr = SvIV(sv);
}

static SV *
tpa_get_char(pTHX_ char *ptr) {
    return newSViv(*ptr);
}

MAKE_CMP(char, char)

static struct tpa_vtbl vtbl_char = { TPA_MAGIC,
                                     sizeof(char),
                                     (void (*)(pTHX_ void*, SV*)) &tpa_set_char,
                                     (SV* (*)(pTHX_ void*)) &tpa_get_char,
                                     &tpa_cmp_char,
                                     "c" };

static void
tpa_set_uchar(pTHX_ unsigned char *ptr, SV *sv) {
    *ptr = SvUV(sv);
}

static SV *
tpa_get_uchar(pTHX_ unsigned char *ptr) {
    return newSVuv(*ptr);
}

MAKE_CMP(uchar, unsigned char)

static struct tpa_vtbl vtbl_uchar = { TPA_MAGIC,
                                      sizeof(unsigned char),
                                      (void (*)(pTHX_ void*, SV*)) &tpa_set_uchar,
                                      (SV* (*)(pTHX_ void*)) &tpa_get_uchar,
                                      &tpa_cmp_uchar,
                                      "C"};

static void
tpa_set_hex(pTHX_ char *ptr, SV *sv) {
    int h = SvUV(sv) & 15;
    *ptr = h + (h > 9 ? 'a' - 10 : '0');
}

#define HEX2INT(c) \
    ( ( ((c) >= '0') && ((c) <= '9')) ? (c) - '0' :             \
      ( ((c) >= 'a') && ((c) <= 'f')) ? (c) - ('a' - 10) :      \
      ( ((c) >= 'A') && ((c) <= 'F')) ? (c) - ('A' - 10) : 0 ) 

static SV *
tpa_get_hex(pTHX_ char *ptr) {
    int c = *ptr;
    return newSVuv( HEX2INT(c) );
}

static int
tpa_cmp_hex(pTHX_ void *ap, void *bp) {
    char a = *(char *)ap;
    char b = *(char *)bp;
    a = HEX2INT(a);
    b = HEX2INT(b);
    return ((a < b) ? -1 : (a > b) ?  1 : 0);
}

static struct tpa_vtbl vtbl_hex = { TPA_MAGIC,
                                    sizeof(unsigned char),
                                    (void (*)(pTHX_ void*, SV*)) &tpa_set_hex,
                                    (SV* (*)(pTHX_ void*)) &tpa_get_hex,
                                    &tpa_cmp_hex,
                                    "h"};

static void
tpa_set_IV(pTHX_ IV *ptr, SV *sv) {
    *ptr = SvIV(sv);
}

static SV *
tpa_get_IV(pTHX_ IV *ptr) {
    return newSViv(*ptr);
}

MAKE_CMP(IV, IV)

static struct tpa_vtbl vtbl_IV = { TPA_MAGIC,
                                   sizeof(IV),
                                   (void (*)(pTHX_ void*, SV*)) &tpa_set_IV,
                                   (SV* (*)(pTHX_ void*)) &tpa_get_IV,
                                   &tpa_cmp_IV,
                                   "j" };

static void
tpa_set_UV(pTHX_ UV *ptr, SV *sv) {
    *ptr = SvUV(sv);
}

static SV *
tpa_get_UV(pTHX_ UV *ptr) {
    return newSVuv(*ptr);
}

MAKE_CMP(UV, UV)

static struct tpa_vtbl vtbl_UV = { TPA_MAGIC,
                                   sizeof(UV),
                                   (void (*)(pTHX_ void*, SV*)) &tpa_set_UV,
                                   (SV* (*)(pTHX_ void*)) &tpa_get_UV,
                                   &tpa_cmp_UV,
                                   "J" };

static void
tpa_set_NV(pTHX_ NV *ptr, SV *sv) {
    *ptr = SvNV(sv);
}

static SV *
tpa_get_NV(pTHX_ NV *ptr) {
    return newSVnv(*ptr);
}

MAKE_CMP(NV, NV)

static struct tpa_vtbl vtbl_NV = { TPA_MAGIC,
                                   sizeof(NV),
                                   (void (*)(pTHX_ void*, SV*)) &tpa_set_NV,
                                   (SV* (*)(pTHX_ void*)) &tpa_get_NV,
                                   &tpa_cmp_NV,
                                   "F" };

static void
tpa_set_double(pTHX_ double *ptr, SV *sv) {
    *ptr = SvNV(sv);
}

static SV *
tpa_get_double(pTHX_ double *ptr) {
    return newSVnv(*ptr);
}

MAKE_CMP(double, double)

static struct tpa_vtbl vtbl_double = { TPA_MAGIC,
                                       sizeof(double),
                                       (void (*)(pTHX_ void*, SV*)) &tpa_set_double,
                                       (SV* (*)(pTHX_ void*)) &tpa_get_double,
                                       &tpa_cmp_double,
                                       "d" };

static void
tpa_set_float(pTHX_ float *ptr, SV *sv) {
    *ptr = SvNV(sv);
}

static SV *
tpa_get_float(pTHX_ float *ptr) {
    return newSVnv(*ptr);
}

MAKE_CMP(float, float)

static struct tpa_vtbl vtbl_float = { TPA_MAGIC,
                                      sizeof(float),
                                      (void (*)(pTHX_ void*, SV*)) &tpa_set_float,
                                      (SV* (*)(pTHX_ void*)) &tpa_get_float,
                                      &tpa_cmp_float,
                                      "f" };

static void
tpa_set_int_native(pTHX_ int *ptr, SV *sv) {
    *ptr = SvIV(sv);
}

static SV*
tpa_get_int_native(pTHX_ int *ptr) {
    return newSViv(*ptr);
}

MAKE_CMP(int_native, int)

static struct tpa_vtbl vtbl_int_native = { TPA_MAGIC,
                                           sizeof(int),
                                           (void (*)(pTHX_ void*, SV*)) &tpa_set_int_native,
                                           (SV* (*)(pTHX_ void*)) &tpa_get_int_native,
                                           &tpa_cmp_int_native,
                                           "i!" };

static void
tpa_set_short_native(pTHX_ short *ptr, SV *sv) {
    *ptr = SvIV(sv);
}

static SV*
tpa_get_short_native(pTHX_ short *ptr) {
    return newSViv(*ptr);
}

MAKE_CMP(short_native, short)

static struct tpa_vtbl vtbl_short_native = { TPA_MAGIC,
                                             sizeof(short),
                                             (void (*)(pTHX_ void*, SV*)) &tpa_set_short_native,
                                             (SV* (*)(pTHX_ void*)) &tpa_get_short_native,
                                             &tpa_cmp_short_native,
                                             "s!" };

static void
tpa_set_long_native(pTHX_ long *ptr, SV *sv) {
#if (IVSIZE >= LONGSIZE)
    *ptr = SvIV(sv);
#else
    if (SvIOK(sv)) {
        if (SvIOK_UV(sv))
            *ptr = SvUV(sv);
        else
            *ptr = SvIV(sv);
    }
    else
        *ptr = SvNV(sv);
#endif
}

static SV *
tpa_get_long_native(pTHX_ long *ptr) {
#if (IVSIZE >= LONGSIZE)
    return newSViv(*ptr);
#else
    return newSVnv(*ptr);
#endif
}

MAKE_CMP(long_native, long)

static struct tpa_vtbl vtbl_long_native = { TPA_MAGIC,
                                            sizeof(long),
                                            (void (*)(pTHX_ void*, SV*)) &tpa_set_long_native,
                                            (SV* (*)(pTHX_ void*)) &tpa_get_long_native,
                                            &tpa_cmp_long_native,
                                            "l!" };

static void
tpa_set_uint_native(pTHX_ unsigned int *ptr, SV *sv) {
    *ptr = SvUV(sv);
}

static SV *
tpa_get_uint_native(pTHX_ unsigned int *ptr) {
    return newSVuv(*ptr);
}

MAKE_CMP(uint_native, unsigned int)

static struct tpa_vtbl vtbl_uint_native = { TPA_MAGIC,
                                            sizeof(unsigned int),
                                            (void (*)(pTHX_ void*, SV*)) &tpa_set_uint_native,
                                            (SV* (*)(pTHX_ void*)) &tpa_get_uint_native,
                                            &tpa_cmp_uint_native,
                                            "S!" };

static void
tpa_set_ushort_native(pTHX_ unsigned short *ptr, SV *sv) {
    *ptr = SvUV(sv);
}

static SV *
tpa_get_ushort_native(pTHX_ unsigned short *ptr) {
    return newSVuv(*ptr);
}

MAKE_CMP(ushort_native, unsigned short)

static struct tpa_vtbl vtbl_ushort_native = { TPA_MAGIC,
                                              sizeof(unsigned short),
                                              (void (*)(pTHX_ void*, SV*)) &tpa_set_ushort_native,
                                              (SV* (*)(pTHX_ void*)) &tpa_get_ushort_native,
                                              &tpa_cmp_ushort_native,
                                              "S!" };

static void
tpa_set_ulong_native(pTHX_ unsigned long *ptr, SV *sv) {
#if (IVSIZE >= LONGSIZE)
    *ptr = SvUV(sv);
#else
    if (SvIOK(sv) && !SvIOK_notUV(sv))
        *ptr = SvNV(sv);
    else
        *ptr = SvUV(sv);
#endif
}

static SV *
tpa_get_ulong_native(pTHX_ unsigned long *ptr) {
#if (IVSIZE >= LONGSIZE)
    return newSVuv(*ptr);
#else
    return newSVnv(*ptr);
#endif
}

MAKE_CMP(ulong_native, unsigned long)

static struct tpa_vtbl vtbl_ulong_native = { TPA_MAGIC,
                                             sizeof(unsigned long),
                                             (void (*)(pTHX_ void*, SV*)) &tpa_set_ulong_native,
                                             (SV* (*)(pTHX_ void*)) &tpa_get_ulong_native,
                                             &tpa_cmp_ulong_native,
                                             "L!" };

#if defined(USE_PERL_MATH_INT64)

static void
tpa_set_quad_native(pTHX_ int64_t *ptr, SV *sv) {
    *ptr = SvI64(sv);
}

static SV *
tpa_get_quad_native(pTHX_ int64_t *ptr) {
    return newSVi64(*ptr);
}

MAKE_CMP(quad_native, int64_t)

static void
tpa_set_uquad_native(pTHX_ uint64_t *ptr, SV *sv) {
    *ptr = SvU64(sv);
}

static SV*
tpa_get_uquad_native(pTHX_ uint64_t *ptr) {
    return newSVu64(*ptr);
}

MAKE_CMP(uquad_native, uint64_t)

#else

static void
tpa_set_quad_native(pTHX_ I64TYPE *ptr, SV *sv) {
    *ptr = SvIV(sv);
}

static SV *
tpa_get_quad_native(pTHX_ I64TYPE *ptr) {
    return newSViv(*ptr);
}

MAKE_CMP(quad_native, I64TYPE)

static void
tpa_set_uquad_native(pTHX_ U64TYPE *ptr, SV *sv) {
    *ptr = SvUV(sv);
}

static SV*
tpa_get_uquad_native(pTHX_ U64TYPE *ptr) {
    return newSVuv(*ptr);
}

MAKE_CMP(uquad_native, U64TYPE)

#endif

static struct tpa_vtbl vtbl_quad_native = { TPA_MAGIC,
                                            8,
                                            (void (*)(pTHX_ void*, SV*)) &tpa_set_quad_native,
                                            (SV* (*)(pTHX_ void*)) &tpa_get_quad_native,
                                            &tpa_cmp_quad_native,
                                            "q" };


static struct tpa_vtbl vtbl_uquad_native = { TPA_MAGIC,
                                             8,
                                             (void (*)(pTHX_ void*, SV*)) &tpa_set_uquad_native,
                                             (SV* (*)(pTHX_ void*)) &tpa_get_uquad_native,
                                             &tpa_cmp_uquad_native,
                                             "Q" };


#if defined(USE_PERL_MATH_INT128)

static void
tpa_set_int128_native(pTHX_ int128_t *ptr, SV *sv) {
    *ptr = SvI128(sv);
}

static SV *
tpa_get_int128_native(pTHX_ int128_t *ptr) {
    return newSVi128(*ptr);
}

MAKE_CMP(int128_native, int128_t)

static struct tpa_vtbl vtbl_int128_native = { TPA_MAGIC,
                                              16,
                                              (void (*)(pTHX_ void*, SV*)) &tpa_set_int128_native,
                                              (SV* (*)(pTHX_ void*)) &tpa_get_int128_native,
                                              &tpa_cmp_int128_native,
                                              "e" };

static void
tpa_set_uint128_native(pTHX_ uint128_t *ptr, SV *sv) {
    *ptr = SvU128(sv);
}

static SV*
tpa_get_uint128_native(pTHX_ uint128_t *ptr) {
    return newSVu128(*ptr);
}

MAKE_CMP(uint128_native, uint128_t)

static struct tpa_vtbl vtbl_uint128_native = { TPA_MAGIC,
                                               16,
                                               (void (*)(pTHX_ void*, SV*)) &tpa_set_uint128_native,
                                               (SV* (*)(pTHX_ void*)) &tpa_get_uint128_native,
                                               &tpa_cmp_uint128_native,
                                               "E" };

#endif

#if (((BYTEORDER == 0x1234) || (BYTEORDER == 0x12345678)) && (SHORTSIZE == 2))

typedef unsigned short ushort_le;
#define tpa_set_ushort_le tpa_set_ushort_native
#define tpa_get_ushort_le tpa_get_ushort_native
#define tpa_cmp_ushort_le tpa_cmp_ushort_native

#else

typedef struct _ushort_le { unsigned char c[2]; } ushort_le;

static void
tpa_set_ushort_le(pTHX_ ushort_le *ptr, SV *sv) {
    UV v = SvUV(sv);
    ptr->c[0] = v;
    ptr->c[1] = v >> 8;
}

static SV *
tpa_get_ushort_le(pTHX_ ushort_le *ptr) {
    return newSVuv((ptr->c[1] << 8) + ptr->c[0]);
}

MAKE_CMP_LE(ushort_le);

#endif

static struct tpa_vtbl vtbl_ushort_le = { TPA_MAGIC,
                                          sizeof(ushort_le),
                                          (void (*)(pTHX_ void*, SV*)) &tpa_set_ushort_le,
                                          (SV* (*)(pTHX_ void*)) &tpa_get_ushort_le,
                                          &tpa_cmp_ushort_le,
                                          "v" };
#if (((BYTEORDER == 0x4321) || (BYTEORDER == 0x87654321)) && (SHORTSIZE == 2))

typedef unsigned short ushort_be;
#define tpa_set_ushort_be tpa_set_ushort_native
#define tpa_get_ushort_be tpa_get_ushort_native
#define tpa_cmp_ushort_be tpa_cmp_ushort_native

#else

typedef struct _ushort_be { unsigned char c[2]; } ushort_be;

static void
tpa_set_ushort_be(pTHX_ ushort_be *ptr, SV *sv) {
    UV v = SvUV(sv);
    ptr->c[0] = v >> 8;
    ptr->c[1] = v;
}

static SV *
tpa_get_ushort_be(pTHX_ ushort_be *ptr) {
    return newSVuv( (ptr->c[0] << 8) + ptr->c[1] );
}

MAKE_CMP_BE(ushort_be)

#endif

static struct tpa_vtbl vtbl_ushort_be = { TPA_MAGIC,
                                          sizeof(ushort_be),
                                          (void (*)(pTHX_ void*, SV*)) &tpa_set_ushort_be,
                                          (SV* (*)(pTHX_ void*)) &tpa_get_ushort_be,
                                          &tpa_cmp_ushort_be,
                                          "n" };

#if (((BYTEORDER == 0x1234) || (BYTEORDER == 0x12345678)) && (SHORTSIZE == 4))

typedef unsigned short ulong_le;
#define tpa_set_ulong_le tpa_set_ushort_native
#define tpa_get_ulong_le tpa_get_ushort_native
#define tpa_cmp_ulong_le tpa_cmp_ushort_native

#elif (((BYTEORDER == 0x1234) || (BYTEORDER == 0x12345678)) && (INTSIZE == 4))

typedef unsigned int ulong_le;
#define tpa_set_ulong_le tpa_set_uint_native
#define tpa_get_ulong_le tpa_get_uint_native
#define tpa_cmp_ulong_le tpa_cmp_uint_native

#elif (((BYTEORDER == 0x1234) || (BYTEORDER == 0x12345678)) && (LONGSIZE == 4))

typedef unsigned int ulong_le;
#define tpa_set_ulong_le tpa_set_ulong_native
#define tpa_get_ulong_le tpa_get_ulong_native
#define tpa_cmp_ulong_le tpa_cmp_ulong_native

#else

typedef struct _ulong_le { unsigned char c[4]; } ulong_le;

static void
tpa_set_ulong_le(pTHX_ ulong_le *ptr, SV *sv) {
    UV v = SvUV(sv);
    ptr->c[0] = v;
    ptr->c[1] = (v >>= 8);
    ptr->c[2] = (v >>= 8);
    ptr->c[3] = (v >>= 8);
}

static SV *
tpa_get_ulong_le(pTHX_ ulong_le *ptr) {
    return newSVuv((((((ptr->c[3] << 8) + ptr->c[2] ) << 8) + ptr->c[1] ) << 8) + ptr->c[0]);
}

MAKE_CMP_LE(ulong_le)

#endif

static struct tpa_vtbl vtbl_ulong_le = { TPA_MAGIC,
                                         sizeof(ulong_le),
                                         (void (*)(pTHX_ void*, SV*)) &tpa_set_ulong_le,
                                         (SV* (*)(pTHX_ void*)) &tpa_get_ulong_le,
                                         &tpa_cmp_ulong_le,
                                         "V" };

#if  (((BYTEORDER == 0x4321) || (BYTEORDER == 0x87654321)) && (SHORTSIZE == 4))

typedef unsigned short ulong_be;
#define tpa_set_ulong_be tpa_set_ushort_native
#define tpa_get_ulong_be tpa_get_ushort_native
#define tpa_cmp_ulong_be tpa_cmp_ushort_native

#elif (((BYTEORDER == 0x4321) || (BYTEORDER == 0x87654321)) && (INTSIZE == 4))

typedef unsigned int ulong_be;
#define tpa_set_ulong_be tpa_set_uint_native
#define tpa_get_ulong_be tpa_get_uint_native
#define tpa_cmp_ulong_be tpa_cmp_uint_native


#elif (((BYTEORDER == 0x4321) || (BYTEORDER == 0x87654321)) && (LONGSIZE == 4))

typedef unsigned long ulong_be;
#define tpa_set_ulong_be tpa_set_ulong_native
#define tpa_get_ulong_be tpa_get_ulong_native
#define tpa_cmp_ulong_be tpa_cmp_ulong_native

#else

typedef struct _ulong_be { unsigned char c[4]; } ulong_be;

static void
tpa_set_ulong_be(pTHX_ ulong_be *ptr, SV *sv) {
    UV v = SvUV(sv);
    ptr->c[3] = v;
    ptr->c[2] = (v >>= 8);
    ptr->c[1] = (v >>= 8);
    ptr->c[0] = (v >>= 8);
}

static SV *
tpa_get_ulong_be(pTHX_ ulong_be *ptr) {
    return newSVuv((((((ptr->c[0] << 8) + ptr->c[1] ) << 8) + ptr->c[2] ) << 8) + ptr->c[3]);
}

MAKE_CMP_BE(ulong_be)

#endif

static struct tpa_vtbl vtbl_ulong_be = { TPA_MAGIC,
                                         sizeof(ulong_be),
                                         (void (*)(pTHX_ void*, SV*)) &tpa_set_ulong_be,
                                         (SV* (*)(pTHX_ void*)) &tpa_get_ulong_be,
                                         &tpa_cmp_ulong_be,
                                         "N" };

static struct tpa_vtbl *
data_vtbl(pTHX_ SV *sv) {
    if (sv) {
        MAGIC *mg = mg_find(sv, '~');
        if (mg && mg->mg_ptr && !strcmp(mg->mg_ptr, TPA_MAGIC))
            return (struct tpa_vtbl *)(mg->mg_ptr);
    }
    Perl_croak(aTHX_ "internal error");
}

static void
check_index(pTHX_ UV ix, UV esize) {
    UV max = ((UV)(-1))/esize;
    if ( max < ix )
        Perl_croak(aTHX_ "index %" UVuf " is out of range", ix);
}

static char *
my_sv_unchop(pTHX_ SV *sv, STRLEN size, STRLEN reserve) {
    STRLEN len;
    char *pv = SvPV(sv, len);
    IV off = SvOOK(sv) ? SvIVX(sv) : 0;
    if (!size)
        return pv;
 
    if (off >= size) {
        SvLEN_set(sv, SvLEN(sv) + size);
        SvCUR_set(sv, len + size);
        SvPV_set(sv, pv - size);
        if (off == size)
            SvFLAGS(sv) &= ~SVf_OOK;
        else
            SvIV_set(sv, off - size);
    }
    else {
        size += reserve;
        if ((size < reserve) || (len + size < size))
            Perl_croak(aTHX_ "panic: memory wrap");
        
        if (len + size <= off + SvLEN(sv)) {
            SvCUR_set(sv, len + size);
            SvPV_set(sv, pv - off);
            Move(pv, pv + size - off, len, char);
            if (off) {
                SvLEN_set(sv, SvLEN(sv) + off );
                SvFLAGS(sv) &= ~SVf_OOK;
            }
        }
        else {
            SV *tmp = sv_2mortal(newSV(len + size));
            char *tmp_pv;
            SvPOK_on(tmp);
            tmp_pv = SvPV_nolen(tmp);
            Move(pv, tmp_pv + size, len, char);
            SvCUR_set(tmp, len + size);
            sv_setsv(sv, tmp);
        }
 
        if (reserve)
            sv_chop(sv, SvPVX(sv) + reserve);
    }
    return SvPVX(sv);
}

static void
reverse_elements(void *ptr, IV len, IV esize) {
    if ((esize % sizeof(unsigned int) == 0) && (PTR2IV(ptr) % sizeof(unsigned int) == 0)) {
        int *start, *end;
        esize /= sizeof(int);
        start = (int *)ptr;
        end = start + (len - 1) * esize;
        if (esize == 1) {
            while (start < end) {
                int tmp = *start;
                *(start++) = *end;
                *(end--) = tmp;
            }
        }
        else {
            while (start < end) {
                int i;
                for (i = 0; i < esize; i++) {
                    int tmp = *start;
                    *(start++) = *end;
                    *(end++) = tmp;
                }
                end -= esize * 2;
            }
        }
    }
    else {
        char *start = (char *)ptr;
        char *end = start + (len - 1) * esize;
        while (start < end) {
            int i;
            for (i = 0; i < esize; i++) {
                char tmp = *start;
                *(start++) = *end;
                *(end++) = tmp;
            }
            end -= esize * 2;
        }
    }
}




MODULE = Tie::Array::Packed		PACKAGE = Tie::Array::Packed
PROTOTYPES: DISABLE

SV *
TIEARRAY(klass, type, init)
    SV *klass;
    char *type;
    SV *init;
  CODE:
    {
        struct tpa_vtbl *vtbl = 0;
        if ( type[0] &&
             ( !type[1] ||
               ( type[1] == '!' && !type[2] ) ) )
        {
            switch(type[0]) {
            case 'c':
                vtbl = &vtbl_char;
                break;
            case 'C':
                vtbl = &vtbl_uchar;
                break;
            case 'h':
                vtbl = &vtbl_hex;
                break;
            case 'i':
                vtbl = &vtbl_int_native;
                break;
            case 'I':
                vtbl = &vtbl_uint_native;
                break;
            case 'j':
                vtbl = &vtbl_IV;
                break;
            case 'J':
                vtbl = &vtbl_UV;
                break;
            case 'f':
                vtbl = &vtbl_float;
                break;
            case 'd':
                vtbl = &vtbl_double;
                break;
            case 'F':
                vtbl = &vtbl_NV;
                break;
            case 'n':
                vtbl = &vtbl_ushort_be;
                break;
            case 'N':
                vtbl = &vtbl_ulong_be;
                break;
            case 'v':
                vtbl = &vtbl_ushort_le;
                break;
            case 'V':
                vtbl = &vtbl_ulong_le;
                break;
            case 's':
                if (type[1])
                    vtbl = &vtbl_short_native;
                break;
            case 'S':
                if (type[1])
                    vtbl = &vtbl_ushort_native;
                break;
            case 'l':
                if (type[1])
                    vtbl = &vtbl_long_native;
                break;
            case 'L':
                if (type[1])
                    vtbl = &vtbl_ulong_native;
                break;
            case 'q':
                init_quad_support(aTHX);
                vtbl = &vtbl_quad_native;
                break;
            case 'Q':
                init_quad_support(aTHX);
                vtbl = &vtbl_uquad_native;
                break;
#ifdef USE_PERL_MATH_INT128
            case 'e':
                init_int128_support(aTHX);
                vtbl = &vtbl_int128_native;
                break;
            case 'E':
                init_int128_support(aTHX);
                vtbl = &vtbl_uint128_native;
                break;
#else
            case 'e':
            case 'E':
                Perl_croak(aTHX_ "128 bit integers are not supported by your C compiler");
                break;
#endif
            }
        }
        if (!vtbl)
            Perl_croak(aTHX_ "invalid/unsupported packing type %s", type);
        else {
            STRLEN len;
            char *pv = SvPV(init, len);
            SV *data = newSVpvn(pv, len);
            RETVAL = newRV_noinc(data);
            if (SvOK(klass))
                sv_bless(RETVAL, gv_stashsv(klass, 1));
#if (PERL_VERSION < 7)
            sv_magic(data, 0, '~', (char *)vtbl, sizeof(*vtbl));
#else
            sv_magic(data, 0, '~', (char *)vtbl, 0);
#endif
        }
    }
  OUTPUT:
    RETVAL

void
STORE(self, key, value)
    SV *self;
    UV key;
    SV *value;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        UV esize = vtbl->element_size;
        STRLEN req = (key + 1) * esize;
        STRLEN len;
        char *pv = SvPV(data, len);
        UV size = len / esize;

        check_index(aTHX_ key, esize);

        if (len < req) {
            pv = MySvGROW(data, req);
            memset(pv + len, 0, req - len - esize);
            SvCUR_set(data, req);
        }
        (*(vtbl->set))(aTHX_ pv + req - esize, value);
    }

SV *
FETCH(self, key)
    SV *self;
    UV key;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        UV esize = vtbl->element_size;
        STRLEN req = (key + 1) * esize;
        STRLEN len;
        char *pv = SvPV(data, len);
        if (len < req)
            RETVAL = &PL_sv_undef;
        else {
            RETVAL = (*(vtbl->get))(aTHX_ pv + req - esize);
        }
    }
  OUTPUT:
    RETVAL

UV
FETCHSIZE(self)
    SV *self;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        UV esize = vtbl->element_size;
        RETVAL = SvCUR(data) / esize;
    }
  OUTPUT:
    RETVAL

void
STORESIZE(self, size)
    SV *self;
    UV size;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        UV esize = vtbl->element_size;
        STRLEN req = size * esize;
        STRLEN len;
        char *pv = SvPV(data, len);
        
        check_index(aTHX_ size, esize);

        if (len < req) {
            pv = SvGROW(data, req);
            memset(pv + len, 0, req - len);
        }
        SvCUR_set(data, req);
    }

void
EXTEND(self, size)
    SV *self;
    UV size;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        UV esize = vtbl->element_size;
        STRLEN req = size * esize;
        
        check_index(aTHX_ size, esize);
        
        SvGROW(data, req);
    }

SV *
EXISTS(self, key)
    SV *self;
    UV key;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        UV esize = vtbl->element_size;
        RETVAL = ((SvCUR(data) / esize) > key) ? &PL_sv_yes : &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

SV *
DELETE(self, key)
    SV *self;
    UV key;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        UV esize = vtbl->element_size;
        STRLEN req = (key + 1) * esize;
        STRLEN len;
        char *pv = SvPV(data, len);

        check_index(aTHX_ key, esize);

        if (len >= req) {
            RETVAL = (*(vtbl->get))(aTHX_ pv + req - esize);
            memset(pv + req - esize, 0, esize);
        }
        else
            RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

void
CLEAR(self)
    SV *self;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        SvCUR_set(data, 0);
    }

void
PUSH(self, ...)
    SV *self;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        UV esize = vtbl->element_size;
        STRLEN len;
        char *pv = SvPV(data, len);
        UV size = len / esize;
        STRLEN req = (size + items - 1) * esize;
        UV i;

        check_index(aTHX_ size + items - 1, esize);

        pv = MySvGROW(data, req);
        SvCUR_set(data, req);

        for (i = 1; i < items; i++)
            (*(vtbl->set))(aTHX_ pv + (size + i - 1) * esize, ST(i));
    }

SV *
POP(self)
    SV *self;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        UV esize = vtbl->element_size;
        STRLEN len;
        char *pv = SvPV(data, len);
        UV size = len / esize;
        if (size) {
            STRLEN new_len = (size - 1) * esize;
            RETVAL = (*(vtbl->get))(aTHX_ pv + new_len);
            SvCUR_set(data, new_len);
        }
        else
            RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

SV *
SHIFT(self)
    SV *self;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        UV esize = vtbl->element_size;
        STRLEN len;
        char *pv = SvPV(data, len);
        UV size = len / esize;
        if (size) {
            RETVAL = (*(vtbl->get))(aTHX_ pv);
            sv_chop(data, pv + esize);
        }
        else
            RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

void
UNSHIFT(self, ...)
    SV *self;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        if (items > 1) {
            UV esize = vtbl->element_size;
	    UV size = SvCUR(data) / esize;
            char *pv;
            UV i;

            check_index(aTHX_ size + items - 1, esize);
            pv = my_sv_unchop(aTHX_ data, esize * (items - 1), RESERVE_BEFORE);
            for (i = 1; i < items; i++, pv += esize) {
                (*(vtbl->set))(aTHX_ pv, ST(i));
            }
        }
    }

void
SPLICE(self, offset, length, ...)
    SV *self;
    UV offset;
    UV length;
  PPCODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        UV esize = vtbl->element_size;
        STRLEN len;
        char *pv = SvPV(data, len);
        UV size = len / esize;
        UV rep = items - 3;
        UV i;

        if (offset > size)
            offset = size;

        if (offset + length > size)
            length = size - offset;

        check_index(aTHX_ offset + items - 3 - length, esize);
        
        switch (GIMME_V) {
        case G_ARRAY:
            EXTEND(SP, items + length);
            for (i = 0; i < length; i++)
                ST(items + i) = sv_2mortal((*(vtbl->get))(aTHX_ pv + (offset + i) * esize));
            break;
        case G_SCALAR:
            if  (length)
                ST(0) = sv_2mortal((*(vtbl->get))(aTHX_ pv + (offset + length - 1) * esize));
            else
                ST(0) = &PL_sv_undef;
        }
        
        if (rep != length) {
            if (offset == 0) {
                if (length)
                    sv_chop(data, pv + length * esize);
                if (rep) {
                    pv = my_sv_unchop(aTHX_ data, rep * esize, RESERVE_BEFORE);
                }
            }
            else {
                pv = MySvGROW(data, (size + rep - length) * esize);
                SvCUR_set(data, (size - length + rep) * esize);
                if (offset + length < size)
                    Move(pv + (offset + length) * esize,
                         pv + (offset + rep) * esize,
                         (size - offset - length) * esize, char);
            }
        }
        for (i = 0; i < rep; i++)
            (*(vtbl->set))(aTHX_ pv + (offset + i) * esize, ST(i + 3));

        switch(GIMME_V) {
        case G_ARRAY:
            for (i = 0; i< length; i++)
                ST(i) = ST(items + i);
            XSRETURN(length);
        case G_SCALAR:
            XSRETURN(1);
        default:
            XSRETURN_EMPTY;
        }
    }

char *
packer(self)
    SV *self;
CODE:
    SV *data = SvRV(self);
    struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
    RETVAL = vtbl->packer;
OUTPUT:
    RETVAL

UV
element_size(self)
    SV *self;
CODE:
    SV *data = SvRV(self);
    struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
    RETVAL = vtbl->element_size;
OUTPUT:
    RETVAL    

void
reverse(self)
    SV *self;
CODE:
    SV *data = SvRV(self);
    STRLEN len;
    char *pv = SvPV(data, len);
    IV esize = data_vtbl(aTHX_ data)->element_size;
    reverse_elements(pv, len / esize, esize);

void
rotate(self, how_much = 1)
    SV *self
    IV how_much
CODE:
    if (how_much) {
        SV *data = SvRV(self);
        STRLEN len;
        char *pv = SvPV(data, len);
        IV esize = data_vtbl(aTHX_ data)->element_size;
        IV size;
        if (esize % sizeof(int) == 0) {
            how_much *= esize / sizeof(int);
            esize = sizeof(int);
        }
        size = len / esize;
        if (how_much < 0)
            how_much += size;
        how_much %= size;
        /* printf("how_much: %d\n", how_much); */
        reverse_elements(pv, how_much, esize);
        reverse_elements(pv + how_much * esize, size - how_much, esize);
        reverse_elements(pv, size, esize);
    }

void
bsearch(self, value)
    SV *self
    SV *value
ALIAS:
    bsearch_le = 1
    bsearch_ge = 2
PPCODE:
  {
      SV *data = SvRV(self);
      struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
      UV esize = vtbl->element_size;      
      STRLEN len;
      char *pv = SvPV(data, len);
      UV a = 0;
      UV b = len / esize;
      void *value_packed;
      Newx(value_packed, esize, char);
      vtbl->set(aTHX_ value_packed, value);
      while (b > a) {
          UV pivot = (a + b) / 2;
          int cmp = vtbl->cmp(aTHX_ pv + esize * pivot, value_packed);
          if (cmp < 0)
              a = pivot + 1;
          else if (cmp > 0)
              b = pivot;
          else {
              ST(0) = sv_2mortal(newSVuv(pivot));
              XSRETURN(1);
          }
      }
      switch (ix) {
      case 1:
          if (a > 0) {
              ST(0) = sv_2mortal(newSVuv(a - 1));
              XSRETURN(1);
          }
          break;
      case 2:
          if (b < len / esize) {
              ST(0) = sv_2mortal(newSVuv(b));
              XSRETURN(1);
          }
      }
      ST(0) = &PL_sv_undef;
      XSRETURN(1);
  }

