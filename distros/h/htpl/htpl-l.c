/***************************************************************
 * HTPL by Ariel Brosh                                         *
 * This program can be used freely, but the source should not  *
 * be modified without notice.                                 *
 * Copyright 1997-1999 Ariel Brosh                             *
 ***************************************************************/

/*********************************************
 * htpl-l.c - HTPL service library           *
 *********************************************/

#include "htpl.h"
#include "htpl-sh.h"
#include <stdarg.h>

/*********************************************
 * Read one token from a string              *
 *********************************************/

void croak(char *fmt, ...);

void eat(line, token)
    STR *line, token; {
    pchar save = token;
    while (isdelim(**line)) (*line)++;
    if (**line == '<' && (*line)[1] == '<') {
	char *find;
	(*line) += 2;
	find = strstr(*line, ">>");
	if (!find) croak("Unterminated long parameter: %s", *line - 2);
	memcpy(token, *line, find - *line);
	token[find - *line] = '\0';
	*line = find + 2;
    } else {
        for (; !isdelim(**line) && **line; token++, (*line)++) 
            *token = **line;
        *token = '\0';
    }
    while (isdelim(**line)) (*line)++;
}

/*********************************************
 * Copy input file to output file            *
 *********************************************/

long fcpy(i, o, how)
    int how;
    FILE *i, *o; {
    long red;
    long total = 0;
    STR buff;

    buff = malloc(BUFF_SIZE);

    if (!how) {
        while (red = fread(buff, 1, BUFF_SIZE, i)) {
            fwrite(buff, 1, red,o);
            total += red;
        }
    } else {
        while (fgets(buff, BUFF_SIZE, i)) outblock(o, buff);
    }

    free(buff);
    return red;
}


/****************************************
 * Open a file, complain if failed      *
 ****************************************/

FILE *FOPEN(filename, mode)
    STR filename, mode; {
    FILE *f;

    f = fopen(filename, mode);
    if (f) return f;
#ifndef __DEBUG__
    printf("Content-type: text/plain\n\n");
#endif
    printf("Could not open %s", filename);
    if (strchr(mode, 'w')) printf(" for write"); else
    if (strchr(mode, 'r')) printf(" for read");
#ifndef _WIN32
    printf(": %s%s", sys_errlist[errno], NEWLINE);
#endif
    printf(NEWLINE);
    exit(0);
}


/* This is basically for debugging */
void emergency() {
    printf("Content-type: text/plain\n\nEmergency exit");
    exit(0);
}
/*
** This is obsolette
void mychdir(filename) 
    STR filename; {
    pchar ch;
    char dir[80];
    strcpy(dir, filename);
    ch = strrchr(dir, SLASH_CHAR);
    if (!ch) return;
    *ch = '\0';
    chdir(dir);
}
*/

/*********************************************************************
 * Make a temporary filename for the specific session for a specific *
 * file type                                                         *
 *********************************************************************/

void maketemp(filename, ext)
    STR filename, ext; {

    sprintf(filename, "%s%c~~htpl-%05d-%05d~~.%s", tmpdir, SLASH_CHAR,
                      getpid(), time(NULL), ext);
}

/*******************************************************************
 * Duplicate a filename, changing extension                        *
 * Add a reference to cache subdirectory if such exists            *
 *******************************************************************/

void makecache(src, rdst, ext)
    STR src, rdst, ext; {
    pchar ch;
    FILENAME dir, dir2;
    DIR *d;
    pchar dst;

/* Get the directory of the file */

    finddir(src, dir);

    dst = dir;

#ifdef __DEBUG__
    if (!noweb && *ext) {
#endif

/* Check for cache directory */

    sprintf(dir2, "%s%chtpl-cache", dir, SLASH_CHAR);
    if (d = opendir(dir2)) {
        closedir(d);
        dst = dir2;
    }

#ifdef __DEBUG__
    }
#endif

/* Copy the filename */

    strcat(dst, SLASH_STR);
    ch = strrchr(src, SLASH_CHAR);
    if (!ch) ch = src; else ch++;
    strcat(dst, ch);

/* Find the extension */

    ch = strrchr(strrchr(dst, SLASH_CHAR), '.');
    if (!ch) ch = &dst[strlen(dst)];

/* Add extension */

    if (!*ext) {
        *ch = '\0';
        return;
    }
    *ch++ = '.';

    strcpy(ch, ext);
    strcpy(rdst, dst);
}

/********************************************
 * Find histroic dependencies between files *
 ********************************************/

long depend(filename1, filename2) 
    STR filename1, filename2; {

    long time1 = getftime(filename1);
    long time2 = getftime(filename2);

    return time2 - time1;
}

/***********************************
 * Get file change time            *
 ***********************************/

long getftime(filename)
    STR filename; {
    struct stat st;

    if (stat(filename, &st) < 0) return 0;

    return st.st_mtime;
}

/******************************************
 * Extract directory out of filename      *
 ******************************************/

void finddir(file, dir)
    STR file, dir; {
    pchar ch;
    FILENAME tempdir;

    strcpy(dir, file);
    ch = strrchr(dir, SLASH_CHAR);
    if (!ch) {
        getcwd(dir, sizeof(FILENAME));
    } else {
        *++ch = '\0';
        getcwd(tempdir, sizeof(FILENAME));
        chdir(dir);
        getcwd(dir, sizeof(FILENAME));
        chdir(tempdir);
    }
#ifdef _WIN32
/* CYGWIN is being nice - no thanks */
    if (SLASH_CHAR != '/') {
        for (ch = dir; *ch; ch++ )
            if (*ch == '/') *ch = SLASH_CHAR;
        if (ch - dir > 3) {
		/* Convert drive letter */
            if (dir[0] == SLASH_CHAR && dir[1] == SLASH_CHAR) {
                STR path = strdup(dir + 3);
                dir[0] = dir[2];
                dir[1] = ':';
                strcpy(dir + 2, path);
                free(path);
            }
	}
    }
#endif
/* Append slash */
/*    strcpy(ch, SLASH_STR);*/
}

