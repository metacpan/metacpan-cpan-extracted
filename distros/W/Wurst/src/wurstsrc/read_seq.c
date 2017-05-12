/*
 * 21 March 2001
 * $Id: read_seq.c,v 1.1 2007/09/28 16:57:03 mmundry Exp $
 */

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "amino_a.h"
#include "e_malloc.h"
#include "fio.h"
#include "mprintf.h"
#include "read_seq_i.h"
#include "scratch.h"
#include "seq.h"
#include "str.h"

/* ---------------- Constants   ------------------------------- */
#ifndef BUFSIZ
    enum { BUFSIZ = 1024 };
#endif

static const char seq_comment = '>';

/* ---------------- seq_std2thomas ----------------------------
 * Convert a whole sequence to thomas format.
 */
void
seq_std2thomas (struct seq *s)
{
    if (s->format == THOMAS)
        return;
    std2thomas (s->seq, s->length);
    s->format = THOMAS;
}

/* ---------------- seq_thomas2std ----------------------------
 * Convert a whole sequence to thomas format.
 */
void
seq_thomas2std (struct seq *s)
{
    if (s->format == PRINTABLE)
        return;
    thomas2std (s->seq, s->length);
    s->format = PRINTABLE;
}

/* ---------------- trim_fgets  -------------------------------
 * This acts like fgets(), but we want to
 * - hop over blank lines
 * - remove leading white space
 * - remove trailing white space
 * This last point is *not* like fgets() which will transfer
 * trailing newlines.
 */
static char *
trim_fgets (char *lbuf, int maxbuf, FILE *fp, const char comment)
{
    char *pend, *spoint, *s;
    while ((s = fgets (lbuf, maxbuf, fp)) != NULL) {
        size_t len;
        while ( isspace((int)*s ))
            s++;                                     /* First non-blank char */
        if (comment != '\0')
            if ( (spoint = strchr (s, comment)))      /* Find comment marker */
                *spoint = '\0';
        if ((len = strlen (s)) == 0)
            continue;
        for (pend = s + len - 1; pend >= s; pend--)
            if ( isspace ( (int)*pend ) )           /* Delete trailing space */
                { *pend = '\0'; len--;}
            else
                break;
        if (s[0] == '\0')
            continue;
        if (len != 0)
            return s;
    }
    return NULL;

}

/* ---------------- remove_newline ----------------------------
 * Get rid of trailing white space.
 * Return the length of the string.
 */
static size_t
remove_newline (char *s)
{
    size_t x = strlen (s);
    while (isspace((int)s[x-1]) && x) {
        s[x-1] = '\0';
        x--;
    }
    return x;
}

/* ---------------- remove_lead_comment -----------------------
 * Given ">xxxyy", turn it into "xxxyy".
 * In this context, we know the length of the string.
 * We do *not* check if the line starts with a comment, because
 * we would not have been called if it did not.
 */
static void
remove_lead_comment (char *buf, size_t len)
{
    char *plast = buf + len;
    for ( ; buf < plast; buf++)
        *buf = *(buf+1);
}

/* ---------------- no_blnk_num -------------------------------
 * Given a line of input, return it with all white space gone
 * and with any digits removed.
 * Do the work in place, return the new size of the line.
 * We are very cunning and do the work in one pass.
 */
static size_t
no_blnk_num (char *s)
{
    size_t n = 0;
    char *t = s;
    while (*t) {
        while( isspace ((int)*t) || isdigit ((int)*t))
            t++;
        *s++ = *t;
        if (! *t++)
            break;
        n++;
    }
    return n;
}

/* ---------------- seq_ini  ----------------------------------
 * Set up a sequence structure. Put this stuff in here, since
 * we may add or remove bits as we write more code.
 * Now a non-static function.  A little naughtly, but seq_deletion
   depends on being able to get at it.
   Will prob. move later.
 */
void
seq_ini (struct seq *s)
{
    s->seq     = NULL;
    s->comment = NULL;
    s->length  = 0;
    s->format  = PRINTABLE;
}

/* ---------------- seq_trim  ---------------------------------
 * Sometimes a sequence structure begins life with more space
 * allocated than is needed. If so, call this to trim it back
 * the necessary size.
 */
void
seq_trim (struct seq *s, const size_t size)
{
    s->length = size;
    s->seq[size] = '\0';
    s->seq = E_REALLOC (s->seq, (size + 1) * sizeof (s->seq[0]));
}

