/*
 * 12 Nov 2003
 * Read a blast, binary checkpoint file.
 * The aim is to get the amino acid frequency at each position.
 * Later, we can mess with any other information in the file.
 *
 * $Id: read_blst.c,v 1.1 2007/09/28 16:57:06 mmundry Exp $
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "amino_a.h"
#include "e_malloc.h"
#include "fio.h"
#include "matrix.h"
#include "mprintf.h"
#include "read_blst.h"
#include "read_seq_i.h"
#include "scratch.h"
#include "seq.h"
#include "seqprof.h"


/* ---------------- blstorder_table  --------------------------
 */
static const short int *
blstorder_table ( void )
{
    static const short int blstorder [MAX_AA+2] = {
        1,   /*  0 A */
        18,  /*  1 R */
        13,  /*  2 N */  
        15,  /*  3 D */ 
        9,   /*  4 C */
        14,  /*  5 Q */
        16,  /*  6 E */ 
        0,   /*  7 G */
        19,  /*  8 H */
        4,   /*  9 I */
        3,   /* 10 L */
        17,  /* 11 K */
        10,  /* 12 M */  
        5,   /* 13 F */
        6,   /* 14 P */
        7,   /* 15 S */
        8,   /* 16 T */
        11,  /* 17 W */
        12,  /* 18 Y */
        2,   /* 19 V */
        -1   /* core dump and burn if we see this */
    };
    return blstorder;
}

/* ---------------- seqprof_str  ------------------------------
 * Given a pointer to a sequence profile, return it as a
 * printable string.
 */
char *
seqprof_str ( const struct seqprof *profile)
{
    char *ret;
    int i;
    unsigned j;
    size_t k;
    seq_thomas2std (profile->seq);
    scr_reset();
    scr_printf (" ");
    for (i = 0; i < blst_afbet_size; i++)
        scr_printf ("%5c", thomas2std_char ((char) i));
    ret = scr_printf ("\n");
    for (k = 0; k < profile->nres; k++) {
        scr_printf ("%-3c", profile->seq->seq[k]);
        for (j = 0; j < blst_afbet_size; j++)
            scr_printf (" %3.2f", profile->freq_mat [k][j]);
        ret= scr_printf ("\n");
    }
    return (ret);
}

/* ---------------- seqprof_sane   ----------------------------
 * Sanity check for sequence profiles. We write this so it can
 * be called from the interpreter or C. Both are reasonable.
 * Given the name, we return 1 on sane and 0 if silly.
 */
static int
seqprof_sane (const struct seqprof *profile)
{
    const char *this_sub = "seqprof_sane";
    const char *freq_err = "warning: residue %lu aa freqs add to %f\n";
    int ret = 1;
    size_t i, j;
    struct seq *seq = profile->seq;
    if (seq->length != profile->nres) {
        err_printf (this_sub, "Serious seq length %u but prof length %u\n",
                    (unsigned) seq->length, (unsigned)profile->nres);
        ret = 0;
    }
    if (seq->length > 10000) {
        err_printf (this_sub, "warning: seq len %u\n", (unsigned) seq->length);
        ret = 0;
    }
    for (i = 0; i < profile->nres; i++) {
        float f = 0;
        for (j = 0; j < blst_afbet_size; j++)
            f += profile->freq_mat[i][j];
        if (f < 0.01) {
            unsigned a = seq->seq[i];      /* hack for residues without prof */
            profile->freq_mat[i][a] = 1.0;
        } else if ((f < 0.40) || (f > 1.2)) {
            err_printf (this_sub, freq_err, i+1, f);
            return 0;
        }
    }
    return (ret);
}

/* ---------------- blst_chk_read  ----------------------------
 * Read a blast profile / checkpoint file.
 * What should the default be ? Lots of checking or not ?
 * A compromise is to check that the number of residues is
 * plausible and the probabilities in the profile sum to a
 * reasonable number.
 */
