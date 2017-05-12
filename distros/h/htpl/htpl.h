/***************************************************************
 * HTPL by Ariel Brosh                                         *
 * This program can be used freely, but the source should not  *
 * be modified without notice.                                 *
 * Copyright 1997-1999 Ariel Brosh                             *
 ***************************************************************/

/***************************
 * HTPL global definitions *
 ***************************/

#ifndef __HTPL_H__
#define __HTPL_H__

#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <malloc.h>
#include <stdlib.h>
#if HAVE_STRING_H
#include <string.h>
#else
#include <strings.h>
#endif
#include <sys/param.h>
#include <sys/wait.h>
#if TIME_WITH_SYS_TIME
 #include <sys/time.h>
 #include <time.h>
#else
 #if HAVE_SYS_TIME_H
  #include <sys/time.h>
 #else
  #include <time.h>
 #endif
#endif
#include <dirent.h>
#include <limits.h>
#include <errno.h>

#ifdef FOPEN
#undef FOPEN
#endif

#ifndef VERSION
#define VERSION 2.8
#endif

#define HEADER_FILE "htpl.head"
#define HEADER_FILE_OFFLINE "htpl.offhead"
#define HEADER_FILE_SITE "htpl.sitehead"

/* #define __DEBUG__ */



#define LOG 5

#define BUFF_SIZE 4000

enum states {ESCAPE = 0, COMMENT, QUOTE, D_QUOTE, FIELD = 10,  PERL_END,
    PERL_EXP, TCL_TAG, PERL_TAG, UPERL_0, UPERL_1, UPERL_2, UPERL_3,
    UPERL_4, UPERL_5, TCL, TCL_INTER,
    PERL_UNEXP, PERL,
    BRAC, TCL_DO_INTER, TAG, UNTAG, T_QUOTE, TAG_H,
    TAG_T, TAG_NONE, PRECOM_1, PRECOM_2, PRECOM_3, 
    PERL_1, PERL_2, PERL_3, PERL_4, TCL_1, TCL_2, TCL_3,
    PREP, UNPREP, PREPBUFF,
    HTML = 60, CC,
    SILENCE, POSTCOM_1, POSTCOM_2, POSTCOM_3, POSTCOM_4};

enum language {LNG_PERL, LNG_TCL};
enum scriptcontext {CODE_TAG, CODE_EVAL, CODE_BLOCK, CODE_TCL_TAG};

#define isperl(s) ((s) <= PERL)
#define ishtml(s) ((s) > PERL && (s) < CC)
#define istag(s) ((s) > BRAC && (s) < HTML)
#define isspecial(s) ((s) >= PERL_1 && (s) <= TCL_3)

#define LDAP_FILTER 10
#define LDAP_START 20
#define LDAP_BIND 30
#define LDAP_DN 40
#define LDAP_ATTR 60

#define HTPL_DB_OBJECT "$htpl_db_object"
#define HTPL_DIR_OBJECT "$htpl_dir_object"
#define HTPL_WAIS_OBJECT "$htpl_wais_object"


/*typedef enum states DFA;*/typedef long DFA;
typedef char TOKEN[260];
typedef char FILENAME[180];
typedef char DN[150];
typedef char *pchar, *STR;
typedef char COMMAND[1253];
typedef void *PTR;

void generate(STR, STR, STR, STR);
void execute(STR, STR, STR, STR, STR);
void process(FILE *, FILE *, FILE *);
void maketemp(STR, STR);
long fcpy(FILE *, FILE *, int);
void flpt(FILE *, FILE *);
void eat(pchar *, STR);
void nodir(STR, STR);
void finddir(STR, STR);
void findpath(STR, STR);
FILE* FOPEN(STR, STR);
long getftime(STR);
long depend(STR, STR);
short fit(STR, STR, int);
void outdbg(FILE *, STR);
STR nprot(STR);
STR convtime(time_t);
int strrcmp(STR, STR);
void SETENV(STR, STR);
void htencode(STR, STR);
void htmldecode(STR, STR);
int disposetrue(pchar);
int disposecmp(pchar, pchar);
STR repeat(int, char);
void outperlline(FILE *, STR);
/*STR populate(STR, STR);*/
int copyhtmltag(STR);
/*int count_args(STR);*/
void compile(STR, STR);
void tryexts(STR, STR, STR);
void makepersist(STR);
void destroypersist();
int retval(int);
STR gettoken(int);
STR gettokenlist(int, STR, STR, STR);
STR getsubtoken(int, char, int);
pchar setworktoken(STR);
int execperl(STR*, STR, STR, STR, int);
void xsub_entry(STR, STR, STR);
void outline(FILE *, STR, long);
void printcode(STR);
STR mystrdup(STR);
void outblock(FILE *, STR);
void outmacro(FILE *, STR, int);
int countlines(STR);
void replacechar(STR, char, char);
STR qualify(STR, int);
void fcopy(STR, STR);
STR escapevars(STR);
STR preprocess(STR, STR);
FILE *opensource(STR);
FILE *openoutput(STR);
FILE *openif(STR, STR);
short debugfirbidden(FILE *);

