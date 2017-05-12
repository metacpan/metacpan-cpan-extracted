/*
 * 14 June 2005
 * Functions for handling class membership probability vectors.
 * $Id: prob_vec.c,v 1.1 2007/09/28 16:57:09 mmundry Exp $
 */

#include <errno.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "e_malloc.h"
#include "fio.h"
#include "matrix.h"
#include "mgc_num.h"
#include "mprintf.h"
#include "prob_vec.h"
#include "prob_vec_i.h"
#include "scratch.h"
#include "seq.h"
#include "yesno.h"

/* ---------------- constants ---------------------------------
 */
const char PVEC_CRAP      = (char) 0;             /* Don't know yet. */
const char PVEC_TRUE_PROB = (char) 1;             /* Normalised to sum = 1.0 */
const char PVEC_UNIT_VEC  = (char) 2;             /* or to unit vector size */
const int  PVEC_VERSION   = 1;
static const char *mismatch = "Size mismatch. Should be four bytes. Got %ud\n";

/* ---------------- new_pvec  ---------------------------------
 * Create a new probability vector.
 */
struct prob_vec *
new_pvec (const size_t frag_len, const size_t prot_len,
          const size_t n_pvec, const size_t n_class)
{
    struct prob_vec *p_vec;
    const char *this_sub = "new_pvec";
    const size_t pv_size = sizeof (struct prob_vec);
    if (prot_len < frag_len) {
        err_printf (this_sub,"Seq size %d too small for fragment size (%d)\n",
                    (int) prot_len, (int) frag_len);
        return NULL;
    }

    p_vec = memset ( E_MALLOC ( pv_size), 0, pv_size);

    p_vec->n_pvec    = n_pvec;
    p_vec->prot_len  = prot_len;
    p_vec->frag_len  = frag_len;
    p_vec->n_class   = n_class;
    if (n_pvec != 0 && n_class != 0)
        p_vec->mship = f_matrix (n_pvec, n_class);

    p_vec->norm_type = PVEC_CRAP;
    return (p_vec);
}

/* ---------------- prob_vec_true_prob ------------------------
 * Look at each of the probability vectors and normalise the
 * sum to 1.0. This is really two functions, depending on whether
 * we are in compressed or expanded format.
 * This function has been tested rather thoroughly, but is
 * commented out since the current applications do not need it.
 */
#ifdef want_prob_vec_true_prob
static void
prob_vec_true_prob (struct prob_vec *p_v)
{
    if (p_v -> norm_type == PVEC_TRUE_PROB)
        return;
    if ( p_v->mship) {                           /* We are in expanded form */
        float **mship = p_v->mship;
        float **mlast = mship + p_v->n_pvec;
        for ( ; mship < mlast; mship++) {
            double total = 0.0;
            float *p;
            float *f = *mship;                      /* Point to start of row */
            float *flast = f + p_v->n_class;
            for ( ; f < flast; f++)
                total += *f;
            if (total == 0.0)      /* If broken, then don't touch vector */
                total = 1.;
            for ( p = *mship; p < flast; p++)
                *p /= (float) total;
        }
    } else {                                                 /* Compact form */
        float *p_prob, *prob2, *pr_last;
        unsigned short *pi, *p_ndx, *pi_last;
        pi      = p_v->cmpct_n;
        p_ndx   = p_v->cmpct_ndx;
        pi      = p_v->cmpct_n;
        pi_last = pi + p_v->n_pvec;
        p_prob = p_v->cmpct_prob;
        prob2  = p_prob;
        for ( ; pi < pi_last; pi++) {               /* Over each prob vector */
            double  total = 0.0;
            pr_last = p_prob + *pi;
            for ( ; p_prob < pr_last; p_prob++)   /* Each element in one vec */
                total += *p_prob;
            if (total == 0.0)          /* If broken, then don't touch vector */
                total = 1.;
            for ( ; prob2 < pr_last; prob2++)
                *prob2 = (float) (*prob2 / total);
        }
    }
    p_v->norm_type = PVEC_TRUE_PROB;
}
#endif /* want_prob_vec_true_prob */

/* ---------------- prob_vec_unit_vec -------------------------
 * If our vectors are normalised so they sum to 1, make the sum
 * of squares by 1.0. That is, normalise the vector to unit
 * length.
 */
