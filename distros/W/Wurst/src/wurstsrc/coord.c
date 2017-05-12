/*
 * 23 Oct 2001
 * $Id: coord.c,v 1.3 2008/04/25 15:15:03 mmundry Exp $
 * The struct coord is a rather central item in this code. This
 * file gathers most of the routines for creating the structure,
 * filling out information and cleaning up. The details of the
 * structure live in coord.h, but the public interface is in
 * coord_i.h.
 * At the end of the file are some functions which do some
 * operations on the numbers within the coordinate structure.
 */

#define _XOPEN_SOURCE 500                 /* Necessary on sun to get M_PI */
#include <limits.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>   /* This is non-ansi, but used to time stamp .bin files */

#include "bad_angle.h"
#include "binver.h"
#include "e_malloc.h"
#include "mgc_num.h"
#include "coord.h"
#include "coord_i.h"
#include "dihedral.h"
#include "fio.h"
#include "mprintf.h"
#include "read_seq_i.h"
#include "scratch.h"
#include "sec_s_i.h"
#include "sec_s.h"
#include "str.h"
#include "yesno.h"

/* Notes...
 * This file may be called from programs other than wurst.
 * Do not make it rely on any really secret files.
 * What is acceptable ?
 * We shall make the various e_malloc and mXprintf() routines
 * acceptable, because they are useful.
 */


/* ---------------- Local Structures  -------------------------*/
struct vrsn {
    int major;
    int minor;
};

/* ---------------- Local Constants   -------------------------*/
static const float MAX_DIST2 = 4.0;    /* maximal reasonable squared */
                                       /* distance between two residues */

#define GET_CA     0001   /* Read C alpha coordinates */
#define GET_CB     0002   /*      C beta  */
#define GET_N      0004   /*      peptide nitrogen */
#define GET_C      0010   /*      carbonyl C */
#define GET_O      0020   /*      carbonyl O */
#define GET_ORIG   0040   /*      original residue numbering from PDB file */
#define GET_SEC    0100   /*      secondary structure information */
#define GET_SEQ    0200   /*      protein sequence */
#define GET_ICODE  0400   /*      insertion codes */
#define GET_COMPND 01000  /*      compound description*/

#define GET_ALL \
           (GET_CA|GET_CB|GET_N|GET_C|GET_O|GET_ORIG|GET_SEC|GET_SEQ|GET_ICODE|GET_COMPND)

#ifdef BUFSIZE
#   error Trying to redefine BUFSIZE
#endif
enum { BUFSIZE = 256 };

/* ---------------- e_fgets  ----------------------------------
 * A wrapper around fgets which prints out an error message.
 */
static char *
e_fgets(char *s, const int size, FILE *stream, const char *fname)
{
    const char *this_sub = "e_fgets";
    if ((s = fgets ( s, size, stream)) == NULL)
        err_printf (this_sub, "reading from %s\n", fname);
    return s;
}

/* ---------------- stoi     ----------------------------------
 * String to int wrapper.
 * s is the string to convert.
 * caller is the name of our caller and will go into an error message.
 * i is a pointer to an int where we put the result.
 */
static int
stoi ( const char *s, const char *caller, int *i)
{
    long l = strtol (s, NULL, 10);
    if ((l == LONG_MAX) || (l == LONG_MIN)) {
        mperror (caller);
        return EXIT_FAILURE;
    }
    *i = (int)l;
    if (*i != l)
        err_printf (caller, "Warning: lost precision converting %ld\n", l);
    return EXIT_SUCCESS;
}

/* ---------------- s_to_st  ----------------------------------
 * String to size_t  wrapper.
 * s is the string to convert.
 * caller is the name of our caller and will go into an error message.
 * i is a pointer to an int where we put the result.
 */
static int
s_to_st ( const char *s, const char *caller, size_t *i)
{
    long l = strtol (s, NULL, 10);
    if ((l == LONG_MAX) || (l == LONG_MIN)) {
        mperror (caller);
        return EXIT_FAILURE;
    }
    *i = (size_t)l;
    if (l < 0)
        err_printf (caller, "Warning: negative num should be + %ld\n", l);
    return EXIT_SUCCESS;
}

/* ---------------- file2pdb   --------------------------------
 * Given a string like /blah/zot/pdb1abc.ent, copy "1abc" into
 * the pdb_code string
 */
static int
file2pdb( char pdb_code[ACQ_SIZ], const char *inbuf)
{
    if (!strstr (inbuf, "pdb"))
        if (!strstr (inbuf, "PDB"))
            return EXIT_FAILURE;
    inbuf = strip_path (inbuf);
    inbuf += 3;
    memset (pdb_code, 0, ACQ_SIZ);
    strncpy (pdb_code, inbuf, ACQ_SIZ - 1);
    str_up (pdb_code);
    return EXIT_SUCCESS;
}

