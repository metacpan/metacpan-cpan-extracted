/*
    Text-ClearSilver.h - XSUBs for Text::ClearSilver

    Copyright(c) 2010 Craftworks. All rights reserved.

    See lib/Text/ClearSilver.pm for details.
*/

#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"

#ifndef LIKELY
#if defined(__GNUC__)
#define HAS_BUILTIN_EXPECT
#endif

/* stolen from perl.h, 5.12.0 */
#ifdef HAS_BUILTIN_EXPECT
#  define EXPECT(expr,val)                  __builtin_expect(expr,val)
#else
#  define EXPECT(expr,val)                  (expr)
#endif

#define LIKELY(cond)                        EXPECT(cond, 1)
#define UNLIKELY(cond)                      EXPECT(cond, 0)
#endif /* ifndef LIKELY */

/* Need raw malloc(3) that must be what ClearSilver uses */
#undef malloc
#undef strdup
#undef strndup

#include "ClearSilver.h"

#define C_HDF "Text::ClearSilver::HDF"
#define C_CS  "Text::ClearSilver::CS"

/* for typemap */
typedef HDF*     Text__ClearSilver__HDF;
typedef CSPARSE* Text__ClearSilver__CS;

#define hdf_DESTROY(p) hdf_destroy(&(p))
#define cs_DESTROY(p)  cs_destroy(&(p))

#define CHECK_ERR(e) STMT_START{ \
        NEOERR* const check_error_value = (e); \
        if(UNLIKELY(check_error_value != STATUS_OK)) tcs_throw_error(aTHX_ check_error_value); \
    }STMT_END

void
tcs_throw_error(pTHX_ NEOERR* const err);

void*
tcs_get_struct_ptr(pTHX_ SV* const arg, const char* const klass,
        const char* const func_fq_name, const char* var_name);

void
tcs_register_funcs(pTHX_ CSPARSE* const cs, HV* const funcs);

NEOERR*
tcs_parse_sv(pTHX_ CSPARSE* const parse, SV* const sv);

/* HDF */
HDF*
tcs_new_hdf(pTHX_ SV* const sv);
void
tcs_hdf_add(pTHX_ HDF* const hdf, SV* const sv, bool const utf8);


/* CS */
NEOERR*
tcs_output_to_io(void* io, char* s);

NEOERR*
tcs_output_to_sv(void* io, char* s);

/* MY_CXT stuff */
typedef struct {
    HV* functions;
    SV* sort_cmp_cb;

    HV* file_cache;
    const char* input_layer;
    bool utf8;

    bool function_set_is_loaded;
} my_cxt_t;

my_cxt_t*
tcs_get_my_cxtp(pTHX);

