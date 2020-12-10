#include <stdint.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#define ERROR_HANDLER perl_error_handler
#define TEXT_FUZZY_USER_ERROR tfp_text_fuzzy_error

#include "config.h"
#define PERL_MEMORY_MANAGEMENT
#include "text-fuzzy-single.c"
#include "text-fuzzy-perl.c"

#undef TEXT_FUZZY_USER_ERROR
#define TEXT_FUZZY_USER_ERROR

typedef text_fuzzy_t * Text__Fuzzy;

MODULE=Text::Fuzzy PACKAGE=Text::Fuzzy

PROTOTYPES: ENABLE

BOOT:
	/* Set the error handler in "text-fuzzy.c" to be the error
	   handler defined in "text-fuzzy-perl.c". */

	text_fuzzy_error_handler = perl_error_handler;


Text::Fuzzy
new (class, search_term, ...)
	const char * class;
	SV * search_term;
PREINIT:
	int i;
	text_fuzzy_t * r;
CODE:
	r = 0;

	sv_to_text_fuzzy (search_term, & r);

        if (! r) {
        	croak ("error making %s.\n", class);
	}

	/* Loop over the parameters in "...". The first two terms are
	   "class" and "search_term", so we start from 2 here. */

	for (i = 2; i < items; i++) {
		SV * x;
		const char * p;
		STRLEN len;

		if (i >= items - 1) {
			warn ("Odd number of parameters %d of %d",
			      i, (int) items);
			break;
		}

		/* Read in parameters in the "form max => 22",
		"no_exact => 1", etc. */

		x = ST (i);
		p = (char *) SvPV (x, len);
		if (strncmp (p, "max", strlen ("max")) == 0) {
			int max;
			max = SvIV (ST (i + 1));
			if (max < 0) {
				TEXT_FUZZY (set_max_distance (r, NO_MAX_DISTANCE));
			}
			else {
				TEXT_FUZZY (set_max_distance (r, max));
			}
		}
		else if (strncmp (p, "no_exact", strlen ("no_exact")) == 0) {
			r->no_exact = SvTRUE (ST (i + 1)) ? 1 : 0;
		}
		else if (strncmp (p, "trans", strlen ("trans")) == 0) {
			r->transpositions_ok = SvTRUE (ST (i + 1)) ? 1 : 0;
		}
		else {
			warn ("Unknown parameter %s", p);
		}
		i++;
	}
	RETVAL = r;
OUTPUT:
        RETVAL

SV *
get_max_distance (tf)
	Text::Fuzzy tf;
PREINIT:
	int maximum;
CODE:
	TEXT_FUZZY (get_max_distance (tf, & maximum));	
        if (maximum >= 0) {
		RETVAL = newSViv (maximum);
	}
	else {
		RETVAL = &PL_sv_undef;
	}
OUTPUT:
	RETVAL

void
set_max_distance (tf, max_distance = &PL_sv_undef)
	Text::Fuzzy tf;
	SV * max_distance;
PREINIT:
	int maximum;
CODE:
	/* Set the maximum distance to "none". */

        maximum = NO_MAX_DISTANCE;
        if (SvOK (max_distance)) {
		maximum = (int) SvIV (max_distance);
		if (maximum < 0) {
			maximum = NO_MAX_DISTANCE;
		}
	}
	TEXT_FUZZY (set_max_distance (tf, maximum));

void
transpositions_ok (tf, trans)
	Text::Fuzzy tf;
	SV * trans;
CODE:
	if (SvTRUE (trans)) {
		TEXT_FUZZY (set_transpositions (tf, 1));
	}
	else {
		TEXT_FUZZY (set_transpositions (tf, 0));
	}

int
get_trans (tf)
	Text::Fuzzy tf;
CODE:
	TEXT_FUZZY (get_transpositions (tf, & RETVAL));
OUTPUT:
	RETVAL

int
distance (tf, word)
	Text::Fuzzy tf;
        SV * word;
CODE:
	RETVAL = text_fuzzy_sv_distance (tf, word);
OUTPUT:
	RETVAL


void
nearest (tf, words)
	Text::Fuzzy tf;
        AV * words;
PREINIT:
	int i;
	int n;
	AV * wantarray;
PPCODE:

	wantarray = 0;

	if (GIMME_V == G_ARRAY) {

	   	/* The user wants an array containing all of the
	   	nearest values. */

		wantarray = newAV ();
		/* Free the array */
		sv_2mortal ((SV *) wantarray);
		n = text_fuzzy_av_distance (tf, words, wantarray);
	}
	else {
		/* Even in void context, we still do the search, in
		   case the user just wants to know the minimum
		   distance and ignores the actual values. */

		n = text_fuzzy_av_distance (tf, words, 0);
	}

	if (wantarray) {
		SV * e;
		int wasize = av_len (wantarray) + 1;
		EXTEND (SP, wasize);
		for (i = 0; i < wasize; i++) {
			e = * av_fetch (wantarray, i, 0);
			SvREFCNT_inc_simple_void_NN (e);
			PUSHs (sv_2mortal (e));
		}
        }
        else {
		if (n >= 0) {
            		PUSHs (sv_2mortal (newSViv (n)));
		}
		else {
            		PUSHs (& PL_sv_undef);
		}
        }


int
last_distance (tf)
	Text::Fuzzy tf;
CODE:
	TEXT_FUZZY (last_distance (tf, & RETVAL));
OUTPUT:
	RETVAL


SV *
unicode_length (tf)
	Text::Fuzzy tf;
PREINIT:
	int unicode_length;
CODE:
	TEXT_FUZZY (get_unicode_length (tf, & unicode_length));
        if (unicode_length == TEXT_FUZZY_INVALID_UNICODE_LENGTH) {
		RETVAL = &PL_sv_undef;
	}
	else {
		RETVAL = newSViv (tf->text.ulength);
	}
OUTPUT:
	RETVAL


void
no_alphabet (tf, yes_no)
	Text::Fuzzy tf;
        SV * yes_no;
CODE:
	TEXT_FUZZY (no_alphabet (tf, SvTRUE (yes_no)));


int
ualphabet_rejections (tf)
	Text::Fuzzy tf;
CODE:
	TEXT_FUZZY (ualphabet_rejections (tf, & RETVAL));
OUTPUT:
        RETVAL


int
length_rejections (tf)
	Text::Fuzzy tf;
CODE:
	TEXT_FUZZY (get_length_rejections (tf, & RETVAL));
OUTPUT:
        RETVAL


SV *
scan_file (tf, file_name)
	Text::Fuzzy tf;
        char * file_name;
PREINIT:
	char * nearest;
	int nearest_length;
CODE:
        TEXT_FUZZY (scan_file (tf, file_name, & nearest, & nearest_length));
	RETVAL = newSVpv (nearest, (STRLEN) nearest_length);
        TEXT_FUZZY (scan_file_free (nearest));
OUTPUT:
        RETVAL


void
no_exact (tf, yes_no)
	Text::Fuzzy tf;
	SV * yes_no;
CODE:
	TEXT_FUZZY (set_no_exact (tf, SvTRUE (yes_no)));

int
alphabet_rejections (tf)
	Text::Fuzzy tf;
CODE:
	TEXT_FUZZY (alphabet_rejections (tf, & RETVAL));
OUTPUT:
	RETVAL

void
DESTROY (tf)
	Text::Fuzzy tf;
CODE:
	text_fuzzy_free (tf);

