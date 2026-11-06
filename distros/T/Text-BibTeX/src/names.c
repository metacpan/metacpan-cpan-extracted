/* ------------------------------------------------------------------------
@NAME       : names.c
@DESCRIPTION: Splitting lists of names (or anything else) on a delimiter
              like "and", and splitting single names into their first,
              von, last and jr parts according to the BibTeX rules:
                bt_split_list
                bt_split_name
              Name tokens are classified as lowercase ("von" particles)
              by the Unicode General_Category of their first character;
              TeX markup is not interpreted.
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

#define MAX_COMMAS 2

#define BT_IS_SPACE(c) ((c) == ' ' || (c) == '\t' || (c) == '\n' || \
                        (c) == '\r' || (c) == '\f' || (c) == '\v')

typedef struct
{
   bt_errors *  errs;
   const char * filename;
   int          line;
   int          name_num;
} name_loc;

static void
name_warning (name_loc *loc, const char *msg)
{
   bt_report (loc->errs, BTERR_CONTENT, loc->filename, loc->line,
              "name", loc->name_num, "%s", msg);
}

static void
update_depth (char c, int *depth, name_loc *loc)
{
   if (c == '{')
      (*depth)++;
   else if (c == '}')
   {
      if (*depth)
         (*depth)--;
      else
         name_warning (loc, "unmatched '}' (ignoring)");
   }
}


/* ------------------------------------------------------------------------
@NAME       : bt_split_list()
@INPUT      : string - string to split up; whitespace must be collapsed
                       eg. by bt_postprocess_string()
              delim  - delimiter to use; must be lowercase and should be
                       free of whitespace (code requires that delimiters
                       in string be surrounded by whitespace)
              filename, line - source of string (for warning messages)
              description - what substrings are (eg. "name") (for warning
                            messages); if NULL will use "substring"
@RETURNS    : a bt_stringlist (free with bt_free_list()), or NULL if
              the string is empty
@DESCRIPTION: Splits a string into substrings at each occurrence of
              `delim' that is at brace-depth zero and surrounded by
              whitespace.  The comparison is case-insensitive.
-------------------------------------------------------------------------- */
bt_stringlist *
bt_split_list (bt_errors *errs, const char *string, const char *delim,
               const char *filename, int line, const char *description)
{
   int    depth;                        /* brace depth */
   int    i, j;                         /* offset into string and delim */
   int    inword;                       /* flag telling if prev. char != ws */
   int    string_len;
   int    delim_len;
   int    maxdiv;                       /* upper limit on no. of divisions */
   int    numdiv;                       /* number of divisions */
   int *  start;                        /* start of each division */
   int *  stop;                         /* stop of each division */
   bt_stringlist * list;
   name_loc loc;

   loc.errs = errs;
   loc.filename = filename;
   loc.line = line;
   loc.name_num = 0;

   if (string == NULL)
      return NULL;
   if (description == NULL)
      description = "substring";
   if (delim == NULL || *delim == 0)
   {
      bt_report (errs, BTERR_USAGEERR, NULL, -1, NULL, -1,
                 "bt_split_list: delimiter must not be empty");
      return NULL;
   }

   string_len = (int) strlen (string);
   delim_len = (int) strlen (delim);
   if (string_len == 0)
      return NULL;

   maxdiv = (string_len / delim_len) + 1;
   start = bt_xmalloc (maxdiv * sizeof (int));
   stop = bt_xmalloc (maxdiv * sizeof (int));

   depth = 0;
   i = j = 0;
   inword = 1;                          /* so leading delim ignored */
   numdiv = 0;
   start[0] = 0;                        /* first substring @ start of string */

   while (i < string_len)
   {
      /* does current char. in string match current char. in delim? */
      if (depth == 0 && !inword
          && BT_TOLOWER ((unsigned char) string[i]) == delim[j])
      {
         j++; i++;

         /* have we found an entire delim, followed by a space? */
         if (j == delim_len && string[i] == ' ')
         {
            stop[numdiv] = i - delim_len - 1;
            start[++numdiv] = ++i;
            j = 0;
         }
      }
      /* no match between string and delim, at non-zero depth, or in a word */
      else
      {
         update_depth (string[i], &depth, &loc);
         inword = string[i] != ' ';
         i++;
         j = 0;
      }
   }
   if (depth)
      name_warning (&loc, "unmatched '{' (ignoring)");

   stop[numdiv] = string_len;           /* last substring ends just past eos */

   list = bt_xmalloc (sizeof (bt_stringlist));
   list->num_items = numdiv + 1;
   list->items = bt_xmalloc (list->num_items * sizeof (char *));
   list->string = bt_xstrdup (string);

   for (i = 0; i < list->num_items; i++)
   {
      if (stop[i] > start[i])           /* the usual case */
      {
         list->string[stop[i]] = 0;
         list->items[i] = list->string + start[i];
      }
      else                              /* empty element */
      {
         list->items[i] = NULL;
         bt_report (errs, BTERR_CONTENT, filename, line, description, i + 1,
                    "empty %s", description);
      }
   }

   free (start);
   free (stop);
   return list;
}

