/* ------------------------------------------------------------------------
@NAME       : string_util.c
@DESCRIPTION: Various string-processing utility functions:
                bt_purify_string()
                bt_change_case()

              Both follow BibTeX's rules (purify$ and change.case$),
              including its treatment of "special characters" -- a brace
              group at depth 0 that starts with a backslash, eg. {\'e}.
              TeX control sequences are only ever ASCII letters; ordinary
              text may be any Unicode, and is classified and case-mapped
              character by character (never byte by byte).  Both functions
              return a new string, since Unicode case mapping can change
              the length of a string.
@CREATED    : 1997/10/19, Greg Ward
-------------------------------------------------------------------------- */

#include <stdlib.h>
#include <string.h>
#include "bt_internal.h"

/*
 * LaTeX's "foreign letter" control sequences, and their upper- and
 * lowercase forms (Kopka and Daly, *A Guide to LaTeX 2e*, section 2.5.6).
 */
typedef enum
{
   L_OTHER,                             /* not a "foreign" letter */
   L_OSLASH_L,                          /* Eastern European {\o} */
   L_OSLASH_U,
   L_LSLASH_L,                          /* {\l} */
   L_LSLASH_U,
   L_OELIG_L,                           /* Latin {\oe} ligature */
   L_OELIG_U,
   L_AELIG_L,                           /* {\ae} ligature */
   L_AELIG_U,
   L_SSHARP_L,                          /* German "sharp s" {\ss} */
   L_SSHARP_U,
   L_ACIRCLE_L,                         /* Nordic {\aa} */
   L_ACIRCLE_U,
   L_INODOT_L,                          /* undotted i: {\i} */
   L_JNODOT_L                           /* {\j} */
} bt_letter;

static const char * uc_version[] =
{
   NULL, "\\O", "\\O", "\\L", "\\L", "\\OE", "\\OE", "\\AE", "\\AE",
   "SS",                                /* L_SSHARP_L -- for LaTeX 2.09 */
   "\\SS", "\\AA", "\\AA", "I", "J"
};

static const char * lc_version[] =
{
   NULL, "\\o", "\\o", "\\l", "\\l", "\\oe", "\\oe", "\\ae", "\\ae",
   "\\ss", "\\ss", "\\aa", "\\aa", "\\i", "\\j"
};

/* Is str[start..stop) one of the foreign letter control sequences? */
static boolean
foreign_letter (const char *str, int start, int stop, bt_letter *letter)
{
   char c1 = str[start];
   char c2 = (stop - start > 1) ? str[start + 1] : 0;

   *letter = L_OTHER;
   switch (stop - start)
   {
      case 1:
         switch (c1)
         {
            case 'o': *letter = L_OSLASH_L; break;
            case 'O': *letter = L_OSLASH_U; break;
            case 'l': *letter = L_LSLASH_L; break;
            case 'L': *letter = L_LSLASH_L; break;
            case 'i': *letter = L_INODOT_L; break;
            case 'j': *letter = L_JNODOT_L; break;
         }
         break;
      case 2:
         if (c1 == 'o' && c2 == 'e') *letter = L_OELIG_L;
         else if (c1 == 'O' && c2 == 'E') *letter = L_OELIG_U;
         else if (c1 == 'a' && c2 == 'e') *letter = L_AELIG_L;
         else if (c1 == 'A' && c2 == 'E') *letter = L_AELIG_U;
         else if (c1 == 'a' && c2 == 'a') *letter = L_ACIRCLE_L;
         else if (c1 == 'A' && c2 == 'A') *letter = L_ACIRCLE_U;
         else if (c1 == 's' && c2 == 's') *letter = L_SSHARP_L;
         else if (c1 == 'S' && c2 == 'S') *letter = L_SSHARP_U;
         break;
   }
   return *letter != L_OTHER;
}

/* Length of the character at s, or 1 at end of string */
static size_t
charlen (const char *s)
{
   size_t n = bt_utf8_charlen (s);
   return n ? n : 1;
}


