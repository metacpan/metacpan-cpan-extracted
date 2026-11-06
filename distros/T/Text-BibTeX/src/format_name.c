/* ------------------------------------------------------------------------
@NAME       : format_name.c
@DESCRIPTION: bt_format_name() and support functions: everything needed
              to turn a bt_name structure (as returned by bt_split_name())
              back into a string according to a highly customizable format.
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


/* ----------------------------------------------------------------------
 * Interface to create/customize bt_name_format structures
 */

static void
set_text (char **slot, const char *text)
{
   free (*slot);
   *slot = bt_xstrdup (text ? text : "");
}

/* ------------------------------------------------------------------------
@NAME       : bt_create_name_format
@INPUT      : parts - a string of letters (maximum four, from the set
                      f, v, l, j, with no repetition) denoting the order
                      and presence of name parts.
              abbrev_first - flag: should first names be abbreviated?
@RETURNS    : a new format (free with bt_free_name_format()), or NULL
              (with a usage error) if `parts' is invalid
@DESCRIPTION: Sets token join methods: inter-token join (within each part)
              is set to BTJ_MAYTIE (a "discretionary tie") for all parts;
              inter-part join is set to BTJ_SPACE, except for a 'von'
              token immediately preceding a 'last' token; there, we have
              a discretionary tie.

              Sets abbreviation flags: FALSE for everything except `first',
              which follows `abbrev_first' argument.

              Sets surrounding text (pre- and post-part, pre- and post-
              token): empty string for everything, except:
                - post-token for 'first' is "." if abbrev_first true
                - if 'jr' immediately preceded by 'last':
                  pre-part for 'jr' is ", ", join for 'last' is nothing
                - if 'first' immediately preceded by 'last'
                  pre-part for 'first' is ", " , join for 'last' is nothing
                - if 'first' immediately preceded by 'jr' and 'jr' immediately
                  preceded by 'last':
                    pre-part for 'first' and 'jr' is ", " ,
                    join for 'last' and 'jr' is nothing
-------------------------------------------------------------------------- */
bt_name_format *
bt_create_name_format (bt_errors *errs, const char *parts,
                       boolean abbrev_first)
{
   int    num_parts;
   int    num_valid_parts;
   bt_name_format * format;
   int    part_pos[BT_MAX_NAMEPARTS];
   int    i;

   for (i = 0; i < BT_MAX_NAMEPARTS; i++)
      part_pos[i] = -2;

   num_parts = (int) strlen (parts);
   num_valid_parts = (int) strspn (parts, BT_VALID_NAMEPARTS);
   if (num_parts > BT_MAX_NAMEPARTS)
   {
      bt_report (errs, BTERR_USAGEERR, NULL, -1, NULL, -1,
                 "bt_create_name_format: part list must have no more than "
                 "%d letters", BT_MAX_NAMEPARTS);
      return NULL;
   }
   if (num_valid_parts != num_parts)
   {
      bt_report (errs, BTERR_USAGEERR, NULL, -1, NULL, -1,
                 "bt_create_name_format: bad part abbreviation \"%c\" "
                 "(must be one of \"%s\")",
                 parts[num_valid_parts], BT_VALID_NAMEPARTS);
      return NULL;
   }
   format = bt_xcalloc (1, sizeof (bt_name_format));
   format->num_parts = num_parts;
   for (i = 0; i < num_parts; i++)
   {
      switch (parts[i])
      {
         case 'f': format->parts[i] = BTN_FIRST; break;
         case 'v': format->parts[i] = BTN_VON; break;
         case 'l': format->parts[i] = BTN_LAST; break;
         case 'j': format->parts[i] = BTN_JR; break;
      }
      part_pos[format->parts[i]] = i;
   }
   for (; i < BT_MAX_NAMEPARTS; i++)
      format->parts[i] = BTN_NONE;

   /*
    * Token join methods: between tokens for all parts is a discretionary
    * tie, and the join between parts is a space (except for 'von': if
    * followed by 'last', we will have a discretionary tie).
    */
   for (i = 0; i < BT_MAX_NAMEPARTS; i++)
   {
      format->join_tokens[i] = BTJ_MAYTIE;
      format->join_part[i] = BTJ_SPACE;
   }
   if (part_pos[BTN_VON] + 1 == part_pos[BTN_LAST])
      format->join_part[BTN_VON] = BTJ_MAYTIE;

   format->abbrev[BTN_FIRST] = abbrev_first;
   format->abbrev[BTN_VON] = FALSE;
   format->abbrev[BTN_LAST] = FALSE;
   format->abbrev[BTN_JR] = FALSE;

   for (i = 0; i < BT_MAX_NAMEPARTS; i++)
   {
      set_text (&format->pre_part[i], "");
      set_text (&format->post_part[i], "");
      set_text (&format->pre_token[i], "");
      set_text (&format->post_token[i], "");
   }

   /* abbreviated first name: "Blow J" -> "Blow J.", or "J Blow" -> "J. Blow" */
   if (abbrev_first)
      set_text (&format->post_token[BTN_FIRST], ".");

   /* 'jr' after 'last': "Joe Blow Jr." -> "Joe Blow, Jr." */
   if (part_pos[BTN_JR] == part_pos[BTN_LAST] + 1)
   {
      set_text (&format->pre_part[BTN_JR], ", ");
      format->join_part[BTN_LAST] = BTJ_NOTHING;
      /* 'first' after 'last' and 'jr': "Blow, Jr. Joe"->"Blow, Jr., Joe" */
      if (part_pos[BTN_FIRST] == part_pos[BTN_JR] + 1)
      {
         set_text (&format->pre_part[BTN_FIRST], ", ");
         format->join_part[BTN_JR] = BTJ_NOTHING;
      }
   }
   /* first after last: "Blow Joe" -> "Blow, Joe" */
   if (part_pos[BTN_FIRST] == part_pos[BTN_LAST] + 1)
   {
      set_text (&format->pre_part[BTN_FIRST], ", ");
      format->join_part[BTN_LAST] = BTJ_NOTHING;
   }

   return format;
}

