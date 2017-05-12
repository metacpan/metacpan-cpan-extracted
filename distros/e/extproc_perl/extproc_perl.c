/* $Id: extproc_perl.c,v 1.44 2006/08/11 13:27:35 jeff Exp $ */

#ifdef __cplusplus
extern "C" {
#endif
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <time.h>
#include <oci.h>

/* Perl headers */
#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>

#include "extproc_perl.h"
#ifdef __cplusplus
}
#endif

#define EXTPROC_PERL_VERSION    "2.51"

/* register termination function */
#if defined(__SUNPRO_C)
#    pragma fini(ep_fini)    
#elif defined(__GNUC__)
#    if defined(__i386__) && (defined(sun) || defined(__sun))
        asm (".section .fini\ncall ep_fini");
#    elif defined(__i386__) || defined(__sparc__)
        asm(".section \".fini\"\ncall ep_fini\nnop");
#    elif defined(__alpha__) && defined(__linux)
        asm (".section \".fini\"\njsr ep_fini");
#    endif
#endif

EXTERN_C void xs_init();

/* per-session context -- contains all the globals from version 1 */
EP_CONTEXT my_context; 

extern int errno;

/* initialize context */
void _ep_init(EP_CONTEXT *c, OCIExtProcContext *ctx)
{
    int err, sessionid;

    /* initialize debug & testing to sane values */
    if (c->debug != 1) {
        c->debug = 0;
    }
    if (c->testing != 1) {
        c->testing = 0;
    }

    /* save OCI context for later */
    c->oci_context.ctx = ctx;

    /* for each new transaction, a new extproc "connection" */
    c->connected = 0;

    /* read configuration if necessary */
    if (c->configured != 1) {
        if (!read_config(c, EP_CONFIG_FILE)) {
            ora_exception(c, "FATAL: configuration failed!");
            return;
        }
        c->perl = NULL;
        c->debug = 0;
        c->debug_file = NULL;

        /* get oracle session id for use in namespace */
        if (c->use_namespace) {
            err = get_sessionid(c, &sessionid);
            if (err != OCI_SUCCESS && err !=OCI_SUCCESS_WITH_INFO) {
                ora_exception(c, "FATAL: couldn't retrieve session id from Oracle");
                return;
            }
            snprintf(c->package, 255, "ExtProc::Session%d",
                sessionid);
        }

        c->configured = 1;
    }
}

void ep_debug_enable(EP_CONTEXT *c)
{
    FILE *fp;
    char *fname;
    pid_t pid;

    if (c->debug) return;
    c->debug = 1;

    /* use oracle's memory allocation in case we're unloaded */
    fname = OCIExtProcAllocCallMemory(c->oci_context.ctx, MAXPATHLEN+1);
        
    /* open log file */
    pid = getpid();
    snprintf(fname, MAXPATHLEN, "%s/ep_debug.%d", c->debug_dir, pid);
    if (!(fp = fopen(fname, "a+"))) {
        fprintf(stderr, "extproc_perl: open failed for debug log %s",
            fname);
        return;
    }

    /* redirect stderr to log file */
    dup2(fileno(fp), fileno(stderr));

    /* save file info for future use */
    c->debug_fp = fp;
    /* copy fname so oracle doesn't deallocate it after transaction */
    if (c->debug_file) free(c->debug_file);
    c->debug_file = strdup(fname);
}

void ep_debug_disable(EP_CONTEXT *c)
{
    if (!c->debug) return;

    c->debug = 0;

    /* close log file & stderr */
    fclose(c->debug_fp);
    c->debug_fp = NULL;
    fclose(stderr);
}

void ep_debug(EP_CONTEXT *c, char *fmt, ...)
{
    va_list ap;
    int n = 0;
    time_t t;
    char *ts;

    dTHX;

    va_start(ap, fmt);
    t = time(NULL);
    ts = ctime(&t);
    ts[strlen(ts)-1] = '\0';
    fprintf(c->debug_fp, "%s ", ts);
    vfprintf(c->debug_fp, fmt, ap);
    fprintf(c->debug_fp, "\n");
    fflush(c->debug_fp);
}