/* ---------------- fread_or_toss -----------------------------
 * Sometimes we want to read from a file, sometimes just skip
 * over that part.
 * This routine checks the value of flag.
 * If non-zero, it mallocs the right amount of space, reads
 * into the variable and returns a pointer to the malloc'd
 * space.
 * If flag is not set, we do a fseek over that part of the file.
 * If rev_byte_flag is set, then we have to be willing to do byte
 * order reversal on everything we have read up.  We use the following
 * heuristic...
 * If the size of the object is a multiple of 4, then it is an int or
 * float, so we do a 4 byte swap.  Similarly, 2 byte objects get a 2-byte
 * swap
 */
static int
fread_or_toss (void ** dst, size_t size, size_t nitems, FILE *fp,
               unsigned flag, const char *path, const char *type,
               int rev_byte_flag)
{
    const char *this_sub = "fread_or_toss";
    int res = 0;      /*  To shut up the gcc compiler  */

    if (flag) {
        *dst = E_MALLOC (size * nitems);
        if (nitems != (size_t) (res = fread (*dst, size, nitems, fp))) {
            if (res == 0)
                mperror (this_sub);
            free (*dst);
            goto error;
        }
    } else {
        if (fseek ( fp, size * nitems, SEEK_CUR) != 0) {
            mperror (this_sub);
            err_printf (this_sub, "fseek error\n");
            goto error;
        }
        return EXIT_SUCCESS;
    }
    if (rev_byte_flag) {
        if ( size >= 4) { /* Get ready for byte reversal */
            size_t i, n;
            unsigned int *p = (unsigned int *) *dst;

            if (sizeof (unsigned int) != 4) {
                err_printf (this_sub, "sizeof u_int != 4. Giving up\n");
                goto error;
            }
            n = (size / 4) * nitems;
            for ( i = 0; i < n ; i++)
                BYTE_REVERSE_4 ( p[i] );
        }
        if (size == 2) {
            size_t i;
            short int *p = (short int *) *dst;
            if (sizeof (short int) != 2) {
                err_printf (this_sub, "sizeof short !=2. Giving up\n");
                goto error;
            }
            for ( i = 0; i < nitems; i++)
                BYTE_REVERSE_2 ( p[i] );
        }
    }
    return EXIT_SUCCESS;
error:
    err_printf (this_sub,
                "error from file %s, getting %u items type %s found %d\n",
                path, (unsigned)nitems, type, res);
    return EXIT_FAILURE;
}

/* ---------------- vrsn_int ----------------------------------
 * Convert a string like
 *      $Revision: 1.3 $ version
 * to a pair of integers, 1 and 10.
 */
static int
vrsn_int ( struct vrsn *v, const char *s )
{
    const char *this_sub = "vrsn_int";
    const char *revision = "Revision: ";
    const char *no_ver =
"A file header must contain a version number in the first line\n\
The string \"%s\" was not found.\nGiving up.\n";
    if ((s = strstr (s, revision)) == NULL) {
        err_printf (this_sub, no_ver, revision);
        return EXIT_FAILURE;
    }
    s += strlen (revision);
    if (stoi (s, this_sub, & v->major) == EXIT_FAILURE)
        return (EXIT_FAILURE);

    if ((s = strstr (s, ".")) == NULL) {
        err_printf (this_sub, "no dot (.) found in version string\n");
        return EXIT_FAILURE;
    }
    s++;

    if (stoi (s, this_sub, & v->minor) == EXIT_FAILURE)
        return (EXIT_FAILURE);

    return EXIT_SUCCESS;
}

/* ---------------- str2unit   --------------------------------
 * Convert a unit string to the enumerated type.
 */
static enum units
str2unit (const char *s)
{
    const char *this_sub = "str2unit";
    if ( (strncmp ("nm ", s, 3) == 0) || (strncmp ("NM ", s, 3) == 0) )
        return nm;
    else if ( (strncmp ("a ", s, 2) == 0) || (strncmp ("A ", s, 2) == 0))
        return angstrom;
    else
        err_printf (this_sub, "Tried to convert %s to some unit.\n", s);
    return broken;
}

/* ---------------- coord_new  --------------------------------
 * Very rarely, an outsider (like the model builder) might have
 * cause to ask for a new coordinate structure.
 * This routine allocates memory and returns an empty structure.
 * It is up to the caller or interpreter to call coord_destroy()
 * to clean up.
 */
static struct coord *
coord_new ( void )
{
    struct coord *c;
    c = E_MALLOC (sizeof (*c));
    memset (c, 0, sizeof (*c));
    c->size = 0;
    c->units = angstrom;
    c->chain = '-';
    c->compnd_len = 0;
    c->compnd = NULL;

    return c;
}
/* ---------------- coord_template ----------------------------
 * We want a new coord structure.
 * We are given the size.
 * We might be given an existing coordinate structure. In that case,
 * copy over the sundry information like units.
 * If it is the same size, copy over the internals.
 */
