/* ------------------------------------------------------------------------
@NAME       : format_name.c
@DESCRIPTION: bt_format_name() and support functions: everything needed
              to turn a bt_name structure (as returned by bt_split_name())
              back into a string according to a highly customizable format.
@GLOBALS    : 
@CREATED    : 
@MODIFIED   : 
@VERSION    : $Id: format_name.c 9577 2011-02-15 21:34:08Z ambs $
@COPYRIGHT  : Copyright (c) 1996-99 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse library.  This library is
              free software; you can redistribute it and/or modify it under
              the terms of the GNU Library General Public License as
              published by the Free Software Foundation; either version 2
              of the License, or (at your option) any later version.
-------------------------------------------------------------------------- */

#include "bt_config.h"
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "btparse.h"
#include "prototypes.h"
#include "error.h"
#include "my_dmalloc.h"
#include "bt_debug.h"


static char EmptyString[] = "";


#if DEBUG
/* prototypes to shut "gcc -Wmissing-prototypes" up */
void print_tokens (char *partname, char **tokens, int num_tokens);
void dump_name (bt_name * name);
void dump_format (bt_name_format * format);
#endif


/* ----------------------------------------------------------------------
 * Interface to create/customize bt_name_format structures
 */

/* ------------------------------------------------------------------------
@NAME       : bt_create_name_format
@INPUT      : parts - a string of letters (maximum four, from the set
                      f, v, l, j, with no repetition) denoting the order
                      and presence of name parts.  Also used to determine
                      certain pre-part text strings.
              abbrev_first - flag: should first names be abbreviated?
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Creates a bt_name_format structure, slightly customized 
              according to the caller's choice of token order and 
              whether to abbreviate the first name.  Use
              bt_free_name_format() to free the structure (and any sub-
              structures that may be allocated here).  Use 
              bt_set_format_text() and bt_set_format_options() for
              further customization of the format structure; do not 
              fiddle its fields directly.

              Fills in the structures `parts' field according to `parts'
              string: 'f' -> BTN_FIRST, and so on.

              Sets token join methods: inter-token join (within each part)
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
@CREATED    : 1997/11/02, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
bt_name_format *
bt_create_name_format (char * parts, boolean abbrev_first)
{
   int    num_parts;
   int    num_valid_parts;
   bt_name_format *
          format;
   int    part_pos[BT_MAX_NAMEPARTS];
   int    i;

   for (i = 0; i < BT_MAX_NAMEPARTS; i++)
      part_pos[i] = -2;

   /* 
    * Check that the part list (a string with one letter -- f, v, l, or j
    * -- for each part is valid: no longer than four characters, and no 
    * invalid characters.
    */

   num_parts = strlen (parts);
   num_valid_parts = strspn (parts, BT_VALID_NAMEPARTS);
   if (num_parts > BT_MAX_NAMEPARTS)
   {
      usage_error ("bt_create_name_format: part list must have no more than "
                   "%d letters", BT_MAX_NAMEPARTS);
   }
   if (num_valid_parts != num_parts)
   {
      usage_error ("bt_create_name_format: bad part abbreviation \"%c\" "
                   "(must be one of \"%s\")", 
                   parts[num_valid_parts], BT_VALID_NAMEPARTS);
   }


   /* User input is OK -- let's create the structure */

   format = (bt_name_format *) malloc (sizeof (bt_name_format));
   format->num_parts = num_parts;
   for (i = 0; i < num_parts; i++)
   {
      switch (parts[i])
      {
         case 'f': format->parts[i] = BTN_FIRST; break;
         case 'v': format->parts[i] = BTN_VON; break;
         case 'l': format->parts[i] = BTN_LAST; break;
         case 'j': format->parts[i] = BTN_JR; break;
         default:  internal_error ("bad part abbreviation \"%c\"", parts[i]);
      }
      part_pos[format->parts[i]] = i;
   }
   for (; i < BT_MAX_NAMEPARTS; i++)
   {
      format->parts[i] = BTN_NONE;
   }


   /* 
    * Set the token join methods: between tokens for all parts is a
    * discretionary tie, and the join between parts is a space (except for
    * 'von': if followed by 'last', we will have a discretionary tie).
    */

   // INITIALIZA ALL!!!! PARTS
   for (i = 0; i < BT_MAX_NAMEPARTS; i++)
   {
      format->join_tokens[i] = BTJ_MAYTIE;
      format->join_part[i] = BTJ_SPACE;
   }
   if (part_pos[BTN_VON] + 1 == part_pos[BTN_LAST])
      format->join_part[BTN_VON] = BTJ_MAYTIE;


   /* 
    * Now the abbreviation flags: follow 'abbrev_first' flag for 'first',
    * and FALSE for everything else.
    */
   format->abbrev[BTN_FIRST] = abbrev_first;
   format->abbrev[BTN_VON] = FALSE;
   format->abbrev[BTN_LAST] = FALSE;
   format->abbrev[BTN_JR] = FALSE;



   /* 
    * Now fill in the "surrounding text" fields (pre- and post-part, pre-
    * and post-token) -- start out with everything NULL (empty string),
    * and then tweak it to handle abbreviated first names, 'jr' following
    * 'last', and 'first' following 'last' or 'last' and 'jr'.  In the
    * last three cases, we put in some pre-part text (", "), and also
    * set the join method for the *previous* part (jr or last) to 
    * BTJ_NOTHING, so we don't get extraneous space before the ", ".
    */
   for (i = 0; i < BT_MAX_NAMEPARTS; i++)
   {
      format->pre_part[i] = EmptyString;
      format->post_part[i] = EmptyString;
      format->pre_token[i] = EmptyString;
      format->post_token[i] = EmptyString;
   }

   /* abbreviated first name: 
    * "Blow J" -> "Blow J.", or "J Blow" -> "J. Blow" 
    */
   if (abbrev_first)
   {
      format->post_token[BTN_FIRST] = ".";
   }
   /* 'jr' after 'last': "Joe Blow Jr." -> "Joe Blow, Jr." */
   if (part_pos[BTN_JR] == part_pos[BTN_LAST]+1) 
   {
      format->pre_part[BTN_JR] = ", ";
      format->join_part[BTN_LAST] = BTJ_NOTHING;
      /* 'first' after 'last' and 'jr': "Blow, Jr. Joe"->"Blow, Jr., Joe" */
      if (part_pos[BTN_FIRST] == part_pos[BTN_JR]+1)
      {
         format->pre_part[BTN_FIRST] = ", "; 
         format->join_part[BTN_JR] = BTJ_NOTHING;
      }
   }
   /* first after last: "Blow Joe" -> "Blow, Joe" */
   if (part_pos[BTN_FIRST] == part_pos[BTN_LAST]+1)
   {
      format->pre_part[BTN_FIRST] = ", ";
      format->join_part[BTN_LAST] = BTJ_NOTHING;
   }

   DBG_ACTION 
      (1, printf ("bt_create_name_format(): returning structure %p\n", format))

   return format;

} /* bt_create_name_format() */


