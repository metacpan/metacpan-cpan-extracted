/*
 * 22 March 2001
 * rcsid = $Id: fio.h,v 1.1 2007/09/28 16:57:12 mmundry Exp $
 */
#ifndef FIO_H
#define FIO_H

FILE *mfopen (const char *fname, const char *mode, const char *s);
int   file_no_cache (FILE *fp);
int   file_clear_cache (FILE *fp);
#endif /* FIO_H */
