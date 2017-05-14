/* akbox_fn.c  -  Application Black (K) Box hash function
 * Copyright (c) 2006,2012 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing. See file COPYING.
 * Special grant: akbox.h may be used with zxid open source project under
 * same licensing terms as zxid itself.
 * $Id$
 *
 * 15.4.2006, created over Easter holiday --Sampo
 * 16.8.2012, modified license grant to allow use with ZXID.org --Sampo
 */

#include <string.h>

/* This redefinition of sizeof(x) is deliberate and is meant to cause the
 * AKBOX_FN macro, see akbox.h, to expand in this function such that it uses
 * runtime string length rather than compile time sizeof. */
#define sizeof(x) (siz)
#include "akbox.h"

int akbox_fn(const char* fn)
{
  int siz = strlen(fn)+1;
  return AKBOX_FN(fn);
}

/* EOF - akbox_fn.c */
