#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>

#define MY_CXT_KEY "Time::Keeper::Recurrence::_guts" XS_VERSION

#include "time_keeper_abi.h"
#include "time_keeper_zone_abi.h"
#include "tkr/tkr_abi_in.h"
#include "tkr/tkr_civil.h"
#include "tkr/tkr_rule.h"
#include "tkr/tkr_rrule.h"
#include "tkr/tkr_cron.h"
#include "tkr/tkr_describe.h"
#include "tkr/tkr_obj.h"
#include "tkr/tkr_zone.h"
#include "tkr/tkr_walk.h"
#include "tkr/tkr_walk_sv.h"
#include "tkr/tkr_set.h"
#include "tkr/tkr_ical.h"
#include "tkr/tkr_set_sv.h"
#include <math.h>
#include "time_keeper_recurrence_abi.h"
#include "tkr/tkr_abi_impl.h"
#include "tkr/tkr_abi_selftest.h"

typedef struct {
    HV *stash;          /* Time::Keeper::Recurrence's */
    HV *set_stash;      /* Time::Keeper::Recurrence::Set's */
} my_cxt_t;
START_MY_CXT

static HV *tkr_rule_stash(pTHX) { dMY_CXT; return MY_CXT.stash; }
static HV *tkr_set_stash(pTHX) { dMY_CXT; return MY_CXT.set_stash; }

/* The stash to bless into: the class named, or the rule's own. */
static HV *
tkr_stash_for(pTHX_ SV *class_or_obj)
{
    dMY_CXT;
    if (SvROK(class_or_obj))
        return SvSTASH(SvRV(class_or_obj));
    if (SvPOK(class_or_obj)) {
        HV *st = gv_stashsv(class_or_obj, 0);
        if (st)
            return st;
    }
    return MY_CXT.stash;
}

MODULE = Time::Keeper::Recurrence    PACKAGE = Time::Keeper::Recurrence

PROTOTYPES: DISABLE

BOOT:
{
    MY_CXT_INIT;
    MY_CXT.stash = gv_stashpvs("Time::Keeper::Recurrence", GV_ADD);
    MY_CXT.set_stash = gv_stashpvs("Time::Keeper::Recurrence::Set", GV_ADD);
    tkr_tk(aTHX);
}

void
CLONE(...)
    CODE:
    {
        MY_CXT_CLONE;
        MY_CXT.stash = gv_stashpvs("Time::Keeper::Recurrence", GV_ADD);
        MY_CXT.set_stash = gv_stashpvs("Time::Keeper::Recurrence::Set", GV_ADD);
        PERL_UNUSED_VAR(items);
    }

INCLUDE: xs/abi_in.xs
INCLUDE: xs/rule.xs
INCLUDE: xs/walk.xs
INCLUDE: xs/set.xs
INCLUDE: xs/abi.xs