/* ---------------- seq_copy  ---------------------------------
 * Given a pointer to a sequence, allocate fresh memory, copy
 * the sequence and return the new version.
 * Note, we cannot reliably use strcpy or save_str() to copy the
 * sequence itself. If we have some funny format, it may contain
 * non-character entries.
 */
struct seq *
seq_copy (const struct seq *src)
{
    size_t n = src->length;
    struct seq *dst = E_MALLOC (sizeof (*dst));
    seq_ini (dst);
    if (src->seq)
        dst->seq = save_anything (src->seq, (n+1) * sizeof (src->seq[0]));
    if (src->comment)
        dst->comment = save_str (src->comment);
    dst->length = n;
    dst->format = src->format;
    return dst;
}

/* ---------------- seq_get_1  --------------------------------
 * Given a sequence array, extract out a specified sequence.
 * Return a fully fledged, newly allocated sequence.
 * Sequences are numbered from zero.
 */
struct seq *
seq_get_1 (struct seq_array **ps_a, size_t n)
{
    const struct seq_array *s_a = *ps_a;

    const char *too_many =
        "asked for sequence number %d, but only %d present\n";
    const char *this_sub = "seq_get_1";
    if (n > s_a->n) {
        err_printf (this_sub, too_many, n, s_a->n);
        return NULL;
    }
    return ( seq_copy ( s_a->seqs + n));
}

/* ---------------- seq_check  --------------------------------
 * Do some checks on a sequence.
 * If it looks like crap, free up any allocated memory.
 * Return NULL if it seems broken.
 */
static struct seq *
seq_check (struct seq * s, const char *fname)
{
    const char *this_sub = "seq_check";
    const char *bad_sequence = "Bad sequence from file %s\n";
    if (s->seq == NULL) {
        err_printf (this_sub, bad_sequence, fname);
        free_if_not_null (s->comment);
        free (s);
        s = NULL;
    } else if (seq_invalid (s->seq, s->length)) {
        const char *a = s->seq;
        const char *last = a + s->length;
        err_printf (this_sub, bad_sequence, fname);
        if (s->comment)
            err_printf (this_sub, "Begins..\n>%s\n", s->comment);
        for ( ; a < last; a++) {
            const char *bad_char = "%ld bytes from start, bad char \"%c\"\n";
            if (aa_invalid (*a))
                err_printf (this_sub, bad_char, (long)(a - s->seq), *a);
        }
        free (s->seq);
        free (s->comment);
        free (s);
        s = NULL;
    } else {
        s->seq[s->length] = '\0';
        /*str_down (s->seq);   Why Bother ?. Uncomment if you like this */
    }
    return s;
}

/* ---------------- seq_from_string ---------------------------
 * We can construct a sequence object given a string.
 * This will probably be called from the interpreter, so the
 * string must be in standard name format.
 * The size measure does not include the null terminator,
 * so we have to add one byte room for that.
 * We can't assume it is safe to play with the string (the interpreter
 * might expect it to be left alone). Hence, we make a temporary copy
 * and play in there.
 */
struct seq *
seq_from_string (const char *src)
{
    char *s;
    char *buf = save_str (src);
    struct seq *seq = E_MALLOC (sizeof (*seq));
    const char *cmd_string = "\"a string\""; /* used in error messages */
    size_t y;
    seq_ini (seq);
    s = buf;
    if (s[0] == seq_comment) {
        char *next;
        if ((next = strchr (s, '\n')) == NULL)
            return (seq_check (seq, cmd_string)); /* sneaky way to bail out */
        *next = '\0';
        remove_lead_comment (s, next - s);
        seq->comment = save_str (s);
        s = next + 1;
    }

    if ((y = no_blnk_num (s)) == 0)
        return (seq_check (seq, cmd_string));
    s[y] = '\0';
    seq->seq    = save_str (s);
    seq->length = y;

    free (buf);
    return (seq_check (seq, cmd_string));
}

/* ---------------- seq_from_thomas ---------------------------
 * This is like seq_from_string(), but for sequences in Thomas
 * format. We are given a binary string and have to put it in
 * a sequence structure.
 */
