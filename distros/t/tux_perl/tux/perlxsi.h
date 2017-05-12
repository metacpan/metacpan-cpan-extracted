/*
 * This code is a part of tux_perl, and is released under the GPL.
 * Copyright 2002 by Yale Huang<mailto:yale@sdf-eu.org>.
 * See README and COPYING for more information, or see
 *   http://tux-perl.sourceforge.net/.
 *
 * $Id: perlxsi.h,v 1.2 2002/11/11 11:17:02 yaleh Exp $
 */

#ifndef __PERLXSI_H
#define __PERLXSI_H

#if defined (__cplusplus)
extern "C" {
#endif

#include <EXTERN.h>
#include <perl.h>

EXTERN_C void xs_init(pTHXo);

#if defined (__cplusplus)
}
#endif

#endif
