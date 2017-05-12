/* Extended regular expression matching and search library.
   Copyright (C) 2002-2014 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Isamu Hasegawa <isamu@yamato.ibm.com>.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, see
   <http://www.gnu.org/licenses/>.  */

#ifndef _REGEX_INTERNAL_H
#define _REGEX_INTERNAL_H 1

#ifdef HAVE_ASSERT_H
#  include <assert.h>
#endif
#ifdef HAVE_CTYPE_H
#  include <ctype.h>
#endif
#ifdef HAVE_STDIO_H
#  include <stdio.h>
#endif
#ifdef HAVE_STDLIB_H
#  include <stdlib.h>
#endif
#ifdef HAVE_STRING_H
#  include <string.h>
#endif

/* We do not want to include locale stuff: everything */
/* will be done using perl API */
#if 0
#  include <langinfo.h>
#  include <locale.h>
#endif
#ifdef HAVE_WCHAR_H
#  include <wchar.h>
#endif
#ifdef HAVE_WCTYPE_H
#  include <wctype.h>
#endif
#ifndef HAS_BOOL
/* Because perl usually already defined it */
#  ifdef HAVE_STDBOOL_H
#    include <stdbool.h>
#  else
#    ifndef __cplusplus
#      ifndef bool
#        ifdef HAVE__BOOL
typedef _Bool bool;
#        else
typedef unsigned char bool;
#        endif
#      endif
#      ifndef true
#        define true 1
#      endif
#      ifndef false
#        define false 0
#      endif
#      define __bool_true_false_are_defined 1
#    endif
#  endif
#else
/* This is perl's bool style. Though it usually does not define true or false */
#  ifndef __bool_true_false_are_defined
#    ifndef true
#      define true 1
#    endif
#    ifndef false
#      define false 0
#    endif
#    define __bool_true_false_are_defined 1
#  endif
#endif /* HAS_BOOL */
#ifdef HAVE_STDINT_H
#include <stdint.h>
#endif
#ifdef HAVE_SYS_INT_TYPES_H
/* for some old solaris */
#include <sys/int_types.h>
#endif

#ifdef _LIBC
# include <bits/libc-lock.h>
# define lock_define(name) __libc_lock_define (, name)
# define lock_init(lock) (__libc_lock_init (lock), 0)
# define lock_fini(lock) 0
# define lock_lock(lock) __libc_lock_lock (lock)
# define lock_unlock(lock) __libc_lock_unlock (lock)
#elif defined GNULIB_LOCK
# include "glthread/lock.h"
  /* Use gl_lock_define if empty macro arguments are known to work.
     Otherwise, fall back on less-portable substitutes.  */
# if ((defined __GNUC__ && !defined __STRICT_ANSI__) \
      || (defined __STDC_VERSION__ && 199901L <= __STDC_VERSION__))
#  define lock_define(name) gl_lock_define (, name)
# elif USE_POSIX_THREADS
#  define lock_define(name) pthread_mutex_t name;
# elif USE_PTH_THREADS
#  define lock_define(name) pth_mutex_t name;
# elif USE_SOLARIS_THREADS
#  define lock_define(name) mutex_t name;
# elif USE_WINDOWS_THREADS
#  define lock_define(name) gl_lock_t name;
# else
#  define lock_define(name)
# endif
# define lock_init(lock) glthread_lock_init (&(lock))
# define lock_fini(lock) glthread_lock_destroy (&(lock))
# define lock_lock(lock) glthread_lock_lock (&(lock))
# define lock_unlock(lock) glthread_lock_unlock (&(lock))
#elif defined GNULIB_PTHREAD
# include <pthread.h>
# define lock_define(name) pthread_mutex_t name;
# define lock_init(lock) pthread_mutex_init (&(lock), 0)
# define lock_fini(lock) pthread_mutex_destroy (&(lock))
# define lock_lock(lock) pthread_mutex_lock (&(lock))
# define lock_unlock(lock) pthread_mutex_unlock (&(lock))
#else
# define lock_define(name) SV *name;
/* GNU regex expect lock_init(lock) to return 0 if success */
/* Break on win32 ? */
/*
# define lock_init(lock) (SvSHARE(lock), 0)
# define lock_fini(lock)
# define lock_lock(lock) SvLOCK(lock)
# define lock_unlock(lock) SvUNLOCK(lock)
*/
# define lock_init(lock) 0
# define lock_fini(lock)
# define lock_lock(lock)
# define lock_unlock(lock)
#endif

/* In case that the system doesn't have isblank().  */
#if !defined _LIBC && ! (defined isblank || (HAVE_ISBLANK && HAVE_DECL_ISBLANK))
# define isblank(ch) ((ch) == ' ' || (ch) == '\t')
#endif

#ifdef _LIBC
# ifndef _RE_DEFINE_LOCALE_FUNCTIONS
#  define _RE_DEFINE_LOCALE_FUNCTIONS 1
#   include <locale/localeinfo.h>
#   include <locale/elem-hash.h>
#   include <locale/coll-lookup.h>
# endif
#endif

/* This is for other GNU distributions with internationalized messages.  */
#if (HAVE_LIBINTL_H && ENABLE_NLS) || defined _LIBC
# include <libintl.h>
# ifdef _LIBC
#  undef gettext
#  define gettext(msgid) \
  __dcgettext (_libc_intl_domainname, msgid, LC_MESSAGES)
# endif
#else
# define gettext(msgid) (msgid)
#endif

#ifndef gettext_noop
/* This define is so xgettext can find the internationalizable
   strings.  */
# define gettext_noop(String) String
#endif

#if __GNUC__ >= 3
# define BE(expr, val) __builtin_expect (expr, val)
#else
# define BE(expr, val) (expr)
#endif

/* Number of ASCII characters.  */
#define ASCII_CHARS 0x80

/* Number of single byte characters.  */
#define SBC_MAX (UCHAR_MAX + 1)

#define COLL_ELEM_LEN_MAX 8

/* The character which represents newline.  */
#define NEWLINE_CHAR '\n'
#define WIDE_NEWLINE_CHAR L'\n'

