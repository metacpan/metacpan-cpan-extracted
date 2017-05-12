/*
 * 21 March 2001
 * rcsid = $Id: seq.h,v 1.1 2007/09/28 16:57:03 mmundry Exp $
 */
#ifndef SEQ_H
#define SEQ_H

/*
 * A sequence may be stored in a printable format. This is lower
 * case and looks like 'acdad'
 * It may also be stored in a compact internal format.
 * Each residue type is numbered from 0 to about 21 or 22.
 * This lets us use amino acid types as lookups into an array.
 * It lets us avoid lots of small calculations like 'd' - 'A'
 */

enum seq_fmt {
    PRINTABLE,  /* Sensible, human readable, lower case version */
    THOMAS      /* Compact form with our names used. */
};


struct seq {
    char *seq;      /* Real sequence, with newlines removed. */
    char *comment;  /* FASTA comment, with newlines and leading ">" removed */
    size_t length;  /* Length of sequence, not including null terminator */
    enum seq_fmt format;   /* How is this thing stored ? */
};

struct seq_array {
    struct seq *seqs;
    unsigned n;
};

#endif  /* SEQ_H */
