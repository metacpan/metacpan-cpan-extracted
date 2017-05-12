/* ------------------------------------------------------------------------
@NAME       : BibTeX.xs
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Glue between my `btparse' library and the Perl module
              Text::BibTeX.  Provides the following functions to Perl:
                 Text::BibTeX::constant
                 Text::BibTeX::initialize
                 Text::BibTeX::cleanup
                 Text::BibTeX::split_list
                 Text::BibTeX::purify_string
                 Text::BibTeX::Entry::_parse_s
                 Text::BibTeX::Entry::_parse
                 Text::BibTeX::Name::split
                 Text::BibTeX::Name::free
                 Text::BibTeX::add_macro_text
                 Text::BibTeX::delete_macro
                 Text::BibTeX::delete_all_macros
                 Text::BibTeX::macro_length
                 Text::BibTeX::macro_text
@GLOBALS    : 
@CALLS      : 
@CREATED    : Jan/Feb 1997, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: BibTeX.xs 7399 2009-06-01 21:22:51Z ambs $
-------------------------------------------------------------------------- */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define BT_DEBUG 0

#include "btparse.h"
#include "btxs_support.h"


MODULE = Text::BibTeX           PACKAGE = Text::BibTeX

# XSUBs with no corresponding functions in the C library (hence no prefix
# for this section):
#    constant

SV *
constant(name)
char *   name
        CODE:
	IV i;
	if (constant(name, &i))
	    ST(0) = sv_2mortal(newSViv(i));
	else
	    ST(0) = &PL_sv_undef;


MODULE = Text::BibTeX           PACKAGE = Text::BibTeX          PREFIX = bt_

# XSUBs that consist solely of calls to corresponding C functions in the
# library:
#    initialize
#    cleanup

void
bt_initialize()

void
bt_cleanup()


# XSUBs that still go right into the Text::BibTeX package (ie. they don't
# really belong in one of the subsidiary packages), but need a bit of work
# to convert the C data to Perl form:
#    split_list
#    purify_string

void
bt_isplit_list (string, delim, filename=NULL, line=0, description=NULL)

    char *   string
    char *   delim
    char *   filename
    int      line
    char *   description

    PREINIT:
       bt_stringlist *
             names;
       int   i;
       SV *  sv_name;

    PPCODE:
       names = bt_split_list (string, delim, filename, line, description);
       if (names == NULL)
          XSRETURN_EMPTY;       /* return empty list to perl */

       EXTEND (sp, names->num_items);
       for (i = 0; i < names->num_items; i++)
       {
          if (names->items[i] == NULL)
             sv_name = &PL_sv_undef;
          else
             sv_name = sv_2mortal (newSVpv (names->items[i], 0));

          PUSHs (sv_name);
       }

       bt_free_list (names);


SV *
bt_purify_string (instr, options=0)

    char *  instr
    int     options

    CODE:
       if (instr == NULL)               /* undef in, undef out */
          XSRETURN_EMPTY;
       RETVAL = newSVpv (instr, 0);
       bt_purify_string (SvPVX (RETVAL), (btshort) options);
       SvCUR_set (RETVAL, strlen (SvPVX (RETVAL))); /* reset SV's length */

    OUTPUT:
       RETVAL


# Here's an alternate formulation of `purify_string' that acts more like
# the C function (and less like nice Perl): it modifies the input string
# in place, and returns nothing.  In addition to being weird Perl,
# this contradicts the documentation.  And it would be impossible
# to replicate this behaviour in a similar Python extension... all
# round, a bad idea!

## void
## bt_purify_string (str, options=0)

##     char * str
##     int    options

##     CODE:
##        if (str != NULL) 
##           bt_purify_string (str, (btshort) options);
##           sv_setpv (ST(0), str);


SV *
bt_change_case (transform, string, options=0)
    char   transform
    char * string
    int    options

    CODE:
       DBG_ACTION
          (1, printf ("XSUB change_case: transform=%c, string=%p (%s)\n",
                      transform, string, string))                  
       if (string == NULL)
          XSRETURN_EMPTY;
       RETVAL = newSVpv (string, 0);
       bt_change_case (transform, SvPVX (RETVAL), (btshort) options);

    OUTPUT:
       RETVAL




MODULE = Text::BibTeX   	PACKAGE = Text::BibTeX::Entry

# The two XSUBs that go to the Text::BibTeX::Entry package; both rely on
# ast_to_hash() to do the appropriate "convert to Perl form" work:
#    _parse
#    _parse_s
# These XSUBs reset the internal parser states:
#    _reset_parse
#    _reset_parse_s

int
_parse (entry_ref, filename, file, preserve=FALSE)
    SV *    entry_ref;
    char *  filename;
    FILE *  file;
    boolean preserve;

    PREINIT:
        btshort  options = 0;
        boolean status;
        AST *   top;

    CODE:

        top = bt_parse_entry (file, filename, options, &status);
        DBG_ACTION 
           (2, dump_ast ("BibTeX.xs:parse: AST from bt_parse_entry():\n", top))

        if (!top)                  /* at EOF -- return false to perl */
        {
           XSRETURN_NO;
        }

        ast_to_hash (entry_ref, top, status, preserve);
        XSRETURN_YES;              /* OK -- return true to perl */