/* Rename to standard API for using out of glibc.  */
#undef rpl__wint_t
#undef rpl__wchar_t
#undef rpl__mbsinit
#undef rpl__wctype_t
#undef rpl__wctype
#undef rpl__isascii
#undef rpl__isalnum
#undef rpl__iswalnum
#undef rpl__iscntrl
#undef rpl__islower
#undef rpl__isspace
#undef rpl__isalpha
#undef rpl__isdigit
#undef rpl__isprint
#undef rpl__isupper
#undef rpl__isblank
#undef rpl__isgraph
#undef rpl__ispunct
#undef rpl__isxdigit
#undef rpl__iswlower
#undef rpl__iswctype
#undef rpl__btowc
#undef rpl__mbrtowc
#undef rpl__mbtowc
#undef rpl__wcrtomb
#undef rpl__towlower
#undef rpl__mbstate_t
#undef rpl__MB_CUR_MAX
#undef rpl__MB_LEN_MAX
#undef rpl__WEOF
#ifndef _LIBC
# ifndef _PERL_I18N
#   define rpl__wint_t wint_t
#   define rpl__wchar_t wchar_t
#   define rpl__mbsinit mbsinit
#   define rpl__wctype_t wctype_t
#   define rpl__wctype(c) wctype(c)
#   define rpl__isascii(c) isascii(c)
#   define rpl__isalnum(c) isalnum(c)
#   define rpl__iswalnum(c) iswalnum(c)
#   define rpl__iscntrl(c) iscntrl(c)
#   define rpl__islower(c) islower(c)
#   define rpl__isspace(c) isspace(c)
#   define rpl__isalpha(c) isalpha(c)
#   define rpl__isdigit(c) isdigit(c)
#   define rpl__isprint(c) isprint(c)
#   define rpl__isupper(c) isupper(c)
#   define rpl__isblank(c) isblank(c)
#   define rpl__isgraph(c) isgraph(c)
#   define rpl__ispunct(c) ispunct(c)
#   define rpl__isxdigit(c) isxdigit(c)
#   define rpl__iswlower(c) iswlower(c)
#   define rpl__iswctype(c) iswctype(c)
#   define rpl__btowc(c) btowc(c)
#   define rpl__mbrtowc(pwc, s, n, ps) mbrtowc(pwc, s, n, ps)
#   define rpl__mbtowc(pwc, s, n) mbrtowc(pwc, s, n)
#   define rpl__wcrtomb(s, wc, ps) wcrtomb(s, wc, ps)
#   define rpl__towlower(wc) towlower(wc)
#   define rpl__towupper(wc) towupper(wc)
#   define rpl__tolower(wc) tolower(wc)
#   define rpl__toupper(wc) toupper(wc)
#   define rpl__mbstate_t mbstate_t 
#   define rpl__MB_CUR_MAX MB_CUR_MAX
#   define rpl__MB_LEN_MAX MB_LEN_MAX
#   define rpl__WEOF WEOF
# else
#   define rpl__wint_t UV
#   define rpl__wchar_t UV
#   define rpl__mbsinit rpl_Perl_mbsinit
#   define rpl__wctype_t rpl_Perl_wctype_t
#   define rpl__wctype(property) rpl_Perl_wctype(aTHX_ property)
#   define rpl__isascii(c) rpl_Perl_isascii(aTHX_ c)
#   define rpl__isalnum(c) rpl_Perl_isalnum(aTHX_ c)
#   define rpl__iswalnum(c) rpl_Perl_iswalnum(aTHX_ c)
#   define rpl__iscntrl(c) rpl_Perl_iscntrl(aTHX_ c)
#   define rpl__islower(c) rpl_Perl_islower(aTHX_ c)
#   define rpl__isspace(c) rpl_Perl_isspace(aTHX_ c)
#   define rpl__isalpha(c) rpl_Perl_isalpha(aTHX_ c)
#   define rpl__isdigit(c) rpl_Perl_isdigit(aTHX_ c)
#   define rpl__isprint(c) rpl_Perl_isprint(aTHX_ c)
#   define rpl__isupper(c) rpl_Perl_isupper(aTHX_ c)
#   define rpl__isblank(c) rpl_Perl_isblank(aTHX_ c)
#   define rpl__isgraph(c) rpl_Perl_isgraph(aTHX_ c)
#   define rpl__ispunct(c) rpl_Perl_ispunct(aTHX_ c)
#   define rpl__isxdigit(c) rpl_Perl_isxdigit(aTHX_ c)
#   define rpl__iswlower(c) rpl_Perl_iswlower(aTHX_ c)
#   define rpl__iswctype(c, t) rpl_Perl_iswctype(aTHX_ c, t)
#   define rpl__btowc(c) rpl_Perl_btowc(aTHX_ c)
#   define rpl__mbrtowc(pwc, s, n, ps) rpl_Perl_mbrtowc(aTHX_ pwc, s, n, ps)
#   define rpl__mbtowc(pwc, s, n) rpl_Perl_mbrtowc(aTHX_ pwc, s, n)
#   define rpl__wcrtomb(s, wc, ps) rpl_Perl_wcrtomb(aTHX_ s, wc, ps)
#   define rpl__towlower(wc) rpl_Perl_towlower(aTHX_ wc)
#   define rpl__towupper(wc) rpl_Perl_towupper(aTHX_ wc)
#   define rpl__tolower(wc) rpl_Perl_tolower(aTHX_ wc)
#   define rpl__toupper(wc) rpl_Perl_toupper(aTHX_ wc)
#   define rpl__mbstate_t rpl_Perl_mbstate_t 
#   define rpl__MB_CUR_MAX rpl_Perl_MB_CUR_MAX(aTHX)
#   define rpl__MB_LEN_MAX UTF8_MAXBYTES
#   define rpl__WEOF ((UV)-1)
typedef enum {
  PERL_WCTYPE_ALNUM = 1,
  PERL_WCTYPE_ALPHA,
  PERL_WCTYPE_CNTRL,
  PERL_WCTYPE_DIGIT,
  PERL_WCTYPE_GRAPH,
  PERL_WCTYPE_LOWER,
  PERL_WCTYPE_PRINT,
  PERL_WCTYPE_PUNCT,
  PERL_WCTYPE_SPACE,
  PERL_WCTYPE_UPPER,
  PERL_WCTYPE_XDIGIT
} rpl_Perl_wctype_t;
typedef struct {
  union
  {
    unsigned int __wch;
    char __wchb[4];
  } u;
} rpl_Perl_mbstate_t;
# endif
# define __regfree regfree
# define attribute_hidden
#endif /* not _LIBC */

#if (defined MB_CUR_MAX && HAVE_WCTYPE_H && HAVE_ISWCTYPE) || _LIBC || defined(_PERL_I18N)
# define RE_ENABLE_I18N
#endif

#if __GNUC__ < 3 + (__GNUC_MINOR__ < 1)
# define __attribute__(arg)
#endif

typedef __re_idx_t Idx;
#ifdef _REGEX_LARGE_OFFSETS
# define IDX_MAX (SIZE_MAX - 2)
#else
# define IDX_MAX INT_MAX
#endif

/* Special return value for failure to match.  */
#define REG_MISSING ((Idx) -1)

/* Special return value for internal error.  */
#define REG_ERROR ((Idx) -2)

/* Test whether N is a valid index, and is not one of the above.  */
#ifdef _REGEX_LARGE_OFFSETS
# define REG_VALID_INDEX(n) ((Idx) (n) < REG_ERROR)
#else
# define REG_VALID_INDEX(n) (0 <= (n))
#endif

/* Test whether N is a valid nonzero index.  */
#ifdef _REGEX_LARGE_OFFSETS
# define REG_VALID_NONZERO_INDEX(n) ((Idx) ((n) - 1) < (Idx) (REG_ERROR - 1))
#else
# define REG_VALID_NONZERO_INDEX(n) (0 < (n))
#endif

/* A hash value, suitable for computing hash tables.  */
typedef __re_size_t re_hashval_t;

/* An integer used to represent a set of bits.  It must be unsigned,
   and must be at least as wide as unsigned int.  */
typedef unsigned long int bitset_word_t;
/* All bits set in a bitset_word_t.  */
#define BITSET_WORD_MAX ULONG_MAX

/* Number of bits in a bitset_word_t.  For portability to hosts with
   padding bits, do not use '(sizeof (bitset_word_t) * CHAR_BIT)';
   instead, deduce it directly from BITSET_WORD_MAX.  Avoid
   greater-than-32-bit integers and unconditional shifts by more than
   31 bits, as they're not portable.  */
#if BITSET_WORD_MAX == 0xffffffffUL
# define BITSET_WORD_BITS 32
#elif BITSET_WORD_MAX >> 31 >> 4 == 1
# define BITSET_WORD_BITS 36
#elif BITSET_WORD_MAX >> 31 >> 16 == 1
# define BITSET_WORD_BITS 48
#elif BITSET_WORD_MAX >> 31 >> 28 == 1
# define BITSET_WORD_BITS 60
#elif BITSET_WORD_MAX >> 31 >> 31 >> 1 == 1
# define BITSET_WORD_BITS 64
#elif BITSET_WORD_MAX >> 31 >> 31 >> 9 == 1
# define BITSET_WORD_BITS 72
#elif BITSET_WORD_MAX >> 31 >> 31 >> 31 >> 31 >> 3 == 1
# define BITSET_WORD_BITS 128
#elif BITSET_WORD_MAX >> 31 >> 31 >> 31 >> 31 >> 31 >> 31 >> 31 >> 31 >> 7 == 1
# define BITSET_WORD_BITS 256
#elif BITSET_WORD_MAX >> 31 >> 31 >> 31 >> 31 >> 31 >> 31 >> 31 >> 31 >> 7 > 1
# define BITSET_WORD_BITS 257 /* any value > SBC_MAX will do here */
# if BITSET_WORD_BITS <= SBC_MAX
#  error "Invalid SBC_MAX"
# endif
#else
# error "Add case for new bitset_word_t size"
#endif

