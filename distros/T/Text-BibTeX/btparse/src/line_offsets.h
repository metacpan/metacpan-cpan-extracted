#ifndef LINEDATA_H
#define LINEDATA_H

#include <stdio.h>

/* Prototypes for functions exported from linedata.c: */

void initialize_line_offsets (void);
void record_line_offset (int line, int offset);
int  line_offset (int line);
void dump_line_offsets (char *filename, FILE *stream);

#endif
