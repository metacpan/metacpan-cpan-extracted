/* ------------------------------------------------------------------------
@NAME       : BibTeX.xs
@DESCRIPTION: Glue between the C library (src/) and the Perl module
              Text::BibTeX.

              The C library never prints, exits or croaks: every call
              collects its errors in a bt_errors list.  Once the C work is
              done and its memory freed, the errors are turned into
              Text::BibTeX::Error objects and handed to
              Text::BibTeX::Error::_dispatch, which reports them through
              Perl's warn/die (so they can be caught, redirected or
              silenced like any other Perl warning or exception).

              Input is read through PerlIO, so any Perl filehandle works
              (layers, in-memory and tied handles included).
@CREATED    : Jan/Feb 1997, Greg Ward
-------------------------------------------------------------------------- */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "btparse.h"

/* Memory allocated by btparse must be released by btparse (bt_free() and
 * the bt_free_* functions): on Windows, free() here is Perl's allocator. */

#define MY_CXT_KEY "Text::BibTeX::_guts" XS_VERSION

typedef struct
{
   bt_macros * macros;                  /* the global macro table */
} my_cxt_t;

START_MY_CXT

/* A parser reading from a Perl filehandle */
typedef struct
{
   bt_parser * parser;
   SV *        fh;                      /* RV to the handle (we hold a ref) */
   bt_macros * private_macros;          /* NULL: use the global table */
   int         utf8;
   SV *        read_died;               /* exception thrown by a tied READ */
#ifdef MULTIPLICITY
   PerlInterpreter * perl;
#endif
} btxs_parser;

/* Wrappers for the C structures behind Name and NameFormat objects */
typedef struct { bt_name * name; } btxs_name;
typedef struct { bt_name_format * format; } btxs_format;

typedef btxs_parser * Text__BibTeX__Parser;
typedef btxs_name *   Text__BibTeX__Name__Struct;
typedef btxs_format * Text__BibTeX__NameFormat__Struct;


static void
btxs_oom (void)
{
   dTHX;
   croak ("Out of memory in Text::BibTeX");
}


/* ----------------------------------------------------------------------
 * Strings
 */

/* Text of an SV as a C string (NULL for undef), and whether it is UTF-8.
 * A UTF-8 flagged string's buffer is already UTF-8, so it never needs
 * upgrading (which would fail on read-only values). */
static const char *
sv_text_len (pTHX_ SV *sv, int *utf8, STRLEN *len)
{
   const char * s;
   STRLEN       l;

   if (utf8) *utf8 = 0;
   if (len) *len = 0;
   if (sv == NULL)
      return NULL;
   SvGETMAGIC (sv);
   if (!SvOK (sv))
      return NULL;
   s = SvPV_nomg (sv, l);
   if (utf8) *utf8 = SvUTF8 (sv) ? 1 : 0;
   if (len) *len = l;
   return s;
}

#define sv_text(sv, utf8) sv_text_len (aTHX_ sv, utf8, NULL)

/* New SV for a C string; flagged as UTF-8 if asked (and if valid) */
static SV *
new_text (pTHX_ const char *s, int utf8)
{
   STRLEN len;

   if (s == NULL)
      return newSV (0);
   len = strlen (s);
   if (utf8 && !is_utf8_string ((const U8 *) s, len))
      utf8 = 0;
   return newSVpvn_flags (s, len, utf8 ? SVf_UTF8 : 0);
}


/* ----------------------------------------------------------------------
 * Errors
 */

/* Convert errs to Text::BibTeX::Error objects, clear it, and pass them
 * (with the entry they belong to, if any) to the Perl dispatcher, which
 * may die.  Call this only when no C memory is left to free. */
