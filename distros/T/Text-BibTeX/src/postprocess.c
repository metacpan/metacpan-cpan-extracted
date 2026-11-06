/* ------------------------------------------------------------------------
@NAME       : postprocess.c
@DESCRIPTION: Post-processing of entries once parsing is complete:
              expanding macros, pasting substrings together, converting
              numbers to strings and collapsing whitespace.
-------------------------------------------------------------------------- */

#include <stdlib.h>
#include <string.h>
#include "bt_internal.h"

/* ------------------------------------------------------------------------
@NAME       : bt_postprocess_string()
@DESCRIPTION: Returns a new copy of s with carriage returns removed and,
              if BTO_COLLAPSE is set, whitespace collapsed according to
              BibTeX rules: leading and trailing spaces removed, and runs
              of spaces reduced to one.  (The lexer has already turned
              newlines inside strings into spaces.)
-------------------------------------------------------------------------- */
char *
bt_postprocess_string (const char *s, btshort options)
{
   boolean collapse = (options & BTO_COLLAPSE) != 0;
   bt_sbuf out;
   boolean prev_space;

   if (s == NULL)
      return NULL;

   bt_sbuf_init (&out);
   bt_sbuf_grow (&out, strlen (s));
   prev_space = collapse;               /* drops leading spaces */

   for (; *s; s++)
   {
      if (*s == '\r')                   /* no Ctrl-Ms in the output */
         continue;
      if (collapse && *s == ' ')
      {
         if (prev_space)
            continue;
         prev_space = TRUE;
      }
      else
         prev_space = FALSE;
      bt_sbuf_putc (&out, *s);
   }

   if (collapse && out.len > 0 && out.s[out.len - 1] == ' ')
      out.s[--out.len] = 0;
   return bt_sbuf_steal (&out);
}


/* ------------------------------------------------------------------------
@NAME       : bt_postprocess_value()
@DESCRIPTION: Post-processes a series of simple values (strings, numbers,
              macros) joined by '#'.  If BTO_PASTE is set and there is
              more than one simple value, they are pasted into a single
              string (which requires macro expansion and number
              conversion); otherwise each simple value is processed on
              its own.

              If `replace' is true, the AST is updated in place (pasted
              values are collapsed into the first node) and NULL is
              returned.  Otherwise the AST is untouched and the processed
              string (of the last simple value, or of the pasted whole)
              is returned; the caller must free() it.
-------------------------------------------------------------------------- */
char *
bt_postprocess_value (bt_macros *macros, bt_errors *errs,
                      AST *value, btshort options, boolean replace)
{
   AST *   sv;
   boolean pasting;
   btshort string_opts;
   bt_sbuf paste;
   char *  result = NULL;

   if (value == NULL)
      return NULL;
   if (value->nodetype != BTAST_STRING &&
       value->nodetype != BTAST_NUMBER &&
       value->nodetype != BTAST_MACRO)
   {
      bt_report (errs, BTERR_USAGEERR, NULL, -1, NULL, -1,
                 "bt_postprocess_value: invalid AST node (not a value)");
      return NULL;
   }

   pasting = (options & BTO_PASTE) && value->right;

   /* Never collapse whitespace in the pieces of a pasted string -- only
    * in the whole thing, once it has been put together. */
   string_opts = pasting ? (options & ~BTO_COLLAPSE) : options;

   if (pasting && ! (options & (BTO_CONVERT | BTO_EXPAND)))
   {
      bt_report (errs, BTERR_USAGEERR, NULL, -1, NULL, -1,
                 "bt_postprocess_value(): must convert numbers and expand "
                 "macros when pasting substrings");
      return NULL;
   }

   bt_sbuf_init (&paste);

   for (sv = value; sv; sv = sv->right)
   {
      char *  tmp = NULL;
      boolean free_tmp = FALSE;

      if (sv->nodetype == BTAST_MACRO && (options & BTO_EXPAND))
      {
         const char * text = bt_macro_text (macros, errs, sv->text,
                                            sv->filename, sv->line);
         tmp = bt_postprocess_string (text, string_opts);
         free_tmp = TRUE;
         if (replace)
         {
            sv->nodetype = BTAST_STRING;
            free (sv->text);
            sv->text = tmp;             /* NULL if the macro is undefined */
            free_tmp = FALSE;
         }
      }
      else if (sv->nodetype == BTAST_STRING && sv->text)
      {
         tmp = bt_postprocess_string (sv->text, string_opts);
         if (replace)
         {
            free (sv->text);
            sv->text = tmp;
         }
         else
            free_tmp = TRUE;
      }
      else if (sv->nodetype == BTAST_NUMBER)
      {
         if (replace && (options & BTO_CONVERT))
            sv->nodetype = BTAST_STRING;
         tmp = sv->text;
      }

      if (pasting)
         bt_sbuf_puts (&paste, tmp);
      else if (!replace)
      {
         free (result);
         result = bt_xstrdup (tmp ? tmp : "");
      }
      if (free_tmp)
         free (tmp);
   }

   if (pasting)
   {
      char * whole = bt_postprocess_string (paste.s ? paste.s : "", options);

      bt_sbuf_free (&paste);
      if (!replace)
         return whole;

      bt_free_ast (value->right);       /* free from 2nd simple value on */
      value->right = NULL;
      free (value->text);
      value->text = whole;
      value->nodetype = BTAST_STRING;
      return NULL;
   }

   return result;
}