/* ------------------------------------------------------------------------
@NAME       : bt_free_name_format()
@INPUT      : format - free()'d, so this is an invalid pointer after the call
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Frees a bt_name_format structure created by 
              bt_create_name_format().
@CREATED    : 1997/11/02, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
void
bt_free_name_format (bt_name_format * format)
{
   free (format);
}



/* ------------------------------------------------------------------------
@NAME       : bt_set_format_text
@INPUT      : format     - the format structure to update
              part       - which name-part to change the surrounding text for
              pre_part   - "pre-part" text, or NULL to leave alone
              post_part  - "post-part" text, or NULL to leave alone
              pre_token  - "pre-token" text, or NULL to leave alone
              post_token - "post-token" text, or NULL to leave alone
@OUTPUT     : format - pre_part, post_part, pre_token, post_token
                       arrays updated (only those with corresponding
                       non-NULL parameters are touched)
@RETURNS    : 
@DESCRIPTION: Sets the "surrounding text" for a particular name part in
              a name format structure.
@CREATED    : 1997/11/02, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
void
bt_set_format_text (bt_name_format * format, 
                    bt_namepart part,
                    char * pre_part,
                    char * post_part,
                    char * pre_token,
                    char * post_token)
{
   if (pre_part) format->pre_part[part] = pre_part;
   if (post_part) format->post_part[part] = post_part;
   if (pre_token) format->pre_token[part] = pre_token;
   if (post_token) format->post_token[part] = post_token;
}


/* ------------------------------------------------------------------------
@NAME       : bt_set_format_options()
@INPUT      : format
              part
              abbrev
              join_tokens
              join_part
@OUTPUT     : format - abbrev, join_tokens, join_part arrays all updated
@RETURNS    : 
@DESCRIPTION: Sets various formatting options for a particular name part in
              a name format structure.
@CREATED    : 1997/11/02, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
void
bt_set_format_options (bt_name_format * format, 
                       bt_namepart part,
                       boolean abbrev,
                       bt_joinmethod join_tokens,
                       bt_joinmethod join_part)
{
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
@INPUT      : string
              offset
@OUTPUT     : vchar_count
@INOUT      : depth
              in_special
@RETURNS    : 
@DESCRIPTION: Munches a single physical character from a string, updating
              the virtual character count, the depth, and an "in special
              character" flag.  

              The virtual character count is incremented by any character
              not part of a special character, and also by the right-brace
              that closes a special character. The depth is incremented by
              a left brace, and decremented by a right brace.  in_special
              is set to TRUE when we encounter a left brace at depth zero
              that is immediately followed by a backslash; it is set to
              false when we encounter the end of the special character,
              i.e. when in_special is TRUE and we hit a right brace that
              brings us back to depth zero.

              *vchar_count and *depth should both be set to zero the first
              time you call count_virtual_char() on a particular string,
              and in_special should be set to FALSE.
@CALLS      : 
@CALLERS    : string_length()
              string_prefix()
@CREATED    : 1997/11/03, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
static void
count_virtual_char (char *    string, 
                    int       offset, 
                    int *     vchar_count,
                    int *     depth,
                    boolean * in_special,
                    int *     utf8_length)
{
   switch (string[offset])
   {
      case '{': 
      {
         /* start of a special char? */
        if (*depth == 0 && string[offset+1] == '\\')
            *in_special = TRUE;
        (*depth)++;
         break;

      }
      case '}': 
      {
         /* end of a special char? */
         if (*depth == 1 && *in_special)
         {
            *in_special = FALSE;
            (*vchar_count)++;
         }
         (*depth)--;
         break;

      }
      default:
      {
         /* anything else? (possibly inside a special char) */
         if (! *in_special)
           /* Have to take care with UTF-8 chars here - we need to increment
              only when we have a full character which could be multi-byte */
         {
           /* not tracking utf8 char yet, so start */ 
           if (*utf8_length == 0)
             *utf8_length = get_uchar(string, offset);
           /* Final byte in utf8 char so count this as a "character" */ 
           if (*utf8_length == 1)
           {
             (*vchar_count)++;
             *utf8_length = 0;
           }
           /* Inside a multi-byte utf-8 char so decrement the count as we move along
              the bytes */ 
           if (*utf8_length > 1)
             (*utf8_length)--;
         }
      }
   }
} /* count_virtual_char () */


