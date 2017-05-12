/* ------------------------------------------------------------------------
@NAME       : btxs_support.c
@DESCRIPTION: Support functions needed by the XSUBs in BibTeX.xs.
@GLOBALS    : 
@CREATED    : 1997/11/16, Greg Ward (from code in BibTeX.xs)
@MODIFIED   : 
@VERSION    : $Id$
@COPYRIGHT  : Copyright (c) 1997-2000 by Gregory P. Ward.  All rights reserved.
-------------------------------------------------------------------------- */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define BT_DEBUG 0

#include "btparse.h"
#include "btxs_support.h"


static char *nodetype_names[] = 
{
   "entry", "macrodef", "text", "key", "field", "string", "number", "macro"
};


/* ----------------------------------------------------------------------
 * Miscellaneous stuff
 */

int
constant (char * name, IV * arg)
{
   int   ok = FALSE;

   DBG_ACTION (1, printf ("constant: name=%s\n", name));

   if (! (name[0] == 'B' && name[1] == 'T')) /* should not happen! */
      croak ("Illegal constant name \"%s\"", name);

   switch (name[2])
   {
      case 'E':                         /* entry metatypes */
         if (strEQ (name, "BTE_UNKNOWN"))  { *arg = BTE_UNKNOWN;  ok = TRUE; }
         if (strEQ (name, "BTE_REGULAR"))  { *arg = BTE_REGULAR;  ok = TRUE; }
         if (strEQ (name, "BTE_COMMENT"))  { *arg = BTE_COMMENT;  ok = TRUE; }
         if (strEQ (name, "BTE_PREAMBLE")) { *arg = BTE_PREAMBLE; ok = TRUE; }
         if (strEQ (name, "BTE_MACRODEF")) { *arg = BTE_MACRODEF; ok = TRUE; }
         break;
      case 'A':                         /* AST nodetypes (not all of them) */
         if (strEQ (name, "BTAST_STRING")) { *arg = BTAST_STRING; ok = TRUE; }
         if (strEQ (name, "BTAST_NUMBER")) { *arg = BTAST_NUMBER; ok = TRUE; }
         if (strEQ (name, "BTAST_MACRO"))  { *arg = BTAST_MACRO;  ok = TRUE; }
         break;
      case 'N':                         /* name parts */
         if (strEQ (name, "BTN_FIRST")) { *arg = BTN_FIRST; ok = TRUE; }
         if (strEQ (name, "BTN_VON"))   { *arg = BTN_VON;   ok = TRUE; }
         if (strEQ (name, "BTN_LAST"))  { *arg = BTN_LAST;  ok = TRUE; }
         if (strEQ (name, "BTN_JR"))    { *arg = BTN_JR;    ok = TRUE; }
         if (strEQ (name, "BTN_NONE"))  { *arg = BTN_NONE;  ok = TRUE; }
         break;
      case 'J':                         /* token join methods */
         if (strEQ (name, "BTJ_MAYTIE"))   { *arg = BTJ_MAYTIE;   ok = TRUE; }
         if (strEQ (name, "BTJ_SPACE"))    { *arg = BTJ_SPACE;    ok = TRUE; }
         if (strEQ (name, "BTJ_FORCETIE")) { *arg = BTJ_FORCETIE; ok = TRUE; }
         if (strEQ (name, "BTJ_NOTHING"))  { *arg = BTJ_NOTHING;  ok = TRUE; }
         break;
      default:
         break;
   }

   return ok;
}


/* ----------------------------------------------------------------------
 * Stuff for converting a btparse entry AST to a Perl structure:
 *   convert_value() [private]
 *   convert_assigned_entry() [private]
 *   convert_value_entry() [private]
 *   ast_to_hash()
 */

