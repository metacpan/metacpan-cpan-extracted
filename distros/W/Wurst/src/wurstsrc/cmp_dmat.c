/*
 * 6 Dec 2001
 *
 * For calculating and comparing alpha carbon-based distance
 * matrices.
 * The main complication is that the model and reference
 * structure are usually different sizes, so the calculation is
 * done on the common sites, marked in the "mask" array.
 *
 * $Id: cmp_dmat.c,v 1.1 2007/09/28 16:57:03 mmundry Exp $
 */


#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "cmp_dmat_i.h"
#include "coord.h"
#include "e_malloc.h"

/* ---------------- local structures --------------------------
 */
struct dmat {
    float  *d;            /* Actual distance matrix */
    size_t n;             /* num atoms */
    size_t sz;            /* Size = (n(n-1))/2 for triangular matrices */
};

struct dme_res {
    float dme;            /* Distance matrix error */
    size_t sz;            /* size of DME matrix */
    size_t n_left;        /* After iterating, how many are left */
};

/* ---------------- alloc_dmat --------------------------------
 */
static struct dmat *
alloc_dmat (struct dmat *dm, size_t n)
{
    size_t tomall;
    dm->n = n;
    dm->sz = (n * (n - 1)) / 2;
    tomall = dm->sz * sizeof (dm->d[0]);
    dm->d = E_MALLOC (tomall);
    memset (dm->d, 0, tomall);
    return dm;
}

/* ---------------- del_dmat ----------------------------------
 */
static void
del_dmat (struct dmat *dm)
{
    dm->sz = 0;
    dm->n = 0;
    free (dm->d);
}

/* ---------------- flt_compar --------------------------------
 */
static int
flt_compar (const void *p, const void *q)
{
    const float f1 = *(float *)p;
    const float f2 = *(float *)q;
    if ( f1 > f2)
        return -1;
    if ( f1 < f2)
        return 1;
    return 0;
}

/* ---------------- get_dme    --------------------------------
 */
static struct dme_res
get_dme (const struct dmat d1, const struct dmat d2, float thresh)
{
    float *f1, *f2, *last;
    float sum = 0;
    struct dme_res result;
    memset (&result, 0, sizeof (result));
    result.sz = d1.sz;
    result.n_left = d1.sz;
    last = d1.d + d1.sz;
    if ( d1.n < 2 ) {
        result.dme = 0;
    } else if (thresh == 0.0) {
        for (f1 = d1.d, f2 = d2.d; f1 < last; f1++, f2++) {
            float diff = *f1 - *f2;
            sum += diff * diff;
        }
        result.dme = sqrt (sum / d1.sz);
    } else {
        float *p;
        float thresh2, tmp_dme2;
        struct dmat d_tmp;
        size_t nleft;
        alloc_dmat (&d_tmp, d1.n);

        nleft = d_tmp.sz;
        p = d_tmp.d;

        for (f1 = d1.d, f2 = d2.d; f1 < last; f1++, f2++, p++) {
            float diff = *f1 - *f2;
            float diff2 = diff * diff;
            sum += diff2;
            *p = diff2;
        }
        tmp_dme2 = sum / d1.sz;
        result.dme = sqrt (tmp_dme2);
        thresh2 = thresh * thresh;
        p = d_tmp.d;
        qsort (p, d_tmp.sz, sizeof (p[0]), flt_compar);
        while ((tmp_dme2 > thresh2) && (--nleft > 0)) {
            sum -= *p;
            tmp_dme2 = sum / nleft;
            p++;
        }
        result.n_left = nleft;
        del_dmat (&d_tmp);
    }
    return result;
}

/* ---------------- fill_dmat  --------------------------------
 * We calculate the elements of a distance matrix.
 * We have a local pointer for the coordinates, rp.
 * If we are using all coordinates (mask == NULL), then we point
 * rp to the array of alpha carbon coordinates.
 * If we are using the mask, then we allocate an array and copy
 * over just the relevant coordinates. This is free()d at the end.
 */
static void
fill_dmat (struct dmat *dm, struct coord *c, size_t n, char *mask)
{
    float *d, *dlast;
    struct RPoint *rp;
    size_t i, j;

    if (mask == NULL) {
        rp = c->rp_ca;
    } else {
        struct RPoint *rp2;
        size_t k;
        size_t to_mall = n * sizeof (rp[0]);
        rp = E_MALLOC (to_mall);
        memset (rp, 0, to_mall);
        rp2 = rp;
        for (k = 0; k < c->size; k++)
            if (mask[k])
                *rp2++ = c->rp_ca [k];
    }

    d = dm->d;
    for (i = 0; i < n; i++) {
        for (j = i + 1; j < n; j++) {
            float x = rp [i].x - rp [j].x;
            float y = rp [i].y - rp [j].y;
            float z = rp [i].z - rp [j].z;
            *d++ = x * x + y * y + z * z;
        }
    }

    dlast = dm->d + dm->sz;
    for (d = dm->d; d < dlast; d++)
        *d = sqrt (*d);

    if (mask != NULL)
        free (rp);
}

/* ---------------- dmat_make_mask ----------------------------
 * creates the byte-field mask to
 * map model to reference coordinates
 */
static char *
dmat_make_mask( struct coord *mdl, struct coord *ref)
{
    char *ref_mask;

    if (mdl->size == ref->size) {
        ref_mask = NULL;
    } else {
        short *orig = mdl->orig;
        short *last = orig + mdl->size;
        size_t to_mall = sizeof(*ref_mask) * ref->size;
        ref_mask = E_MALLOC ( to_mall );
        memset (ref_mask, 0, to_mall);
        
        for ( ; orig < last; orig++) {
            ref_mask [*orig - 1] = 1;
        }
    }
    return ref_mask;
}

/* ---------------- dme_thresh --------------------------------
 * We are given two sets of coordinates, probably coming from
 * the same molecule. Unfortunately, one may be imcomplete. This
 * is the model. We assume that all of its residues are present
 * in the larger structure.
 * Begin by building a mask which can be applied to the larger
 * system. We will calculate a distance matrix only for the
 * residues present in both molecules.
 * Our return value is success/failure, but our numerical return
 * is via a pointer to a float.
 */
int
dme_thresh (float *frac, struct coord *c1, struct coord *c2, float thresh)
{
    struct coord *ref, *mdl;
    char *ref_mask;
    struct dme_res result;
    struct dmat ref_dmat, mdl_dmat;
    
    if (c1->size > c2->size)
        ref = c1, mdl = c2;
    else
        ref = c2, mdl = c1;

    if (mdl->size <= 1) {    /* If given a tiny model, should we return  */
        *frac = 0.0;         /* failure or success ? */
        return EXIT_SUCCESS; /* There is no correct answer. Depends on what */
    }                        /* caller expects  */
    
    ref_mask = dmat_make_mask(mdl, ref);

    alloc_dmat (&ref_dmat, mdl->size);  /*same as model size - not a bug ! */
    alloc_dmat (&mdl_dmat, mdl->size);
    

    fill_dmat (&ref_dmat, ref, mdl->size, ref_mask);
    fill_dmat (&mdl_dmat, mdl, mdl->size, NULL);
    
    result = get_dme (ref_dmat, mdl_dmat, thresh);
    del_dmat (&ref_dmat);
    del_dmat (&mdl_dmat);
    free_if_not_null (ref_mask);
    
    *frac = (float) result.n_left / result.sz;

    return EXIT_SUCCESS;
}
