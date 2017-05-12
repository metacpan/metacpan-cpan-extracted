/*
 * 23 March 2001
 * $Id: amino_a.c,v 1.1 2007/09/28 16:57:04 mmundry Exp $
 */

#include <ctype.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>

#include "amino_a.h"

/* Rules:
 * This file knows about amino acids. It knows that they can be
 * collected into strings.
 * It does not want to know about sequences, substitution matrices
 * or anything else that may need to know about amino acids.
 * This file knows how many amino acid types there are.
 * Unlike most code that we write, we *do* hard wire MAX_AA
 * into amino_a.h. This lets us make some assumptions about some
 * of the two-dimensional matrices below.
 */


enum {AA_INVALID = SCHAR_MAX}; /* This may become public */



/* ---------------- std2thomas_table --------------------------
 * Return a pointer to the conversion array from printable
 * to THOMAS format names
 * This is quite cute (if you like this kind of thing).
 * We can hide the table within a static function like this
 */
static const char *
std2thomas_table (void)
{
    /*  Here is our roadmap,
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
        0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
        0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
        0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
        0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
        0x28, 0x29, '*',  0x2b, 0x2c, '-'.  '.',  0x2f,
        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
        0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f,
        0x40, 'A',  'B',  'C',  'D',  'E',  'F',  'G',
        'H',  'I',  'J',  'K',  'L',  'M',  'N',  'O',
        'P',  'Q',  'R',  'S',  'T',  'U',  'V',  'W',
        'X',  'Y',  'Z',  0x5b, 0x5c, 0x5d, 0x5e, 0x5f,
        0x60, 'a',  'b',  'c',  'd',  'e',  'f',  'g',
        'h',  'i',  'j',  'k',  'l',  'm',  'n',  'o',
        'p',  'q',  'r',  's',  't',  'u',  'v',  'w',
        'x',  'y',  'z'
    */
    enum {CRAP = AA_INVALID};
    static const char p2i[] = {
        CRAP, CRAP, CRAP, CRAP, CRAP, CRAP, CRAP, CRAP,
        CRAP, CRAP, CRAP, CRAP, CRAP, CRAP, CRAP, CRAP,
        CRAP, CRAP, CRAP, CRAP, CRAP, CRAP, CRAP, CRAP,
        CRAP, CRAP, CRAP, CRAP, CRAP, CRAP, CRAP, CRAP,
        CRAP, CRAP, CRAP, CRAP, CRAP, CRAP, CRAP, CRAP,
        CRAP, CRAP, CRAP, CRAP, CRAP, 23,   23,   CRAP,
        CRAP, CRAP, CRAP, CRAP, CRAP, CRAP, CRAP, CRAP,
        CRAP, CRAP, CRAP, CRAP, CRAP, CRAP, CRAP, CRAP,
        CRAP, 1,    21,   9,    15,   16,   5,    0,
        19,   4,    CRAP, 17,   3,    10,   13,   CRAP,
        6,    14,   18,   7,    8,    CRAP, 2,    11,
        20,   12,   22,   CRAP, CRAP, CRAP, CRAP, CRAP,
        CRAP, 1,    21,   9,    15,   16,   5,    0,
        19,   4,    CRAP, 17,   3,    10,   13,   CRAP,
        6,    14,   18,   7,    8,    CRAP, 2,    11,
        20,   12,   22
    };
    return p2i;
}

/* ---------------- thomas2std_table --------------------------
 */
static const char *
thomas2std_table ( void )
{
    static const char t2s [MAX_AA+2] = {
        'g',    /* 0        GLY   */
        'a',    /* 1        ALA   */
        'v',    /* 2        VAL   */
        'l',    /* 3        LEU   */
        'i',    /* 4        ILE   */
        'f',    /* 5        PHE   */
        'p',    /* 6        PRO   */
        's',    /* 7        SER   */
        't',    /* 8        THR   */
        'c',    /* 9        CYS   */
        'm',    /* 10       MET   */
        'w',    /* 11       TRP   */
        'y',    /* 12       TYR   */
        'n',    /* 13       ASN   */
        'q',    /* 14       GLN   */
        'd',    /* 15       ASP   */
        'e',    /* 16       GLU   */
        'k',    /* 17       LYS   */
        'r',    /* 18       ARG   */
        'h',    /* 19       HIS   */
        'x',    /* 20       unknown*/
        'b',    /* 21       av of N and D */
        'z',    /* 22       av of q and E */
        '.',    /* 23       gaps  */
        '*',    /* 24       lowest in matrix ? */
    };
    return t2s;
}

/* ---------------- std2thomas  -------------------------------
 */
void
std2thomas (char *s,  const size_t n)
{
    const char *slast = s + n;
    const char *table = std2thomas_table ();
    for ( ; s < slast; s++)
        *s = table [ (int) *s ];
}

/* ---------------- thomas2std  -------------------------------
 */
void
thomas2std (char *s, const size_t n)
{
    const char *slast = s + n;
    const char *table = thomas2std_table ();
    while ( s < slast) {
        *s = table [ (int) *s];          /* newest gcc complains about *s++ */
        s++;
    }
}

/* ---------------- thomas2std_char ---------------------------
 */
char
thomas2std_char (const char x)
{
    const char *table = thomas2std_table();
    return (table [ (int) x]);
}
/* ---------------- std2thomas_char ---------------------------
 */
char
std2thomas_char (const char x)
{
    const char *table = std2thomas_table();
    return (table [ (int) x]);
}

