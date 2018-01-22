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

static const char *DEFAULT_LOG_FILE = "/var/log/xslogger.log";

/* some constants */
static const char *LOG_LEVEL_NAMES[] = {
  "DEBUG", "INFO", "WARN", "ERROR", "FATAL" /* , "DISABLE" */
};

static const char *END_COLOR = "\x1b[0m";
static const char *LEVEL_COLORS[] = {
  "\x1b[94m", "\x1b[36m", "\x1b[33m", "\x1b[1;31m", "\x1b[1;35m" /* "\x1b[1;35m"  */
};

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

	localtime_r(&t, &lt);

	if ( level == LOG_DISABLE ) /* to move earlier */
		return;

	buf[strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M:%S", &lt)] = '\0';

	/* Note: *mylogger can be a NULL pointer => would fall back to a GV string or a constant from .c to get the filename */

	if ( mylogger ) { /* we got a mylogger pointer */
		if ( mylogger->filepath && strlen(mylogger->filepath) )
			path = mylogger->filepath;
		else {
			path = get_default_file_path();
		}

		pid = getpid();
		if ( mylogger->pid && mylogger->pid != pid ) {
			if (mylogger->fhandle) close(mylogger->fhandle);
			mylogger->fhandle = NULL;
		}

		if ( ! mylogger->fhandle ) {
			/* FIXME -- probably do not use PerlIO layer at all */
			if ( (fhandle = fopen( path, "a" )) == NULL ) /* open in append mode */
				croak("Failed to open file \"%s\"", path);
			mylogger->fhandle = fhandle; /* save the fhandle for future reuse */
			mylogger->pid = pid; /* store the pid which open the file */

			ACQUIRE_LOCK_ONCE(fhandle); /* get a lock before moving to the end */
			fseek(fhandle, 0, SEEK_END);
		}

		fhandle = mylogger->fhandle;
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

		if (num_args) va_start(args, num_args);

		ACQUIRE_LOCK_ONCE(fhandle);

		/* write the message */
		/* header: [timestamp tz] pid LEVEL */
		if ( mylogger && mylogger->use_color ) {
			fprintf( fhandle, "[%s % 03d%02d] %d %s%-5s%s: ",
				 buf, (int) lt.tm_gmtoff / 3600, ( lt.tm_gmtoff % 3600) / 60,
				 (int) pid,
				 LEVEL_COLORS[level], LOG_LEVEL_NAMES[level], END_COLOR
			);
		} else {
			fprintf( fhandle, "[%s % 03d%02d] %d %-5s: ",
				 buf, (int) lt.tm_gmtoff / 3600, ( lt.tm_gmtoff % 3600) / 60,
				 (int) pid,
				 LOG_LEVEL_NAMES[level]
			);
		}

		{
			int len = 0;
			//PerlIO_printf( PerlIO_stderr(), "# num_args %d\n", num_args );
			if ( fmt && (len=strlen(fmt)) ) {
				if (num_args == 0)  /* no need to use sprintf when not needed */
					fputs( fmt, fhandle );
				else
					vfprintf( fhandle, fmt, args );
			}

			// only add "\n" if missing from fmt
			if ( !len || fmt[len-1] != '\n')
				fputs( "\n", fhandle );
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

SV*
xlog_new(class, ...)
    char* class;
PREINIT:
	    MyLogger* mylogger;
	    SV*            obj;
	    HV*           opts = NULL;
	    SV **svp;
CODE:
{

	char tmpbuf[256] = {0};
	/* mylogger = malloc(sizeof(MyLogger)); */ /* malloc our object */
	Newxz( mylogger, 1, MyLogger);
	RETVAL = newSViv(0);
	obj = newSVrv(RETVAL, class); /* bless our object */

	if( items > 1 ) { /* could also probably use va_start, va_list, ... */
		SV *extra = (SV*) ST(1);
		if ( SvROK(extra) && SvTYPE(SvRV(extra)) == SVt_PVHV )
			opts = (HV*) SvRV( extra );
	}

	/* default (non zero) values */
	mylogger->use_color = true; /* maybe use a GV from the stash to set the default value */

	if ( opts ) {
		if ( svp = hv_fetchs(opts, "color", FALSE) ) {
			if (!SvIOK(*svp)) croak("invalid color option value: should be a boolean 1/0");
			mylogger->use_color = (bool) SvIV(*svp);
		}

		if ( svp = hv_fetchs(opts, "level", FALSE) ) {
			if (!SvIOK(*svp)) croak("invalid log level: should be one integer");
			mylogger->level = (logLevel) SvIV(*svp);
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

	sv_setiv(obj, PTR2IV(mylogger)); /* get a pointer to our malloc object */
	SvREADONLY_on(obj);
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

     	if ( items < (1 + args_start_at) ) { /* */
     		/* maybe croak ?? */
     		//croak("Need more args")
     		do_log( mylogger, level, "", 0 ); /* do a simple call */
     	} else if ( items <= ( 11 + args_start_at ) ) { /* set a cap on the maximum of item we can use: 10 arguments + 1 format + 1 for self */
     		IV i;
     		I32 nitems = items - args_start_at; /* for self */
     		const char *fmt;
     		MultiValue targs[10]; /* no need to malloc limited to 10 */

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

      		//PerlIO_printf( PerlIO_stderr(), "# something %d\n", 42 );
 			// can switch on the number of arguments
      		do_log( mylogger, level, fmt, items - args_start_at,
					targs[0], targs[1], targs[2], targs[3], targs[4],
      				targs[5], targs[6], targs[7], targs[8], targs[9]
      		);

     	} else {
     		croak("Too many args to the caller (max=10).");
     	}
     }

     if ( should_die ) /* maybe fatal needs to exit */
     	croak( "XS::Logger - die/fatal event logged" );

     /* no need to return anything there */
     XSRETURN_EMPTY;
}

SV*
xlog_getters(self)
    SV* self;
ALIAS:
     XS::Logger::get_pid               = 1
     XS::Logger::use_color             = 2
     XS::Logger::get_level             = 3
PREINIT:
	MyLogger* mylogger;
CODE:
{   /* some getters: mainly used for test for now to access internals */
	mylogger = INT2PTR(MyLogger*, SvIV(SvRV(self)));

    switch (ix) {
        case 1:
             RETVAL = newSViv( mylogger->pid );
        break;
        case 2:
             RETVAL = newSViv( mylogger->use_color );
        break;
        case 3:
             RETVAL = newSViv( (int) mylogger->level );
        break;
        default:
             XSRETURN_EMPTY;

     }
}
OUTPUT:
	RETVAL

void
xlog_setters(self, value)
    SV* self;
    SV* value;
ALIAS:
     XS::Logger::set_level             = 1
PREINIT:
	MyLogger* mylogger;
CODE:
{   /* improve protection on self/logger here */
	mylogger = INT2PTR(MyLogger*, SvIV(SvRV(self)));
    switch (ix) {
        case 1:
        	if ( !SvIOK(value) ) croak("invalid level: must be interger.");
             mylogger->level = SvIV(value);
        break;
        default:
             croak("undefined setter");
     }

     XSRETURN_EMPTY;
}

void DESTROY(self)
    SV* self;
PREINIT:
	    I32* temp;
	    MyLogger* mylogger;
PPCODE:
{
	    temp = PL_markstack_ptr++;

	    if ( self && SvROK(self) && SvOBJECT(SvRV(self)) ) { /* check if self is an object */
		    mylogger = INT2PTR(MyLogger*, SvIV(SvRV(self)));
		    /* close the file fhandle on destroy if exists */
		    if ( mylogger->fhandle )
		    	fclose( mylogger->fhandle );
		    /* free the logger... maybe more to clear from struct */
		    free(mylogger);
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