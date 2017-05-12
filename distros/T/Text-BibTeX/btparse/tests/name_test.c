/*
 * name_test.c
 *
 * GPW 1997/11/03
 *
 * $Id$
 */

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "btparse.h"


static void
print_tokens (char *partname, char **tokens, int num_tokens)
{
   int  i;

   if (tokens)
   {
      printf ("%s tokens = (", partname);
      for (i = 0; i < num_tokens; i++)
      {
         printf ("%s%c", tokens[i], i == num_tokens-1 ? ')' : '|');
      }
      putchar ('\n');
   }
}


static void
dump_name (bt_name * name)
{
   printf ("total number of tokens = %d\n", name->tokens->num_items);
   print_tokens ("first", name->parts[BTN_FIRST], name->part_len[BTN_FIRST]);
   print_tokens ("von", name->parts[BTN_VON], name->part_len[BTN_VON]);
   print_tokens ("last", name->parts[BTN_LAST], name->part_len[BTN_LAST]);
   print_tokens ("jr", name->parts[BTN_JR], name->part_len[BTN_JR]);
}


static void
show_formatted_name (char * msg, bt_name_format * format, bt_name * name)
{
   char * fname;

   fname = bt_format_name (name, format);
   printf ("%s = (%s)\n", msg, fname);
   free (fname);
}


static void
process_name (char * name_string, int line_num, int name_num)
{
   bt_name * name;
   bt_name_format * format;

   printf ("original name = %s\n", name_string);
   name = bt_split_name (name_string, "stdin", line_num, name_num);
   if (! (name && name->tokens))
   {
      fprintf (stderr, "empty name\n");
      return;
   }

   dump_name (name);

   /* First "vljf", unabbreviated first name. */
   format = bt_create_name_format ("vljf", FALSE);
   show_formatted_name ("fname 1", format, name);

   /* Now abbreviate first name stupidly (ie. with no post-token text) */
   bt_set_format_options (format, BTN_FIRST, TRUE, BTJ_MAYTIE, BTJ_SPACE);
   show_formatted_name ("fname 2", format, name);

   /* Add those missing post-token periods */
   bt_set_format_text (format, BTN_FIRST, NULL, NULL, NULL, ".");
   show_formatted_name ("fname 3", format, name);

   /* Drop the periods and force no space between first-name tokens */
   bt_set_format_text (format, BTN_FIRST, NULL, NULL, NULL, "");
   bt_set_format_options (format, BTN_FIRST, TRUE, BTJ_NOTHING, BTJ_SPACE);
   show_formatted_name ("fname 4", format, name);

   /* Finish with this format, and create a new one: "fvlj", abbreviated. */
   bt_free_name_format (format);
   format = bt_create_name_format ("fvlj", TRUE);
   show_formatted_name ("fname 5", format, name);

   /* Degenerate to "no periods, no spaces" abbrev again */
   bt_set_format_text (format, BTN_FIRST, NULL, NULL, NULL, "");
   bt_set_format_options (format, BTN_FIRST, TRUE, BTJ_NOTHING, BTJ_SPACE);
   show_formatted_name ("fname 6", format, name);

   /* OK, let's play at something a little more "custom": kindergarten-
    * style names (full first name, abbreviated last name, forget about
    * 'von' and 'jr'.
    */
   bt_free_name_format (format);
   format = bt_create_name_format ("fl", FALSE);
   bt_set_format_text (format, BTN_LAST, NULL, NULL, NULL, ".");
   bt_set_format_options (format, BTN_LAST, TRUE, BTJ_MAYTIE, BTJ_SPACE);
   show_formatted_name ("fname 7", format, name);

   /* 'von' and 'last' only, abbreviated with no periods or spaces */
   bt_free_name_format (format);
   format = bt_create_name_format ("vl", FALSE);
   bt_set_format_options (format, BTN_VON, TRUE, BTJ_NOTHING, BTJ_NOTHING);
   bt_set_format_options (format, BTN_LAST, TRUE, BTJ_NOTHING, BTJ_NOTHING);
   show_formatted_name ("fname 8", format, name);

   bt_free_name_format (format);
   bt_free_name (name);

} /* process_name () */


int
main (void)
{
   char   line[1024];
   int    line_num;
   int    len;
   bt_stringlist * names;
   int    i;

   while (! feof (stdin))
   {
      if (fgets (line, 1024, stdin) == NULL)
         break;

      len = strlen (line);
      if (line[len-1] == '\n') line[len-1] = '\0';
      line_num++;

      names = bt_split_list (line, "and", "stdin", line_num, "name");
      if (names == NULL)
         printf ("empty or invalid string\n");
      else
      {
         if (names->num_items > 1)
            printf ("%d names in string\n", names->num_items);

         for (i = 0; i < names->num_items; i++)
         {
            if (names->items[i])
               process_name (names->items[i], line_num, i+1);
         }
         bt_free_list (names);
      }
   }
   return 0;
}
