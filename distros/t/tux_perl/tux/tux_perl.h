/*
 * This code is a part of tux_perl, and is released under the GPL.
 * Copyright 2002 by Yale Huang<mailto:yale@sdf-eu.org>.
 * See README and COPYING for more information, or see
 *   http://tux-perl.sourceforge.net/.
 *
 * $Id: tux_perl.h,v 1.2 2002/11/11 11:17:02 yaleh Exp $
 */

#ifndef __TUX_PERL_H
#define __TUX_PERL_H

#define TP_DEBUG 1

#ifdef TP_DEBUG
#define TP_LOG(x...) do{ fprintf(stderr,x); fflush(stderr); } while(0)
#else
#define TP_LOG(x...) do{} while(0)
#endif

#endif
