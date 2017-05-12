/*
 * 21 mar 2005
 * Read the influence file from an autoclass run for sequence
 * classification and put the numbers into a table.
 * Write code for getting the probability of a sequence fragment.
 * Implementation..
 * This assumes our input is the text results from an autoclass
 * classification and it assumes a corresponding layout of the
 * data. This means we look for characteristic strings and
 * patterns. We do this with a mixture of the posix regex
 * functions and calls to strstr(). In principle, we do not need
 * both, but string matching is so much simpler, it is used to
 * quickly hop over large parts of the input file.
 *
 * $Id: read_ac.c,v 1.3 2008/04/12 18:09:20 torda Exp $
 */

#define _XOPEN_SOURCE 600

#include <errno.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <regex.h>
#include <stdlib.h>
#include <string.h>

#include "amino_a.h"
#include "e_malloc.h"
#include "fio.h"
#include "matrix.h"
#include "mprintf.h"
#include "prob_vec.h"
#include "prob_vec_i.h"
#include "read_ac.h"
#include "read_ac_i.h"
#include "read_seq_i.h"
#include "seq.h"
#include "seqprof.h"
#include "str.h"

/* ---------------- Structures -------------------------------- */

/* A classification is an array of classes, + the number of
 * classes and the number of attributes per class.
 * An attribute is an array of probabilities (aa_prob) for each
 * amino acid.
 */
/* After much experimenting, it looks as if we do not need to
 * store all the numbers that we can read from the classification
 * file. We used to read into a "struct aa_prob". Now, we might
 * as well remove all references to this and just read up the log
 * of probabilities.
 */

#ifdef want_old_aa_prob
struct aa_prob {
    float log_pp;
    float prob_jkl;
    float prob_kl;
};

#endif /* want_old_aa_prob */

/* ---------------- find_line ---------------------------------
 * We are looking for a line containing a string.
 * We will return that line. If the line is not found, return a
 * NULL pointer.
 * We use a buffer, provided by the caller, to store the line.
 * s is the string we are looking for.
 */
static char *
find_line(char *buf, const int size, FILE *fp, const char *s)
{
    do {
        if (fgets (buf, size, fp) == NULL)
            return NULL;
    } while (strstr (buf, s) == NULL);
    return buf;
}

/* ---------------- m_regcomp ---------------------------------
 * This is just a wrapper around the regular expression
 * compilation routine. To do the call properly requires all this
 * extra baggage for printing out errors, so let us do it here.
 * We assume the simplest case of extended regular expressions
 * and no special handling of start or end of string.
 */