/*
struct ldapp {
    FILENAME server;
    TOKEN bind;
    TOKEN pass;
    DN dn;
    DN start;
    DN attributes;
    int port;
    DN filter;
    int sizelimit;
    TOKEN scope;
    TOKEN sortkey;
};
*/
struct link_el {
    PTR data;
    struct link_el *next; 
};

typedef struct link_el *LINK_EL;

struct btree {
    STR key;
    PTR data;
    struct btree *left, *right;	
};

typedef struct btree *BTREE;

struct scope_el {
    int scope;
    long nline;
    int id;
    BTREE vars;
};

typedef struct scope_el *SCOPE;

struct buffer_el {
    pchar buffer;
    long size;
    int lines;
};

typedef struct buffer_el *BUFFER;

struct vector {
    PTR *data;
    int num;
    int alloc;
};

typedef struct vector *VECTOR;

struct persist_el {
    VECTOR tokens;
    VECTOR extras;
    int n;
};

typedef struct persist_el *PERSIST;

enum btree_whence {BTREE_PREFIX, BTREE_INFIX, BTREE_POSTFIX};

void ppush(LINK_EL *, PTR);
PTR ppop(LINK_EL *);
void pushscope(int, int);
void popscope();
void dumpscopes();
void pushbuffer();
void popbuffer();
int begin_parse_htpl(STR);

typedef int (*btreecallback)(BTREE *, int, PTR);
typedef PTR (*btreesimpleproc)(PTR);

BTREE *btreescan(BTREE *, btreecallback, int, PTR, int);
BTREE *btreeadd(BTREE *, char *, PTR);
void btreekill(BTREE *);
PTR btreesearch(BTREE, char *);
BTREE *btreesearch2(BTREE *, char *);
PTR btreedel(BTREE *);
PTR btreedelkey(BTREE *, char *);
void btreesimplescan(BTREE, btreesimpleproc);

void vectorinit(VECTOR);
void vectorpush(VECTOR, PTR);
void vectorkill(VECTOR);

#ifdef __HTMAIN__
#define HTE
#define HTZ = 0
#else
#define HTE extern
#define HTZ
#endif
HTE FILENAME scriptdir, tmpdir, bindir, origdir;
HTE FILENAME infile, thefilename, thescript;
HTE long nline, rline;

HTE FILENAME myself;
HTE STR argv_1;

HTE short hasxs;

HTE short fatal HTZ;
HTE STR errstr;
HTE STR errloc;

HTE DFA cstate HTZ;

#ifdef __DEBUG__

HTE int create HTZ;
HTE short runit HTZ;
HTE short noweb HTZ;
HTE short inputcgi HTZ;
HTE short noout HTZ;
HTE short perldb HTZ;
#endif

HTE char **myargv;
HTE int myargc HTZ;

HTE STR result;
HTE long resultsize HTZ;
HTE short nest;

HTE SCOPE currscope;
struct scope_el mainscope;
HTE LINK_EL scopestack;
HTE LINK_EL bufferstack;
HTE BUFFER currbuffer;

HTE int scopelevel HTZ;
HTE struct persist_el *persist;
HTE struct link_el *persiststack;

HTE int internal_flags[32];

HTE short kludge_reunifying HTZ;

#undef HTE
#undef HTZ

extern int optind;
extern char *optarg;

#ifndef __PERLEMBED__
#define EXECPERL(argc, argv, output, postdata, error, redir) execperl(argv, output, postdata, error, redir)
#else
int runperl(int, STR*, STR, STR, STR, int);
#define EXECPERL(argc, argv, output, postdata, error, redir) runperl(argc, argv, output, postdata, error, redir)
#endif

#define GETENV(key) getenv(key)

#define isdelim(ch) ((ch) == ' ' || (ch) == '\t'|| \
           (ch) == '\r' || (ch) == '\n')
#ifdef _WIN32
#define SLASH_CHAR '\\'
#define SLASH_STR "\\"
#define NEWLINE "\n"
#define qNEWLINE "\\n"
#else
#define SLASH_CHAR '/'
#define SLASH_STR "/"
#define NEWLINE "\n"
#define qNEWLINE "\\n"
#endif

#ifndef PERL_BIN
#ifndef _WIN32
#define PERL_BIN "/usr/bin/perl"
#else
STR getperlpath();
#define PERL_BIN getperlpath()
#endif
#endif

#define NEW(var) var = malloc(sizeof(*var));

#endif // __HTPL_H__