int
_reset_parse ()

    PREINIT:
        btshort  options = 0;
        boolean status;

    CODE:

        bt_parse_entry (NULL, NULL, options, &status);

        XSRETURN_NO;              /* cleanup -- return false to perl */


int
_parse_s (entry_ref, text, preserve=FALSE)
    SV *    entry_ref;
    char *  text;
    boolean preserve;

    PREINIT:
        btshort  options = 0;
        boolean status;
        AST *   top;

    CODE:

        top = bt_parse_entry_s (text, NULL, 1, options, &status);
        if (!top)                  /* no entry found -- return false to perl */
        {
           XSRETURN_NO;
        }

        ast_to_hash (entry_ref, top, status, preserve);
        XSRETURN_YES;              /* OK -- return true to perl */


int
_reset_parse_s ()

    PREINIT:
        btshort  options = 0;
        boolean status;

    CODE:

        bt_parse_entry_s (NULL, NULL, 1, options, &status);

        XSRETURN_NO;              /* cleanup -- return false to perl */


MODULE = Text::BibTeX           PACKAGE = Text::BibTeX::Name

# The XSUBs that go in the Text::BibTeX::Name package (ie. that operate
# on name objects):
#    split
#    free

#if BT_DEBUG

void
dump_name (hashref)
    SV *   hashref

    PREINIT:
       HV *       hash;
       SV **      sv_name;
       bt_name  * name;

    CODE:
       hash = (HV *) SvRV (hashref);
       sv_name = hv_fetch (hash, "_cstruct", 8, 0);
       if (! sv_name)
       {
          warn ("Name::dump: no _cstruct member in hash");
       }
       else
       { 
          name = (bt_name *) SvIV (*sv_name);
          dump_name (name);             /* currently in format_name.c */
       }

#endif


void
_split (name_hashref, name, filename, line, name_num, keep_cstruct)

    SV *    name_hashref
    char *  name
    char *  filename
    int     line
    int     name_num
    int     keep_cstruct

    PREINIT:
       HV *      name_hash;
       SV *      sv_old_name;
       bt_name * old_name;
       bt_name * name_split;

    CODE:
       if (! (SvROK (name_hashref) && 
              SvTYPE (SvRV (name_hashref)) == SVt_PVHV))
          croak ("name_hashref is not a hash reference");
       name_hash = (HV *) SvRV (name_hashref);

       DBG_ACTION (1, 
       {
          printf ("XS Name::_split:\n");
          printf ("  name_hashref=%p, name_hash=%p\n", 
                  (void *) name_hashref, (void *) name_hash);
          printf ("  name=%p (%s), filename=%p (%s)\n",
                  name, name, filename, filename);
          printf ("  line=%d, name_num=%d, keep_cstruct=%d\n",
                  line, name_num, keep_cstruct);
       })

       sv_old_name = hv_delete (name_hash, "_cstruct", 8, 0);
       if (sv_old_name)
       {
          old_name = (bt_name *) SvIV (sv_old_name);
          DBG_ACTION
             (1, printf ("XS Name::_split: name hash had old C structure "
                         "(%d tokens, first was >%s<) -- freeing it\n",
                         old_name->tokens->num_items,
                         old_name->tokens->items[0]))
          bt_free_name (old_name);
       }

       name_split = bt_split_name (name, filename, line, name_num);
       DBG_ACTION (1, printf ("XS Name::_split: back from bt_split_name, "
                              "calling store_stringlist x 4\n"))

       store_stringlist (name_hash, "first", 
                         name_split->parts[BTN_FIRST],
                         name_split->part_len[BTN_FIRST]);
       store_stringlist (name_hash, "von", 
                         name_split->parts[BTN_VON],
                         name_split->part_len[BTN_VON]);
       store_stringlist (name_hash, "last", 
                         name_split->parts[BTN_LAST],
                         name_split->part_len[BTN_LAST]);
       store_stringlist (name_hash, "jr", 
                         name_split->parts[BTN_JR],
                         name_split->part_len[BTN_JR]);

       DBG_ACTION (1, 
       {
          char ** last = name_split->parts[BTN_LAST];
          char ** first = name_split->parts[BTN_FIRST];
              
          printf ("XS Name::_split: name has %d tokens; "
                 "last[0]=%s, first[0]=%s\n",
                 name_split->tokens->num_items,
                 last ? last[0] : "*no last name*",
                 first ? first[0] : "*no first name*");
       })

       if (keep_cstruct)
       {
          hv_store (name_hash, "_cstruct", 8, newSViv ((IV) name_split), 0);
          DBG_ACTION 
             (1, printf ("XS Name::_split: storing pointer to structure %p\n", 
                         name_split))
       }
       else
       {
          bt_free_name (name_split);
       }


