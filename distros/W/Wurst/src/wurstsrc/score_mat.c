/*
 * 1 March 2002
 * For manipulations of score matrices.
 * $Id: score_mat.c,v 1.1 2007/09/28 16:57:13 mmundry Exp $
 */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "e_malloc.h"
#include "fio.h"
#include "matrix.h"
#include "mprintf.h"
#include "read_seq_i.h"
#include "score_mat.h"
#include "score_mat_i.h"
#include "scratch.h"
#include "seq.h"
#include "str.h"
#include "pair_set.h"
#include "pair_set_i.h"





/* ---------------- score_mat_new   ---------------------------
 * Given the size of two things (sequences, structures),
 * allocate memory for a score matrix.
 * WATCH OUT !
 * There is a rule.. Score matrices have two extra columns and
 * two extra rows. This means makes it easier to implement
 * some scoring schemes with fancy end penalties. The extra
 * rows and columns are at the start and end of each scored
 * thing.
 */
struct score_mat *
score_mat_new (const size_t n_rows, const size_t n_cols)
{
    float **mat;
    struct score_mat *ret_mat;
    mat = f_matrix (n_rows + 2, n_cols + 2);
    memset (mat[0], (int)0.0, sizeof (mat[0][0]) * (n_rows+2) * (n_cols+2));
    ret_mat = E_MALLOC (sizeof (*ret_mat));
    ret_mat->mat = mat;
    ret_mat->n_rows = n_rows + 2;
    ret_mat->n_cols = n_cols + 2;
    return (ret_mat);
}

/* ---------------- score_mat_destroy -------------------------
 */
void
score_mat_destroy (struct score_mat *smat)
{
    const char *this_sub = "score_mat_destroy";
    if (smat == NULL) {
        err_printf (this_sub, "called to delete null score matrix\n");
        return ;
    }
    if ( smat->mat)
        kill_f_matrix (smat->mat);
    else
        err_printf (this_sub, "Called to delete score mat with no matrix\n");
    smat->mat = NULL; /* only to provoke an error if we try again */
    free (smat);
}

/* ---------------- score_mat_shift ---------------------------
 * Add a constant value to a score matrix
 * This one returns a new score matrix.
 * We shift all elements, except first and last row and column.
 */
struct score_mat *
score_mat_shift (struct score_mat *mat1, const float shift)
{
    struct score_mat *res;
    size_t i, j;
    const size_t n_rows = mat1->n_rows;
    const size_t n_cols = mat1->n_cols;
    const size_t last_row = n_rows - 1;
    const size_t last_col = n_cols - 1;
    res = score_mat_new (n_rows - 2, n_cols - 2);
    for (i = 1; i < last_row; i++)
        for (j = 1; j < last_col ; j++)
            res->mat[i][j] = mat1->mat[i][j] + shift;
    return res;
}

/* ---------------- score_mat_scale ---------------------------
 * Scale a score matrix. Return a new matrix.
 * We could do the operation in-place, but then some code at the
 * perl level can lead to destroying the matrix, and then referring
 * to the free()'d memory.
 */
struct score_mat *
score_mat_scale (struct score_mat *mat, const float scale)
{
    struct score_mat *res;
    float *dlast, *d, *m;
    res = score_mat_new (mat->n_rows - 2, mat->n_cols - 2);
    d = mat->mat[0];
    m = res->mat[0];
    dlast = d + mat->n_rows * mat->n_cols;
    for ( ; d < dlast ; d++, m++)
        *m = *d * scale;
    return res;
}

/* ---------------- score_mat_add  ----------------------------
 * Do like new_mat = mat1 + (k * mat2 + b)
 * Do *not* do the operation in-place. There is a good reason
 * for this.
 */