struct seq *
seq_from_thomas (const char *src, size_t n_a)
{
    char *tmpseq;
    struct seq *seq = E_MALLOC (sizeof (*seq));
    seq_ini (seq);
    tmpseq = save_anything (src, n_a);
    tmpseq = E_REALLOC (tmpseq, n_a + 1);
    tmpseq[n_a] = '\0';
    seq->seq = tmpseq;
    seq->length = n_a;
    seq->format = THOMAS;
    return seq;
}

/* ---------------- seq_get_thomas  ---------------------------
 * This returns a pointer to a const char array, which is a null
 * terminated version of the sequence in "thomas" format.
 * It is deliberately const char, so if you want to manipulate it,
 * you have to copy it.
 * Actually, dealing with binaries is so dangerous, we do tell
 * the caller of the size via a size_t pointer.
 */
const char *
seq_get_thomas (struct seq *seq, size_t *n)
{
    *n = 0;
    if (seq == NULL)
        return NULL;
    if (seq->seq == NULL)
        return NULL;
    *n = seq->length;
    seq_std2thomas (seq); /* Force to thomas format */
    return (seq->seq);
}

/* ---------------- seq_read_1 --------------------------------
 * This reads a single sequence from a file pointer.  It stops
 * reading and resets the file pointer if it encounters a
 * ">" at the beginning of a line.  The intention is that it
 * will be used in a future routine which reads possibly
 * multiple sequences from a single file.
 */
static struct seq *
seq_read_1 (FILE *fp, const char *fname)
{
    long pos = ftell (fp);
    struct seq *s = E_MALLOC (sizeof (*s));
    char bigbuf[BUFSIZ];
    char *buf = bigbuf;
    const char *this_sub = "seq_read_1";
    size_t x;
    const char no_comment = '\0';

    seq_ini (s);
    buf[0] = '\0';
    if ((buf = trim_fgets (buf, BUFSIZ, fp, no_comment)) == NULL) {
        free (s);
        return NULL;
    }

    if (buf[0] == seq_comment) {
        x = remove_newline (buf);
        remove_lead_comment (buf, x);
        s->comment = save_str (buf);
    } else {
        x = no_blnk_num (buf);
        s->seq    = save_str (buf);
        s->length = x;
    }
    pos = ftell (fp);
    while (trim_fgets (buf, BUFSIZ, fp, '\0')) {
        size_t a;
        if (buf[0] == seq_comment) {/* No problem, indicates next seq coming */
            if (fseek (fp, pos, SEEK_SET) == -1) {  /* Reset so the routine */
                mperror (this_sub);                 /* starts at right place */
                return NULL;                        /* for next sequence */
            }
            goto end;
        }
        pos = ftell (fp);
        a = no_blnk_num (buf);
        /*        a = remove_newline (buf); */
        s->seq = E_REALLOC (s->seq, s->length + a + 1);
        strncpy (s->seq + s->length, buf, a + 1);
        s->length += a;
    }

 end:    
    return seq_check (s, fname);
}

/* ---------------- seq_read ----------------------------------
 */
struct seq *
seq_read (const char *fname)
{
    FILE *fp;
    const char *this_sub = "seq_read";
    struct seq *s;

    if ((fp = mfopen (fname, "r", this_sub)) == NULL)
        return NULL;

    s = seq_read_1 (fp, fname);

    fclose (fp);

    return s;

}

/* ---------------- seq_read_many -----------------------------
 */
struct seq_array **
seq_read_many (const char *fname, struct seq_array **ps_a)
{
    FILE *fp;
    const char *this_sub = "seq_read_many";

    struct seq *s;
    struct seq_array *s_a;
    struct seq_array ** ret;
    size_t start_num;

    if ((fp = mfopen (fname, "r", this_sub)) == NULL)
        return NULL;

    if (ps_a) {
        s_a = *ps_a;
    } else {
        s_a = E_MALLOC (sizeof (s_a[0]));
        s_a->seqs = NULL;
        s_a->n = 0;
    }
    start_num = s_a->n;
    while ((s = seq_read_1(fp, fname))) {
        s_a->seqs = E_REALLOC (s_a->seqs,(s_a->n + 1) * sizeof (s_a->seqs[0]));
        s_a->seqs[s_a->n] = *s;
        s_a->n++;
        free (s);
    }
    fclose (fp);
    if (s_a->n == start_num) {
        err_printf (this_sub, "No sequences found\n");
        return NULL;
    }
    ret = E_MALLOC (sizeof ( *ret));  /* not getting freed */
    if (ps_a)
        *ps_a = NULL;      /* old address for seq_array is no longer valid */

    *ret = s_a;
    return ret;
}
/* ---------------- seq_num    --------------------------------
 * Return the number of sequences in a sequence array.
 */