void
bt_free_list (bt_stringlist *list)
{
   if (list)
   {
      free (list->string);
      free (list->items);
      free (list);
   }
}


/* ----------------------------------------------------------------------
 * Splitting a single name
 */

/* ------------------------------------------------------------------------
@NAME       : find_commas
@INPUT      : name       - string to search for commas
              max_commas - maximum number of commas to allow (if more than
                           this number are seen, a warning is given and
                           the excess commas are removed)
@RETURNS    : number of commas found
@DESCRIPTION: Counts commas at brace-depth 0.  Modifies the string in
              place to remove whitespace around commas, excess commas,
              and any trailing commas; warns on excess or trailing commas.
-------------------------------------------------------------------------- */
static int
find_commas (name_loc *loc, char *name, int max_commas)
{
   char *  i = name, *j = name;
   int     depth = 0;
   int     num_commas = 0;
   boolean last_whitespace = FALSE;
   boolean warned = FALSE;

   /* First pass to check for and blank out excess commas */
   while (*i)
   {
      char c = *i++;

      update_depth (c, &depth, loc);
      if (depth == 0 && c == ',')
      {
         num_commas++;
         if (num_commas > max_commas)
         {
            if (!warned)
            {
               name_warning (loc, "too many commas in name (removing extras)");
               warned = TRUE;
            }
            c = ' ';
         }
         /* replace any preceding (collapsed) whitespace with the comma,
          * and drop any following whitespace */
         if (last_whitespace && j > name)
            --j;
         else
            last_whitespace = TRUE;
      }
      else if (BT_IS_SPACE (c))
      {
         if (last_whitespace)
            continue;
         last_whitespace = TRUE;
      }
      else
         last_whitespace = FALSE;
      *j++ = c;
   }
   *j = 0;

   if (depth)
      name_warning (loc, "unmatched '{' (ignoring)");

   if (num_commas == 0)
      return 0;

   j = name + strlen (name);
   if (j > name && j[-1] == ',')
   {
      name_warning (loc, "comma(s) at end of name (removing)");
      while (j > name && j[-1] == ',')
      {
         *--j = 0;
         num_commas--;
      }
   }

   return num_commas > max_commas ? max_commas : num_commas;
}


/* ------------------------------------------------------------------------
@NAME       : find_tokens
@INPUT      : name       - string to tokenize (a private copy that we're
                           free to clobber)
@OUTPUT     : comma_token- number of token immediately preceding each comma
              num_commas - number of commas recorded in comma_token
@RETURNS    : newly-allocated bt_stringlist structure
@DESCRIPTION: Finds tokens in a string; the delimiter is space or comma at
              brace-depth zero.  Empty tokens (caused by consecutive
              commas) are recorded as NULL.
-------------------------------------------------------------------------- */
static bt_stringlist *
find_tokens (char *name, int *comma_token, int *num_commas, name_loc *loc)
{
   int    i = 0;
   int    num_tok = 0;
   int    in_boundary = 1;              /* previous char was ' ' or ',' */
   int    len = (int) strlen (name);
   int    depth = 0;
   bt_stringlist * tokens;

   *num_commas = 0;
   tokens = bt_xmalloc (sizeof (bt_stringlist));
   tokens->string = name;
   tokens->num_items = 0;
   tokens->items = NULL;

   if (len == 0)
      return tokens;

   tokens->items = bt_xmalloc (sizeof (char *) * (len + 1));

   while (i < len)
   {
      if (depth == 0 && in_boundary)    /* at start of a new token */
         tokens->items[num_tok++] = name + i;

      if (depth == 0 && (name[i] == ' ' || name[i] == ','))
      {
         /* if we're at a comma, record the token preceding the comma */
         if (name[i] == ',' && *num_commas < MAX_COMMAS)
            comma_token[(*num_commas)++] = num_tok - 1;

         /* if already in a boundary zone, we have an empty token
          * (caused by multiple consecutive commas) */
         if (in_boundary)
            tokens->items[num_tok - 1] = NULL;

         name[i] = 0;
         in_boundary = 1;
      }
      else
         in_boundary = 0;

      update_depth (name[i], &depth, loc);
      i++;
   }

   if (depth)
      name_warning (loc, "unmatched '{' (ignoring)");

   tokens->num_items = num_tok;
   return tokens;
}


