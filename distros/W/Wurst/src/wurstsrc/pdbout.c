/*
 * 30 Oct 2001
 * Write pdb format coordinates
 * $Id: pdbout.c,v 1.1 2007/09/28 16:57:05 mmundry Exp $
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

#include "coord.h"
#include "coord_i.h"
#include "fio.h"
#include "mprintf.h"
#include "read_seq_i.h"
#include "yesno.h"
#include "pdbout_i.h"
#include "seq.h"

#include "scor_set.h"

static const char *REMARK = "REMARK";
static const char *SEQRES = "SEQRES";
static const char *pdb_header = "\
ORIGX1      1.000000  0.000000  0.000000        0.00000\n\
ORIGX2      0.000000  1.000000  0.000000        0.00000\n\
ORIGX3      0.000000  0.000000  1.000000        0.00000\n\
SCALE1      1.000000  0.000000  0.000000        0.00000\n\
SCALE2      0.000000  1.000000  0.000000        0.00000\n\
SCALE3      0.000000  0.000000  1.000000        0.00000\n";
static const char *seq_info_blah ="\
Now the original sequence follows. It probably has more\n\
residues than the model below.\n";

enum { TEXT_LEN = 72 };

/* ---------------- competition_headers -----------------------------
 */
static void
competition_headers (FILE *fp)
{
    mfprintf (fp, "no cptn headers yet\n");
    mfprintf (stderr, "competition headers not written yet !!n");
}

/* ---------------- competition_trailers ----------------------------
 */
static void
competition_trailers (FILE *fp)
{
    mfprintf (fp, "no cptn trailers yet\n");
}


/* ---------------- fn_puts   ---------------------------------
 * Print n characters from a string to the specified file
 * pointer.
 * Precede each line with the identifier given by ident.
 * Print a newline at the end.
 * New on 8/6/98.  Check for errors.  If there is one, return EOF.
 */
static int
fn_puts (FILE *fp, const char *ident, const char *s, unsigned n)
{
    unsigned i;
    int r;
    if ((r = mfputs (ident, fp)) == EOF)
        goto bad_exit;
    if (mfputc (' ', fp)   == EOF)
        goto bad_exit;
    r++;
    for (i = 0; i < n; i++, r++)
        if (mfputc (*s++, fp) == EOF)
            goto bad_exit;
    if ((* --s) != '\n')
        if (mfputc ('\n', fp) == EOF)
            goto bad_exit;
    r++;
    return r;
bad_exit:
    return EOF;
}

/* ---------------- record_prnt -------------------------------
 * We have a few lines to be printed out.  Each must be
 * preceded by a record identifier like "AUTHOR" or "REMARK".
 * Walk down the string and check that there are newlines
 * every "len" characters.  If not, break the string.
 * Try to break the string at a space.  Otherwise, just break
 * the string.
 * fp is obvious
 * ident is a null terminated identifier like "REMARK"
 * s is the string
 * max
 */
static int
record_prnt ( FILE *fp, const char *ident, const char *s, size_t max)
{
    const char *tmp;
    unsigned i;
    /* Maybe we can just print out the string */
    tmp = s;
    i = 0;
    while (*tmp) {
        if (*tmp == '\n') {
            if (fn_puts (fp, ident, s, tmp - s) == EOF)
                return EXIT_FAILURE;
            tmp++;
            s = tmp; i = 0;
            if ( ! *tmp )
                break;
        }
        if (i >= max) {
            if (fn_puts (fp, ident, s, tmp - s) == EOF)
                return EXIT_FAILURE;
            if (*(tmp) == '\n' )
                tmp++;
            s = tmp; i = 0; 
        }
        tmp++;
        i++;
    }
    if ( tmp != s)
        if (fn_puts (fp, ident, s, tmp - s) == EOF)
            return EXIT_FAILURE;
    return EXIT_SUCCESS;
}

/* ---------------- my_strftime -------------------------------
 * There is a bug in the warnings emitted by some versions of
 * gcc. They complain about the %c format in strftime. This hack
 * obscures the argument sufficiently that gcc will not complain.
 */
static size_t
my_strftime (char *s, const size_t max, const char *fmt, const struct tm *tm)
{
    return strftime (s, max, fmt, tm);
}