void ora_exception(EP_CONTEXT *c, char *msg)
{
    char str[1024];

    snprintf(str, 1023, "PERL EXTPROC ERROR: %s\n", msg);
    OCIExtProcRaiseExcpWithMsg(c->oci_context.ctx, ORACLE_USER_ERR, str, 0);
}

/* convert colon-delimited inc_path to a "-Mlib=path1,path2" construct */
/* this is easier than dealing with multiple "-I" flags */
char *inc_path_to_mflag(EP_CONTEXT *c)
{
    char *p, *q, *flags = NULL;
    int n = 0;

    EP_DEBUGF(c, "IN inc_path_to_mflag(%p)", c);

    if (!strcmp(c->inc_path, "")) return NULL;

    /* make volatile copy */
    q = strdup(c->inc_path);

    /* NEED TO MAKE THIS THREAD-SAFE WITH strtok_r */
    for (p = strtok(q, ":") ; p ; p = strtok(NULL, ":")) {
        if (n == 0) {
            flags = OCIExtProcAllocCallMemory(c->oci_context.ctx, 4096);
            *flags = '\0';
            strcat(flags, "-Mlib=");
        }
        else {
            strcat(flags, ",");
        }
        /* chance of overflow here -- should check bounds */
        strcat(flags, p);
        n++;
    }

    free(q);

    EP_DEBUGF(c, "-- using mflag '%s'", flags);

    return(flags);
}

PerlInterpreter *pl_startup(EP_CONTEXT *c)
{
    PerlInterpreter *p;
    int argc, n = 0;
    char *argv[5], *mflag, bootcode[1024];
    struct stat st;
    SV *sv;

    dTHX;

    dSP;

    EP_DEBUGF(c, "IN pl_startup(%p)", c);


    /* create interpreter */
    if((p = perl_alloc()) == NULL) {
        EP_DEBUG(c, "perl_alloc() failed!");
        return(NULL);
    }

    /* destroy EVERYTHING during during perl_destruct() */
    PL_perl_destruct_level = 1;

    perl_construct(p);
    EP_DEBUGF(c, "-- Perl interpreter created: p=%p", p);

    argv[0] = "";
    if ((mflag = inc_path_to_mflag(c))) {
        argv[1] = mflag;
        n = 2;
    }
    else {
        n = 1;
    }
    EP_DEBUG(c, "RETURN pl_startup");
    if (c->tainting) {
        argv[n] = "-T";
        argv[n+1] = "-e";
        argv[n+2] = "0";
        argc = n+3;
    }
    else {
        argv[n] = "-e";
        argv[n+1] = "0";
        argc = n+2;
    }

    if (argc == 2) EP_DEBUGF(c, "-- perl_parse argv: '%s'", argv[1]);
    if (argc == 3) EP_DEBUGF(c, "-- perl_parse argv: '%s','%s'", argv[1], argv[2]);
    if (argc == 4) EP_DEBUGF(c, "-- perl_parse argv: '%s','%s','%s'", argv[1], argv[2], argv[3]);
    if (argc == 5) EP_DEBUGF(c, "-- perl_parse argv: '%s','%s','%s','%s'", argv[1], argv[2], argv[3], argv[4]);

    if (!perl_parse(p, xs_init, argc, argv, NULL)) {
        if (!perl_run(p)) {
            EP_DEBUGF(c, "-- using bootstrap file '%s'",
                c->bootstrap_file);

            if (c->use_namespace) {
                snprintf(bootcode, 1024,
                    "package %s; use ExtProc::Code; do '%s'; package main;",
                    c->package, c->bootstrap_file);
            }
            else {
                snprintf(bootcode, 1024, "use ExtProc::Code; do '%s';",
                    c->bootstrap_file);
            }
            if (c->use_namespace) {
                EP_DEBUGF(c, "-- using namespace %s", c->package);
            }
            sv = newSVpv(bootcode, 0);
            eval_sv(sv, G_DISCARD|G_KEEPERR|G_NOARGS);
            SvREFCNT_dec(sv);
            if (SvTRUE(ERRSV)) {
                EP_DEBUGF(c, "-- FATAL: bootstrap failed: %s",
                    SvPV(ERRSV, PL_na));
                ora_exception(c, SvPV(ERRSV, PL_na));
                perl_destruct(p);
                perl_free(p);
                return(NULL);
            }

            EP_DEBUG(c, "-- bootstrapping successful!");
            return(p);
        }
        EP_DEBUG(c, "-- FATAL: bootstrap failed in perl_run()");
        ora_exception(c, "-- FATAL: bootstrap failed in perl_run()");
        return(NULL);
    }
    EP_DEBUG(c, "-- FATAL: bootstrap failed in perl_parse()");
    ora_exception(c, "-- FATAL: bootstrap failed in perl_parse()");
    return(NULL);
}

