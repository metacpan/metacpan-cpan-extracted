/* ------------------------------------------------------------------------
@NAME       : btparse.h
@DESCRIPTION: Declarations and types for the btparse core: a reentrant
              BibTeX parser plus the name, string and macro utilities
              used by Text::BibTeX.

              Nothing here keeps global state.  Everything that used to
              be global (lexer state, error counts, the macro table) now
              lives in an explicit object that the caller owns:

                bt_parser  - one input stream (file, handle or string)
                bt_macros  - a macro (@string) table
                bt_errors  - a list of errors/warnings collected during
                             a call; nothing is ever printed, and the
                             library never exits or aborts

              All text is handled as UTF-8 (or as opaque bytes when the
              caller asks for that); TeX markup is passed through
              unchanged.
@COPYRIGHT  : Copyright (c) 1996-99 by Gregory P. Ward.  All rights reserved.
              Rewrite copyright (c) 2026 the Text::BibTeX maintainers.

              This file is part of the btparse library.  This library is
              free software; you can redistribute it and/or modify it under
              the terms of the GNU Library General Public License as
              published by the Free Software Foundation; either version 2
              of the License, or (at your option) any later version.
-------------------------------------------------------------------------- */

#ifndef BTPARSE_H
#define BTPARSE_H

#include <stddef.h>

typedef unsigned short btshort;
typedef int boolean;

#ifndef TRUE
# define TRUE 1
# define FALSE 0
#endif

/* Post-processing options */
#define BTO_CONVERT   1                 /* convert numbers to strings? */
#define BTO_EXPAND    2                 /* expand macros? */
#define BTO_PASTE     4                 /* paste substrings together? */
#define BTO_COLLAPSE  8                 /* collapse whitespace? */
#define BTO_NOSTORE   16                /* don't store @string macros */
#define BTO_NOPOSTPROCESS 32            /* bt_parse_entry: return the raw */
                                        /* entry, don't post-process it */

#define BTO_FULL (BTO_CONVERT | BTO_EXPAND | BTO_PASTE | BTO_COLLAPSE)
#define BTO_MACRO (BTO_CONVERT | BTO_EXPAND | BTO_PASTE)
#define BTO_MINIMAL 0
#define BTO_STRINGMASK (BTO_CONVERT | BTO_EXPAND | BTO_PASTE | BTO_COLLAPSE)

/* Parser options (bt_parser_new_*) */
#define BTP_UTF8      1                 /* validate input as UTF-8 */

#define BT_VALID_NAMEPARTS "fvlj"
#define BT_MAX_NAMEPARTS 4

/* The numeric values of these enums are part of the Perl API. */
typedef enum
{
   BTE_UNKNOWN,
   BTE_REGULAR,
   BTE_COMMENT,
   BTE_PREAMBLE,
   BTE_MACRODEF
} bt_metatype;

#define NUM_METATYPES ((int) BTE_MACRODEF + 1)

typedef enum
{
   BTAST_BOGUS,                         /* to detect uninitialized nodes */
   BTAST_ENTRY,
   BTAST_KEY,
   BTAST_FIELD,
   BTAST_STRING,
   BTAST_NUMBER,
   BTAST_MACRO
} bt_nodetype;

typedef enum
{
   BTN_FIRST, BTN_VON, BTN_LAST, BTN_JR, BTN_NONE
} bt_namepart;

typedef enum
{
   BTJ_MAYTIE,                          /* "discretionary" tie between words */
   BTJ_SPACE,                           /* force a space between words */
   BTJ_FORCETIE,                        /* force a tie (~ in TeX) */
   BTJ_NOTHING                          /* nothing between words */
} bt_joinmethod;


/* ----------------------------------------------------------------------
 * Errors
 */

typedef enum
{
   BTERR_NOTIFY,                /* notification about next action */
   BTERR_CONTENT,               /* warning about the content of a record */
   BTERR_LEXWARN,               /* warning in lexical analysis */
   BTERR_USAGEWARN,             /* warning about library usage */
   BTERR_LEXERR,                /* error in lexical analysis */
   BTERR_SYNTAX,                /* error in parser */
   BTERR_USAGEERR,              /* fatal error in library usage */
   BTERR_INTERNAL               /* my fault */
} bt_errclass;

