/* ------------------------------------------------------------------------
@NAME       : parser.c
@DESCRIPTION: A reentrant lexer and recursive-descent parser for the BibTeX
              data language.  This replaces the PCCTS-generated parser of
              the original btparse; it accepts the same language, builds
              the same AST and produces the same error messages, but keeps
              all of its state in a bt_parser object and reads its input
              through a callback (or from memory).

              The lexer has three modes, as before:

                START   between entries: looks for '@', skips whitespace
                        and %-comments, and counts any other "junk"
                ENTRY   inside an entry: names, numbers and punctuation
                STRING  inside a quoted ("...") or braced ({...}) string

              The grammar is:

                entry        : '@' NAME body
                body         : STRING                      (@comment only)
                             | ENTRY_OPEN contents ENTRY_CLOSE
                             | (empty)  (@comment not followed by a STRING:
                                         ignored, like BibTeX does)
                contents     : (NAME | NUMBER) [ ',' fields ]  (regular entry)
                             | fields                      (@string)
                             | value                       (@preamble)
                fields       : field { ',' fields } | (empty)
                field        : NAME '=' value
                value        : simple_value ( '#' simple_value )*
                simple_value : STRING | NUMBER | NAME

              Error recovery follows the original parser: an error in a
              field skips to the next ',' or end of entry; an error in a
              simple value skips to the next '#', ',' or end of entry;
              anything worse skips to the next '@' at top level.  In
              addition, a name token that starts with '@' inside an entry
              almost always means a missing closing brace, so during error
              recovery (and where a field name is expected) the parser
              backs up and restarts at that '@' rather than losing the
              following entry.
@COPYRIGHT  : Copyright (c) 1996-99 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse library.  This library is
              free software; you can redistribute it and/or modify it under
              the terms of the GNU Library General Public License as
              published by the Free Software Foundation; either version 2
              of the License, or (at your option) any later version.
-------------------------------------------------------------------------- */

#include <stdlib.h>
#include <string.h>
#include "bt_internal.h"

#define READ_CHUNK      65536
#define MAX_BAD_TEXT    200             /* bytes of a token quoted in errors */

typedef enum { M_START, M_ENTRY, M_STRING } lex_mode;

typedef enum
{
   S_TOPLEVEL,                  /* between entries */
   S_AFTER_AT,                  /* seen '@' */
   S_AFTER_TYPE,                /* seen '@name' (not "comment") */
   S_IN_COMMENT,                /* seen '@comment' */
   S_IN_ENTRY                   /* seen '@name{' or '@name(' */
} entry_state;

typedef enum
{
   T_EOF, T_AT, T_NAME, T_NUMBER, T_LBRACE, T_RBRACE, T_ENTRY_OPEN,
   T_ENTRY_CLOSE, T_EQUALS, T_HASH, T_COMMA, T_STRING, T_QUOTE
} token;

#define TOKSET(t) (1u << (t))

/* Is c (a byte, or -1 at end of input) one of the characters in set?
 * Unlike plain strchr() this never matches NUL. */
#define ISIN(set, c) ((c) > 0 && strchr (set, (c)) != NULL)

struct bt_parser
{
   /* input */
   bt_read_fn   read;
   void *       userdata;
   char *       buf;
   size_t       cap;
   size_t       keep;           /* start of bytes we must not discard */
   size_t       pos;
   size_t       end;
   long         base;           /* input offset of buf[0] */
   boolean      eof;
   boolean      read_error;
   unsigned     flags;
   char *       filename;
   int          line;
   bt_macros *  macros;

   /* lexical state */
   lex_mode     mode;
   entry_state  state;
   char         entry_opener;
   bt_metatype  metatype;
   long         junk_count;
   char         string_opener;
   int          brace_depth;
   int          paren_depth;
   int          string_start;
   boolean      apparent_runaway;
   int          bad_utf8_line;

   /* the lookahead token */
   boolean      have_tok;
   token        tok;
   bt_sbuf      text;
   int          tok_line;       /* line at end of token */
   int          tok_start_line;
   size_t       tok_pos;        /* buffer position of token start */

   /* parsing */
   bt_errors *  errs;
   boolean      bail;           /* abandon current entry (restarted at '@') */
   int          entries;        /* entries returned so far */
   int          attempts;       /* entries attempted so far */
};


/* ----------------------------------------------------------------------
 * Construction
 */

static bt_parser *
new_parser (const char *filename, unsigned flags)
{
   bt_parser * p = bt_xcalloc (1, sizeof (bt_parser));

   p->filename = bt_xstrdup (filename);
   p->flags = flags;
   p->line = 1;
   p->mode = M_START;
   p->state = S_TOPLEVEL;
   p->metatype = BTE_UNKNOWN;
   p->string_start = -1;
   bt_sbuf_init (&p->text);
   return p;
}