/* ---------------- time_prnt ---------------------------------
 * Print out the time and date in a remark record.
 * We used to use ctime() here, but it is non-reentrant. This
 * means we have to use a non-ANSI function. The POSIX manual
 * says to use strftime() for maximum portability, so we do.
 * To avoid a gcc warning, we have to use a little wrapper around
 * strftime().
 */
static void
time_prnt (FILE *fp, const char *ident, size_t max)
{
    time_t clck;
    
    enum {BSIZE = 128};
    char timebuf [BSIZE];
    
    if ((clck = time (NULL)) == 0)
        return;                /* Don't even print an error.  Not important */
    
    if ( !my_strftime(timebuf, BSIZE, "%c", localtime(&clck)))
        strcpy (timebuf, "Time Unknown");
    record_prnt (fp, ident, timebuf, max);
}

/* ---------------- xp   --------------------------------------
 * Helper routine, printf wrapper used by coord_out.
 * It is just for printing out ATOM records.
 */
static void
xp (FILE *fp, int at_i, const char *at_nam, const char *res_name,
    short res_i, char icode, float x, float y, float z, float occ, float b_fac)
{
    const char *aline =
        "ATOM  %5u  %-2s  %s %5d%c   %8.3f%8.3f%8.3f%6.2f%6.2f\n";
    mfprintf (fp, aline, at_i, at_nam, res_name, res_i, icode,
              x, y, z, occ, b_fac);
}



/* ---------------- do_coord_2_pdb  ---------------------------------
 * This actually spits the coordinates out. Unlike earlier
 * version, we do not currently allow for fancy occupancy or
 * b-factors.  That is, unless *scr is non-NULL.
 */
static int
do_coord_2_pdb (FILE *fp, struct coord *c, float *scr)
{
    size_t i;
    int r_crct = 0;
    int at_i;

    at_i = 1;
    if (scr==NULL) {
        const float occ   = 1.,
            b_fac = 1.;

        for (i = 0; i < c->size; i++) {
            struct RPoint *rp;
            const char * res_name =  seq_get_res (c->seq, i);
            if ((rp = c->rp_n) != NULL)
                xp (fp, at_i++, "N", res_name, c->orig[i] - r_crct, c->icode[i],
                    rp[i].x, rp[i].y, rp[i].z, occ, b_fac);
            
            if ((rp = c->rp_ca) != NULL)
                xp (fp, at_i++, "CA", res_name, c->orig[i] - r_crct, c->icode[i],
                    rp[i].x, rp[i].y, rp[i].z, occ, b_fac );
            
            if ((rp = c->rp_c) != NULL)
                xp (fp, at_i++, "C", res_name, c->orig[i] - r_crct, c->icode[i],
                    rp[i].x, rp[i].y, rp[i].z, occ, b_fac );
            
            if ((rp = c->rp_o) != NULL)
                xp (fp, at_i++, "O", res_name, c->orig[i] - r_crct, c->icode[i],
                    rp[i].x, rp[i].y, rp[i].z, occ, b_fac );
            
            if ( (rp = c->rp_cb) != NULL && (seq_res_is_gly (c->seq, i) != 1))
                xp (fp, at_i++, "CB", res_name, c->orig[i] - r_crct, c->icode[i],
                    rp[i].x, rp[i].y, rp[i].z, occ, b_fac );
        }
    } else {
        float *bfac = scr; /* scr is preformed to the correct length */
        const float occ = 1.;
        for (i = 0; i < c->size; i++, bfac+=1) {
            struct RPoint *rp;
            const char * res_name =  seq_get_res (c->seq, i);
            
            if ((rp = c->rp_n) != NULL)
                xp (fp, at_i++, "N", res_name, c->orig[i] - r_crct, c->icode[i],
                    rp[i].x, rp[i].y, rp[i].z, occ, *bfac);
            
            if ((rp = c->rp_ca) != NULL)
                xp (fp, at_i++, "CA", res_name, c->orig[i] - r_crct, c->icode[i],
                    rp[i].x, rp[i].y, rp[i].z, occ, *bfac);
            
            if ((rp = c->rp_c) != NULL)
                xp (fp, at_i++, "C", res_name, c->orig[i] - r_crct, c->icode[i],
                    rp[i].x, rp[i].y, rp[i].z, occ, *bfac);
            
            if ((rp = c->rp_o) != NULL)
                xp (fp, at_i++, "O", res_name, c->orig[i] - r_crct, c->icode[i],
                    rp[i].x, rp[i].y, rp[i].z, occ, *bfac);
            
            if ( (rp = c->rp_cb) != NULL && (seq_res_is_gly (c->seq, i) != 1))
                xp (fp, at_i++, "CB", res_name, c->orig[i] - r_crct, c->icode[i],
                    rp[i].x, rp[i].y, rp[i].z, occ, *bfac);
        }

    }
    return EXIT_SUCCESS;
}
/* ---------------- seq_info_print  ---------------------------------
 * Write out sequence information. Perhaps this should be preceded by
 * SEQRES lines for pure PDB-ness. At the same time, our sequence may
 * be longer than the number of atoms we have coordinates for, so we
 * use REMARK records for the moment.
 * The rest of the rules come from PDB -Number each line, 13 residues
 * to a line and so on.
 */