static void
dispatch_errors (pTHX_ bt_errors *errs, int utf8, SV *entry_ref)
{
   dSP;
   AV *       av;
   HV *       stash;
   bt_error * e;

   if (errs->head == NULL)
      return;

   av = newAV ();
   stash = gv_stashpv ("Text::BibTeX::Error", GV_ADD);
   for (e = errs->head; e; e = e->next)
   {
      HV * hv = newHV ();
      hv_stores (hv, "errclass", newSViv (e->errclass));
      hv_stores (hv, "message", new_text (aTHX_ e->message, utf8));
      if (e->filename)
         hv_stores (hv, "filename", new_text (aTHX_ e->filename, utf8));
      if (e->line > 0)
         hv_stores (hv, "line", newSViv (e->line));
      if (e->item_desc && e->item > 0)
      {
         hv_stores (hv, "item_desc", new_text (aTHX_ e->item_desc, utf8));
         hv_stores (hv, "item", newSViv (e->item));
      }
      av_push (av, sv_bless (newRV_noinc ((SV *) hv), stash));
   }
   bt_errors_clear (errs);

   ENTER;
   SAVETMPS;
   PUSHMARK (SP);
   XPUSHs (sv_2mortal (newRV_noinc ((SV *) av)));
   XPUSHs (entry_ref ? entry_ref : &PL_sv_undef);
   PUTBACK;
   call_pv ("Text::BibTeX::Error::_dispatch", G_DISCARD);
   FREETMPS;
   LEAVE;
}


/* ----------------------------------------------------------------------
 * Reading from a Perl filehandle
 */

static long
read_tied (pTHX_ btxs_parser *xp, IO *io, MAGIC *mg, char *buf, size_t n)
{
   dSP;
   SV *  bufsv = sv_2mortal (newSVpvs (""));
   long  got = -1;
   int   count;

   ENTER;
   SAVETMPS;
   PUSHMARK (SP);
   XPUSHs (SvTIED_obj ((SV *) io, mg));
   XPUSHs (bufsv);
   XPUSHs (sv_2mortal (newSVuv (n)));
   PUTBACK;
   count = call_method ("READ", G_SCALAR | G_EVAL);
   SPAGAIN;
   if (count == 1)
   {
      SV * ret = POPs;
      if (SvTRUE (ERRSV))
      {
         if (!xp->read_died)
            xp->read_died = newSVsv (ERRSV);
      }
      else if (SvOK (ret))
      {
         STRLEN       len;
         const char * s;

         if (SvUTF8 (bufsv))
            xp->utf8 = 1;
         s = SvPV (bufsv, len);
         if (len > n)                   /* READ returned more than asked */
            len = n;
         memcpy (buf, s, len);
         got = (long) len;
      }
   }
   PUTBACK;
   FREETMPS;
   LEAVE;
   return got;
}

static long
xs_read (void *userdata, char *buf, size_t n)
{
   btxs_parser * xp = (btxs_parser *) userdata;
   IO *          io;
   MAGIC *       mg;
   PerlIO *      f;
   SSize_t       got;
#ifdef MULTIPLICITY
   PerlInterpreter * my_perl = xp->perl;
#endif

   io = GvIO ((GV *) SvRV (xp->fh));
   if (io == NULL)
      return -1;
   if ((mg = SvTIED_mg ((SV *) io, PERL_MAGIC_tiedscalar)))
      return read_tied (aTHX_ xp, io, mg, buf, n);

   f = IoIFP (io);
   if (f == NULL)
      return -1;
   got = PerlIO_read (f, buf, n);
   if (got < 0 || (got == 0 && PerlIO_error (f)))
      return -1;
   return (long) got;
}


/* ----------------------------------------------------------------------
 * Converting a btparse entry AST to a Perl structure
 */

static SV *
convert_value (pTHX_ AST *top, int preserve, int utf8)
{
   AST *        value;
   bt_nodetype  nodetype;
   char *       text;

   value = bt_next_value (top, NULL, &nodetype, &text);

   if (preserve)
   {
      HV * val_stash  = gv_stashpv ("Text::BibTeX::Value", GV_ADD);
      HV * sval_stash = gv_stashpv ("Text::BibTeX::SimpleValue", GV_ADD);
      AV * compound = newAV ();

      while (value)
      {
         AV * simple = newAV ();
         av_push (simple, newSViv ((IV) nodetype));
         av_push (simple, new_text (aTHX_ text, utf8));
         av_push (compound, sv_bless (newRV_noinc ((SV *) simple), sval_stash));
         value = bt_next_value (top, value, &nodetype, &text);
      }
      return sv_bless (newRV_noinc ((SV *) compound), val_stash);
   }

   /* After full post-processing a value is a single string (or NULL for
    * an undefined macro); if not, paste what there is. */
   if (value && value->right)
   {
      SV * sv = newSVpvs ("");
      if (utf8)
         SvUTF8_on (sv);
      for (; value; value = bt_next_value (top, value, NULL, &text))
         if (text)
            sv_catsv (sv, sv_2mortal (new_text (aTHX_ text, utf8)));
      return sv;
   }
   return text ? new_text (aTHX_ text, utf8) : newSV (0);
}

