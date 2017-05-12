#include <stdio.h>
#include <string.h>
#include "btparse.h"

void dump_name(bt_name*);

int main (void)
{
   char * snames[4] = { "Joe Blow", "John Smith", "Fred Rogers", "" };
   bt_name * names[4];
   int i;

   printf ("split as we go:\n");
   for (i = 0; i < 4; i++)
   {
      names[i] = bt_split_name (strdup (snames[i]), NULL, 0, 0);
      dump_name (names[i]);
   }

   printf ("pre-split:\n");
   for (i = 0; i < 4; i++)
   {
      dump_name (names[i]);
   }

   return 0;
}