/********************************************************
 * Chop directory information out of filename           *
 ********************************************************/

void nodir(spec, file)
    STR spec, file; {

    pchar ch;
    ch = strrchr(spec, SLASH_CHAR);
    if (!ch) ch = file; else ch++;
    strcpy(file, ch);
}

/***********************************************************
 * strrcmp library function                                *
 ***********************************************************/

int strrcmp(s1, s2)
    STR s1, s2; {

    pchar ch1, ch2;
    int l1, l2;

    l1 = strlen(s1);
    l2 = strlen(s2);

    for (ch2 = s2; l1 < l2; ch2++, l2--) ;
    for (ch1 = s1; l1 > l2; ch1++, l1--) ;
    return strcmp(ch1, ch2);
}

/************************************************
 * Line print input into output                 *
 ************************************************/

void flpt(i, o)
    FILE *i, *o; {

    STR buff;
    int line = 0, line2 = 0, nline, l;
    FILENAME filename, newfilename;
    TOKEN s;

    buff = malloc(BUFF_SIZE);

    strcpy(filename, "");
    while (!feof(i)) {
        fgets(buff, BUFF_SIZE, i);
        buff[strlen(buff) - 1] = '\0';
        if (feof(i)) break;
        if (sscanf(buff, "#line %d %s", &nline, newfilename) == 2) {
            if (!strcmp(newfilename, thescript)) {
                filename[0] = '\0';
                line2 = 0;
            } else {
                line2 = nline;
                nodir(newfilename, filename);
            }
        } else if (line2) fprintf(o, "[%s(%d)] ", filename, line2++);
        fprintf(o, "%d> %s%s", ++line, buff, NEWLINE);
    }
}

/***************************************************
* Format a string into temporary storage          *
***************************************************/

char *mysprintf(char *fmt, ...) {
    va_list ap;
    char *msg;

    va_start(ap, fmt);
    vasprintf(&msg, fmt, ap);
    va_end(ap);

    return msg;
}

/*************************************
 * Write a formatted output line     *
 *************************************/

void outf(FILE *o, char *fmt, ...) {
    va_list ap;
    char *msg;

    va_start(ap, fmt);
    vasprintf(&msg, fmt, ap);
    va_end(ap);

    outblock(o, msg);
    free(msg);
}

/**********************************************
 * Output debug information                   *
 **********************************************/

void outdbg(o, line)
    FILE *o;
    STR line; {
    outf(o, "# Line: %d File: %s >> %s", nline, infile, line);
/*    outline(o, thescript, rline + 1 + 1);*/
}

/****************************
 * Dump scope stack         *
 ****************************/

void dumpscopes() {
    if (scopelevel > 0) {
        printf("Dumping scope stack:%s", NEWLINE);
        while (scopelevel > 0 && currscope) {
            printf("%d) %s in line %d.%s", scopelevel,
              scope_names[currscope->scope], currscope->nline, NEWLINE);
            popscope();
        }
    }
}

/******************************************************
 * Return string or a blank string for a null pointer *
 ******************************************************/

STR nprot(s) 
    STR s; {

    static STR blank = "";

    if (s) return s;
    return blank;
}

/********************************************************
 * Convert time to ASCII                                *
 ********************************************************/

STR convtime(t)
    time_t t; {

    static char stat[1024];
    pchar ch, dst;

    struct tm *timep;

    timep = localtime(&t);

    ch = asctime(timep);
    dst = stat;

    while (*ch && *ch != '\n') *dst++ = *ch++;
    *dst = '\0';
    return stat;
}

/*************************************
 * Stack implementation              *
 *************************************/

/********************
 * Push             *
 ********************/
    
void ppush(stack, elem)
    LINK_EL *stack;
    void *elem; {

    LINK_EL curr;

    curr = malloc(sizeof(struct link_el));
    curr->data = elem;
    curr->next = *stack;
    *stack = curr;
}

/*************
 * Pop       *
 *************/

void *ppop(stack) 
    LINK_EL *stack; {

    void *elem, *old;

    if (!*stack) return NULL;
    free((*stack)->data);
    old = *stack;
    *stack = (*stack)->next;
    free(old);
    if (*stack) elem = (*stack)->data; else elem = NULL;
    return elem;
}

/*************************************
 * Simple setenv function            *
 *************************************/

#ifdef HAVE_SETENV

void SETENV(key, val)
    STR key;
    STR val; {
 
    setenv(key, val, 1);
}

#else

#ifndef HAVE_PUTENV
#error You must have either putenv or setenv
#endif

void SETENV(key, val)
    STR key;
    STR val; {

    TOKEN s;
    sprintf(s, "%s=%s", key, val);
    putenv(s);
}

#endif


void getready() {
#ifdef _WIN32
        TOKEN newlib;
        STR lib = GETENV("PERL5LIB");
        if (!lib) lib = "";
        if (strstr(lib, bindir)) return;
        sprintf(newlib, "%s\\HTPL-modules\\lib;%s", bindir, lib);
        SETENV("PERL5LIB", newlib);
#endif
}


/*******************************************************
 * Spawn a Perl process                                *
 *******************************************************/

