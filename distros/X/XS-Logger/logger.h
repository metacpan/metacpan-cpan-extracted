/*
 * logger.h
 */

#ifndef XS_LOGGER_H
#  define XS_LOGGER_H 1

#include <perl.h>

/* typedef enum { xfalse, xtrue } xbool; */

typedef enum {
		LOG_DEBUG, /* 0 */
		LOG_INFO,  /* 1 */
		LOG_WARN,  /* 2 */
		LOG_ERROR, /* 3 or also DIE */
		LOG_FATAL,  /* 4 or also PANIC */
		/* keep it in last position */
	    LOG_DISABLE  /* 5 - disable all log events - should be preserved in last position */
} logLevel;

typedef union {
        int ival;
        double fval;
        char *sval;
} MultiValue;

typedef struct {
	bool use_color;
	pid_t pid;
	FILE *fhandle;
	char filepath[256];
	logLevel level; /* only display what is after the log level (included) */
} MyLogger;

/* function prototypes */
char* get_default_file_path();
void do_log(MyLogger *mylogger, logLevel level, const char *fmt, int num_args, ...);

#define ACQUIRE_LOCK_ONCE(f) if (!hold_lock) { flock( fileno(f), LOCK_EX ); hold_lock = true; }
#define RELEASE_LOCK(f) if (hold_lock) flock( fileno(f), LOCK_UN );

#endif /* XS_LOGGER_H */