/* this should probably be publicly available, documented, etc. */
/* ------------------------------------------------------------------------
@NAME       : string_length()
@INPUT      : string
@OUTPUT     : 
@RETURNS    : "virtual length" of `string'
@DESCRIPTION: Counts the number of "virtual characters" in a string.  A
              virtual character is either an entire BibTeX special character,
              or any character outside of a special character.

              Thus, "Hello" has virtual length 5, and so does
              "H{\\'e}ll{\\\"o}".  "{\\noop Hello there how are you?}" has
              virtual length one.
@CALLS      : count_virtual_char()
@CALLERS    : format_name()
@CREATED    : 1997/11/03, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
static int
string_length (char * string)
{
   int      length;
   int      depth;
   boolean  in_special;
   int      utf8_length;
   int      i;

   if (string == NULL)
      return 0;

   length = 0;
   depth = 0;
   in_special = FALSE;
   utf8_length = 0;

   for (i = 0; string[i] != 0; i++)
   {
     count_virtual_char (string, i, &length, &depth, &in_special, &utf8_length);
   }

   return length;
} /* string_length() */


/* ------------------------------------------------------------------------
@NAME       : string_prefix()
@INPUT      : string
              prefix_len
@OUTPUT     : 
@RETURNS    : physical length of the prefix of `string' with a virtual length
              of `prefix_len'
@DESCRIPTION: Counts the number of physical characters from the beginning
              of `string' needed to extract a sub-string with virtual
              length `prefix_len'. There is a special case emulating BibTeX
              where we want to ignore beginning '{' which are not escaping
              a virtual char, for example '{Some Organization}' with prefix_len
              1 should return "S".
@CALLS      : count_virtual_char()
@CALLERS    : format_name()
@CREATED    : 1997/11/03, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
static int
string_prefix (char * string, int prefix_start, int prefix_len)
{
   int     i;
   int     vchars_seen;
   int     depth;
   boolean in_special;
   int      utf8_length;

   vchars_seen = 0;
   depth = 0;
   in_special = FALSE;
   utf8_length = 0;

   for (i = prefix_start; string[i] != 0; i++)
   {
     count_virtual_char (string, i, &vchars_seen, &depth, &in_special, &utf8_length);
      if (vchars_seen == prefix_len)
        return (i+1)-prefix_start;
   }

   return i-prefix_start;
   
} /* string_prefix() */