size_t
seq_num (struct seq_array **ps_a)
{
    const struct seq_array *s_a = *ps_a;
    return s_a->n;
}

/* ---------------- seq_size   --------------------------------
 * Return the number of characters in our sequence.
 */
size_t
seq_size (const struct seq *seq)
{
    return seq->length;
}

/* ---------------- seq_print_inner ---------------------------
 */
static char *
seq_print_inner (struct seq *seq)
{
    const char *this_sub = "seq_print_inner";
    if ( !seq) {
        err_printf (this_sub, "Warning, called with null sequence\n");
        return NULL;
    }
    if ( !seq->length) {
        mfprintf (stderr, "%s called with empty sequence\n", this_sub);
        return NULL;
    }
    if (seq->comment)
        scr_printf (">%s\n", seq->comment);
    if (seq->format == THOMAS)
        seq_thomas2std (seq);
    return (scr_printf ("%s\n", seq->seq));
    
}
/* ---------------- seq_print  --------------------------------
 */
char *
seq_print (struct seq *seq)
{
    scr_reset();
    return seq_print_inner (seq);
}



/* ---------------- seq_print_many ----------------------------
 */
char *
seq_print_many (struct seq_array **ps_a)
{
    char *ret = NULL;
    struct seq_array *s_a = *ps_a;
    struct seq *s, *slast;
    s = s_a->seqs;
    slast = s + s_a->n;
    scr_reset ();
    scr_printf ("%d sequences\n", s_a->n);
    for ( ; s < slast; s++)
        if ((ret = seq_print_inner (s)) == NULL)
            goto end;
 end:
    return ret;
}

#ifdef want_seq_array_merge
/* ---------------- seq_array_merge   -------------------------
 */
void
seq_array_merge (struct seq_array **pdst, struct seq_array **psrc)
{
    struct seq_array *dst = *pdst,
                     *src = *psrc;
    size_t i, j;
    size_t n = dst->n + src->n;
    dst->seqs  E_REALLOC (dst->seqs, n * sizeof (dst->seqs[0]));
    for (i = dst->n, j = 0; j < src->n; i++, j++)
        dst->seqs[i] = src->seqs[j];
    dst->n = n;
    free (src->seqs);
    free (src);
}

#endif /* want_seq_array_merge */

/* ---------------- seq_destroy_innards -----------------------
 */
static void
seq_destroy_innards (struct seq *s)
{
    free_if_not_null (s->seq);
    free_if_not_null (s->comment);
}

/* ---------------- seq_destroy -------------------------------
 * Free resources for one sequence. This may be called from
 * the interpreter, or as part of destroying an array of
 * sequences.
 */
void
seq_destroy (struct seq *s)
{
    if (!s)
        return;
    seq_destroy_innards (s);
    free (s);
}

/* ---------------- seq_get_res -------------------------------
 * Return the n'th reside from a sequence as a string of three
 * characters.
 */
const char *
seq_get_res (struct seq *s, size_t i)
{
    char c;
    if (s->format  == THOMAS)
        c = thomas2std_char (s->seq[i]);
    else
        c = s->seq[i];
    return (one_a_to_3 (c));
}

/* ---------------- seq_res_is_gly ----------------------------
 * Return 1 if the i'th residue is glycine, 0 otherwise
 */
int
seq_res_is_gly (struct seq *s, size_t i)
{
    char c;
    if (s->format == THOMAS)
        c = thomas2std_char (s->seq[i]);
    else
        c = s->seq[i];
    if (c == 'g' || c == 'G')
        return 1;
    else
        return 0;
}

/* ---------------- seq_array_destroy -------------------------
 */
void
seq_array_destroy (struct seq_array **ps_a)
{
    struct seq_array *s_a = *ps_a;
    struct seq *s, *slast;

    if (s_a == NULL) {
        free (ps_a);
        return;
    }
    s = s_a->seqs;
    slast = s + s_a->n;
    for ( ; s < slast; s++)
        seq_destroy_innards (s);

    free_if_not_null(s_a->seqs);
    free (s_a);
    free (ps_a);
}