void
prob_vec_unit_vec (struct prob_vec *p_v)
{
    if (p_v -> norm_type == PVEC_UNIT_VEC)
        return;
    if ( p_v->mship) {                           /* We are in expanded form */
        float **mship = p_v->mship;
        float **mlast = mship + p_v->n_pvec;
        for ( ; mship < mlast; mship++) {
            double total = 0.0;
            float *p;
            float *f = *mship;                      /* Point to start of row */
            float *flast = f + p_v->n_class;
            for ( ; f < flast; f++)
                total += *f * *f;
            if (total == 0.0)      /* If broken, then don't touch vector */
                total = 1;
            total = sqrt (total);
            for ( p = *mship; p < flast; p++)
                *p /= (float) total;
        }
    } else {                                                 /* Compact form */
        float *p_prob, *prob2, *pr_last;
        unsigned short *pi, *pi_last;
        pi      = p_v->cmpct_n;
        pi      = p_v->cmpct_n;
        pi_last = pi + p_v->n_pvec;
        p_prob = p_v->cmpct_prob;
        prob2  = p_prob;
        for ( ; pi < pi_last; pi++) {               /* Over each prob vector */
            double  total = 0.0;
            pr_last = p_prob + *pi;
            for ( ; p_prob < pr_last; p_prob++)   /* Each element in one vec */
                total += (*p_prob * *p_prob);
            if (total == 0.0)      /* If broken, then don't touch vector */
                total = 1;
            total = sqrt (total);
            for ( ; prob2 < pr_last; prob2++)
                *prob2 = (float) (*prob2 / total);
        }
    }
    p_v->norm_type = PVEC_UNIT_VEC;
}

static float *tmp_flt;  /* This pointer is used for communication with */
                        /* the qsort comparison function, ndx_cmp(). */

/* ---------------- ndx_sort  ---------------------------------
 * Local sort helper function to get most important elements
 * from probability array.
 */
static int
ndx_cmpr (const void *a, const void *b)
{
    const unsigned short int *pa = a;
    const unsigned short int *pb = b;
    float fa = tmp_flt [*pa];
    float fb = tmp_flt [*pb];
    if (fa > fb)
        return -1;
    if (fa < fb)
        return 1;
    return 0;
}

/* ---------------- prob_vec_compact --------------------------
 * Given a full probability vector, build a compact form with
 * just the populated classes.
 */
static struct prob_vec *
prob_vec_compact (struct prob_vec * p_vec)
{
    const float threshold = 0.99;
    const size_t n_class = p_vec->n_class;
    float *tmp = E_MALLOC (n_class * sizeof (tmp[0]));
    unsigned short *ndx = E_MALLOC (n_class * sizeof (ndx[0]));

    size_t i;
    unsigned pcount = 0;

    if (p_vec -> cmpct_prob)                  /* Data is already in */
        return (p_vec);                       /* compact (sparse) form */

    p_vec->cmpct_n = E_MALLOC (p_vec->n_pvec * sizeof(p_vec->cmpct_n[0]));
    for (i = 0; i < p_vec->n_pvec; i++) {
        float ptotal = 0.0;
        unsigned short n = 0;
        unsigned short j;
        size_t nitem;
        tmp_flt = p_vec->mship[i];
        for (j = 0; j < p_vec->n_class; j++)
            ndx [j] = j;
        qsort (ndx, n_class, sizeof (ndx[0]), ndx_cmpr);
        while (ptotal < threshold && n < n_class) {
            tmp [n] = p_vec->mship[i][ndx[n]];
            ptotal += tmp [n];
            n++;
        }
        p_vec->cmpct_n[i] = n;
        nitem = pcount + n;
        p_vec->cmpct_prob =
            E_REALLOC(p_vec->cmpct_prob, nitem * sizeof(p_vec->cmpct_prob[0]));
        p_vec->cmpct_ndx =
            E_REALLOC(p_vec->cmpct_ndx, nitem * sizeof(p_vec->cmpct_ndx[0]));
        memcpy (p_vec->cmpct_prob + pcount, tmp, n * sizeof (tmp[0]));
        memcpy (p_vec->cmpct_ndx  + pcount, ndx, n * sizeof (ndx[0]));
        pcount += n;
    }
    free (ndx);
    free (tmp);
    return p_vec;
}