/* ------------------------------------------------------------------------
@NAME       : string_prefix_start()
@INPUT      : string
@OUTPUT     : 
@RETURNS    : index where we need to start looking at name part when 
              abbreviating
@DESCRIPTION: If we are not in a special but depth == 1 then we need
              start at index 1 (examples "{John Henry} Ford" or
              "{Some Organisation Inc.}
@CALLS      : 
@CALLERS    : format_name()
@CREATED    : 2010/03/13, PK
@MODIFIED   : 
-------------------------------------------------------------------------- */
static int
string_prefix_start (char * string, int index)
{
   int     i;
   int     vchars_seen;
   int     depth;
   boolean in_special;
   int      utf8_length;

   vchars_seen = 0;
   depth = 0;
   in_special = FALSE;
   utf8_length = 0;

   count_virtual_char (string, index, &vchars_seen, &depth, &in_special, &utf8_length);
   if (! in_special && depth == 1)
     return index+1;

   return index;
   
} /* string_prefix_start() */



/* ------------------------------------------------------------------------
@NAME       : append_text()
@INOUT      : string
@INPUT      : offset
              text
              start
              len
@OUTPUT     : 
@RETURNS    : number of characters copied from text+start to string+offset
@DESCRIPTION: Copies at most `len' characters from text+start to 
              string+offset.  (I don't use strcpy() or strncpy() for this
              because I need to get the number of characters actually 
              copied.)
@CALLS      : 
@CALLERS    : format_name()
@CREATED    : 1997/11/03, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
static int
append_text (char * string,
             int    offset,
             char * text,
             int    start,
             int    len)
{
   int   i;

   if (text == NULL) return 0;          /* no text -- none appended! */

   for (i = 0; text[start+i] != 0; i++)
   {
      if (len > 0 && i == len) 
         break;                         /* exit loop without i++, right?!? */
      string[offset+i] = text[start+i];
   } /* for i */

   return i;                            /* number of characters copied */

} /* append_text () */


