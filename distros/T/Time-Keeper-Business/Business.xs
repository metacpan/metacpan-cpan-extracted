#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdint.h>

#include "time_keeper_abi.h"
#include "tkb/tkb_abi.h"
#include "tkb/tkb_civil.h"
#include "tkb/tkb_schedule.h"
#include "tkb/tkb_value.h"
#include "tkb/tkb_build.h"
#include "tkb/tkb_rule.h"
#include "tkb/tkb_sources.h"
#include "tkb/tkb_days.h"
#include "tkb/tkb_hours.h"
#include "tkb/tkb_time.h"

#define MY_CXT_KEY "Time::Keeper::Business::_guts" XS_VERSION

typedef struct {
    HV *stash;        /* Time::Keeper */
    HV *dstash;       /* Time::Keeper::Date */
    HV *ymstash;      /* Time::Keeper::YearMonth */
    HV *durstash;     /* Time::Keeper::Duration */
    HV *bstash;       /* Time::Keeper::Business */
} my_cxt_t;

START_MY_CXT

static void
tkb_cxt_stashes(pTHX_ my_cxt_t *cxt)
{
    cxt->stash    = gv_stashpvs("Time::Keeper", GV_ADD);
    cxt->dstash   = gv_stashpvs("Time::Keeper::Date", GV_ADD);
    cxt->ymstash  = gv_stashpvs("Time::Keeper::YearMonth", GV_ADD);
    cxt->durstash = gv_stashpvs("Time::Keeper::Duration", GV_ADD);
    cxt->bstash   = gv_stashpvs("Time::Keeper::Business", GV_ADD);
}

MODULE = Time::Keeper::Business    PACKAGE = Time::Keeper::Business

PROTOTYPES: DISABLE

BOOT:
{
    MY_CXT_INIT;
    tkb_vtbl_init();
    tkb_rule_vtbl_init();
    tkb_cxt_stashes(aTHX_ &MY_CXT);
}

void
CLONE(...)
    CODE:
        PERL_UNUSED_VAR(items);
        MY_CXT_CLONE;
        tkb_cxt_stashes(aTHX_ &MY_CXT);

INCLUDE: xs/schedule.xs
INCLUDE: xs/days.xs
INCLUDE: xs/hours.xs
INCLUDE: xs/rule.xs
INCLUDE: xs/test.xs