static void
seq_info_print (FILE *fp, struct seq *seq)
{
    unsigned lcount = 1;
    unsigned rescount = 0;
    unsigned todo = seq->length;

    record_prnt ( fp, REMARK, seq_info_blah, 65);

    while ( todo ) {
        unsigned i;
        char buf [100];
        char baby [5];
        const char cid = ' ';   /* Chain identifier */
        unsigned now = 13;      /* Magic number from pdb format */
        if (todo < now)
            now = todo;
        buf [0] = '\0';
        sprintf (buf, "%6s  %2u %c %4u ", SEQRES, lcount++, cid,
                 (unsigned) seq->length);
        for ( i = 0; i < now; i++) {
            baby[0] = ' ';
            baby[4] = '\0';
            strncpy (baby + 1, seq_get_res (seq, rescount++), 3);
            strcat (buf, baby);
        }
        strcat (buf, "\n");
        todo -= now;
        mfprintf (fp, buf);
    }
}

/* ---------------- inner_coord_2_pdb -------------------------------
 * The *seq pointer is only used to print out the original sequence
 * if one wants it. If it is NULL, we do not worry. This is
 * mainly for Thomas' routines to extract tinker information.
 * Similarly, the *scr point is only if a pairset with local scores
 * was also passed to the routine to be written as the occupancy
 * entry for each residue.
 */
static int
inner_coord_2_pdb ( const char *fname, struct coord *c, enum yes_no cptn_flag,
                    struct seq *seq, struct scor_set *scr)
{
    FILE *fp;
    const char *this_sub = "coord_2_pdb";
    float *scores;
    if ((fp = mfopen (fname, "w", this_sub)) == NULL)
        return EXIT_FAILURE;

    time_prnt (fp, REMARK, TEXT_LEN);
    if (cptn_flag == YES)
        competition_headers (fp);
    else
        mfprintf (fp, pdb_header);

    if (seq)
        seq_info_print (fp, seq);

    if (c->units == nm)                /* Get rid of nanometers if necessary */
        coord_nm_2_a (c);

    seq_thomas2std (c->seq);              /* Force standard amino acid names */
    if (scr!=NULL) {             /* a vector of temp factors from the scores */
        scores = scr->scores;
    } else
        scores = NULL;
    do_coord_2_pdb (fp, c, scores);

    if (cptn_flag == YES)
        competition_trailers (fp);

    if (fclose (fp)) {
        mperror (this_sub);
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}

/* ---------------- coord_2_pdb -------------------------------
 * Return EXIT_SUCCESS or EXIT_FAILURE.
 */
int
coord_2_pdb (const char *fname, struct coord *c, struct seq *seq)
{
    enum yes_no cptn_flag = NO;
    return (inner_coord_2_pdb (fname, c, cptn_flag, seq, NULL));
}

/* ---------------- coord_2_cptn ------------------------------
 * This is the sam as coord_2_pdb, but first writes some headers
 * and notes for competition files.
 */
int
coord_2_cptn (const char *fname, struct coord *c, struct seq *seq)
{
    enum yes_no cptn_flag = YES;
    return (inner_coord_2_pdb (fname, c, cptn_flag, seq, NULL));
}
/* ---------- coord_2_spdb ------------------------------
 * This, contrary to the above comment, adds local scores
 * as a temperature factor in the generated pdb file.
 */
int
coord_2_spdb ( const char *fname, struct coord *c,
               struct seq *seq, struct scor_set *scr) {
    enum yes_no cptn_flag = NO;
    return (inner_coord_2_pdb (fname, c, cptn_flag, seq, scr));
}