struct coord *
coord_template (const struct coord *c, size_t n)
{
    struct coord *c_new = coord_new();

    size_t i;

    c_new->size    = n;
    if (n) {
        c_new->rp_ca   = E_MALLOC (n * sizeof (*c_new->rp_ca));
        c_new->rp_cb   = E_MALLOC (n * sizeof (*c_new->rp_cb));
        c_new->rp_n    = E_MALLOC (n * sizeof (*c_new->rp_n));
        c_new->rp_c    = E_MALLOC (n * sizeof (*c_new->rp_c));
        c_new->rp_o    = E_MALLOC (n * sizeof (*c_new->rp_o));
        c_new->orig    = E_MALLOC (n * sizeof (*c_new->orig));
        c_new->icode   = E_MALLOC (n * sizeof (*c_new->icode));
        if (c) {
            if (c->psi)
                c_new->psi = E_MALLOC (n * sizeof (*c_new->psi));
            if (c->phi)
                c_new->phi = E_MALLOC (n * sizeof (*c_new->phi));
            if (c->sec_typ)
                c_new->sec_typ = E_MALLOC (n * sizeof (*c_new->sec_typ));
            if (c->compnd)
                c_new->compnd  = E_MALLOC (c->compnd_len * sizeof (c_new->compnd[0]));
        }
    } else {
        c_new->rp_ca   = NULL;
        c_new->rp_cb   = NULL;
        c_new->rp_n    = NULL;
        c_new->rp_c    = NULL;
        c_new->rp_o    = NULL;
        c_new->orig    = NULL;
        c_new->icode   = NULL;
        c_new->psi     = NULL;
        c_new->phi     = NULL;
        c_new->sec_typ = NULL;
        c_new->compnd  = NULL;
    }

    /* Space has been allocated. If there is old data, copy it over. */

    if (c) {
        c_new->units   = c->units;
        for (i = 0; i < ACQ_SIZ; i++)
            c_new->pdb_acq[i] = ' ';
        c_new->chain   = '_';
        if (n && c->sec_typ)
            c_new->sec_typ = E_MALLOC (n * sizeof (*c_new->sec_typ));

        if (n && c->psi)
            c_new->psi = E_MALLOC (n * sizeof (c_new->psi[0]));
        
        if ( n && c->phi)
            c_new->phi = E_MALLOC (n * sizeof (c_new->phi[0]));

        if (c->size == c_new->size) {
            if (c->rp_ca)
                memcpy (c_new->rp_ca, c->rp_ca, n * sizeof (*c->rp_ca));
            if (c->rp_cb)
                memcpy (c_new->rp_cb, c->rp_cb, n * sizeof (*c->rp_cb));
            if (c->rp_n)
                memcpy (c_new->rp_n, c->rp_n, n * sizeof (*c->rp_n));
            if (c->rp_c)
                memcpy (c_new->rp_c, c->rp_c, n * sizeof (*c->rp_c));
            if (c->rp_o)
                memcpy (c_new->rp_o, c->rp_o, n * sizeof (*c->rp_o));
            if (c->orig)
                memcpy (c_new->orig, c->orig, n * sizeof (*c->orig));
            if (c->icode)
                memcpy (c_new->icode, c->icode, n * sizeof(*c->icode));
            if (c->psi)
                memcpy (c_new->psi, c->psi, n * sizeof (*c->psi));
            if (c->phi)
                memcpy (c_new->phi, c->phi, n * sizeof (*c->phi));
            if (c->sec_typ)
                memcpy (c_new->sec_typ, c->sec_typ, n * sizeof (*c->sec_typ));
            if (c->compnd) {
                memcpy (c_new->compnd, c->compnd, c->compnd_len * sizeof (*c->compnd));
                c_new->compnd_len = c->compnd_len;
            }
        }
    }

    return c_new;
}

/* ---------------- coord_read_specific -----------------------
 * This is the inner part of reading coordinates.
 * We have the option of reading up pieces of a coordinate file
 * such as subsets of atoms.
 * The general interface below calls us with the default of
 * reading all atoms.
 * This routine allocates memory which the caller must free.
 * Actually, the caller should call the _destroy() routine below.
 */