void
bt_free_name_format (bt_name_format *format)
{
   int i;

   if (!format)
      return;
   for (i = 0; i < BT_MAX_NAMEPARTS; i++)
   {
      free (format->pre_part[i]);
      free (format->post_part[i]);
      free (format->pre_token[i]);
      free (format->post_token[i]);
   }
   free (format);
}

/* Sets the "surrounding text" for a name part; NULL leaves a slot alone.
 * The strings are copied. */
void
bt_set_format_text (bt_name_format *format, bt_namepart part,
                    const char *pre_part, const char *post_part,
                    const char *pre_token, const char *post_token)
{
   if ((int) part < 0 || part >= BT_MAX_NAMEPARTS)
      return;
   if (pre_part) set_text (&format->pre_part[part], pre_part);
   if (post_part) set_text (&format->post_part[part], post_part);
   if (pre_token) set_text (&format->pre_token[part], pre_token);
   if (post_token) set_text (&format->post_token[part], post_token);
}

void
bt_set_format_options (bt_name_format *format, bt_namepart part,
                       boolean abbrev, bt_joinmethod join_tokens,
                       bt_joinmethod join_part)
{
   if ((int) part < 0 || part >= BT_MAX_NAMEPARTS)
      return;
   format->abbrev[part] = abbrev;
   format->join_tokens[part] = join_tokens;
   format->join_part[part] = join_part;
}


/* ----------------------------------------------------------------------
 * Functions for actually formatting a name (given a name and a name
 * format structure).
 */