struct score_mat *
score_mat_add ( struct score_mat *mat1, struct score_mat *mat2,
                const float scale, const float shift)
{
    struct score_mat *res;
    const char *this_sub = "score_mat_add";
    const char *broken_sizes = "%s size mismatch, %u != %u\n";
    float *dlast, *d, *m1, *m2;

    if (mat1->n_rows != mat2->n_rows) {
        err_printf (this_sub, broken_sizes, "Row", mat1->n_rows, mat2->n_rows);
        return NULL;
    }
    if (mat1->n_cols != mat2->n_cols) {
        err_printf (this_sub, broken_sizes, "Col", mat1->n_cols, mat2->n_cols);
        return NULL;
    }
    res = score_mat_new (mat1->n_rows - 2, mat1->n_cols - 2);
    d = res->mat[0];
    m1 = mat1->mat[0];
    m2 = mat2->mat[0];
    dlast = d + mat1->n_rows * mat1 ->n_cols;
    for ( ; d < dlast; d++, m1++, m2++)
        *d = *m1 + (shift  + scale * *m2);
    return res;
}

/* ---------------- score_mat_info   --------------------------
 * To give an idea of the size of elements in a score matrix.
 * Do not look at first or last rows or columns.
 */
void
score_mat_info (const struct score_mat *score_mat,
                float *min, float *max, float *av,
                float *std_dev)
{
    float **mat = score_mat->mat;
    double sum = 0;
    double sumsq = 0;
    unsigned n = 0;
    size_t i, j;
    const size_t last_row = score_mat->n_rows - 1;
    const size_t last_col = score_mat->n_cols - 1;
    *min = *max = mat[1][1];
    for (i = 1; i < last_row; i++) {
        for (j = 1; j < last_col; j++) {
            float f = mat[i][j];
            if (f < *min)
                *min = f;
            if (f > *max)
                *max = f;
            sum += f;
            sumsq += (f * f);
            n++;
        }
    }

    *av   = (float) (sum / n);
    *std_dev = (float) (sqrt (n * sumsq - (sum * sum)) / n);
}

/* ---------------- score_mat_string --------------------------
 * This is not a score routine, it is not an alignment routine.
 * Maybe it should go in its own file.
 * Here are the tricks to remember.
 * Our M+N score matrix is actually (M+2)(M+2) so as to allow
 * for empty places and end-gaps. You don't have to use them if
 * you don't like them.
 * The loops below are far more elegant if we temporarily store
 * the strings with end bits at start and end.
 */
char *
score_mat_string (struct score_mat *smat, struct seq *s1, struct seq *s2)
{
    char *ret = NULL;
    char *str1, *str2;
    size_t n_rows = smat->n_rows;
    size_t n_cols = smat->n_cols;
    size_t i, j;
    const char *c_fmt = "%4c ";
    const char *f_fmt = "%4.2f ";
    const char *hat   = "^";
    seq_thomas2std (s1);
    seq_thomas2std (s2);
    str1 = save_str (hat);
    str1 = save_str_append (str1, s1->seq);
    str1 = save_str_append (str1, hat);
    str2 = save_str (hat);
    str2 = save_str_append (str2, s2->seq);
    str2 = save_str_append (str2, hat);

    scr_reset();
    scr_printf (c_fmt, ' ');
    for ( i = 0; i < n_cols; i++)
        scr_printf (c_fmt, str2[i]);
    scr_printf ("\n");
    for ( i = 0; i < n_rows; i++) {
        scr_printf (c_fmt, str1[i]);
        for ( j = 0 ; j < n_cols; j++)
            scr_printf (f_fmt, smat->mat[i][j]);
        ret = scr_printf ("\n");
    }
    free (str1);
    free (str2);
    return (ret);
}

/* ---------------- score_mat_write  --------------------------
 * Dump a score matrix to a file.
 */