/* ------------------------------------------------------------------------
@NAME       : purify_special_char()
@DESCRIPTION: "Purifies" a BibTeX special character.  On input, *src
              points to the opening brace of a special character.  Skips
              the opening brace and backslash; if the control sequence is
              a foreign letter it is copied, otherwise it is skipped.  Text
              after the control sequence is copied if it consists of
              letters (and combining marks), and skipped otherwise.  On
              return *src points to the closing brace.
-------------------------------------------------------------------------- */
static void
purify_special_char (const char *str, size_t *src, bt_sbuf *out)
{
   int       depth = 1;
   size_t    peek;
   bt_letter letter;

   *src += 2;                           /* jump to start of control sequence */
   peek = *src;                         /* scan to end of control sequence */
   while (BT_IS_ALPHA (str[peek]))
      peek++;
   if (peek == *src && str[peek])       /* single-char, non-alpha control */
      peek += charlen (str + peek);     /* sequence (eg. {\'e}) */

   if (foreign_letter (str, (int) *src, (int) peek, &letter))
   {
      bt_sbuf_putc (out, str[(*src)++]);           /* copy first char */
      if (*src < peek)                             /* and second, */
      {                                            /* downcased */
         char c = str[(*src)++];
         bt_sbuf_putc (out, BT_TOLOWER (c));
      }
   }
   else
      *src = peek;                      /* skip the control sequence */

   while (str[*src])
   {
      switch (str[*src])
      {
         case '{':
            depth++;
            (*src)++;
            break;
         case '}':
            depth--;
            if (depth == 0)
               return;                  /* done with special char */
            (*src)++;
            break;
         default:
         {
            size_t n = charlen (str + *src);
            if (bt_uni_isalpha (str + *src) || bt_uni_ismark (str + *src))
               bt_sbuf_putn (out, str + *src, n);
            *src += n;
         }
      }
   }
   /* Unbalanced braces: no warning, as BibTeX doesn't warn here either
    * (and the lexer will already have complained). */
}


/* ------------------------------------------------------------------------
@NAME       : bt_purify_string()
@DESCRIPTION: "Purifies" a BibTeX string: alphanumeric characters (and
              combining marks) are copied, hyphens and ties become spaces,
              spaces are copied, and everything else is skipped.  Special
              characters are handled by purify_special_char().
-------------------------------------------------------------------------- */
char *
bt_purify_string (const char *string, btshort options)
{
   size_t  src = 0;
   int     depth = 0;
   bt_sbuf out;

   (void) options;
   bt_sbuf_init (&out);
   bt_sbuf_grow (&out, strlen (string));

   while (string[src] != 0)
   {
      switch (string[src])
      {
         case '~':                      /* "separator" characters -- */
         case '-':                      /* replaced with space */
         case ' ':                      /* and copy an actual space */
            bt_sbuf_putc (&out, ' ');
            src++;
            break;
         case '{':
            if (depth == 0 && string[src + 1] == '\\')
               purify_special_char (string, &src, &out);
            else
               src++;
            depth++;
            break;
         case '}':
            depth--;
            src++;
            break;
         default:
         {
            size_t n = charlen (string + src);
            if (bt_uni_isalnum (string + src) || bt_uni_ismark (string + src))
               bt_sbuf_putn (&out, string + src, n);
            src += n;
         }
      }
   }

   return bt_sbuf_steal (&out);
}


/* ======================================================================
 * Case-transformation stuff
 */

static boolean
is_space (char c)
{
   return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f'
      || c == '\v';
}