/* ------------------------------------------------------------------------
@NAME       : count_virtual_char()
@DESCRIPTION: Munches a single byte from a string, updating the virtual
              character count, the depth, and an "in special character"
              flag.

              The virtual character count is incremented by any character
              (grapheme cluster) not part of a special character, and also
              by the right-brace that closes a special character. The depth
              is incremented by a left brace, and decremented by a right
              brace.  in_special is set to TRUE when we encounter a left
              brace at depth zero that is immediately followed by a
              backslash; it is set to false when we encounter the end of
              the special character, i.e. when in_special is TRUE and we
              hit a right brace that brings us back to depth zero.

              *glen tracks how many bytes remain of the current grapheme;
              the count goes up on its last byte.  Set all of the state to
              zero/FALSE before the first call on a string.
-------------------------------------------------------------------------- */
static void
count_virtual_char (const char *string, int offset, int *vchar_count,
                    int *depth, boolean *in_special, int *glen)
{
   switch (string[offset])
   {
      case '{':
         /* start of a special char? */
         if (*depth == 0 && string[offset + 1] == '\\')
            *in_special = TRUE;
         (*depth)++;
         break;
      case '}':
         /* end of a special char? */
         if (*depth == 1 && *in_special)
         {
            *in_special = FALSE;
            (*vchar_count)++;
         }
         (*depth)--;
         break;
      default:
         if (! *in_special)
         {
            if (*glen == 0)
               *glen = (int) bt_uni_grapheme_len (string + offset);
            if (*glen == 1)
            {
               (*vchar_count)++;
               *glen = 0;
            }
            else if (*glen > 1)
               (*glen)--;
         }
   }
}

/* "virtual length" of a string: special characters count as one, as
 * does each grapheme cluster outside them */
static int
string_length (const char *string)
{
   int     length = 0, depth = 0, glen = 0, i;
   boolean in_special = FALSE;

   if (string == NULL)
      return 0;
   for (i = 0; string[i] != 0; i++)
      count_virtual_char (string, i, &length, &depth, &in_special, &glen);
   return length;
}

/* ------------------------------------------------------------------------
@NAME       : string_prefix()
@RETURNS    : physical length of the prefix of `string' (starting at
              prefix_start) with a virtual length of `prefix_len'
-------------------------------------------------------------------------- */
static int
string_prefix (const char *string, int prefix_start, int prefix_len)
{
   int     i, vchars_seen = 0, depth = 0, glen = 0;
   boolean in_special = FALSE;

   for (i = prefix_start; string[i] != 0; i++)
   {
      count_virtual_char (string, i, &vchars_seen, &depth, &in_special,
                          &glen);
      if (vchars_seen == prefix_len)
         return (i + 1) - prefix_start;
   }
   return i - prefix_start;
}

/* ------------------------------------------------------------------------
@NAME       : string_prefix_start()
@RETURNS    : index where we need to start looking at name part when
              abbreviating: if the character at `index' opens a brace
              group that is not a special character (examples:
              "{John Henry} Ford" or "{Some Organisation Inc.}"), the
              initial is taken from just inside the brace.
-------------------------------------------------------------------------- */
static int
string_prefix_start (const char *string, int index)
{
   int     vchars_seen = 0, depth = 0, glen = 0;
   boolean in_special = FALSE;

   count_virtual_char (string, index, &vchars_seen, &depth, &in_special,
                       &glen);
   if (! in_special && depth == 1)
      return index + 1;
   return index;
}

/* Appends at most len bytes (all of them if len <= 0) of text+start */
static void
append_text (bt_sbuf *out, const char *text, int start, int len)
{
   size_t n;

   if (text == NULL)
      return;
   n = strlen (text + start);
   if (len > 0 && (size_t) len < n)
      n = (size_t) len;
   bt_sbuf_putn (out, text + start, n);
}

/* ------------------------------------------------------------------------
@NAME       : append_join
@DESCRIPTION: Appends a "join character" ('~' or ' ') or nothing according
              to the join method and the `should_tie' flag (which decides
              what a BTJ_MAYTIE becomes).
-------------------------------------------------------------------------- */
static void
append_join (bt_sbuf *out, bt_joinmethod method, boolean should_tie)
{
   switch (method)
   {
      case BTJ_MAYTIE:   bt_sbuf_putc (out, should_tie ? '~' : ' '); break;
      case BTJ_SPACE:    bt_sbuf_putc (out, ' '); break;
      case BTJ_FORCETIE: bt_sbuf_putc (out, '~'); break;
      case BTJ_NOTHING:  break;
   }
}