struct seqprof *
blst_chk_read (const char *fname)
{
    float **freq_mat;
    FILE *fp_blst    = NULL;
    double *blst_tmp = NULL;
    char *seq_tmp    = NULL;
    struct seq *seq;
    size_t tomall, nelem;
    size_t i, j, k;
    size_t nres;
    int itmp;
    struct seqprof *profile;
    const char *this_sub = "blst_chk_read";

    if ((fp_blst = mfopen (fname, "r", this_sub)) == NULL)
        return NULL;

    
    file_no_cache(fp_blst);
#   define broken_file_no_cache
#   ifndef broken_file_no_cache
    {
        int tmp;
        const char *s = "Turning off caching for %s:\n\"%s\"\n";
        if ((tmp = file_no_cache(fp_blst)) != 0)
            err_printf (this_sub, s, fname, strerror (tmp));
    }
#   endif
    if (fread (&itmp, sizeof (itmp), 1, fp_blst) != 1) {
        err_printf (this_sub, "Failed first read on %s\n", fname);
        goto escape;
    }
    nres = (size_t) itmp;
    seq_tmp = E_MALLOC (((size_t)nres + 1) * sizeof (*seq_tmp));
    if (fread (seq_tmp, sizeof (char), nres, fp_blst) != nres) {
        err_printf (this_sub, "Fail read sequence from %s\n", fname);
        goto escape;
    }
    seq_tmp[nres] = '\0';
    seq = seq_from_string (seq_tmp);
    seq_std2thomas (seq);      /* The sanity checker assumes this conversion */
    free (seq_tmp);

    /* Now come residue frequencies, stored as doubles and using
     * blast encoding.
     * Each residue in turn is a 20 element vector.
     */

    nelem = nres * blst_afbet_size;
    tomall = nelem * sizeof(blst_tmp[0]);
    blst_tmp = E_MALLOC ( tomall );

    if (fread (blst_tmp, sizeof(blst_tmp[0]), nelem, fp_blst) != nelem) {
        err_printf (this_sub, "Fail read a.a. freq from %s\n", fname);
        goto escape;
    }
    fclose (fp_blst);
    freq_mat = f_matrix (nres, MAX_AA);

    for (k = 0; k < nres; k++) {
        memset (freq_mat[k], (int)0.0, MAX_AA * sizeof (freq_mat[0][0])); }
    
    {
        const short int *blstorder = blstorder_table();
        unsigned n = 0;
        for (i = 0; i < nres; i++)
            for (j = 0; j < blst_afbet_size; j++)
                freq_mat[i][blstorder[j]] = (float) blst_tmp [n++];
    }
    free (blst_tmp);


    profile = E_MALLOC (sizeof (*profile));
    profile -> seq = seq;
    profile -> freq_mat = freq_mat;
    profile -> nres = nres;

    if ( ! seqprof_sane (profile))
        err_printf (this_sub, "problem from %s\n", fname);
    
    /* We do return a sequence, even if it appears broken.
     * Normally, this would be wrong, but it seems we have to
     * tolerate a large degree of brokenness.
     */
    return (profile);
 escape:
    free_if_not_null (blst_tmp);
    free_if_not_null (seq_tmp);
    if (fp_blst)
        fclose (fp_blst);
    return NULL;
}

/* ---------------- seqprof_get_seq ---------------------------
 * Analogous to coord_get_seq, this returns a sequence object
 * from a seqprof object. It is copied, so the caller can do
 * whatever it wants.
 */
struct seq *
seqprof_get_seq (struct seqprof *sp)
{
    const char *this_sub = "seqprof_get_seq";
    extern char *null_point;
    if (sp == NULL) {
        err_printf (this_sub, null_point);
        return NULL;
    }
    return (seq_copy (sp->seq));
}

/* ---------------- seqprof_destroy ---------------------------
 */
void
seqprof_destroy (struct seqprof *profile)
{
    if (! profile)
        return;
    if (profile->seq)
        seq_destroy (profile->seq);
    if (profile->freq_mat)
        kill_f_matrix (profile->freq_mat);
    free (profile);
}

#ifdef want_blst_chk_write
/* ---------------- blst_chk_write --------------------------------
 */
int
blst_chk_write (const char *fname, struct seqprof *chk)
{
    size_t itmp;
    size_t j, k, n;
    double *dtmp, *dp;
    FILE *fp_nckp;
    struct seq *sq_tmp;
    const short int *blstorder = blstorder_table ();
    const char *this_sub = "blst_chk_write";

    if ((fp_bckp = mfopen (fname, "w", this_sub)) == NULL)
        return EXIT_FAILURE;
  
    itmp = chk->nres;
    if (fwrite (&itmp, sizeof (itmp), 1, fp_nckp) != 1)
        return 0;
    sq_tmp = seq_copy (chk->seq);
    seq_thomas2std (sq_tmp);
    if (fwrite (sq_tmp->seq, sizeof (char), itmp, fp_nckp) != itmp )
        return EXIT_FAILURE;
    seq_destroy (sq_tmp);
    /* form the blast profile matrix */
    dtmp = E_MALLOC (chk->nres * blst_afbet_size * sizeof (*dtmp));
    dp = dtmp;
    n = 0;
    for (j = 0; j < chk->nres; j++)
        for (k = 0; k < blst_afbet_size; k++)
            dp[n++] = chk->freq_mat[j][blstorder[k]];
    
    if (fwrite (dtmp, sizeof (*dtmp), n, fp_nckp) != n)
        return EXIT_FAILURE;
    
    fclose (fp_nckp);
    free (dtmp);
    return EXIT_SUCCESS;
}

#endif /* want_blst_chk_write */
