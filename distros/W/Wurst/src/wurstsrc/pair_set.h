/*
 * 12 Sep 2001
 * This defines the structures for passing alignments, or pair_sets
 * around.
 * It defines the internals, so it is only to be included by
 * the very few routines which manipulate pair_sets.
 * The functions are declared in pair_set_i.h
 * rcsid = "$Id: pair_set.h,v 1.1 2007/09/28 16:57:05 mmundry Exp $"
 */

#ifndef PAIR_SET_H
#define PAIR_SET_H

/* ---------------- Structures  -------------------------------
 */

struct pair_set {
    int **indices;  /* alignments are now stored here. */
    size_t n;         /* length of the alignment */
    size_t m;         /* number of sequences in alignment */
    float score;      /* Full score, including gaps */
    float smpl_score; /* Score, but without gaps */
};

/* ---------------- Enumerations ------------------------------
 */
enum long_or_short {
    EXT_LONG = 0,
    EXT_SHORT = 1
};
enum { GAP_INDEX = -1 };

#endif /* PAIR_SET_H */
