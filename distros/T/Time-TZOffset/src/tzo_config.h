#ifndef _tzo_config_h_
#define _tzo_config_h_

#include "config.h"

#if __STDC_VERSION__ < 199901L
#define restrict /* nothing */
#endif

#ifdef HAS_TM_TM_GMTOFF
#define HAVE_TM_GMTOFF 1
#endif

#ifdef HAS_GMTIME_R
#define HAVE_GMTIME_R 1
#endif

#ifdef HAS_LOCALTIME_R
#define HAVE_LOCALTIME_R 1
#endif

#endif