/* Number of bitset_word_t values in a bitset_t.  */
#define BITSET_WORDS ((SBC_MAX + BITSET_WORD_BITS - 1) / BITSET_WORD_BITS)

typedef bitset_word_t bitset_t[BITSET_WORDS];
typedef bitset_word_t *re_bitset_ptr_t;
typedef const bitset_word_t *re_const_bitset_ptr_t;

#define PREV_WORD_CONSTRAINT 0x0001
#define PREV_NOTWORD_CONSTRAINT 0x0002
#define NEXT_WORD_CONSTRAINT 0x0004
#define NEXT_NOTWORD_CONSTRAINT 0x0008
#define PREV_NEWLINE_CONSTRAINT 0x0010
#define NEXT_NEWLINE_CONSTRAINT 0x0020
#define PREV_BEGBUF_CONSTRAINT 0x0040
#define NEXT_ENDBUF_CONSTRAINT 0x0080
#define WORD_DELIM_CONSTRAINT 0x0100
#define NOT_WORD_DELIM_CONSTRAINT 0x0200

typedef enum
{
  INSIDE_WORD = PREV_WORD_CONSTRAINT | NEXT_WORD_CONSTRAINT,
  WORD_FIRST = PREV_NOTWORD_CONSTRAINT | NEXT_WORD_CONSTRAINT,
  WORD_LAST = PREV_WORD_CONSTRAINT | NEXT_NOTWORD_CONSTRAINT,
  INSIDE_NOTWORD = PREV_NOTWORD_CONSTRAINT | NEXT_NOTWORD_CONSTRAINT,
  LINE_FIRST = PREV_NEWLINE_CONSTRAINT,
  LINE_LAST = NEXT_NEWLINE_CONSTRAINT,
  BUF_FIRST = PREV_BEGBUF_CONSTRAINT,
  BUF_LAST = NEXT_ENDBUF_CONSTRAINT,
  WORD_DELIM = WORD_DELIM_CONSTRAINT,
  NOT_WORD_DELIM = NOT_WORD_DELIM_CONSTRAINT
} re_context_type;

typedef struct
{
  Idx alloc;
  Idx nelem;
  Idx *elems;
} re_node_set;

typedef enum
{
  NON_TYPE = 0,

  /* Node type, These are used by token, node, tree.  */
  CHARACTER = 1,
  END_OF_RE = 2,
  SIMPLE_BRACKET = 3,
  OP_BACK_REF = 4,
  OP_PERIOD = 5,
#ifdef RE_ENABLE_I18N
  COMPLEX_BRACKET = 6,
  OP_UTF8_PERIOD = 7,
#endif /* RE_ENABLE_I18N */

  /* We define EPSILON_BIT as a macro so that OP_OPEN_SUBEXP is used
     when the debugger shows values of this enum type.  */
#define EPSILON_BIT 8
  OP_OPEN_SUBEXP = EPSILON_BIT | 0,
  OP_CLOSE_SUBEXP = EPSILON_BIT | 1,
  OP_ALT = EPSILON_BIT | 2,
  OP_DUP_ASTERISK = EPSILON_BIT | 3,
  ANCHOR = EPSILON_BIT | 4,

  /* Tree type, these are used only by tree. */
  CONCAT = 16,
  SUBEXP = 17,

  /* Token type, these are used only by token.  */
  OP_DUP_PLUS = 18,
  OP_DUP_QUESTION,
  OP_OPEN_BRACKET,
  OP_CLOSE_BRACKET,
  OP_CHARSET_RANGE,
  OP_OPEN_DUP_NUM,
  OP_CLOSE_DUP_NUM,
  OP_NON_MATCH_LIST,
  OP_OPEN_COLL_ELEM,
  OP_CLOSE_COLL_ELEM,
  OP_OPEN_EQUIV_CLASS,
  OP_CLOSE_EQUIV_CLASS,
  OP_OPEN_CHAR_CLASS,
  OP_CLOSE_CHAR_CLASS,
  OP_WORD,
  OP_NOTWORD,
  OP_SPACE,
  OP_NOTSPACE,
  BACK_SLASH

} re_token_type_t;

#ifdef RE_ENABLE_I18N
typedef struct
{
  /* Multibyte characters.  */
  rpl__wchar_t *mbchars;

  /* Collating symbols.  */
# if (defined(_LIBC) || defined(_PERL_I18N))
#   ifdef _LIBC
  int32_t *coll_syms;
#   else
  UV *coll_syms;
#   endif
# endif

  /* Equivalence classes. */
# if (defined(_LIBC) || defined(_PERL_I18N))
#   ifdef _LIBC
  int32_t *equiv_classes;
#   else
  UV *equiv_classes;
#   endif
# endif

  /* Range expressions. */
# ifdef _LIBC
  uint32_t *range_starts;
  uint32_t *range_ends;
# else /* not _LIBC */
  rpl__wchar_t *range_starts;
  rpl__wchar_t *range_ends;
# endif /* not _LIBC */

  /* Character classes. */
  rpl__wctype_t *char_classes;

  /* If this character set is the non-matching list.  */
  unsigned int non_match : 1;

  /* # of multibyte characters.  */
  Idx nmbchars;

  /* # of collating symbols.  */
  Idx ncoll_syms;

  /* # of equivalence classes. */
  Idx nequiv_classes;

  /* # of range expressions. */
  Idx nranges;

  /* # of character classes. */
  Idx nchar_classes;
} re_charset_t;
#endif /* RE_ENABLE_I18N */

typedef struct
{
  union
  {
    unsigned char c;		/* for CHARACTER */
    re_bitset_ptr_t sbcset;	/* for SIMPLE_BRACKET */
#ifdef RE_ENABLE_I18N
    re_charset_t *mbcset;	/* for COMPLEX_BRACKET */
#endif /* RE_ENABLE_I18N */
    Idx idx;			/* for BACK_REF */
    re_context_type ctx_type;	/* for ANCHOR */
  } opr;
#if __GNUC__ >= 2 && !defined __STRICT_ANSI__
  re_token_type_t type : 8;
#else
  re_token_type_t type;
#endif
  unsigned int constraint : 10;	/* context constraint */
  unsigned int duplicated : 1;
  unsigned int opt_subexp : 1;
#ifdef RE_ENABLE_I18N
  unsigned int accept_mb : 1;
  /* These 2 bits can be moved into the union if needed (e.g. if running out
     of bits; move opr.c to opr.c.c and move the flags to opr.c.flags).  */
  unsigned int mb_partial : 1;
#endif
  unsigned int word_char : 1;
} re_token_t;

#define IS_EPSILON_NODE(type) ((type) & EPSILON_BIT)