static void
convert_assigned_entry (pTHX_ AST *top, HV *entry, int preserve, int utf8)
{
   AV *   flist = newAV ();
   HV *   values = newHV ();
   HV *   lines = newHV ();
   AST *  field;
   char * field_name;
   int    last_line = top->line;

   /* The STOP line is the line of the last field (the closing brace is
    * not kept in the AST) */
   hv_stores (lines, "START", newSViv (top->line));

   for (field = bt_next_field (top, NULL, &field_name);
        field;
        field = bt_next_field (top, field, &field_name))
   {
      SV * name;

      if (!field_name)
         continue;
      name = new_text (aTHX_ field_name, utf8);
      av_push (flist, name);
      (void) hv_store_ent (values, name, convert_value (aTHX_ field, preserve, utf8), 0);
      (void) hv_store_ent (lines, name, newSViv (field->line), 0);
      last_line = field->line;
   }
   hv_stores (lines, "STOP", newSViv (last_line));

   hv_stores (entry, "fields", newRV_noinc ((SV *) flist));
   hv_stores (entry, "values", newRV_noinc ((SV *) values));
   hv_stores (entry, "lines", newRV_noinc ((SV *) lines));
}

static void
convert_value_entry (pTHX_ AST *top, HV *entry, int preserve, int utf8)
{
   HV *  lines = newHV ();
   AST * item = NULL, *last = NULL;

   hv_stores (lines, "START", newSViv (top->line));
   while ((item = bt_next_value (top, item, NULL, NULL)))
      last = item;
   hv_stores (lines, "STOP", newSViv (last ? last->line : top->line));
   hv_stores (entry, "lines", newRV_noinc ((SV *) lines));
   hv_stores (entry, "value", convert_value (aTHX_ top, preserve, utf8));
}

/* Fill in an entry hash from an AST (and free the AST) */
static void
ast_to_hash (pTHX_ HV *entry, AST *top, int status, int preserve,
             bt_macros *macros, bt_errors *errs, int utf8)
{
   bt_metatype metatype = bt_entry_metatype (top);
   btshort     options;
   char *      key;

   /*
    * Clear out all hash values that might not be replaced in this
    * conversion (in case the user parses into an existing
    * Text::BibTeX::Entry object).
    */
   (void) hv_deletes (entry, "key", G_DISCARD);
   (void) hv_deletes (entry, "fields", G_DISCARD);
   (void) hv_deletes (entry, "lines", G_DISCARD);
   (void) hv_deletes (entry, "values", G_DISCARD);
   (void) hv_deletes (entry, "value", G_DISCARD);

   /*
    * Post-process (the parser returned the raw entry): with 'preserve'
    * we keep the values as they are; otherwise expand macros, paste
    * strings and (except for @string values) collapse whitespace.  This
    * also stores the macros defined by an @string entry.
    */
   if (preserve)
      options = BTO_MINIMAL;
   else
      options = (metatype == BTE_MACRODEF) ? BTO_MACRO : BTO_FULL;
   bt_postprocess_entry (macros, errs, top, options);

   hv_stores (entry, "type", new_text (aTHX_ bt_entry_type (top), utf8));
   hv_stores (entry, "metatype", newSViv (metatype));
   if ((key = bt_entry_key (top)))
      hv_stores (entry, "key", new_text (aTHX_ key, utf8));
   hv_stores (entry, "status", newSViv (status ? 1 : 0));

   switch (metatype)
   {
      case BTE_MACRODEF:
      case BTE_REGULAR:
         convert_assigned_entry (aTHX_ top, entry, preserve, utf8);
         break;
      case BTE_COMMENT:
      case BTE_PREAMBLE:
         convert_value_entry (aTHX_ top, entry, preserve, utf8);
         break;
      default:
         break;
   }
}

static HV *
entry_hash (pTHX_ SV *entry_ref)
{
   if (! (SvROK (entry_ref) && SvTYPE (SvRV (entry_ref)) == SVt_PVHV))
      croak ("entry_ref must be a hash ref");
   return (HV *) SvRV (entry_ref);
}