int execperl(argv, output, postdata, error, redir) 
    int redir;
    char **argv;
    STR output, postdata, error; {

    int code;
    int chld;
    int nerr, nout, nin;
    FILENAME cmd;

    if (!redir) {
        if (!(chld=fork())) {
            getready();
            execv(PERL_BIN, argv);
        }
        waitpid(chld, &code, 0);
        return code;
    }

/* Ok, we need to capture STDOUT and STDERR, and to feed STDIN */

    nout=creat(output, 0777);
    nin=open(postdata, O_RDONLY);
    nerr=creat(error, 0777);

    if (!(chld=fork())) {

        dup(0);
        close(0);
        dup(nin);

        dup(1);
        close(1);
        dup(nout);

        dup(2);
        close(2);
        dup(nerr);
        getready();
        execv(PERL_BIN, argv);
    } else {
        waitpid(chld, &code, 0);
        close(nerr);
        close(nin);
        close(nout);
    }
    return code;
}
/*
int dumbexecperl(argv, output, postdata, error, redir) 
    int redir;
    char **argv;
    STR output, postdata, error; {

    COMMAND line, cmd;

    strcpy(line, PERL_BIN);
    while (*argv) {
        strcat(line, " ");
        strcat(line, *argv++);
    }
    if (redir) sprintf(cmd, "%s <
    system(line);
}
*/

/****************************************************
 * Encode string for HTTP                           *
 ****************************************************/

void htencode(str, decstr)
    STR str, decstr; {

    TOKEN c;
    pchar ch, dst;
    static STR HEX = "0123456789ABCDEF";

    for (ch = str, dst = decstr; *ch; ch++) {
        if (*ch == ' ') *dst++ = '+'; 
        else if (isalnum(*ch)) *dst++ = *ch;
        else {
            *dst++ = '%';
            *dst++ = HEX[(*ch) / 16];
            *dst++ = HEX[(*ch) % 16];
        }
    }
    *dst = '\0';
}

/****************************************************
 * Encode SGML strings with entities                *
 ****************************************************/

/* Mostly taken from e-perl. Allows perl runtime macroes to process HTML
code with entities. */

struct html2char {
    STR h;
    char c;
};

static struct html2char html2char[] = {
    { "copy",   '©' },    /* Copyright */
    { "die",    '¨' },    /* Diæresis / Umlaut */
    { "laquo",  '«' },    /* Left angle quote, guillemot left */
    { "not",    '¬' },    /* Not sign */
    { "ordf",   'ª' },    /* Feminine ordinal */
    { "sect",   '§' },    /* Section sign */
    { "um",     '¨' },    /* Diæresis / Umlaut */
    { "AElig",  'Æ' },    /* Capital AE ligature */
    { "Aacute", 'Á' },    /* Capital A, acute accent */
    { "Acirc",  'Â' },    /* Capital A, circumflex */
    { "Agrave", 'À' },    /* Capital A, grave accent */
    { "Aring",  'Å' },    /* Capital A, ring */
    { "Atilde", 'Ã' },    /* Capital A, tilde */
    { "Auml",   'Ä' },    /* Capital A, diæresis / umlaut */
    { "Ccedil", 'Ç' },    /* Capital C, cedilla */
    { "ETH",    'Ð' },    /* Capital Eth, Icelandic */
    { "Eacute", 'É' },    /* Capital E, acute accent */
    { "Ecirc",  'Ê' },    /* Capital E, circumflex */
    { "Egrave", 'È' },    /* Capital E, grave accent */
    { "Euml",   'Ë' },    /* Capital E, diæresis / umlaut */
    { "Iacute", 'Í' },    /* Capital I, acute accent */
    { "Icirc",  'Î' },    /* Capital I, circumflex */
    { "Igrave", 'Ì' },    /* Capital I, grave accent */
    { "Iuml",   'Ï' },    /* Capital I, diæresis / umlaut */
    { "Ntilde", 'Ñ' },    /* Capital N, tilde */
    { "Oacute", 'Ó' },    /* Capital O, acute accent */
    { "Ocirc",  'Ô' },    /* Capital O, circumflex */
    { "Ograve", 'Ò' },    /* Capital O, grave accent */
    { "Oslash", 'Ø' },    /* Capital O, slash */
    { "Otilde", 'Õ' },    /* Capital O, tilde */
    { "Ouml",   'Ö' },    /* Capital O, diæresis / umlaut */
    { "THORN",  'Þ' },    /* Capital Thorn, Icelandic */
    { "Uacute", 'Ú' },    /* Capital U, acute accent */
    { "Ucirc",  'Û' },    /* Capital U, circumflex */
    { "Ugrave", 'Ù' },    /* Capital U, grave accent */
    { "Uuml",   'Ü' },    /* Capital U, diæresis / umlaut */
    { "Yacute", 'Ý' },    /* Capital Y, acute accent */
    { "aacute", 'ß' },    /* Small a, acute accent */
    { "acirc",  'â' },    /* Small a, circumflex */
    { "acute",  '´' },    /* Acute accent */
    { "aelig",  'æ' },    /* Small ae ligature */
    { "agrave", 'à' },    /* Small a, grave accent */
    { "amp",    '&' },    /* Ampersand */
    { "aring",  'å' },    /* Small a, ring */
    { "atilde", 'ã' },    /* Small a, tilde */
    { "auml",   'ä' },    /* Small a, diæresis / umlaut */
    { "brkbar", '¦' },    /* Broken vertical bar */
    { "brvbar", '¦' },    /* Broken vertical bar */
    { "ccedil", 'ç' },    /* Small c, cedilla */
    { "cedil",  '¸' },    /* Cedilla */
    { "cent",   '¢' },    /* Cent sign */
    { "curren", '¤' },    /* General currency sign */
    { "deg",    '°' },    /* Degree sign */
    { "divide", '÷' },    /* Division sign */
    { "eacute", 'é' },    /* Small e, acute accent */
    { "ecirc",  'ê' },    /* Small e, circumflex */
    { "egrave", 'è' },    /* Small e, grave accent */
    { "eth",    'ð' },    /* Small eth, Icelandic */
    { "euml",   'ë' },    /* Small e, diæresis / umlaut */
    { "frac12", '½' },    /* Fraction one-half */
    { "frac14", '¼' },    /* Fraction one-fourth */
    { "frac34", '¾' },    /* Fraction three-fourths */
    { "gt",     '>' },    /* Greater than */
    { "hibar",  '¯' },    /* Macron accent */
    { "iacute", 'í' },    /* Small i, acute accent */
    { "icirc",  'î' },    /* Small i, circumflex */
    { "iexcl",  '¡' },    /* Inverted exclamation */
    { "igrave", 'ì' },    /* Small i, grave accent */
    { "iquest", '¿' },    /* Inverted question mark */
    { "iuml",   'ï' },    /* Small i, diæresis / umlaut */
    { "lt",     '<' },    /* Less than */
    { "macr",   '¯' },    /* Macron accent */
    { "micro",  'µ' },    /* Micro sign */
    { "middot", '·' },    /* Middle dot */
    { "nbsp",   ' ' },    /* Non-breaking Space */
    { "ntilde", 'ñ' },    /* Small n, tilde */
    { "oacute", 'ó' },    /* Small o, acute accent */
    { "ocirc",  'ô' },    /* Small o, circumflex */
    { "ograve", 'ò' },    /* Small o, grave accent */
    { "ordm",   'º' },    /* Masculine ordinal */
    { "oslash", 'ø' },    /* Small o, slash */
    { "otilde", 'õ' },    /* Small o, tilde */
    { "ouml",   'ö' },    /* Small o, diæresis / umlaut */
    { "para",   '¶' },    /* Paragraph sign */
    { "plusmn", '±' },    /* Plus or minus */
    { "pound",  '£' },    /* Pound sterling */
    { "quot",   '"' },    /* Quotation mark */
    { "raquo",  '»' },    /* Right angle quote, guillemot right */
    { "reg",    '®' },    /* Registered trademark */
    { "shy",    '­' },    /* Soft hyphen */
    { "sup1",   '¹' },    /* Superscript one */
    { "sup2",   '²' },    /* Superscript two */
    { "sup3",   '³' },    /* Superscript three */
    { "szlig",  'ß' },    /* Small sharp s, German sz */
    { "thorn",  'þ' },    /* Small thorn, Icelandic */
    { "times",  '×' },    /* Multiply sign */
    { "uacute", 'ú' },    /* Small u, acute accent */
    { "ucirc",  'û' },    /* Small u, circumflex */
    { "ugrave", 'ù' },    /* Small u, grave accent */
    { "uuml",   'ü' },    /* Small u, diæresis / umlaut */
    { "yacute", 'ý' },    /* Small y, acute accent */
    { "yen",    '¥' },    /* Yen sign */
    { "yuml",'\255' },    /* Small y, diæresis / umlaut */
    { NULL, 0 }
};

