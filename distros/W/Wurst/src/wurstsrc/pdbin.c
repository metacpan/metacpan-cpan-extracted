/*
 * 23 Mar 2002
 * Read a pdb file. Return a model.
 * $Id: pdbin.c,v 1.1 2007/09/28 16:57:13 mmundry Exp $
 */

#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "amino_a.h"
#include "coord.h"
#include "coord_i.h"
#include "e_malloc.h"
#include "fio.h"
#include "mprintf.h"
#include "pdbin_i.h"
#include "read_seq_i.h"
#include "str.h"
#include "vec_i.h"
#include "yesno.h"

/* ---------------- Constants   -------------------------------------
 * We have a bunch of switches in the code. These could /
 * should be passed in. For the moment, we set them here.
 */

static const float CC_BOND = 1.54;

/* 28 May 96
 * Format for ATOM records in a PDB file.
 */

enum {
    SERIAL =       7,      /* int, atom serial number */
    SERIAL_LEN =   5,
    AT_NAM =      12,      /* char *, atom name */
    AT_NAM_LEN =   4,
    ALT_LOC =     16,      /* alternate location indicator */
    ALT_LOC_LEN =  1,
    RES_NAM =     17,
    RES_NAM_LEN =  3,
    CHAIN_ID =    21,
    CHAIN_ID_LEN = 1,
    RES_SEQ =     22,
    RES_SEQ_LEN =  4,
    ICODE =       26,      /* Code for insertion of residues */
    ICODE_LEN =    1,
    X_START =     30,
    X_LEN =        8,
    Y_START =     38,
    Z_START =     46,
    OCC =         54,
    OCC_LEN =      6,
    BFAC =        60,
    BFAC_LEN =     6,
    SEG_ID =      72,      /* Segment identifier, left-justified */
    SEG_ID_LEN =   4,
    ELEM =        76,     /* Element symbol, right-justified */
    ELEM_LEN =     2,
    CHARGE =      78,
    CHARGE_LEN =   2
};



/* ---------------- Structures  -------------------------------------
 */
/* This is really a copy of an ATOM record from a PDB file.
 */
struct atompdb {
    int at_num;
    char at_name[5];
    char alt_loc;
    char res_name[4];
    char chain_id;
    int res_num;
    char icode;
    float x, y, z;
    enum yes_no wanted;
    char error;
};

struct allatoms {
    struct atompdb *atoms;
    size_t n;
};

struct bin_res { /* Bare number of atoms to make a residue worthwhile */
    struct RPoint rp_ca,
                  rp_cb,
                  rp_n,
                  rp_c,
                  rp_o;
};

enum at_type {
    BORING,
    CA,          /* A list of atom types we save and write out */
    CB,
    N,
    C,
    O
};

struct atom_ok {
    unsigned int ca : 1;
    unsigned int cb : 1;
    unsigned int n  : 1;
    unsigned int c  : 1;
    unsigned int o  : 1;
};

/* ---------------- at_type    --------------------------------
 * Given a line from a PDB file, decide if it is interesting or not.
 * This means, check if it contains coordinates of an atom we know
 * about.
 */
static enum at_type
get_at_type (const char *at_nam)
{
    if (strncmp (at_nam, "CA", AT_NAM_LEN) == 0)
        return CA;
    if (strncmp (at_nam, "CB", AT_NAM_LEN) == 0)
        return CB;
    if (strncmp (at_nam, "C", AT_NAM_LEN) == 0)
        return C;
    if (strncmp (at_nam, "N", AT_NAM_LEN) == 0)
        return N;
    if (strncmp (at_nam, "O", AT_NAM_LEN) == 0)
        return O;
    if (strncmp (at_nam, "OXT", AT_NAM_LEN) == 0)
        return O;  /* we accept these as oxygens, as well */
    return BORING;
}

/* ---------------- nothing_atom ------------------------------------
 * Return an empty atom structure. This is syntactic decoration only,
 * but makes some bits tidier.
 */