struct re_string_t
{
  /* Indicate the raw buffer which is the original string passed as an
     argument of regexec(), re_search(), etc..  */
  const unsigned char *raw_mbs;
  /* Store the multibyte string.  In case of "case insensitive mode" like
     REG_ICASE, upper cases of the string are stored, otherwise MBS points
     the same address that RAW_MBS points.  */
  unsigned char *mbs;
#ifdef RE_ENABLE_I18N
  /* Store the wide character string which is corresponding to MBS.  */
  rpl__wint_t *wcs;
  Idx *offsets;
  rpl__mbstate_t cur_state;
#endif
  /* Index in RAW_MBS.  Each character mbs[i] corresponds to
     raw_mbs[raw_mbs_idx + i].  */
  Idx raw_mbs_idx;
  /* The length of the valid characters in the buffers.  */
  Idx valid_len;
  /* The corresponding number of bytes in raw_mbs array.  */
  Idx valid_raw_len;
  /* The length of the buffers MBS and WCS.  */
  Idx bufs_len;
  /* The index in MBS, which is updated by re_string_fetch_byte.  */
  Idx cur_idx;
  /* length of RAW_MBS array.  */
  Idx raw_len;
  /* This is RAW_LEN - RAW_MBS_IDX + VALID_LEN - VALID_RAW_LEN.  */
  Idx len;
  /* End of the buffer may be shorter than its length in the cases such
     as re_match_2, re_search_2.  Then, we use STOP for end of the buffer
     instead of LEN.  */
  Idx raw_stop;
  /* This is RAW_STOP - RAW_MBS_IDX adjusted through OFFSETS.  */
  Idx stop;

  /* The context of mbs[0].  We store the context independently, since
     the context of mbs[0] may be different from raw_mbs[0], which is
     the beginning of the input string.  */
  unsigned int tip_context;
  /* The translation passed as a part of an argument of re_compile_pattern.  */
  RE_TRANSLATE_TYPE trans;
  /* Copy of re_dfa_t's word_char.  */
  re_const_bitset_ptr_t word_char;
  /* true if REG_ICASE.  */
  unsigned char icase;
  unsigned char is_utf8;
  unsigned char map_notascii;
  unsigned char mbs_allocated;
  unsigned char offsets_needed;
  unsigned char newline_anchor;
  unsigned char word_ops_used;
  int mb_cur_max;
};
typedef struct re_string_t re_string_t;


struct re_dfa_t;
typedef struct re_dfa_t re_dfa_t;

#ifndef _LIBC
# define internal_function
#endif

#ifndef NOT_IN_libc
static reg_errcode_t re_string_realloc_buffers (pTHX_ re_string_t *pstr,
						Idx new_buf_len)
     internal_function;
# ifdef RE_ENABLE_I18N
static void build_wcs_buffer (pTHX_ re_string_t *pstr) internal_function;
static reg_errcode_t build_wcs_upper_buffer (pTHX_ re_string_t *pstr)
  internal_function;
# endif /* RE_ENABLE_I18N */
static void build_upper_buffer (pTHX_ re_string_t *pstr) internal_function;
static void re_string_translate_buffer (pTHX_ re_string_t *pstr) internal_function;
static unsigned int re_string_context_at (pTHX_ const re_string_t *input, Idx idx,
					  int eflags)
     internal_function __attribute__ ((pure));
#endif
#define re_string_peek_byte(pstr, offset) \
  ((pstr)->mbs[(pstr)->cur_idx + offset])
#define re_string_fetch_byte(pstr) \
  ((pstr)->mbs[(pstr)->cur_idx++])
#define re_string_first_byte(pstr, idx) \
  ((idx) == (pstr)->valid_len || (pstr)->wcs[idx] != rpl__WEOF)
#define re_string_is_single_byte_char(pstr, idx) \
  ((pstr)->wcs[idx] != rpl__WEOF && ((pstr)->valid_len == (idx) + 1 \
				|| (pstr)->wcs[(idx) + 1] != rpl__WEOF))
#define re_string_eoi(pstr) ((pstr)->stop <= (pstr)->cur_idx)
#define re_string_cur_idx(pstr) ((pstr)->cur_idx)
#define re_string_get_buffer(pstr) ((pstr)->mbs)
#define re_string_length(pstr) ((pstr)->len)
#define re_string_byte_at(pstr,idx) ((pstr)->mbs[idx])
#define re_string_skip_bytes(pstr,idx) ((pstr)->cur_idx += (idx))
#define re_string_set_index(pstr,idx) ((pstr)->cur_idx = (idx))

#if defined _LIBC || HAVE_ALLOCA
# include <alloca.h>
#endif

#ifndef _LIBC
# if HAVE_ALLOCA
/* The OS usually guarantees only one guard page at the bottom of the stack,
   and a page size can be as small as 4096 bytes.  So we cannot safely
   allocate anything larger than 4096 bytes.  Also care for the possibility
   of a few compiler-allocated temporary stack slots.  */
#  define __libc_use_alloca(n) ((n) < 4032)
# else
/* alloca is implemented with malloc, so just use malloc.  */
#  define __libc_use_alloca(n) 0
#  undef alloca
#  define alloca(n) malloc (n)
# endif
#endif

#ifdef _LIBC
# define MALLOC_0_IS_NONNULL 1
#elif !defined MALLOC_0_IS_NONNULL
# define MALLOC_0_IS_NONNULL 0
#endif

#ifndef MAX
# define MAX(a,b) ((a) < (b) ? (b) : (a))
#endif
#ifndef MIN
# define MIN(a,b) ((a) < (b) ? (a) : (b))
#endif

/*  t* p = malloc(n) <==> Newx(p, n, t) */
/* #define re_malloc(t,n) ((t *) malloc ((n) * sizeof (t))) */
#define re_malloc(dst,t,n) Newx(dst, (n) * sizeof (t), t)

/* p = ((t *) realloc(p, n)) <==> Renew(p, n, t) */
/* #define re_realloc(p,t,n) ((t *) realloc (p, (n) * sizeof (t))) */
#define re_realloc(p,t,n) Renew(p, (n) * sizeof (t), t)

#define re_calloc(dst,t,n) Newxz(dst, (n) * sizeof (t), t)

/*  free(p) <==> Safefree(p) */
/* #define re_free(p) free (p) */
#define re_free(p) do { if (p != NULL) { Safefree (p); } p = NULL; } while (0)

struct bin_tree_t
{
  struct bin_tree_t *parent;
  struct bin_tree_t *left;
  struct bin_tree_t *right;
  struct bin_tree_t *first;
  struct bin_tree_t *next;

  re_token_t token;

  /* 'node_idx' is the index in dfa->nodes, if 'type' == 0.
     Otherwise 'type' indicate the type of this node.  */
  Idx node_idx;
};
typedef struct bin_tree_t bin_tree_t;

#define BIN_TREE_STORAGE_SIZE \
  ((1024 - sizeof (void *)) / sizeof (bin_tree_t))

struct bin_tree_storage_t
{
  struct bin_tree_storage_t *next;
  bin_tree_t data[BIN_TREE_STORAGE_SIZE];
};
typedef struct bin_tree_storage_t bin_tree_storage_t;

#define CONTEXT_WORD 1
#define CONTEXT_NEWLINE (CONTEXT_WORD << 1)
#define CONTEXT_BEGBUF (CONTEXT_NEWLINE << 1)
#define CONTEXT_ENDBUF (CONTEXT_BEGBUF << 1)

#define IS_WORD_CONTEXT(c) ((c) & CONTEXT_WORD)
#define IS_NEWLINE_CONTEXT(c) ((c) & CONTEXT_NEWLINE)
#define IS_BEGBUF_CONTEXT(c) ((c) & CONTEXT_BEGBUF)
#define IS_ENDBUF_CONTEXT(c) ((c) & CONTEXT_ENDBUF)
#define IS_ORDINARY_CONTEXT(c) ((c) == 0)

#define IS_WORD_CHAR(ch) (rpl__isalnum (ch) || (ch) == '_')
#define IS_NEWLINE(ch) ((ch) == NEWLINE_CHAR)
#define IS_WIDE_WORD_CHAR(ch) (rpl__iswalnum (ch) || (ch) == L'_')
#define IS_WIDE_NEWLINE(ch) ((ch) == WIDE_NEWLINE_CHAR)