static SV *
convert_value (char * field_name, AST * field, boolean preserve)
{
   AST *  value;
   bt_nodetype 
          nodetype;
   char * text;
   SV *   sv_field_value;

   value = bt_next_value (field, NULL, &nodetype, &text);
   if (preserve)
   {
      HV * val_stash;                   /* stash for Text::BibTeX::Value pkg */
      HV * sval_stash;                  /* and for Text::BibTeX::SimpleValue */
      AV * compound_value;              /* list of simple values */
      SV * sval_contents[2];            /* type and text */
      AV * simple_value;                /* list of (type, text) */
      SV * simple_value_ref;            /* ref to simple_value */

      /* 
       * Get the stashes for the two classes into which we'll be 
       * blessing things.
       */
      val_stash  = gv_stashpv ("Text::BibTeX::Value",       TRUE);
      sval_stash = gv_stashpv ("Text::BibTeX::SimpleValue", TRUE);

      if (val_stash == NULL || sval_stash == NULL) {
          croak ("unable to get stash for one or both of " 
                 "Text::BibTeX::Value or Text::BibTeX::SimpleValue");
      }

      /* Start the compound value as an empty list */
      compound_value = newAV ();

      /* Walk the list of simple values */
      while (value)
      {
         /* 
          * Convert the nodetype and text to SVs and save them in what will
          * soon become a Text::BibTeX::SimpleValue object.
          */
         sval_contents[0] = newSViv ((IV) nodetype);
         sval_contents[1] = newSVpv (text, 0);
         simple_value = av_make (2, sval_contents);

         /* 
          * We're done with these two SVs (they're saved in the
          * simple_value AV), so decrement them out of existence
          */
         SvREFCNT_dec (sval_contents[0]);
         SvREFCNT_dec (sval_contents[1]);

         /* Create the SimpleValue object by blessing a reference */
         simple_value_ref = newRV_noinc ((SV *) simple_value);
         sv_bless (simple_value_ref, sval_stash);

         /* Push this SimpleValue object onto the main list */
         av_push (compound_value, simple_value_ref);

         /* And find the next simple value in this field */
         value = bt_next_value (field, value, &nodetype, &text);
      }

      /* Make a Text::BibTeX::Value object from our list of SimpleValues */
      sv_field_value  = newRV_noinc ((SV *) compound_value);
      sv_bless (sv_field_value, val_stash);
   }
   else
   {
      if (value &&
          (nodetype != BTAST_STRING ||
           bt_next_value (field, value, NULL, NULL) != NULL))
      {
         croak ("BibTeX.xs: internal error in entry post-processing--"
                "value for field %s is not a simple string", 
                field_name);
      }

      DBG_ACTION (2, printf ("  field=%s, value=\"%s\"\n", 
                             field_name, text));
      sv_field_value = text ? newSVpv (text, 0) : &PL_sv_undef;
   }

   return sv_field_value;
}  /* convert_value () */


static void
convert_assigned_entry (AST *top, HV *entry, boolean preserve)
{
   AV *    flist;                 /* the field list -- put into entry */
   HV *    values;                /* the field values -- put into entry */
   HV *    lines;                 /* line numbers of entry and its fields */
   AST *   field;
   char *  field_name;
   AST *   item;
   char *  item_text;
   int     prev_line;

   /*
    * Start the line number hash.  It will contain (num_fields)+2 elements;
    * one for each field (keyed on the field name), and the `start' and
    * `stop' lines for the entry as a whole.  (Currently, the `stop' line
    * number is the same as the line number of the last field.  This isn't
    * strictly correct, but by the time we get our hands on the AST, that
    * closing brace or parenthesis is long lost -- so this is the best we
    * get.  I just want to put this redundant line number in in case some
    * day I get ambitious and keep track of its true value.)
    */

   lines = newHV ();
   hv_store (lines, "START", 5, newSViv (top->line), 0);

   /* 
    * Now loop over all fields in the entry.   As we loop, we build 
    * three structures: the list of field names, the hash relating
    * field names to (fully expanded) values, and the list of line 
    * numbers.
    */
   
   DBG_ACTION (2, printf ("  creating field list, value hash\n"));
   flist = newAV ();
   values = newHV ();

   DBG_ACTION (2, printf ("  getting fields and values\n"));
   field = bt_next_field (top, NULL, &field_name);
   while (field)
   {
      SV *   sv_field_name;
      SV *   sv_field_value;

      if (!field_name)                  /* this shouldn't happen -- but if */
         continue;                      /* it does, skipping the field seems */
                                        /* reasonable to me */

      /* Convert the field name to an SV (for storing in the entry hash) */
      sv_field_name = newSVpv (field_name, 0);

      /* 
       * Convert the field value to an SV; this might be just a string, or
       * it might be a reference to a Text::BibTeX::Value object (if
       * 'preserve' is true).
       */
      sv_field_value = convert_value (field_name, field, preserve);

      /* 
       * Push the field name onto the field list, add the field value to
       * the values hash, and add the line number onto the line number
       * hash.
       */
      av_push (flist, sv_field_name);
      hv_store (values, field_name, strlen (field_name), sv_field_value, 0);
      hv_store (lines, field_name, strlen (field_name),
                newSViv (field->line), 0);
      prev_line = field->line;          /* so we can duplicate last line no. */

      field = bt_next_field (top, field, &field_name);
      DBG_ACTION (2, printf ("  stored field/value; next will be %s\n",
                             field_name));
   }


   /* 
    * Duplicate the last element of `lines' (kludge until we keep track of
    * the true end-of-entry line number).
    */
   hv_store (lines, "STOP", 4, newSViv (prev_line), 0);


   /* Put refs to field list, value hash, and line list into the main hash */

   DBG_ACTION (2, printf ("  got all fields; storing list/hash refs\n"));
   hv_store (entry, "fields", 6, newRV ((SV *) flist), 0);
   hv_store (entry, "values", 6, newRV ((SV *) values), 0);
   hv_store (entry, "lines", 5, newRV ((SV *) lines), 0);

} /* convert_assigned_entry () */


