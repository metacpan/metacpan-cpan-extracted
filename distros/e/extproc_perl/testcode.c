/* $Id: testcode.c,v 1.5 2006/04/05 20:38:58 jeff Exp $ */

/* This code will only be included in the testing version of extproc_perl.so */

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

extern EP_CONTEXT my_context;

/* TestPerl.test procedure */
/* sets up engine for testing before installation */
void ora_perl_test(OCIExtProcContext *ctx)
{
    EP_CONTEXT *c = &my_context;

    dTHX;

    /* set up for testing */
    c->testing = 1;
    _ep_init(c, ctx);

    /* change trusted code directory */
    strcpy(c->trusted_dir, BUILD_DIR"/t");

    /* change inc_path so we load uninstalled ExtProc.pm */
    strcpy(c->inc_path, BUILD_DIR"/ExtProc/blib/lib");

    /* change bootstrap file */
    strcpy(c->bootstrap_file, BUILD_DIR"/t/testboot.pl");

    /* change code table */
    strcpy(c->code_table, "EPTEST_USER_PERL_SOURCE");
}