/* ---------------- prob_vec_expand ---------------------------
 * Go from compact to expanded form of vector.
 * We work on the vector in-place, so we can return EXIT_SUCCESS/FAILURE.
 */
int
prob_vec_expand (struct prob_vec *p_vec)
{
    float **mship;
    float *p_prob;
    unsigned short *pi, *pi_last;
    unsigned short *p_ndx;
    const char *this_sub = "prob_vec_expand";
    if (p_vec->mship)
        return EXIT_SUCCESS;            /* The data was already expanded. */
    if (p_vec->prot_len == 0) {
        err_printf (this_sub, "prot length zero");
        return EXIT_FAILURE;
    }
    if (p_vec->n_class == 0) {
        err_printf (this_sub, "n_class is zero");
        return EXIT_FAILURE;
    }
    p_vec->mship = f_matrix (p_vec->n_pvec, p_vec->n_class);
    mship  = p_vec->mship;     /* Use this below, to point to parts of array */
    p_prob = p_vec->cmpct_prob;
    p_ndx  = p_vec->cmpct_ndx;
    pi     = p_vec->cmpct_n;
    pi_last = pi + p_vec->n_pvec;
    for ( ; pi < pi_last ; pi++) {
        unsigned short j;
        float *f = *mship++;        /* The column corresponding to this site */
        memset (f, 0, sizeof (f[0]) * p_vec->n_class);
        for (j = 0; j < *pi; j++) {
            int ndx   = *p_ndx++;
            float val = *p_prob++;
            f[ndx]    = val;
        }
    }

    return EXIT_SUCCESS;
}

/* ---------------- xfwrt  ------------------------------------
 * An fwrite() wrapper with appropriate error messages if
 * something breaks. Without this, the code looks boring and
 * repetitive, below. Return EXIT_SUCCESS / FAILURE.
 */