bt_parser *
bt_parser_new_reader (bt_read_fn read, void *userdata,
                      const char *filename, unsigned flags)
{
   bt_parser * p = new_parser (filename, flags);

   p->read = read;
   p->userdata = userdata;
   p->cap = READ_CHUNK;
   p->buf = bt_xmalloc (p->cap);
   return p;
}

bt_parser *
bt_parser_new_string (const char *text, size_t len, const char *filename,
                      int line, unsigned flags)
{
   bt_parser * p = new_parser (filename, flags);

   p->buf = bt_xstrndup (text, len);
   p->cap = len + 1;
   p->end = len;
   p->eof = TRUE;
   p->line = line > 0 ? line : 1;
   return p;
}

void
bt_parser_free (bt_parser *p)
{
   if (!p)
      return;
   free (p->buf);
   free (p->filename);
   bt_sbuf_free (&p->text);
   free (p);
}

void
bt_parser_set_macros (bt_parser *p, bt_macros *macros)
{
   p->macros = macros;
}

bt_macros *
bt_parser_macros (bt_parser *p)
{
   return p->macros;
}

const char *
bt_parser_filename (bt_parser *p)
{
   return p->filename;
}

boolean
bt_parser_read_error (bt_parser *p)
{
   return p->read_error;
}


boolean
bt_parser_eof (bt_parser *p)
{
   if (p->have_tok && p->tok != T_EOF)
      return FALSE;
   return p->eof && p->pos >= p->end;
}


/* ----------------------------------------------------------------------
 * Input buffer
 */

static void
fill (bt_parser *p)
{
   long n;

   if (p->eof)
      return;

   /* discard what we no longer need, then make room */
   if (p->keep > 0)
   {
      memmove (p->buf, p->buf + p->keep, p->end - p->keep);
      p->pos -= p->keep;
      p->end -= p->keep;
      p->tok_pos -= p->keep < p->tok_pos ? p->keep : p->tok_pos;
      p->base += (long) p->keep;
      p->keep = 0;
   }
   if (p->cap - p->end < READ_CHUNK / 4)
   {
      p->cap *= 2;
      p->buf = bt_xrealloc (p->buf, p->cap);
   }

   n = p->read (p->userdata, p->buf + p->end, p->cap - p->end);
   if (n < 0)
   {
      p->read_error = TRUE;
      p->eof = TRUE;
   }
   else if (n == 0)
      p->eof = TRUE;
   else
      p->end += (size_t) n;
}

/* The byte k positions ahead, or -1 at end of input */
static int
peek (bt_parser *p, size_t k)
{
   while (p->pos + k >= p->end && !p->eof)
      fill (p);
   if (p->pos + k >= p->end)
      return -1;
   return (unsigned char) p->buf[p->pos + k];
}

#define CUR(p) peek (p, 0)


/* ----------------------------------------------------------------------
 * Lexical errors
 */

static void
lex_report (bt_parser *p, bt_errclass errclass, const char *fmt, ...)
#ifdef __GNUC__
   __attribute__ ((format (printf, 3, 4)))
#endif
   ;

static void
lex_report (bt_parser *p, bt_errclass errclass, const char *fmt, ...)
{
   va_list ap;

   va_start (ap, fmt);
   bt_vreport (p->errs, errclass, p->filename, p->line, NULL, -1, fmt, ap);
   va_end (ap);
}

#define lexical_warning(p, ...) lex_report (p, BTERR_LEXWARN, __VA_ARGS__)
#define lexical_error(p, ...)   lex_report (p, BTERR_LEXERR, __VA_ARGS__)


/* Copy one character from the input to out (if out is non-NULL),
 * validating UTF-8 if asked to; returns the number of bytes consumed. */
static size_t
take_char (bt_parser *p, bt_sbuf *out)
{
   int    c = CUR (p);
   size_t avail, len;
   long   cp;

   if (c < 0)
      return 0;
   if (c < 0x80 && c != 0)
   {
      if (out)
         bt_sbuf_putc (out, (char) c);
      p->pos++;
      return 1;
   }

   peek (p, 3);                         /* make sure a whole char is here */
   avail = p->end - p->pos;
   len = bt_utf8_decode (p->buf + p->pos, avail, &cp);
   if (cp < 0 || c == 0)
      len = 1;

   if ((cp < 0 || c == 0) && (p->flags & BTP_UTF8))
   {
      if (out)
         bt_sbuf_puts (out, BT_REPLACEMENT_CHAR);
      if (p->bad_utf8_line != p->line)
      {
         lexical_warning (p, "invalid UTF-8 byte sequence "
                          "(replaced with U+FFFD)");
         p->bad_utf8_line = p->line;
      }
   }
   else if (out)
      bt_sbuf_putn (out, p->buf + p->pos, len);

   p->pos += len;
   return len;
}


