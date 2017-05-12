#ifndef __METAPHONE_H__
#define __METAPHONE_H__

#include <string.h>


/*  I add modifications to the traditional metaphone algorithm that you
    might find in books.  Define this if you want metaphone to behave
    traditionally */
#undef USE_TRADITIONAL_METAPHONE

/* Special encodings */
#define  SH 	'X'
#define  TH	'0'

char *metaphone (char *word, size_t max_phonemes );

#endif