void htmldecode(src, dst) 
    STR src, dst; {

    pchar ch1, ch2, ch3;
    int p;
    TOKEN token;
    int i;

    ch1 = src;
    ch2 = dst;

    while (*ch1) {
        if (*ch1 != '&')
            *ch2++ = *ch1++;
        else {
            ch3 = token;
            ch1++;
            while (*ch1 && *ch1 != ';') *ch3++ = *ch1++;
            if (*ch1) ch1++;
            *ch3 = '\0';
            if (token[0] == '#') {
                ch3 = token + 1;
                p = atoi(ch3);
                *ch2++ = (char)p;
            } else {
                p = 1;
                i = 0;
                while (p && html2char[i].c) {
                    if (!strncasecmp(token, html2char[i].h,
                           strlen(token))) {
                               *ch2++ = html2char[i].c;
                               p = 0;
                    }
                    i++;
                }
                if (p) {
                    *ch2++ = '&';
                    ch3 = token;
                    while (*ch3) *ch2++ = *ch3++;
                }
            }
        }
    }
    *ch2 = '\0';
}

/************************************************
 * Fork a subprocess to compile a needed module *
 ************************************************/

void compile(src, dst)
    STR src, dst; {
    int oout, nout;
    int p[2];
    int code;
    int pid;
    FILE *e, *o;
    FILENAME thedir;

    oout = dup(1);
    pipe(p);
    if (!(pid = fork())) {
        close(1);
        dup(p[1]);
        finddir(src, thedir);
        chdir(thedir);
        execl(myself, myself, "-t", "-w", "-o", dst, src, NULL);
        exit(0);
    }
    waitpid(pid, &code, 0);

    if (!WIFEXITED(code)) {
        e = fdopen(p[0], "r");
        o = fdopen(oout, "w");
        fcpy(e, o, 0);
        fclose(e);
        fclose(o);
        close(p[1]);
        exit(1);
    }
    close(1);
    close(p[0]);
    close(p[1]);
    dup(oout);
}

/****************************************************
 * Try to find a filename with a list of extensions *
 ****************************************************/