/* ----------------------------------------------------------------------
 * Lexer state and actions
 */

static void
initialize_lexer_state (bt_parser *p)
{
   p->mode = M_START;
   p->state = S_TOPLEVEL;
   p->entry_opener = 0;
   p->metatype = BTE_UNKNOWN;
   p->junk_count = 0;
}

/* Characters allowed in names (entry types, keys, field and macro names)
 * in ENTRY mode.  This matches the scanner tables of the original
 * btparse, which allowed all printable ASCII except the BibTeX
 * punctuation, plus all non-ASCII bytes (so UTF-8 names work). */
static boolean
is_name_char (int c)
{
   if (c >= 0x80)
      return TRUE;
   if (c <= 32 || c == 127)
      return FALSE;
   return strchr ("\"#%'(),={}\\", c) == NULL;
}

static boolean
is_invalid_entry_char (int c)
{
   return (c >= 0 && c < 32 && c != '\t' && c != '\n' && c != '\r')
      || c == '\'' || c == '\\' || c == 127;
}

/* Set the metatype when the entry type has been seen */
static void
name_action (bt_parser *p)
{
   if (p->state == S_AFTER_AT)
   {
      const char * etype = p->text.s;

      p->state = S_AFTER_TYPE;
      if (bt_ascii_strcasecmp (etype, "comment") == 0)
      {
         p->metatype = BTE_COMMENT;
         p->state = S_IN_COMMENT;
      }
      else if (bt_ascii_strcasecmp (etype, "preamble") == 0)
         p->metatype = BTE_PREAMBLE;
      else if (bt_ascii_strcasecmp (etype, "string") == 0)
         p->metatype = BTE_MACRODEF;
      else
         p->metatype = BTE_REGULAR;
   }
}

/* Called at each newline in a string: if what follows the newline looks
 * like the start of a field ("name =") the string is probably a runaway
 * (eg. a missing closing quote), so warn -- once per string.  `chunk' is
 * the newline plus the text up to the next brace, parenthesis, quote,
 * backslash or newline, already converted to spaces. */
static void
check_runaway_string (bt_parser *p, const char *chunk, size_t len)
{
   static const char alpha_chars[] = "abcdefghijklmnopqrstuvwxyz";
   static const char name_chars[] = "abcdefghijklmnopqrstuvwxyz0123456789:+/'.-";
   enum { none, entry, field, giveup } guess = none;
   size_t i = 1;

   if (p->apparent_runaway)
      return;

#define IN(set, c) ((c) != 0 && strchr (set, BT_TOLOWER (c)) != NULL)

   while (i < len && chunk[i] == ' ') i++;
   if (i < len && chunk[i] == '@')
   {
      i++;
      while (i < len && chunk[i] == ' ') i++;
      guess = entry;
   }

   if (i < len && IN (alpha_chars, chunk[i]))
   {
      while (i < len && IN (name_chars, chunk[i]))
         i++;
      while (i < len && chunk[i] == ' ') i++;
      if (i == len)
         guess = giveup;
      else if (guess == entry)
      {
         if (chunk[i] != '{' && chunk[i] != '(')
            guess = giveup;
      }
      else
         guess = (chunk[i] == '=') ? field : giveup;
   }
   else
      guess = giveup;
#undef IN

   if (guess != giveup)
   {
      lexical_warning (p, "possible runaway string started at line %d",
                       p->string_start);
      p->apparent_runaway = TRUE;
   }
}

static void
end_string (bt_parser *p)
{
   if (p->brace_depth > 0)
   {
      lexical_error (p, "unbalanced braces: too many {'s");
      p->brace_depth = 0;
   }
   p->string_opener = 0;
   p->string_start = -1;
   p->tok = T_STRING;

   if (p->state == S_IN_COMMENT)
   {
      /* convert @comment(...) to the standard {...} delimiters */
      if (p->text.s[0] == '(')
      {
         p->text.s[0] = '{';
         p->text.s[p->text.len - 1] = '}';
      }
      p->state = S_TOPLEVEL;
      p->mode = M_START;
   }
   else
      p->mode = M_ENTRY;
}

/* Lex the body of a string (the opening delimiter has been consumed and
 * put in p->text).  Returns FALSE if end of input came first. */