#define NOT_SATISFY_PREV_CONSTRAINT(constraint,context) \
 ((((constraint) & PREV_WORD_CONSTRAINT) && !IS_WORD_CONTEXT (context)) \
  || ((constraint & PREV_NOTWORD_CONSTRAINT) && IS_WORD_CONTEXT (context)) \
  || ((constraint & PREV_NEWLINE_CONSTRAINT) && !IS_NEWLINE_CONTEXT (context))\
  || ((constraint & PREV_BEGBUF_CONSTRAINT) && !IS_BEGBUF_CONTEXT (context)))

#define NOT_SATISFY_NEXT_CONSTRAINT(constraint,context) \
 ((((constraint) & NEXT_WORD_CONSTRAINT) && !IS_WORD_CONTEXT (context)) \
  || (((constraint) & NEXT_NOTWORD_CONSTRAINT) && IS_WORD_CONTEXT (context)) \
  || (((constraint) & NEXT_NEWLINE_CONSTRAINT) && !IS_NEWLINE_CONTEXT (context)) \
  || (((constraint) & NEXT_ENDBUF_CONSTRAINT) && !IS_ENDBUF_CONTEXT (context)))

struct re_dfastate_t
{
  re_hashval_t hash;
  re_node_set nodes;
  re_node_set non_eps_nodes;
  re_node_set inveclosure;
  re_node_set *entrance_nodes;
  struct re_dfastate_t **trtable, **word_trtable;
  unsigned int context : 4;
  unsigned int halt : 1;
  /* If this state can accept "multi byte".
     Note that we refer to multibyte characters, and multi character
     collating elements as "multi byte".  */
  unsigned int accept_mb : 1;
  /* If this state has backreference node(s).  */
  unsigned int has_backref : 1;
  unsigned int has_constraint : 1;
};
typedef struct re_dfastate_t re_dfastate_t;

struct re_state_table_entry
{
  Idx num;
  Idx alloc;
  re_dfastate_t **array;
};

/* Array type used in re_sub_match_last_t and re_sub_match_top_t.  */

typedef struct
{
  Idx next_idx;
  Idx alloc;
  re_dfastate_t **array;
} state_array_t;

/* Store information about the node NODE whose type is OP_CLOSE_SUBEXP.  */

typedef struct
{
  Idx node;
  Idx str_idx; /* The position NODE match at.  */
  state_array_t path;
} re_sub_match_last_t;

/* Store information about the node NODE whose type is OP_OPEN_SUBEXP.
   And information about the node, whose type is OP_CLOSE_SUBEXP,
   corresponding to NODE is stored in LASTS.  */

typedef struct
{
  Idx str_idx;
  Idx node;
  state_array_t *path;
  Idx alasts; /* Allocation size of LASTS.  */
  Idx nlasts; /* The number of LASTS.  */
  re_sub_match_last_t **lasts;
} re_sub_match_top_t;

struct re_backref_cache_entry
{
  Idx node;
  Idx str_idx;
  Idx subexp_from;
  Idx subexp_to;
  char more;
  char unused;
  unsigned short int eps_reachable_subexps_map;
};

typedef struct
{
  /* The string object corresponding to the input string.  */
  re_string_t input;
#if defined _LIBC || (defined __STDC_VERSION__ && __STDC_VERSION__ >= 199901L)
  const re_dfa_t *const dfa;
#else
  const re_dfa_t *dfa;
#endif
  /* EFLAGS of the argument of regexec.  */
  int eflags;
  /* Where the matching ends.  */
  Idx match_last;
  Idx last_node;
  /* The state log used by the matcher.  */
  re_dfastate_t **state_log;
  Idx state_log_top;
  /* Back reference cache.  */
  Idx nbkref_ents;
  Idx abkref_ents;
  struct re_backref_cache_entry *bkref_ents;
  int max_mb_elem_len;
  Idx nsub_tops;
  Idx asub_tops;
  re_sub_match_top_t **sub_tops;
#ifdef _PERL_I18N
  SV *sv;
#endif
} re_match_context_t;

typedef struct
{
  re_dfastate_t **sifted_states;
  re_dfastate_t **limited_states;
  Idx last_node;
  Idx last_str_idx;
  re_node_set limits;
} re_sift_context_t;

struct re_fail_stack_ent_t
{
  Idx idx;
  Idx node;
  regmatch_t *regs;
  re_node_set eps_via_nodes;
};

struct re_fail_stack_t
{
  Idx num;
  Idx alloc;
  struct re_fail_stack_ent_t *stack;
};

struct re_dfa_t
{
  re_token_t *nodes;
  size_t nodes_alloc;
  size_t nodes_len;
  Idx *nexts;
  Idx *org_indices;
  re_node_set *edests;
  re_node_set *eclosures;
  re_node_set *inveclosures;
  struct re_state_table_entry *state_table;
  re_dfastate_t *init_state;
  re_dfastate_t *init_state_word;
  re_dfastate_t *init_state_nl;
  re_dfastate_t *init_state_begbuf;
  bin_tree_t *str_tree;
  bin_tree_storage_t *str_tree_storage;
  re_bitset_ptr_t sb_char;
  int str_tree_storage_idx;

  /* number of subexpressions 're_nsub' is in regex_t.  */
  re_hashval_t state_hash_mask;
  Idx init_node;
  Idx nbackref; /* The number of backreference in this dfa.  */

  /* Bitmap expressing which backreference is used.  */
  bitset_word_t used_bkref_map;
  bitset_word_t completed_bkref_map;

  unsigned int has_plural_match : 1;
  /* If this dfa has "multibyte node", which is a backreference or
     a node which can accept multibyte character or multi character
     collating element.  */
  unsigned int has_mb_node : 1;
  unsigned int is_utf8 : 1;
  unsigned int map_notascii : 1;
  unsigned int word_ops_used : 1;
  int mb_cur_max;
  bitset_t word_char;
  reg_syntax_t syntax;
  Idx *subexp_map;
#ifdef DEBUG
  char* re_str;
#endif
  lock_define (lock)
};

/*  memset(dst, 0, n * sizeof(t)) <==> Zero(dst, n, t) */
/* #define re_node_set_init_empty(set) memset (set, '\0', sizeof (re_node_set)) */
#define re_node_set_init_empty(set) Zero(set, 1, re_node_set)

#define re_node_set_remove(set,id) \
  (re_node_set_remove_at (set, re_node_set_contains (set, id) - 1))
#define re_node_set_empty(p) ((p)->nelem = 0)
#define re_node_set_free(set) re_free ((set)->elems)


typedef enum
{
  SB_CHAR,
  MB_CHAR,
  EQUIV_CLASS,
  COLL_SYM,
  CHAR_CLASS
} bracket_elem_type;

typedef struct
{
  bracket_elem_type type;
  union
  {
    unsigned char ch;
    unsigned char *name;
    rpl__wchar_t wch;
  } opr;
} bracket_elem_t;


/* Functions for bitset_t operation.  */

static void
bitset_set (pTHX_ bitset_t set, Idx i)
{
  set[i / BITSET_WORD_BITS] |= (bitset_word_t) 1 << i % BITSET_WORD_BITS;
}

static void
bitset_clear (bitset_t set, Idx i)
{
  set[i / BITSET_WORD_BITS] &= ~ ((bitset_word_t) 1 << i % BITSET_WORD_BITS);
}

static bool
bitset_contain (pTHX_ const bitset_t set, Idx i)
{
  return ((set[i / BITSET_WORD_BITS] >> i % BITSET_WORD_BITS) & 1) ? true : false;
}