#define BT_NUM_ERRCLASSES ((int) BTERR_INTERNAL + 1)

typedef struct bt_error
{
   bt_errclass  errclass;
   char *       filename;               /* NULL if unknown */
   int          line;                   /* <= 0 if unknown */
   char *       item_desc;              /* eg. "name"; NULL if none */
   int          item;                   /* <= 0 if none */
   char *       message;
   struct bt_error * next;
} bt_error;

typedef struct
{
   bt_error *   head;
   bt_error *   tail;
   int          counts[BT_NUM_ERRCLASSES];
} bt_errors;

void bt_errors_init (bt_errors *errs);
void bt_errors_clear (bt_errors *errs);
void bt_report (bt_errors *errs, bt_errclass errclass,
                const char *filename, int line,
                const char *item_desc, int item,
                const char *fmt, ...)
#ifdef __GNUC__
   __attribute__ ((format (printf, 7, 8)))
#endif
   ;
int bt_errors_count (const bt_errors *errs, bt_errclass errclass);
boolean bt_errors_ok (const bt_errors *errs);      /* no serious errors? */
boolean bt_errors_fatal (const bt_errors *errs);   /* usage/internal error? */
const char *bt_errclass_name (bt_errclass errclass);


/* ----------------------------------------------------------------------
 * The abstract syntax tree for one entry
 */

typedef struct _ast
{
   struct _ast *right, *down;
   const char *  filename;              /* owned by the parser */
   int           line;
   long          offset;                /* byte offset of token in input */
   bt_nodetype   nodetype;
   bt_metatype   metatype;
   char *        text;
} AST;

void bt_free_ast (AST *ast);


/* ----------------------------------------------------------------------
 * Macro tables
 */

typedef struct bt_macros bt_macros;

bt_macros * bt_macros_new (bt_macros *parent);
void        bt_macros_free (bt_macros *macros);
bt_macros * bt_macros_clone (const bt_macros *macros, bt_macros *parent);

void   bt_add_macro_text (bt_macros *macros, bt_errors *errs,
                          const char *macro, const char *text,
                          const char *filename, int line);
void   bt_add_macro_value (bt_macros *macros, bt_errors *errs,
                           AST *assignment, btshort options);
void   bt_delete_macro (bt_macros *macros, const char *macro);
void   bt_delete_all_macros (bt_macros *macros);
int    bt_macro_length (bt_macros *macros, const char *macro);
const char * bt_macro_text (bt_macros *macros, bt_errors *errs,
                            const char *macro,
                            const char *filename, int line);


/* ----------------------------------------------------------------------
 * Parsing
 */

/* Read callback: fill buf with up to n bytes.  Return the number of bytes
 * read, 0 at end of input, or -1 on a read error. */
typedef long (*bt_read_fn) (void *userdata, char *buf, size_t n);

typedef struct bt_parser bt_parser;

bt_parser * bt_parser_new_reader (bt_read_fn read, void *userdata,
                                  const char *filename, unsigned flags);
bt_parser * bt_parser_new_string (const char *text, size_t len,
                                  const char *filename, int line,
                                  unsigned flags);
void        bt_parser_free (bt_parser *parser);
void        bt_parser_set_macros (bt_parser *parser, bt_macros *macros);
bt_macros * bt_parser_macros (bt_parser *parser);
const char *bt_parser_filename (bt_parser *parser);
boolean     bt_parser_read_error (bt_parser *parser);
boolean     bt_parser_eof (bt_parser *parser);   /* all input consumed? */

/* Parse the next entry.  Returns NULL at end of input.  Errors are
 * appended to errs; *status is set to FALSE if the returned entry (or
 * the attempt to find one) had any serious errors.  The returned AST
 * refers to the parser's filename and must not outlive the parser. */
AST * bt_parse_entry (bt_parser *parser, bt_errors *errs,
                      btshort options, boolean *status);


/* ----------------------------------------------------------------------
 * Post-processing and traversal
 */