static boolean
lex_string (bt_parser *p)
{
   for (;;)
   {
      int c = CUR (p);

      switch (c)
      {
         case -1:
            return FALSE;

         case '\n':
         {
            /* newline plus following text up to a delimiter or
             * backslash, with all whitespace turned into spaces */
            size_t chunk = p->text.len;

            p->pos++;
            p->line++;
            bt_sbuf_putc (&p->text, ' ');
            while ((c = CUR (p)) >= 0 && !ISIN ("\n{}()\"\\", c))
            {
               if (c >= 9 && c <= 13)
               {
                  bt_sbuf_putc (&p->text, ' ');
                  p->pos++;
               }
               else
                  take_char (p, &p->text);
            }
            check_runaway_string (p, p->text.s + chunk, p->text.len - chunk);
            break;
         }

         case '{':
            p->brace_depth++;
            bt_sbuf_putc (&p->text, '{');
            p->pos++;
            break;

         case '}':
            p->brace_depth--;
            bt_sbuf_putc (&p->text, '}');
            p->pos++;
            if (p->string_opener == '{' && p->brace_depth == 0)
            {
               end_string (p);
               return TRUE;
            }
            if (p->brace_depth < 0)
            {
               lexical_error (p, "unbalanced braces: too many }'s");
               p->brace_depth = 0;
            }
            break;

         case '(':
            p->paren_depth++;
            bt_sbuf_putc (&p->text, '(');
            p->pos++;
            break;

         case ')':
            p->paren_depth--;
            bt_sbuf_putc (&p->text, ')');
            p->pos++;
            if (p->string_opener == '(' && p->paren_depth == 0)
            {
               end_string (p);
               return TRUE;
            }
            break;

         case '"':
            bt_sbuf_putc (&p->text, '"');
            p->pos++;
            if (p->string_opener == '"' && p->brace_depth == 0)
            {
               end_string (p);
               return TRUE;
            }
            break;

         case '\r':
         case '\t':
         {
            /* A lone tab/CR before a delimiter becomes a space; otherwise
             * it is just part of the text (as in the original lexer). */
            int next = peek (p, 1);
            if (next < 0 || ISIN ("\n{}()\"", next))
            {
               bt_sbuf_putc (&p->text, ' ');
               p->pos++;
               break;
            }
         }
         /* FALLTHROUGH */
         default:
            while ((c = CUR (p)) >= 0 && !ISIN ("\n{}()\"", c))
               take_char (p, &p->text);
            break;
      }
   }
}

/* Start a string at the current character (one of { " ( ). Returns the
 * token: T_STRING, T_QUOTE (for the @comment"..." error), or T_EOF. */
static token
start_string (bt_parser *p, char opener)
{
   p->string_opener = opener;
   p->brace_depth = (opener == '{');
   p->paren_depth = (opener == '(');
   p->string_start = p->line;
   p->apparent_runaway = FALSE;
   bt_sbuf_putc (&p->text, opener);
   p->pos++;

   if (opener == '"' && p->state == S_IN_COMMENT)
   {
      lexical_error (p, "comment entries must be delimited by either "
                     "braces or parentheses");
      p->state = S_TOPLEVEL;
      p->mode = M_START;
      return T_QUOTE;
   }
   if (p->state != S_IN_ENTRY && p->state != S_IN_COMMENT)
      lexical_warning (p, "start of string seen at weird place");

   p->mode = M_STRING;
   if (!lex_string (p))
   {
      bt_sbuf_clear (&p->text);
      return T_EOF;
   }
   return T_STRING;
}

/* Skip a %-comment if there is a newline to end it; returns FALSE (and
 * consumes nothing) if not. */
static boolean
skip_comment (bt_parser *p)
{
   size_t k = 1;
   int    c;

   while ((c = peek (p, k)) >= 0 && c != '\n')
      k++;
   if (c < 0)
      return FALSE;
   p->pos += k + 1;
   p->line++;
   return TRUE;
}

/* Lex the next token in START mode */
static token
lex_start (bt_parser *p)
{
   /* skip a byte order mark at the very start of the input */
   if (p->base + (long) p->pos == 0 && CUR (p) == 0xEF
       && peek (p, 1) == 0xBB && peek (p, 2) == 0xBF)
      p->pos += 3;

   for (;;)
   {
      int c;

      p->tok_pos = p->pos;
      p->keep = p->pos;
      c = CUR (p);

      switch (c)
      {
         case -1:
            return T_EOF;
         case '@':
            p->pos++;
            bt_sbuf_putc (&p->text, '@');
            if (p->state == S_TOPLEVEL)
            {
               p->state = S_AFTER_AT;
               p->mode = M_ENTRY;
               if (p->junk_count > 0)
               {
                  lexical_warning (p, "%ld characters of junk seen at "
                                   "toplevel", p->junk_count);
                  p->junk_count = 0;
               }
            }
            else
               lexical_warning (p, "\"@\" in strange place -- should get "
                                "syntax error");
            return T_AT;
         case '\n':
            p->pos++;
            p->line++;
            break;
         case ' ':
         case '\r':
         case '\t':
            p->pos++;
            break;
         case '%':
            if (skip_comment (p))
               break;
            /* FALLTHROUGH: unterminated comment at end of input is junk */
         default:
            while ((c = CUR (p)) >= 0 && !ISIN ("@\n \r\t", c))
            {
               take_char (p, NULL);
               p->junk_count++;
            }
            break;
      }
   }
}