/* ------------------------------------------------------------------------
@NAME       : convert_special_char()
@DESCRIPTION: Does case conversion on a special character: text at any
              depth inside it is case-mangled (lowercased for 'l' and 't',
              uppercased for 'u'); control sequences are left alone unless
              they are foreign letters, which are converted using the
              uc_version/lc_version tables.
-------------------------------------------------------------------------- */
static void
convert_special_char (char transform, const char *string, size_t *src,
                      bt_sbuf *out, boolean *start_sentence,
                      boolean *after_colon)
{
   int     depth = 1;
   boolean done_special = FALSE;

   bt_sbuf_putc (out, string[(*src)++]);   /* copy the opening brace */

   while (string[*src] != 0 && !done_special)
   {
      switch (string[*src])
      {
         case '\\':                     /* a control sequence */
         {
            size_t    cs_end = *src + 1;
            bt_letter letter;

            while (BT_IS_ALPHA (string[cs_end]))
               cs_end++;

            if (foreign_letter (string, (int) *src + 1, (int) cs_end, &letter))
            {
               const char * repl;

               if (transform == 'u')
                  repl = uc_version[letter];
               else if (transform == 'l')
                  repl = lc_version[letter];
               else if (*start_sentence || *after_colon)
               {
                  repl = uc_version[letter];
                  *start_sentence = *after_colon = FALSE;
               }
               else
                  repl = lc_version[letter];
               bt_sbuf_puts (out, repl);
            }
            else                        /* copy the control seq. as is */
               bt_sbuf_putn (out, string + *src, cs_end - *src);
            *src = cs_end;
            break;
         }

         case '{':
            bt_sbuf_putc (out, string[(*src)++]);
            depth++;
            break;

         case '}':
            bt_sbuf_putc (out, string[(*src)++]);
            depth--;
            if (depth == 0)
               done_special = TRUE;
            break;

         default:
            /* Inside special chars, lowercase and title caps are the same
             * (BibTeX's convention). */
            *src += bt_uni_map_char (out, string + *src,
                                     transform == 'u'
                                     ? BT_CASE_UPPER : BT_CASE_LOWER);
      }
   }
}


/* ------------------------------------------------------------------------
@NAME       : bt_change_case()
@DESCRIPTION: Converts a string to uppercase ('u'), lowercase ('l'), or
              "title capitalization" ('t': lowercase, except for the first
              character of the string, of each sentence, and after a
              colon).  Text in braces is left alone, except in special
              characters (see convert_special_char()).
@RETURNS    : new string, or NULL (with a usage error) if `transform' is
              invalid
-------------------------------------------------------------------------- */
char *
bt_change_case (bt_errors *errs, char transform, const char *string,
                btshort options)
{
   size_t  src = 0;
   int     depth = 0;
   boolean start_sentence = TRUE;
   boolean after_colon = FALSE;
   bt_sbuf out;

   (void) options;
   if (transform != 'u' && transform != 'l' && transform != 't')
   {
      bt_report (errs, BTERR_USAGEERR, NULL, -1, NULL, -1,
                 "bt_change_case: invalid transform \"%c\" "
                 "(must be one of \"t\", \"u\" or \"l\")", transform);
      return NULL;
   }

   bt_sbuf_init (&out);
   bt_sbuf_grow (&out, strlen (string));

   while (string[src] != 0)
   {
      switch (string[src])
      {
         case '{':
            /* A special character is handled in one go; anything else in
             * braces is protected from case-mangling, but still switches
             * us out of start-of-sentence/after-colon mode. */
            if (depth == 0 && string[src + 1] == '\\')
               convert_special_char (transform, string, &src, &out,
                                     &start_sentence, &after_colon);
            else
            {
               bt_sbuf_putc (&out, string[src++]);
               start_sentence = after_colon = FALSE;
               depth++;
            }
            break;

         case '}':
            bt_sbuf_putc (&out, string[src++]);
            depth--;
            break;

         /* Sentence-ending punctuation and colons (BibTeX only cares
          * about colons; we also capitalize the start of sentences) */
         case '.':
         case '?':
         case '!':
            start_sentence = TRUE;
            bt_sbuf_putc (&out, string[src++]);
            break;

         case ':':
            after_colon = TRUE;
            bt_sbuf_putc (&out, string[src++]);
            break;

         default:
            if (is_space (string[src]))
               bt_sbuf_putc (&out, string[src++]);
            else if (depth == 0)
            {
               bt_casemap how;

               if (transform == 'u')
                  how = BT_CASE_UPPER;
               else if (transform == 'l')
                  how = BT_CASE_LOWER;
               else if (start_sentence || after_colon)
               {
                  how = BT_CASE_TITLE;
                  start_sentence = after_colon = FALSE;
               }
               else
                  how = BT_CASE_LOWER;
               src += bt_uni_map_char (&out, string + src, how);
            }
            else
            {
               size_t n = charlen (string + src);
               bt_sbuf_putn (&out, string + src, n);
               src += n;
            }
      }
   }

   return bt_sbuf_steal (&out);
}
