/*
 * 4 Jan 2002
 * $Id: silly.h,v 1.1 2007/09/28 16:57:10 mmundry Exp $
 */

#ifndef SILLY_H
#define SILLY_H

int   func_int (void );
float func_float (void);
char *func_char  (void);

char *funcs1_char ( char *in );
char *funcs2_char ( void );
void  free_scratch (void);
#endif /* SILLY_H */
