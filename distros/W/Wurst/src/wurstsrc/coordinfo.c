/* coordinfo.c
 * To get some information out of the coord structure
 * (for scripting/manipulation rather than threading)
 *
 * $Id: coordinfo.c,v 1.1 2007/09/28 16:57:04 mmundry Exp $
 */

#include <limits.h>
#include <stdio.h>
#include <stdlib.h>

#include "mprintf.h"
#include "e_malloc.h"
#include "coord.h"
#include "sec_s.h"

#include "sec_s_i.h"
#include "coordinfo_i.h"

/* coord_get_sec_s
 * Returns a string with the secondary structure assignment for each residue
 */
char *
coord_get_sec_s (struct coord *c) {

    /* From coordio routine */
    if (c==NULL) {
        err_printf("coord_get_sec_s","Script bug? Null Coord\n");
        return NULL;
    }

    if (c->size && c->sec_typ) {  /* Internally, secondary structure is an enumerated */
        size_t i;      /* type. For the output, we have to convert */
        char *a;       /* to a string array */
        a = E_MALLOC (sizeof (*a) * (1+c->size));
        for ( i = 0; i < c->size; i++)
            a[i] = ss2char (c->sec_typ[i]);
        a[c->size]='\0';
        return a;
    }
    return NULL;
}

