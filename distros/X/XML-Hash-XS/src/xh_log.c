#include "xh_config.h"
#include "xh_core.h"

#define XH_LOG_LEVEL   XH_LOG_TRACE

static char *LOG_LEVEL_NAME[7] = {
    "CRITIC",
    "ERROR",
    "WARN",
    "NOTICE",
    "INFO",
    "DEBUG",
    "TRACE",
};

void
xh_log(xh_log_level_t log_level, const char *func, xh_int_t line, const char *msg, ...)
{
    va_list args;

    if (log_level > XH_LOG_LEVEL) return;

    (void) fprintf(stderr, "(%s) %s[%.0d]: ", LOG_LEVEL_NAME[log_level], func, (int) line);

    va_start(args, msg);
    (void) vfprintf(stderr, msg, args);
    if (msg[strlen(msg) - 1] != '\n') {
        (void) fprintf(stderr, "\n");
    }
    va_end(args);
}