/* Parse one entry with p into entry_ref; returns true if one was found */
static int
parse_into (pTHX_ SV *entry_ref, bt_parser *p, int preserve, int utf8)
{
   HV *      entry = entry_hash (aTHX_ entry_ref);
   bt_errors errs;
   boolean   status;
   AST *     top;

   (void) hv_deletes (entry, "errors", G_DISCARD);   /* fresh error list */
   bt_errors_init (&errs);
   top = bt_parse_entry (p, &errs, BTO_NOPOSTPROCESS, &status);
   if (top)
   {
      ast_to_hash (aTHX_ entry, top, status, preserve,
                   bt_parser_macros (p), &errs, utf8);
      bt_free_ast (top);
   }
   dispatch_errors (aTHX_ &errs, utf8, entry_ref);
   return top != NULL;
}


/* ----------------------------------------------------------------------
 * Converting lists of C strings to Perl
 */

static void
store_stringlist (pTHX_ HV *hash, const char *key, char **list, int n,
                  int utf8)
{
   if (list)
   {
      AV * av = newAV ();
      int  i;

      for (i = 0; i < n; i++)
         av_push (av, list[i] ? new_text (aTHX_ list[i], utf8) : newSV (0));
      (void) hv_store (hash, key, strlen (key), newRV_noinc ((SV *) av), 0);
   }
   else
      (void) hv_delete (hash, key, strlen (key), G_DISCARD);
}


static int
constant (const char *name, IV *arg)
{
   static const struct { const char *name; IV value; } constants[] =
   {
      { "BTE_UNKNOWN",  BTE_UNKNOWN },
      { "BTE_REGULAR",  BTE_REGULAR },
      { "BTE_COMMENT",  BTE_COMMENT },
      { "BTE_PREAMBLE", BTE_PREAMBLE },
      { "BTE_MACRODEF", BTE_MACRODEF },
      { "BTAST_STRING", BTAST_STRING },
      { "BTAST_NUMBER", BTAST_NUMBER },
      { "BTAST_MACRO",  BTAST_MACRO },
      { "BTN_FIRST",    BTN_FIRST },
      { "BTN_VON",      BTN_VON },
      { "BTN_LAST",     BTN_LAST },
      { "BTN_JR",       BTN_JR },
      { "BTN_NONE",     BTN_NONE },
      { "BTJ_MAYTIE",   BTJ_MAYTIE },
      { "BTJ_SPACE",    BTJ_SPACE },
      { "BTJ_FORCETIE", BTJ_FORCETIE },
      { "BTJ_NOTHING",  BTJ_NOTHING },
   };
   size_t i;

   for (i = 0; i < sizeof (constants) / sizeof (constants[0]); i++)
      if (strEQ (name, constants[i].name))
      {
         *arg = constants[i].value;
         return 1;
      }
   return 0;
}


MODULE = Text::BibTeX           PACKAGE = Text::BibTeX

PROTOTYPES: DISABLE

BOOT:
{
   MY_CXT_INIT;
   MY_CXT.macros = bt_macros_new (NULL);
   bt_set_oom_handler (btxs_oom);
}

void
CLONE (...)
   CODE:
      /* the new interpreter starts with a copy of the parent's macros */
      MY_CXT_CLONE;
      MY_CXT.macros = bt_macros_clone (MY_CXT.macros, NULL);

SV *
constant (name)
      const char * name
   CODE:
      IV i;
      if (constant (name, &i))
         RETVAL = newSViv (i);
      else
         RETVAL = &PL_sv_undef;
   OUTPUT:
      RETVAL

const char *
unicode_version ()
   CODE:
      RETVAL = bt_unicode_version ();
   OUTPUT:
      RETVAL

void
initialize ()
   CODE:
      /* nothing to do: kept for compatibility */

void
cleanup ()
   CODE:
      dMY_CXT;
      bt_delete_all_macros (MY_CXT.macros);

void
isplit_list (string, delim, filename=NULL, line=0, description=NULL)
      SV *         string
      const char * delim
      SV *         filename
      int          line
      SV *         description
   PREINIT:
      bt_stringlist * list;
      bt_errors       errs;
      int             utf8, i;
      const char *    s;
      AV *            result;
   PPCODE:
      s = sv_text (string, &utf8);
      bt_errors_init (&errs);
      list = bt_split_list (&errs, s, delim, sv_text (filename, NULL),
                            line, sv_text (description, NULL));
      result = (AV *) sv_2mortal ((SV *) newAV ());
      if (list)
      {
         for (i = 0; i < list->num_items; i++)
            av_push (result, list->items[i]
                     ? new_text (aTHX_ list->items[i], utf8) : newSV (0));
         bt_free_list (list);
      }
      dispatch_errors (aTHX_ &errs, utf8, NULL);
      EXTEND (SP, av_len (result) + 1);
      for (i = 0; i <= av_len (result); i++)
         PUSHs (sv_2mortal (SvREFCNT_inc (*av_fetch (result, i, 0))));

