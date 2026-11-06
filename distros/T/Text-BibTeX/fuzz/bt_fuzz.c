/* ------------------------------------------------------------------------
@NAME       : bt_fuzz.c
@DESCRIPTION: Stand-alone driver for testing the C library (src/) under
              sanitizers and fuzzers (it needs no Perl).  Each input is
              parsed twice -- once from memory and once through a reader
              callback that returns small, irregular chunks, to exercise
              buffer refills -- and every entry is run through the whole
              pipeline: post-processing, macro storage, name splitting and
              formatting, purify and change_case.

              Build with "make -C fuzz" (see the Makefile there), then:
                fuzz/bt_fuzz FILE...           run over files
              or, with libFuzzer:
                make -C fuzz libfuzzer && fuzz/bt_libfuzzer CORPUS_DIR
-------------------------------------------------------------------------- */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "btparse.h"

typedef struct
{
   const char * data;
   size_t       len;
   size_t       pos;
   unsigned     seed;
} chunk_reader;

static long
read_chunks (void *ud, char *buf, size_t n)
{
   chunk_reader * r = ud;
   size_t         k;

   if (r->pos >= r->len)
      return 0;
   r->seed = r->seed * 1103515245 + 12345;
   k = 1 + (r->seed >> 16) % 7;         /* 1..7 bytes at a time */
   if (k > n) k = n;
   if (k > r->len - r->pos) k = r->len - r->pos;
   memcpy (buf, r->data + r->pos, k);
   r->pos += k;
   return (long) k;
}

static void
exercise_string (bt_errors *errs, const char *s)
{
   bt_stringlist * list;
   char *          p;
   static const char * formats[] = { "fvlj", "vljf", "l", "f", "lf", "jfl" };
   int             i, j;

   p = bt_purify_string (s, 0);
   free (p);
   p = bt_change_case (errs, 't', s, 0); free (p);
   p = bt_change_case (errs, 'u', s, 0); free (p);
   p = bt_change_case (errs, 'l', s, 0); free (p);

   list = bt_split_list (errs, s, "and", "fuzz", 1, "name");
   if (!list)
      return;
   for (i = 0; i < list->num_items; i++)
   {
      bt_name * name = bt_split_name (errs, list->items[i], "fuzz", 1, i);
      for (j = 0; j < (int) (sizeof (formats) / sizeof (formats[0])); j++)
      {
         bt_name_format * f = bt_create_name_format (errs, formats[j], j & 1);
         if (f)
         {
            bt_set_format_text (f, BTN_LAST, NULL, NULL, NULL, ".");
            bt_set_format_options (f, BTN_LAST, j & 1, BTJ_MAYTIE, BTJ_SPACE);
            free (bt_format_name (errs, name, f));
            bt_free_name_format (f);
         }
      }
      bt_free_name (name);
   }
   bt_free_list (list);
}

static void
run_parser (bt_parser *p, bt_macros *macros)
{
   bt_errors errs;
   boolean   status;
   AST *     entry;
   int       n = 0;

   bt_errors_init (&errs);
   bt_parser_set_macros (p, macros);
   while ((entry = bt_parse_entry (p, &errs, 0, &status)) && n++ < 100000)
   {
      AST *  field;
      char * name;

      bt_postprocess_entry (macros, &errs, entry,
                            (entry->metatype == BTE_MACRODEF ? BTO_MACRO : BTO_FULL)
                            | BTO_NOSTORE);
      for (field = bt_next_field (entry, NULL, &name); field;
           field = bt_next_field (entry, field, &name))
      {
         char * text;
         bt_next_value (field, NULL, NULL, &text);
         if (text)
            exercise_string (&errs, text);
      }
      bt_free_ast (entry);
      bt_errors_clear (&errs);
   }
   bt_errors_clear (&errs);
}

static void
fuzz_one (const char *data, size_t len)
{
   bt_macros *  global = bt_macros_new (NULL);
   bt_macros *  local = bt_macros_new (global);
   bt_parser *  p;
   chunk_reader r;
   bt_errors    errs;

   bt_errors_init (&errs);
   bt_add_macro_text (global, &errs, "jan", "January", NULL, 0);
   bt_errors_clear (&errs);

   p = bt_parser_new_string (data, len, "fuzz", 1, BTP_UTF8);
   run_parser (p, global);
   bt_parser_free (p);

   r.data = data;
   r.len = len;
   r.pos = 0;
   r.seed = (unsigned) len;
   p = bt_parser_new_reader (read_chunks, &r, "fuzz", 0);
   run_parser (p, local);
   bt_parser_free (p);

   /* the input as a raw string for the string utilities too */
   {
      char * s = malloc (len + 1);
      memcpy (s, data, len);
      s[len] = 0;
      exercise_string (&errs, s);
      bt_errors_clear (&errs);
      free (s);
   }

   bt_macros_free (local);
   bt_macros_free (global);
}

#ifdef BT_LIBFUZZER
int
LLVMFuzzerTestOneInput (const unsigned char *data, size_t size)
{
   fuzz_one ((const char *) data, size);
   return 0;
}
#else
int
main (int argc, char **argv)
{
   int i;

   for (i = 1; i < argc; i++)
   {
      FILE * f = fopen (argv[i], "rb");
      char * buf;
      long   len;

      if (!f)
      {
         perror (argv[i]);
         return 1;
      }
      fseek (f, 0, SEEK_END);
      len = ftell (f);
      fseek (f, 0, SEEK_SET);
      buf = malloc (len + 1);
      if (fread (buf, 1, len, f) != (size_t) len)
      {
         perror (argv[i]);
         return 1;
      }
      fclose (f);
      fuzz_one (buf, (size_t) len);
      free (buf);
   }
   return 0;
}
#endif
