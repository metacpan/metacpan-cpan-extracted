/* $Id: config.c,v 1.18 2006/04/05 20:38:58 jeff Exp $ */

#ifdef __cplusplus
extern "C" {
#endif
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <oci.h>
#include <EXTERN.h>
#include <perl.h>
#include "extproc_perl.h"
#ifdef __cplusplus
}
#endif

#define YESORNO(x) (!strncasecmp(x, "yes", 3) ? 1 : 0)

int read_config(EP_CONTEXT *c, char *fn)
{
    FILE *fp;
    char line[1024], err[256], key[1024], val[1024], db[256], mydb[256],
        *p, *keyp;
    int res, len, n = 0;
    unsigned int i;

    /* if we're testing, configure with hardcoded test values */
    if (c->testing) {
        strcpy(c->code_table, "test_user_perl_source");
        strcpy(c->bootstrap_file, ""); /* will be filled in later */
        strcpy(c->debug_dir, "/tmp");
        strcpy(c->inc_path, "");
        strcpy(c->trusted_dir, ""); /* will be filled in later */
        c->use_namespace = 1;
        c->tainting = 1;
        c->package_subs = 0;
        c->max_code_size = 32768;
        c->max_sub_args = 32;
        c->ddl_format = EP_DDL_FORMAT_STANDARD;
        c->reparse_subs = 0;
        return(1);
    }
    if (!(fp = fopen(fn, "r"))) {
        return(0);
    }

    /* get our database name */
    res = get_dbname(c, mydb);
    if (res != OCI_SUCCESS && res != OCI_SUCCESS_WITH_INFO) {
        ora_exception(c, "get_dbname");
        fclose(fp);
        return(0);
    }

    while(fgets(line, 1024, fp)) {
        n++;
        /* ignore comments and blank lines */
        if (line[0] == '#' || line[0] == '\n') {
            continue;
        }

        /* parse away */
        if ((p = strpbrk(line, " \t"))) {
            len = p-line;
            strncpy(key, line, len);
            key[len] = '\0';
            strncpy(val, p+1, 1024-len-1);
            /* get rid of newline */
            if ((p = strchr(val, '\n'))) {
                *p = '\0';
            }
        }
        else {
            snprintf(err, 255, "Bad configuration line %d\n", n);
            ora_exception(c, err);
            fclose(fp);
            return(0);
        }

        /* parse out database name, if any */
        if (keyp = index(key, ':')) {
            strncpy(db, key, keyp-key);
            /* skip if line doesn't apply to our database */
            if (strncasecmp(db, mydb, strlen(mydb))) {
                continue;
            }
            strncpy(key, keyp+1, strlen(key));
        }

        if (!strcmp(key, "code_table")) {
            strncpy(c->code_table, val, 255);
            continue;
        }
        if (!strcmp(key, "bootstrap_file")) {
            strncpy(c->bootstrap_file, val, MAXPATHLEN-1);
            continue;
        }
        if (!strcmp(key, "debug_directory")) {
            strncpy(c->debug_dir, val, MAXPATHLEN-1);
            continue;
        }
        if (!strcmp(key, "inc_path")) {
            strncpy(c->inc_path, val, 4095);
            continue;
        }
        if (!strcmp(key, "trusted_code_directory")) {
            strncpy(c->trusted_dir, val, MAXPATHLEN-1);
            continue;
        }
        if (!strcmp(key, "enable_session_namespace")) {
            c->use_namespace = YESORNO(val);
            continue;
        }
        if (!strcmp(key, "enable_tainting")) {
            c->tainting = YESORNO(val);
            continue;
        }
        if (!strcmp(key, "enable_package_subs")) {
            c->package_subs = YESORNO(val);
            continue;
        }
        if (!strcmp(key, "reparse_subs")) {
            c->reparse_subs = YESORNO(val);
            continue;
        }
        if (!strcmp(key, "ddl_format")) {
            if (!strncmp(val, "standard", 8)) {
                c->ddl_format = EP_DDL_FORMAT_STANDARD;
            }
            else if (!strncmp(val, "package", 7)) {
                c->ddl_format = EP_DDL_FORMAT_PACKAGE;
            }
            else {
                ora_exception(c, "illegal DDL format");
                fclose(fp);
                return(0);
            }
            continue;
        }
        if (!strcmp(key, "max_code_size")) {
            i = atoi(val);
            if (i < 1 || i > 0xffffffff) {
                snprintf(err, 255, "Illegal value for max_code_size: '%s'\n", val);
                ora_exception(c, err);
                fclose(fp);
                return(0);
            }
            c->max_code_size = (int)i;
            continue;
        }
        if (!strcmp(key, "max_sub_args")) {
            i = atoi(val);
            if (i < 0 || i > 128) {
                snprintf(err, 255, "Illegal value for max_sub_args: '%s'\n", val);
                ora_exception(c, err);
                fclose(fp);
                return(0);
            }
            c->max_sub_args = i;
            continue;
        }
    }

    fclose(fp);

    return(1);
}
