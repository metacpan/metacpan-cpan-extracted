/*
 * 20 Feb 2002
 * Read secondary structure predictions or assignments in either
 * Rost/PHD format or our manual format.
 * Generally, the philosophy is that we read down for typical
 * lines in the phd output. When we hit the set with
 * the interesting data, we get interesting data to fill
 * out an array of struct pred[].
 *
 * $Id: read_sec.c,v 1.1 2007/09/28 16:57:12 mmundry Exp $
 */

#include <ctype.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "e_malloc.h"
#include "fio.h"
#include "misc.h"
#include "mprintf.h"
#include "read_sec_i.h"
#include "scratch.h"
#include "sec_s.h"
#include "sec_s_i.h"
#include "str.h"

/* ---------------- Constants   --------------------------------
 */
#ifndef SEEK_CUR
    enum { SEEK_CUR = 1 };
#endif
enum  {SKIP, NO_SKIP};
enum man_csi_fmt {
    MAN_FMT,           /* Our manual input format */
    CSI_FMT,           /* CSI input format */
    ROST_FMT,          /* Burkhard Rost, PHDsec format */
    BROKEN_FMT
};

/* ---------------- Structures  --------------------------------
 * These structures are internal. They are for this file only.
 * The publicly visible structure is in read_sec.h.
 * The publicly visible interface to the functions is in read_sec_i.h
 */
struct sec_data {
    enum sec_typ sec_typ;    /* Predicted type like S,H,E.. */
    unsigned char rely;      /* Reliability of prediction from 0 to 9 */
    char res;                /* Amino acid type */
};

struct sec_info {
    struct sec_data *sec_data;
    size_t n;
};


/* ---------------- fill_buf    --------------------------------
 * Fill the buffer.
 * Return number of characters read.
 * Buffer is really n+1 bytes long, so we can safely add a
 * NULL terminator.
 */
static size_t
fill_buf (char *buf, const size_t n, FILE *fp)
{
    size_t r = fread (buf, 1, n, fp);
    buf [ r ] = '\0';
    return r;
}

/* ---------------- find_str_fp --------------------------------
 * Given a file pointer, go forward until we find the string
 * we have been asked for. If we do not find the string, return
 * NULL. If we find it, return a pointer to the start of the
 * string.
 * If the last argument is NO_SKIP, we return with the file
 * positioned at the start of the string we were looking for.
 * If the last argument is SKIP, we return with the file
 * positioned after skipping past the line containing the
 * string we were looking for.
 */
static int
find_str_fp (FILE *fp, const char *s, const int skip)
{
    char *p, *near_end, *near_start;
    char *buf;
    size_t r;
    size_t bufsiz, len, len1;
    int result = EXIT_FAILURE;
    char first = 1;
    const char *this_sub = "find_str_fp";
    enum {BASEBUF = 64512};

    len = strlen (s);
    len1 = len - 1;
    bufsiz = strlen (s) + BASEBUF - 1;
    buf = E_MALLOC (sizeof (buf[0]) * bufsiz + 1 );
    buf [bufsiz] = '\0';
    near_end = buf + BASEBUF;
    near_start = buf + len1;

    r = fill_buf (buf, bufsiz, fp);
    p = NULL;
    do {
        if ((p = strstr (buf, s)))
            break;        /* Found the string */
        if (r < BASEBUF)  /* Short read, so go no further */
            break;
        memmove (buf, near_end, len1);
        first = 0;
    } while ((r = fill_buf (near_start, BASEBUF, fp)));
    if (p) {
        long offs;
        result = EXIT_SUCCESS;
        offs = r - (p - buf);
        if ( ! first)
            offs += len1;
        if (fseek (fp, -offs, SEEK_CUR)) {
            mperror (this_sub);
            result = EXIT_FAILURE;
            goto end;
        }
        if (skip == SKIP)
            if (fgets (buf, bufsiz, fp) == NULL)
                err_printf (this_sub, "Unexpected missing line\n");
    }

 end:
    free (buf);
    return (result);
}

/* ---------------- str_srch_error -----------------------------
 * Look for the specified string in the named file, using the
 * open file pointer.
 * If it is not found, print a clear error message.
 */
static int
str_srch_error (FILE *fp, const char *str, const int skip)
{
    int result = find_str_fp (fp, str, skip);
    const char *this_sub = "str_srch_error";
    if (result != EXIT_SUCCESS) {
        err_printf (this_sub, "Looking for a string \n\n\"%s\"\n\n", str);
        err_printf (this_sub, "It was not found. Failed parsing phd file\n");
    }
    return result;
}

