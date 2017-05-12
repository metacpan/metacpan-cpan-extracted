/* missing definitions for cygwin:
   itoa

   and this .def file:
   LIBRARY COMCTL32.DLL
   EXPORTS
   ImageList_Duplicate@4
   ImageList_DrawIndirect@4
   ImageList_Copy@20
*/

#ifdef __CYGWIN__

char* itoa (int value, char * buffer, int radix);

/* This is no strict ANSI definition, and not in newlib */
#include <stdio.h>
char* itoa (int value, char * buffer, int radix) {
  if (sprintf(buffer, "%d", value)) return buffer;
  else return NULL;
}

#endif