static void
convert_value_entry (AST *top, HV *entry, boolean preserve)
{
   HV *    lines;                 /* line numbers of entry and its fields */
   AST *   item,
       *   prev_item = NULL;
   int     last_line;
   char *  value;
   SV *    sv_value;

   /* 
    * Start the line number hash.  For "value" entries, it's a bit simpler --
    * just a `start' and `stop' line number.  Again, the `stop' line is
    * inaccurate; it's just the line number of the last value in the
    * entry.
    */
   lines = newHV ();
   hv_store (lines, "START", 5, newSViv (top->line), 0);

   /* Walk the list of values to find the last one (for its line number) */
   item = NULL;
   while ((item = bt_next_value (top, item, NULL, NULL)))
      prev_item = item;
  
   if (prev_item) {
      last_line = prev_item->line;
      hv_store (lines, "STOP", 4, newSViv (last_line), 0);

      /* Store the line number hash in the entry hash */
      hv_store (entry, "lines", 5, newRV ((SV *) lines), 0);
   }

   /* And get the value of the entry as a single string (fully processed) */

   if (preserve)
   {
      sv_value = convert_value (NULL, top, TRUE);
   }
   else
   {
      value = bt_get_text (top);
      sv_value = value ? newSVpv (value, 0) : &PL_sv_undef;
   }
   hv_store (entry, "value", 5, sv_value, 0);

} /* convert_value_entry () */