static struct coord *
coord_read_specific (const char *fname, const unsigned flags)
{
    enum { FBUFSIZ = 32768 };
    char fbuf [FBUFSIZ];
    FILE *fp;
    struct coord *c;
    char *text;
    size_t n_a, tmp, s;
    int t, err;
    struct vrsn v;
    int rev_byte_flag = 0;
    enum yes_no do_sec_s;
    char inbuf [BUFSIZE];
    static unsigned char first = (char) 1;
    extern const char *prog_bug;
    const char *mismatch = "Type mismatch, ";
    const char *this_sub = "coord_read_specific";
    const char *err_bin =
        "Error reading test binary numbers after header\n";
    const char *no_cache = "Turning off caching for %s:\n\"%s\"\n";


    if ((fp = mfopen (fname, "r", this_sub)) == NULL)
        return NULL;
    if (setvbuf(fp, fbuf, _IOFBF, FBUFSIZ))
        err_printf (this_sub, "warning setvbuf() call failed\n");

    if ((err = file_no_cache(fp)) != 0) {
        if (first) {
            first = 0;
            err_printf (this_sub, no_cache, fname, strerror (err));
        }
    }

    c = coord_new();

    memset ((void *) inbuf, 0, BUFSIZE);
    /* Read header information */
    if (e_fgets (inbuf, BUFSIZE, fp, fname) == NULL)      /* Version info */
        goto error_exit;
    if (EXIT_FAILURE == vrsn_int (&v, inbuf)) {
        err_printf (this_sub, "Failure parsing version line\n");
        goto error_exit;
    }
    if (v.major < 1) {
        err_printf (this_sub, "Version %d too low\n",  v.major);
        goto error_exit;
    }
    if (v.minor < 3) {
        err_printf (this_sub, "Version minor %d too low\n",  v.minor);
        goto error_exit;
    }

    if (e_fgets (inbuf, BUFSIZE, fp, fname) == NULL)   /* num amino acids */
        goto error_exit;
    if (s_to_st (inbuf, this_sub, &n_a) == EXIT_FAILURE)
        goto error_exit;

    if (n_a == 0) {
        err_printf (this_sub, "broken coordinates.\n");
        err_printf (this_sub, "File %s seems to have 0 amino acids.\n", fname);
        goto error_exit;
    }


    if (e_fgets (inbuf, BUFSIZE, fp, fname) == NULL)          /* filename */
        goto error_exit;
    if (file2pdb(c->pdb_acq, inbuf) == EXIT_FAILURE) {
        err_printf (this_sub, "\"pdb\" not found in file\n");
        goto error_exit;
    }
    if (e_fgets (inbuf, BUFSIZE, fp, fname) == NULL)          /* chain ID */
        goto error_exit;
    c->chain = inbuf[6];

    if (e_fgets (inbuf, BUFSIZE, fp, fname) == NULL)              /* Time */
        goto error_exit;
    if (e_fgets (inbuf, BUFSIZE, fp, fname) == NULL)         /* int check */
        goto error_exit;
    if ((tmp = (size_t) strtol ( inbuf, NULL, 10)) != sizeof (int)) {
        err_printf (this_sub, "%s sizeof int in file %d, should be %u\n",
                    mismatch, (int)tmp, (unsigned)sizeof (int));
        goto error_exit;
    }
    if (e_fgets (inbuf, BUFSIZE, fp, fname) == NULL)         /* float check */
        goto error_exit;
    if ((tmp = (size_t) strtol ( inbuf, NULL, 10)) != sizeof (float)) {
        err_printf (this_sub, "%s float size in file %u, should be %u\n",
                    mismatch, (unsigned) tmp, (unsigned) sizeof (float));
        goto error_exit;
    }

    if (e_fgets (inbuf, BUFSIZE, fp, fname) == NULL)       /* units check */
        goto error_exit;
    if ((c->units = str2unit (inbuf)) == broken) {
        err_printf (this_sub, "Invalid units in file: %s\n", fname);
        goto error_exit;
    }

    if (( v.major < 1) || ((v.major == 1) && (v.minor < 7))) {
        err_printf (this_sub, "coordinate version < 1.7 BAD NEWS\n");
        do_sec_s = NO;
    } else {
        if (e_fgets (inbuf, BUFSIZE, fp, fname) == NULL)
            goto error_exit;
        if (strstr (inbuf, "sec_s") == NULL) {
            err_printf (this_sub, "Reading sec struct line in %s\n", fname);
            goto error_exit;
        }
        if (inbuf [0] == '0')
            do_sec_s = NO;
        else
            do_sec_s = YES;
    }

    switch (read_magic_num (fp) ) {
    case BYTE_STRAIGHT:
        break;
    case BYTE_REVERSE:
        rev_byte_flag = 1;     break;
    case BYTE_BROKEN:
        err_printf (this_sub, err_bin);
        goto error_exit;
    }


    /* Now, read coordinates */

    s = sizeof (*(c->rp_ca));       /* Alpha carbons first */
    t = fread_or_toss ((void*) &(c->rp_ca), s, n_a, fp,
                       flags & GET_CA, fname, "CA", rev_byte_flag);
    if (t == EXIT_FAILURE)
        goto error_exit;


    s = sizeof (*text);            /* Amino acid sequence */
    t = fread_or_toss ((void *)&text, s, n_a, fp,
                       flags & GET_SEQ, fname, "seq", rev_byte_flag);
    if (t == EXIT_FAILURE)
        goto error_exit;


    s = sizeof (*(c->rp_cb));          /* Beta carbons */
    t = fread_or_toss ((void *) &(c->rp_cb), s, n_a, fp,
                       flags & GET_CB, fname, "CB", rev_byte_flag);
    if (t == EXIT_FAILURE)
        goto error_exit;


    s = sizeof (* (c->orig));    /* Original residue numbering from PDB file */
    fread_or_toss ( (void *) &c->orig, s, n_a, fp,
                    flags & GET_ORIG, fname, "orig", rev_byte_flag);
    if (t == EXIT_FAILURE)
        goto error_exit;

    if (( v.major < 1) || ((v.major == 1) && (v.minor < 6))) {
        err_printf (this_sub, "coordinate version < 1.6 BAD NEWS\n");
    } else {
        s = sizeof (*(c->rp_n));
        t = fread_or_toss ((void *) &(c->rp_n), s, n_a,
                           fp, flags & GET_N, fname, "N", rev_byte_flag);
        if (t == EXIT_FAILURE)
            goto error_exit;

        t = fread_or_toss ((void *) &(c->rp_c), s, n_a,
                           fp, flags & GET_C, fname, "C", rev_byte_flag);
        if (t == EXIT_FAILURE)
            goto error_exit;

        t = fread_or_toss ((void *) &(c->rp_o), s, n_a,
                           fp, flags & GET_O, fname, "O", rev_byte_flag);
        if (t == EXIT_FAILURE)
            goto error_exit;
    }

    if (( v.major < 1) || ((v.major == 1) && (v.minor < 6))) {
        err_printf (this_sub, "coordinate version < 1.6 BAD NEWS\n");
        goto error_exit;
    } else {
        s = sizeof (c->icode[0]);
        t = fread_or_toss ((void *) &(c->icode), s, n_a,
                           fp, flags&GET_ICODE, fname, "icode", rev_byte_flag);
        if (t == EXIT_FAILURE)
            goto error_exit;
    }

    if (do_sec_s == YES) {
        unsigned i;
        char *tmp_c;
        if (flags & GET_SEC) {
            size_t x = sizeof (*c->sec_typ) * n_a;
            c->sec_typ = E_MALLOC (x);
        }
        s = sizeof (char);
        t = fread_or_toss ((void *) &tmp_c, s, n_a,
                           fp, flags & GET_SEC, fname, "sec_s", rev_byte_flag);
        if (t == EXIT_FAILURE)
            goto error_exit;
        if (flags & GET_SEC) {
            for (i = 0; i < n_a; i++)
                c->sec_typ[i] = char2ss( tmp_c[i]);
            free (tmp_c);
        }
    }

    if (flags & GET_SEQ) {
        text = E_REALLOC (text, sizeof (*text) * (n_a + 1));
        text[n_a] = '\0';
        if ((c->seq = seq_from_thomas (text, n_a)) == NULL)
            goto error_exit;
        free (text);  /* The sequence object has made a copy */
        text = NULL;
    }

    if ((flags & GET_COMPND) && (v.minor > 9)) {   /*read compound information*/
        unsigned compnd = 0;
	if (fread(&compnd, sizeof(compnd), 1, fp) != 1)
            goto error_exit;
	if (rev_byte_flag) {
            switch (sizeof (compnd)) {
            case 2: BYTE_REVERSE_2 (compnd); break;
            case 4: BYTE_REVERSE_4 (compnd); break;
            default: err_printf (this_sub, prog_bug, __FILE__, __LINE__); goto error_exit;
            }
        }
            
        c->compnd_len = compnd;
        if (c->compnd_len > 0) {
            size_t to_mall = c->compnd_len * sizeof (c->compnd[0]);
            c->compnd = E_MALLOC (to_mall);
            t = fread_or_toss ((void *) &c->compnd, s, c->compnd_len,
                               fp, flags & GET_COMPND, fname, "compnd info", rev_byte_flag);
            if ( t== EXIT_FAILURE)
                goto error_exit;
            c->compnd[c->compnd_len-1]='\0';
        }
    }

    file_clear_cache (fp);
    fclose (fp);
    c->size = n_a;

    return c;

error_exit:
    c->size = 0;
    free_if_not_null (c->rp_ca);
    free_if_not_null (c->rp_cb);
    free_if_not_null (c->rp_n);
    free_if_not_null (c->rp_c);
    free_if_not_null (c->rp_o);
    free_if_not_null (c->orig);
    free_if_not_null (c->icode);
    free_if_not_null (c->psi);
    free_if_not_null (c->phi);
    free_if_not_null (c->sec_typ);
    free_if_not_null (text);
    free_if_not_null (c->compnd);
    seq_destroy (c->seq);
    free_if_not_null (c);
    return NULL;

}