SV *
purify_string (instr, options=0)
      SV *  instr
      int   options
   PREINIT:
      const char * s;
      char *       pure;
      int          utf8;
   CODE:
      if ((s = sv_text (instr, &utf8)) == NULL)
         XSRETURN_UNDEF;
      pure = bt_purify_string (s, (btshort) options);
      RETVAL = new_text (aTHX_ pure, utf8);
      bt_free (pure);
   OUTPUT:
      RETVAL

SV *
change_case (transform, string, options=0)
      char  transform
      SV *  string
      int   options
   PREINIT:
      const char * s;
      char *       changed;
      bt_errors    errs;
      int          utf8;
   CODE:
      if ((s = sv_text (string, &utf8)) == NULL)
         XSRETURN_UNDEF;
      bt_errors_init (&errs);
      changed = bt_change_case (&errs, transform, s, (btshort) options);
      RETVAL = changed ? new_text (aTHX_ changed, utf8) : newSV (0);
      bt_free (changed);
      sv_2mortal (RETVAL);
      dispatch_errors (aTHX_ &errs, utf8, NULL);
      SvREFCNT_inc_simple_void (RETVAL);
   OUTPUT:
      RETVAL

void
add_macro_text (macro, text, filename=NULL, line=0)
      SV *  macro
      SV *  text
      SV *  filename
      int   line
   PREINIT:
      bt_errors errs;
      int       utf8;
   CODE:
      dMY_CXT;
      bt_errors_init (&errs);
      bt_add_macro_text (MY_CXT.macros, &errs, sv_text (macro, &utf8),
                         sv_text (text, NULL),
                         sv_text (filename, NULL), line);
      dispatch_errors (aTHX_ &errs, utf8, NULL);

void
delete_macro (macro)
      SV *  macro
   CODE:
      dMY_CXT;
      if (SvOK (macro))
         bt_delete_macro (MY_CXT.macros, sv_text (macro, NULL));

void
delete_all_macros ()
   CODE:
      dMY_CXT;
      bt_delete_all_macros (MY_CXT.macros);

int
macro_length (macro)
      SV *  macro
   CODE:
      dMY_CXT;
      RETVAL = SvOK (macro)
         ? bt_macro_length (MY_CXT.macros, sv_text (macro, NULL)) : 0;
   OUTPUT:
      RETVAL

SV *
macro_text (macro, filename=NULL, line=0)
      SV *  macro
      SV *  filename
      int   line
   PREINIT:
      bt_errors    errs;
      const char * text;
      int          utf8;
   CODE:
      dMY_CXT;
      bt_errors_init (&errs);
      text = bt_macro_text (MY_CXT.macros, &errs, sv_text (macro, &utf8),
                            sv_text (filename, NULL), line);
      RETVAL = sv_2mortal (text ? newSVpv (text, 0) : newSV (0));
      dispatch_errors (aTHX_ &errs, utf8, NULL);
      SvREFCNT_inc_simple_void (RETVAL);
   OUTPUT:
      RETVAL


MODULE = Text::BibTeX           PACKAGE = Text::BibTeX::Parser

Text::BibTeX::Parser
new (class, fh, filename=NULL, utf8=0, private_macros=0)
      const char * class
      SV *         fh
      SV *         filename
      int          utf8
      int          private_macros
   PREINIT:
      btxs_parser * xp;
      GV *          gv = NULL;
   CODE:
      PERL_UNUSED_VAR (class);
      if (SvROK (fh) && SvTYPE (SvRV (fh)) == SVt_PVGV)
         gv = (GV *) SvRV (fh);
      else if (SvTYPE (fh) == SVt_PVGV)
         gv = (GV *) fh;
      else if (SvROK (fh) && SvTYPE (SvRV (fh)) == SVt_PVIO)
         croak ("Text::BibTeX::Parser::new: pass a glob or glob reference, "
                "not an IO object");
      if (gv == NULL || GvIO (gv) == NULL)
         croak ("Text::BibTeX::Parser::new: not a filehandle");
      {
         dMY_CXT;
         Newxz (xp, 1, btxs_parser);
#ifdef MULTIPLICITY
         xp->perl = aTHX;
#endif
         xp->fh = newRV_inc ((SV *) gv);
         xp->utf8 = utf8;
         if (IoIFP (GvIO (gv)) && PerlIO_isutf8 (IoIFP (GvIO (gv))))
            xp->utf8 = 1;
         xp->parser = bt_parser_new_reader (xs_read, xp,
                                            sv_text (filename, NULL),
                                            xp->utf8 ? BTP_UTF8 : 0);
         if (private_macros)
            xp->private_macros = bt_macros_new (MY_CXT.macros);
         bt_parser_set_macros (xp->parser, xp->private_macros
                               ? xp->private_macros : MY_CXT.macros);
      }
      RETVAL = xp;
   OUTPUT:
      RETVAL