void 
ast_to_hash (SV *    entry_ref, 
             AST *   top,
             boolean parse_status,
             boolean preserve)
{
   char *  type;
   char *  key;
   bt_metatype 
           metatype;
   btshort options;                     /* post-processing options */
   HV *    entry;                       /* the main hash -- build and return */

   DBG_ACTION (1, printf ("ast_to_hash: entry\n"));

   /* printf ("checking that entry_ref is a ref and a hash ref\n"); */
   if (! (SvROK (entry_ref) && (SvTYPE (SvRV (entry_ref)) == SVt_PVHV)))
      croak ("entry_ref must be a hash ref");
   entry = (HV *) SvRV (entry_ref);

   /* 
    * Clear out all hash values that might not be replaced in this
    * conversion (in case the user parses into an existing
    * Text::BibTeX::Entry object).  (We don't blow the hash away with
    * hv_clear() in case higher-up code has put interesting stuff into it.)
    */

   hv_delete (entry, "key",    3, G_DISCARD);
   hv_delete (entry, "fields", 6, G_DISCARD);
   hv_delete (entry, "lines",  5, G_DISCARD);
   hv_delete (entry, "values", 6, G_DISCARD);
   hv_delete (entry, "value",  5, G_DISCARD);

   /*
    * Perform entry post-processing.  How exactly we post-process depends on
    * 1) the entry type, and 2) the 'preserve' flag.  
    */

   metatype = bt_entry_metatype (top);
   if (preserve)                        /* if true, then entry type */
   {                                    /* doesn't matter */
      options = BTO_MINIMAL;
   }
   else
   {
      if (metatype == BTE_MACRODEF)
         options = BTO_MACRO;
      else
         options = BTO_FULL;
   }

   /* 
    * Postprocess the entry, with the string-processing options we just
    * determined plus "no store macros" turned on.  (That's because
    * macros will already have been stored by the postprocessing done
    * by bt_parse*; we don't want to do it again and generate spurious
    * warnings!
    */
   bt_postprocess_entry (top, options | BTO_NOSTORE);


   /* 
    * Start filling in the hash; all entries have a type and metatype,
    * and we'll do the key here (even though it's not in all entries)
    * for good measure.
    */

   type = bt_entry_type (top);
   key = bt_entry_key (top);
   DBG_ACTION (2, printf ("  inserting type (%s), metatype (%d)\n",
                          type ? type : "*none*", bt_entry_metatype (top)));
   DBG_ACTION (2, printf ("        ... key (%s) status (%d)\n",
                          key ? key : "*none*", parse_status));

   if (!type)
      croak ("entry has no type");
   hv_store (entry, "type", 4, newSVpv (type, 0), 0);
   hv_store (entry, "metatype", 8, newSViv (bt_entry_metatype (top)), 0);

   if (key)
      hv_store (entry, "key", 3, newSVpv (key, 0), 0);

   hv_store (entry, "status", 6, newSViv ((IV) parse_status), 0);


   switch (metatype)
   {
      case BTE_MACRODEF:
      case BTE_REGULAR:
         convert_assigned_entry (top, entry, preserve);
         break;

      case BTE_COMMENT:
      case BTE_PREAMBLE:
         convert_value_entry (top, entry, preserve);
         break;

      default:                          /* this should never happen! */
         croak ("unknown entry metatype (%d)\n", bt_entry_metatype (top));
   }

   /* 
    * If 'preserve' was true, then the user is going to need the 
    * Text::BibTeX::Value module!
    *
    * XXX this doesn't work!  Why?!?!
    */
/*
   if (preserve)
   {
      printf ("requiring Text::BibTeX::Value...\n");
      perl_require_pv ("Text::BibTeX::Value");
   }
*/

   /* And finally, free up the AST */

   bt_free_ast (top);

/*   hv_store (entry, "ast", 3, newSViv ((IV) top), 0); */

   DBG_ACTION (1, printf ("ast_to_hash: exit\n"));
}  /* ast_to_hash () */


/* ----------------------------------------------------------------------
 * Stuff for converting a list of C strings to Perl
 *   convert_stringlist()   [private]
 *   store_stringlist()
 */

static SV *
convert_stringlist (char **list, int num_strings)
{
   int    i;
   AV *   perl_list;
   SV *   sv_string;

   perl_list = newAV ();
   for (i = 0; i < num_strings; i++)
   {
      sv_string = newSVpv (list[i], 0);
      av_push (perl_list, sv_string);
   }

   return newRV ((SV *) perl_list);

} /* convert_stringlist() */


void
store_stringlist (HV *hash, char *key, char **list, int num_strings)
{
   SV *  listref;

   if (list)
   {
      DBG_ACTION (2,
      {
         int i;

         printf ("store_stringlist(): hash=%p, key=%s, list=(", 
                 hash, key);
         for (i = 0; i < num_strings; i++)
            printf ("%s%c", list[i], (i == num_strings-1) ? ')' : ',');
         printf ("\n");
      })
                 
      listref = convert_stringlist (list, num_strings);
      hv_store (hash, key, strlen (key), listref, 0);
   }
   else
   {
      DBG_ACTION (2, printf ("store_stringlist(): hash=%p, key=%s: deleting\n",
                             hash, key))
      hv_delete (hash, key, strlen (key), G_DISCARD);
   }

} /* store_stringlist() */