/* Lex the next token in ENTRY mode */
static token
lex_entry (bt_parser *p)
{
   for (;;)
   {
      int c;

      p->tok_pos = p->pos;
      p->keep = p->pos;
      p->tok_start_line = p->line;
      c = CUR (p);

      if (c == -1)
         return T_EOF;
      if (c == '\n')
      {
         p->pos++;
         p->line++;
         continue;
      }
      if (c == ' ' || c == '\r' || c == '\t')
      {
         p->pos++;
         continue;
      }
      if (c == '%')
      {
         if (!skip_comment (p))         /* comment runs to end of input */
            p->pos = p->end;
         continue;
      }

      if (BT_IS_DIGIT (c) || is_name_char (c))
      {
         boolean all_digits = TRUE;

         while ((c = CUR (p)) >= 0 && (BT_IS_DIGIT (c) || is_name_char (c)))
         {
            if (!BT_IS_DIGIT (c))
               all_digits = FALSE;
            take_char (p, &p->text);
         }
         if (all_digits)
            return T_NUMBER;
         name_action (p);
         return T_NAME;
      }

      switch (c)
      {
         case '{':
            if (p->state == S_IN_ENTRY || p->state == S_IN_COMMENT)
               return start_string (p, '{');
            p->pos++;
            bt_sbuf_putc (&p->text, '{');
            if (p->state == S_AFTER_TYPE)
            {
               p->state = S_IN_ENTRY;
               p->entry_opener = '{';
               return T_ENTRY_OPEN;
            }
            lexical_warning (p, "\"{\" in strange place -- should get a "
                             "syntax error");
            return T_LBRACE;

         case '}':
            p->pos++;
            bt_sbuf_putc (&p->text, '}');
            if (p->state == S_IN_ENTRY)
            {
               if (p->entry_opener == '(')
                  lexical_warning (p, "entry started with \"(\", but ends "
                                   "with \"}\"");
               initialize_lexer_state (p);
               return T_ENTRY_CLOSE;
            }
            lexical_warning (p, "\"}\" in strange place -- should get a "
                             "syntax error");
            return T_RBRACE;

         case '(':
            if (p->state == S_IN_COMMENT)
               return start_string (p, '(');
            p->pos++;
            bt_sbuf_putc (&p->text, '(');
            if (p->state == S_AFTER_TYPE)
            {
               p->state = S_IN_ENTRY;
               p->entry_opener = '(';
            }
            else
               lexical_warning (p, "\"(\" in strange place -- should get a "
                                "syntax error");
            return T_ENTRY_OPEN;

         case ')':
            p->pos++;
            bt_sbuf_putc (&p->text, ')');
            if (p->state == S_IN_ENTRY)
            {
               if (p->entry_opener == '{')
                  lexical_warning (p, "entry started with \"{\", but ends "
                                   "with \")\"");
               initialize_lexer_state (p);
            }
            else
               lexical_warning (p, "\")\" in strange place -- should get a "
                                "syntax error");
            return T_ENTRY_CLOSE;

         case '=':
            p->pos++;
            bt_sbuf_putc (&p->text, '=');
            return T_EQUALS;
         case '#':
            p->pos++;
            bt_sbuf_putc (&p->text, '#');
            return T_HASH;
         case ',':
            p->pos++;
            bt_sbuf_putc (&p->text, ',');
            return T_COMMA;
         case '"':
            return start_string (p, '"');
      }

      /* anything else is not a valid token here: report and skip it */
      if (is_invalid_entry_char (c))
      {
         if (c < 32 || c == 127)
            lexical_warning (p, "invalid token (character \\x%02X)", c);
         else
            lexical_warning (p, "invalid token (text was '%c')", c);
      }
      p->pos++;
   }
}

/* Read the next token into the lookahead */
static void
lex (bt_parser *p)
{
   bt_sbuf_clear (&p->text);
   p->tok_start_line = p->line;
   if (p->mode == M_START)
      p->tok = lex_start (p);
   else
      p->tok = lex_entry (p);
   p->tok_line = p->line;
   p->have_tok = TRUE;
}

#define consume(p) lex (p)


