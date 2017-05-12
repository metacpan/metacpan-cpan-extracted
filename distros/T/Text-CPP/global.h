#ifndef __TCPP_GLOBAL_H__
#define __TCPP_GLOBAL_H__

/* These control system.h */

#define HAVE_STRING_H 1
#define HAVE_STDLIB_H 1
#define HAVE_UNISTD_H 1
#define HAVE_STRSIGNAL 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_WAIT_H 1
#define HAVE_FCNTL_H 1
#define TIME_WITH_SYS_TIME 1

/* And I've included these anyway for now. */

/* I really must use "perl -MConfig" to handle these. */

#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <limits.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "ansidecl.h"

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#define progname "Text::CPP"

	/* Since the gcc code is written in terms of x() functions
	 * normally provided by libiberty, it is simple to rewrite
	 * in terms of Perl. Unfortunately I looked at the definition
	 * of Newz and choked. */
static inline void *xmalloc(int s)
	{ void *ret; New(0, ret, s, char); return ret; }
static inline void *xcalloc(int n, int s)
	{ void *ret; Newz(0, ret, n * s, char); return ret; }
static inline void *xrealloc(void *p, int s)	/* Needed? */
	{ Renew(p, s, char); return p; }
static inline char *xstrdup(const char *p)
	{ char *ret; int len = strlen(p) + 1; ret = xmalloc(len);
	  Copy(p, ret, len, char); return ret; }

// #include "defaults.h"

/* This from gcc's defaults.h */
#ifndef GET_ENVIRONMENT
#define GET_ENVIRONMENT(VALUE, NAME) \
		do { (VALUE) = getenv (NAME); } while (0)
#endif

/* This from gcc's defaults.h */
/* Define default standard character escape sequences.  */
#ifndef TARGET_BELL
#  define TARGET_BELL 007
#  define TARGET_BS 010
#  define TARGET_TAB 011
#  define TARGET_NEWLINE 012
#  define TARGET_VT 013
#  define TARGET_FF 014
#  define TARGET_CR 015
#  define TARGET_ESC 033
#endif

#include "safe-ctype.h"
#include "system.h"

/* These are defined in the .xs file */
struct cpp_reader;
void cb_error(struct cpp_reader *, SV *, const char *, va_list);
void cb_diagnostic(struct cpp_reader *reader, int code, const char*dir);
extern SV * _sv_cpp_begin_message PARAMS ((struct cpp_reader *, int,
                                       unsigned int, unsigned int));

/* These are defined at the bottom of cppinit.c */
void cpp_append_include_chain(struct cpp_reader *, const char *, int);
void cpp_append_include_file(struct cpp_reader *, const char *);
void cpp_append_imacros_file(struct cpp_reader *, const char *);
typedef void (* cl_directive_handler) PARAMS ((struct  cpp_reader *, const char *));
void cpp_append_pending_directive(struct cpp_reader *, const char *, cl_directive_handler);

#endif
