/*
 * 24 Oct 2001
 * Secondary structure routines.
 * Only these routines know the details of secondary structure stuff.
 * $Id: sec_s.c,v 1.1 2007/09/28 16:57:07 mmundry Exp $
 */

#include <stdio.h>
#include <string.h>

#include "mprintf.h"
#include "coord.h"
#include "e_malloc.h"
#include "sec_s.h"
#include "sec_s_i.h"

/* ---------------- char2ss   ---------------------------------
 * Helper for add_man_s.  Given a single character from DSSP,
 * return the enumerated type for the secondary structure.
 * Actually, we only return an int.
 */
int
char2ss ( char c)
{
    const char *this_sub = "char2ss";
    switch (c){
    case 'h':
    case 'H':
        return HELIX;
    case 'e':
    case 'E':
        return EXTEND;
    case 's':
    case 'S':
        return BEND;
    case 'b':
    case 'B':
        return B_BRIDGE;
    case 'i':
    case 'I':
        return PI_HELIX;
    case 'g':
    case 'G':
        return TT_HELIX;
    case 't':
    case 'T':
        return TURN;
    case '-':
    case ' ':
        return NO_SEC;
    default:
        err_printf(this_sub, "Incorrect input, char %c\n", c);
        return ERROR;
    }
}

/* ---------------- ss2char   ---------------------------------
 */
char
ss2char (int sec_typ)
{
    switch ((enum sec_typ) sec_typ) {
    case HELIX:    return 'H';
    case EXTEND:   return 'E';
    case BEND:     return 'S';
    case B_BRIDGE: return 'B';
    case PI_HELIX: return 'I';
    case TT_HELIX: return 'G';
    case TURN:     return 'T';
    case NO_SEC:   return '-';
    case ERROR:    
    default:
        err_printf ("ss2char", "Unknown sec struct, %d\n", sec_typ);
    }
    return '?';
}

/* ---------------- coord_2_pnlty   ---------------------------
 * Given a set of coordinates, return an array containing
 * coefficients for extra gap penalties.
 */
float *
coord_2_pnlty ( struct coord *c, float value)
{
    size_t i;
    float *mult = E_MALLOC (c->size * sizeof(mult[0]));
    const float diff = value - 1;
    const float diff2 = diff / 2.0;
    const float diff4 = diff / 4.0;
    const char *this_sub = "coord_2_pnlty";


    {
        float *p = mult;
        float *last = mult + c->size;
        for ( p = mult; p < last; p++)  /* This is default, every place */
            *p = 1;                      /* gets a coefficient of 1.0 */
    }
    if ( value == 0.0) {
        /* no work to do */; 
    } else if (c->sec_typ == NULL) {
        char t[8];
        strncpy (t, c->pdb_acq, 4);
        t[4] = c->chain;
        t[5] = '\0';
        err_printf (this_sub, "warning no secondary struct inf in %s\n", t);
    } else {
        float *curr, *last;  /* Current and last of coefficient array */
        float *pred, *succ;  /* Predecessor and successors in array */
        size_t end;
        enum sec_typ tmp_typ = c->sec_typ[0];  /* Special case start array */
        if ((tmp_typ == HELIX) || (tmp_typ == EXTEND)) {
            mult[0] += diff2;
            mult[1] += diff4;
        }

        curr = mult + 1;
        pred = curr - 1;
        succ = curr + 1;
        last = mult + c->size - 1;
        for (i = 1; curr < last; i++, curr++, pred++, succ++) {
            enum sec_typ sec_t = c->sec_typ [i];
            if ((sec_t == HELIX)  || (sec_t == EXTEND)) {
                *pred += diff4;
                *curr += diff2;
                *succ += diff4;
            }
        }
        end = c->size - 1;
        tmp_typ = c->sec_typ[end]; /* Special case, end of array */
        if ((tmp_typ == HELIX) || (tmp_typ == EXTEND)) {
            mult[end - 1] += diff4;
            mult[end]     += diff2;
        }
    }
    return mult;
}
