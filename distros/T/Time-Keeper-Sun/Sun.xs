#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdint.h>

#include "time_keeper_abi.h"

#include "tks/tks_int.h"
#include "tks/tks_tk.h"
#include "tks/tks_names.h"
#include "tks/tks_time.h"
#include "tks/tks_sv.h"
#include "tks/tks_sun.h"
#include "tks/tks_civil.h"
#include "tks/tks_moonpos.h"
#include "tks/tks_rise.h"
#include "tks/tks_day_sv.h"
#include "tks/tks_args.h"
#include "tks/tks_moon.h"
#include "tks/tks_seasons.h"
#include "tks/tks_places.h"
#include "tks/tks_place_find.h"

MODULE = Time::Keeper::Sun    PACKAGE = Time::Keeper::Sun

PROTOTYPES: DISABLE

BOOT:
{
    MY_CXT_INIT;
#ifdef USE_ITHREADS
    {
        static int names_mutex_ready = 0;
        if (!names_mutex_ready) {
            MUTEX_INIT(&tks_names_mutex);
            names_mutex_ready = 1;
        }
    }
#endif
    MY_CXT.stash = gv_stashpvs("Time::Keeper::Sun", GV_ADD);
    MY_CXT.pstash = MY_CXT.stash;
    MY_CXT.dstash = gv_stashpvs("Time::Keeper::Sun::Day", GV_ADD);
    MY_CXT.mstash = gv_stashpvs("Time::Keeper::Moon::Day", GV_ADD);
}

void
CLONE(...)
    CODE:
        PERL_UNUSED_VAR(items);
        {
            MY_CXT_CLONE;
            MY_CXT.stash = gv_stashpvs("Time::Keeper::Sun", GV_ADD);
            MY_CXT.pstash = MY_CXT.stash;
            MY_CXT.dstash = gv_stashpvs("Time::Keeper::Sun::Day", GV_ADD);
            MY_CXT.mstash = gv_stashpvs("Time::Keeper::Moon::Day", GV_ADD);
        }

INCLUDE: xs/sun.xs
INCLUDE: xs/day.xs
INCLUDE: xs/moon.xs
INCLUDE: xs/test.xs