void tryexts(src, dst, exts)
    STR src, dst, exts; {

    pchar ptr, ch;
    FILE *t;
    TOKEN ext;
 
    ext[0] = '\0';

    ptr = exts;

    while (ptr) {
        strcpy(dst, src); 
        strcat(dst, ext);   
        t = fopen(dst, "r");
        if (t) {
            fclose(t);
            return;
        }
        ptr = strchr(ptr, '.');
        if (!ptr) break;
        strcpy(ext, ptr);
        ch = strchr(ext + 1, '.');
        if (ch) *ch = '\0';
        ptr++;
    }
    strcpy(dst, src);
}

/***********************************
 * Dependency database             *
 ***********************************/

#ifdef __DEPEND_DB__

#include <db_185.h>

#define VECTOR_LN 6
typedef int dst_t[2][VECTOR_LN];

/*************************************
 * File checksum                     *
 *************************************/

int checksum(filename)
    STR filename; {

    int r = 0, x = 0;
    FILE *i = FOPEN(filename, "r");
    while (!feof(i)) r += (getw(i) ^ ++x);
    fclose(i);
    return r;
}

/*******************************************
 * Create a block from file statistics     *
 *******************************************/

int loadstat(ary, filename)
    STR filename;
    int ary[]; {
    struct stat st; 

    if (stat(filename, &st) < 0) return 0;
    bzero(ary, sizeof(int) * VECTOR_LN);
    ary[0] = st.st_mtime;
    ary[1] = st.st_ctime;
    ary[2] = st.st_mode;
    ary[3] = st.st_size;
    ary[4] = st.st_ino;
    ary[5] = checksum(filename);
    return 1;
}

/****************************************************************
 * Validate or store information about two dependent files      *
 ****************************************************************/

short fit(filename1, filename2, action) 
    STR filename1, filename2;
    int action; {

    FILENAME dbfn;
    TOKEN skey;
    DB *db;
    dst_t *rec, facts;
    DBT key, datum;
    int code;
    pchar ch;
    char c, c2;

    loadstat(facts[0], filename1);
    if (!loadstat(facts[1], filename2)) return 0;

    c = (char)(facts[0][3] + facts[1][3]);
    c2 = (char)(facts[0][0] + facts[1][0]);

    sprintf(dbfn, "%s/htpl-depend.db", scriptdir);
    sprintf(skey, "%s//\\\\//%s", filename1, filename2);

    for (ch = skey; *ch; ch++, c = c + c2) *ch ^= c;

    db = dbopen(dbfn, O_CREAT | O_RDWR, S_IREAD | S_IWRITE, DB_HASH, NULL);
    
    key.data = (PTR)&skey[0];
    key.size = strlen(skey);
    if (action == 0) {
        if (db->get(db, &key, &datum, 0)) return 1;
        rec = datum.data;
        code = memcmp(rec, &facts, sizeof(dst_t));
        db->close(db);
        return code;
    }
    if (action == 1) {
        datum.data = &facts;
        datum.size = sizeof(dst_t);
        db->put(db, &key, &datum, 0);
        db->close(db);
        return;
    }
}

#else

/************************************************************
 * Always succeed if dependency database is not implemented *
 ************************************************************/

short fit(filename1, filename2, action) 
    STR filename1, filename2;
    int action; {

    return 0;
}

#endif /* __DEPEND_DB__ */

/*********************************
 * Output #line numbers          *
 *********************************/

void outline(o, filename, line)
    FILE *o;
    STR filename;
    long line; {
    outf(o, "#line %d %s", line, filename);
}

/*****************************************
STR mystrdup(src)
    STR src; {

    STR dst = malloc(strlen(src) + 1);
    strcpy(dst, src);
    return dst;
}
*/

/******************************
 * Initialize a vector        *
 ******************************/

void vectorinit(vec)
    VECTOR vec; {
    vec->alloc = 4;
    vec->num = 0;
    vec->data = calloc(vec->alloc, sizeof(PTR));
}

/****************************************
 * Push element to a vector             *
 ****************************************/

void vectorpush(vec, el)
    VECTOR vec;
    PTR el; {
/*    if (!vec->data) vectorinit(vec);*/
    if (vec->num >= vec->alloc - 1) {
        vec->alloc += 4;
        vec->data = realloc(vec->data, vec->alloc * sizeof(PTR));
    }
    vec->data[vec->num++] = el;
}

/*************************************
 * Destroy a vector                  *
 *************************************/

void vectorkill(vec)
    VECTOR vec; {
    int i;
    if (!vec || !vec) return;
    for (i = 0; i < vec->num; i++) free(vec->data[i]);
    free(vec->data);
}

/***************************************************
 * Report compile time error                       *
 ***************************************************/

void croak(char *fmt, ...) {
    va_list ap;
    
    if (fatal) return;
    va_start(ap, fmt);
    vasprintf(&errstr, fmt, ap);
    va_end(ap);
    
    fatal = 1;
    asprintf(&errloc, "File %s, Line %d", infile, nline);
}
/**********************************************************
 * Escape variables Cold Fusion Style                     *
 **********************************************************/