/* ------------------------------------------------------------------------
@NAME       : append_join
@INOUT      : string
@INPUT      : offset
              method
              should_tie
@OUTPUT     : 
@RETURNS    : number of charactersa appended to string+offset (either 0 or 1)
@DESCRIPTION: Copies a "join character" ('~' or ' ') or nothing to 
              string+offset, according to the join method specified by
              `method' and the `should_tie' flag.

              Specifically: if `method' is BTJ_SPACE, a space is appended
              and 1 is returned; if `method' is BTJ_FORCETIE, a TeX "tie"
              character ('~') is appended and 1 is returned.  If `method'
              is BTJ_NOTHING, `string' is unchanged and 0 is returned.  If
              `method' is BTJ_MAYTIE then either a tie (if should_tie is
              true) or a space (otherwise) is appended, and 1 is returned.
@CALLS      : 
@CALLERS    : format_name()
@CREATED    : 1997/11/03, GPW
@MODIFIED   : 
@COMMENTS   : This should allow "tie" strings other than TeX's '~' -- I 
              think this could be done by putting a "tie string" field in
              the name format structure, and using it here.
-------------------------------------------------------------------------- */
static int
append_join (char * string,
             int    offset,
             bt_joinmethod method,
             boolean should_tie)
{
   switch (method)
   {                                    
      case BTJ_MAYTIE:                  /* a "discretionary tie" -- pay */
      {                                 /* attention to should_tie */
         if (should_tie)
            string[offset] = '~';
         else
            string[offset] = ' ';
         return 1;
      }
      case BTJ_SPACE:
      {
         string[offset] = ' ';
         return 1;
      }
      case BTJ_FORCETIE:
      {
         string[offset] = '~';
         return 1;
      }
      case BTJ_NOTHING:
      {
         return 0;
      }
      default:
         internal_error ("bad token join method %d", (int) method);
   }

   return 0;                            /* can't happen -- just here to */
                                        /* keep gcc -Wall happy */
} /* append_join () */


#define STRLEN(s) (s == NULL) ? 0 : strlen (s)

/* ------------------------------------------------------------------------
@NAME       : format_firstpass()
@INPUT      : name
              format
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Makes the first pass over a name for formatting, in order to
              establish an upper bound on the length of the formatted name.
@CALLS      : 
@CALLERS    : bt_format_name()
@CREATED    : 1997/11/03, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
static unsigned
format_firstpass (bt_name *        name,
                  bt_name_format * format)
{
   int         i;                       /* loop over parts */
   int         j;                       /* loop over tokens */
   unsigned    max_length;
   bt_namepart part;
   char **     tok;
   int         num_tok;

   max_length = 0;

   for (i = 0; i < format->num_parts; i++)
   {
      part = format->parts[i];          /* 'cause I'm a lazy typist */
      tok = name->parts[part];
      num_tok = name->part_len[part];

      assert ((tok != NULL) == (num_tok > 0));
      if (tok)
      {
         max_length += STRLEN (format->pre_part[part]);
         max_length += STRLEN (format->post_part[part]);
         max_length += STRLEN (format->pre_token[part]) * num_tok;
         max_length += STRLEN (format->post_token[part]) * num_tok;
         max_length += num_tok + 1;     /* one join char per token, plus */
                                        /* join char to next part */

         /* 
          * We ignore abbreviation here -- just overestimates the maximum
          * length, so no big deal.  Also saves us the bother of computing
          * the physical length of the prefix of virtual length 1.
          */
         for (j = 0; j < num_tok; j++)
            max_length += STRLEN (tok[j]);
      }

   } /* for i (loop over parts) */

   return max_length;

} /* format_firstpass() */