static void
bitset_empty (pTHX_ bitset_t set)
{
  Zero(set, 1, bitset_t);
}

static void
bitset_set_all (pTHX_ bitset_t set)
{
  memset (set, -1, sizeof (bitset_word_t) * (SBC_MAX / BITSET_WORD_BITS));
  if (SBC_MAX % BITSET_WORD_BITS != 0)
    set[BITSET_WORDS - 1] =
      ((bitset_word_t) 1 << SBC_MAX % BITSET_WORD_BITS) - 1;
}

static void
bitset_copy (pTHX_ bitset_t dest, const bitset_t src)
{
  Copy (src, dest, 1, bitset_t);
}

static void __attribute__ ((unused))
bitset_not (pTHX_ bitset_t set)
{
  int bitset_i;
  for (bitset_i = 0; bitset_i < SBC_MAX / BITSET_WORD_BITS; ++bitset_i)
    set[bitset_i] = ~set[bitset_i];
  if (SBC_MAX % BITSET_WORD_BITS != 0)
    set[BITSET_WORDS - 1] =
      ((((bitset_word_t) 1 << SBC_MAX % BITSET_WORD_BITS) - 1)
       & ~set[BITSET_WORDS - 1]);
}

static void __attribute__ ((unused))
bitset_merge (pTHX_ bitset_t dest, const bitset_t src)
{
  int bitset_i;
  for (bitset_i = 0; bitset_i < BITSET_WORDS; ++bitset_i)
    dest[bitset_i] |= src[bitset_i];
}

static void __attribute__ ((unused))
bitset_mask (pTHX_ bitset_t dest, const bitset_t src)
{
  int bitset_i;
  for (bitset_i = 0; bitset_i < BITSET_WORDS; ++bitset_i)
    dest[bitset_i] &= src[bitset_i];
}

#ifdef RE_ENABLE_I18N
/* Functions for re_string.  */
static int
internal_function __attribute__ ((pure, unused))
re_string_char_size_at (pTHX_ const re_string_t *pstr, Idx idx)
{
  int byte_idx;
  if (pstr->mb_cur_max == 1)
    return 1;
  for (byte_idx = 1; idx + byte_idx < pstr->valid_len; ++byte_idx)
    if (pstr->wcs[idx + byte_idx] != rpl__WEOF)
      break;
  return byte_idx;
}

static rpl__wint_t
internal_function __attribute__ ((pure, unused))
re_string_wchar_at (pTHX_ const re_string_t *pstr, Idx idx)
{
  if (pstr->mb_cur_max == 1)
    return (rpl__wint_t) pstr->mbs[idx];
  return (rpl__wint_t) pstr->wcs[idx];
}

#ifndef _LIBC
#ifdef _PERL_I18N
size_t rpl_Perl_MB_CUR_MAX(pTHX) {
  size_t rc;

  rc = rpl__MB_LEN_MAX;
#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_MB_CUR_MAX() ==> %d\n", (int) rc);
#endif
  return rc;
}
/* Initalize only the first element */
static rpl_Perl_mbstate_t Perl_internal_state = { 0 };

int rpl_Perl_isascii(pTHX_ UV c) {
  int rc;
#ifndef isASCII_LC_uvchr
#define isASCII_LC_uvchr isASCII_LC
#ifndef isASCII_LC
#define isASCII_LC isASCII
#endif
#endif
  rc = isASCII_LC_uvchr(c);

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_isascii(%d) ==> %d\n", (int) c, rc);
#endif
  return rc;
}

int rpl_Perl_isalnum(pTHX_ UV c) {
  int rc;
#ifndef isALNUM_LC_uvchr
#define isALNUM_LC_uvchr isALNUM_LC
#ifndef isALNUM_LC
#define isALNUM_LC isALNUM
#endif
#endif
  rc = isALNUM_LC_uvchr(c);

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_isalnum(%d) ==> %d\n", (int) c, rc);
#endif

  return rc;
}

int rpl_Perl_iswalnum(pTHX_ UV c) {
  int rc;
#ifndef isALNUM_LC_uvchr
#define isALNUM_LC_uvchr isALNUM_LC
#ifndef isALNUM_LC
#define isALNUM_LC isALNUM
#endif
#endif
  rc = isALNUM_LC_uvchr(c);

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_iswalnum(%d) ==> %d\n", (int) c, rc);
#endif

  return rc;
}

int rpl_Perl_iscntrl(pTHX_ UV c) {
  int rc;
#ifndef isCNTRL_LC_uvchr
#define isCNTRL_LC_uvchr isCNTRL_LC
#ifndef isCNTRL_LC
#define isCNTRL_LC isCNTRL
#endif
#endif
  rc = isCNTRL_LC_uvchr(c);

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_iscntrl(%d) ==> %d\n", (int) c, rc);
#endif

  return rc;
}

int rpl_Perl_islower(pTHX_ UV c) {
  int rc;
#ifndef isLOWER_LC_uvchr
#define isLOWER_LC_uvchr isLOWER_LC
#ifndef isLOWER_LC
#define isLOWER_LC isLOWER
#endif
#endif
  rc = isLOWER_LC_uvchr(c);

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_islower(%d) ==> %d\n", (int) c, rc);
#endif

  return rc;
}

int rpl_Perl_isspace(pTHX_ UV c) {
  int rc;
#ifndef isSPACE_LC_uvchr
#define isSPACE_LC_uvchr isSPACE_LC
#ifndef isSPACE_LC
#define isSPACE_LC isSPACE
#endif
#endif
  rc = isSPACE_LC_uvchr(c);

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_isspace(%d) ==> %d\n", (int) c, rc);
#endif

  return rc;
}

int rpl_Perl_isalpha(pTHX_ UV c) {
  int rc;
#ifndef isALPHA_LC_uvchr
#define isALPHA_LC_uvchr isALPHA_LC
#ifndef isALPHA_LC
#define isALPHA_LC isALPHA
#endif
#endif
  rc = isALPHA_LC_uvchr(c);

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_isalpha(%d) ==> %d\n", (int) c, rc);
#endif

  return rc;
}

int rpl_Perl_isdigit(pTHX_ UV c) {
  int rc;
#ifndef isDIGIT_LC_uvchr
#define isDIGIT_LC_uvchr isDIGIT_LC
#ifndef isDIGIT_LC
#define isDIGIT_LC isDIGIT
#endif
#endif
  rc = isDIGIT_LC_uvchr(c);

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_isdigit(%d) ==> %d\n", (int) c, rc);
#endif

  return rc;
}

int rpl_Perl_isprint(pTHX_ UV c) {
  int rc;
#ifndef isPRINT_LC_uvchr
#define isPRINT_LC_uvchr isPRINT_LC
#ifndef isPRINT_LC
#define isPRINT_LC isPRINT
#endif
#endif
  rc = isPRINT_LC_uvchr(c);

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_isprint(%d) ==> %d\n", (int) c, rc);
#endif

  return rc;
}

int rpl_Perl_isupper(pTHX_ UV c) {
  int rc;
#ifndef isUPPER_LC_uvchr
#define isUPPER_LC_uvchr isUPPER_LC
#ifndef isUPPER_LC
#define isUPPER_LC isUPPER
#endif
#endif
  rc = isUPPER_LC_uvchr(c);

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_isupper(%d) ==> %d\n", (int) c, rc);
#endif

  return rc;
}

int rpl_Perl_isblank(pTHX_ UV c) {
  int rc;
#ifndef isBLANK_LC_uvchr
#define isBLANK_LC_uvchr isBLANK_LC
#ifndef isBLANK_LC
#define isBLANK_LC isBLANK
#endif
#endif
  rc = isBLANK_LC_uvchr(c);

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_isblank(%d) ==> %d\n", (int) c, rc);
#endif

  return rc;
}