/* ---------------- seq_invalid -------------------------------
 * Return 1 if the sequence contains an amino acid we do not
 * know about.
 */
int
seq_invalid ( const char *s, const size_t n)
{
    const char *slast = s + n;
    const char *table = std2thomas_table ();
    while (s < slast)
        if (table [ (int) *s++] == AA_INVALID)
            return 1;
    return 0;
}

/* ---------------- aa_invalid  -------------------------------
 * This is a check to see if a single residue is invalid.
 * It is slow, compared to eating the string in a single loop
 * as above.
 */
int
aa_invalid (const char a)
{
    const char *table = std2thomas_table();
    if (table [(int)a] == AA_INVALID)
        return 1;
    return 0;
}

/* ---------------- one_a_to_3  -------------------------------
 * Given a character like 'a', return the corresponding amino
 * acid three letter string like "ALA".
 */
const char *
one_a_to_3 (const char a)
{
    static const char *p_name [26];
    p_name ['a'- 'a'] = "ALA";
    p_name ['g'- 'a'] = "GLY";
    p_name ['a'- 'a'] = "ALA";
    p_name ['v'- 'a'] = "VAL";
    p_name ['l'- 'a'] = "LEU";
    p_name ['i'- 'a'] = "ILE";
    p_name ['f'- 'a'] = "PHE";
    p_name ['p'- 'a'] = "PRO";
    p_name ['s'- 'a'] = "SER";
    p_name ['t'- 'a'] = "THR";
    p_name ['c'- 'a'] = "CYS";
    p_name ['m'- 'a'] = "MET";
    p_name ['w'- 'a'] = "TRP";
    p_name ['y'- 'a'] = "TYR";
    p_name ['n'- 'a'] = "ASN";
    p_name ['q'- 'a'] = "GLN";
    p_name ['d'- 'a'] = "ASP";
    p_name ['e'- 'a'] = "GLU";
    p_name ['k'- 'a'] = "LYS";
    p_name ['r'- 'a'] = "ARG";
    p_name ['h'- 'a'] = "HIS";
    return (p_name [tolower(a) - 'a']);
}

/* ---------------- three_a_to_1 ------------------------------
 * Given a string with a three letter amino acid name, return
 * the corresponding single character code, but using standard,
 * one letter codes, not Thomas numbering.
 * We could use a hash lookup, but for 20 names or so, it is
 * not worthwhile. Even if the list grows, 99.9 % of residues
 * are found within the first 20 lines.
 * To give us case insensitivity, we first copy the string and
 * turn it to upper case.
 */
char
three_a_to_1 (const char *name)
{
    char *p;
    
    char buf[4];
    
    struct namepair {
        const char *name;
        char c;
    };
    struct namepair *t;
    struct namepair table[] = {
        { "GLY",    'g' },
        { "ALA",    'a' },
        { "VAL",    'v' },
        { "LEU",    'l' },
        { "ILE",    'i' },
        { "PHE",    'f' },
        { "PRO",    'p' },
        { "SER",    's' },
        { "THR",    't' },
        { "CYS",    'c' },
        { "MET",    'm' },
        { "TRP",    'w' },
        { "TYR",    'y' },
        { "ASN",    'n' },
        { "GLN",    'q' },
        { "ASP",    'd' },
        { "GLU",    'e' },
        { "LYS",    'k' },
        { "ARG",    'r' },
        { "HIS",    'h' },
        { "ARQ",    'd' },  /* phospho aspartate as in 1lvh */
        { "ARO",    'r' },  /* gamma hydroxy arg */
        { "BHD",    'd' },  /* beta-hydroxy asp */
        { "CGU",    'e' },
        { "CEA",    'c' },  /* modified cys */
        { "CSE",    'c' },  /* seleno cysteine */
        { "CYH",    'c' },  
        { "CSH",    'c' },  /* There is a list at           */
        { "CSZ",    'c' },  /* s-selanyl cys*/
        { "CYA",    'c' },
        { "CYX",    'c' },  /* http://pdb.rutgers.edu/het_dictionary.txt */
        { "CME",    'c' },  /* s,s-(2-hydroxyethyl)thiocysteine */
        { "CSS",    'c' },
        { "YCM",    'c' },
        { "HLU",    'l' },  /* beta-hydroxy leu */
        { "LLP",    'k' },
        { "HTR",    'w' },  /* beta hydroxy trp */
        { "MLY",    'k' },  /* dimethyl-lysine */
        { "NIY",    'y' },  /* meta nitro tyr */
        { "OMT",    'm' },  /* di-oxy met */
        { "CXM",    'm' },  /* carboxymethionine -> methione */
        { "MSE",    'm' },  /* selenomethionine -> methionine */
        { "PCA",    'p' },
        { "PGA",    'p' },
        { "SEP",    's' },  /* serine phosphate */
        { "PTR",    'y' },  /* phospho tyr */
        { "TPQ",    'y' },  /* very modified tyr */
        { "TYQ",    'y' },  /* aminoquinol mod of tyr */
        { "TYT",    'y' },  
        { "ASX",    'a' },  /* these guys become alanine */
        { "GLX",    'a' },
        { "MES",    'a' },
        { "UNK",    'a' },
        { NULL,      0 }
    };
    strncpy (buf, name, 4);
    for (p = buf; *p; p++)
        *p = toupper (*p);
    for (t = table; t->name; t++)
        if (! strcmp (buf, t->name))
            return t->c;
    return (char) 0; /* unknown */
}