/* ------------------------------------------------------------------------
@NAME       : format_name()
@INPUT      : format
              tokens     - token list (eg. from format_firstpass())
              num_tokens - token count list (eg. from format_firstpass())
@OUTPUT     : fname      - filled in, must be preallocated by caller
@RETURNS    : 
@DESCRIPTION: Performs the second pass over a name and format, to actually
              put the name into a single string according to `format'.
@CALLS      : 
@CALLERS    : bt_format_name()
@CREATED    : 1997/11/03, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
static void
format_name (bt_name_format * format,
             char ***         tokens,
             int *            num_tokens,
             char *           fname)
{
   bt_namepart parts[BT_MAX_NAMEPARTS]; /* culled list from format */
   int         num_parts;

   int     offset;                      /* into fname */
   int     tmpoffset;
   int     i;                           /* loop over parts */
   int     j;                           /* loop over tokens */
   int     k;                           /* loop within tokens */
   bt_namepart part;
   int     prefix_len;
   int     abbrev_prefix_len;
   int     prefix_start;                /* Index where to start looking for abbrev */
   int     abbrev_prefix_start;         /* Index where to start looking for abbrev
                                           but taking into account post-part token
                                           to deal with hyphens in terse abbrevs */
   int     token_len;                   /* "physical" length (characters) */
   int     token_vlen;                  /* "virtual" length (special char */
                                        /* counts as one character) */
   boolean should_tie;
   boolean hyphen_todo;

   int     vchars_seen;
   int     depth;
   boolean in_special;
   int     utf8_length;

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
      if (tokens[part])                 /* name actually has this part */
         parts[num_parts++] = part;
   }

   offset = 0;
   token_vlen = -1;                     /* sanity check, and keeps */
                                        /* "gcc -O -Wall" happy */

   for (i = 0; i < num_parts; i++)
   {
      part = parts[i];
            
      offset += append_text (fname, offset,
                             format->pre_part[part], 0, -1);

      for (j = 0; j < num_tokens[part]; j++)
      {
	 if (!tokens[part][j]) continue; // ignore empty tokens
         offset += append_text (fname, offset, 
                                format->pre_token[part], 0, -1);

         if (format->abbrev[part])
         {
           /* Set up tracking of depth and specials so we can ignore
              hyphenated token parts within protected braces */
           vchars_seen = 0;
           depth = 0;
           in_special = FALSE;
           utf8_length = 0;

           for (k = 0 ; tokens[part][j][k] != 0; k++)
           {

             count_virtual_char (tokens[part][j], k, &vchars_seen, &depth, &in_special, &utf8_length);
             prefix_start = string_prefix_start (tokens[part][j], k);

             /* Add initial from the begining of the string or beginning of after-hyphen
                string */
             if (k == 0 || hyphen_todo)
             {
               prefix_len = string_prefix (tokens[part][j], prefix_start, 1);
               token_len = append_text (fname, offset,
                                        tokens[part][j], prefix_start, prefix_len);
               offset += token_len;
               hyphen_todo = 0;
             }
             /* Potentially add a hyphen unless in protecting braces */
             if (tokens[part][j][k] == '-' && depth == 0 && in_special == FALSE)
             {
               /* Add any post token part e. g. ('.') */
               tmpoffset = 0;
               tmpoffset = append_text (fname, offset, 
                                      format->post_token[part], 0, -1);
               offset += tmpoffset;

               /* copy the hyphen */
               tmpoffset = append_text (fname, offset,
                            tokens[part][j],
                            k, 1);
               offset += tmpoffset;

               /* Set a flag to say we need to get the post-hyphen initial */
               hyphen_todo = 1;
             }
           }
           token_vlen = 1;
         }
         else
         {
            token_len = append_text (fname, offset,
                                     tokens[part][j], 0, -1);
            offset += token_len;
            token_vlen = string_length (tokens[part][j]);
         }

         offset += append_text (fname, offset, 
                                format->post_token[part], 0, -1);

         /* join to next token, but only if there is a next token! */
         if (j < num_tokens[part]-1)    
         {
            should_tie = (num_tokens[part] > 1)
               && (((j == 0) && (token_vlen < 3))
                   || (j == num_tokens[part]-2));
            offset += append_join (fname, offset,
                                   format->join_tokens[part], should_tie);
         }

      } /* for j */

      offset += append_text (fname, offset,
                             format->post_part[part], 0, -1);
      /* join to the next part, but again only if there is a next part */
      if (i < num_parts-1)
      {
         if (token_vlen == -1)
         {
            internal_error ("token_vlen uninitialized -- no tokens in a part "
                            "that I checked existed");
         }
         should_tie = (num_tokens[part] == 1 && token_vlen < 3);
         offset += append_join (fname, offset,
                                format->join_part[part], should_tie);
      }

   } /* for i (loop over parts) */

   fname[offset] = 0;

} /* format_name () */


