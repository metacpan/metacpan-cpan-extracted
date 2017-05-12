/* $Id: extproc_perl.h,v 1.21 2006/08/01 16:57:07 jeff Exp $ */

#ifndef EXTPROC_PERL_H
#define EXTPROC_PERL_H

#define    ORACLE_USER_ERR        20100
#define    MAX_SIMPLE_QUERY_SQL    1024
#define    MAX_SIMPLE_QUERY_RESULT    32768

#define EP_SUBTYPE_FUNCTION    0
#define EP_SUBTYPE_PROCEDURE    1

#define EP_DDL_FORMAT_STANDARD    0
#define EP_DDL_FORMAT_PACKAGE    1

#define EP_DEBUG(c, msg) if (c->debug) { ep_debug(c, "%s", msg); }
#define EP_DEBUGF(c, fmt, ...) if (c->debug) { ep_debug(c, fmt, __VA_ARGS__); }

struct ocictx {
    OCIExtProcContext *ctx;    /* For OCI ExtProc Context */
    OCIEnv *envhp;        /* For OCI Environment Handle */
    OCISvcCtx *svchp;    /* For OCI Service Handle */
    OCIError *errhp;    /* For OCI Error Handle  */
    OCIStmt *stmtp;        /* For OCI Statement Handle */
};
typedef struct ocictx ocictx;

struct ep_context {

    /* per-session globals */
    int configured;        /* have we been configured yet? */
    PerlInterpreter *perl;    /* perl interpreter */
    ocictx oci_context;    /* OCI context for callbacks */
    int connected;        /* is OCIExtProcContext initialized? */
    int debug;        /* debug flag */
    char *debug_file;    /* most recent debug file */
    FILE *debug_fp;        /* debug file descriptor */
    char package[256];    /* optional session namespace */
    int subtype;        /* function or procedure? */
    int testing;        /* are we just testing? */

    /* initialized from configuration file */
    char code_table[256];
    char bootstrap_file[MAXPATHLEN];
    char debug_dir[MAXPATHLEN];
    char inc_path[4096];
    char trusted_dir[MAXPATHLEN];
    int ddl_format;
    int reparse_subs;
    int use_namespace;
    int tainting;
    int package_subs;
    unsigned int max_code_size;
    unsigned int max_sub_args;
};
typedef struct ep_context EP_CONTEXT;

struct ep_code {
    char label[255];
    char plsql_spec[255];
    char language[255];
    int version;
    char *code;
    int code_len;
};
typedef struct ep_code EP_CODE;

struct ep_arg {
    void *val;
    char type;
    OCIInd *ind;
    char direction;
    STRLEN *len;
    STRLEN *maxlen;
    SV *sv;
};
typedef struct ep_arg EP_ARG;

void ora_exception(EP_CONTEXT *, char *);
int fetch_code(EP_CONTEXT *, EP_CODE *, char *);
int get_sessionid(EP_CONTEXT *, int *);
int get_dbname(EP_CONTEXT *, char *);
PerlInterpreter *pl_startup(EP_CONTEXT *);
void _ep_init(EP_CONTEXT *, OCIExtProcContext *);
char *parse_code(EP_CONTEXT *, EP_CODE *, char*);
OCIDate *string_to_ocidate(EP_CONTEXT *, char *, char *);
char *ocidate_to_string(EP_CONTEXT *, OCIDate *, char *);
int is_null(void *);
void set_null(void *);
void clear_null (void *);

#endif /* EXTPROC_PERL_H */
