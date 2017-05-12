/* -------------------------------------------------------------------
   nsapi_perl.c - utility functions for nsapi_perl

   Copyright (C) 1997, 1998 Benjamin Sugars

   This is free software; you can redistribute it and/or modify it
   under the same terms as Perl itself.

   This software is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this software. If not, write to the Free Software
   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
   ------------------------------------------------------------------- */

#include "base/util.h"
#include "base/pblock.h"
#include "base/session.h"
#include "base/cinfo.h"
#ifdef NP_THREAD_SAFE
#include "base/crit.h"
#endif
#include "frame/req.h"
#include "frame/log.h"
#include "frame/protocol.h"
#include <EXTERN.h>
#include <perl.h>
#include <string.h>
#include "nsapi_perl.h"

/*
 * nsapi_perl_pblock2hash_ref() - converts a NSAPI pblock to
 *              a perl hash. Returns reference to the hash.
 */

NSAPI_PUBLIC SV* nsapi_perl_pblock2hash_ref(pblock * pb)
{
    char *key;
    char **pblock_contents;
    HV *pblock;
    SV *value, *pblock_ref;
    int i, len;

    /* Mortalize the pblock hash */
    pblock = newHV();
    sv_2mortal((SV *) pblock);

    /* Shove the pb into an array of strings */
    pblock_contents = pblock_pb2env(pb, NULL);

    /* Loop through each string in pblock_contents */
    for (; *pblock_contents != NULL; ++pblock_contents) {
	len = strlen(*pblock_contents);

	/* Look for an '=' sign in the string */
	for (i = 0; i < len && *(*pblock_contents + i) != '='; i++);
	if (i == len)
	    continue;

	/* Split on the '=' */
	*(*pblock_contents + i) = '\0';
	key = *pblock_contents;
	value = sv_newmortal();
	sv_setpv(value, *pblock_contents + i + 1);

	/* Store the key/value pair */
	if (hv_store(pblock, key, strlen(key), value, 0))
	    /* Increment the reference count of the hash elements */
	    (void) SvREFCNT_inc(value);

    }

    /* Create the reference to the hash */
    pblock_ref = newRV((SV *) pblock);
    return (sv_2mortal(pblock_ref));
}