/* ----------------------------------------------------------------------
 * Syntax errors
 */

static const char *
token_name (token t)
{
   switch (t)
   {
      case T_AT:          return "\"@\"";
      case T_NAME:        return "name (entry type, key, field, or macro name)";
      case T_NUMBER:      return "number";
      case T_LBRACE:      return "left brace (\"{\")";
      case T_RBRACE:      return "right brace (\"}\")";
      case T_ENTRY_OPEN:  return "start of entry (\"{\" or \"(\")";
      case T_ENTRY_CLOSE: return "end of entry (\"}\" or \")\")";
      case T_EQUALS:      return "\"=\"";
      case T_HASH:        return "\"#\"";
      case T_COMMA:       return "\",\"";
      case T_STRING:      return "quoted string ({...} or \"...\")";
      default:            return "token";
   }
}

static void
syntax_error (bt_parser *p, const char *fmt, ...)
#ifdef __GNUC__
   __attribute__ ((format (printf, 2, 3)))
#endif
   ;

static void
syntax_error (bt_parser *p, const char *fmt, ...)
{
   va_list ap;

   va_start (ap, fmt);
   bt_vreport (p->errs, BTERR_SYNTAX, p->filename, p->line, NULL, -1, fmt, ap);
   va_end (ap);
}

/* Report "found X, expected Y" for the current token.  `expected' lists
 * the acceptable tokens (in the order they appear in messages). */
static void
expected (bt_parser *p, const token *expect, int nexpect, const char *suffix)
{
   bt_sbuf msg;
   int     i;

   bt_sbuf_init (&msg);
   if (p->tok == T_EOF)
      bt_sbuf_puts (&msg, "at end of input");
   else
   {
      size_t n = p->text.len;
      bt_sbuf_puts (&msg, "found \"");
      if (n > MAX_BAD_TEXT)
      {
         n = MAX_BAD_TEXT;
         while (n > 0 && (p->text.s[n] & 0xC0) == 0x80)
            n--;                        /* don't split a UTF-8 character */
         bt_sbuf_putn (&msg, p->text.s, n);
         bt_sbuf_puts (&msg, "...");
      }
      else
         bt_sbuf_putn (&msg, p->text.s, n);
      bt_sbuf_puts (&msg, "\"");
   }

   bt_sbuf_puts (&msg, nexpect > 1 ? ", expected one of: " : ", expected ");
   for (i = 0; i < nexpect; i++)
   {
      bt_sbuf_puts (&msg, token_name (expect[i]));
      if (i < nexpect - 2)
         bt_sbuf_puts (&msg, ", ");
      else if (i == nexpect - 2)
         bt_sbuf_puts (&msg, " or ");
   }
   if (suffix)
      bt_sbuf_puts (&msg, suffix);

   syntax_error (p, "%s", msg.s);
   bt_sbuf_free (&msg);
}

#define EXPECT1(p, t, suffix) do {                                       \
      token _e[1] = { t };                                              \
      expected (p, _e, 1, suffix);                                      \
   } while (0)

static const token body_set[] = { T_ENTRY_OPEN, T_STRING };
static const token contents_set[] = { T_NUMBER, T_NAME, T_ENTRY_CLOSE, T_STRING };
static const token fields_set[] = { T_NAME, T_ENTRY_CLOSE };
static const token value_set[] = { T_NUMBER, T_NAME, T_STRING };

#define NELEM(a) ((int) (sizeof (a) / sizeof ((a)[0])))

static const char skipping[] = " (skipping to next \"@\")";


/* ----------------------------------------------------------------------
 * Error recovery
 */

static boolean
at_name (bt_parser *p)
{
   return p->tok == T_NAME && p->text.s[0] == '@';
}

/* Back up to the '@' at the start of the current (name) token and
 * restart lexing there at top level, abandoning the current entry. */
static void
restart_at (bt_parser *p)
{
   p->pos = p->tok_pos;
   p->line = p->tok_start_line;
   initialize_lexer_state (p);
   lex (p);                             /* the '@' */
   p->bail = TRUE;
}

/* A name starting with '@' where the parser would accept a name almost
 * certainly means the entry was not closed: report it and restart. */
static boolean
check_at (bt_parser *p)
{
   if (!at_name (p))
      return FALSE;
   EXPECT1 (p, T_ENTRY_CLOSE, skipping);
   restart_at (p);
   return TRUE;
}

/* Skip tokens until one in `set' (or end of input) */
static void
resync (bt_parser *p, unsigned set)
{
   for (;;)
   {
      if (at_name (p))
      {
         restart_at (p);
         return;
      }
      if ((set & TOKSET (p->tok)) || p->tok == T_EOF)
         return;
      consume (p);
   }
}