int
score_mat_write (const struct score_mat *smat, const char *fname)
{
    FILE *fp;
    float **mat;
    unsigned int n_rows, n_cols;
    size_t to_write;
    const char *this_sub = "score_mat_write";
    extern const char *null_point, *prog_bug;

    if (sizeof(n_rows) != 4) {
        err_printf (this_sub, prog_bug, __FILE__, __LINE__);
        return EXIT_FAILURE;
    }
    if ( ! smat ) {
        err_printf (this_sub, null_point);
        return EXIT_FAILURE;
    }

    if ( smat->n_rows == 0 || smat->n_cols == 0) {
        err_printf (this_sub, "n_rows or columns is zero for %s\n", fname);
        return EXIT_FAILURE;
    }
    if ((fp = mfopen ( fname, "w", this_sub)) == NULL)
        return EXIT_FAILURE;

    n_rows = (unsigned int) smat->n_rows;
    n_cols = (unsigned int) smat->n_cols;

    if (fwrite (&n_rows, sizeof (n_rows), 1, fp) != 1)
        goto error;
    if (fwrite (&n_cols, sizeof (n_cols), 1, fp) != 1)
        goto error;

    mat = smat->mat;
    to_write = n_rows * n_cols;
    if (fwrite (mat[0], sizeof (mat[0][0]), to_write, fp) != to_write)
        goto error;
    fclose (fp);
    return EXIT_SUCCESS;
    error:
        mperror (this_sub);
        err_printf (this_sub, "Failed writing to %s", fname);
        fclose (fp);
        return EXIT_FAILURE;
}

/* ---------------- score_mat_read   --------------------------
 * Read a score matrix from a file. Return a newly allocated
 * score_mat pointer.
 */
struct score_mat *
score_mat_read ( const char *fname)
{
    float **mat;
    struct score_mat *ret_mat = NULL;
    FILE *fp;
    unsigned to_read;
    unsigned int n_rows, n_cols, ret;
    int err = 0;
    static int first = 1;
    const char *this_sub = "score_mat_read";
    const char *read_fail = "Read fail on %s in %s\n";
    extern const char *prog_bug;
    if (sizeof(n_rows) != 4) {
        err_printf (this_sub, prog_bug, __FILE__, __LINE__);
        return NULL;
    }
    if ((fp = mfopen (fname, "r", this_sub)) == NULL)
        return NULL;

    if ((err = file_no_cache(fp)) != 0) {
        if (first) {
            const char *no_cache = "cannot disable read cache: %s: %s";
            first = 0;
            err_printf (this_sub, no_cache, fname, strerror (err));
        }
    }

    if (fread (&n_rows, sizeof (n_rows), 1, fp) != 1) {
        err_printf (this_sub, read_fail, "n_rows", fname);
        goto end;
    }
    if (fread (&n_cols, sizeof (n_cols), 1, fp) != 1) {
        err_printf (this_sub, read_fail, "n_cols", fname);
        goto end;
    }

    ret_mat = score_mat_new (n_rows - 2, n_cols - 2);
    mat = ret_mat->mat;
    to_read = (n_rows ) * (n_cols);
    if ((ret = fread (mat[0], sizeof (mat[0][0]), to_read, fp)) != to_read) {
        err_printf (this_sub, "Failed reading %s. Wanted %lu items. Got %lu\n",
                    fname, (long unsigned) to_read, (long unsigned) ret);
        score_mat_destroy (ret_mat);
        goto end;
    }

    end:
    fclose (fp);
    return ret_mat;
}

/* ------------------------ score_mat_diag_wipe --------------------------
 * At duplicated scorings, we must get rid off the big selfalignments, in
 * case of very similar or even indentical aa sequences in order to discover
 * circluar permutated proteins (similar domains but different conectivity).
 */
void score_mat_diag_wipe( struct pair_set *p_s, struct score_mat *smat )
{
    int **p, **plast;
    float min, max, av, std_dev;

    score_mat_info ( smat, &min, &max, &av, &std_dev);

    p= p_s->indices;
    plast = p + p_s->n;
    for ( ; p < plast ; p++){
        int nc, nr;
        nc = (*p)[0];
        nr = (*p)[1];
        if (nc == GAP_INDEX)
            continue;
        if (nr == GAP_INDEX)
            continue;

	smat->mat[nc + 1][nr + 1] = min;
    }
}