/* ---------------- get_length  --------------------------------
 * parse the line like "blah blah length  78" and retrieve 78
 * Read it as int, but convert to size_t
 */
static size_t
get_length (const char *buf)
{
    char *p;
    int r;
    const char *this_sub = "get_length";
    const char *length = "length";
    if ((p = strstr (buf, "length")) == NULL)
        return 0;
    p += strlen (length);
    sscanf (p, "%d", &r);
    if (r < 0) {
        err_printf (this_sub,
                    "Disaster. PHD ouput suggests sequence length %d\n", r);
        r = 0;
    }
    return ((size_t) r);
}


/* ---------------- fgets_err   --------------------------------
 * This is mainly a wrapper around fgets(), but with some common
 * operations for this file.
 * We are often reading with two features:
 *    - there should be something to read. To stop early is not
 *      just end of file, it is an error
 *    - there is some characteristic signature string that we
 *      expect to find on the line. If it is missing, it is an
 *      error.
 * buf is the buffer of size "n" given by the caller.
 * sig is the characteristic signature, and caller is the caller's
 *     name for error messages.
 */
static char *
fgets_err (char *buf, const int n, FILE *fp,
           const char *sig, const char *caller)
{
    char *r;
    const char *no_sig = "\
Reading phd file, looking for characteristic string, \"%s\"\n\
Input line was\n\
\"%s\"\n";
    if (( r = fgets (buf, n, fp)) == NULL) {
        err_printf (caller, "No characters read\n");
        goto end;
    }
    if (! strstr (buf, sig)) {
        err_printf (caller, no_sig, sig, buf);
        r = NULL;
    }

 end:
    return r;
}

/* ---------------- inner_string -------------------------------
 * The vital lines in PHD output seem to look like
         PHD sec |    HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH  |
 * What we have to do is
 *   0. Read the next line from *fp
 *   1. Check for the signature at the start of the line
 *      like "PHD sec"
 *   2. Extract the text between the pipe symbols
 *      or maybe between first pipe and end of line
 *   3. Terminate the string
 *   4. Return a pointer to the start of the information
 *
 * If we find a newline in the string, replace it with a null terminator.
 *   We are given a buffer of size "n" to play with.
 */
static char *
inner_string (FILE *fp, char *buf, const int n, const char *sig)
{
    char *p, *pend;
    const char *this_sub = "inner_string";
    const char *parsing  =
"Parsing phd output, looking for \"|\"\nTrying in line\n\"%s\".\n ";


    p = fgets_err( buf, n, fp, sig, this_sub);

    p = buf + strlen (sig);  /* Move along by a few characters */
    if ((p = strchr (p, '|')) == NULL) {
        err_printf (this_sub, parsing, buf);
        return NULL;
    }
    p++;  /* We do not want the first "|" */
    pend = NULL;
    if (! (pend = strchr (p, '|')))  /* If we do not see terminator*/
        pend = strchr (p, '\n');     /* chop the string at end of line */
    if (pend)
        *pend = '\0';

    return p;
}

/* ---------------- add_to_pred --------------------------------
 */
static int
add_to_pred (struct sec_data *sec_data, char *seq, char *sec, char *rely,
             size_t *nfound, const size_t nres)
{
    const char *this_sub = "add_to_pred";
    const char *broken = "Non %s, \"%c\" in phd data\n";
    const char *prem   = "Premature end of %s string\n";
    while (*seq && *nfound <= nres) {
        if ( ! *rely) {
            err_printf (this_sub, prem, "rely");
            return EXIT_FAILURE;
        }
        if ( ! *sec) {
            err_printf (this_sub, prem, "sec");
            return EXIT_FAILURE;
        }
        if ( ! *seq) {
            err_printf (this_sub, prem, "sequence");
            return EXIT_FAILURE;
        }
        if ( ! isdigit ((int)*rely)) {
            err_printf (this_sub, broken, "digit", *rely);
            return EXIT_FAILURE;
        }
        if ( ! isprint ((int)*sec)) {
            err_printf (this_sub, broken, "character", *sec);
            return EXIT_FAILURE;
        }
        if ( ! isalpha ((int)*seq)) {
            err_printf (this_sub, broken, "alphabetic", *seq);
            return EXIT_FAILURE;
        }
        sec_data->rely    = *rely - '0';
        sec_data->sec_typ = char2ss (*sec);
        sec_data->res     = *seq;

        sec_data++;
        rely++;
        seq++;
        sec++;
        (*nfound)++;
    }
    return EXIT_SUCCESS;
}
/* ---------------- get_interesting ----------------------------
 * The file pointer, fp, is set at our first interesting line.
 * We expect to get lines in the order of
 *     sequence   ETDQLEDE
 *     sec strct  HHHHHHH
 *     confidence 9998534
 *       other stuff
 *     repeated for rest of sequence.
 */