/* ------------------------------------------------------------------------
@NAME       : find_lc_tokens()
@OUTPUT     : first_lc, last_lc - first and last token of the first run of
                                  lowercase tokens (-1 if none)
@DESCRIPTION: A token is "lowercase" if its first character is a
              lowercase letter.
-------------------------------------------------------------------------- */
static void
find_lc_tokens (bt_stringlist *tokens, int *first_lc, int *last_lc)
{
   int i = 0;

   *first_lc = *last_lc = -1;
   while (i < tokens->num_items)
   {
      char * token = tokens->items[i];

      if (*first_lc == -1 && token != NULL && bt_uni_islower (token))
      {
         *first_lc = i;
         i++;
         while (i < tokens->num_items && tokens->items[i] != NULL
                && bt_uni_islower (tokens->items[i]))
            i++;
         *last_lc = i - 1;
      }
      else
         i++;
   }
}


static void
resolve_token_range (bt_stringlist *tokens, int *tok_range,
                     char ***part, int *num_tok)
{
   *num_tok = (tok_range[1] - tok_range[0]) + 1;
   if (*num_tok <= 0 || tok_range[0] < 0
       || tok_range[1] >= tokens->num_items)
   {
      *num_tok = 0;
      *part = NULL;
   }
   else
      *part = tokens->items + tok_range[0];
}


/* ------------------------------------------------------------------------
@NAME       : split_simple_name()
@DESCRIPTION: Splits a name with no commas according to the BibTeX rules:
                 - tokens up to the first lowercase token (or all but the
                   last token, if there are no lowercase tokens) become
                   the `first' part
                 - the run of lowercase tokens, up to (but not including)
                   the last token, becomes the `von' part
                 - the remaining tokens (at least the last) become the
                   `last' part
-------------------------------------------------------------------------- */
static void
split_simple_name (bt_name *name, int first_lc, int last_lc)
{
   int first_t[2], von_t[2], last_t[2];
   int end = name->tokens->num_items - 1;

   if (first_lc > -1)                   /* any lowercase tokens at all? */
   {
      first_t[0] = 0;
      first_t[1] = first_lc - 1;
      if (last_lc == end)               /* lowercase run goes to the end */
         last_lc--;                     /* -- keep the last as lastname */
      von_t[0] = first_lc;
      von_t[1] = last_lc;
      last_t[0] = last_lc + 1;
      last_t[1] = end;
   }
   else                                 /* no lowercase tokens */
   {
      von_t[0] = 0;
      von_t[1] = -1;
      first_t[0] = 0;
      first_t[1] = end - 1;
      last_t[0] = last_t[1] = end;
   }

   resolve_token_range (name->tokens, first_t,
                        name->parts + BTN_FIRST, name->part_len + BTN_FIRST);
   resolve_token_range (name->tokens, von_t,
                        name->parts + BTN_VON, name->part_len + BTN_VON);
   resolve_token_range (name->tokens, last_t,
                        name->parts + BTN_LAST, name->part_len + BTN_LAST);
   name->parts[BTN_JR] = NULL;
   name->part_len[BTN_JR] = 0;
}


