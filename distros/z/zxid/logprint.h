/* logprint.h  -  Macros to print debugging output
 * 20.10.1999, Sampo Kellomaki <sampo@iki.fi>
 * 21.10.1999, added IMoaFile2 interface
 *
 * Logging needs to be enabled at compile time by defining these
 * macros as nonempty.  Once latent in program, logging needs to be
 * turned on by opening Log to desired file. If Log is NULL (the
 * default), the logging is off.
 */

#ifndef _LOGPRINT_H
#define _LOGPRINT_H

#ifdef __cplusplus
extern "C" {
#endif

/* All logging macros are conditional on Log_fd, which usually means Log,
 * but by defining Log_fd differently, you can control separately logging
 * in some source files, e.g. malloc.c, which see. */

# ifndef Log_fd
# define Log_fd Log
# endif

# if 1

/* Production code, no logging overhead, please. Like as if the program
 * does not have bugs?!? This option is for those who do not want to
 * maintain their code. */

#  define LOG_PRINT(s)
#  define LOG_PRINT2(s,x)
#  define LOG_PRINT3(s,x,y)

# else

/* Logging desired */

#  if 1

/* Use IMoaFile2 and IMoaStream2 for macromedia compatibility. NB: to avoid
 * dynamic memory allocation, the maximum size of one write is 4K. Further,
 * no attempt is made to see if the stuff actually got written. */

//#include <moafile2.h>
#include "moastr2.h"
#include <string.h>

extern PIMoaStream2 Log /* = NULL */;
extern PIMoaStream2 Log2;
extern PIMoaStream2 Log_malloc;

#   ifdef __cplusplus
#     define _LOG_WRITE  Log_fd->Write(Logbuf, strlen(Logbuf), &written); Log_fd->Flush();
#   else
#     define _LOG_WRITE  Log_fd->lpVtbl->Write(Log, Logbuf, strlen(Logbuf), &written); \
                         Log_fd->lpVtbl->Flush(Log);
#   endif

#   define LOG_PRINT(s) do{ if (Log_fd) { char Logbuf[1024]; MoaStreamCount written; \
     snprintf(Logbuf, sizeof(Logbuf), "%s %d: %s\n", __FILE__, __LINE__, (s)); \
     _LOG_WRITE } }while(0)

#   define LOG_PRINT2(s,x) do{ if (Log_fd) { char Logbuf[1024]; MoaStreamCount written; \
     snprintf(Logbuf, sizeof(Logbuf), "%s %d: " s "\n", __FILE__, __LINE__, (x)); \
     _LOG_WRITE } }while(0)

#   define LOG_PRINT3(s,x,y) do{ if (Log_fd) { char Logbuf[1024]; MoaStreamCount written; \
     snprintf(Logbuf, sizeof(Logbuf), "%s %d: " s "\n", __FILE__, __LINE__, (x), (y)); \
     _LOG_WRITE } }while(0)

#  else

/* Use libc FILE* interface */

#include <stdio.h>

extern FILE* Log /* = NULL */;

#   define LOG_PRINT(s) do{ if (Log_fd) { \
     fprintf(Log_fd, "%s %d: %s\n", __FILE__, __LINE__, (s)); \
     fflush(Log_fd);} }while(0)

#   define LOG_PRINT2(s,x) do{ if (Log_fd) { \
     fprintf(Log_fd, "%s %d: " s "\n", __FILE__, __LINE__, (x)); \
     fflush(Log_fd);} }while(0)

#   define LOG_PRINT3(s,x,y) do{ if (Log_fd) { \
     fprintf(Log_fd, "%s %d: " s "\n", __FILE__, __LINE__, (x), (y)); \
     fflush(Log_fd);} }while(0)

#  endif
# endif

#ifdef __cplusplus
}
#endif

#endif /* logprint.h */