/* ----------------------------------------------------------------------
 * The parser proper
 */

static void
append_child (AST *parent, AST *child)
{
   AST ** link = &parent->down;
   while (*link)
      link = &(*link)->right;
   *link = child;
}

static AST *
token_node (bt_parser *p, bt_nodetype nodetype)
{
   const char * text = p->text.s ? p->text.s : "";
   size_t       len = p->text.len;

   if (nodetype == BTAST_STRING && len >= 2)   /* strip the delimiters */
   {
      text++;
      len -= 2;
   }
   return bt_new_ast (nodetype, text, len, p->filename, p->tok_line,
                      p->base + (long) p->tok_pos);
}

static void
simple_value (bt_parser *p, AST *parent)
{
   switch (p->tok)
   {
      case T_STRING:
         append_child (parent, token_node (p, BTAST_STRING));
         consume (p);
         break;
      case T_NUMBER:
         append_child (parent, token_node (p, BTAST_NUMBER));
         consume (p);
         break;
      case T_NAME:
         append_child (parent, token_node (p, BTAST_MACRO));
         consume (p);
         break;
      default:
         expected (p, value_set, NELEM (value_set), NULL);
         resync (p, TOKSET (T_ENTRY_CLOSE) | TOKSET (T_HASH) | TOKSET (T_COMMA));
   }
}

static void
value (bt_parser *p, AST *parent)
{
   simple_value (p, parent);
   while (!p->bail && p->tok == T_HASH)
   {
      consume (p);
      simple_value (p, parent);
   }
}

static void
field (bt_parser *p, AST *entry)
{
   AST * f = token_node (p, BTAST_FIELD);

   append_child (entry, f);
   if (BT_IS_DIGIT (f->text[0]))
      syntax_error (p, "invalid field name \"%s\": cannot start with digit",
                    f->text);
   consume (p);

   if (p->tok != T_EQUALS)
   {
      EXPECT1 (p, T_EQUALS, NULL);
      resync (p, TOKSET (T_ENTRY_CLOSE) | TOKSET (T_COMMA));
      return;
   }
   consume (p);
   value (p, f);
}

static void
fields (bt_parser *p, AST *entry)
{
   for (;;)
   {
      if (p->tok == T_NAME)
      {
         if (check_at (p))
            return;
         field (p, entry);
         if (p->bail || p->tok != T_COMMA)
            return;
         consume (p);
         continue;
      }
      if (p->tok == T_ENTRY_CLOSE)
         return;
      expected (p, fields_set, NELEM (fields_set), NULL);
      resync (p, TOKSET (T_ENTRY_CLOSE));
      return;
   }
}

static void
contents (bt_parser *p, AST *entry)
{
   switch (entry->metatype)
   {
      case BTE_REGULAR:
         if (p->tok == T_NAME || p->tok == T_NUMBER)
         {
            append_child (entry, token_node (p, BTAST_KEY));
            consume (p);
            if (p->tok == T_ENTRY_CLOSE)  /* no fields, eg. @misc{key}, */
               return;                    /* which BibTeX accepts */
            if (p->tok != T_COMMA)
            {
               EXPECT1 (p, T_COMMA, NULL);
               resync (p, TOKSET (T_ENTRY_CLOSE));
               return;
            }
            consume (p);
            fields (p, entry);
            return;
         }
         break;
      case BTE_MACRODEF:
         if (p->tok == T_NAME || p->tok == T_ENTRY_CLOSE)
         {
            fields (p, entry);
            return;
         }
         break;
      case BTE_PREAMBLE:
         if (p->tok == T_NUMBER || p->tok == T_NAME || p->tok == T_STRING)
         {
            value (p, entry);
            return;
         }
         break;
      default:
         break;
   }
   expected (p, contents_set, NELEM (contents_set), NULL);
   resync (p, TOKSET (T_ENTRY_CLOSE));
}

static void
body (bt_parser *p, AST *entry)
{
   if (p->tok == T_STRING && entry->metatype == BTE_COMMENT)
   {
      append_child (entry, token_node (p, BTAST_STRING));
      p->have_tok = FALSE;              /* lexer is back at top level */
      return;
   }

   if (p->tok == T_ENTRY_OPEN && entry->metatype != BTE_COMMENT)
   {
      consume (p);
      contents (p, entry);
      if (p->bail)
         return;
      if (p->tok == T_ENTRY_CLOSE)
      {
         p->have_tok = FALSE;           /* lex the next one lazily */
         return;
      }
      if (check_at (p))
         return;
      EXPECT1 (p, T_ENTRY_CLOSE, skipping);
      initialize_lexer_state (p);       /* skip the rest at top level */
      resync (p, TOKSET (T_AT));
      return;
   }

   if (p->tok == T_STRING)              /* "..." after a regular entry type */
      EXPECT1 (p, T_ENTRY_OPEN, NULL);
   else if (!check_at (p))
      expected (p, body_set, NELEM (body_set), NULL);
   if (!p->bail)
      resync (p, TOKSET (T_AT));
}

