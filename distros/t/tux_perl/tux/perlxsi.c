/*
 * This code is a part of tux_perl, and is released under the GPL.
 * Copyright 2002 by Yale Huang<mailto:yale@sdf-eu.org>.
 * See README and COPYING for more information, or see
 *   http://tux-perl.sourceforge.net/.
 *
 * $Id: perlxsi.c,v 1.2 2002/11/11 11:17:02 yaleh Exp $
 */

#include <EXTERN.h>
#include <perl.h>
#include "perlxsi.h"

EXTERN_C void xs_init (pTHXo);

EXTERN_C void boot_DynaLoader (pTHXo_ CV* cv);

EXTERN_C void
xs_init(pTHXo)
{
  char *file = __FILE__;
  dXSUB_SYS;

  /* DynaLoader is a special case */
  newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file); 
}