static struct sec_info *
get_interesting (FILE *fp, const size_t nres)
{
    struct sec_data *sec_data = NULL;
    struct sec_info *sec_info = NULL;
    const char *dots = "...,";
    size_t nfound = 0;
    int r;
    const char *this_sub = "get_interesting";
    sec_data = E_MALLOC (sizeof (sec_data[0]) * nres);

    while (nfound < nres) {
        char b1 [BUFSIZ], b2 [BUFSIZ], b3 [BUFSIZ];
        char *seq  = b1,
             *sec  = b2,
             *rely = b3;

        if (str_srch_error (fp, dots, SKIP) == EXIT_FAILURE)
            goto broken;

        if ((seq  = inner_string (fp, seq,  BUFSIZ, "AA ")) == NULL)
            goto broken;
        if ((sec  = inner_string (fp, sec,  BUFSIZ, "PHD ")) == NULL)
            goto broken;
        if ((rely = inner_string (fp, rely, BUFSIZ, "Rel ")) == NULL)
            goto broken;
        r = add_to_pred (sec_data + nfound, seq, sec, rely, &nfound, nres);
        if (r  == EXIT_FAILURE)
            goto broken;
    }
    if (nres != nfound) {
        err_printf (this_sub, "Looking for %u residues, got %u\n",
                    (unsigned) nres, (unsigned) nfound);
        goto broken;
    }
    sec_info = E_MALLOC (sizeof (*sec_info));
    sec_info->sec_data = sec_data;
    sec_info->n = nfound;

 broken:
    if (sec_info == NULL)
        if (sec_data)
            free (sec_data);
    return (sec_info);
}

/* ---------------- do_phd_read --------------------------------
 */
static struct sec_info *
do_phd_read (const char *fname)
{
    FILE *fp;
    struct sec_info *sec_info = NULL;
    size_t length; /* As given by PHD */

#   ifndef BUFSIZ
        enum {BUFSIZ = 1024};
#   endif
    char buf [BUFSIZ];
    const char *this_sub = "do_phd_read";
    const char *phd1 =
        "SUB: a subset of the prediction, for all residues with";
    const char *phd2 = " protein:";

    if ((fp = mfopen (fname, "r", this_sub)) == NULL)
        return NULL;
    if ( str_srch_error (fp, phd1, SKIP)    == EXIT_FAILURE)
        goto end;
    if ( str_srch_error (fp, phd2, NO_SKIP) == EXIT_FAILURE)
        goto end;
    if (fgets (buf, BUFSIZ, fp) == NULL)
        goto end;
    if ((length = get_length (buf)) == 0) {
        err_printf (this_sub, "Could not find length in PHD output\n");
        goto end;
    }
    sec_info = get_interesting (fp, (size_t) length);
 end:
    fclose (fp);
    return (sec_info);
}

/* ---------------- grow    ------------------------------------
 * When reading manual format data, we grow the sec_info structure
 * as needed.
 */
static void
grow (struct sec_info *sec_info, int max)
{
    struct sec_data *s, *sbase, *slast;
    struct sec_data empty = { NO_SEC, 0, 'z' };
    size_t tomall;
    max = max + 1;
    if (sec_info->n >= (size_t) max)
        return;
    tomall = sizeof (s[0]) * (size_t) max;
    sec_info->sec_data = E_REALLOC (sec_info->sec_data, tomall);
    sbase = sec_info->sec_data + sec_info->n;
    slast = sbase + ( max - sec_info->n);
    for (s = sbase; s < slast; s++)
        *s = empty;
    sec_info->n = max;
}

/* ---------------- add_man_line  ------------------------------
 */