void pl_shutdown(EP_CONTEXT *c)
{
    EP_DEBUGF(c, "IN pl_shutdown(%p)", c);
    perl_destruct(c->perl);
    perl_free(c->perl);
}

/* called when extproc_perl.so is unloaded */
void ep_fini(void)
{
    EP_CONTEXT *c = &my_context;

    dTHX;

    if (!c->perl) return;

    /* call registered extproc_perl destructors -- don't die on error */
    call_pv("ExtProc::destroy", G_VOID|G_EVAL);

    /* shutdown debugging */
    if (c->debug) {
        EP_DEBUG(c, "STOP");
        ep_debug_disable(c);
    }

    /* shutdown gracefully so we can call destructors and free memory */
    pl_shutdown(&my_context);
}

/* *_null functions are for maniuplating NULL oracle types */

int is_null(void *p)
{
    HV *nullhv;
    char key[80];
    EP_CONTEXT *c = &my_context;

    dTHX;

    EP_DEBUGF(c, "IN is_null(%p)", p);
    nullhv = get_hv("ExtProc::_nullhv", TRUE);
    snprintf(key, 80, "%p", p);
    return hv_exists(nullhv, key, strlen(key)) ? 1 : 0;
}

void set_null(void *p)
{
    HV *nullhv;
    char key[80];
    EP_CONTEXT *c = &my_context;

    dTHX;

    EP_DEBUGF(c, "IN set_null(%p)", p);
    nullhv = get_hv("ExtProc::_nullhv", TRUE);
    snprintf(key, 80, "%p", p);
    hv_store(nullhv, key, strlen(key), &PL_sv_yes, 0);
}

void clear_null(void *p)
{
    HV *nullhv;
    char key[80];
    EP_CONTEXT *c = &my_context;

    dTHX;

    EP_DEBUGF(c, "IN clear_null(%p)", p);
    nullhv = get_hv("ExtProc::_nullhv", TRUE);
    snprintf(key, 80, "%p", p);
    hv_delete(nullhv, key, strlen(key), G_DISCARD);
}

int get_parsed_sub_version(char *name)
{
    HV *versionhv;
    SV **versionsv;
    int version;
    EP_CONTEXT *c = &my_context;

    dTHX;

    EP_DEBUGF(c, "IN get_parsed_sub_version(\"%s\")", name);
    versionhv = get_hv("ExtProc::_sub_version", TRUE);
    versionsv = hv_fetch(versionhv, name, strlen(name), 0);

    if (!versionsv) return(0);
    version = SvIV(*versionsv);
    return(version);
}

