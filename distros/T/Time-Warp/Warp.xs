#ifdef __cplusplus
extern "C" {
#endif

#define MIN_PERL_DEFINE 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
}
#endif

/* Is time() portable everywhere?  Hope so!  XXX */

static NV fallback_NVtime()
{ return time(0); }

static void fallback_U2time(U32 *ret)
{
  ret[0]=time(0);
  ret[1]=0;
}

/*-----------------*/

static int    Installed=0;
static NV (*realNVtime)();
static void   (*realU2time)(U32 *);

static double Lost;    /** time relative to now */
static double Scale;   /** speed of time (.5 == half speed) */

static void reset_warp()
{
    Lost=0;
    Scale=1;
}

/*-----------------*/

static NV warped_NVtime()
{
    return (*realNVtime)() * Scale + Lost;
}

static void warped_U2time(U32 *ret)
{
    /* performance doesn't matter enough for a native
       non-float implementation */
    double now = warped_NVtime();
    U32 unow = now;
    ret[0] = unow;
    ret[1] = (now - unow) * 1000000;
}

MODULE = Time::Warp            PACKAGE = Time::Warp

PROTOTYPES: ENABLE

void
install_time_api()
	CODE:
{
    SV **svp;
    if (Installed) {
	warn("Time::Warp::install_time_api() called more than once");
	return;
    }
    Installed=1;
    svp = hv_fetch(PL_modglobal, "Time::NVtime", 12, 0);
    if (!svp) {
	warn("Time::Warp: Time::HiRes is not loaded --\n\tat best 1s time accuracy is available");
	hv_store(PL_modglobal, "Time::NVtime", 12,
		 newSViv((IV) fallback_NVtime), 0);
	hv_store(PL_modglobal, "Time::U2time", 12,
		 newSViv((IV) fallback_U2time), 0);
    }
    svp = hv_fetch(PL_modglobal, "Time::NVtime", 12, 0);
    if (!SvIOK(*svp)) croak("Time::NVtime isn't a function pointer");
    realNVtime = (NV(*)()) SvIV(*svp);
    svp = hv_fetch(PL_modglobal, "Time::U2time", 12, 0);
    if (!SvIOK(*svp)) croak("Time::U2time isn't a function pointer");
    realU2time = (void(*)(U32*)) SvIV(*svp);
    hv_store(PL_modglobal, "Time::NVtime", 12,
	     newSViv((IV) warped_NVtime), 0);
    hv_store(PL_modglobal, "Time::U2time", 12,
	     newSViv((IV) warped_U2time), 0);

    reset_warp();
}

void
reset()
	CODE:
	reset_warp();

void
to(when)
     double when
     CODE:
{
    Lost = when - (*realNVtime)() * Scale;
}

void
scale(...)
     PREINIT:
	double new_Scale;
     PPCODE:
{
    if (items == 0) {
	XPUSHs(sv_2mortal(newSVnv(Scale)));
    } else {
	new_Scale = SvNV(ST(0));
	if (new_Scale < 0) {
	    warn("Sorry, Time::Warp cannot go backwards");
	    new_Scale = 1;
	}
	else if (new_Scale < .001) {
	    warn("Sorry, Time::Warp cannot stop time");
	    new_Scale = .001;
	}
	Lost += (*realNVtime)() * (Scale - new_Scale);
	Scale = new_Scale;
    }
}

void
time()
     PPCODE:
{
    XPUSHs(sv_2mortal(newSVnv(warped_NVtime())));
}
