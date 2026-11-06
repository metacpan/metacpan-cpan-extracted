/* ------------------------------------------------------------------------
@NAME       : bt_internal.h
@DESCRIPTION: Private declarations shared between the btparse source files:
              memory helpers, a growable string buffer, ASCII character
              classes and the UTF-8/Unicode helpers in unicode.c.
-------------------------------------------------------------------------- */

#ifndef BT_INTERNAL_H
#define BT_INTERNAL_H

#include <stddef.h>
#include <stdarg.h>
#include "btparse.h"

/* Memory (never return NULL: they call the OOM handler instead) */
void * bt_xmalloc (size_t n);
void * bt_xcalloc (size_t n, size_t size);
void * bt_xrealloc (void *p, size_t n);
char * bt_xstrdup (const char *s);
char * bt_xstrndup (const char *s, size_t n);


/* Growable, always NUL-terminated string buffer */
typedef struct
{
   char * s;
   size_t len;
   size_t cap;
} bt_sbuf;

void   bt_sbuf_init (bt_sbuf *b);
void   bt_sbuf_free (bt_sbuf *b);
void   bt_sbuf_clear (bt_sbuf *b);
void   bt_sbuf_grow (bt_sbuf *b, size_t extra);
void   bt_sbuf_putn (bt_sbuf *b, const char *s, size_t n);
void   bt_sbuf_puts (bt_sbuf *b, const char *s);
void   bt_sbuf_vprintf (bt_sbuf *b, const char *fmt, va_list ap);
void   bt_sbuf_putc (bt_sbuf *b, char c);
char * bt_sbuf_steal (bt_sbuf *b);     /* malloc'd result; buffer reset */


/* Locale-independent ASCII character classes.  Never use <ctype.h> on
 * text: in a UTF-8 locale it misclassifies the bytes of multi-byte
 * characters on some platforms. */
#define BT_IS_ASCII(c)   (((unsigned char) (c)) < 0x80)
#define BT_IS_DIGIT(c)   ((c) >= '0' && (c) <= '9')
#define BT_IS_LOWER(c)   ((c) >= 'a' && (c) <= 'z')
#define BT_IS_UPPER(c)   ((c) >= 'A' && (c) <= 'Z')
#define BT_IS_ALPHA(c)   (BT_IS_LOWER (c) || BT_IS_UPPER (c))
#define BT_IS_ALNUM(c)   (BT_IS_ALPHA (c) || BT_IS_DIGIT (c))
#define BT_TOLOWER(c)    (BT_IS_UPPER (c) ? (c) + ('a' - 'A') : (c))
#define BT_TOUPPER(c)    (BT_IS_LOWER (c) ? (c) - ('a' - 'A') : (c))

int bt_ascii_strcasecmp (const char *a, const char *b);


/* ----------------------------------------------------------------------
 * UTF-8 and Unicode (unicode.c).  All functions are safe on invalid
 * UTF-8: an invalid byte is treated as a single, unclassified character.
 */

#define BT_REPLACEMENT_CHAR "\xEF\xBF\xBD"   /* U+FFFD */

/* Decode one character at s (which has n bytes available).  Returns its
 * length in bytes (>= 1 when n > 0), and sets *cp to the code point, or
 * to -1 if the bytes are not valid UTF-8. */
size_t bt_utf8_decode (const char *s, size_t n, long *cp);
size_t bt_utf8_encode (unsigned long cp, char *buf);   /* buf >= 4 bytes */

/* Byte length of the character starting at the NUL-terminated s. */
size_t bt_utf8_charlen (const char *s);

/* Byte length of the grapheme cluster starting at s (a character plus
 * any following combining marks / extenders). */
size_t bt_uni_grapheme_len (const char *s);

/* Number of characters (code points) in the first n bytes of s */
size_t bt_utf8_length (const char *s, size_t n);

/* Classify the character starting at the NUL-terminated s */
boolean bt_uni_islower (const char *s);     /* General_Category=Ll */
boolean bt_uni_isalpha (const char *s);     /* Alphabetic */
boolean bt_uni_isalnum (const char *s);     /* Alphabetic or Nd */
boolean bt_uni_ismark (const char *s);      /* grapheme extender */

/* Append the case-mapped version of the character at s to out;
 * returns the number of input bytes consumed.  Invalid bytes are
 * copied unchanged. */
typedef enum { BT_CASE_LOWER, BT_CASE_UPPER, BT_CASE_TITLE, BT_CASE_FOLD }
   bt_casemap;
size_t bt_uni_map_char (bt_sbuf *out, const char *s, bt_casemap how);

/* Case-map a whole string; returns a malloc'd string */
char * bt_uni_map_string (const char *s, bt_casemap how);


/* ----------------------------------------------------------------------
 * Other cross-file helpers
 */

void bt_vreport (bt_errors *errs, bt_errclass errclass,
                 const char *filename, int line,
                 const char *item_desc, int item,
                 const char *fmt, va_list ap);

AST * bt_new_ast (bt_nodetype nodetype, const char *text, size_t len,
                  const char *filename, int line, long offset);

#endif /* BT_INTERNAL_H */
