#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdint.h>

#include "time_keeper_zone_abi.h"

#include "tk/tk_int.h"
#include "tk/tk_sv.h"
#include "tk/tk_civil.h"
#include "tk/tk_cal.h"
#include "tk/tk_now.h"
#include "tk/tk_zone.h"
#include "tk/tk_value.h"
#include "tk/tk_surface.h"
#include "tk/tk_now_sv.h"
#include "tk/tk_args.h"
#include "tk/tk_cal_value.h"
#include "tk/tk_duration.h"
#include "tk/tk_dur_sv.h"
#include "tk/tk_arith.h"
#include "tk/tk_arith_sv.h"
#include "tk/tk_range.h"
#include "tk/tk_locale.h"
#include "tk/tk_locale_table.h"
#include "tk/tk_locale_en.h"
#include "tk/tk_plural.h"
#include "tk/tk_locale_load.h"
#include "tk/tk_cal_meta.h"
#include "tk/tk_freeze.h"
#include "tk/tk_cal_names.h"

/* The locale of a value. */
#define tk_locale_of(v) tk_locale_get(aTHX_ (v)->locale)

#include "tk/tk_format.h"
#include "tk/tk_relative.h"
#include "tk/tk_interval.h"
#include "tk/tk_parse.h"
#include "tk/tk_parse_pat.h"
#include "tk/tk_parse_sv.h"
#include "tk/tk_cal_parse.h"
#include "tk/tk_parse_xs.h"
#include "tk/tk_plain.h"
#include "time_keeper_abi.h"
#include "tk/tk_abi_impl.h"
#include "tk/tk_abi_selftest.h"

MODULE = Time::Keeper    PACKAGE = Time::Keeper

PROTOTYPES: DISABLE

BOOT:
{
    MY_CXT_INIT;
    MY_CXT.stash = gv_stashpvs("Time::Keeper", GV_ADD);
    MY_CXT.dstash = gv_stashpvs("Time::Keeper::Duration", GV_ADD);
    MY_CXT.clock = gv_fetchpvs("Time::Keeper::CLOCK", GV_ADD, SVt_PV);
    MY_CXT.in_clock = 0;
    { int k; for (k = 1; k < TK_KIND_COUNT; k++) MY_CXT.pstash[k] = gv_stashpv(tk_plain_class[k], GV_ADD); }
#ifdef USE_ITHREADS
    {
        static int mutex_ready = 0;
        if (!mutex_ready) {
            MUTEX_INIT(&tk_locale_mutex);
            mutex_ready = 1;
        }
    }
#endif
}

INCLUDE: xs/keeper.xs
INCLUDE: xs/arith.xs
INCLUDE: xs/duration.xs
INCLUDE: xs/format.xs
INCLUDE: xs/parse.xs
INCLUDE: xs/plain.xs
INCLUDE: xs/calendar.xs
INCLUDE: xs/locale.xs
INCLUDE: xs/abi.xs
INCLUDE: xs/civil.xs
INCLUDE: xs/leap.xs
INCLUDE: xs/test.xs