int rpl_Perl_isgraph(pTHX_ UV c) {
  int rc;
#ifndef isGRAPH_LC_uvchr
#define isGRAPH_LC_uvchr isGRAPH_LC
#ifndef isGRAPH_LC
#define isGRAPH_LC isGRAPH
#endif
#endif
  rc = isGRAPH_LC_uvchr(c);

#ifndef DEBUG
  fprintf(stderr, "rpl_Perl_isgraph(%d) ==> %d\n", (int) c, rc);
#endif

  return rc;
}

int rpl_Perl_ispunct(pTHX_ UV c) {
  int rc;
#ifndef isPUNCT_LC_uvchr
#define isPUNCT_LC_uvchr isPUNCT_LC
#ifndef isPUNCT_LC
#define isPUNCT_LC isPUNCT
#endif
#endif
  rc = isPUNCT_LC_uvchr(c);

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_ispunct(%d) ==> %d\n", (int) c, rc);
#endif

  return rc;
}

int rpl_Perl_isxdigit(pTHX_ UV c) {
  int rc;
#ifndef isXDIGIT_LC_uvchr
#define isXDIGIT_LC_uvchr isXDIGIT_LC
#ifndef isXDIGIT_LC
#define isXDIGIT_LC isXDIGIT
#endif
#endif
  rc = isXDIGIT_LC_uvchr(c);

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_isxdigit(%d) ==> %d\n", (int) c, rc);
#endif

  return rc;
}

int rpl_Perl_iswlower(pTHX_ UV wc) {
  int rc = rpl_Perl_islower(aTHX_ wc);

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_iswlower(%ld) ==> %d\n", (unsigned long) wc, rc);
#endif

  return rc;
}

/* Our mb implementations are all stateless */
size_t rpl_Perl_mbrtowc(pTHX_ UV *restrict pwc, const char *restrict s, size_t n, void *restrict ps) {
  STRLEN ch_len;
  UV     ord;
  size_t rc;
#ifndef NDEBUG
  void octdump(pTHX_ const void *mem, unsigned int len);
#endif

  if (s == NULL) {
    pwc = NULL;
    s = "";
    n = 1;
  }

#ifndef NDEBUG
  octdump(aTHX_ s, n);
#endif

  if (n == 0) {
    rc = (size_t)(-2);
  }
  else {
    /* In here you find the reason why the buffers allocated at the */
    /* very beginning are already the full buffers: I do not want */
    /* Perl to raise a warning if the buffer is not enough. So I */
    /* should not use UTF8_CHECK_ONLY. But the only way to NOT raise */
    /* a warning is to use UTF8_CHECK_ONLY -; */
    /* This is why in this case we do never return -2: we made sure */
    /* at the very beginning that the buffer will always be large enough */

    ord = utf8n_to_uvchr((U8 *) s, n, &ch_len, UTF8_CHECK_ONLY);
    if (ord > 0 || *s == 0) {
      if (pwc != NULL) {
        *pwc = ord;
      }
      rc = (ord == 0) ? 0 : ch_len;
    } else {
      /* Invalid */
      errno = EILSEQ;
      /* The conversion state is undefined, says POSIX.  */
      rc = (size_t)(-1);
    }
  }

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_mbrtowc ==> %d\n", (int) rc);
#endif

  return rc;
}

int rpl_Perl_mbtowc(pTHX_ UV *restrict pwc, const char *restrict s, size_t n) {
  int rc;

  static rpl_Perl_mbstate_t state;
  /* If s is NULL the function has to return null or not null
     depending on the encoding having a state depending encoding or
     not. */
  if (s == NULL) {
    /* No support for state dependent encodings. */
    rc = 0;
  }
  else if (*s == '\0') {
    if (pwc != NULL) {
      *pwc = L'\0';
    }
    rc = 0;
  } else {
    rc = rpl_Perl_mbrtowc(aTHX_ pwc, s, n, &state);
    if (rc < 0) {
      rc = -1;
    }
  }

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_mbtowc(pwc, s=\"%s\", n=%d) ==> %d\n", s, (int) n, (int) rc);
#endif

  return rc;
}

rpl__wint_t rpl_Perl_btowc (pTHX_ int c) {
  rpl__wint_t rc = rpl__WEOF;

  if (c != EOF) {
    char buf[1];
    rpl__wchar_t wc;

    buf[0] = (U8)c;
    if (rpl_Perl_mbtowc(aTHX_ &wc, buf, 1) >= 0) {
      rc = (rpl__wint_t) wc;
    }
  }

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_btowc(c=%d) ==> %d\n", (int) c, (int) rc);
#endif

  return rc;
}

int rpl_Perl_iswctype(pTHX_ rpl__wint_t wi, rpl__wctype_t wt) {
  int rc;

  if (wi == rpl__WEOF) {
    rc = 0;
  } else {
    switch (wt) {
    case PERL_WCTYPE_ALNUM:
      rc = isALNUM_uni((UV) wi);
      break;
    case PERL_WCTYPE_ALPHA:
      rc = isALPHA_uni((UV) wi);
      break;
    case PERL_WCTYPE_CNTRL:
      rc = isCNTRL_uni((UV) wi);
      break;
    case PERL_WCTYPE_DIGIT:
      rc = isDIGIT_uni((UV) wi);
      break;
    case PERL_WCTYPE_GRAPH:
      rc = isGRAPH_uni((UV) wi);
      break;
    case PERL_WCTYPE_LOWER:
      rc = isLOWER_uni((UV) wi);
      break;
    case PERL_WCTYPE_PRINT:
      rc = isPRINT_uni((UV) wi);
      break;
    case PERL_WCTYPE_PUNCT:
      rc = isPUNCT_uni((UV) wi);
      break;
    case PERL_WCTYPE_SPACE:
      rc = isSPACE_uni((UV) wi);
      break;
    case PERL_WCTYPE_UPPER:
      rc = isUPPER_uni((UV) wi);
      break;
    case PERL_WCTYPE_XDIGIT:
      rc = isXDIGIT_uni((UV) wi);
      break;
    default:
      rc = 0;
    }
  }

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_iswctype(wi=%ld, wt=%d) ==> %d\n", (unsigned long) wi, (int) wt, (int) rc);
#endif

  return rc;
}

rpl_Perl_wctype_t rpl_Perl_wctype(pTHX_ const char * property) {
  rpl_Perl_wctype_t rc;

  if (strncmp(property, "alnum", sizeof("alnum") - 1) == 0) {
    rc = PERL_WCTYPE_ALNUM;
  }
  else if  (strncmp(property, "alpha", sizeof("alpha") - 1) == 0) {
    rc = PERL_WCTYPE_ALPHA;
  }
  else if  (strncmp(property, "cntrl", sizeof("cntrl") - 1) == 0) {
    rc = PERL_WCTYPE_CNTRL;
  }
  else if  (strncmp(property, "digit", sizeof("digit") - 1) == 0) {
    rc = PERL_WCTYPE_DIGIT;
  }
  else if  (strncmp(property, "graph", sizeof("graph") - 1) == 0) {
    rc = PERL_WCTYPE_GRAPH;
  }
  else if  (strncmp(property, "lower", sizeof("lower") - 1) == 0) {
    rc = PERL_WCTYPE_LOWER;
  }
  else if  (strncmp(property, "print", sizeof("print") - 1) == 0) {
    rc = PERL_WCTYPE_PRINT;
  }
  else if  (strncmp(property, "punct", sizeof("punct") - 1) == 0) {
    rc = PERL_WCTYPE_PUNCT;
  }
  else if  (strncmp(property, "space", sizeof("space") - 1) == 0) {
    rc = PERL_WCTYPE_SPACE;
  }
  else if  (strncmp(property, "upper", sizeof("upper") - 1) == 0) {
    rc = PERL_WCTYPE_UPPER;
  }
  else if  (strncmp(property, "xdigit", sizeof("xdigit") - 1) == 0) {
    rc = PERL_WCTYPE_XDIGIT;
  }
  else {
    rc = 0;
  }

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_wctype(property=%s) ==> %d\n", property, (int) rc);
#endif

  return rc;
}