int
eof (xp)
      Text::BibTeX::Parser xp
   CODE:
      RETVAL = bt_parser_eof (xp->parser);
   OUTPUT:
      RETVAL

int
utf8 (xp)
      Text::BibTeX::Parser xp
   CODE:
      RETVAL = xp->utf8;
   OUTPUT:
      RETVAL

int
CLONE_SKIP (...)
   CODE:
      RETVAL = 1;                       /* C state can't be shared */
   OUTPUT:
      RETVAL

void
DESTROY (xp)
      Text::BibTeX::Parser xp
   CODE:
      bt_parser_free (xp->parser);
      bt_macros_free (xp->private_macros);
      SvREFCNT_dec (xp->fh);
      SvREFCNT_dec (xp->read_died);
      Safefree (xp);


MODULE = Text::BibTeX           PACKAGE = Text::BibTeX::Entry

int
_parse (entry_ref, parser, preserve=0)
      SV *                 entry_ref
      Text::BibTeX::Parser parser
      int                  preserve
   CODE:
      RETVAL = parse_into (aTHX_ entry_ref, parser->parser, preserve,
                           parser->utf8);
      if (parser->read_died)
      {
         SV * err = sv_2mortal (parser->read_died);
         parser->read_died = NULL;
         croak_sv (err);
      }
   OUTPUT:
      RETVAL

int
_parse_s (entry_ref, text, preserve=0, want_utf8=0)
      SV *  entry_ref
      SV *  text
      int   preserve
      int   want_utf8
   PREINIT:
      bt_parser *  p;
      const char * s;
      STRLEN       len;
      int          utf8;
   CODE:
      dMY_CXT;
      (void) entry_hash (aTHX_ entry_ref);
      s = sv_text_len (aTHX_ text, &utf8, &len);
      if (s == NULL)
         XSRETURN_NO;
      utf8 = utf8 || want_utf8;
      p = bt_parser_new_string (s, len, NULL, 1, utf8 ? BTP_UTF8 : 0);
      bt_parser_set_macros (p, MY_CXT.macros);
      SAVEDESTRUCTOR ((void (*) (void *)) bt_parser_free, p);
      RETVAL = parse_into (aTHX_ entry_ref, p, preserve, utf8);
   OUTPUT:
      RETVAL


MODULE = Text::BibTeX           PACKAGE = Text::BibTeX::Name

void
_split (name_hashref, name, filename, line, name_num, keep_cstruct)
      SV *  name_hashref
      SV *  name
      SV *  filename
      int   line
      int   name_num
      int   keep_cstruct
   PREINIT:
      HV *        name_hash;
      bt_name *   split;
      bt_errors   errs;
      int         utf8;
   CODE:
      if (! (SvROK (name_hashref) && SvTYPE (SvRV (name_hashref)) == SVt_PVHV))
         croak ("name_hashref is not a hash reference");
      name_hash = (HV *) SvRV (name_hashref);
      (void) hv_deletes (name_hash, "_cstruct", G_DISCARD);

      bt_errors_init (&errs);
      split = bt_split_name (&errs, sv_text (name, &utf8),
                             sv_text (filename, NULL), line, name_num);
      store_stringlist (aTHX_ name_hash, "first", split->parts[BTN_FIRST],
                        split->part_len[BTN_FIRST], utf8);
      store_stringlist (aTHX_ name_hash, "von", split->parts[BTN_VON],
                        split->part_len[BTN_VON], utf8);
      store_stringlist (aTHX_ name_hash, "last", split->parts[BTN_LAST],
                        split->part_len[BTN_LAST], utf8);
      store_stringlist (aTHX_ name_hash, "jr", split->parts[BTN_JR],
                        split->part_len[BTN_JR], utf8);

      if (keep_cstruct)
      {
         btxs_name * xn;
         SV *        obj = newSV (0);
         Newx (xn, 1, btxs_name);
         xn->name = split;
         sv_setref_pv (obj, "Text::BibTeX::Name::Struct", xn);
         (void) hv_stores (name_hash, "_cstruct", obj);
      }
      else
         bt_free_name (split);
      dispatch_errors (aTHX_ &errs, utf8, NULL);

