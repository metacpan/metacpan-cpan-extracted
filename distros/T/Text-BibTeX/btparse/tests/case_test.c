/*
 * case_test.c
 * 
 * GPW 1997/11/25
 *
 * $Id$
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "btparse.h"


static void
show_case_changed (char transform, char * msg, char * string)
{
   char * dup;

   dup = strdup (string);
   bt_change_case (transform, dup, 0);
   printf ("%s%s\n", msg, dup);
   free (dup);
}


int
main (void)
{
   char   line[1024];
   int    line_num;
   int    len;

   while (! feof (stdin))
   {
      if (fgets (line, 1024, stdin) == NULL)
         break;

      len = strlen (line);
      if (line[len-1] == '\n') line[len-1] = '\0';
      line_num++;

      printf ("original_string = %s\n", line);

      show_case_changed ('l', "      lowercase = ", line);
      show_case_changed ('u', "      uppercase = ", line);
      show_case_changed ('t', "     title caps = ", line);
   }
   return 0;
}