void
free (name_hashref)
    SV *   name_hashref

    PREINIT:
       HV *      name_hash;
       SV **     sv_name;
       bt_name * name;

    CODE:
       name_hash = (HV *) SvRV (name_hashref);
       sv_name = hv_fetch (name_hash, "_cstruct", 8, 0);
       if (sv_name != NULL)
       {
          name = (bt_name *) SvIV (*sv_name);
          DBG_ACTION (1, printf ("XS Name::free: freeing name %p\n", name))
          bt_free_name (name);
       }
#if BT_DEBUG >= 1
       else
       {
          printf ("XS Name::free: no C structure to free!\n");
       }
#endif


MODULE = Text::BibTeX           PACKAGE = Text::BibTeX::NameFormat

IV
create (parts="fvlj", abbrev_first=FALSE)
    char * parts
    bool   abbrev_first

    PREINIT:

    CODE:
       DBG_ACTION 
          (1, printf ("XS NameFormat::create: "
                      "creating name format: parts=\"%s\", abbrev=%d\n",
                      parts, abbrev_first));
       RETVAL = (IV) bt_create_name_format (parts, abbrev_first);

    OUTPUT:
       RETVAL


void
free (format)
    bt_name_format * format

    CODE:
       bt_free_name_format ((bt_name_format *) format);


#if BT_DEBUG

void
dump_format (hashref)
    SV *   hashref

    PREINIT:
       HV *             hash;
       SV **            sv_format;
       bt_name_format * format;

    CODE: 
       hash = (HV *) SvRV (hashref);
       sv_format = hv_fetch (hash, "_cstruct", 8, 0);
       if (! sv_format)
       {
          warn ("NameFormat::dump: no _cstruct member in hash");
       }
       else
       { 
          format = (bt_name_format *) SvIV (*sv_format);
          dump_format (format);         /* currently in format_name.c */
       }

#endif


void
_set_text (format, part, pre_part, post_part, pre_token, post_token)
    bt_name_format * format
    bt_namepart      part
    char *           pre_part
    char *           post_part
    char *           pre_token
    char *           post_token

    CODE:
#if BT_DEBUG >= 2
    {
       static char * nameparts[] =
          { "first", "von", "last", "jr" };
       static char * joinmethods[] =
          {"may tie", "space", "force tie", "nothing"};

       printf ("XS NameFormat::_set_text:\n");
       printf ("  format=%p, namepart=%d (%s)\n", 
               format, part, nameparts[part]);
       printf ("  format currently is:\n");
       dump_format (format);
       printf ("  pre_part=%s, post_part=%s\n", pre_part, post_part);
       printf ("  pre_token=%s, post_token=%s\n", pre_token, post_token);
    }
#endif

       /*
        * No memory leak here -- just copy the pointers.  At first
        * blush, it might seem that we're opening ourselves up to
        * the possibility of dangling pointers if the Perl strings
        * that these char *'s refer to ever go away.  However, this
        * is taken care of at the Perl level -- see the comment
        * in BibTeX/NameFormat.pm, sub set_text.
        */

       bt_set_format_text (format, part,
                           pre_part, post_part, pre_token, post_token);
#if BT_DEBUG >= 2
       printf ("XS NameFormat::_set_text: after call, format is:\n");
       dump_format (format);
#endif


void
_set_options (format, part, abbrev, join_tokens, join_part)
    bt_name_format * format
    bt_namepart      part
    bool             abbrev
    bt_joinmethod    join_tokens
    bt_joinmethod    join_part

    CODE:
       DBG_ACTION (2,
          printf ("XS _set_options: format=%p, part=%d, "
                  "abbrev=%d, join_tokens=%d, join_part=%d\n",
                  format, part, abbrev, join_tokens, join_part))
       bt_set_format_options (format, part, 
                              abbrev, join_tokens, join_part);


char *
format_name (name, format)
    bt_name * name
    bt_name_format * format

    CODE:
       DBG_ACTION 
          (2, printf ("XS format_name: name=%p, format=%p\n", name, format))
       RETVAL = bt_format_name (name, format);
       DBG_ACTION
          (1, printf ("XS format_name: formatted name=%s\n", RETVAL))

    OUTPUT:
       RETVAL


MODULE = Text::BibTeX           PACKAGE = Text::BibTeX          PREFIX = bt_

void
bt_add_macro_text (macro, text, filename=NULL, line=0) 
    char * macro
    char * text
    char * filename
    int    line

void
bt_delete_macro (macro)
    char * macro

void
bt_delete_all_macros ()

int
bt_macro_length (macro)
    char * macro

char *
bt_macro_text (macro, filename=NULL, line=0)
    char * macro
    char * filename
    int    line


# This bootstrap code is used to make btparse do "minimal post-processing"
# on all entries.  That way, we can control how much is done on a per-entry
# basis by simply calling bt_postprocess_entry() ourselves.
#
# The need to do this means that btparse is somewhat brain-damaged -- I 
# should be able to specify the per-entry processing options when I call
# bt_parse_entry()!  Shouldn't be too hard to fix....
BOOT:
    bt_set_stringopts (BTE_MACRODEF, 0);
    bt_set_stringopts (BTE_REGULAR, 0);
    bt_set_stringopts (BTE_COMMENT, 0);
    bt_set_stringopts (BTE_PREAMBLE, 0);

