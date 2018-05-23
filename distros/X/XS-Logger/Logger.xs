#define PERL_EXT_XS_LOG 1
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <sys/file.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>
#include "logger.h"

char*
get_default_file_path() {
    char *path;
    SV   *sv = get_sv( "XS::Logger::PATH_FILE", 0 );

    if ( sv && SvPOK(sv) )
        path = SvPV_nolen( sv );
    else
        path = (char *) DEFAULT_LOG_FILE; /* fallback to default path */

    return path;
}

char*
_file_path_for_logger(MyLogger *self) {
	if ( strlen(self->filepath) )
		return self->filepath;
	else
		return get_default_file_path();
}

/* c internal functions */
void
do_log(MyLogger *mylogger, logLevel level, const char *fmt, int num_args, ...) {
    FILE *fhandle = NULL;
    char *path = NULL;
    SV *sv = NULL;
    /* Get current time */
    time_t t = time(NULL);
    struct tm lt = {0};
    char buf[32];
    bool has_logger_object = true;
    bool hold_lock = false;
    pid_t pid;
    bool quiet = false; /* do not display messages on stderr when quiet mode enabled */

    localtime_r(&t, &lt);

    if ( level == LOG_DISABLE ) /* to move earlier */
        return;

    buf[strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M:%S", &lt)] = '\0';

    pid = getpid();

    /* Note: *mylogger can be a NULL pointer => would fall back to a GV string or a constant from .c to get the filename */
    if ( mylogger ) { /* we got a mylogger pointer */
        path = _file_path_for_logger( mylogger );

        if ( mylogger->pid && mylogger->pid != pid ) {
            if (mylogger->fhandle) fclose(mylogger->fhandle);
            mylogger->fhandle = NULL;
        }
        if ( ! mylogger->fhandle ) {
            if ( (fhandle = fopen( path, "a" )) == NULL ) /* open in append mode */
                croak("Failed to open file \"%s\"", path);
            mylogger->fhandle = fhandle; /* save the fhandle for future reuse */
            mylogger->pid = pid; /* store the pid which open the file */

            ACQUIRE_LOCK_ONCE(fhandle); /* get a lock before moving to the end */
            fseek(fhandle, 0, SEEK_END);
        }
        fhandle = mylogger->fhandle;
        quiet   = mylogger->quiet;
    } else {
        path = get_default_file_path();
        has_logger_object = false;

        if ( (fhandle = fopen( path, "a" )) == NULL ) /* open in append mode */
            croak("Failed to open file \"%s\"", path);

        ACQUIRE_LOCK_ONCE(fhandle); /* get a lock before moving to the end */
        fseek(fhandle, 0, SEEK_END);
    }

    if ( fhandle ) {
        va_list args;
        int abs_gmtoff = lt.tm_gmtoff >= 0 ? lt.tm_gmtoff : -1 * lt.tm_gmtoff;
        if (num_args) va_start(args, num_args);

        ACQUIRE_LOCK_ONCE(fhandle);

        /* write the message */
        /* header: [timestamp tz] pid LEVEL */
        if ( mylogger && mylogger->use_color ) {
            M_FPRINTF( fhandle, "[%s %s%02d%02d] %s%-5s%s",
                 buf,
                lt.tm_gmtoff >= 0 ? "+" : "-",
                 (int) abs_gmtoff / 3600,
                ( abs_gmtoff % 3600) / 60,
                 LEVEL_COLORS[level], LOG_LEVEL_NAMES[level], END_COLOR
            );
        } else {
            M_FPRINTF( fhandle, "[%s %s%02d%02d] %-5s",
                 buf,
                 lt.tm_gmtoff >= 0 ? "+" : "-",
                 (int) abs_gmtoff / 3600, ( abs_gmtoff % 3600) / 60,
                 LOG_LEVEL_NAMES[level]
            );
        }
        {
            SV *const dollar_0 = get_sv("0",GV_ADDWARN); /* $0 - application name */
            char *str_dollar_0;

            if ( !SvPOK(dollar_0) ) { /* probably a better helper to simply get the PV at all cost */
                if ( SvIOK(dollar_0) )
                    SvUPGRADE(dollar_0, SVt_PVIV);
                else
                    croak("dollar_0 is not a string?!");
            }
            str_dollar_0 = SvPV_nolen( dollar_0 );
            M_FPRINTF( fhandle, " %u [%s] ", (unsigned int) pid, str_dollar_0 ); /* print the source */
            /* with the pid ? */
            /* fprintf( fhandle, " [%u %s] ", (unsigned int) pid, str_dollar_0 ); */
        }
        {
            int len = 0;

            //PerlIO_printf( PerlIO_stderr(), "# num_args %d\n", num_args );
            if ( fmt && (len=strlen(fmt)) ) {
                if (num_args == 0)  /* no need to use sprintf when not needed */
                    M_FPUTS( fmt, fhandle )
                else
                    M_VFPRINTF( fhandle, fmt, args )
            }
            // only add "\n" if missing from fmt
            if ( !len || fmt[len-1] != '\n')
                M_FPUTS( "\n", fhandle );
        }
        if (has_logger_object) fflush(fhandle); /* otherwise we are going to close the ffhandle just after */
        if (num_args) va_end(args);
    }

    RELEASE_LOCK(fhandle); /* only release if acquired before */

    if ( !has_logger_object ) fclose( fhandle );

    return;
}

/* function exposed to the module */
/* maybe a bad idea to use a prefix */
MODULE = XS__Logger    PACKAGE = XS::Logger PREFIX = xlog_

TYPEMAP: <<HERE

MyLogger*  T_PTROBJ
XS::Logger T_PTROBJ

HERE

XS::Logger
xlog_new(class, ...)
    char* class;
PREINIT:
        MyLogger* mylogger;
        HV*           opts = NULL;
        SV **svp;
CODE:
{
    Newxz( mylogger, 1, MyLogger );
    RETVAL = mylogger;

    if( items > 1 ) { /* could also probably use va_start, va_list, ... */
        SV *extra = (SV*) ST(1);

        if ( SvROK(extra) && SvTYPE(SvRV(extra)) == SVt_PVHV )
            opts = (HV*) SvRV( extra );
    }

    /* default (non zero) values */
    mylogger->use_color = true; /* maybe use a GV from the stash to set the default value */
    if ( opts ) {
        if ( (svp = hv_fetchs(opts, "color", FALSE)) ) {
            if (!SvIOK(*svp)) croak("invalid color option value: should be a boolean 1/0");
            mylogger->use_color = (bool) SvIV(*svp);
        }
        if ( (svp = hv_fetchs(opts, "level", FALSE)) ) {
            if (!SvIOK(*svp)) croak("invalid log level: should be one integer");
            mylogger->level = (logLevel) SvIV(*svp);
        }
        if ( (svp = hv_fetchs(opts, "quiet", FALSE)) ) {
            if (!SvIOK(*svp)) croak("invalid quiet value: should be one integer 0 or 1");
            mylogger->quiet = (logLevel) SvIV(*svp);
        }
        if ( (svp = hv_fetchs(opts, "logfile", FALSE)) || (svp = hv_fetchs(opts, "path", FALSE)) ) {
            STRLEN len;
            char *src;

            if (!SvPOK(*svp)) croak("invalid logfile path: must be a string");
            src = SvPV(*svp, len);
            if (len >= sizeof(mylogger->filepath))
                croak("file path too long max=256!");
            strcpy(mylogger->filepath, src); /* do a copy to the object */
        }
    }
}
OUTPUT:
    RETVAL

void
xlog_loggers(...)
ALIAS:
        XS::Logger::info                 = 1
        XS::Logger::warn                 = 2
        XS::Logger::error                = 3
        XS::Logger::die                  = 4
        XS::Logger::panic                = 5
        XS::Logger::fatal                = 6
        XS::Logger::debug                = 7
PREINIT:
        SV *ret;
        SV* self; /* optional */
CODE:
{
     logLevel level = LOG_DISABLE;
     bool dolog = true;
     MyLogger* mylogger = NULL; /* can be null when not called on an object */
     int args_start_at = 0;
     bool should_die = false;
     const char *fmt;
     MultiValue targs[10] = {0}; /* no need to malloc limited to 10 */

     switch (ix) {
         case 1: /* info */
             level = LOG_INFO;
         break;
         case 2: /* warn */
             level = LOG_WARN;
         break;
         case 3: /* error */
            level = LOG_ERROR;
         break;
         case 4: /* die */
            level = LOG_ERROR;
            should_die = true;
         break;
         case 5: /* panic */
         case 6: /* fatal */
            level = LOG_FATAL;
            should_die = true;
         break;
         case 7:
            level = LOG_DEBUG;
         break;
         default:
            level = LOG_DISABLE;
     }

     /* check if called as function or method call */
     if ( items && SvROK(ST(0)) && SvOBJECT(SvRV(ST(0))) ) { /* check if self is an object */
        self = ST(0);
        args_start_at = 1;
        mylogger = INT2PTR(MyLogger*, SvIV(SvRV(self)));
        /* check the caller level */
        if ( level < mylogger->level )
            dolog = false;
     }

     if (dolog) {
        SV **list;
        if ( items < (1 + args_start_at) ) {
            fmt = EMPTY_STR;
            do_log( mylogger, level, fmt, 0 ); /* do a simple call */
        } else if ( items <= ( 11 + args_start_at ) ) { /* set a cap on the maximum of item we can use: 10 arguments + 1 format + 1 for self */
            IV i;
            I32 nitems = items - args_start_at; /* for self */

            //Newx(list, nitems, SV*);
            for ( i = args_start_at ; i < items ; ++i ) {
                SV *sv = ST(i);
                if ( !SvOK(sv) )
                    croak( "Invalid element item %i - not an SV.", (int) i );
                else {
                    /* do a switch on the type */
                    if ( i == args_start_at ) { /* the first entry shoulkd be the format */
                        if ( !SvPOK(sv) ) { /* maybe upgrade to a PV */
                            if ( SvIOK(sv) )
                                 SvUPGRADE(sv, SVt_PVIV);
                            else
                                croak("First argument must be a string.");
                        }
                        fmt = SvPV_nolen( sv );
                    } else {
                        int ix = i - 1 - args_start_at;

                        if ( SvIOK(sv) ) { /* SvTYPE(sv) == SVt_IV */
                            targs[ix].ival = SvIV(sv);
                        } else if ( SvNOK(sv) ) { // not working for now
                            //PerlIO_printf( PerlIO_stderr(), "# SV SV %f\n", 1.345 );
                            //PerlIO_printf( PerlIO_stderr(), "# SV SV %f\n", SvNV(sv) );
                            targs[ix].fval = SvNV(sv);
                        } else {
                            targs[ix].sval = SvPV_nolen(sv);
                        }
                    }
                }
            }
            /* not really necessary but probaby better for performance */
            switch ( nitems ) {
                case 1:
                do_log( mylogger, level, fmt, nitems,
                        targs[0]
                );
                break;
                case 2:
                do_log( mylogger, level, fmt, nitems,
                        targs[0], targs[1]
                );
                break;
                case 3:
                do_log( mylogger, level, fmt, nitems,
                        targs[0], targs[1], targs[2]
                );
                break;
                case 4:
                do_log( mylogger, level, fmt, nitems,
                        targs[0], targs[1], targs[2], targs[3]
                );
                break;
                case 5:
                do_log( mylogger, level, fmt, nitems,
                        targs[0], targs[1], targs[2], targs[3], targs[4]
                );
                break;
                case 6:
                do_log( mylogger, level, fmt, nitems,
                        targs[0], targs[1], targs[2], targs[3], targs[4],
                        targs[5]
                );
                break;
                case 7:
                do_log( mylogger, level, fmt, nitems,
                        targs[0], targs[1], targs[2], targs[3], targs[4],
                        targs[5], targs[6]
                );
                break;
                case 8:
                do_log( mylogger, level, fmt, nitems,
                        targs[0], targs[1], targs[2], targs[3], targs[4],
                        targs[5], targs[6], targs[7]
                );
                break;
                case 9:
                do_log( mylogger, level, fmt, nitems,
                        targs[0], targs[1], targs[2], targs[3], targs[4],
                        targs[5], targs[6], targs[7], targs[8]
                );
                break;
                case 10:
                do_log( mylogger, level, fmt, nitems,
                        targs[0], targs[1], targs[2], targs[3], targs[4],
                        targs[5], targs[6], targs[7], targs[8], targs[9]
                );
                break;
                default:
                do_log( mylogger, level, fmt, nitems,
                        targs[0], targs[1], targs[2], targs[3], targs[4],
                        targs[5], targs[6], targs[7], targs[8], targs[9]
                );
            }
        } else {
            croak("Too many args to the caller (max=10).");
        }
     } /* end of dolog */

     if ( should_die ) /* maybe fatal needs to exit */ {
         /* FIXME: right now only using the fmt without the args */
        /* exit level [panic] [pid=6904] (This is a message) */
        croak( "exit level [%s] [pid=%d] (%s)\n", LOG_LEVEL_NAMES_lc[level], getpid(),
            fmt
        );
     }

     /* no need to return anything there */
     XSRETURN_EMPTY;
}

SV*
xlog_getters(self)
    XS::Logger self;
ALIAS:
     XS::Logger::get_pid               = 1
     XS::Logger::use_color             = 2
     XS::Logger::get_level             = 3
     XS::Logger::get_quiet             = 4
     XS::Logger::get_file_path         = 5
     XS::Logger::logfile               = 5
PREINIT:
    MyLogger* mylogger;
    char *fp;
CODE:
{   /* some getters: mainly used for test for now to access internals */

    switch (ix) {
        case 1:
             RETVAL = newSViv( self->pid );
        break;
        case 2:
             RETVAL = newSViv( self->use_color );
        break;
        case 3:
             RETVAL = newSViv( (int) self->level );
        break;
        case 4:
             RETVAL = newSViv( (int) self->quiet );
        break;
        case 5:
        	 fp = _file_path_for_logger( self );
             RETVAL = newSVpv( fp, strlen(fp) );
        break;        
        default:
             XSRETURN_EMPTY;
     }
}
OUTPUT:
    RETVAL

void
xlog_setters(self, value)
    XS::Logger self;
    SV* value;
ALIAS:
     XS::Logger::set_level             = 1
     XS::Logger::set_quiet             = 2
PREINIT:
    MyLogger* mylogger;
CODE:
{   /* improve protection on self/logger here */
 
    switch (ix) {
        case 1:
            if ( !SvIOK(value) ) croak("invalid level: must be interger.");
             self->level = SvIV(value);
        break;
        case 2:
            if ( !SvIOK(value) ) croak("invalid quiet value: must be interger.");
             self->quiet = SvIV(value);
        break;
        default:
             croak("undefined setter");
     }

     XSRETURN_EMPTY;
}

void xlog_DESTROY(self)
    XS::Logger self;
PREINIT:
        I32* temp;
PPCODE:
{
        temp = PL_markstack_ptr++;

        if ( self ) {
            /* close the file fhandle on destroy if exists */
            if ( self->fhandle )
                fclose( self->fhandle );
            /* free the logger... maybe more to clear from struct */
            Safefree(self);
        }

        if (PL_markstack_ptr != temp) {
            /* truly void, because dXSARGS not invoked */
            PL_markstack_ptr = temp;
            XSRETURN_EMPTY;
            /* return empty stack */
        }  /* must have used dXSARGS; list context implied */

        return;  /* assume stack size is correct */
}

BOOT:
{
    HV *stash;
    SV *sv;
    stash = gv_stashpvn("XS::Logger", 10, TRUE);

    newCONSTSUB(stash, "_loaded", newSViv(1) );
    newCONSTSUB(stash, "DEBUG_LOG_LEVEL", newSViv( LOG_DEBUG ) );
    newCONSTSUB(stash, "INFO_LOG_LEVEL", newSViv( LOG_INFO ) );
    newCONSTSUB(stash, "WARN_LOG_LEVEL", newSViv( LOG_WARN ) );
    newCONSTSUB(stash, "ERROR_LOG_LEVEL", newSViv( LOG_ERROR ) );
    newCONSTSUB(stash, "FATAL_LOG_LEVEL", newSViv( LOG_FATAL ) );
    newCONSTSUB(stash, "DISABLE_LOG_LEVEL", newSViv( LOG_DISABLE ) );

    sv = get_sv("XS::Logger::PATH_FILE", GV_ADD|GV_ADDMULTI);
    if ( ! SvPOK(sv) ) { /* preserve any value set before loading the module */
        SvREFCNT_inc(sv);
        sv_setpv(sv, DEFAULT_LOG_FILE);
    }
}
