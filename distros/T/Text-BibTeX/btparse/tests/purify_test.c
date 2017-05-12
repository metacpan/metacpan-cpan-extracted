#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "btparse.h"

int
main (void)
{
   char   line[1024];
   int    line_num;
   int    len, i;

   while (! feof (stdin))
   {
      if (fgets (line, 1024, stdin))
      {
         len = strlen (line);
         if (line[len-1] == '\n') line[len-1] = '\0';
         line_num++;
         printf ("original string = %s\n", line);
         bt_purify_string (line, 0);
         len = strlen (line);

         /* strip trailing spaces so our output looks like BibTeX's */
         for (i = len-1; line[i] == ' '; i--)
            line[i] = (char) 0;

         if (len > 0)
            printf ("purified string = %s\n", line);
         else                           /* more imitating BibTeX's output */
            printf ("purified string =\n");
         printf ("purified length = %d\n", len);
      }
   }
   return 0;
}