STR escapevars(code)
    STR code; {
    pchar ch;
    short flag = 0;
    int len = strlen(code);
    STR buff = malloc(len + 4);
    pchar dst = buff;
    TOKEN alt, bk;
    pchar save;
    STR todel;
    pchar sub, ptr;
    int n, m, act, pos;
    int bidi;
    char cast;

#define ismetachar(ch) ((ch) == '%' || (ch) == '@' || (ch) == '^')

    ch = code;
    while (*ch) {
#ifdef SHARP_VARS
        if (*ch == '#') {
            switch (flag) {
                case 0: flag = 1;
                        bidi = 0;
                        cast = 0;
                        save = dst;
                        dst = alt;
                        break;
                case 1: dst = save;
                        flag = 0;
                        *dst++ = '#';
                        break;
                case 4: 
                case 3: 
                case 2: *dst = '\0';
                        n = dst-- - alt + 2;
                        while (ismetachar(*dst) && dst > alt) *dst-- = '\0';
                        todel = sub = malloc(n + 80);
                        if (flag > 2 || bidi) {
                            if (bidi) {
                                strcpy(bk, alt);
                                sprintf(alt, "hebrewflip($%s)", bk);
                            } else {
                                strcpy(bk, alt);
                                alt[0] = '$';
                                strcpy(&alt[1], bk);
                            }
                            if (flag == 4) n = m;
                            switch (cast) {
                                case 0   : sprintf(sub, "\" . %s . \"", alt);
                                           break;
                                case '%' : sprintf(sub, 
                                 "\" . substr(killnl(%s) . ' ' x %d, 0, %d) . \"",
                                    alt, n, n);
                                           break;
                                case '@' : sprintf(sub, 
                                 "\" . substr(' ' x %d . killnl(%s), -%d) . \"",
                                    n, alt, n);
                                           break;
                                case '^' : sprintf(sub, 
                                 "\" . substr(' ' x (%d / 2) . killnl(%s) . ' ' x (%d / 2),0, %d) . \"",
                                    n, alt, n, n);
                                           break;
                            }
                        } else {
                            *sub++ = '$';
                            *sub++ = '{';
                            *++dst = '}';
                            *++dst = '\0';
                            strcpy(sub, alt);
                        }
                        act = strlen(todel);
                        pos = save - buff;
                        buff = realloc(buff, len + act + 4);
                        save = buff + pos;
                        strcpy(save, todel);
                        free(todel);
                        dst = save + act;
                        flag = 0;
                        break;
            } 
        } else if (flag < 3 && (isalnum(*ch) || *ch == '_')) {
            if (flag == 1) flag = 2;
            *dst++ = *ch;
        } else if (flag == 1 && *ch == '!' && !bidi) {
            bidi = 1;
        } else if (flag == 2 && ismetachar(*ch)) {
            flag = 3;
            cast = *ch;
            *dst++ = *ch;
            m = 1;
        } else if (flag == 3 && *ch == '-') {
            flag = 4;
        } else if ((flag == 3 || flag == 4) && cast == *ch) {
            *dst++ = *ch;
            m++;
#else
        if (0) {
#endif
        } else {
            if (flag) {
                *dst = '\0';
                *save++ = '#';
                strcpy(save, alt);
                dst = save + strlen(save);
                flag = 0;
            }
	    if (*ch == '[' && (dst == buff || dst[-1] != '\\')
                && flag == 0) *dst++ = '\\';
            *dst++ = *ch;
        }
        ch++;
    }
    *dst = '\0';
    return buff;
}

/*********************************************
 * Write text to output file, counting lines *
 *********************************************/

void outblock(o, buffer)
    FILE *o;
    STR buffer; {
    pchar ch2, ch = buffer;
    STR top;

    if (!*buffer) {
        fprintf(o, NEWLINE);
        rline++;
        return;
    }

    while (ch && *ch) {
        ch2 = strchr(ch, '\n'); 
        if (ch2) {
            *ch2 = '\0';
            ch2++;
        }
        fprintf(o, "%s%s", ch, NEWLINE);
        ch = ch2;
        rline++;
    }
}

/*******************************************************
 * Convert slash to local slash                        *
 *******************************************************/

STR qualify(filename, thread)
    STR filename;
    int thread; {

    static FILENAME buffer[4];
    pchar src = filename;
    pchar dst = buffer[thread];

    if (SLASH_CHAR != '\\') return filename;
    while (*src) {
        if (*src == '\\') *dst++ = '\\';
        *dst++ = *src++;
    }
    *dst = '\0';

    return buffer[thread];
}

/***********************************************************
 * Count lines in a buffer                                 *
 ***********************************************************/

int countlines(buff)
    STR buff; {

    pchar ch2, ch = buff;
    int num = 0;

    if (!*buff) return 0;
    while (*ch) {
        ch2 = strchr(ch, '\n');
        if (!ch2) return num;
        num++;
        ch = ch2 + 1;
    }
    return num;
}

/**************************************************************
 * Replace occurences of one specific char                    *
 **************************************************************/

void replacechar(src, ch1, ch2)
    char ch1, ch2;
    STR src; {

    pchar pch;
    if (ch1 == ch2) return;
    for (pch = src; *pch; pch++) if (*pch == ch1) *pch = ch2;
}

/********************************************************
 * Copy files                                           *
 ********************************************************/

void fcopy(src, dst)
    STR src, dst; {

    FILE *i = FOPEN(src, "rb");
    FILE *o = FOPEN(dst, "wb");

    fcpy(i, o, 0);

    fclose(i);
    fclose(o);
}

/*********************************************************
 * Add to binary tree                                    *
 *********************************************************/

BTREE *btreeadd(tree, key, data)
    BTREE *tree;
    STR key;
    PTR data; {

    int cmp;

    while (1) {
        if (!*tree) {
            *tree = malloc(sizeof(struct btree));
            (*tree)->data = data;
            (*tree)->key = strdup(key);
            (*tree)->left = (*tree)->right = NULL;
            return tree;
        }
        cmp = strcmp((*tree)->key, key);
        if (cmp) cmp = (int)(cmp / abs(cmp));
        switch (cmp) {
            case 0 : free((*tree)->data);
                     (*tree)->data = data;
                     return;
            case 1 : tree = &((*tree)->left);
                     break;
            case -1: tree = &((*tree)->right);
                     break;
        }
    } 
}

/***************************************************
 * Scan a binary tree                              *
 ***************************************************/

BTREE *btreescan(tree, proc, level, tag, when) 
    BTREE *tree; 
    int level;
    PTR tag;
    int when;
    btreecallback proc; {

    BTREE *res;

    if (tree && *tree) {
#define SCAN(node) if (res = btreescan(&((*tree)->node), proc, level + 1, tag, when)) \
                     return res;
#define DOIT(w) if (when == w && proc(tree, level, tag)) return tree;
        DOIT(BTREE_PREFIX)
        SCAN(left) 
        DOIT(BTREE_INFIX)
        SCAN(right)
        DOIT(BTREE_POSTFIX)
#undef SCAN
#undef DOIT
    }
    return NULL;
}

int __btreekillnode(node, level, tag)
    BTREE *node;
    int level; 
    PTR tag; {
    free((*node)->key);
    if ((*node)->data) free((*node)->data);
    free(*node);
    *node = NULL;
    return 0;
}
/****************************************
 * Kill a binary tree                   *
 ****************************************/

void btreekill(tree) 
    BTREE *tree; {
    btreescan(tree, &__btreekillnode, 0, NULL, BTREE_POSTFIX);
}

int __btreechknode(node, level, tag)
    BTREE *node;
    PTR tag;
    int level; {
    return !strcmp((*node)->key, (STR)tag);
}

BTREE *btreesearch2(tree, key)
    BTREE *tree;
    STR key; {
    
    return btreescan(tree, &__btreechknode, 0, (PTR)key, BTREE_INFIX);
}

/***********************************************************
 * Search for a key in a binary tree                       *
 ***********************************************************/

PTR btreesearch(tree, key)
    BTREE tree;
    STR key; {
    
    BTREE *node = btreesearch2(&tree, key);
    if (!node || !*node) return NULL;
    return (*node)->data;
}

/**************************************************************
 * Erase a node in a binary tree                              *
 **************************************************************/

PTR btreedel(node)
    BTREE *node; {
    BTREE left, right, ptr;
    PTR datum = (*node)->data;
    left = (*node)->left;
    right = (*node)->right;
    __btreekillnode(node, 0, NULL);
    ptr = *node = left;
    if (!ptr) {
        *node = right;
        return;
    }
    while (ptr && ptr->right) ptr = ptr->right;
    ptr->right = right;
    return datum;
}

/********************************************************
 * Erase a node in a binary tree by key                 *
 ********************************************************/

PTR btreedelkey(tree, key)
    BTREE *tree;
    STR key; {
    BTREE *node = btreesearch2(tree, key);
    if (node) return btreedel(node);
    return NULL;
}

int __btreesimple(node, level, tag)
    BTREE *node;
    int level;
    PTR tag; {

    btreesimpleproc proc = (btreesimpleproc)tag;
    proc((*node)->data);
    return 0;
}

/***********************************************
 * Simply scan a binary tree                   *
 ***********************************************/

void btreesimplescan(tree, proc)
    BTREE tree;
    btreesimpleproc proc; {

    btreescan(&tree, __btreesimple, 0, (PTR)proc, BTREE_INFIX);
}

int makecomponent(filename) 
    STR filename; {
    char *argv[5];
    FILENAME work, work2;
    FILENAME dirbefore, thisdir;
    FILENAME temp;
    int code;
    pchar ch;

    getcwd(dirbefore, sizeof(FILENAME));
    finddir(filename, thisdir);
    chdir(thisdir);

    nodir(filename, work2);
    ch = strchr(work2, '.');
    if (ch) *ch ='\0';
    sprintf(work, "%s%chtplp", bindir, SLASH_CHAR);
    argv[0] = PERL_BIN;
    argv[1] = work;
    argv[2] = work2;
    argv[3] = NULL;


    maketemp(temp, "comp");
    code = EXECPERL(3, argv, NULL, NULL, temp, 1);
    if (code) {
        FILE *i;
#ifdef __DEBUG__
        if (runit)
#endif
        printf("Content-type: text/plain\n\n");
        printf("Component compiler (htplp) failed:\n");
        i = fopen(temp, "r");
        fcpy(i, stdout, 0);
        fclose(i);
        unlink(temp);
        exit(1);
    }
    unlink(temp);
    chdir(dirbefore);
}

/********************************************************
 * Pipe a string through a process                      *
 ********************************************************/

STR preprocess(str, cmd)
    STR str, cmd; {

    int dad_rdr, dad_wtr, kid_rdr, kid_wtr, dad_err, kid_err;
    int pi[2], po[2], pe[2];
    int pid;
    FILE *f, *i;
    int code;
    STR buff;
    char chunk[BUFF_SIZE];
    int len, red;

    fflush(stdout);

    pipe(pi);
    pipe(po);
    pipe(pe);


    dad_rdr = po[0];
    dad_wtr = pi[1];
    kid_rdr = pi[0];
    kid_wtr = po[1];
    dad_err = pe[0];
    kid_err = pe[1];
    

    if ((pid = fork()) == 0) {
        close(dad_wtr);
        close(dad_rdr);
        close(dad_err);
        close(0);
        dup(kid_rdr);
        close(1);
        dup(kid_wtr);
        close(2);
        dup(kid_err);
        system(cmd);
        fflush(stdout);
        exit(0);
    }

    if (pid < 0) {
#ifndef _WIN32
        croak("PP: fork failed: %s", sys_errlist[errno]);
#else
        croak("PP: fork failed");
#endif
        close(kid_err);
        close(kid_rdr);
        close(kid_wtr);
        close(dad_wtr);
        close(dad_rdr);
        close(dad_err);
      
        return strdup("");
    }

    close(kid_err);
    close(kid_rdr);
    close(kid_wtr);

    write(dad_wtr, str, strlen(str));
    close(dad_wtr);

    waitpid(pid, &code, 0);



    if (!WIFEXITED(code)) {
        TOKEN err;
        FILE *e = fdopen(dad_err, "r");
        close(dad_rdr);
        if (e) {
            fgets(err, sizeof(err), e);
            err[strlen(err) - 1] = '\0';
        }
        fclose(e);
        croak("PP: Child returned error: %s", err);
        return strdup("");
    }

    close(dad_err);

    buff = strdup("");
    len = 0;

    while ((red = read(dad_rdr, chunk, sizeof(chunk))) > 0) {
        buff = realloc(buff, len + red);
        memcpy(buff + len, chunk, red);
        len += red;
    }

    close(dad_rdr);
    buff[len] = '\0';
    return buff;
}

/**************************************************************
 * Open a text file, optionally via a filter if such exists   *
 * The second parameter contains the filename to search for   *
 * filter instructions inside                                 *
 **************************************************************/

FILE* openif(filename, filter)
    STR filename, filter; {
    FILENAME dir;
    FILENAME try;
    FILE *f;
    TOKEN pn;

    finddir(filename, dir);
    sprintf(try, "%s%c%s", dir, SLASH_CHAR, filter);
    if (f = fopen(try, "r")) {
        fgets(pn, sizeof(pn), f);
        fclose(f);
        pn[strlen(pn) - 1] = '\0';
        if (!strstr(pn, "%s")) strcat(pn, " %s");
        sprintf(try, pn, filename);
        if (f = popen(try, "r")) return f;
        puts("Content-type: text/plain\n");
#ifndef _WIN32
        printf("Could not spawn filter %s: %s", filter, sys_errlist[errno]);
#else
        printf("Could not spawn filter %s", filter);
#endif
        exit(-1);
    }
    return FOPEN(filename, "r");
}

/*********************************************************
 * Open an HTPL source                                   *
 *********************************************************/

FILE* opensource(filename)
    STR filename; {
    return openif(filename, "htsource.pre");
}

/*********************************************************
 * Open output of an HTPL script                         *
 *********************************************************/

FILE* openoutput(filename)
    STR filename; {
    return openif(filename, "htout.pre");
}

short debugforbidden(out) 
    FILE *out; {

    unsigned long a, b, c, d, e;
    unsigned long rh, sn, nm;
    FILE *i;
    FILENAME inp;
    TOKEN line;
    pchar ch, ch2;

#define VOUS(a, b, c, d) (((((((a) << 8) + (b)) << 8) + (c)) << 8) + (d))

    static STR mask ="%s%chtpl.dbg";

    STR remote = getenv("REMOTE_ADDR");
    if (!remote) return 0;
    sprintf(inp, mask, scriptdir, SLASH_CHAR);
    i = fopen(inp, "r");

    if (!i) {
        sprintf(inp, mask, bindir, SLASH_CHAR);
        i = fopen(inp, "r");
    }

    if (!i) return 0;

    sscanf(remote, "%d.%d.%d.%d", &a, &b, &c, &d);
    rh = VOUS(a, b, c, d);
    if (rh == VOUS(127, 0, 0, 1)) {
        fclose(i);
        return 0;
    }

    for (;;) {
        fgets(line, sizeof(line), i);
        if (feof(i)) {
            fclose(i);
            return 1;
        }
        ch = &line[strlen(line)];
        while (*ch == '\n' || isspace(*ch)) *ch-- = '\0';
        strcpy(ch + 1, "\n");
        ch2 = line;
        while (isspace(*ch2)) ch2++;
        ch = strpbrk(ch2, "\t ");
        if (!ch) break;
        *ch++ = '\0';
        d = -1;
        sscanf(ch2, "%d.%d.%d.%d", &a, &b, &c, &d);
        if (d < 0) break;
        sn = VOUS(a, b, c, d);
        while (isspace(*ch)) ch++;
        d = -1;
        sscanf(ch, "%d.%d.%d.%d%c", &a, &b, &c, &d, &e);
        if (e != '\n') break;
        nm = VOUS(a, b, c, d);

        if ((sn & nm) == (rh & nm)) {
            fclose(i);
            return 0;
        }
    }    
    fprintf(out, "%sFormat of %s wrong%s", NEWLINE, inp, NEWLINE);
    fclose(i);
    return 1;
}

void findpath(prog, dst)
    STR prog, dst; {

    STR path = getenv("PATH");
    char sep;
    STR copy;
    pchar p;
    
    dst[0] = '\0';
    if (!path) return;
    sep = SLASH_CHAR == '/' ? ':' : ';';
    copy = strdup(path);
    p = copy;
    while (p) {
	pchar p2 = strchr(p, sep);
	STR candidate;

	if (p2) *p2++ = '\0';
	asprintf(&candidate, "%s%c%s", p, SLASH_CHAR, prog);
	if (!access(candidate, X_OK)) {
	    while (readlink(candidate, dst, sizeof(TOKEN)) > 0) {
		free(candidate);
		candidate = strdup(dst);
	    }
            strcpy(dst, candidate);
            free(candidate);
	    free(copy);
	    return;
	}
	free(candidate);
	p = p2;
    }
    free(copy);
}