static int
m_regcomp ( regex_t *r_compiled, const char *regex)
{
    int r;
    enum { BSIZE = 256 } ;
    char ebuf [BSIZE];
    const int cflags = REG_EXTENDED;
    const char *this_sub = "m_regcomp";
    if ((r = regcomp (r_compiled, regex, cflags))) {
        regerror (r, r_compiled, ebuf, BSIZE);
        err_printf (this_sub, "%s\n", ebuf);
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}

/* ---------------- find_regex --------------------------------
 * Read down the file until we find a line with the wanted
 * regular expression.
 * Return NULL if we do not find it.
 * Read up to max lines. If we want to keep reading, in order to
 * search for a file, set max to 0.
 * Return a pointer (into the buffer) which points to our
 * expression. For example...
 * We are looking for "how" in the string "hello how are we".
 * We will return the address of the buffer + 6.
 */
static char *
find_regex (char *buf, const int size, FILE *fp, const char *regex, int max)
{
    char *ret = NULL;
    regex_t reg;
    int r;
    size_t nmatch = 1;
    regmatch_t pmatch[1];

    if (m_regcomp (&reg, regex))
        goto exit;

    do {                            /* Read lines until either max lines are */
        if (fgets (buf, size, fp) == NULL)     /* read or we find the string */
            goto exit;
        r = regexec(&reg,buf, nmatch, pmatch, 0);
    } while((r == REG_NOMATCH) && (--max != 0) );

    if (r != REG_NOMATCH)
        ret = buf + pmatch->rm_so;
 exit:
    regfree (&reg);
    return ret;
}

/* ---------------- get_n_class -------------------------------
 * Read the classification output and return the number of
 * classes. Returning zero means we found an error.
 */
static size_t
get_n_class (FILE *fp, char *buf, const int bufsiz)
{
    char *s;
    long int l;

    const char *this_sub = "get_n_class";
    const char *class_str = "[0-9]* POPULATED CLASSE";
    if ((s = find_regex ( buf, bufsiz, fp, class_str, 0)) == NULL) {
        err_printf (this_sub, "Failed to find number of classes\n");
        return 0;
    }
    l = strtol (s, NULL, 0);
    return (size_t) l;
}

/* ---------------- get_n_att ---------------------------------
 * Keep reading the file and find the number of attributes in the
 * classification.
 * There is a call to find_regex() below. This used to print an
 * error when it did not find anything. Unfortunately, it the
 * unified code, this may not be an error. We may be reading a
 * file without sequence information.
 */
static size_t
get_n_att (FILE *fp, char *buf, const int bufsiz)
{
    size_t n_att = 1;
    const char *this_sub = "get_n_att";
    const char *parse_fail = "Failed at %s:%d\n";
    const char *look_for = "Looking for regex \"%s\"\n";
    const char *heading = "num                        description ";
    const char *magic_line = "[0-9]+  aa *[0-9] +[0-9].[0-9]+";

    if ( ! find_line (buf, bufsiz, fp, heading)) {
        err_printf (this_sub, parse_fail, __FILE__, __LINE__);
        err_printf (this_sub, look_for, heading);
        return 0;
    }
    if ( ! find_regex (buf, bufsiz, fp, magic_line, 20)) {
#       ifdef want_parse_error
            err_printf (this_sub, parse_fail, __FILE__, __LINE__);
            err_printf (this_sub, look_for, magic_line);
#       endif /* want_parse_error */
        return 0;
    }
    while ( find_regex (buf, bufsiz, fp, magic_line, 1))
        n_att++;
    return n_att;
}

/* ---------------- get_three_num -----------------------------
 * Given a string from the classification file, return the last
 * three floating point numbers on the line.
 * Put the answers into the float pointers.
 * If something breaks, return EXIT_FAILURE;
 */
static int
get_three_num (char *buf, regex_t *three_num,
               float *f1, float *f2, float *f3)
{
    const char *this_sub = "get_three_num";
    float **ff[3];
    regmatch_t pmatch[1];
    size_t nmatch = 1;
    int eflags = 0;
    int i;

    ff[0] = &f1; ff[1] = &f2; ff[2] = &f3;

    errno = 0;
    for (i = 0; i < 3; i++) {
        double d;
        char *tmp;
        if (regexec (three_num, buf, nmatch, pmatch, eflags) != 0)
            return EXIT_FAILURE;
        tmp = buf + pmatch->rm_so;
        d = strtod (tmp, NULL);
        if (errno && (d == 0.0)) {
            err_printf (this_sub, "invalid double number %s\n", buf);
            return EXIT_FAILURE;
        }
        buf += pmatch->rm_eo;
        **(ff[i]) = (float)d;
    }

    return EXIT_SUCCESS;
}

/* ---------------- get_class_wt ------------------------------
 * Given a string like
 *  "CLASS  0 - weight   3   normalized weight 0.500   rela"
 * return the normalised class weight, 0.500, in this case.
 */
static float
get_class_wt (const char *buf)
{
    float f;
    char *s;
    const char *s_n = "normalized weight ";
    const char *this_sub = "get_class_wt";
    if ((s = strstr (buf, s_n)) == NULL) {
        err_printf (this_sub, "Failed to find %s in %s\n", s_n, buf);
        return -1.0;
    }
    s += strlen (s_n);
    f = (float) strtod (s, NULL);
    return f;
}

/* ---------------- read_class --------------------------------
 * We have the overview of the classification, now read up the
 * description of each class. buf is just a line buffer for us to
 * use. aa_clssfcn is the main classification.
 * n_class is the number of the class we are reading.
 * n_val is the number of values a descriptor can have. For this
 * function, it is always 20, the number of amino acids.
 */
static int
read_class (FILE *fp, char *buf, const int bufsiz,
            struct aa_clssfcn *aa_clssfcn, const size_t n_class,
            const size_t num_aa)
{
    float wt;
    int want_new_att = 1;
    int att_num = -1;
    int ret = EXIT_SUCCESS; /* On error, set this and go to escape */
    unsigned aa_seen = 0;
    unsigned att_seen = 0;

    regex_t new_att, next_aa, three_num, get_att_num;

    const char *this_sub = "read_class";
    const char *heading1  = " numb t mtt   description           I-jk";
    /*    00 02 D SM    aa 2 ...............  0.116  h .................. -1.79e+00   3.84e-03  2.30e-02 */

    const char *s_class_wt    = "normalized weight ";
    const char *s_new_att     = "[0-9]+ [0-9]+ .+M +.+[.]+.+[.]+ -*[0-9]";
    /*       n .................. -1.02e+00   1.53e-02  4.26e-02 */
    /* const char *s_next_aa     = "[a-zA-Z] [.]{13}"; */
    const char *s_next_aa     = "[a-zA-Z] [ .]{13}";
    const char *s_three_num   = "-*[0-9][.][0-9]+e[+-][0-9]+";
    /* const char *s_get_att_num = "[0-9]{2,} [DR] +S.+[a-zA-Z0-9] [.]{13}"; */
    const char *s_get_att_num = "[0-9]{2,} [DR] +S.+aa";
    const char *broke_ijk     = "Broke looking for I-jk value in \"%s\"\n";

    if ( ! find_line (buf, bufsiz, fp, s_class_wt))
         return EXIT_FAILURE;

    if ((wt = get_class_wt (buf)) < 0) {
        err_printf (this_sub, "Failed finding class weight on %s\n", buf);
        return EXIT_FAILURE;
    }
    aa_clssfcn->class_wt[n_class] = wt;

    if ( ! find_line (buf, bufsiz, fp, heading1))
         return EXIT_FAILURE;

    if (m_regcomp (&new_att, s_new_att)         == EXIT_FAILURE)
        return EXIT_FAILURE;
    if (m_regcomp (&next_aa, s_next_aa)         == EXIT_FAILURE)
        return EXIT_FAILURE;
    if (m_regcomp (&three_num, s_three_num)     == EXIT_FAILURE)
        return EXIT_FAILURE;
    if (m_regcomp (&get_att_num, s_get_att_num) == EXIT_FAILURE)
        return EXIT_FAILURE;

    while ( fgets (buf, bufsiz, fp) && (att_seen < aa_clssfcn->n_att)) {
        char *p = buf;
        regmatch_t pmatch[1];
        const size_t nmatch = 1;
        int r;
        const int eflags = 0;
        char aa;
        unsigned char t_aa;
        float f1, f2, f3;
        if (want_new_att) {
            aa_seen = 0;
            r = regexec (&get_att_num, p, nmatch, pmatch, eflags);
            if (r != 0)                    /* This is a new attribute, so */
                continue;                  /* first we get the attribute */
            p += pmatch->rm_so;            /* number into att_num */
            att_num = (int) strtol (p, NULL, 0);
            if (r !=0) {
                err_printf (this_sub, broke_ijk, buf);
                ret = EXIT_FAILURE;
                goto escape;
            }
            want_new_att = 0;
        }
        r = regexec (&next_aa, p, nmatch, pmatch, eflags);
        if (r != 0)                  /* Now we are looking for the substring */
            break;                   /* which contains the amino acid letter */
        p += pmatch->rm_so;
        aa = *p++;
        t_aa = std2thomas_char (aa);
        if (get_three_num (p, &three_num, &f1, &f2, &f3) == EXIT_FAILURE) {
            ret = EXIT_FAILURE;
            goto escape;
        }

        aa_clssfcn->log_pp [n_class] [att_num] [t_aa]  = f1;
        if (++aa_seen >= num_aa) {
            want_new_att = 1;
            att_seen++;
        }
    }
 escape:
    regfree (&get_att_num);
    regfree (&next_aa);
    regfree (&new_att);
    regfree (&three_num);

    return ret;
}

/* ---------------- aa_clssfcn_destroy ------------------------
 * This clean up function will be called by the perl interface.
 */
void
aa_clssfcn_destroy( struct aa_clssfcn* aa_clssfcn)
{
    free (aa_clssfcn->class_wt);
    kill_3d_array ((void *)aa_clssfcn->log_pp);
    free (aa_clssfcn);
}

/* ---------------- new_aa_clssfcn-----------------------------
 * Do all the allocating to set up a new classification.
 */
static struct aa_clssfcn *
new_aa_clssfcn ( const size_t n_class, const size_t n_att)
{
    struct aa_clssfcn *aa_clssfcn = E_MALLOC (sizeof (*aa_clssfcn));
    size_t s, t;
    aa_clssfcn->n_class = n_class;
    aa_clssfcn->n_att   = n_att;
    t = sizeof (aa_clssfcn->log_pp[0][0][0]);
    aa_clssfcn->log_pp = d3_array (n_class, n_att, MIN_AA, t);
    s = sizeof (aa_clssfcn->class_wt[0]);
    aa_clssfcn->class_wt = E_MALLOC (n_class * s);
#   ifdef fill_with_a_value_for_debugging
    {
        unsigned i, j, k;
        unsigned n1 = n_class;
        unsigned n2 = n_att;
        unsigned n3 = MIN_AA;
        struct aa_prob boo;
        for (i = 0; i < n1; i++) {
            for (j = 0; j < n2; j++) {
                for (k = 0; k < n3; k++) {
                    boo.log_pp = i; boo.prob_jkl = j; boo.prob_kl = k;
                    aa_clssfcn->aa_prob [i][j][k] = boo;
                }
            }
        }
    }
#   endif  /* fill_with_a_value_for_debugging */
    return aa_clssfcn;
}

/* ---------------- ac_read  ----------------------------------
 * Given a pointer to a filename, read in the data.
 * This is an interface function, visible to the outside world.
 */
struct aa_clssfcn *
ac_read (const char *fname)
{
    FILE *fp;
    size_t n_class, n_att;
    struct aa_clssfcn *aa_clssfcn = NULL;
    size_t i;
    const char *this_sub = "ac_read";

#   ifndef BUFSIZ
        enum {BUFSIZ = 1024};
#   endif
    char buf [BUFSIZ];

    if ((fp = mfopen (fname, "r", this_sub)) == NULL)
        return (NULL);

    if ((n_class = get_n_class (fp, buf, BUFSIZ)) == 0)
        goto end;
    if ((n_att = get_n_att (fp, buf, BUFSIZ)) == 0)
        goto end;

    aa_clssfcn = new_aa_clssfcn ( n_class, n_att);

    for (i = 0; i < n_class; i++) {
        if (read_class (fp, buf, BUFSIZ, aa_clssfcn, i, MIN_AA)==EXIT_FAILURE){
            aa_clssfcn_destroy (aa_clssfcn);
            goto end;
        }
    }
 end:
    fclose (fp);
    return (aa_clssfcn);
}

/* ---------------- ac_size  ----------------------------------
 * Return the fragment length size associated with a
 * classification. This is *not* the number of classes. It will
 * typically be a number between 4 and 9.
 */
size_t
ac_size (const struct aa_clssfcn *aa_clssfcn)
{
    return aa_clssfcn->n_att;
}

/* ---------------- ac_nclass ---------------------------------
 * Return the number of classes in a classification.
 */
size_t
ac_nclass ( const struct aa_clssfcn *aa_clssfcn)
{
    return aa_clssfcn->n_class;
}

/* ---------------- ac_dump  ----------------------------------
 * Print some information about the classification.
 */
void
ac_dump ( const struct aa_clssfcn *aa_clssfcn)
{
    mprintf ("The classification has %ld classes and fragment length of %ld\n",
             (long int) aa_clssfcn->n_class, (long int) aa_clssfcn->n_att);
}

/* ---------------- computeMembershipAAProf --------------------
 */
int
computeMembershipAAProf (float **mship, const struct seqprof *sp,
                         const struct aa_clssfcn *aa_clssfcn)
{
    size_t i, j, k, r;
    const size_t n_pvec = sp->nres - aa_clssfcn->n_att + 1;
    const char *this_sub = "computeMembershipAAProf";

    if (sp->nres < aa_clssfcn->n_att) {
        err_printf (this_sub, "Seq length %d to small for classification %d\n",
                    (int) sp->nres, (int) aa_clssfcn->n_att);
        return EXIT_FAILURE;
    }
    memset (mship[0], 0, aa_clssfcn->n_class * n_pvec * sizeof(mship[0][0]));
    for (i = 0; i < n_pvec; i++){ /* seq loop */
        for (j = 0; j < aa_clssfcn->n_class; j++){
            for (k = 0; k < aa_clssfcn->n_att; k++){ /* Class loop */
                for (r = 0; r < blst_afbet_size; r++) /* amino acid loop */
                    mship[i][j] += aa_clssfcn->log_pp[j][k][r] *
                                   sp->freq_mat[i+k][r];
            }
            mship[i][j] = exp(mship[i][j]);
         }
    }
    return EXIT_SUCCESS;
}

/* ---------------- computeMembershipAA -----------------------
 * mship[s][0] = exp (log_pp[0][0][s]+log_pp[0][1][s+1]+...+
 *                    log_pp[0][n_att][s+n_att])
 * Calculate the probability vectors for a sequence.
 * The answers go straight into mship[][] of dimension n_pvec,
 * and the number of classes.
 * It does *not* multiply by the proper class weight. This should
 * be done by the caller.
 * Return EXIT_SUCCESS / FAILURE.
 */
int
computeMembershipAA (float **mship, struct seq *seq,
                     const struct aa_clssfcn *aa_clssfcn)
{
    size_t i, j, k;
    const char z_aa = 22;
    const char x_aa = 20;
    const size_t n_pvec = seq->length - aa_clssfcn->n_att + 1;
    const char *this_sub = "computeMembershipAA";

    if (seq->length < aa_clssfcn->n_att) {
        err_printf (this_sub, "Seq length %d to small for classification %d\n",
                    (int) seq->length, (int) aa_clssfcn->n_att);
        return EXIT_FAILURE;
    }
    seq_std2thomas (seq);
    memset (mship[0], 0,  n_pvec * aa_clssfcn->n_class * sizeof(mship[0][0]));
    for (i = 0; i < n_pvec; i++){
        for (j = 0; j < aa_clssfcn->n_class; j++){
            for (k = 0; k < aa_clssfcn->n_att; k++){
                unsigned char aa_i = (unsigned char)seq->seq[i+k];
                if (aa_i == z_aa || aa_i == x_aa)
                    continue;
                mship[i][j] += aa_clssfcn->log_pp[j][k][aa_i];
            }
            mship[i][j] = exp(mship[i][j]);
        }
    }
    return EXIT_SUCCESS;
}

/* ---------------- seq_2_prob_vec ----------------------------
 * Take a sequence object and return a probability vector.
 * The probability vector routines are defined elsewhere since
 * they will be used by both sequence and structure based
 * functions.
 * TODO: this function should be shut down, it is deprecated 
 * TODO: use the function in read_ac_strct_i.h instead
 */
struct prob_vec *
seq_2_prob_vec (struct seq *seq, const struct aa_clssfcn *aa_clssfcn)
{
    size_t i, j;
    const char *this_sub = "seq_2_prob_vec";
    struct prob_vec *pvec;
    const size_t prot_len = seq->length;
    const size_t n_pvec = seq->length - aa_clssfcn->n_att + 1;

    pvec = new_pvec (aa_clssfcn->n_att, prot_len, n_pvec, aa_clssfcn->n_class);
    if (!pvec) {
        err_printf (this_sub, "Failed to make probability vector\n");
        return NULL;
    }


    if (computeMembershipAA (pvec->mship, seq, aa_clssfcn) == EXIT_FAILURE ) {
        prob_vec_destroy (pvec);
        return NULL;
    }

    for (i = 0; i < n_pvec; i++) {
        double sum = 0.0;
        for (j = 0; j < aa_clssfcn->n_class; j++) {
            pvec->mship[i][j] *= aa_clssfcn->class_wt[j];
            sum += pvec->mship[i][j];
        }
        for (j = 0; j < aa_clssfcn->n_class; j++)
            pvec->mship[i][j] /= sum;
    }
    pvec->norm_type = PVEC_TRUE_PROB; /* Signal that probabilities are */
                                      /* normalised so they sum to 1.0 */
    return pvec;
}

#ifdef WANT_MAIN
#ifdef GCC
void usage () __attribute__ ((noreturn));
#endif
#include "str.h"

/* ---------------- spielen   ---------------------------------
 */
static void
spielen (const struct clssfcn *aa_clssfcn)
{
    const char *s[] = { "cgac", "ngsn", "npea", NULL};
    char **ss;
    size_t i;
    size_t foo;

    ss = (char **)s;
    foo = aa_clssfcn->n_class;
    do {
        float *per_class = E_MALLOC (foo * sizeof (*per_class));
        str_2_class (aa_clssfcn, per_class, *ss);
        for ( i = 0; i < aa_clssfcn->n_class; i++)
            mprintf ("%s class %4d %.3f\n", *ss, i, per_class[i]);
        free (per_class);
    } while (*(++ss) != NULL);
}

/* ---------------- usage     ---------------------------------
 */
static void
usage (const char *name)
{
    err_printf (name, ": input_file\n");
    exit (EXIT_FAILURE);
}

/* ---------------- main      ---------------------------------
 */
int
main (int argc, char *argv[])
{
    struct aa_clssfcn *aa_clssfcn;
    if (argc !=2)
        usage(argv[0]);
    if ( (aa_clssfcn = ac_read (argv[1])) == NULL)
        return (EXIT_FAILURE);
    spielen (aa_clssfcn);
    aa_clssfcn_destroy (aa_clssfcn);
    return (EXIT_SUCCESS);
}
#endif /* WANT_MAIN */
