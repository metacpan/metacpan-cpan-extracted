/*
 * Debug hook to bring in debugger
 * $Id: dbg.c,v 1.1 2007/09/28 16:57:06 mmundry Exp $
 */
#include <unistd.h>
#include <sys/types.h>
#include <signal.h>

#include "dbg.h"

#define need_breaker

pid_t getpid (void);
void
breaker (void)
{
#   ifdef need_breaker
    int kill (pid_t x, int sig);/* with ansi flags set, prototype explicitly */
    int sigignore( int sig);
    sigignore (SIGTRAP);
    kill (getpid(), SIGTRAP);
#   endif /* need_breaker */
}
    