void set_parsed_sub_version(char *name, int version)
{
    HV *versionhv;
    SV *versionsv;
    EP_CONTEXT *c = &my_context;

    dTHX;

    EP_DEBUGF(c, "IN set_parsed_sub_version(\"%s\", %d)", name, version);
    versionhv = get_hv("ExtProc::_sub_version", TRUE);
    versionsv = newSViv(version);
    hv_store(versionhv, name, strlen(name), versionsv, 0);
}

static char *call_perl_sub(EP_CONTEXT *c, char *sub, char **args)
{
    STRLEN len;
    int nret;
    char *tmp, *retval, **p;
    SV *sv;

    dTHX;

    dSP;

    EP_DEBUGF(c, "IN call_perl_sub(%p, \"%s\", ...)", c, sub);

    /* push arguments onto stack */
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    p = args;
    while (*p) {
        sv = sv_2mortal(newSVpv(*p++,0));
        if (c->tainting) {
            SvTAINTED_on(sv);
        }
        XPUSHs(sv);
    }
    PUTBACK;

    /* run subroutine */
    EP_DEBUG(c, "-- about to call call_pv()");
    nret = call_pv(sub, G_SCALAR|G_EVAL);
    EP_DEBUGF(c, "-- call_pv() returned %d", nret);
    SPAGAIN;

    /* grab return value, detecting errors along the way */
    if (SvTRUE(ERRSV) || nret != 1) {
        EP_DEBUGF(c, "-- ERRSV is defined: %s", SvPV(ERRSV, PL_na));
        ora_exception(c, SvPV(ERRSV, PL_na));
        POPs;
        retval = NULL;
    }
    else {
        EP_DEBUG(c, "-- No errors detected");
        sv = POPs;
        tmp = SvPV(sv,len);
        /* use oracle's memory allocation in case we're unloaded */
        retval = OCIExtProcAllocCallMemory(c->oci_context.ctx, len+1);
        Copy(tmp, retval, len, char);
        retval[len] = '\0';
    }

    /* clean up stack and return */
    PUTBACK;
    FREETMPS;
    LEAVE;
    return(retval);
}

char *parse_code(EP_CONTEXT *c, EP_CODE *code, char *sub)
{
    char *fqsub;
    int status, version1, version2, reparse;
    SV *codesv;

    dTHX;

    EP_DEBUGF(c, "IN parse_code(%p, %p, '%s')", c, code, sub);

    /* create fully qualified subroutine name if it's not already */
    if (c->use_namespace && !strchr(sub, ':')) {
        fqsub = OCIExtProcAllocCallMemory(c->oci_context.ctx,
            strlen(c->package) + strlen(sub) + 1);
        snprintf(fqsub, 512, "%s::%s", c->package, sub);
    }
    else {
        fqsub = sub;
    }
    EP_DEBUGF(c, "-- fully qualified sub name is '%s'", fqsub);

    /* is there more recent code in the database? */
    if (c->reparse_subs) {
        EP_DEBUG(c, "-- reparse_subs is enabled");
        version1 = fetch_sub_version(c, sub);
        EP_DEBUG(c, "RETURN parse_code");
        if (version1 < 0) {
            EP_DEBUG(c, "-- error in fetch_sub_version()");
            return(NULL);
        }
        else if (version1 > 0) {
            version2 = get_parsed_sub_version(sub);
            EP_DEBUG(c, "RETURN parse_code");
            EP_DEBUGF(c, "-- parsed version is %d", version2);
            EP_DEBUGF(c, "-- database version is %d", version1);
            reparse = (version1 > version2) ? 1 : 0;
        }
        else {
            reparse = 0;
        }
    }
    else {
        reparse = 0;
    }

    if (reparse || !get_cv(fqsub, FALSE)) {
        /* load code -- fail silently if no code is available */
        EP_DEBUG(c, "-- attempting to fetch code from database");
                
        status = fetch_code(c, code, sub);
        EP_DEBUG(c, "RETURN parse_code");
        if (status != OCI_SUCCESS && status != OCI_SUCCESS_WITH_INFO) {
            EP_DEBUG(c, "-- code fetch failed");
            ora_exception(c, "invalid subroutine");
            return(NULL);
        }

        /* parse code */
        EP_DEBUG(c, "-- eval'ing fetched code");
        TAINT_NOT;
        if (c->use_namespace) {
            ENTER;
            codesv = sv_2mortal(newSVpv("package ", 0));
            sv_catpvf(codesv, "%s;\n", c->package);
            sv_catpv(codesv, code->code);
            sv_catpv(codesv, "\npackage main;\n");
            eval_sv(codesv, G_DISCARD);
            LEAVE;
        }
        else {
            eval_pv(code->code, TRUE);
        }
        TAINT;

        /* check for eval errors */
        if (SvTRUE(ERRSV)) {
            EP_DEBUGF(c, "-- error in eval: %s", SvPV(ERRSV, PL_na));
            ora_exception(c, SvPV(ERRSV, PL_na));
            return(NULL);
        }

        /* try again */
        if (!get_cv(fqsub, FALSE)) {
            EP_DEBUG(c, "-- still no valid CV");
            ora_exception(c, "invalid subroutine");
            return(NULL);
        }

        /* save version */
        set_parsed_sub_version(sub, version1);
        EP_DEBUG(c, "RETURN parse_code");
    }

    EP_DEBUG(c, "-- CV is cached");
    return(fqsub);
}

