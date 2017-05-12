/* -------------------------------------------------------------------
   nsapi_perl.c - embed Perl interpreter in a Netscape web server

   Copyright (C) 1997, 1998 Benjamin Sugars

   This is free software; you can redistribute it and/or modify it
   under the same terms as Perl itself.

   This software is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this software. If not, write to the Free Software
   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
   ------------------------------------------------------------------- */

#include "base/util.h"
#include "base/pblock.h"
#include "base/session.h"
#include "base/cinfo.h"
#ifdef NP_USE_CRITICAL
#include "base/crit.h"
#endif
#include "frame/req.h"
#include "frame/log.h"
#include "frame/protocol.h"
#include <EXTERN.h>
#include <perl.h>
#include <string.h>
#include "nsapi_perl.h"

/* The perl interpreter */
static PerlInterpreter *nsapi_perl;

/* Critical-section variable */
#ifdef NP_USE_CRITICAL
static CRITICAL handler_crit;
#endif

/* Trace variables */
#ifdef NP_USE_CRITICAL
static CRITICAL traceLog_crit;
#endif
static FILE *tfp = NULL;
static int trace = 0;

/*
 * nsapi_perl_init() - loads perl interpreter
 */

NSAPI_PUBLIC int nsapi_perl_init(pblock * pb, Session * sn, Request * rq)
{
    char *init_script, *shlib, *tf;
    char *perl_argv[2];
    SV *perl_version;
    int exitstatus, i, perl_argc;

#ifdef NP_USE_CRITICAL
    handler_crit = crit_init();
#endif

    /* enable tracing ? */
    if ((tf = pblock_findval("tracelog", pb)) && (tfp = fopen(tf, "a+"))) {
#ifdef NP_USE_CRITICAL
	traceLog_crit = crit_init();
#endif
	trace = 1;
	log_error(LOG_INFORM, "nsapi_perl_init", sn, rq,
		  "tracing enabled. Writing to tracefile %s", tf);
    }

    /* Some OSs don't make their symbols global by default.
       This function takes care of that. */
    shlib = pblock_findval("shlib", pb);
    if (shlib == NULL) {
      shlib = pblock_findval("libperl", pb);
      if (shlib != NULL) {
	/* They're using old syntax */
	log_error(LOG_INFORM, "nsapi_perl_init", sn, rq,
		  "warning: use of 'libperl' parameter to nsapi_perl_init is deprecated");
      }
    }
    if (shlib != NULL) {
      if (!(nsapi_perl_bootstrap(sn, rq, shlib))) {
	log_error(LOG_CATASTROPHE, "nsapi_perl_init", sn, rq,
		  "can't globalize perl symbol table");
	return REQ_ABORTED;
      }
    }

    /* Find the location of the init script */
    init_script = pblock_findval("init-script", pb);
    if (init_script == NULL) {
	init_script = pblock_findval("conf", pb);
	if (init_script != NULL) {
	    /* They're using old syntax */
	    log_error(LOG_INFORM, "nsapi_perl_init", sn, rq,
		      "warning: use of 'conf' parameter to nsapi_perl_init is deprecated");
	} else {
	    /* No start-up script specified */
	    init_script = "-e 1;";
	}
    }
    /* Initialise the perl interpreter */
    NP_TRACE(traceLog("nsapi_perl_init: allocating perl interpreter ..."));
    if (!(nsapi_perl = perl_alloc())) {
	NP_TRACE(traceLog(" not ok\n"));
	return REQ_ABORTED;
    }
    NP_TRACE(traceLog(" ok\n"));

    /* Construct interpreter */
    NP_TRACE(traceLog("nsapi_perl_init: constructing perl interpreter\n"));
    perl_construct(nsapi_perl);

    /* Parse and run the start-up script */

    /* Construct an argv for perl to parse */
    perl_argv[0] = (char *) MALLOC(strlen("perl") + 1);
    perl_argv[1] = (char *) MALLOC(strlen(init_script) + 1);
    util_sprintf(perl_argv[0], "perl");
    util_sprintf(perl_argv[1], init_script);
    perl_argc = 2;

    /* Parse the start-up script */
    NP_TRACE(traceLog("nsapi_perl_init: parsing perl script: "));
    for (i = 0; i < perl_argc; i++)
	NP_TRACE(traceLog("'%s' ", perl_argv[i]));
    NP_TRACE(traceLog("..."));
    exitstatus = perl_parse(nsapi_perl, xs_init, perl_argc, perl_argv, NULL);
    if (exitstatus) {
	NP_TRACE(traceLog(" not ok, exitstatus=%d\n", exitstatus));
	log_error(LOG_CATASTROPHE, "nsapi_perl_init", sn, rq, "trouble compiling %s", init_script);
	return REQ_ABORTED;
    }
    NP_TRACE(traceLog(" ok\n"));

    /* Run perl script */
    NP_TRACE(traceLog("nsapi_perl_init: running perl script ..."));
    exitstatus = perl_run(nsapi_perl);
    if (exitstatus) {
	NP_TRACE(traceLog(" not ok, exitstatus=%d\n", exitstatus));
	log_error(LOG_CATASTROPHE, "nsapi_perl_init", sn, rq, "trouble running %s", init_script);
	return REQ_ABORTED;
    }
    NP_TRACE(traceLog(" ok\n"));

    /* Preload base modules */
    if (!gv_stashpv("Netscape::Server::Session", FALSE))
	nsapi_perl_require_module(sn, rq, "Netscape::Server::Session");
    if (!gv_stashpv("Netscape::Server::Request", FALSE))
	nsapi_perl_require_module(sn, rq, "Netscape::Server::Request");

    /* Get the version of the perl interpreter */
    perl_version = perl_get_sv("main::]", FALSE);

    /* Looks good.  Print out a progress message */
    log_error(LOG_INFORM, "nsapi_perl_init", sn, rq,
	 "loaded a perl version %s interpreter", SvPV(perl_version, na));
    NP_TRACE(traceLog("nsapi_perl_init: loaded perl version %s\n", SvPV(perl_version, na)));
    return REQ_PROCEED;
}

