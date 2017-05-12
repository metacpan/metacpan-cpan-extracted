/* $Id$ */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "btparse.h"

int main (void)
{
   char   line[1024];
   int    line_num;
   int    len;
   bt_tex_tree *
          tree;
   char * str;

   line_num = 0;
   while (! feof (stdin))
   {
      if (fgets (line, 1024, stdin))
      {
         len = strlen (line);
         if (line[len-1] == '\n') line[len-1] = '\0';
         line_num++;

         tree = bt_build_tex_tree (line);

         if (tree)
         {
            printf ("tree =\n");
            bt_dump_tex_tree (tree, 0, stdout);

            str = bt_flatten_tex_tree (tree);
            printf ("flattened tree = [%s]\n", str);
            if (strcmp (line, str) != 0)
               printf ("uh-oh! line and str don't match!\n");
            free (str);
         }
      }
   }
   return 0;
}
