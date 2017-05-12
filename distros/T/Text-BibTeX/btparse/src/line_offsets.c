/*
 * line_offsets.c
 * 
 * Data structure and code for recording the offset (zero-based) into an
 * input file of every line.  
 *
 * Problems: what happens at eof? perhaps need special code in lexer...
 *           not tested for large (> 1024 lines) files -- does the array
 *             grow properly?
 * 
 * GPW 1996/08/29
 */

#include <stdlib.h>
#include <assert.h>
#include <stdio.h>              /* only for dump_line_offsets() */

#include "line_offsets.h"

typedef struct
{
   int   num_slots, num_lines;
   int  *offsets;
} line_offsets_t;

static line_offsets_t line_offsets = { 0, 0, NULL };


void
initialize_line_offsets (void)
{

   /* 
    * If the structure is completely unused (ie. we're starting the first
    * file) then malloc() it from scratch.
    */

   if (line_offsets.num_slots == 0)
   {
      line_offsets.num_slots = 1024;
      line_offsets.offsets = 
         (int *) malloc (line_offsets.num_slots * sizeof (int));
   }

   /* In any case, initialize the array with the offset of line 0, 
    * and chalk up "one line counted" (line 0) so far.
    */

   line_offsets.offsets[0] = 0;
   line_offsets.num_lines = 1;
}


void
record_line_offset (int line, int offset)
{
   assert (line_offsets.num_slots > 0); /* make sure the structure has been */
                                        /* allocated */

   if (line >= line_offsets.num_slots)
   {
      line_offsets.num_slots *= 2;
      line_offsets.offsets = 
         (int *) realloc ((void *) line_offsets.offsets, 
                          line_offsets.num_slots * sizeof (int));
   }

   assert (line_offsets.num_lines == line);
   line_offsets.offsets[line] = offset;
   line_offsets.num_lines++;
}


int
line_offset (int line)
{
   return line_offsets.offsets[line-1];
}


void
dump_line_offsets (char *filename, FILE *stream)
{
   int  i;

   fprintf (stream, "Line offsets in %s:\n", filename);
   fprintf (stream, "%4s %6s\n", "Line", "Offset");
   for (i = 0; i < line_offsets.num_lines; i++)
      fprintf (stream, "%4d %6d (%04x)\n",
               i+1, line_offsets.offsets[i], line_offsets.offsets[i]);
}
