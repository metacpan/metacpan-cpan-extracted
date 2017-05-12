/*
 * 3 Sep 96
 * Because of the reference to FILE, only works after including
 * <stdio.h>.
 * rcsid = "$Id: mprintf.h,v 1.1 2007/09/28 16:57:10 mmundry Exp $"
 */

#ifndef __MPRINTF_H
#define __MPRINTF_H

int err_printf (const char *fnc_name, const char *fmt, ...)
#ifdef __GNUC__
__attribute__ ((format (printf, 2, 3)))
#endif /* __GNUC__ */
;
int mprintf  (const char *fmt, ...)
#ifdef __GNUC__
__attribute__ ((format (printf, 1, 2)))
#endif /* __GNUC__ */
;
int mfprintf (FILE *fp, const char *fmt, ...)
#ifdef __GNUC__
__attribute__ ((format (printf, 2, 3)))
#endif /* __GNUC__ */
;
int mputs ( const char *s);
int mfputs (const char *s, FILE *fp);
int mfputc (int c, FILE *fp);
/* int mputc (int c, FILE *stream); Not written yet */
int mputchar (int c);
#define mputc(x,p) ((p == stdout) ? mputchar(x) : putc (x,p))
void mperror (const char *s);

/* We do not want routines to do their own i/o.
 * We use the following #defines to prevent this.
 * Under some circumstances, there is a peculiar macro
 * _FORTIFY_SOURCE which redefines printf(). If we do not
 * undefine it, we get compiler warnings.
 */
#undef  printf
#undef  fprintf
#define printf(a) ERROR_DONT_USE_PRINTF!!_Use_mprintf
#define fprintf(a) ERROR_Dont_use_fprintf_Use_mfprintf

#endif /* __MPRINTF_H */
