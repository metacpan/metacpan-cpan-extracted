#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdint.h>

#include "time_keeper_abi.h"

#include "tks/tks_int.h"
#include "tks/tks_xsub.h"
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
#include "tks/tks_vsop.h"
#include "tks/tks_planet.h"
#include "tks/tks_config.h"
#include "tks/tks_star.h"
#include "tks/tks_eclipse.h"
#include "tks/tks_solar.h"
#include "tks/tks_track.h"
#include "tks/tks_tonight.h"
#include "tks/tks_seasons.h"
#include "tks/tks_places.h"
#include "tks/tks_place_find.h"

MODULE = Time::Keeper::Sky    PACKAGE = Time::Keeper::Sky

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
    MY_CXT.stash = gv_stashpvs("Time::Keeper::Sky", GV_ADD);
    MY_CXT.pstash = gv_stashpvs("Time::Keeper::Sun", GV_ADD);
    MY_CXT.dstash = gv_stashpvs("Time::Keeper::Sun::Day", GV_ADD);
    MY_CXT.mstash = gv_stashpvs("Time::Keeper::Moon::Day", GV_ADD);
    MY_CXT.ystash = gv_stashpvs("Time::Keeper::Planet::Day", GV_ADD);
    MY_CXT.sstash = gv_stashpvs("Time::Keeper::Star::Day", GV_ADD);
    MY_CXT.estash = gv_stashpvs("Time::Keeper::Eclipse", GV_ADD);
    MY_CXT.lstash = gv_stashpvs("Time::Keeper::Eclipse::Local", GV_ADD);
    MY_CXT.cons_jq = 0.0;
    (void)tks_star_hr_index(1);     /* fill the HR table here, not in a thread */
    tks_cons_init();
    /* a planet's and a star's day share their methods */
    tks_isa(aTHX_ "Time::Keeper::Planet::Day", "Time::Keeper::Body::Day");
    tks_isa(aTHX_ "Time::Keeper::Star::Day", "Time::Keeper::Body::Day");
    /* a Time::Keeper::Sun is a Sky; 0.01 and 0.02 defined these methods in
     * Time::Keeper::Sun, and a program may call one by its full name */
    {
        static const char *const sun_methods[] = {
            "new", "latitude", "longitude", "elevation", "zone_name", "locale", "position", "track",
            "sub_point", "on", "next_sunrise", "next_sunset", "previous_sunrise", "previous_sunset",
            "next_solar_noon", "previous_solar_noon", "next_dawn", "next_dusk", "previous_dawn",
            "previous_dusk", "equinox", "solstice", "seasons", "place_of", "places",
            "places_release", "delta_t", NULL,
        };
        tks_isa(aTHX_ "Time::Keeper::Sun", "Time::Keeper::Sky");
        tks_xsubs_share(aTHX_ "Time::Keeper::Sky", "Time::Keeper::Sun", sun_methods);
    }
}

void
CLONE(...)
    CODE:
        PERL_UNUSED_VAR(items);
        {
            MY_CXT_CLONE;
            MY_CXT.stash = gv_stashpvs("Time::Keeper::Sky", GV_ADD);
            MY_CXT.pstash = gv_stashpvs("Time::Keeper::Sun", GV_ADD);
            MY_CXT.dstash = gv_stashpvs("Time::Keeper::Sun::Day", GV_ADD);
            MY_CXT.mstash = gv_stashpvs("Time::Keeper::Moon::Day", GV_ADD);
            MY_CXT.ystash = gv_stashpvs("Time::Keeper::Planet::Day", GV_ADD);
            MY_CXT.sstash = gv_stashpvs("Time::Keeper::Star::Day", GV_ADD);
            MY_CXT.estash = gv_stashpvs("Time::Keeper::Eclipse", GV_ADD);
            MY_CXT.lstash = gv_stashpvs("Time::Keeper::Eclipse::Local", GV_ADD);
        }

INCLUDE: xs/sun.xs
INCLUDE: xs/day.xs
INCLUDE: xs/moon.xs
INCLUDE: xs/planet.xs
INCLUDE: xs/star.xs
INCLUDE: xs/eclipse.xs
INCLUDE: xs/tonight.xs
INCLUDE: xs/test.xs
