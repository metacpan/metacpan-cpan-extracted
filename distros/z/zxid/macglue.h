/* macglue.h  -  Define couple of things that Mac evidently misses. ARG!
 *
 * Copyright (c) 1999 Sampo Kellomaki <sampo@iki.fi>, All Rights Reserved.
 * License: This software may be distributed under the same license
 *          terms as openssl (i.e. free, but mandatory attribution).
 *          See file LICENSE for details.
 *
 * 26.9.1999, Created. --Sampo
 */
 
#ifdef __macintosh__

#include <string.h>
#include <stdlib.h>

/* Why do we have to reinvent the wheel? */

static char*
strdup(const char* s)
{
	char* x = malloc(strlen(s)+1);
	if (!x) return NULL;
	strcpy(x, s);
	return x;
}

#endif

/* EOF  -  macglue.h */