/* ------------------------------------------------------------------------
@NAME       : bt_format_name()
@INPUT      : name, format
@RETURNS    : formatted name (a malloc'd string)
-------------------------------------------------------------------------- */
char *
bt_format_name (bt_errors *errs, bt_name *name, bt_name_format *format)
{
   bt_namepart parts[BT_MAX_NAMEPARTS]; /* culled list from format */
   int         num_parts;
   char **     tokens[BT_MAX_NAMEPARTS];
   int         num_tokens[BT_MAX_NAMEPARTS];
   bt_sbuf     out;
   int         i, j, k;
   bt_namepart part;
   int         token_vlen = -1;         /* "virtual" length of last token */
   boolean     should_tie;
   boolean     hyphen_todo = FALSE;

   for (i = 0; i < BT_MAX_NAMEPARTS; i++)
   {
      tokens[i] = name->parts[i];
      num_tokens[i] = name->part_len[i];
   }

   /*
    * Cull format->parts down by keeping only those parts that are actually
    * present in the current name (keeps the main loop simpler: makes it
    * easy to know if the "next part" is present or not, so we know whether
    * to append a join character.
    */
   num_parts = 0;
   for (i = 0; i < format->num_parts; i++)
   {
      part = format->parts[i];
      if (tokens[part])
         parts[num_parts++] = part;
   }

   bt_sbuf_init (&out);
   bt_sbuf_grow (&out, 0);

   for (i = 0; i < num_parts; i++)
   {
      part = parts[i];
      append_text (&out, format->pre_part[part], 0, -1);

      for (j = 0; j < num_tokens[part]; j++)
      {
         const char * tok = tokens[part][j];

         if (!tok)                      /* ignore empty tokens */
            continue;
         append_text (&out, format->pre_token[part], 0, -1);

         if (format->abbrev[part])
         {
            /* Track depth and specials so we can ignore hyphenated token
             * parts within protecting braces */
            int     vchars_seen = 0, depth = 0, glen = 0;
            boolean in_special = FALSE;

            for (k = 0; tok[k] != 0; k++)
            {
               int prefix_start;

               count_virtual_char (tok, k, &vchars_seen, &depth,
                                   &in_special, &glen);
               prefix_start = string_prefix_start (tok, k);

               /* Add initial from the beginning of the string, or after
                * a hyphen */
               if (k == 0 || hyphen_todo)
               {
                  append_text (&out, tok, prefix_start,
                               string_prefix (tok, prefix_start, 1));
                  hyphen_todo = FALSE;
               }
               /* Potentially add a hyphen unless in protecting braces */
               if (tok[k] == '-' && depth == 0 && in_special == FALSE)
               {
                  append_text (&out, format->post_token[part], 0, -1);
                  append_text (&out, tok, k, 1);
                  hyphen_todo = TRUE;
               }
            }
            token_vlen = 1;
         }
         else
         {
            append_text (&out, tok, 0, -1);
            token_vlen = string_length (tok);
         }

         append_text (&out, format->post_token[part], 0, -1);

         /* join to next token, but only if there is a next token! */
         if (j < num_tokens[part] - 1)
         {
            should_tie = (num_tokens[part] > 1)
               && (((j == 0) && (token_vlen < 3))
                   || (j == num_tokens[part] - 2));
            append_join (&out, format->join_tokens[part], should_tie);
         }
      }

      append_text (&out, format->post_part[part], 0, -1);

      /* join to the next part, but again only if there is a next part */
      if (i < num_parts - 1)
      {
         if (token_vlen == -1)
         {
            bt_report (errs, BTERR_INTERNAL, NULL, -1, NULL, -1,
                       "token_vlen uninitialized -- no tokens in a part "
                       "that I checked existed");
            token_vlen = 0;
         }
         should_tie = (num_tokens[part] == 1 && token_vlen < 3);
         append_join (&out, format->join_part[part], should_tie);
      }
   }

   return bt_sbuf_steal (&out);
}
