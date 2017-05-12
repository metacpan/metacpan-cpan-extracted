/* This file is only for testing */

#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef USE_PPPORT
#include "ppport.h"
#endif


#define XS_ASSERT
#include "xs_assert.h"


MODULE = XS::Assert	PACKAGE = XS::Assert

PROTOTYPES: DISABLE

void
assert_success()
CODE:
    assert_not_null(&PL_sv_undef);

void
assert_fail()
PREINIT:
    SV* foo = NULL;
CODE:
    assert_not_null(foo);

void
assert_sv_is_av(SV* sv)
INIT:
    if(SvROK(sv)) sv = SvRV(sv);

void
assert_sv_is_hv(SV* sv)
INIT:
    if(SvROK(sv)) sv = SvRV(sv);

void
assert_sv_is_cv(SV* sv)
INIT:
    if(SvROK(sv)) sv = SvRV(sv);

void
assert_sv_is_gv(SV* sv)
INIT:
    if(SvROK(sv)) sv = SvRV(sv);


void
assert_sv_ok(SV* sv)

void
assert_sv_pok(SV* sv)

void
assert_sv_iok(SV* sv)

void
assert_sv_nok(SV* sv)

void
assert_sv_rok(SV* sv)

void
assert_sv_is_avref(SV* sv)

void
assert_sv_is_hvref(SV* sv)

void
assert_sv_is_cvref(SV* sv)

void
assert_sv_is_gvref(SV* sv)

void
assert_sv_is_object(SV* sv)