/* 
 * entry point from oracle function
 * NOTE: use my_context here because we can't pass in our context from oracle
 */
char *ora_perl_func(OCIExtProcContext *ctx, OCIInd *ret_ind, char *sub, ...)
{
    int status, n = 0;
    va_list ap;
    short ind;
    char *args[128], *retval, *errbuf, *fqsub;
    SV *codesv;
    EP_CONTEXT *c;
    EP_CODE code;

    dTHX;

    /* for macros */
    c = &my_context;

    _ep_init(c, ctx);

    EP_DEBUGF(c, "IN ora_perl_func(%p, %p, \"%s\", ...)", ctx, ret_ind, sub);

    c->subtype = EP_SUBTYPE_FUNCTION;

    /* don't allow fully qualified subroutine name if package_subs is off */
    /* exception is ExtProc::* */
    if (strchr(sub, ':') && !c->package_subs) {
        /* keep string compare inside the block for performance */
        if (strncmp(sub, "ExtProc::", 9)) {
            ora_exception(c, "invalid subroutine");
            *ret_ind = OCI_IND_NULL;
            return NULL;
        }
    }

    /* grab arguments, NULL terminated */
    va_start(ap, sub);

    while (n < c->max_sub_args) {
        args[n] = va_arg(ap, char*);
        ind = va_arg(ap, int);
        if (ind == OCI_IND_NULL) {
            args[n] = NULL;
            break;
        }
        n++;
    }
    va_end(ap);

    EP_DEBUGF(c, "-- found %d argument(s)", n);

    /* start perl interpreter if necessary */
    if (!c->perl) {
        c->perl = pl_startup(c);
        EP_DEBUG(c, "RETURN ora_perl_func");
        if (!c->perl) {
            *ret_ind = OCI_IND_NULL;
            return(NULL);
        }
        EP_DEBUGF(c, "-- code table is %s", c->code_table);
    }

    fqsub = parse_code(c, &code, sub);
    if (!fqsub) {
        *ret_ind = OCI_IND_NULL;
        return(NULL);
    }

    /* run subroutine */
    retval = call_perl_sub(c, fqsub, args);
    *ret_ind = retval ? OCI_IND_NOTNULL : OCI_IND_NULL;

    return(retval);
}

/* 
 * entry point from oracle procedure
 * NOTE: use my_context here because we can't pass in our context from oracle
 */