void
free (name_hashref)
      SV *  name_hashref
   CODE:
      if (SvROK (name_hashref) && SvTYPE (SvRV (name_hashref)) == SVt_PVHV)
         (void) hv_deletes ((HV *) SvRV (name_hashref), "_cstruct", G_DISCARD);


MODULE = Text::BibTeX           PACKAGE = Text::BibTeX::Name::Struct

int
CLONE_SKIP (...)
   CODE:
      RETVAL = 1;
   OUTPUT:
      RETVAL

void
DESTROY (xn)
      Text::BibTeX::Name::Struct xn
   CODE:
      bt_free_name (xn->name);
      Safefree (xn);


MODULE = Text::BibTeX           PACKAGE = Text::BibTeX::NameFormat

Text::BibTeX::NameFormat::Struct
create (parts="fvlj", abbrev_first=0)
      const char * parts
      int          abbrev_first
   PREINIT:
      bt_errors        errs;
      bt_name_format * format;
   CODE:
      bt_errors_init (&errs);
      format = bt_create_name_format (&errs, parts, abbrev_first);
      dispatch_errors (aTHX_ &errs, 0, NULL);       /* dies on bad parts */
      if (format == NULL)
         croak ("invalid name format \"%s\"", parts);
      Newx (RETVAL, 1, btxs_format);
      RETVAL->format = format;
   OUTPUT:
      RETVAL

void
free (format)
      SV *  format
   CODE:
      /* the structure is freed when its last reference goes away */
      PERL_UNUSED_VAR (format);

void
_set_text (format, part, pre_part, post_part, pre_token, post_token)
      Text::BibTeX::NameFormat::Struct format
      int   part
      SV *  pre_part
      SV *  post_part
      SV *  pre_token
      SV *  post_token
   CODE:
      if (part < 0 || part >= BT_MAX_NAMEPARTS)
         croak ("invalid name part %d", part);
      bt_set_format_text (format->format, (bt_namepart) part,
                          sv_text (pre_part, NULL),
                          sv_text (post_part, NULL),
                          sv_text (pre_token, NULL),
                          sv_text (post_token, NULL));

void
_set_options (format, part, abbrev, join_tokens, join_part)
      Text::BibTeX::NameFormat::Struct format
      int   part
      int   abbrev
      int   join_tokens
      int   join_part
   CODE:
      if (part < 0 || part >= BT_MAX_NAMEPARTS)
         croak ("invalid name part %d", part);
      if (join_tokens < BTJ_MAYTIE || join_tokens > BTJ_NOTHING
          || join_part < BTJ_MAYTIE || join_part > BTJ_NOTHING)
         croak ("invalid join method");
      bt_set_format_options (format->format, (bt_namepart) part, abbrev,
                             (bt_joinmethod) join_tokens,
                             (bt_joinmethod) join_part);

SV *
format_name (name, format, utf8=0)
      Text::BibTeX::Name::Struct       name
      Text::BibTeX::NameFormat::Struct format
      int                              utf8
   PREINIT:
      bt_errors errs;
      char *    formatted;
   CODE:
      bt_errors_init (&errs);
      formatted = bt_format_name (&errs, name->name, format->format);
      RETVAL = sv_2mortal (new_text (aTHX_ formatted, utf8));
      bt_free (formatted);
      dispatch_errors (aTHX_ &errs, utf8, NULL);
      SvREFCNT_inc_simple_void (RETVAL);
   OUTPUT:
      RETVAL


MODULE = Text::BibTeX           PACKAGE = Text::BibTeX::NameFormat::Struct

int
CLONE_SKIP (...)
   CODE:
      RETVAL = 1;
   OUTPUT:
      RETVAL

void
DESTROY (xf)
      Text::BibTeX::NameFormat::Struct xf
   CODE:
      bt_free_name_format (xf->format);
      Safefree (xf);