/* ------------------------------------------------------------------------
@NAME       : bt_postprocess_field()
@DESCRIPTION: Lowercases the field name and post-processes its value.
-------------------------------------------------------------------------- */
char *
bt_postprocess_field (bt_macros *macros, bt_errors *errs,
                      AST *field, btshort options, boolean replace)
{
   if (field == NULL)
      return NULL;
   if (field->nodetype != BTAST_FIELD)
   {
      bt_report (errs, BTERR_USAGEERR, NULL, -1, NULL, -1,
                 "bt_postprocess_field: invalid AST node (not a field)");
      return NULL;
   }

   if (replace)
   {
      char * lc = bt_uni_map_string (field->text, BT_CASE_LOWER);
      free (field->text);
      field->text = lc;
   }
   return bt_postprocess_value (macros, errs, field->down, options, replace);
}


/* ------------------------------------------------------------------------
@NAME       : bt_postprocess_entry()
@DESCRIPTION: Post-processes all the fields of an entry, and (unless
              BTO_NOSTORE is set) stores the macros defined by an @string
              entry.
-------------------------------------------------------------------------- */
void
bt_postprocess_entry (bt_macros *macros, bt_errors *errs,
                      AST *top, btshort options)
{
   AST * cur;

   if (top == NULL)
      return;
   if (top->nodetype != BTAST_ENTRY)
   {
      bt_report (errs, BTERR_USAGEERR, NULL, -1, NULL, -1,
                 "bt_postprocess_entry: invalid node type (not entry root)");
      return;
   }

   if (top->text)
   {
      char * lc = bt_uni_map_string (top->text, BT_CASE_LOWER);
      free (top->text);
      top->text = lc;
   }

   cur = top->down;
   if (cur && cur->nodetype == BTAST_KEY)
      cur = cur->right;
   if (cur == NULL)
      return;

   switch (top->metatype)
   {
      case BTE_REGULAR:
      case BTE_MACRODEF:
         for (; cur; cur = cur->right)
         {
            bt_postprocess_field (macros, errs, cur, options, TRUE);
            if (top->metatype == BTE_MACRODEF && ! (options & BTO_NOSTORE))
               bt_add_macro_value (macros, errs, cur, options);
         }
         break;
      case BTE_COMMENT:
      case BTE_PREAMBLE:
         bt_postprocess_value (macros, errs, cur, options, TRUE);
         break;
      default:
         bt_report (errs, BTERR_INTERNAL, NULL, -1, NULL, -1,
                    "bt_postprocess_entry: unknown entry metatype (%d)",
                    (int) top->metatype);
   }
}