typedef enum { PARSE_EOF, PARSE_ENTRY, PARSE_FAILED, PARSE_SKIPPED } parse_result;

/* BibTeX ignores the word "@comment" itself, so when it is not followed
 * by a braced or parenthesised comment, what follows it is ordinary text
 * between entries: back up to the current token and skip to the next '@'
 * at top level (without the junk warning; BibTeX doesn't warn either). */
static void
skip_bare_comment (bt_parser *p)
{
   int c;

   p->pos = p->tok_pos;
   p->line = p->tok_start_line;
   while ((c = CUR (p)) >= 0 && c != '@')
   {
      if (c == '\n')
      {
         p->pos++;
         p->line++;
      }
      else
         take_char (p, NULL);
   }
   initialize_lexer_state (p);
   bt_sbuf_clear (&p->text);
   p->have_tok = FALSE;
}

static parse_result
parse_one (bt_parser *p, AST **result)
{
   AST * entry;

   *result = NULL;
   p->bail = FALSE;
   if (!p->have_tok)
      lex (p);
   if (p->tok == T_EOF)
      return PARSE_EOF;

   if (p->tok != T_AT)                  /* can't happen: START mode only */
   {                                    /* produces '@' and EOF */
      EXPECT1 (p, T_AT, NULL);
      initialize_lexer_state (p);
      resync (p, TOKSET (T_AT));
      return PARSE_FAILED;
   }

   p->attempts++;
   consume (p);
   if (p->tok != T_NAME)
   {
      EXPECT1 (p, T_NAME, NULL);
      resync (p, TOKSET (T_AT));
      return PARSE_FAILED;
   }

   entry = token_node (p, BTAST_ENTRY);
   entry->metatype = p->metatype;
   consume (p);
   /* A bare @comment is one whose next token doesn't start a braced,
    * parenthesised or quoted comment ("..." is reported by the lexer).
    * An unterminated comment comes back as end of input, but starts with
    * its delimiter, and is left to body() to report. */
   if (entry->metatype == BTE_COMMENT && p->tok != T_STRING
       && p->tok != T_QUOTE
       && !(p->tok_pos < p->end && ISIN ("{(\"", p->buf[p->tok_pos])))
   {
      bt_free_ast (entry);
      skip_bare_comment (p);
      return PARSE_SKIPPED;
   }
   body (p, entry);
   *result = entry;
   return PARSE_ENTRY;
}

static boolean
serious_since (const bt_errors *errs, const int *before)
{
   int i;

   for (i = 0; i < BT_NUM_ERRCLASSES; i++)
   {
      if (i == BTERR_NOTIFY || i == BTERR_CONTENT || i == BTERR_LEXWARN)
         continue;
      if (errs->counts[i] != before[i])
         return TRUE;
   }
   return FALSE;
}

AST *
bt_parse_entry (bt_parser *p, bt_errors *errs, btshort options,
                boolean *status)
{
   bt_errors local;

   if (errs == NULL)
   {
      bt_errors_init (&local);
      errs = &local;
   }
   p->errs = errs;
   if (status) *status = TRUE;

   for (;;)
   {
      int          before[BT_NUM_ERRCLASSES];
      AST *        entry;
      parse_result r;

      memcpy (before, errs->counts, sizeof (before));
      r = parse_one (p, &entry);

      if (r == PARSE_ENTRY)
      {
         if (! (options & BTO_NOPOSTPROCESS))
            bt_postprocess_entry (p->macros, errs, entry, options);
         if (status) *status = !serious_since (errs, before);
         p->entries++;
         p->errs = NULL;
         if (errs == &local)
            bt_errors_clear (&local);
         return entry;
      }

      if (r == PARSE_EOF)
      {
         if (p->read_error)
            bt_report (errs, BTERR_LEXERR, p->filename, p->line, NULL, -1,
                       "error reading input");
         if (p->entries == 0 && p->attempts == 0)
         {
            EXPECT1 (p, T_AT, NULL);
            if (status) *status = FALSE;
            p->attempts++;              /* only complain once */
         }
         p->errs = NULL;
         if (errs == &local)
            bt_errors_clear (&local);
         return NULL;
      }

      if (r == PARSE_SKIPPED)           /* a bare @comment: not an error */
         continue;

      /* PARSE_FAILED: no entry was started; try the next one */
      if (status) *status = FALSE;
   }
}