static struct atompdb
nothing_atom ( void )
{
    struct atompdb nothing = {
        -1,               /* at_num */
        "",               /* at_name */
        '\0',             /* alt_loc */
        "",               /* res_name */
        '\0',             /* chain_id */
        -1,               /* res_num */
        ' ',              /* insertion code */
        -99., -99., -99., /* x, y, z */
        YES,              /* wanted, interesting */
        NO,               /* an error in this line */
    };
    return nothing;
}

/* ---------------- line2atom   -------------------------------------
 * Take an atom record, and split it into pieces, filling out an
 * atompdb structure.
 */
static struct atompdb
line2atom (char *inbuf)
{
    char s[64]; /* Just a little holding buffer */
    struct atompdb a = nothing_atom();
    long i;
    const char *this_sub = "line2atom";
    char c;
    if ((c = *(inbuf + ALT_LOC)) == ' ')
        a.alt_loc = '\0';
    else
        a.alt_loc = c;
    memset (s, 0, 64);
    strncpy (s, inbuf + AT_NAM, AT_NAM_LEN);
    strncpy (a.at_name, strip_blank (s), AT_NAM_LEN);
    strncpy (a.res_name, inbuf + RES_NAM, RES_NAM_LEN);
    a.chain_id = *(inbuf + CHAIN_ID);
    errno = 0;
    errno = 0;
    i = strtod ( inbuf + RES_SEQ, NULL);
    if (i == 0 && errno == ERANGE) {
        if (errno) {
            err_printf (this_sub, "Res num error in line\n%s\n", inbuf);
            mperror (this_sub);
            a.error = YES;
            return a;
        }
    } else {
        a.res_num = i;
    }
    a.icode = *(inbuf + ICODE);
    if (sscanf (inbuf + X_START, "%8f%8f%8f", &a.x, &a.y, &a.z) != 3){
        err_printf (this_sub, "Error xyz on \n%s\n", inbuf);
        a.error = YES;
    }
    return a;
}

/* ---------------- get_atoms   -------------------------------------
 * This is a lumpy function that just swallows up all ATOM records
 * in its path. It does little filtering or checking.
 * There is a switch. If take_hetatom, then we accept HETATOM records
 * as well. These days, we have to allow for MSE residues and converting
 * them to MET.
 */
static struct allatoms
get_atoms (FILE *fp, const char chain, const enum yes_no take_hetatom)
{
    struct atompdb *atoms;
    enum {MAXLINE = 100};
    char inbuf [MAXLINE];
    const char* ATOM= "ATOM";
    const char* HETATM = "HETATM";
    const char* ENDMDL = "ENDMDL";
    struct allatoms allatoms = {NULL, 0};
    while (fgets (inbuf, MAXLINE, fp)) {
        struct atompdb tempatom;
        if (strncmp (inbuf, ENDMDL, 6) == 0)
            break;
        if (take_hetatom == NO) {
            if (strncmp (inbuf, ATOM, 4) != 0)
                continue;
        } else {                              /* accept HETATM lines */
            if ((strncmp (inbuf, ATOM, 4) != 0)
                && (strncmp (inbuf, HETATM, 6) != 0))
                continue;
        }
        if (chain)
            if (inbuf [CHAIN_ID] != chain)
                continue;
        tempatom = line2atom (inbuf);
        if (! tempatom.error) {
            atoms = allatoms.atoms;
            allatoms.n++;
            atoms = E_REALLOC (atoms, allatoms.n * sizeof (atoms[0]));
            atoms[allatoms.n - 1] = tempatom;
            allatoms.atoms = atoms;
        }
    }
    /* We add a dummy atom at the end, to make parsing easier
       below */
    atoms = allatoms.atoms;
    allatoms.n++;
    atoms = E_REALLOC (atoms, allatoms.n * sizeof (atoms[0]));
    atoms[allatoms.n - 1] = nothing_atom();
    allatoms.atoms = atoms;
    return allatoms;
}

/* ---------------- make_cb     -------------------------------------
 */