/* ---------------- score_pvec_double_matrix -----------------
 * Duplication of the scoring matrix containing pvecs.
 * The result is a quadrified matrix with the extra columns and rows '$'.
 *
 *  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
 *  $--------------|--------------$
 *  $| smat        | smat_2       |$
 *  _|_______________|_______________|_
 *  $|             |             |$
 *  $| smat_3       | smat_4      |$
 *  $--------------|--------------$
 *  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
 * */

struct score_mat *
score_mat_double_matrix (const struct score_mat *smat){
    struct score_mat *new_smat;
    size_t new_n_cols, new_n_rows;
    size_t i, k;

    float **src_mat, **dst_mat; /* source and destination data */

    new_n_rows = (smat->n_rows -2) * 2;
    new_n_cols = (smat->n_cols -2) * 2;

    /* init new scoring matrix */
    new_smat = score_mat_new( new_n_rows, new_n_cols );
    src_mat = smat->mat;
    dst_mat = new_smat->mat;


    /* copy and duplication of the entries into the big new one
     * considering the extra cols and rows */

    /* first and second, filling the whole rows
     *  $$$$   $= extra rows and cols untouched
     *  $**$
     *  $--$
     *  $$$$
     *
     * */

    for (i = 1; i < smat->n_rows-1 ; i++){
        for(k = 0; k < 2; k++){
           memcpy( dst_mat[i]+(1+ k*(smat->n_cols-2)), src_mat[i]+1, (smat->n_cols-2) * sizeof(src_mat[0][0]) );
        }
    }

    /* third and fourth concurrently
     *  $$$$ $= extra rows and cols untouched
     *  $**$
     *  $**$
     *  $$$$
     */

     for ( i = 1 ; i < smat->n_rows-2; i++){
     	memcpy( dst_mat[i + smat->n_rows - 2]+1, dst_mat[i]+1,  (new_smat->n_cols-2) * 2 * sizeof(dst_mat[0][0]));
     }

    return new_smat;
}

/* ------------------------ score_mat_write_gnuplot ----------------------
 * For Plotting an alignment traceback, e.g. with gnuplot, you need the
 * smat->mat scores. This function writes them into an ASCII file with
 * filename as param with output in each line:
 * 	i j value
 */
int
score_mat_write_gnuplot( const struct score_mat *smat, const char *fname, const char *protA, const char *protB ){
    const char *this_sub = "score_mat_write_gnuplot";
    float **mat = smat->mat;
    size_t i,j;

    FILE *fp;
    if ((fp = mfopen ( fname, "w", this_sub)) == NULL)
        return EXIT_FAILURE;

    if ( mfprintf ( fp , "%s%s%s%s%s\n","# Data from ", protA, ".pdb and ", protB ,".pdb") < 0)
        goto error;

    if ( mfprintf ( fp, "# %u entries per side \n", (unsigned int) smat->n_cols ) < 0)
        goto error;

    if ( mfprintf ( fp, "# Total entries %u\n", (unsigned int)(smat->n_rows * smat->n_cols) ) < 0)
        goto error;

    for (i = 0; i < smat->n_rows; i++ ){
        for (j = 0; j < smat->n_cols; j++ ){
     	    if ( mfprintf ( fp, "%d %d %f \n", i, j , mat[i][j] ) < 0)
                goto error;
     	}
     	if ( mfprintf ( fp, "\n") < 0)
            goto error;
    }
    if ( mfprintf ( fp, "\n" )  < 0)
        goto error;

    fclose (fp);
    return EXIT_SUCCESS;

    error:
        mperror (this_sub);
        err_printf (this_sub, "Failed writing to %s", fname);
        fclose (fp);
        return EXIT_FAILURE;
}