/* ---------------- coord_read   ------------------------------
 */
struct coord *
coord_read ( const char *fname )
{
    struct coord *temp;
    const unsigned flags  = GET_ALL;
    temp = coord_read_specific ( fname, flags);
    return temp;
}

/* ---------------- fwrite_err  -------------------------------
 * We are doing this often enough, so it might as well get
 * wrapped into a function. Write a binary record, print an error
 * message on failure and return an appropriate code on success /
 * failure.
 */
static int
fwrite_err (const void * data, size_t size, size_t n_item,
            FILE *fp, const char *d_type, const char *fname)
{
    const char *this_sub = "fwrite_err";
    if (n_item != fwrite (data, size, n_item, fp)) {
        err_printf (this_sub, "Failed writing %s to %s\n", d_type, fname);
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}

/* ---------------- coord_2_bin -------------------------------
 * Given a coordinate structure, write some coordinates to the
 * named file in our .bin format.
 */
int
coord_2_bin (struct coord *c, const char *fname)
{
    FILE *fp = NULL;
    const char *tmps;
    time_t time_now;
    size_t s, tmp, csiz;
    const char *this_sub  = "coord_2_bin";
    extern const char *prog_bug;
    char have_sec = '0';

    if ((fp = mfopen (fname, "w", this_sub)) == NULL)
        goto broken;
    csiz = c->size;
    if (csiz == 0) {
        err_printf (this_sub, "Empty coordinate structure\n");
        goto broken;
    }
    time_now = time (NULL);

    mfprintf (fp, "%s", bin_version());
    mfprintf (fp, "%i aa\n", (unsigned) csiz);
    if (! strstr (c->pdb_acq, "pdb"))
        mfprintf (fp, "pdb");  /* Quirk of reading routines.. Should remove */
    mfprintf (fp, "%s\n", c->pdb_acq);
    mfprintf (fp, "chain %c\n", c->chain);
    mfprintf (fp, "%s", ctime ( &time_now));
    mfprintf (fp, "%u bytes per int\n", (unsigned) sizeof (int));
    mfprintf (fp, "%u bytes per float\n", (unsigned) sizeof (float));
    switch (c->units) {
    case nm:        mfprintf (fp, "nm units\n");  break;
    case angstrom:  mfprintf (fp, "A units\n");  break;
    default:
        err_printf (this_sub, prog_bug, __FILE__, __LINE__);
        goto broken;
    }
    if (c->sec_typ)
        have_sec = '1';
    mfprintf (fp, "%c sec_s\n", have_sec);
    if (write_magic_num (fp) == EXIT_FAILURE)
        goto broken;
    /* Human readable headers all done. Now data */
    s = sizeof (*c->rp_ca);

    if (fwrite_err (c->rp_ca, s, csiz, fp, "CA atoms", fname) == EXIT_FAILURE)
        goto broken;

    s = sizeof (char);

    if ((tmps = seq_get_thomas (c->seq, &tmp)) == NULL) {
        err_printf (this_sub, "Sequence broken writing %s\n", fname);
        goto broken;
    }
    if (fwrite_err (tmps, s, csiz, fp, "sequence", fname) == EXIT_FAILURE)
        goto broken;

    s = sizeof (*c->rp_cb);
    if (fwrite_err (c->rp_cb, s, csiz, fp, "CB atoms", fname) == EXIT_FAILURE)
        goto broken;

    s = sizeof (*c->orig);
    if (fwrite_err(c->orig, s, csiz, fp, "orig names", fname) == EXIT_FAILURE)
        goto broken;

    s = sizeof (*c->rp_n);
    if (fwrite_err (c->rp_n, s, csiz, fp, "N atoms", fname) == EXIT_FAILURE)
        goto broken;

    s = sizeof (*c->rp_c);
    if (fwrite_err (c->rp_c, s, csiz, fp, "CB atoms", fname) == EXIT_FAILURE)
        goto broken;

    s = sizeof (*c->rp_o);
    if (fwrite_err (c->rp_o, s, csiz, fp, "CB atoms", fname) == EXIT_FAILURE)
        goto broken;

    s = sizeof (*c->icode);
    if (fwrite_err (c->icode, s, csiz, fp, "CB atoms", fname) == EXIT_FAILURE)
        goto broken;

    if (c->sec_typ) {  /* Internally, secondary structure is an enumerated */
        size_t i;      /* type. For the output file, we have to convert */
        char *a;       /* to a string array */
        a = E_MALLOC (sizeof (*a) * csiz);
        for ( i = 0; i < csiz; i++)
            a[i] = ss2char (c->sec_typ[i]);
        if (fwrite_err (a, s, csiz, fp, "sec struct", fname) == EXIT_FAILURE) {
            free (a);
            goto broken;
        }
    }

    if (c->compnd) {                         /*store the compound information*/
        unsigned len = (unsigned) c->compnd_len;
        fwrite_err(&len, 4, 1, fp, "compnd_len", fname);
        s = sizeof (char);
        if (fwrite_err (c->compnd, s, c->compnd_len, fp,
                        "compnd info", fname) == EXIT_FAILURE)
            goto broken;
    }

    fclose (fp);
    return EXIT_SUCCESS; /* Happy exit */

    broken:              /* Sad exit */
    if (fp)
        fclose (fp);
    return EXIT_FAILURE;
}

/* ---------------- coord_size  -------------------------------
 * Return the size of the coordinate structure.
 * Should be the number of residues.
 */
size_t
coord_size ( const struct coord *c )
{
    return c->size;
}

/* ---------------- coord_name  -------------------------------
 */
char *
coord_name (struct coord *c)
{
    const char *this_sub = "coord_print_name";
    if (c == NULL) {
        err_printf (this_sub, "---NULL--- coordinates\n");
        return NULL;
    }
    scr_reset();
    return (scr_printf ("%4s%c", c->pdb_acq, c->chain));
}

/* ---------------- coord_get_seq -----------------------------
 * Return the sequence structure hidden within a coordinate
 * structure.
 */
struct seq *
coord_get_seq (struct coord *c)
{
    extern const char *null_point;
    const char *this_sub = "coord_get_seq";
    if (c == NULL) {
        err_printf (this_sub, null_point);
        return NULL;
    }
    return (seq_copy (c->seq));
}

/* ---------------- coord_trim      ---------------------------
 * Sometimes, we ask for a coord struct of a certain size, but
 * then we don't find all the atoms. In that case, trim the
 * arrays back and reset the size.
 */
struct coord *
coord_trim (struct coord *c, const size_t size)
{
    c->size = size;
    c->rp_ca = E_REALLOC (c->rp_ca, size * sizeof (*c->rp_ca));
    c->rp_cb = E_REALLOC (c->rp_cb, size * sizeof (*c->rp_cb));
    c->rp_n  = E_REALLOC (c->rp_n,  size * sizeof (*c->rp_n));
    c->rp_c  = E_REALLOC (c->rp_c,  size * sizeof (*c->rp_c));
    c->rp_o  = E_REALLOC (c->rp_o,  size * sizeof (*c->rp_o));
    c->orig  = E_REALLOC (c->orig,  size * sizeof (*c->orig));
    c->icode = E_REALLOC (c->icode, size * sizeof (*c->icode));
    if (c->psi)
        c->psi = E_REALLOC (c->psi, size * sizeof (c->psi[0]));
    if (c->phi)
        c->phi = E_REALLOC (c->phi, size * sizeof (c->phi[0]));
    if (c->sec_typ)
        c->sec_typ = E_REALLOC (c->sec_typ, size * sizeof (c->sec_typ[0]));
    seq_trim (c->seq, size);
    return (c);
}

/* ---------------- coord_destroy   ---------------------------
 */
void
coord_destroy (struct coord *c)
{
    const char *this_sub = "coord_destroy";
    if (!c) {
        err_printf (this_sub, "null pointer, probable script bug\n");
        return;
    }
    free_if_not_null (c->rp_ca);
    free_if_not_null (c->rp_cb);
    free_if_not_null (c->rp_n);
    free_if_not_null (c->rp_c);
    free_if_not_null (c->rp_o);
    free_if_not_null (c->orig);
    free_if_not_null (c->icode);
    free_if_not_null (c->psi);
    free_if_not_null (c->phi);
    free_if_not_null (c->sec_typ);
    free_if_not_null (c->compnd);
    if (c->seq)
        seq_destroy (c->seq);
    free (c);
}

/* ---------------- coord_has_sec_s --------------------------
 */

int
coord_has_sec_s (const struct coord *c)
{
    const char *this_sub = "coord_has_sec_s";
    if (!c) {
        err_printf (this_sub, "null pointer, probable script bug\n");
        return 0;
    }
    if (c->sec_typ!=NULL)
        return 1;
    return 0;
}

/* ---------------- coord_scale -------------------------------
 */
static void
coord_scale (struct coord *c, float scale)
{
    if (c->rp_ca) {
        struct RPoint *r     = c->rp_ca;
        struct RPoint *rlast = r + c->size;
        for ( ; r < rlast; r++) {
            r->x *= scale;
            r->y *= scale;
            r->z *= scale;
        }
    }
    if (c->rp_cb) {
        struct RPoint *r     = c->rp_cb;
        struct RPoint *rlast = r + c->size;
        for ( ; r < rlast; r++) {
            r->x *= scale;
            r->y *= scale;
            r->z *= scale;
        }
    }
    if (c->rp_n) {
        struct RPoint *r     = c->rp_n;
        struct RPoint *rlast = r + c->size;
        for ( ; r < rlast; r++) {
            r->x *= scale;
            r->y *= scale;
            r->z *= scale;
        }
    }
    if (c->rp_c) {
        struct RPoint *r     = c->rp_c;
        struct RPoint *rlast = r + c->size;
        for ( ; r < rlast; r++) {
            r->x *= scale;
            r->y *= scale;
            r->z *= scale;
        }
    }
    if (c->rp_o) {
        struct RPoint *r     = c->rp_o;
        struct RPoint *rlast = r + c->size;
        for ( ; r < rlast; r++) {
            r->x *= scale;
            r->y *= scale;
            r->z *= scale;
        }
    }
}

/* ---------------- coord_nm_2_a ------------------------------
 * Convert a coordinate structure in nanometers to angstroms.
 */
void
coord_nm_2_a (struct coord *c)
{
    if (c->units != angstrom) {
        c->units = angstrom;
        coord_scale (c, 10.0);
    }
}

/* ---------------- coord_a_2_nm ------------------------------
 * Convert a coordinate structure in angstroms to nanometers.
 */
void
coord_a_2_nm (struct coord *c)
{
    if (c->units == angstrom) {
        c->units = nm;
        coord_scale (c, 0.1);
    }
}

/* ---------------- dist2   ------------------------------------
 * Return the distance squared between two atoms. I know this
 * does not really merit a function, but the code occurs three
 * times in a row below.
 */
static float
dist2 ( const struct RPoint a, const struct RPoint b)
{
    float x, y, z;
    x = a.x - b.x;
    y = a.y - b.y;
    z = a.z - b.z;
    return (x * x + y * y + z * z);
}

/* ---------------- bonds_ok   ---------------------------------
 * A general check for integrity of bonds, to be used by the
 * routines which fill out dihedral angles. This determines the
 * interface (a set of 4 coordinates).
 * Given the coordinates of atoms A, B, C and D, check if the AB,
 * BC, CD distances are all less than MAX_DIST2 (square rooted).
 * There is the unreasonable assumption that one distance suits
 * all.
 */
static enum yes_no
bonds_ok (const struct RPoint a, const struct RPoint b,
          const struct RPoint c, const struct RPoint d)
{
    if (dist2 (a, b) < MAX_DIST2)
        if (dist2 (b, c) < MAX_DIST2)
            if (dist2 (c, d) < MAX_DIST2)
                return YES;
    return NO;
}

/* ---------------- dihedral_check -----------------------------
 * Wrapper around dihedral() function. Check if the bond lengths
 * seem roughly OK.
 * If so, return the dihedral angle. If not, return BAD_ANGLE.
 */
static float
dihedral_check (const struct RPoint a, const struct RPoint b,
                const struct RPoint c, const struct RPoint d)
{
    if (bonds_ok (a, b, c, d) == YES)
        return (dihedral (a, b, c, d));
    else
        return BAD_ANGLE;
}

/* ---------------- coord_calc_psi -----------------------------
 * We may not psi angles calculated, but we may need them.
 * Anyone can all this routine if they are going to need psi
 * angles.
 * The function returns void for the same reasons as coord_calc_phi().
 */
void
coord_calc_psi (struct coord *c)
{
    float *psi;
    size_t i;
    if (c->psi != NULL)
        return;
    c->psi = E_MALLOC (sizeof (psi[0]) * (c->size));
    for ( psi = c->psi, i = 0; i < c->size - 1; i++, psi++)
        *psi = dihedral_check(c->rp_n[i],c->rp_ca[i],c->rp_c[i], c->rp_n[i+1]);
    *psi = dihedral_check (c->rp_n[i], c->rp_ca[i], c->rp_c[i], c->rp_o[i]);
}

/* ---------------- coord_calc_phi -----------------------------
 * We may not have phi angles calculated, but we may need them.
 * Anyone can all this routine if they are going to need phi
 * angles.
 * This function is void since individual angles may be missing,
 * but that is not fatal.
 */
void
coord_calc_phi (struct coord *c)
{
    float *phi;
    size_t i;
    if (c->phi != NULL)
        return;
    c->phi = E_MALLOC (sizeof (phi[0]) * (c->size));
    *(c->phi) = BAD_ANGLE;      /* The first angle in a protein is undefined */

    for ( phi = c->phi+1, i = 1; i < c->size; i++, phi++)
        *phi = dihedral_check(c->rp_c[i-1],c->rp_n[i],c->rp_ca[i], c->rp_c[i]);
}

/* ---------------- coord_psi -----------------------------
 * return the psi angle for residue i
 *
 * shift_min is start of range for shifting
 */
float
coord_psi (struct coord *c, const size_t i, const float shift_min)
{
    if ( c->size-1 <= i)
        return (BAD_ANGLE);

    if (c->psi == NULL)
        coord_calc_psi (c);

    if (c->psi[i] == BAD_ANGLE)
        return (BAD_ANGLE);
    return (c->psi[i]<shift_min ? c->psi[i]+(2 * M_PI) : c->psi[i]);
}

/* ---------------- coord_phi -----------------------------
 * return the phi angle for residue j
 * note: j=0 does not make sense
 *
 * shift_min is start of range for shifting
 */
float
coord_phi (struct coord *c, const size_t j, const float shift_min)
{
    if (j < 1 || c->size <= j)
        return (BAD_ANGLE);

    if (c->phi == NULL)
        coord_calc_phi (c);
    if (c->phi[j] == BAD_ANGLE)
        return (BAD_ANGLE);               /* Don't allow this to be shifted */
    return (c->phi[j] < shift_min ? c->phi[j] + (2 * M_PI) : c->phi[j]);
}


/* ---------------- coord_c_n_dist ----------------------------
 * Given the indices of two residues, return the distance from
 * the carbonyl c of the first, to the backbone N of the
 * second. In a real protein, this is about 1.32 Angstrom.
 * We return either the value or the square of the value. For
 * most applications, we will not need the square root.
 */
float
coord_c_n_dist (const struct coord *c,
                const unsigned int i, const unsigned int j,
                const unsigned int sqrt_flag)
{
    struct RPoint *rc = c->rp_c + i;
    struct RPoint *rn = c->rp_n + j;
    float x = rc->x - rn->x;
    float y = rc->y - rn->y;
    float z = rc->z - rn->z;
    float d2 = (x * x) + (y * y) + (z * z);
    if (d2 < 0.0)
        return 0.0;
    if (sqrt_flag)
        return sqrt (d2);
    else
        return d2;
}