static struct RPoint
make_cb ( struct bin_res res)
{
    struct RPoint *ca = &res.rp_ca,
                  *n  = &res.rp_n,
                  *c  = &res.rp_c;

    struct RPoint cx, prd, av, result;
    vector_difference (n, ca, n);
    vector_difference (c, ca, c);
    vec_nrm (n, n, vector_length (c));
    vector_add (&cx, n, c);
    vec_nrm (&cx, &cx, CC_BOND);
    vec_nrm (&prd, vector_product (&prd, n, c), CC_BOND);
    vector_add (&av, vec_scl (&cx, &cx, -1.0), vec_scl (&prd, &prd, -1.5));
    vec_nrm (&av, &av, CC_BOND);
    vector_difference (&result, ca, &av);
    return (result);
}

/* ---------------- residue_ok  -------------------------------------
 * We are given the five atoms of interest. Let's see if they are
 * all there. If the beta carbon is missing, add it.
 */
static int
residue_ok (struct bin_res *res, struct atom_ok atom_ok)
{
    /* debug till I bleed from all orifices. Compare the
       calculated and real cb positions. */

#   ifdef debug_till_i_bleed_from_all_orifices
    if (atom_ok.ca && atom_ok.cb && atom_ok.n && atom_ok.c && atom_ok.o) {
        struct bin_res tmp_res = *res;
        struct RPoint check = make_cb (tmp_res);
        float diff =
            vector_length (vector_difference (&check, &check, &res.rp_cb));
        mprintf ("Diff %.2f\n", diff);
    }
#   endif /* debug_till_i_bleed_from_all_orifices */
    if ( ! atom_ok.cb ) {
        struct bin_res tmp_res = *res;
        if (atom_ok.n && atom_ok.ca && atom_ok.c && atom_ok.o) {
            res->rp_cb = make_cb ( tmp_res );
            atom_ok.cb = 1;
        }
    }
    if (atom_ok.ca && atom_ok.cb && atom_ok.n && atom_ok.c && atom_ok.o)
        return 1;                       /* Most common case, all OK. */
    else
        return 0;
}

/* ---------------- add_to_coord ------------------------------------
 *
 */
static void
add_to_coord (struct coord *coord, const struct bin_res res, const size_t done,
              const int res_num, const char icode)
{
    coord->rp_ca[done] = res.rp_ca;
    coord->rp_cb[done] = res.rp_cb;
    coord->rp_n[done]  = res.rp_n;
    coord->rp_o[done]  = res.rp_o;
    coord->rp_c[done]  = res.rp_c;
    coord->icode[done] = icode;
    coord->orig[done]  = res_num;
    return;
}

/* ---------------- atoms2mdl   -------------------------------------
 * We have a great big pile of atoms. Some are nice. Some not so nice.
 * Copy the ones we are interested in over to the model / coordinate
 * structure. We do something radical to the sequence. If we do not
 * recognise a residue, we turn it into ALA. Consequences:
 * We get coordinates for everything + if it is some other kind of
 * hetatm, the code which looks for backbone atoms will reject it.
 * Some structures are initialised with rubbish values. The initialisation
 * should not be necessary, but some/most compilers cannot see
 * that at compile time. We use crazy values to provoke problems
 * if the values are not initialized properly.
 */
