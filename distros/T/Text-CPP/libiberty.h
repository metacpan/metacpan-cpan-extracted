/* Function declarations hacked out of gcc's libiberty.h by Shevek */

#ifndef LIBIBERTY_H
#define LIBIBERTY_H

#ifdef __cplusplus
extern "C" {
#endif

#include "ansidecl.h"

/* Get a definition for size_t.  */
#include <stddef.h>
/* Get a definition for va_list.  */
#include <stdarg.h>

/* A well-defined basename () that is always compiled in.  */

extern const char *lbasename PARAMS ((const char *));

extern char *concat PARAMS ((const char *, ...)) ATTRIBUTE_MALLOC;

/* Copy a string into a memory buffer without fail.  */

extern char *xstrdup PARAMS ((const char *)) ATTRIBUTE_MALLOC;

/* Copy an existing memory buffer to a new memory buffer without fail.  */

extern PTR xmemdup PARAMS ((const PTR, size_t, size_t)) ATTRIBUTE_MALLOC;

/* hex character manipulation routines */

#define _hex_array_size 256
#define _hex_bad	99
extern const char _hex_value[_hex_array_size];
extern void hex_init PARAMS ((void));
#define hex_p(c)	(hex_value (c) != _hex_bad)
/* If you change this, note well: Some code relies on side effects in
   the argument being performed exactly once.  */
#define hex_value(c)	(_hex_value[(unsigned char) (c)])

#define ARRAY_SIZE(a) (sizeof (a) / sizeof ((a)[0]))

#ifdef __cplusplus
}
#endif

#endif /* ! defined (LIBIBERTY_H) */