/* Hack to make perl symbol table global.  Right now only tested
   under Solaris, but will be made more portable soon? */
int nsapi_perl_bootstrap(Session *sn, Request *rq, char *shlib)
{
#ifdef NP_USE_NP_BOOTSTRAP
  log_error(LOG_INFORM, "nsapi_perl_bootstrap", sn, rq,
	    "calling dlopen(\"%s\", RTLD_LAZY|RTLD_GLOBAL)", shlib);
  if (dlopen(shlib, RTLD_LAZY|RTLD_GLOBAL) == NULL) {
    log_error(LOG_INFORM, "nsapi_perl_bootstrap", sn, rq,
	      "dlopen of %s: %s", shlib, dlerror());
    return(0);
  }
  log_error(LOG_INFORM, "nsapi_perl_bootstrap", sn, rq,
	    "dlopen of %s ok", shlib);
  return(1);
#else
  return(1);
#endif
}

/*
 * nsapi_perl_handler() - handles requests to run perl modules
 */

NSAPI_PUBLIC int nsapi_perl_handler(pblock * pb, Session * sn, Request * rq)
{
    char *module, *sub;
    int count;
    I32 response;

    /* Get name of module::sub to call */
    if (!(module = pblock_findval("module", pb))) {
	log_error(LOG_MISCONFIG, "nsapi_perl_handler", sn, rq, "no module argument specified");
	return REQ_ABORTED;
    }
    if (!(sub = pblock_findval("sub", pb)))
	sub = "handler";

#ifdef NP_USE_CRITICAL
    /* Enter critical section; needed for !threaded Perl */
    crit_enter(handler_crit);
#endif

    /* Mostly for catching memory leaks */
    NP_TRACE(traceLog("nsapi_perl_handler: (enter %s::%s) SVs = %5d, OBJs = %5d\n",
		      module, sub, sv_count, sv_objcount));

    {
	/* Enter a new perl scope */
	dSP;
	SV *request;
	SV *session;
	SV *pblock;
	SV *handler;

	/* Convert module name to an sv so we can call perl_call_sv() */
	handler = newSVpv(module, 0);

	/* Require the module; let Perl handle %INC stuff */
	if (nsapi_perl_require_module(sn, rq, module) < 0) {
	    SvREFCNT_dec(handler);
#ifdef NP_USE_CRITICAL
	    crit_exit(handler_crit);
#endif
	    return REQ_ABORTED;
	}
	/* Finish building SV */
	sv_catpv(handler, "::");
	sv_catpv(handler, sub);

	/* Start of lifespan for mortals */
	ENTER;
	SAVETMPS;
	PUSHMARK(sp);

	/* Create the Request and Session objects */
	request = nsapi_perl_bless_request(rq);
	session = nsapi_perl_bless_session(sn);

	/* Create the pb hash table */
	pblock = nsapi_perl_pblock2hash_ref(pb);

	/* Call the sucker */
	XPUSHs(pblock);
	XPUSHs(session);
	XPUSHs(request);
	PUTBACK;
	count = perl_call_sv(handler, G_SCALAR | G_EVAL);
	SPAGAIN;

	/* Determine return code */
	if (nsapi_perl_eval_ok(sn, rq) != 0) {
	    log_error(LOG_MISCONFIG, "nsapi_perl_handler", sn, rq,
		      "call to '%s' failed on eval\n", SvPV(handler, na));
	    NP_TRACE(traceLog("nsapi_perl_handler: call to '%s' ... not ok; failed on eval", SvPV(handler, na)));
	    response = REQ_ABORTED;
	} else if (count != 1) {
	    log_error(LOG_MISCONFIG, "nsapi_perl_handler", sn, rq,
	    "no return value from '%s'; assuming ok", SvPV(handler, na));
	    NP_TRACE(traceLog("nsapi_perl_handler: no return value from '%s' ... assuming ok\n", SvPV(handler, na)));
	    response = REQ_PROCEED;
	} else {
	    response = POPi;
	    NP_TRACE(traceLog("nsapi_perl_handler: '%s' returned %d\n", SvPV(handler, na), response));
	    if (response == 1)
		response = REQ_PROCEED;
	}

	/* Cleanup */
	PUTBACK;
	FREETMPS;
	LEAVE;
	SvREFCNT_dec(handler);
    }

    /* Mostly for debugging */
    NP_TRACE(traceLog("nsapi_perl_handler: (leave %s::%s) SVs = %5d, OBJs = %5d\n",
		      module, sub, sv_count, sv_objcount));

    /* Leave critical section */
#ifdef NP_USE_CRITICAL
    crit_exit(handler_crit);
#endif

    /* Done */
    return (response);
}