void ora_perl_proc(OCIExtProcContext *ctx, char *sub, ...)
{
    int status, n = 0;
    va_list ap;
    short ind;
    char *args[128], *fqsub;
    EP_CONTEXT *c;
    EP_CODE code;
    SV *codesv;

    dTHX;

    /* for macros */
    c = &my_context;

    _ep_init(c, ctx);

    EP_DEBUGF(c, "IN ora_perl_proc(%p, \"%s\", ...)", ctx, sub);

    c->subtype = EP_SUBTYPE_PROCEDURE;

    /* don't allow fully qualified subroutine name if package_subs is off */
    /* exception is ExtProc::* */
    if (strchr(sub, ':') && !c->package_subs) {
        /* keep string compare inside the block for performance */
        if (strncmp(sub, "ExtProc::", 9)) {
            ora_exception(c, "invalid subroutine");
            return;
        }
    }

    /* grab arguments, NULL terminated */
    va_start(ap, sub);

    while (n < c->max_sub_args) {
        args[n] = va_arg(ap, char*);
        ind = va_arg(ap, int);
        if (ind == OCI_IND_NULL) {
            args[n] = NULL;
            break;
        }
        n++;
    }
    va_end(ap);

    EP_DEBUGF(c, "-- found %d argument(s)", n);

    /* start perl interpreter if necessary */
    if (!c->perl) {
        c->perl = pl_startup(c);
        EP_DEBUG(c, "RETURN ora_perl_proc");
        if (!c->perl) {
            return;
        }
        EP_DEBUGF(c, "-- code table is %s", c->code_table);
    }

    fqsub = parse_code(c, &code, sub);
    if (!fqsub) {
        return;
    }

    /* run subroutine */
    call_perl_sub(c, fqsub, args);
}

/* Perl.version function */
char *ora_perl_version(OCIExtProcContext *ctx, OCIInd *ret_ind)
{
    char *version;
    EP_CONTEXT *c = &my_context;

    dTHX;

    _ep_init(c, ctx);

    EP_DEBUGF(c, "IN ora_perl_version(%p, %p)", ctx, ret_ind);

    version = OCIExtProcAllocCallMemory(ctx, 255);
    *version = '\0';
    snprintf(version, 235, "extproc_perl-%s/Perl-%s",
        EXTPROC_PERL_VERSION, PERL_VERSION_STRING);
    *ret_ind = OCI_IND_NOTNULL;
    return(version);
}

/* Perl.flush procedure */
void ora_perl_flush(OCIExtProcContext *ctx)
{
    EP_CONTEXT *c = &my_context;

    dTHX;

    _ep_init(c, ctx);

    EP_DEBUGF(c, "IN ora_perl_flush(%p)", ctx);

    /* only destroy the interpreter if it exists */
    if (c->perl) {
        /* call registered extproc_perl destructors */
        call_pv("ExtProc::destroy", G_VOID|G_EVAL);

        /* shut down interpreter */
        pl_shutdown(c);
        c->perl = NULL;
    }
    else {
        ora_exception(c, "interpreter not started");
    }
}

/* Perl.debug procedure */
void ora_perl_debug(OCIExtProcContext *ctx, int enable)
{
    EP_CONTEXT *c = &my_context;

    dTHX;

    _ep_init(c, ctx);

    EP_DEBUGF(c, "IN ora_perl_debug(%p, %d)", ctx, enable);

    if (enable) {
        ep_debug_enable(c);
        EP_DEBUG(c, "START");
    }
    else {
        EP_DEBUG(c, "STOP");
        ep_debug_disable(c);
    }
}

/* Perl.ddl_format procedure */
void ora_perl_ddl_format(OCIExtProcContext *ctx, char *fmt)
{
    EP_CONTEXT *c = &my_context;

    dTHX;

    _ep_init(c, ctx);

    EP_DEBUGF(c, "IN ora_perl_ddl_format(%p, %s)", ctx, fmt);

    if (!strncasecmp(fmt, "standard", 8)) {
        c->ddl_format = EP_DDL_FORMAT_STANDARD;
        EP_DEBUG(c, "-- set DDL format to EP_DDL_FORMAT_STANDARD");
    }
    else if(!strncasecmp(fmt, "package", 7)) {
        c->ddl_format = EP_DDL_FORMAT_PACKAGE;
        EP_DEBUG(c, "-- set DDL format to EP_DDL_FORMAT_PACKAGE");
    }
    else {
        ora_exception(c, "invalid DDL format");
    }
}

