#define PERL_NO_GET_CONTEXT
/* Under PERL_IMPLICIT_SYS (every Strawberry perl) XSUB.h rewrites plain
 * fopen/fgets/fclose into PerlSIO_ macros that need an interpreter. The
 * headers below are plain C with no interpreter to hand, so keep the
 * names as the C library's. */
#define NO_XSLOCKS
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef G_LIST
#  define G_LIST G_ARRAY
#endif

#include "time_keeper_zone_abi.h"
#include "tkz/tkz_types.h"
#include "tkz/tkz_data.h"
#include "tkz/tkz_engine.h"
#include "tkz/tkz_local.h"
#include "tkz/tkz_abi_impl.h"
#include "tkz/tkz_dump.h"

/* A method's zone argument: its id, or a croak naming it. */
static int
tkz_sv_zone(pTHX_ SV *name)
{
    STRLEN len;
    const char *p;
    int id;
    if (!SvOK(name))
        croak("Time::Keeper::Zone: no zone name given");
    p = SvPV(name, len);
    id = tkz_lookup_name(p, len);
    if (id < 0)
        croak("Time::Keeper::Zone: unknown time zone '%" SVf "'", SVfARG(name));
    return id;
}

/* A method's epoch argument, floored to the second: a fraction belongs to
 * the second it falls in. About three billion years either way. */
static int64_t
tkz_sv_epoch(pTHX_ SV *sv)
{
    NV n;
    if (SvIOK(sv) && !SvIsUV(sv))
        n = (NV)SvIV(sv);
    else
        n = SvNV(sv);
    if (!(n >= -1e17 && n <= 1e17))
        croak("Time::Keeper::Zone: epoch %" NVgf " is out of range", n);
    if (SvIOK(sv) && !SvIsUV(sv))
        return (int64_t)SvIV(sv);
    return (int64_t)Perl_floor(n);
}

MODULE = Time::Keeper::Zone    PACKAGE = Time::Keeper::Zone

PROTOTYPES: DISABLE

INCLUDE: xs/zone.xs
INCLUDE: xs/abi.xs
INCLUDE: xs/data.xs
INCLUDE: xs/engine.xs
INCLUDE: xs/rules.xs
INCLUDE: xs/test.xs