int rpl_Perl_mbsinit(rpl__mbstate_t *ps) {
  const char *pstate = (const char *)ps;
  return (pstate == NULL) || (pstate[0] == 0);
}

int Perl_wctomb(pTHX_ char *restrict s, rpl__wchar_t wc) {
  U8     d[UTF8_MAXBYTES+1];
  bool   is_utf8 = 1;
  U8    *bytes;
  STRLEN len;

  if (s == NULL) {
    return 0;
  }

  if (wc == 0) {
    *s = '\0';
    return 1;
  }

  len = uvchr_to_utf8(d, (UV) wc) - d;
  bytes = bytes_from_utf8(d, &len, &is_utf8);
  memcpy(s, bytes, len);

  if (bytes != d) {
    Safefree(bytes);
  }
  
#ifndef NDEBUG
  fprintf(stderr, "Perl_wctomb(%ld) ==> %d\n", (unsigned long) wc, (int) len);
#endif

  return len;
}

size_t rpl_Perl_wcrtomb (pTHX_ char *s, rpl__wchar_t wc, rpl__mbstate_t *ps) {
  /* This implementation of wcrtomb on top of wctomb() supports only
     stateless encodings.  ps must be in the initial state.  */
  if (ps != NULL && !rpl_Perl_mbsinit ( ps))
    {
      errno = EINVAL;
      return (size_t)(-1);
    }

  if (s == NULL)
    /* We know the NUL wide character corresponds to the NUL character.  */
    return 1;
  else
    {
      int ret = Perl_wctomb (aTHX_ s, wc);

      if (ret >= 0)
        return ret;
      else
        {
          errno = EILSEQ;
          return (size_t)(-1);
        }
    }
}

rpl__wint_t rpl_Perl_towlower(pTHX_ UV wc) {
  U8     s[UTF8_MAXBYTES_CASE+1];
  rpl__wint_t rc;
  STRLEN len;

  rc = toLOWER_uni(wc, s, &len);

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_towlower(%d) ==> %d\n", (int) wc, (int) rc);
#endif

  return rc;

}

rpl__wint_t rpl_Perl_towupper(pTHX_ UV wc) {
  U8     s[UTF8_MAXBYTES_CASE+1];
  rpl__wint_t rc;
  STRLEN len;

  rc = toUPPER_uni(wc, s, &len);

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_towlower(%d) ==> %d\n", (int) wc, (int) rc);
#endif

  return rc;

}

rpl__wint_t rpl_Perl_tolower(pTHX_ UV c) {
  rpl__wint_t rc;

  /* The caller made sure that it fits in 8 bytes */
  rc = toLOWER((U8) c);

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_tolower(%d) ==> %d\n", (int) c, (int) rc);
#endif

  return rc;

}

rpl__wint_t rpl_Perl_toupper(pTHX_ UV c) {
  rpl__wint_t rc;

  /* The caller made sure that it fits in 8 bytes */
  rc = toUPPER((U8) c);

#ifndef NDEBUG
  fprintf(stderr, "rpl_Perl_toupper(%d) ==> %d\n", (int) c, (int) rc);
#endif

  return rc;

}

#endif /* _PERL_I18N */
#endif /* _LIBC */

# ifndef NOT_IN_libc
static int
internal_function __attribute__ ((pure, unused))
re_string_elem_size_at (pTHX_ const re_string_t *pstr, SV *sv, Idx idx)
{
#  ifdef _LIBC
  const unsigned char *p, *extra;
  const int32_t *table, *indirect;
#   include <locale/weight.h>
  uint_fast32_t nrules = _NL_CURRENT_WORD (LC_COLLATE, _NL_COLLATE_NRULES);

  if (nrules != 0)
    {
      table = (const int32_t *) _NL_CURRENT (LC_COLLATE, _NL_COLLATE_TABLEMB);
      extra = (const unsigned char *)
	_NL_CURRENT (LC_COLLATE, _NL_COLLATE_EXTRAMB);
      indirect = (const int32_t *) _NL_CURRENT (LC_COLLATE,
						_NL_COLLATE_INDIRECTMB);
      p = pstr->mbs + idx;
      findidx (&p, pstr->len - idx);
      return p - pstr->mbs - idx;
    }
  else
#  else
#    ifdef _PERL_I18N
    {
      if (! DO_UTF8(sv)) {
        /* Per def perl's non UTF-8 is one byte */
#ifndef NDEBUG
        fprintf(stderr, "re_string_elem_size_at(.., Idx=%d) => 1\n", (int) idx);
#endif
        return 1;
      } else {
        /* We know that pstr->mbs is at offset raw_mbs_idx v.s. original string */
        I32 offset = pstr->raw_mbs_idx + idx;
        I32 len = 1;

        sv_pos_b2u(sv, &offset);
        sv_pos_u2b(sv, &offset, &len);
#ifndef NDEBUG
        fprintf(stderr, "re_string_elem_size_at(.., Idx=%d) => %d\n", (int) idx, (int) len);
#endif
        return (int) len;
      }
      
    }
#    else
    return 1;
#    endif  
#  endif /* _LIBC */
}
# endif
#endif /* RE_ENABLE_I18N */

#ifndef __GNUC_PREREQ
# if defined __GNUC__ && defined __GNUC_MINOR__
#  define __GNUC_PREREQ(maj, min) \
         ((__GNUC__ << 16) + __GNUC_MINOR__ >= ((maj) << 16) + (min))
# else
#  define __GNUC_PREREQ(maj, min) 0
# endif
#endif

#if __GNUC_PREREQ (3,4)
# undef __attribute_warn_unused_result__
# define __attribute_warn_unused_result__ \
   __attribute__ ((__warn_unused_result__))
#else
# define __attribute_warn_unused_result__ /* empty */
#endif

#ifndef NDEBUG
#include <stdio.h>
#include <ctype.h>
 
#ifndef OCTDUMP_COLS
#define OCTDUMP_COLS 8
#endif
 
void octdump(pTHX_ const void *mem, unsigned int len)
{
  unsigned int i, j;
        
  for(i = 0; i < len + ((len % OCTDUMP_COLS) ? (OCTDUMP_COLS - len % OCTDUMP_COLS) : 0); i++)
    {
      /* print offset */
      if(i % OCTDUMP_COLS == 0)
        {
          fprintf(stderr, "0x%06x: ", i);
        }
 
      /* print oct data */
      if(i < len)
        {
          fprintf(stderr, "%03o ", 0xFF & ((char*)mem)[i]);
        }
      else /* end of block, just aligning for ASCII dump */
        {
          fprintf(stderr, "    ");
        }
                
      /* print ASCII dump */
      if(i % OCTDUMP_COLS == (OCTDUMP_COLS - 1))
        {
          for(j = i - (OCTDUMP_COLS - 1); j <= i; j++)
            {
              if(j >= len) /* end of block, not really printing */
                {
                  fprintf(stderr, "%c", ' ');
                }
              else if(isprint(((char*)mem)[j])) /* printable char */
                {
                  fprintf(stderr, "%c", 0xFF & ((char*)mem)[j]);        
                }
              else /* other char */
                {
                  fprintf(stderr, "%c", '.');
                }
            }
          fprintf(stderr, "\n");
        }
    }
}
#endif /* NDEBUG */
#endif /*  _REGEX_INTERNAL_H */