static int
add_man_line (struct sec_info *sec_info, char *p)
{
    const char *sep = " 	-";
    struct sec_data *s, *slast;
    int min, max, rely;
    enum sec_typ sec_typ = ERROR;
    char sec_char = '\0';
    const char *this_sub = "add_man_line";
    min = max = -1;
    rely = 9;                          /* Default is to be very confident */
    if ((p = strtok (p, sep)) == NULL)
        return EXIT_FAILURE;
    if (! isdigit ((int) *p))
        return EXIT_FAILURE;
    min = atoi (p);
    max = min;
    if ((p = strtok (NULL, sep)) == NULL)
        return EXIT_FAILURE;
    if ( isdigit ((int) *p))
        max = atoi (p);
    else
        sec_char = *p;
    if (sec_char == '\0') {
        if ((p = strtok (NULL, sep)) == NULL)
            return EXIT_FAILURE;
        sec_char = *p;
    }
    if ((p = strtok (NULL, sep))) {
        if (isdigit ((int) *p)) {
            rely = atoi (p);
        } else {
            err_printf (this_sub, "Unknown reliability char \"%c\"\n", *p);
            return EXIT_FAILURE;
        }
    }

    max = max - 1;
    min = min - 1;
    if (max < min) {
        err_printf (this_sub, "max %d < min %d\n", max + 1, min + 1);
        return EXIT_FAILURE;
    }
    if ((min < 0) || (max < 0)) {
        err_printf (this_sub, "min or max of residue range < 0\n");
        return EXIT_FAILURE;
    }
    if ((rely < 0) || (rely > UCHAR_MAX)) {
        err_printf (this_sub, "rely %d too small or big\n", rely);
        return EXIT_FAILURE;
    }
    if ((sec_typ = char2ss (sec_char)) == ERROR)
        return EXIT_FAILURE;
    grow (sec_info, max);
    s = sec_info->sec_data + min;
    slast = s + max - min;
    for ( ; s <= slast ; s++) {
        s->sec_typ = sec_typ;
        s->rely = (unsigned char) rely;
    }
    return EXIT_SUCCESS;

}


/* ---------------- do_man_read   ------------------------------
 */
static struct sec_info *
do_man_read (const char *fname)
{
    FILE *fp;
    struct sec_info *sec_info = NULL;
    char *p;
    char buf [BUFSIZ];
    const char *this_sub = "do_man_read";
    int nline = 0;
    if ((fp = mfopen (fname, "r", this_sub)) == NULL)
        return NULL;
    p = get_nline (fp, buf, &nline, BUFSIZ); /* Title not interesting */
    sec_info = E_MALLOC (sizeof (*sec_info));
    sec_info->n = 0;
    sec_info->sec_data = NULL;
    while ( (p = get_nline (fp, buf, &nline, BUFSIZ))) {
        if (add_man_line (sec_info, p) == EXIT_FAILURE) {
            if (sec_info->sec_data)
                free (sec_info->sec_data);
            free (sec_info);
            sec_info = NULL;
            err_printf (this_sub, "Error on input, line %d\n", nline);
            break;
        }
    }

    return (sec_info);
}

/* ---------------- phd_or_manual ------------------------------
 */
static enum man_csi_fmt
guess_fmt (const char *fname)
{
    FILE *fp;
    enum man_csi_fmt r;
    int crap = 0;
    char buf [BUFSIZ];
    const char *this_sub = "guess_fmt";
    if ((fp = mfopen (fname, "r", this_sub)) == NULL)
        return (BROKEN_FMT);
    if (get_nline (fp, buf, &crap, BUFSIZ) == NULL)
        return BROKEN_FMT;
    if (strstr (str_down (buf), "secondary struct"))
        r = MAN_FMT;
    else
        r = ROST_FMT;
    fclose (fp);
    return r;
}

/* ---------------- not_impl -----------------------------------
 * Not implemented yet.
 */
static void
not_impl ( const char *fname, const char *type)
{
    err_printf (__FILE__,
               "Sorry. Reading from %s. %s format not implemented yet\n",
                fname, type);
}

/* ---------------- interesting --------------------------------
 * Decide if a piece of secondary structure information is
 * interesting, worth keeping and worth passing back to the
 * caller.
 */
static int
interesting (struct sec_data *s)
{
    if (s->rely < 2)
        return 0;
    switch (s->sec_typ) {
    case HELIX:
    case EXTEND: return 1;
    case BEND:
    case B_BRIDGE:
    case PI_HELIX:
    case TT_HELIX:
    case TURN:
    case NO_SEC:
    case ERROR:
    default:
        return 0;
    }
}

/* ---------------- squash   -----------------------------------
 * When we read the secondary structure data, it is in a very
 * verbose format. There is a large array, often with very
 * little data in it.  For the sake of tidiness, we squash this
 * down to a smaller, sparse-style structure.
 * So as to avoid lots of calls to realloc(), we allocate for
 * the worst possible case and then call realloc() at the end
 * with the amount of data we actually found.
 */