static int
xfwrt (const void *data, const size_t size, size_t nmem, FILE *fp,
               const char *caller, const char *fname)
{
    size_t r = fwrite(data,  size, nmem, fp) ;
    if (r != nmem) {
        mperror (caller);
        err_printf (caller, "Trying to write to %s\n", fname);
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}

/* ---------------- write_4 -----------------------------------
 * We have a slight problem when writing things of type size_t.
 * This can be 4 or 8 bytes long.
 * In general, we know that we are dealing with small numbers,
 * so 4 bytes will do.
 * This takes a size_t arg, copies to a 4 byte int and then calls
 * the writer. On 32 bit machines, it does no harm. On 64 bit
 * machines it will write just 4 bytes. Remarkably, gcc does seem
 * to optimise the test around sizeof() away (reading the
 * assembler).
 */
static int
write_4 (size_t data, FILE *fp, const char *caller, const char *fname)
{
    unsigned int i_tmp;
    if (sizeof (i_tmp) != 4) {
        err_printf (caller, mismatch, sizeof (i_tmp)); return EXIT_FAILURE ;}
    i_tmp = data;
    return (xfwrt ( &i_tmp, sizeof (i_tmp), 1, fp, caller, fname));
}

/* ---------------- xfrd  -------------------------------------
 * Noisy wrapper around fread. Make it more convenient to
 * print out the sys error message and name of the file.
 * The third parameter can be used to silence errors. If
 * quiet == yes, we assume this is just a test read. The return value
 * will tell the caller that the data is not available, but we
 * should not print an error message.
 * Return EXIT_SUCCESS/FAILURE.
 */
static int
xfrd (void *data, size_t size, size_t nmem, FILE *fp,
      const char *caller, const char *fname, const enum yes_no quiet)
{
    size_t r = fread (data, size, nmem, fp);
    if (r != nmem) {
        if (quiet == YES)
            return EXIT_FAILURE;
        if (errno)
            mperror (caller);
        err_printf (caller, "Trying to read from %s\n", fname);
        err_printf (caller, "Wanted %u elements, got %u\n",
                    (unsigned) nmem, (unsigned) r);
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}

/* ---------------- prob_vec_write ----------------------------
 * Write a probability vector a specified file name.
 * First, some sizes are written, followed by the data.
 * The compound information is written last for historical
 * reasons and we do not require it to be present. This will
 * change in the future. Eventually all old applications should
 * be updated to take advantage of the compound information.
 */
int
prob_vec_write (struct prob_vec *p_v, const char *fname)
{
    FILE *fp;
    unsigned short *nc, *nc_last;
    unsigned total = 0;
    const char *this_sub = "prob_vec_write";

    if (! (fp = mfopen(fname, "w", this_sub)))
        return EXIT_FAILURE;
    if (p_v -> cmpct_prob == NULL)
        prob_vec_compact (p_v);

    nc      = p_v->cmpct_n;
    nc_last = nc + p_v->n_pvec;
    for ( ; nc < nc_last; nc++)
        total += *nc;
    if (write_magic_num (fp) == EXIT_FAILURE)
        return EXIT_FAILURE;

    if (xfwrt ( &PVEC_VERSION,  sizeof(PVEC_VERSION),  1, fp, this_sub, fname)
        == EXIT_FAILURE) goto error;
    if (write_4 (p_v->frag_len, fp, this_sub, fname) == EXIT_FAILURE)
        goto error;
    if (write_4 (p_v->prot_len, fp, this_sub, fname) == EXIT_FAILURE)
        goto error;
    if (write_4 (p_v->n_pvec,   fp, this_sub, fname) == EXIT_FAILURE)
        goto error;
    if (write_4 (p_v->n_class,  fp, this_sub, fname) == EXIT_FAILURE)
        goto error;
    if (xfwrt( p_v->cmpct_n, sizeof (p_v->cmpct_n[0]), p_v->n_pvec, fp,
               this_sub, fname) == EXIT_FAILURE)
        goto error;
    if (xfwrt( p_v->cmpct_prob, sizeof(p_v->cmpct_prob[0]), total, fp,
               this_sub, fname) == EXIT_FAILURE)
        goto error;
    if (xfwrt( p_v->cmpct_ndx, sizeof(p_v->cmpct_ndx[0]), total, fp,
               this_sub, fname) == EXIT_FAILURE)
        goto error;

    if (xfwrt ( &p_v->norm_type, sizeof(p_v->norm_type), 1, fp,
                this_sub, fname) == EXIT_FAILURE) goto error;

    /*store compound information*/
    {
        unsigned u = (unsigned) p_v->compnd_len;
        if (write_4 (u,  fp, this_sub, fname) == EXIT_FAILURE)
        goto error;
    }

    if (xfwrt ( p_v->compnd, sizeof(char), p_v->compnd_len, fp,
                this_sub, fname) == EXIT_FAILURE) goto error;

    fclose (fp);
    return EXIT_SUCCESS;
 error:
    fclose (fp);
    return EXIT_FAILURE;
}

/* ---------------- prob_vec_read  ----------------------------
 * When we read from one of these files, we are always going to
 * read the whole thing. If we use a largish buffer, we can read
 * the thing in one call.
 */
struct prob_vec *
prob_vec_read (const char *fname)
{
    enum { FBUFSIZ = 32768 };
    char fbuf [FBUFSIZ];
    FILE *fp;
    struct prob_vec *p_v = NULL;
    int version, err;
    unsigned total = 0;
    unsigned int n_pvec, n_class, prot_len, frag_len;
    const enum yes_no quiet = NO;
    const enum yes_no noisy = YES;
    static unsigned char first = (char) 1;
    const char *this_sub = "prob_vec_read";
    const char *no_swap = "Byte swapping not written yet. Reading from %s\n";
    const char *broken  = "File error reading magic number from %s\n";
    const char *s = "Turning off caching for %s:\n\"%s\"\n";

    if (sizeof (n_pvec) != 4) {
        err_printf (this_sub, mismatch, sizeof (n_pvec)); return NULL; }

    if (! (fp = mfopen(fname, "r", this_sub)))
        return NULL;
    if (setvbuf(fp, fbuf, _IOFBF, FBUFSIZ))
        err_printf (this_sub, "warning setvbuf() call failed\n");

    if ((err = file_no_cache(fp)) != 0) {
        if (first) {
            first = 0;
            err_printf (this_sub, s, fname, strerror (err));
        }
    }

    switch (read_magic_num (fp)) {
    case BYTE_REVERSE:
        err_printf (this_sub, no_swap, fname); fclose (fp); return NULL;
    case BYTE_BROKEN:
        err_printf (this_sub, broken, fname);  fclose (fp); return NULL;
    case BYTE_STRAIGHT:
        break;                         /* fall through, no problem occurred */
    }

    if( xfrd ( &version, sizeof (version),       1, fp, this_sub, fname, quiet)
        == EXIT_FAILURE) goto error;
    if (version != 1) {
        err_printf (this_sub, "error reading version num, got %d\n", version);
        goto error;
    }
    if( xfrd ( &frag_len, sizeof (frag_len), 1, fp, this_sub, fname, quiet)
        == EXIT_FAILURE) goto error;
    if( xfrd ( &prot_len, sizeof (prot_len), 1, fp, this_sub, fname, quiet)
        == EXIT_FAILURE) goto error;
    if( xfrd ( &n_pvec,   sizeof (n_pvec),   1, fp, this_sub, fname, quiet)
        == EXIT_FAILURE) goto error;
    if( xfrd ( &n_class,  sizeof (n_class),  1, fp, this_sub, fname, quiet)
        == EXIT_FAILURE) goto error;

    p_v = new_pvec (frag_len, prot_len, n_pvec, 0);
    p_v->n_class = n_class;
    p_v->cmpct_n = E_MALLOC (n_pvec * sizeof (p_v->cmpct_n[0]));
    if (xfrd (p_v->cmpct_n, sizeof (p_v->cmpct_n[0]), n_pvec, fp,
              this_sub, fname, quiet) == EXIT_FAILURE) goto error;
    {
        unsigned short *nc            = p_v->cmpct_n;
        const unsigned short *nc_last = nc + n_pvec;
        for ( ; nc < nc_last; nc++)
            total += *nc;
    }
    p_v->cmpct_prob = E_MALLOC (total * sizeof (p_v->cmpct_prob[0]));
    if (xfrd (p_v->cmpct_prob, sizeof (p_v->cmpct_prob[0]), total, fp,
              this_sub, fname, quiet) == EXIT_FAILURE) goto error;
    p_v->cmpct_ndx  = E_MALLOC (total * sizeof (p_v->cmpct_ndx[0]));
    if (xfrd (p_v->cmpct_ndx, sizeof (p_v->cmpct_ndx[0]), total, fp,
              this_sub, fname, quiet) == EXIT_FAILURE) goto error;
    if( xfrd (&p_v->norm_type, sizeof (p_v->norm_type), 1, fp,
              this_sub, fname, quiet) == EXIT_FAILURE) goto error;

    /* Read compound information. This may not be present, so we
     * continue even if we do not find it. Note also that we have
     * to read into an unsigned, not size_t, variable.
     */

    {
        unsigned u;
        if (xfrd (&u,sizeof(u),1,fp, this_sub, fname, noisy) == EXIT_SUCCESS){
            p_v->compnd_len = u;
            p_v->compnd = E_MALLOC (p_v->compnd_len * sizeof (char));
            if (xfrd ( p_v->compnd, sizeof(char), p_v->compnd_len, fp,
                       this_sub, fname, quiet) == EXIT_FAILURE) goto error;
        } else {
            p_v->compnd = NULL;
            p_v->compnd_len = 0;
        }
    }
    fclose (fp);
    return p_v;
 error:
    if (p_v)
        prob_vec_destroy (p_v);
    fclose (fp);
    return NULL;
}

/* ---------------- prob_vec_size    --------------------------
 */
size_t
prob_vec_size(const struct prob_vec *pvec)
{
    return pvec->n_pvec;
}

/* ---------------- prob_vec_length    --------------------------
 * Returns the length of the underlying protein seqence.
 */
size_t
prob_vec_length(const struct prob_vec *pvec){
    return pvec->prot_len;
}

/* ---------------- prob_vec_info    --------------------------
 * Print information about the probability vector.
 * This uses the ugly machinery to write into scratch space.
 * Changed so it always writes out the total of probabilities
 * and the sum of squares of probabilities.
 */
char *
prob_vec_info ( struct prob_vec *p_v)
{
    char *ret = NULL;
    float *totals, *total2;
    size_t i, j, k, m, n, tomall;
    if (p_v -> mship == NULL)
        prob_vec_expand (p_v);
    scr_reset();
    scr_printf ("# Probability vector as ");
    if (p_v->norm_type == PVEC_TRUE_PROB)
        scr_printf ("true probability form\n");
    else if ( p_v->norm_type == PVEC_UNIT_VEC)
        scr_printf ("unit vector normalised\n");
    else
        scr_printf ("unknown normalised form\n");
    scr_printf ("#   protein length: %u ", (unsigned) p_v->prot_len);
    scr_printf (" num vectors: %u ", (unsigned) p_v->n_pvec);
    scr_printf (" fragment length: %u ", (unsigned) p_v->frag_len);
    scr_printf (" num classes: %u\n", (unsigned) p_v->n_class);
    scr_printf ("# res   class\n");
    scr_printf ("# num");
    for (i = 0; i < p_v->n_class; i++)
        scr_printf ("%8d", (int)(i + 1));
    scr_printf ("%8s", "total");
    scr_printf ("%8s", "tot^2");
    scr_printf ("\n");
    tomall = p_v->n_pvec * sizeof (totals[0]);
    totals = E_MALLOC (tomall);
    memset (totals, 0, tomall);
    total2 = E_MALLOC (tomall);
    memset (total2, 0, tomall);
    for (j = 0; j < p_v->n_pvec; j++) {
        for (k = 0; k < p_v->n_class; k++) {
            totals [j] += p_v->mship [j][k];
            total2 [j] += (p_v->mship [j][k] * p_v->mship [j][k]);
        }
    }

    for (m = 0; m < p_v->n_pvec; m++) {
        scr_printf ("%5u ", (int)m);
        for (n = 0; n < p_v->n_class; n++)
            scr_printf ("%7.2g ", p_v->mship[m][n]);
        scr_printf ("%7.2g %7.2g", totals[m], total2[m]);
        ret = scr_printf ("\n");
    }
    free (totals);
    free (total2);
    return ret;
}

/* ---------------- prob_vec_copy --------------------------
 */
struct prob_vec *
prob_vec_copy (const struct prob_vec *p_vec)
{
    struct prob_vec * p_v = NULL;

    size_t n_cmpct_n = 0;
    size_t i = 0, j = 0;


    if (!p_vec)
        return NULL;

    if ((p_v = new_pvec (p_vec->frag_len, p_vec->prot_len,
                         p_vec->n_pvec, p_vec->n_class)) == NULL) {
        return NULL;
    }

    if (p_vec->cmpct_n) {
        p_v->cmpct_n = E_CALLOC(p_vec->n_pvec, sizeof(p_v->cmpct_n[0]));
        for (i = 0; i < p_vec->n_pvec; ++i) {
            p_v->cmpct_n[i] = p_vec->cmpct_n[i];
            n_cmpct_n += p_v->cmpct_n[i];
        }
    }

    if (p_vec->cmpct_prob) {
        p_v->cmpct_prob = E_CALLOC(n_cmpct_n, sizeof(p_v->cmpct_prob[0]));
        for (i = 0; i < n_cmpct_n; ++i) {
            p_v->cmpct_prob[i] = p_vec->cmpct_prob[i];
        }
    }

    if (p_vec->cmpct_ndx) {
        p_v->cmpct_ndx = E_CALLOC(n_cmpct_n, sizeof(p_v->cmpct_ndx[0]));
        for (i = 0; i < n_cmpct_n; ++i) {
            p_v->cmpct_ndx[i] = p_vec->cmpct_ndx[i];
        }
    }

    if (p_vec->mship) {
        for (i = 0; i < p_vec->n_pvec; ++i) {
            for (j = 0; j < p_vec->n_class; ++j) {
                p_v->mship[i][j] = p_vec->mship[i][j];
            }
        }
    } else {
        kill_f_matrix(p_v->mship);
        p_v->mship = NULL;
    }

    p_v->norm_type = p_vec->norm_type;

    return p_v;
}

/* ---------------- prob_vec_destroy --------------------------
 */
void
prob_vec_destroy ( struct prob_vec *p_vec)
{
    const char *this_sub = "prob_vec_destroy";
    extern const char *prog_bug;
    extern const char *null_point;
    if ( ! p_vec ) {
        err_printf (this_sub, prog_bug, __FILE__, __LINE__);
        err_printf (this_sub, null_point);
        return;
    }

    free_if_not_null (p_vec->cmpct_n);
    free_if_not_null (p_vec->cmpct_prob);
    free_if_not_null (p_vec->cmpct_ndx);
    free_if_not_null (p_vec->compnd);
    if (p_vec->mship)
        kill_f_matrix (p_vec->mship);
    free (p_vec);
}