/* Perl.debug_file function */
char *ora_perl_debug_file(OCIExtProcContext *ctx, OCIInd *ret_ind)
{
    EP_CONTEXT *c = &my_context;

    dTHX;

    _ep_init(c, ctx);

    EP_DEBUGF(c, "IN ora_perl_debug_file(%p)", ctx);

    if (c->debug_file) {
        *ret_ind = OCI_IND_NOTNULL;
        return(c->debug_file);
    }
    else {
        *ret_ind = OCI_IND_NULL;
        return NULL;
    }
}

/* Perl.debug_status function */
char *ora_perl_debug_status(OCIExtProcContext *ctx, OCIInd *ret_ind)
{
    EP_CONTEXT *c = &my_context;
    char *res;

    dTHX;

    _ep_init(c, ctx);

    EP_DEBUGF(c, "IN ora_perl_debug_status(%p)", ctx);

    res = OCIExtProcAllocCallMemory(ctx, 8);
    if (c->debug) {
        strcpy(res, "ENABLED");
    }
    else {
        strcpy(res, "DISABLED");
    }

    *ret_ind = OCI_IND_NOTNULL;
    return res;
}

/* Perl.package function */
char *ora_perl_package(OCIExtProcContext *ctx, OCIInd *ret_ind)
{
    EP_CONTEXT *c = &my_context;
    char *res;

    dTHX;

    _ep_init(c, ctx);

    EP_DEBUGF(c, "IN ora_perl_package(%p)", ctx);

    if (c->use_namespace) {
        *ret_ind = OCI_IND_NOTNULL;
        res = strdup(c->package);
    }
    else {
        *ret_ind = OCI_IND_NULL;
        res = NULL;
    }

    return res;
}

/* Perl.errno function */
char *ora_perl_errno(OCIExtProcContext *ctx, OCIInd *ret_ind)
{
    EP_CONTEXT *c = &my_context;
    char *res;

    dTHX;

    _ep_init(c, ctx);

    EP_DEBUGF(c, "IN ora_perl_errno(%p)", ctx);

    /* don't display errors unless perl interpreter has been started */
    if (c->perl) {
        res = strerror(errno);
        *ret_ind = OCI_IND_NOTNULL;
    }
    else {
        res = NULL;
        *ret_ind = OCI_IND_NULL;
    }

    return res;
}

/* Perl.errsv function */
char *ora_perl_errsv(OCIExtProcContext *ctx, OCIInd *ret_ind)
{
    EP_CONTEXT *c = &my_context;
    char *res;

    dTHX;

    _ep_init(c, ctx);

    EP_DEBUGF(c, "IN ora_perl_errsv(%p)", ctx);

    /* don't display errors unless perl interpreter has been started */
    if (c->perl) {
        res = SvPV(ERRSV, PL_na);
        *ret_ind = OCI_IND_NOTNULL;
    }
    else {
        res = NULL;
        *ret_ind = OCI_IND_NULL;
    }

    return res;
}