static struct sec_s_data *
squash ( const struct sec_info *sec_info)
{
    struct sec_data *s, *slast;
    struct sec_s_data *sec_s_data;
    struct sec_datum *datum;
    size_t i, nfound;
    sec_s_data = E_MALLOC (sizeof (*sec_s_data));
    sec_s_data->data = E_MALLOC (sizeof (datum[0]) * sec_info->n);
    
    s = sec_info->sec_data;
    slast = s + sec_info->n;
    datum = sec_s_data->data;
    nfound = 0;
    for ( i = 0; s < slast ; i++, s++) {
        if (interesting (s)) {
            datum->resnum = i;
            datum->sec_typ = s->sec_typ;
            datum->rely = s->rely;
            datum++;
            nfound++;
        }
    }
    sec_s_data->n = nfound;
    sec_s_data->data = E_REALLOC(sec_s_data->data, sizeof (datum[0]) * nfound);

    return sec_s_data;
}

/* ---------------- sec_s_data_destroy -------------------------
 */
void
sec_s_data_destroy (struct sec_s_data *sec_s_data)
{
    if ( !sec_s_data)
        return;
    free_if_not_null (sec_s_data->data);
    free (sec_s_data);
}

/* ---------------- sec_s_data_string --------------------------
 * This is visible to the interpreter. Mostly useful for
 * debugging if it is useful at all.
 */
char *
sec_s_data_string (struct sec_s_data * sec_s_data)
{
    struct sec_datum *datum = sec_s_data->data;
    struct sec_datum *dlast = datum + sec_s_data->n;
    char *p = NULL; /* initialisation only to stop compiler complaints */

    scr_reset();
    scr_printf ("%6s %6s %6s\n", "resnum", "type", "confidence");
    for ( ; datum < dlast; datum++)
        p = scr_printf ("%6u %6c %6u\n",
                        (unsigned) datum->resnum+1,
                        ss2char(datum->sec_typ), datum->rely);
    return p;
}

/* ---------------- read_sec -----------------------------------
 * Interface to reading phd/Rost or manual secondary structure
 * format data.
 * This calls the correct reader and returns either a sec_s_data
 * object or a NULL pointer.
 */
struct sec_s_data *
sec_s_data_read (const char *fname)
{
    struct sec_info *sec_info = NULL;
    struct sec_s_data *sec_s_data = NULL;
    enum man_csi_fmt fmt;
    const char *this_sub = "read_sec";
    fmt = guess_fmt (fname);
    switch (fmt) {
    case ROST_FMT:
        if ((sec_info = do_phd_read (fname)) == NULL)
            err_printf (this_sub, "broken on %s\n", fname);
        break;
    case MAN_FMT:
        if ((sec_info = do_man_read (fname)) == NULL)
            err_printf (this_sub, "broken on %s\n", fname);
        break;
    case CSI_FMT:     not_impl (fname, "CSI");      break;
    case BROKEN_FMT:  break;
    }
    if ( ! sec_info)
        return NULL;
    sec_s_data = squash (sec_info);
    free (sec_info->sec_data);
    free (sec_info);
    return (sec_s_data);
}


#undef TEST_READ_PHD
#ifdef TEST_READ_PHD

/* ---------------- check_reading ------------------------------
 * This is for debugging.
 * Check if we have read the file properly.
 */
static void
check_reading (struct sec_info *sec_info)
{
    struct sec_data *s, *slast;
    int i = 1;
    slast = sec_info->sec_data + sec_info->n;
    for ( s = sec_info->sec_data, i = 0; s < slast; s++, i++)
        mprintf ("%4d, %c %c %d\n", i, ss2char (s->sec_typ), s->res, s->rely);
}


/* ---------------- main   -------------------------------------
 */
int
main (int argc, char *argv[])
{
    const char *this_sub = argv[0];
    while ( --argc ) {
        struct sec_info *sec_info;
        enum man_csi_fmt fmt;
        mprintf ("Working on  %s\n", *++argv);
        fmt = guess_fmt (*argv);
        switch (fmt) {
        case ROST_FMT:
            if ((sec_info = do_phd_read (*argv)) == NULL)
                err_printf (this_sub, "broken on %s\n", *argv);
            break;
        case MAN_FMT:
            if ((sec_info = do_man_read (*argv)) == NULL)
                err_printf (this_sub, "broken on %s\n", *argv);
            break;
        case CSI_FMT:     not_impl (*argv, "CSI");      break;

        case BROKEN_FMT:  not_impl (*argv, "broken");   break;
        }
        if (sec_info) {
            check_reading (sec_info);
            free (sec_info->sec_data);
            free (sec_info);
        }
    }
    return (EXIT_SUCCESS);
}

#endif /* TEST_READ_PHD */