/*
 * nsapi_perl_bless*() - blessess the Session and Request objects
 */

SV* nsapi_perl_bless_request(Request * rq)
{
    SV *request = sv_newmortal();
    sv_setref_iv(request, "Netscape::Server::Request", (IV) rq);
    return (request);
}

SV* nsapi_perl_bless_session(Session * sn)
{
    SV *session = sv_newmortal();
    sv_setref_iv(session, "Netscape::Server::Session", (IV) sn);
    return (session);
}

/*
 * nsapi_perl_require_module() - requires a module.   This function
 *        was borrowed more or less from mod_perl perl_require_module.
 *        Running this routine over having perl do a "use" saves about
 *        100k of space per module.
 */

int nsapi_perl_require_module(Session * sn, Request * rq, char *mod)
{
    SV *code = newSV(100);
    SV *m = newSVpv(mod, 0);

    NP_TRACE(traceLog("nsapi_perl_require_module: loading perl module '%s' ...\n", mod));
    sv_setpv(code, "require ");
    sv_catsv(code, m);
    perl_eval_sv(code, G_DISCARD);
    SvREFCNT_dec(m);
    if (nsapi_perl_eval_ok(sn, rq) != 0) {
	log_error(LOG_MISCONFIG, "nsapi_perl_require_module", sn, rq,
		  "error running '%s'", SvPV(code, na));
	(void) SvREFCNT_dec(code);
	NP_TRACE(traceLog("nsapi_perl_require_module: error running '%s'\n", code));
	return -1;
    }
    (void) SvREFCNT_dec(code);
    NP_TRACE(traceLog("nsapi_perl_require_module: '%s' loaded ok\n", mod));
    return 0;
}

/*
 * nsapi_perl_eval_ok() - check $@ for errors
 */

int nsapi_perl_eval_ok(Session * sn, Request * rq)
{
    SV *eval_error;

    eval_error = GvSV(gv_fetchpv("@", TRUE, SVt_PV));
    if (SvTRUE(eval_error)) {
	/* Ooops.  Error during eval */
	log_error(LOG_MISCONFIG, "nsapi_perl_eval_ok", sn, rq,
		  "%s", SvPV(eval_error, na));
	NP_TRACE(traceLog("perl_eval_ok: ERROR: %s", SvPV(eval_error, na)));
	return -1;
    }
    return 0;
}

/*
 * traceLog() - syncronized logging facility
 */

NSAPI_PUBLIC void traceLog(char *fmt,...)
{
    va_list marker;

    va_start(marker, fmt);
#ifdef NP_USE_CRITICAL
    crit_enter(traceLog_crit);
#endif
    if (tfp) {
	vfprintf(tfp, fmt, marker);
	fflush(tfp);
    }
#ifdef NP_USE_CRITICAL
    crit_exit(traceLog_crit);
#endif
    va_end(marker);
}