/* ------------------------------------------------------------------------
@NAME       : split_general_name()
@DESCRIPTION: Splits a name with 1 or 2 commas:
                 - a leading run of lowercase tokens before the first
                   comma becomes the `von' part
                 - the tokens after that up to the first comma become
                   the `last' part
                 - with one comma, the rest is the `first' part
                 - with two commas, the tokens between them are the `jr'
                   part and the tokens after the second are `first'
-------------------------------------------------------------------------- */
static void
split_general_name (bt_name *name, int num_commas, int *comma_token,
                    int first_lc, int last_lc)
{
   int first_t[2], von_t[2], last_t[2], jr_t[2];
   int end = name->tokens->num_items - 1;

   if (first_lc == 0)                   /* initial run of lowercase tokens */
   {
      if (last_lc == comma_token[0])    /* lc string ends at first comma */
         last_lc--;
      von_t[0] = first_lc;
      von_t[1] = last_lc;
   }
   else
   {
      von_t[0] = 0;
      von_t[1] = -1;
   }

   last_t[0] = von_t[1] + 1;
   last_t[1] = comma_token[0];

   if (num_commas == 1)
   {
      first_t[0] = comma_token[0] + 1;
      first_t[1] = end;
      jr_t[0] = 0;
      jr_t[1] = -1;
   }
   else
   {
      jr_t[0] = comma_token[0] + 1;
      jr_t[1] = comma_token[1];
      first_t[0] = comma_token[1] + 1;
      first_t[1] = end;
   }

   resolve_token_range (name->tokens, first_t,
                        name->parts + BTN_FIRST, name->part_len + BTN_FIRST);
   resolve_token_range (name->tokens, von_t,
                        name->parts + BTN_VON, name->part_len + BTN_VON);
   resolve_token_range (name->tokens, last_t,
                        name->parts + BTN_LAST, name->part_len + BTN_LAST);
   resolve_token_range (name->tokens, jr_t,
                        name->parts + BTN_JR, name->part_len + BTN_JR);
}


/* A part made up only of empty tokens (from stray commas, as in
 * ", John") is no part at all */
static void
drop_empty_parts (bt_name *name)
{
   int i, j;

   for (i = 0; i < BT_MAX_NAMEPARTS; i++)
   {
      for (j = 0; j < name->part_len[i]; j++)
         if (name->parts[i][j] != NULL)
            break;
      if (j == name->part_len[i])
      {
         name->parts[i] = NULL;
         name->part_len[i] = 0;
      }
   }
}

static void
empty_name (bt_name *name)
{
   int i;

   for (i = 0; i < BT_MAX_NAMEPARTS; i++)
   {
      name->parts[i] = NULL;
      name->part_len[i] = 0;
   }
   name->tokens = NULL;
}

/* ------------------------------------------------------------------------
@NAME       : bt_split_name()
@INPUT      : name     - string to split (whitespace should be collapsed)
              filename, line, name_num - for warning messages
@RETURNS    : a bt_name structure (free with bt_free_name())
@DESCRIPTION: Splits a single name into its first, von, last and jr
              parts.  See split_simple_name() for the rules for names
              without commas, and split_general_name() for names with 1 or
              2 commas (any extra commas are removed with a warning).
-------------------------------------------------------------------------- */
bt_name *
bt_split_name (bt_errors *errs, const char *string,
               const char *filename, int line, int name_num)
{
   name_loc  loc;
   bt_stringlist * tokens;
   int       comma_token[MAX_COMMAS];
   int       num_commas, num_comma_tokens;
   int       first_lc, last_lc;
   bt_name * split_name;
   char *    name;

   split_name = bt_xmalloc (sizeof (bt_name));
   empty_name (split_name);
   if (string == NULL || *string == 0)
      return split_name;

   name = bt_xstrdup (string);          /* private copy that we may clobber */
   loc.errs = errs;
   loc.filename = filename;
   loc.line = line;
   loc.name_num = name_num;

   num_commas = find_commas (&loc, name, MAX_COMMAS);
   if (*name == 0)                      /* (check before find_tokens() puts */
   {                                    /* NULs at the commas) */
      free (name);
      return split_name;
   }
   tokens = find_tokens (name, comma_token, &num_comma_tokens, &loc);
   if (num_comma_tokens < num_commas)
      num_commas = num_comma_tokens;
   find_lc_tokens (tokens, &first_lc, &last_lc);

   if (tokens->num_items == 0)
   {
      bt_free_list (tokens);            /* frees `name' too */
      return split_name;
   }

   split_name->tokens = tokens;
   if (num_commas == 0)
      split_simple_name (split_name, first_lc, last_lc);
   else
      split_general_name (split_name, num_commas, comma_token,
                          first_lc, last_lc);
   drop_empty_parts (split_name);

   if (split_name->parts[BTN_LAST] == NULL)
      name_warning (&loc, "name has no last name");
   return split_name;
}

void
bt_free_name (bt_name *name)
{
   if (name)
   {
      bt_free_list (name->tokens);
      free (name);
   }
}