char * bt_postprocess_string (const char *s, btshort options);
char * bt_postprocess_value (bt_macros *macros, bt_errors *errs,
                             AST *value, btshort options, boolean replace);
char * bt_postprocess_field (bt_macros *macros, bt_errors *errs,
                             AST *field, btshort options, boolean replace);
void   bt_postprocess_entry (bt_macros *macros, bt_errors *errs,
                             AST *entry, btshort options);

AST *       bt_next_entry (AST *entry_list, AST *prev_entry);
bt_metatype bt_entry_metatype (AST *entry);
char *      bt_entry_type (AST *entry);
char *      bt_entry_key (AST *entry);
AST *       bt_next_field (AST *entry, AST *prev, char **name);
AST *       bt_next_value (AST *head, AST *prev,
                           bt_nodetype *nodetype, char **text);


/* ----------------------------------------------------------------------
 * Names and lists
 */

typedef struct
{
   /*
    * `string' is the string that has been split; items[0] ...
    * items[num_items-1] are pointers into `string', or NULL for empty
    * substrings.  Note that `string' is actually a copy of the string
    * passed in to bt_split_list() with NULs inserted between substrings.
    */
   char *  string;
   int     num_items;
   char ** items;
} bt_stringlist;

typedef struct
{
   bt_stringlist * tokens;              /* flat list of all tokens in name */
   char ** parts[BT_MAX_NAMEPARTS];     /* each elt. is list of pointers */
                                        /* into `tokens->string' */
   int     part_len[BT_MAX_NAMEPARTS];  /* length in tokens */
} bt_name;

typedef struct
{
   /* These determine the order (and presence) of parts in the name. */
   int           num_parts;
   bt_namepart   parts[BT_MAX_NAMEPARTS];

   /*
    * These lists are always in the order of the bt_namepart enum -- *not*
    * dependent on the particular order of parts the user specified!
    * The strings are owned by the format structure.
    */
   char *        pre_part[BT_MAX_NAMEPARTS];
   char *        post_part[BT_MAX_NAMEPARTS];
   char *        pre_token[BT_MAX_NAMEPARTS];
   char *        post_token[BT_MAX_NAMEPARTS];
   boolean       abbrev[BT_MAX_NAMEPARTS];
   bt_joinmethod join_tokens[BT_MAX_NAMEPARTS];
   bt_joinmethod join_part[BT_MAX_NAMEPARTS];
} bt_name_format;

bt_stringlist * bt_split_list (bt_errors *errs, const char *string,
                               const char *delim, const char *filename,
                               int line, const char *description);
void            bt_free_list (bt_stringlist *list);
bt_name *       bt_split_name (bt_errors *errs, const char *name,
                               const char *filename, int line, int name_num);
void            bt_free_name (bt_name *name);

bt_name_format * bt_create_name_format (bt_errors *errs, const char *parts,
                                        boolean abbrev_first);
void   bt_free_name_format (bt_name_format *format);
void   bt_set_format_text (bt_name_format *format, bt_namepart part,
                           const char *pre_part, const char *post_part,
                           const char *pre_token, const char *post_token);
void   bt_set_format_options (bt_name_format *format, bt_namepart part,
                              boolean abbrev, bt_joinmethod join_tokens,
                              bt_joinmethod join_part);
char * bt_format_name (bt_errors *errs, bt_name *name,
                       bt_name_format *format);


/* ----------------------------------------------------------------------
 * String utilities (return newly allocated strings)
 */

char * bt_purify_string (const char *string, btshort options);
char * bt_change_case (bt_errors *errs, char transform, const char *string,
                       btshort options);


/* ----------------------------------------------------------------------
 * Memory: the library calls this when malloc() fails.  The default
 * handler aborts; a host (eg. Perl) should install one that croaks.
 */

void bt_set_oom_handler (void (*handler) (void));

/* Free a string (or other memory) returned by the library.  Use this
 * rather than free(): on some platforms (eg. Perl on Windows) the caller's
 * free() may be a different allocator from the library's. */
void bt_free (void *p);

/* Version of the Unicode database the character tables were built from */
const char * bt_unicode_version (void);

#endif /* BTPARSE_H */
