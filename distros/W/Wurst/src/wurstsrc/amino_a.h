/*
 * 23 March 2001
 * You can only include me after <stdlib.h>
 * because I use size_t.
 * rcsid = $Id: amino_a.h,v 1.1 2007/09/28 16:57:05 mmundry Exp $
 */
#ifndef AMINO_A_H
#define AMINO_A_H

enum {MAX_AA = 23 };  /* Max number of amino acid types. */
enum {MIN_AA = 20 };  /* Mininum number of aa types we expect */
void  std2thomas (char *s, const size_t n);
void  thomas2std (char *s, const size_t n);
char  thomas2std_char (const char x);
char  std2thomas_char (const char x);
int   seq_invalid (const char *s, const size_t n);
int   aa_invalid (const char a);
const char *one_a_to_3 (const char a);
char  three_a_to_1 (const char *s);
#endif   /* AMINO_A_H */