static struct coord *
atoms2mdl (struct allatoms allatoms)
{
    struct coord *coord;
    struct atompdb *atoms, *alast;
    char *seq_str;
    size_t nres, done, i;
    int last_res_num;
    struct atom_ok atom_ok;
    const struct bin_res junk_res = {
        {9999., 9999., 9999.}, {9999., 9999., 9999.}, {9999., 9999., 9999.},
        {9999., 9999., 9999.},{9999., 9999., 9999.}
    };
    const struct RPoint rp_junk = {9999., 9999., 9999.};
    struct bin_res tmpres = junk_res;
    char last_icode;
    const struct atom_ok atom_not_ok = {0, 0, 0, 0, 0};
    const char *this_sub = "atoms2mdl";
    const char *bust =
        "Broke after trim. coord size: %u, done: %u, str_len: %u\n";
    
    if (allatoms.n < 5)
        return (NULL);  /* Don't even bother with this stuff */
    /* Pass over and check we do not have any broken residue types */
    atoms = allatoms.atoms;
    alast = atoms + allatoms.n;
    for ( ; atoms < alast - 1; atoms++) {
        if ( ! three_a_to_1 ( atoms->res_name )) {
            strncpy (atoms->res_name, "ALA", 4); } }
    /* Pass over the atoms to work out how many residues we will need */
    nres = 1;
    atoms = allatoms.atoms;

    last_res_num = atoms->res_num;
    last_icode = atoms->icode;

    for (; atoms < alast; atoms++) {
        if ((atoms->res_num != last_res_num) || (atoms->icode != last_icode)) {
            nres++;
            last_icode = atoms->icode;
            last_res_num = atoms->res_num;
        }
    }

    coord = coord_template ( NULL, nres);
    seq_str = E_MALLOC ((nres + 1) * sizeof (seq_str[0]));
    memset (seq_str, 0, (nres + 1) * sizeof (seq_str[0]));
    atoms = allatoms.atoms;
    last_res_num = atoms->res_num;
    last_icode = atoms->icode;
    atom_ok = atom_not_ok;
    done = 0;
    for (; atoms < alast ; atoms++) {
        struct RPoint  tmp = rp_junk;
        char c1, c2, c3;
        enum at_type at_type = get_at_type (atoms->at_name);
        if (at_type != BORING) {
            tmp.x = atoms->x ; tmp.y = atoms->y; tmp.z = atoms->z; }
        c1 = (atoms->res_num != last_res_num);
        c2 = (atoms->icode != last_icode);
        c3 = (atoms == alast - 1);
        if ( c1 || c2 || c3) {
            if (residue_ok ( &tmpres, atom_ok )) {
                char s;
                char *res = (atoms - 1) ->res_name;
                add_to_coord (coord, tmpres, done, last_res_num, last_icode);
                s = three_a_to_1 (res);
                if (s == 0)
                    err_printf (this_sub, "Failed to convert amino acid %s\n", res);
                seq_str[done] = s;
                tmpres = junk_res;
                done++;
            }
            atom_ok = atom_not_ok;
            last_icode = atoms->icode;
            last_res_num = atoms->res_num;
        }

        switch (at_type) {  /* This looks strange, but there can be */
        case CA:            /* duplicates of atoms in the case of alt loc */
            if ( !atom_ok.ca)       /* residues. Only save atom if it is new */
                tmpres.rp_ca = tmp;   atom_ok.ca = 1; break;
        case CB:
            if ( !atom_ok.cb)
                tmpres.rp_cb = tmp;   atom_ok.cb = 1; break;
        case N:
            if ( !atom_ok.n)
                tmpres.rp_n  = tmp;   atom_ok.n  = 1; break;
        case C:
            if ( !atom_ok.c)
                tmpres.rp_c  = tmp;   atom_ok.c  = 1; break;
        case O:
            if ( !atom_ok.o)
                tmpres.rp_o  = tmp;   atom_ok.o  = 1; break;
        case BORING:
            continue;
        default: err_printf (this_sub, "Prog bug %s %d\n", __FILE__, __LINE__);
        }

    }
    /* Almost done, but maybe we did not get many residues. Trim
     * our memory back if so.
     */

    if (done == 0) {
        coord_destroy(coord); coord = NULL; goto error_exit; }
    coord->seq = seq_from_string (seq_str);
    if (done != coord->size)
        coord = coord_trim (coord, done);

    if ((i = strlen(seq_str)) != done) {
        err_printf (this_sub, bust, coord->size, done, i);
        coord_destroy(coord); coord = NULL; goto error_exit;
    }



 error_exit:
    free_if_not_null (seq_str);
    return (coord);
}

#ifdef want_strtrim
/* ----------------- strtrim ----------------------------------------
 *
 * trims a string, removes trailing whitespaces
 * as defined by isspace()
 *
 */
static char*
trim_string(char *str, int len) {
    int j;

    for (j=len; j >= 0; j--)
        if(isspace(str[j])==0) break;

    str = E_REALLOC(str, (len-(len-j)+1)*sizeof(char));
    str[len-(len-j)] = '\0';

    return str;
}
#endif /*  want_strtrim */