char *ora_perl_config(OCIExtProcContext *ctx, OCIInd *ret_ind, char *param, OCIInd param_ind)
{
    EP_CONTEXT *c = &my_context;
    char *res;

    dTHX;

    _ep_init(c, ctx);

    EP_DEBUGF(c, "IN ora_perl_config(%p)", ctx);

    if (param_ind == OCI_IND_NULL) {
        ora_exception(c, "ora_perl_config: passed NULL parameter");
        *ret_ind = OCI_IND_NULL;
        return NULL;
    }
    res = OCIExtProcAllocCallMemory(ctx, 1024);

    if (!strncmp(param, "tainting", 8)) {
        if (c->tainting) {
            strcpy(res, "ENABLED");
        }
        else {
            strcpy(res, "DISABLED");
        }
        *ret_ind = OCI_IND_NOTNULL;
    }
    else if (!strncmp(param, "session_namespace", 17)) {
        *ret_ind = OCI_IND_NOTNULL;
        if (c->use_namespace) {
            strcpy(res, "ENABLED");
        }
        else {
            strcpy(res, "DISABLED");
        }
    }
    else if (!strncmp(param, "package_subs", 12)) {
        *ret_ind = OCI_IND_NOTNULL;
        if (c->package_subs) {
            strcpy(res, "ENABLED");
        }
        else {
            strcpy(res, "DISABLED");
        }
    }
    else if (!strncmp(param, "inc_path", 8)) {
        if (c->inc_path == NULL) {
            *ret_ind = OCI_IND_NULL;
        }
        else {
            strcpy(res, c->inc_path);
            *ret_ind = OCI_IND_NOTNULL;
        }
    }
    else if (!strncmp(param, "bootstrap_file", 14)) {
        *ret_ind = OCI_IND_NOTNULL;
        strcpy(res, c->bootstrap_file);
    }
    else if (!strncmp(param, "debug_directory", 22)) {
        *ret_ind = OCI_IND_NOTNULL;
        strcpy(res, c->debug_dir);
    }
    else if (!strncmp(param, "trusted_code_directory", 22)) {
        *ret_ind = OCI_IND_NOTNULL;
        strcpy(res, c->trusted_dir);
    }
    else if (!strncmp(param, "code_table", 10)) {
        *ret_ind = OCI_IND_NOTNULL;
        strcpy(res, c->code_table);
    }
    else if (!strncmp(param, "max_code_size", 13)) {
        *ret_ind = OCI_IND_NOTNULL;
        snprintf(res, 1024, "%d", c->max_code_size);
    }
    else if (!strncmp(param, "max_sub_args", 12)) {
        *ret_ind = OCI_IND_NOTNULL;
        snprintf(res, 1024, "%d", c->max_sub_args);
    }
    else if (!strncmp(param, "ddl_format", 10)) {
        *ret_ind = OCI_IND_NOTNULL;
        if (c->ddl_format == EP_DDL_FORMAT_STANDARD) {
            strcpy(res, "STANDARD");
        }
        if (c->ddl_format == EP_DDL_FORMAT_PACKAGE) {
            strcpy(res, "PACKAGE");
        }
    }
    else if (!strncmp(param, "reparse_subs", 12)) {
        if (c->reparse_subs) {
            strcpy(res, "ENABLED");
        }
        else {
            strcpy(res, "DISABLED");
        }
        *ret_ind = OCI_IND_NOTNULL;
    }
    else {
        ora_exception(c, "ora_perl_config: unknown parameter");
        *ret_ind = OCI_IND_NULL;
    }

    return res;
}

/* Perl.eval procedure */
void ora_perl_eval(OCIExtProcContext *ctx, char *code)
{
    SV *codesv;
    EP_CONTEXT *c = &my_context;

    dTHX;

    _ep_init(c, ctx);

    EP_DEBUGF(c, "IN ora_perl_eval(%p, '%s')", ctx, code);

    if (c->tainting) {
        ora_exception(c, "eval not supported in taint mode");
        return;
    }

    if (c->use_namespace) {
        ENTER;
        codesv = sv_2mortal(newSVpv("package ", 0));
        sv_catpvf(codesv, "%s;\n", c->package);
        sv_catpv(codesv, code);
        sv_catpv(codesv, "\npackage main;\n");
        eval_sv(codesv, FALSE);
        LEAVE;
    }
    else {
        eval_pv(code, FALSE);
    }
    if (SvTRUE(ERRSV)) {
        ora_exception(c, SvPV(ERRSV, PL_na));
    }
}