#if DEBUG

#define STATIC                          /* so BibTeX.xs can call 'em too */

/* borrowed print_tokens() and dump_name() from t/name_test.c */
STATIC void
print_tokens (char *partname, char **tokens, int num_tokens)
{
   int  i;

   if (tokens)
   {
      printf ("%s = (", partname);
      for (i = 0; i < num_tokens; i++)
      {
         printf ("%s%c", tokens[i], i == num_tokens-1 ? ')' : '|');
      }
      putchar ('\n');
   }
}


STATIC void
dump_name (bt_name * name)
{
   if (name == NULL)
   {
      printf (" name: null\n");
      return;
   }

   if (name->tokens == NULL)
   {
      printf (" name: null token list\n");
      return;
   }

   printf (" name (%p):\n", name);
   printf ("  total number of tokens = %d\n", name->tokens->num_items);
   print_tokens ("  first", name->parts[BTN_FIRST], name->part_len[BTN_FIRST]);
   print_tokens ("  von", name->parts[BTN_VON], name->part_len[BTN_VON]);
   print_tokens ("  last", name->parts[BTN_LAST], name->part_len[BTN_LAST]);
   print_tokens ("  jr", name->parts[BTN_JR], name->part_len[BTN_JR]);
}


STATIC void
dump_format (bt_name_format * format)
{
   int      i;
   static char * nameparts[] = { "first", "von", "last", "jr" };
   static char * joinmethods[] = {"may tie", "space", "force tie", "nothing"};

   printf (" name format (%p):\n", format);
   printf ("  order:");
   for (i = 0; i < format->num_parts; i++)
      printf (" %s", nameparts[format->parts[i]]);
   printf ("\n");
      
   for (i = 0; i < BT_MAX_NAMEPARTS; i++)
   {
      int j;
      for (j = 0; j < format->num_parts; j++)
        if (i == format->parts[j])
          break; 
      if (j == format->num_parts) continue;

      printf ("  %-5s: pre-part=%p (%s), post-part=%p (%s)\n",
              nameparts[i], 
              format->pre_part[i], format->pre_part[i], 
              format->post_part[i], format->post_part[i]);
      printf ("  %-5s  pre-token=%p (%s), post-token=%p (%s)\n",
              "", 
              format->pre_token[i], format->pre_token[i], 
              format->post_token[i],format->post_token[i]);
      printf ("  %-5s  abbrev=%s, join_tokens=%s, join_parts=%s\n",
              "",
              format->abbrev[i] ? "yes" : "no",
              joinmethods[format->join_tokens[i]],
              joinmethods[format->join_part[i]]);
   }
}
#endif


/* ------------------------------------------------------------------------
@NAME       : bt_format_name()
@INPUT      : name
              format
@OUTPUT     : 
@RETURNS    : formatted name (allocated with malloc(); caller must free() it)
@DESCRIPTION: Formats an already-split name according to a pre-constructed
              format structure.
@GLOBALS    : 
@CALLS      : format_firstpass(), format_name()
@CALLERS    : 
@CREATED    : 1997/11/03, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
char *
bt_format_name (bt_name *        name,
                bt_name_format * format)
{
   unsigned max_length;
   char *   fname;

#if DEBUG >= 2
   printf ("bt_format_name():\n");
   dump_name (name);
   dump_format (format);
#endif

   max_length = format_firstpass (name, format);
   fname = (char *) malloc ((max_length+1) * sizeof (char));
#if 0
   memset (fname, '_', max_length);
   fname[max_length] = 0;
#endif
   format_name (format, name->parts, name->part_len, fname);
   assert (strlen (fname) <= max_length);
   return fname;

} /* bt_format_name() */
