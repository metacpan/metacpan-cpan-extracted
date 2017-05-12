#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "metaphone.h"

MODULE = Text::Metaphone        PACKAGE = Text::Metaphone

PROTOTYPES: ENABLE

SV *
Metaphone(word, ...)
        char* word
        PROTOTYPE: $;$
        PREINIT:
            size_t max_length = 0;
        INIT:
            char *phoned_word;
        CODE:
            if( items > 1 ) {
                max_length = SvIV(ST(1));
            }

            phoned_word = metaphone(word, max_length);
            RETVAL = newSVpv(phoned_word, 0);
/* Use the real free() to free memory allocated by the real calloc() */
#undef free
            free(phoned_word);
        OUTPUT:
            RETVAL
