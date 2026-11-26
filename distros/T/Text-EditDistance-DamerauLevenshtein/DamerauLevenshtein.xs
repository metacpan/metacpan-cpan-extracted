#ifdef __GNUC__
 #if __GNUC__ >= 5
  #define IF_HAVE_GCC_5(X) X
 #endif

 #if (__GNUC__ == 4 && __GNUC_MINOR__ >= 6) || __GNUC__ >= 5
  #define PRAGMA_GCC_(X) _Pragma(#X)
  #define PRAGMA_GCC(X) PRAGMA_GCC_(GCC X)
 #endif
#endif

#ifndef IF_HAVE_GCC_5
 #define IF_HAVE_GCC_5(X)
#endif

#ifndef PRAGMA_GCC
 #define PRAGMA_GCC(X)
#endif

#ifdef DEVEL
 #define WARNINGS_RESET PRAGMA_GCC(diagnostic pop)
 #define WARNINGS_ENABLEW(X) PRAGMA_GCC(diagnostic error #X)
 #define WARNINGS_ENABLE \
    WARNINGS_ENABLEW(-Wall) \
    WARNINGS_ENABLEW(-Wextra) \
    WARNINGS_ENABLEW(-Wundef) \
    WARNINGS_ENABLEW(-Wshadow) \
    WARNINGS_ENABLEW(-Wbad-function-cast) \
    WARNINGS_ENABLEW(-Wcast-align) \
    WARNINGS_ENABLEW(-Wwrite-strings) \
    WARNINGS_ENABLEW(-Wstrict-prototypes) \
    WARNINGS_ENABLEW(-Wmissing-prototypes) \
    WARNINGS_ENABLEW(-Winline) \
    WARNINGS_ENABLEW(-Wdisabled-optimization) \
    IF_HAVE_GCC_5(WARNINGS_ENABLEW(-Wnested-externs))

#else
 #define WARNINGS_RESET
 #define WARNINGS_ENABLE
#endif

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <errno.h>
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>

#ifdef DEVEL
#undef NDEBUG
#include <assert.h>
#endif

WARNINGS_ENABLE

#define X_FN_NAME distance_bytes
#define X_IS_CONTINUATION(X) 0
#define X_LENGTH(P, P_END) ((P_END) - (P))
#define X_CHARBYTES(X, Y) 1
#define X_CHAR_EQ(PX, NX, PY, NY) (*(PX) == *(PY))
#include "xedistance.h"

// work around perl core bug https://github.com/Perl/perl5/issues/25120
#undef UTF8_SAFE_SKIP

#ifndef UTF8_SAFE_SKIP
static size_t utf8_skip(pTHX_ const char *p, const char *p_end) {
    assert(p <= p_end);
    if (p >= p_end) {
        return 0;
    }
    size_t r = p_end - p, s = UTF8SKIP(p);
    return r < s ? r : s;
}
#define UTF8_SAFE_SKIP(P, P_END) utf8_skip(aTHX_ P, P_END)
#endif

#define X_FN_NAME distance_utf8
#define X_IS_CONTINUATION(C) UTF8_IS_CONTINUATION(C)
#define X_LENGTH(P, P_END) utf8_length((const unsigned char *)(P), (const unsigned char *)(P_END))
#define X_CHARBYTES(P, P_END) UTF8_SAFE_SKIP(P, P_END)
#define X_CHAR_EQ(PX, NX, PY, NY) ((NX) == (NY) && memEQ(PX, PY, NX))
#include "xedistance.h"

WARNINGS_RESET

MODULE = Text::EditDistance::DamerauLevenshtein PACKAGE = Text::EditDistance::DamerauLevenshtein
PROTOTYPES: DISABLE

size_t
dl_distance(SV *from, SV *to)
    CODE:
        size_t from_len;
        const char *pv_from = SvPV(from, from_len);
        bool from_is_utf8 = !!SvUTF8(from);
        size_t to_len;
        const char *pv_to = SvPV(to, to_len);
        switch (from_is_utf8 << 1 | (from_is_utf8 == !!SvUTF8(to))) {
            case 0 << 1 | 1:
                RETVAL = distance_bytes(aTHX_ pv_from, pv_from + from_len, pv_to, pv_to + to_len);
                break;
            case 0 << 1 | 0:
                from = newSVpvn_flags(pv_from, from_len, SVs_TEMP);
                from_len = sv_utf8_upgrade_nomg(from);
                pv_from = SvPVX_const(from);
                if (0)
            case 1 << 1 | 0: {
                to = newSVpvn_flags(pv_to, to_len, SVs_TEMP);
                to_len = sv_utf8_upgrade_nomg(to);
                pv_to = SvPVX_const(to);
            }
            case 1 << 1 | 1:
                RETVAL = distance_utf8(aTHX_ pv_from, pv_from + from_len, pv_to, pv_to + to_len);
                break;
        }
        if (RETVAL == SIZE_MAX) {
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL
