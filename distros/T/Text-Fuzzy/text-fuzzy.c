#include <string.h>
#include <errno.h>
#include <limits.h>
#include "config.h"
#include "text-fuzzy.h"
#include "edit-distance-char-trans.h"
#include "edit-distance-int-trans.h"
#include "edit-distance-char.h"
#include "edit-distance-int.h"

#ifndef ERROR_HANDLER
#define ERROR_HANDLER text_fuzzy_error_handler;
#endif /* undef ERROR_HANDLER */
#include "text-fuzzy.h"
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>

#ifndef ERROR_HANDLER_H
#define ERROR_HANDLER_H
typedef int (* error_handler_t) (const char * source_file,
                                 int source_line_number,
                                 const char * message, ...)
#ifdef __GNUC__
    __attribute__ ((format (printf, 3, 4)))
#endif /* __GNUC__ */
;
#endif /* ndef ERROR_HANDLER_H */

extern error_handler_t text_fuzzy_error_handler;


/* This is the default error handler for this namespace. */

static int
text_fuzzy_default_error_handler (const char * source_file,
                                        int source_line_number,
                                        const char * message, ...)
{
    va_list args;

    fprintf (stderr, "%s:%d: ", source_file, source_line_number);
    va_start (args, message);
    vfprintf (stderr, message, args);
    fprintf (stderr, "\n");
    return 0;
}

/* This global variable is the error handler for this namespace. */

error_handler_t text_fuzzy_error_handler =
    text_fuzzy_default_error_handler;


/* Print an error message for a failed condition "condition" at the
   appropriate line. */

#define LINE_ERROR(condition, status)                                   \
    if (text_fuzzy_error_handler) {                               \
        (* text_fuzzy_error_handler)                              \
            (__FILE__, __LINE__,                                        \
             "Failed test '%s', returning status '%s': %s",             \
             #condition, #status,                                       \
             text_fuzzy_statuses                                  \
             [text_fuzzy_status_ ## status]);                     \
    }                                                               

/* Fail a test, without message. */

#define FAIL(condition, status)                                         \
    if (condition) {                                                    \
        LINE_ERROR (condition, status);                                 \
        return text_fuzzy_status_ ## status;                      \
    }

/* Fail a test, with message. */

#ifdef __GNUC__

#define FAIL_MSG(condition, status, msg, args...)                       \
    if (condition) {                                                    \
        LINE_ERROR (condition, status);                                 \
        if (text_fuzzy_error_handler) {                           \
            (* text_fuzzy_error_handler)                          \
                (__FILE__, __LINE__,                                    \
                 msg, ## args);                                         \
        }                                                               \
        return text_fuzzy_status_ ## status;                      \
    }

#else /* __GNUC__ */

#define FAIL_MSG fail_msg

static void fail_msg (int condition, int status, char * msg, ...)
{
    if (condition) {
	fprintf (stderr, "%d:%s", status, msg);
    }
}

#endif /* __GNUC__ */

#define OK return text_fuzzy_status_ok;

/* Call a function and print an error message and return if the
   function returns an error value. */

#define CALL(x) {                                                       \
	text_fuzzy_status_t _status = text_fuzzy_ ## x;     \
	if (_status != text_fuzzy_status_ok) {                    \
            if (text_fuzzy_error_handler) {                       \
                (* text_fuzzy_error_handler)                      \
                    (__FILE__, __LINE__,                                \
                     "Call 'text_fuzzy_%s' "                      \
                     "failed with status '%d': %s",                     \
                     #x, _status,                                       \
                     text_fuzzy_statuses[_status]);       \
            }                                                           \
            return _status;                                             \
        }                                                               \
    }

/*
Local variables:
mode: c
End:
*/

const char * text_fuzzy_statuses[] = {
    "normal operation",
    "out of memory",
    "open error",
    "close error",
    "read error",
    "line too long",
    "There was an attempt to make a Unicode alphabet on a non-Unicode string.",
    "max min miscalculation",
    "A string for comparison was larger than the value of HUGE defined in the code.",
    "An attempt was made to use the maximum edit distance which was unset.",
    "miscount",
};

#define STATIC static
#define FUNC(name) text_fuzzy_status_t text_fuzzy_ ## name

#ifdef __GNUC__
#ifdef VERBOSE
#define MESSAGE(format, args...) {              \
        printf ("%s:%d: ", __FILE__, __LINE__); \
        printf (format, ## args);               \
}
#else /* VERBOSE */
#define MESSAGE(format, args...)
#endif /* VERBOSE */
#else /* __GNUC__ */
#define MESSAGE empty_message
static void empty_message (const char * format, ...) { return; }
#endif /* __GNUC__ */

/* Local variables:
mode: c
End:
*/

#line 1 "/usr/home/ben/projects/Text-Fuzzy/text-fuzzy.c.in"

/* For error-handling for the file opening functions. */

/* For INT_MAX, INT_MIN. */





/* All of the following are automatically generated from
   "edit-distance.h.tmpl" by "make-edit-distance-c.pl". */






/* The following starts off the header file. This is a tag which tells
   "C::Maker" to start writing "text-fuzzy.h". */

#ifdef HEADER

//#define VERBOSE 1

/* Alphabet over unicode characters. */

typedef struct ualphabet {

    /* The smallest character in our alphabet. */
    int min;

    /* The largest character in our alphabet. */
    int max;

    /* Number of chars allocated in the following array. */
    int size;

    /* Array containing Unicode alphabet, as a bitmap. */
    unsigned char * alphabet;

    /* The number of characters which were rejected using the Unicode
       alphabet. */
    int rejections;
}
ualphabet_t;

/* This structure contains one string of whatever type. */

typedef struct text_fuzzy_string {

    /* The text of the string. */
    char * text;

    /* The length of "text". */
    int length;

    /* The characters of "text" expanded out into unicode
       characters. */
    int * unicode;

    /* The length of "unicode". */
    int ulength;
}
text_fuzzy_string_t;

/* Match candidates. */

typedef struct candidate candidate_t;

struct candidate {
    int distance;
    int offset;
    candidate_t * next;
};

/* The following structure contains one string plus additional
   paraphenalia used in searching for the string, for example the
   alphabet of the string. */

typedef struct text_fuzzy {

    /* The string we are to match. */
    text_fuzzy_string_t text;

    /* The matching string. */

    text_fuzzy_string_t b;

    /* The maximum edit distance we allow for. */
    int max_distance;

    /* The maximum edit distance the user will allow. We are going to
       cheat and ignore the user's value. */
    int max_distance_holder;

    /* The number of mallocs we are guilty of. */
    int n_mallocs;

    /* ASCII alphabet */
    int alphabet[0x100];

    /* The number of characters which were rejected using the ASCII
       alphabet. */
    int alphabet_rejections;

    /* Unicode alphabet. */
    ualphabet_t ualphabet;

    /* The minimum distance we got in our most recent effort. */
    int distance;

    /* The number of units allocated for "b.unicode". This is not the
       string length. This is used when deciding whether there is
       sufficient space to store a test string. */
    int b_unicode_length;

    /* The number of items which have been rejected because the length
       difference is bigger than the maximum edit distance. */
    int length_rejections;

    /* A character which is not in use. */
    unsigned char invalid_char;

    /* Candidates for an array match. */

    candidate_t first;
    candidate_t * last;

    /* When scanning an array, put the index of the element of the
       array into "text_fuzzy->offset". The offset of the nearest
       elements are preserved in the "candidate_t" linked list which
       starts off with "text_fuzzy". 

       There is currently no sanity check, so if the user forgets to
       set "offset" each time around the loop, the code will not
       notice anything amiss and just send a list of zeros back to the
       user. */

    int offset;

    /* Does the user want to use an alphabet filter? Default is yes,
       so this must be set to a non-zero value to switch off use. */
    unsigned int user_no_alphabet : 1;

    /* Are we actually going to use it? (This may be false even if the
       user wants to use it, for silly cases, but is not true if the
       user does not want to use it.) */
    unsigned int use_alphabet : 1;
    unsigned int use_ualphabet : 1;

    /* Variable edit costs? (currently unused) */
    unsigned int variable_edit_costs : 1;

    /* Do we account for transpositions? */
    unsigned int transpositions_ok : 1;

    /* Did we find it? */
    unsigned int found : 1;

    /* Is this Unicode? */
    unsigned int unicode : 1;

    /* Do we want to skip exact matches? */
    unsigned int no_exact : 1;

    /* Are we scanning a list of entries? */
    unsigned int scanning : 1;

    /* Do we want an array of answers? */
    unsigned int wantarray : 1;
}
text_fuzzy_t;

/* The string is not unicode so its length in unicode characters is
   unknown. */

#define TEXT_FUZZY_INVALID_UNICODE_LENGTH -1

#endif /* HEADER */

/* The following calculations need to be done twice, first when
   creating the alphabet and second when looking up a new character in
   it. The macro saves us from exasperating bugs. */

#define BYTE_BIT				\
    byte = ((c - u->min) / 8) ;			\
    bit = 1 << (c % 8);

/* Generate the Unicode alphabet in "tf->ualphabet". */

FUNC (generate_ualphabet) (text_fuzzy_t * tf)
{
    int i;

    /* "u" is a pointer to the alphabet in "tf". This saves repeatedly
       typing "tf->ualphabet". */

    ualphabet_t * u;

    /* "t" is a pointer to the string in "tf". This saves repeatedly
       typing "tf->text". */

    text_fuzzy_string_t * t;

    /* Check this routine was not called by mistake. */

    FAIL (! tf->unicode, ualphabet_on_non_unicode);

    u = & tf->ualphabet;
    t = & tf->text;

    MESSAGE ("Alphabetizing %s\n", t->text);

    /* Set the maximum to the smallest possible value and the minimum
       to the largest possible value. */

    u->min = INT_MAX;
    u->max = INT_MIN;

    /* Get the minimum and maximum values. */

    for (i = 0; i < t->ulength; i++) {

	/* Character at position "i". */

	int c;

	c = t->unicode[i];

	if (c > u->max) {
	    u->max = c;
	}
	if (c < u->min) {
	    u->min = c;
	}
    }

    MESSAGE ("Range is %X - %X\n", u->min, u->max);

    /* The number of bytes we need to store the alphabet. */

    u->size = u->max /8 - u->min / 8 + 1;

    if (u->size >= UALPHABET_MAX_SIZE) {

	/* Give up trying to make this alphabet. */

	OK;
    }

    /* Create a zeroed alphabet. */

    u->alphabet = calloc (u->size, sizeof (char));
    FAIL_MSG (! u->alphabet, memory_failure, "Could not allocate %d memory slots",
	      u->size);

    tf->n_mallocs++;

    /* Get the minimum and maximum values. */

    for (i = 0; i < t->ulength; i++) {

	/* Character at position "i". */



	int c;

	/* Byte and bit offset of c in u->alphabet. */

	int byte;
	unsigned char bit;

	c = t->unicode[i];
	FAIL (c > u->max || c < u->min, max_min_miscalculation);

	BYTE_BIT;
	MESSAGE ("Accepting %X at byte %X, bit %X.\n", c, byte, bit);
	FAIL_MSG (byte < 0 || byte >= u->size, max_min_miscalculation,
		  "The value of byte is %d, not within 0 - %d", byte, u->size);

	u->alphabet[byte] |= bit;
    }

    /* We have succeeded. */

    tf->use_ualphabet = 1;

    MESSAGE ("Size %d, min %d, max %d\n", u->size, u->min, u->max);

    OK;
}

/* This returns a true value if the difference between the alphabet of
   "b" and the alphabet of "tf" is greater than the maximum distance
   which "tf" will accept. */

static int ualphabet_miss (text_fuzzy_t * tf, text_fuzzy_string_t * b)
{
    int i;

    /* "u" is a pointer to the alphabet in "tf". This saves repeatedly
       typing "tf->ualphabet". */

    ualphabet_t * u;

    /* The number of misses. */

    int misses;

    FAIL (tf->max_distance == NO_MAX_DISTANCE, max_distance_misuse);

    u = & tf->ualphabet;

    misses = 0;

    for (i = 0; i < tf->b.ulength; i++) {

	int c;

	c = tf->b.unicode[i];
	MESSAGE ("Looking for %X: ", c);

	/* Eliminate too large or too small. */

	if (c >= u->min && c <= u->max) {

	    /* Byte and bit offset of c in u->alphabet. */

	    int byte;
	    unsigned char bit;

	    BYTE_BIT;

	    MESSAGE (" byte %X, bit %X: ", byte, bit);

	    /* Exact check against the alphabet of "tf". */

	    if (! (u->alphabet[byte] & bit)) {
		MESSAGE ("not ");
		misses++;
	    }
	    MESSAGE ("there.\n");
	}
	else {
	    misses++;
	    MESSAGE (" out of bounds.\n");
	}

	/* If we have too many misses, stop searching. */

	if (misses > tf->max_distance) {
	    MESSAGE ("%s:%s: %d misses over %d: ",
		    tf->text.text, tf->b.text, misses, tf->max_distance);
	    return 1;
	}
    }
    return 0;
}

/* This is a value for the edit distance which indicates complete
   failure to match. */

#define NOT_FOUND -1

#define LENGTH_REJECT(x,y)						\
    MESSAGE ("Length of %d can never match %d within %d edits",		\
	     (x), (y), tf->max_distance);				\
    tf->length_rejections++


/* Compare tf and b. This goes through a series of filters which
   reject impossible matches, and then if none of the filters applies,
   it uses the dynamic programming algorithm to search. The source
   code for the dynamic programming algorithms is in
   "edit-distance.c.tmpl". */

FUNC (compare_single) (text_fuzzy_t * tf)
{

    /* The edit distance between "tf->search_term" and the
       truncated version of "tf->buf". */

    int d;

    d = NOT_FOUND;

    tf->found = 0;

    if (tf->unicode) {

	if (tf->max_distance != NO_MAX_DISTANCE) {

	    /* Filter on distance: If the distance in the length of
	       the strings is greater than the max distance, give up,
	       since the number of additions necessary to make the
	       strings identical is greater than the maximum distance
	       we are allowed. */

	    if (abs (tf->text.ulength - tf->b.ulength) > tf->max_distance) {

		LENGTH_REJECT (tf->b.ulength, tf->text.ulength);

		OK;
	    }
	    if (tf->use_ualphabet) {

		/*
		  Check that the length of "b" is more than the maximum
		  distance, otherwise the alphabet check will not reject
		  "b" regardless of the alphabet difference found, since
		  the largest possible value of "misses" in the alphabet
		  check is the total number of characters in "b".
		*/

		if (tf->b.ulength > tf->max_distance) {

		    /* Filter using alphabet: If the number of
		       characters in "b" which are not in "tf->text"
		       is greater than the maximum distance, give
		       up. */

		    if (ualphabet_miss (tf, & tf->b)) {

			MESSAGE ("Rejected.\n");

			tf->ualphabet.rejections++;

			OK;
		    }
		    else {
			MESSAGE ("Accepted.\n");
		    }
		}
		else {
		    MESSAGE ("%s: skipping alphabet check because len %d <= max %d.\n",
			     tf->b.text, tf->b.ulength, tf->max_distance);
		}
	    }
	}

	/* Calculate edit distances using the dynamic programming
	   algorithm for the integer Unicode strings. */

	if (tf->transpositions_ok) {
	    MESSAGE ("Transpositions OK.\n");
	    d = distance_int_trans (tf);
	}
	else {
	    MESSAGE ("No transpositions.\n");
	    d = distance_int (tf);
	}
    }
    else {

	/* This is not Unicode. */

        if (tf->max_distance != NO_MAX_DISTANCE) {

            /* If the distance in the length of the strings is greater
               than the max distance, give up. */

            if (abs (tf->text.length - tf->b.length) > tf->max_distance) {

		LENGTH_REJECT (tf->b.length, tf->text.length);
	    
                OK;
            }

	    /* See comment in the Unicode version, above. */

	    if (tf->b.length > tf->max_distance) {

		/* Alphabet filter: eliminate terms which cannot match. */

		if (tf->use_alphabet) {
		    int alphabet_misses;
		    int l;

		    alphabet_misses = 0;

		    for (l = 0; l < tf->b.length; l++) {

			int a = (unsigned char) tf->b.text[l];

			if (! tf->alphabet[a]) {
			    alphabet_misses++;
			    if (alphabet_misses > tf->max_distance) {

				/* It is not possible that the two words
				   are within the maximum edit distance of
				   each other. */

				tf->alphabet_rejections++;
				OK;
			    }
			}
		    }
		}
	    }
        }
        /* Calculate the edit distance using the dynamic programming
	   algorithm for "unsigned char". */

	if (tf->transpositions_ok) {
	    d = distance_char_trans (tf);
	}
	else {
	    d = distance_char (tf);
	}
    }

    /* If we have found something, and either it is less than or equal
       to the maximum distance allowed, or we are not checking for
       maximum distance, then record this distance and switch on the
       "found" flag, "tf->found". */

    if (d != NOT_FOUND && (tf->max_distance == NO_MAX_DISTANCE ||
			   d <= tf->max_distance)) {
	if (tf->no_exact) {

	    /* Skip exact matches. */

	    if (d == 0) {
		OK;
	    }
	}
	tf->found = 1;
	tf->distance = d;
	if (tf->scanning) {
	    tf->max_distance = tf->distance;
	}
	if (tf->wantarray) {
	    candidate_t * c;
	    c = malloc (sizeof (candidate_t));
	    FAIL (! c, memory_failure);
	    tf->n_mallocs+=1;
	    c->distance = d;
	    c->offset = tf->offset;
	    c->next = 0;
	    tf->last->next = c;
	    tf->last = c;
	}
    }
    OK;
}

FUNC (get_candidates) (text_fuzzy_t * text_fuzzy,
		       int * n_candidates_ptr,
		       int ** candidates_ptr)
{
    candidate_t * c;
    candidate_t * last;
    int n_candidates = 0;
    int * candidates;
    int i;

    last = text_fuzzy->first.next;
    while (last) {
	c = last;
	last = last->next;
	if (c->distance == text_fuzzy->distance) {
	    n_candidates++;
	}
    }

    if (n_candidates == 0) {
	* n_candidates_ptr = 0;
	* candidates_ptr = 0;
	OK;
    }

    candidates = malloc (sizeof (int) * n_candidates);
    FAIL (! candidates, memory_failure);
    text_fuzzy->n_mallocs+=1;

    last = text_fuzzy->first.next;
    i = 0;
    while (last) {
	c = last;

	/* Set "last" to the next one here so that we do not
	   access freed memory. */
	last = last->next;
	
	/* Some of the entries might be things which had a lower
	   distance initially, but then were beaten by later
	   entries, so here we check that the entry actually does
	   have the lowest distance, and only if so do we keep
	   it. */
	
	if (c->distance == text_fuzzy->distance) {
	    candidates[i] = c->offset;
	    i++;
	}
	free (c);
	text_fuzzy->n_mallocs--;
    }
    FAIL_MSG (i != n_candidates, miscount,
	      "Wrong number of entries %d should be %d", i, n_candidates);
    * candidates_ptr = candidates;
    * n_candidates_ptr = n_candidates;
    OK;
}

FUNC (free_candidates) (text_fuzzy_t * text_fuzzy, int * candidates)
{
    if (candidates) {
	free (candidates);
	text_fuzzy->n_mallocs--;
    }
    OK;
}


/* This is the threshold above which we do not bother computing the
   alphabet of the string. If it has more than this number of unique
   characters, the alphabet will not reduce the search time by
   much. */

static int max_unique_characters = 45;

/* Generate an alphabet from the search word, which is used to filter
   non-matching terms without using the dynamic programming
   algorithm. */

FUNC (generate_alphabet) (text_fuzzy_t * text_fuzzy)
{
    int unique_characters;
    int i;

    text_fuzzy->use_alphabet = 1;

    for (i = 0; i < 0x100; i++) {
        text_fuzzy->alphabet[i] = 0;
    }
    unique_characters = 0;
    for (i = 0; i < text_fuzzy->text.length; i++) {
        int c;
        c = (unsigned char) text_fuzzy->text.text[i];
        if (! text_fuzzy->alphabet[c]) {
            unique_characters++;
            text_fuzzy->alphabet[c] = 1;
        }
    }
    if (unique_characters > max_unique_characters) {
        text_fuzzy->use_alphabet = 0;
    }
    /* Find an unused slot. This is for the case where the string to
       match is not in Unicode, but the string which it is matched
       against is in Unicode. */
    for (i = 1; i < 0x100; i++) {
	if (text_fuzzy->alphabet[i] == 0) {
	    text_fuzzy->invalid_char = i;
	    break;
	}
    }
    OK;
}

FUNC (begin_scanning) (text_fuzzy_t * text_fuzzy)
{
    /* Even if the user does not want to set a maximum distance, set
       one anyway so that we can reject stuff without going into the
       dynamic programming algorithm. Keep the user's value in
       "text_fuzzy->max_distance_holder". */
    
    text_fuzzy->max_distance_holder = text_fuzzy->max_distance;

    if (text_fuzzy->max_distance == NO_MAX_DISTANCE) {
	/* Use INT_MAX / 2 here because INT_MAX + 1 = INT_MIN, causing
	   hard-to-find bugs. */
	text_fuzzy->max_distance = INT_MAX / 2;
    }
    text_fuzzy->scanning = 1;

    /* Set per-scan variables. */

    text_fuzzy->distance = -1;
    text_fuzzy->ualphabet.rejections = 0;
    text_fuzzy->alphabet_rejections = 0;
    text_fuzzy->length_rejections = 0;

    /* Set up the linked list. */

    if (text_fuzzy->wantarray) {
	text_fuzzy->last = & text_fuzzy->first;
    }

    OK;
}

/* Put the user's desired maximum distance back into the object for
   the next search. */

FUNC (end_scanning) (text_fuzzy_t * text_fuzzy)
{
    text_fuzzy->max_distance = text_fuzzy->max_distance_holder;
    text_fuzzy->scanning = 0;

    OK;
}

/*   __ _ _         __                  _   _                 
    / _(_) | ___   / _|_   _ _ __   ___| |_(_) ___  _ __  ___ 
   | |_| | |/ _ \ | |_| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
   |  _| | |  __/ |  _| |_| | | | | (__| |_| | (_) | | | \__ \
   |_| |_|_|\___| |_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/ */
                                                           


#define BUF_SIZE 0x1000

typedef struct fuzzy_file {
    const char * file_name;
    FILE * fh;
    char buf[BUF_SIZE];
    char * line;
    int length;
    text_fuzzy_string_t b;
    int remaining;
    int offset;
    int eof : 1;
}
fuzzy_file_t;

#define SIZE 0x1000

STATIC FUNC (more_bytes) (fuzzy_file_t * ff)
{
    int bytes;

    bytes = fread (ff->buf, sizeof (char), SIZE, ff->fh);
    if (bytes != SIZE) {
        if (feof (ff->fh)) {
            ff->eof = 1;
        }
        else {
            FAIL (bytes != SIZE, read_error);
        }
    }
    ff->remaining = bytes;
    ff->offset = 0;
    OK;
}

STATIC FUNC (get_line) (fuzzy_file_t * ff)
{
    int i;
    static char s[SIZE];

    i = 0;
    while (1) {
        char c;
        if (! ff->remaining) {
            CALL (more_bytes (ff));
        }
        c = ff->buf[ff->offset];
        ff->offset++;
        ff->remaining--;
        if (c == '\n' || (ff->remaining == 0 && ff->eof)) {
            s[i] = '\0';
            break;
        }
        else {
            s[i] = c;
        }
        i++;
        FAIL (i >= SIZE, line_too_long);
    }

    ff->b.text = s;
    ff->b.length = i;

    OK;
}

STATIC FUNC (open) (fuzzy_file_t * ff, const char * file_name)
{
    ff->file_name = file_name;
    ff->fh = fopen (ff->file_name, "r");
    FAIL_MSG (! ff->fh, open_error, "failed to open %s: %s", ff->file_name,
              strerror (errno));
    OK;
}

STATIC FUNC (close) (fuzzy_file_t * ff)
{
    FAIL (fclose (ff->fh), close_error);
    OK;
}

/* Scan the file specified by "file_name" for our string. The nearest
   string found is returned in "* nearest_ptr". */

FUNC (scan_file) (text_fuzzy_t * text_fuzzy, char * file_name,
                  char ** nearest_ptr, int * nearest_length_ptr)
{
    fuzzy_file_t ff = {0};
    char * nearest;
    int found;

    CALL (open (& ff, file_name));

    CALL (begin_scanning (text_fuzzy));

    found = 0;
    nearest = 0;
    while (1) {
        CALL (get_line (& ff));
	text_fuzzy->b = ff.b;
        CALL (compare_single (text_fuzzy));
        if (text_fuzzy->found) {
            found = 1;
	    if (! nearest) {
		nearest = malloc (ff.b.length + 1);
		FAIL (! nearest, memory_failure);
	    }
	    else {
		nearest = realloc (nearest, ff.b.length + 1);
		FAIL (! nearest, memory_failure);
	    }
	    strncpy (nearest, ff.b.text, ff.b.length);
	    nearest[ff.b.length] = '\0';
        }
        if (ff.eof && ff.remaining == 0) {
            break;
        }
    }

    CALL (close (& ff));

    CALL (end_scanning (text_fuzzy));

    if (found) {
        * nearest_ptr = nearest;
    }
    else {
        * nearest_ptr = 0;
    }
    OK;
}

FUNC (scan_file_free) (char * nearest)
{
    free (nearest);
    OK;
}

FUNC (alphabet_rejections) (text_fuzzy_t * text_fuzzy, int * r)
{
    * r = text_fuzzy->alphabet_rejections;
    OK;
}

/* Free non-Perl malloc memory using the C library "free". This is all
   about "free to wrong pool". See
   "http://www.perlmonks.org/?node_id=742205" */

FUNC (free_memory) (text_fuzzy_t * text_fuzzy)
{
    if (text_fuzzy->ualphabet.alphabet) {
	free (text_fuzzy->ualphabet.alphabet);
	text_fuzzy->n_mallocs--;
    }
    OK;
}

FUNC (set_max_distance) (text_fuzzy_t * text_fuzzy, int max_distance)
{
    text_fuzzy->max_distance = max_distance;
    OK;
}

FUNC (get_max_distance) (text_fuzzy_t * text_fuzzy, int * max_distance)
{
    * max_distance = text_fuzzy->max_distance;
    OK;
}

FUNC (set_transpositions) (text_fuzzy_t * text_fuzzy, int transpositions)
{
    text_fuzzy->transpositions_ok = transpositions != 0 ? 1 : 0;
    OK;
}

FUNC (get_transpositions) (text_fuzzy_t * text_fuzzy, int * transpositions)
{
    * transpositions = text_fuzzy->transpositions_ok;
    OK;
}

FUNC (last_distance) (text_fuzzy_t * text_fuzzy, int * last_distance)
{
    * last_distance = text_fuzzy->distance;
    OK;
}

FUNC (no_alphabet) (text_fuzzy_t * text_fuzzy, int yes_no)
{
    text_fuzzy->user_no_alphabet = yes_no != 0 ? 1 : 0;
    if (text_fuzzy->user_no_alphabet) {
	text_fuzzy->use_alphabet = 0;
	text_fuzzy->use_ualphabet = 0;
    }
    OK;
}

FUNC (ualphabet_rejections) (text_fuzzy_t * text_fuzzy, int * ualphabet_rejections)
{
    * ualphabet_rejections = text_fuzzy->ualphabet.rejections;
    OK;
}

FUNC (set_no_exact) (text_fuzzy_t * text_fuzzy, int yes_no)
{
    text_fuzzy->no_exact = yes_no != 0 ? 1 : 0;
    OK;
}

FUNC (get_length_rejections) (text_fuzzy_t * text_fuzzy, int * length_rejections)
{
    * length_rejections = text_fuzzy->length_rejections;
    OK;
}

FUNC (get_unicode_length) (text_fuzzy_t * text_fuzzy, int * unicode_length)
{
    if (text_fuzzy->text.unicode) {
	* unicode_length = text_fuzzy->text.ulength;
    }
    else {
	* unicode_length = TEXT_FUZZY_INVALID_UNICODE_LENGTH;
    }
    OK;
}

/* statuses:

status: open_error

status: close_error

status: read_error

status: line_too_long

status: ualphabet_on_non_unicode
%%description:
There was an attempt to make a Unicode alphabet on a non-Unicode string.
%%

status: max_min_miscalculation

status: string_too_long
%%description:
A string for comparison was larger than the value of HUGE defined in the code.
%%

status: max_distance_misuse
%%description:
An attempt was made to use the maximum edit distance which was unset.
%%

status: miscount

*/

