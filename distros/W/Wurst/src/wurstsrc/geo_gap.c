/*
 * 20 May 2002
 * $Id: geo_gap.c,v 1.1 2007/09/28 16:57:05 mmundry Exp $
 */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include "coord.h"
#include "geo_gap.h"
#include "mprintf.h"

/* ---------------- Constants --------------------------------
 */
static const float R_CN = 1.32;  /* Ideal bond distance */
static const float TRIG = 2.0;   /* Minimum dist to worry about. Below
                             this, there is no gap */
/* ---------------- coord_geo_gap -----------------------------
 * Implement gap penalties for a sequence to structure alignment,
 * based on geometry of model.
 * c is the coordinate set we are looking at.
 * scale is a coefficient which we multiply our final result by.
 * max is the maximum distance. This is a cap. If the calculated
 * distance is more than max, treat it as max.
 * In the code (hardwired), if the C..N distance is less than
 * TRIG (2.0 Angstrom), do not treat it as a gap.
 * num_gap is a pointer into which we return the number of gaps.
 * We want to give the caller several numbers back
 *   gap penalty using quadratic penalties
 *               using linear penalties
 *               using crazy logistic function (rising part)
 *   the number of gaps
 * To see what our logistic function looks like, feed this to gnuplot:
     c1 = 2;
     c2 = 4;
     f(x) = 1. / (1. + c2 * exp (c1 - ( (x < 1.8) ? 0 : x)));
     set xrange [0:15]
     plot f(x);
 * More notes..
 * Some example gap sizes from real structures
 *  gap in residues / gap in Angstrom
 *  1  / 3 to 3.5
 *  2  / 4.2 to about 7
 *  3  / Anywhere from 4 to 9
 */
int
coord_geo_gap (struct coord *c,
               float *quadratic, float *linear, float *logistic,
               unsigned int *num_gap, const float scale, const float max)
{
    const char *this_sub = "coord_geo_gap";
    struct RPoint *rn = c->rp_n + 1;
    struct RPoint *rc = c->rp_c;
    struct RPoint *rclast;
    unsigned ngap = 0;
    float quad    = 0.0;
    float lin     = 0.0;
    float logi    = 0.0;
    const float TRIG2 = TRIG * TRIG;  /* Don't worry. This is optimised away */
    const float max2 = max * max;
    const float k1 = 0.0,
                k2 = 1;
    if (c->size < 2) {
        err_printf (this_sub, "Coordinates too small ( < 2 residues)\n");
        return EXIT_FAILURE;
    }
    rclast = rc + c->size - 1;
    for ( ; rc < rclast; rc++, rn++) {
        float x = rc->x - rn->x;
        float y = rc->y - rn->y;
        float z = rc->z - rn->z;
        float d2 = (x * x) + (y * y) + (z * z);
        float d;
        if (d2 < TRIG2)       /* If dist is less than our threshold */
            continue;         /* there is no penalty */

        if (d2 > max2) {      /* If distance is too big, then just use */
            d2 = max2;        /* the maximum we were given. */
            d  = max;
        } else {
            d = sqrt (d2);    /* Real distance between atoms */
        }
        ngap++;             /* Whatever happens, we track the number of gaps */
        d -= R_CN;                                  /* This is our violation */
        logi += 1 / (1 + k2 * exp (k1 - d/2 ));   /* logistic function */
        lin  += d;
        quad += (d * d);
    }

    *num_gap   = ngap;            /* These are really the return values */
    *quadratic = quad * scale;
    *linear    = lin  * scale;
    *logistic  = logi * scale;
    return EXIT_SUCCESS;
}
