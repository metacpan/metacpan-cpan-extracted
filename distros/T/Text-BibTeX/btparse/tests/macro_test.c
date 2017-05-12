/*
 * macro_test.c
 *
 * Test driver for the btparse macro table.  Reads simple one-line commands
 * from stdin; each one consists of a one-letter action code and possibly
 * some arguments.  The allowed actions are:
 *   a <macro> <text>    - add macro
 *   p <macro>           - print expansion of macro
 *   d <macro>           - delete macro
 *   l                   - delete all macros
 *
 * There must be exactly one space between the action and <macro>, and
 * between <macro> and <text> (where appropriate).
 *
 * GPW 1998/03/01
 *
 * $Id$
 */

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include "btparse.h"


int
main (void)
{
   char   line[1024];
   int    line_num;
   int    i;
   char   action;
   char * macro;
   char * text;

   bt_initialize();

   /* 
    * Read lines from stdin.  Each one starts with a single-letter command,
    * which may be one of the following:
    */

   line_num = 0;
   while (! feof (stdin))
   {
      if (fgets (line, 1024, stdin))
      {
         line_num++;
         action = line[0];
         if (action != 'l')             /* other commands take <macro> arg */
         {
            line[1] = (char) 0;
            i = 2;
            macro = line+2;
            while (! isspace (line[i])) i++;
            line[i++] = (char) 0;
            text = line+i;
            text[strlen(text)-1] = (char) 0; /* wipe the newline */
         }

         switch (action)
         {
            case 'a':
               bt_add_macro_text (macro, text, "stdin", line_num);
               break;
            case 'p':
               text = bt_macro_text (macro, "stdin", line_num);
               if (text)
                  printf ("%s\n", text);
               break;
            case 'd':
               bt_delete_macro (macro);
               break;
            case 'l':
               bt_delete_all_macros ();
               break;
            default:
               fprintf (stderr, "unknown command '%c'\n", action);
         }

         /* zzs_stat(); */

      }

   } /* while !eof */
   
   bt_cleanup();
   return 0;
}