/* ---------------- get_cmpnd  --------------------------------------
 * Get the compound information of a pdb file
 * Written by Steve Hoffmann, but the first version caused us to
 * read each file twice.
 * Currently, only MOLECULE: lines are saved. Steve used to store
 * the CHAIN: lines, but these are not so informative.
 * We return as soon as we have a non-matching line.
 * Return NULL on failure.
 */

static char*
get_compnd (FILE *fp) {
    const char SEP = ' ';
    const char TERM = '\0';
    const char *TOKSTR = ";\n";
    const char *COMPND = "COMPND";
    const char *CPD_MOL = "MOLECULE";

    int found = 0;        /* Have we found compound information ? */
    size_t i, buflen;
    size_t len = 0;
    enum {MAXLINE = 100};
    char inbuf[MAXLINE],
        *compnd = NULL;

    /* The first time we see a compnd line, save it. */
    /* If we get a subsequent compnd line which contains molecule, */
    /* overwrite the old information */
    while (fgets (inbuf, MAXLINE, fp)) {
        if(strncmp(inbuf, COMPND, 6) == 0 ) {
            if ((found && strstr (inbuf, CPD_MOL)) || ( ! found) ) {
                char *pch;

                found = 1;
                pch = strtok(&inbuf[11], TOKSTR);
                buflen = strlen(pch);

                for (i = buflen; i > 0; i--)              /* trim whitespace */
                    if(isspace(pch[i-1]) == 0) break;

                compnd = E_REALLOC (compnd, (len+i+2) * sizeof(char));
                memcpy( &compnd[len], &inbuf[11], i);
                compnd[len+i] = SEP;
                compnd[len+i+1] = TERM;
                len += i+1;
            }
        } else {
            if (found)     /* We have some compound info, but now it stopped */
                return compnd;                    /* so return what we found */
        }
    }
    return NULL;
}

/* ---------------- pdb_read    -------------------------------------
 * This is the broad interface to reading a PDB file.
 * Obviously, we get the file name from fname.
 * acq_c is the pdb acquisition code. (1abc). If the pointer is NULL,
 * we try to get the code from fname.
 * Chain refers to the chain. It can be a letter or space. If it is
 * a space or '\0', we do not use it.
 * Philosophy ? A bit different to earlier, similar routines used in
 * sausage. Here, we read up all crap like anything that looks like
 * an atom identifier. Afterwards, we think about what we really
 * need and put that into a struct coord.
 * Return NULL on breakage.
 */
struct coord *
pdb_read ( const char *fname, const char *acq_c, char chain)
{
    FILE *fp;
    const char *s;
    struct coord *c = NULL;  /* This is what we will return */
    const enum yes_no take_hetatom = YES;
    struct allatoms allatoms;
    char *compnd;
    const char *this_sub = "pdb_read";
    const char *no_compound = "warning: no COMPND line found in %s\n";
    if ((chain == '_') || (chain == ' ') || (chain == '-'))
        chain = 0;

    if ((fp = mfopen (fname, "r", this_sub)) == NULL)
        return NULL;

    if ((compnd = get_compnd(fp)) == NULL) {
        err_printf (this_sub, no_compound, fname);
        if (fseek (fp, 0, SEEK_SET) == -1) {
            mperror (this_sub);
            err_printf (this_sub, "seek fail on %s\n", fname);
        }
    }

    allatoms = get_atoms (fp, chain, take_hetatom);
    fclose (fp);
    c = atoms2mdl (allatoms);
    if ( ! c) {       /* Something broke ! */
        err_printf (this_sub, "nothing found in %s\n", fname);
        goto exit;
    }
    memset (c->pdb_acq, 0, ACQ_SIZ);
    if (chain)
        c->chain = chain;
    else
        c->chain = '_';
    if (acq_c) {
        s = acq_c;
    } else {
        s = "    ";
    }
    strncpy (c->pdb_acq, s, ACQ_SIZ -1);
    c->compnd = compnd;
    if (compnd != NULL)
        c->compnd_len = strlen(compnd);
    else
        c->compnd_len = 0;
  exit:
    free (allatoms.atoms);
    return c;
}
