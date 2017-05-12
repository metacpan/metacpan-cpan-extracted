/*
**        ____           _ 
**    ___|  _ \ ___ _ __| |
**   / _ \ |_) / _ \ '__| |
**  |  __/  __/  __/ |  | |
**   \___|_|   \___|_|  |_|
** 
**  ePerl -- Embedded Perl 5 Language
**
**  ePerl interprets an ASCII file bristled with Perl 5 program statements
**  by evaluating the Perl 5 code while passing through the plain ASCII
**  data. It can operate both as a standard Unix filter for general file
**  generation tasks and as a powerful Webserver scripting language for
**  dynamic HTML page programming. 
**
**  ======================================================================
**
**  Copyright (c) 1996,1997,1998 Ralf S. Engelschall <rse@engelschall.com>
**
**  This program is free software; it may be redistributed and/or modified
**  only under the terms of either the Artistic License or the GNU General
**  Public License, which may be found in the ePerl source distribution.
**  Look at the files ARTISTIC and COPYING or run ``eperl -l'' to receive
**  a built-in copy of both license files.
**
**  This program is distributed in the hope that it will be useful, but
**  WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
**  Artistic License or the GNU General Public License for more details.
**
**  ======================================================================
**
**  eperl_main.c -- ePerl main procedure 
*/

#include "eperl_config.h"
#include "eperl_global.h"
#include "eperl_security.h"
#include "eperl_getopt.h"
#include "eperl_perl5.h"
#include "eperl_proto.h"

int mode = MODE_UNKNOWN;

char *allowed_file_ext[]   = LIST_OF_ALLOWED_FILE_EXT;
char *allowed_caller_uid[] = LIST_OF_ALLOWED_CALLER_UID;

/*
 *  Display an error message and a logfile content as a HTML page
 */
void PrintError(int mode, char *scripturl, char *scriptfile, char *logfile, char *str, ...)
{
    va_list ap;
    char ca[1024];
    char *cpBuf;
    char *cp;

    va_start(ap, str);
    vsprintf(ca, str, ap);

    IO_restore_stdout();
    IO_restore_stderr();

    if (mode == MODE_CGI || mode == MODE_NPHCGI) {
        if (mode == MODE_NPHCGI)
            HTTP_PrintResponseHeaders("");
        printf("Content-Type: text/html\n\n");
        printf("<html>\n");
        printf("<head>\n");
        printf("<title>ePerl: ERROR: %s</title>\n", ca);
        printf("</head>\n");
        printf("<body bgcolor=\"#d0d0d0\">\n");
        printf("<blockquote>\n");
        cp = getenv("SCRIPT_NAME");
        if (cp == NULL)
            cp = "UNKNOWN_IMG_DIR";
        printf("<a href=\"http://www.engelschall.com/sw/eperl/\"><img src=\"%s/powered.gif\" alt=\"Powered By ePerl\" align=right border=0></a>\n", cp);
        printf("<table cellspacing=0 cellpadding=0 border=0>\n");
        printf("<tr>\n");
        printf("<td><img src=\"%s/logo.gif\" alt=\"Embedded Perl 5 Language\"></td>\n", cp);
        printf("</tr>\n");
        printf("<tr>\n");
        printf("<td align=right><b>Version %s</b></td>\n", ePerl_Version);
        printf("</tr>\n");
        printf("</table>\n");
        printf("<p>\n");
        printf("<table bgcolor=\"#d0d0f0\" cellspacing=0 cellpadding=10 border=0>\n");
        printf("<tr><td bgcolor=\"#b0b0d0\">\n");
        printf("<font face=\"Arial, Helvetica\"><b>ERROR:</b></font>\n");
        printf("</td></tr>\n");
        printf("<tr><td>\n");
        printf("<h1><font color=\"#3333cc\">%s</font></h1>\n", ca);
        printf("</td></tr>\n");
        printf("</table>\n");
        if (logfile != NULL) {
            if ((cpBuf = ePerl_ReadErrorFile(logfile, scriptfile, scripturl)) != NULL) {
                printf("<p>");
                printf("<table bgcolor=\"#e0e0e0\" cellspacing=0 cellpadding=10 border=0>\n");
                printf("<tr><td bgcolor=\"#c0c0c0\">\n");
                printf("<font face=\"Arial, Helvetica\"><b>Contents of STDERR channel:</b></font>\n");
                printf("</td></tr>\n");
                printf("<tr><td>\n");
                printf("<pre>\n");
                printf("%s", cpBuf);
                printf("</pre>");
                printf("</td></tr>\n");
                printf("</table>\n");
            }
        }
        printf("</blockquote>\n");
        printf("</body>\n");
        printf("</html>\n");
    }
    else {
        fprintf(stderr, "ePerl:Error: %s\n", ca);
        if (logfile != NULL) {
            if ((cpBuf = ePerl_ReadErrorFile(logfile, scriptfile, scripturl)) != NULL) {
                fprintf(stderr, "\n");
                fprintf(stderr, "---- Contents of STDERR channel: ---------\n");
                fprintf(stderr, "%s", cpBuf);
                if (cpBuf[strlen(cpBuf)-1] != '\n')
                    fprintf(stderr, "\n");
                fprintf(stderr, "------------------------------------------\n");
            }
        }
    }
    fflush(stderr);
    fflush(stdout);
    
    va_end(ap);
    return;
}

void give_version(void)
{
    fprintf(stdout, "%s\n", ePerl_Hello);
    fprintf(stdout, "\n");
    fprintf(stdout, "Copyright (c) 1996,1997,1998 Ralf S. Engelschall <rse@engelschall.com>\n");
    fprintf(stdout, "\n");
    fprintf(stdout, "This program is distributed in the hope that it will be useful,\n");
    fprintf(stdout, "but WITHOUT ANY WARRANTY; without even the implied warranty of\n");
    fprintf(stdout, "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either\n");
    fprintf(stdout, "the Artistic License or the GNU General Public License for more details.\n");
    fprintf(stdout, "\n");
}

void give_version_extended(void)
{
    give_version();
    fprintf(stdout, "Characteristics of this binary:\n");
    fprintf(stdout, "  Perl Version    : %s (%s)\n", AC_perl_vers, AC_perl_prog);
    fprintf(stdout, "  Perl I/O Layer  : %s\n", PERL_IO_LAYER_ID);
    fprintf(stdout, "  Perl Library    : %s/CORE/libperl.a\n", AC_perl_archlib);
    fprintf(stdout, "  Perl DynaLoader : %s\n", AC_perl_dla);
    fprintf(stdout, "  System Libs     : %s\n", AC_perl_libs);
    fprintf(stdout, "  Built User      : %s\n", AC_build_user);
    fprintf(stdout, "  Built Time      : %s\n", AC_build_time_iso);
    fprintf(stdout, "\n");
}

void give_readme(void)
{
    fprintf(stdout, ePerl_README);
}

void give_license(void)
{
    fprintf(stdout, ePerl_LICENSE);
}

void give_img_logo(void)
{
    if (mode == MODE_NPHCGI)
        HTTP_PrintResponseHeaders("");
    printf("Content-Type: image/gif\n\n");
    fwrite(ePerl_LOGO_data, ePerl_LOGO_size, 1, stdout);
}

void give_img_powered(void)
{
    if (mode == MODE_NPHCGI)
        HTTP_PrintResponseHeaders("");
    printf("Content-Type: image/gif\n\n");
    fwrite(ePerl_POWERED_data, ePerl_POWERED_size, 1, stdout);
}

void give_usage(char *name)
{
    fprintf(stderr, "Usage: %s [options] [scriptfile]\n", name);
    fprintf(stderr, "\n");
    fprintf(stderr, "Input Options:\n");
    fprintf(stderr, "  -d, --define=NAME=VALUE   define global Perl variable ($main::name)\n");
    fprintf(stderr, "  -D, --setenv=NAME=VALUE   define environment variable ($ENV{'name'})\n");
    fprintf(stderr, "  -I, --includedir=PATH     add @INC/#include directory\n");
    fprintf(stderr, "  -B, --block-begin=STR     set begin block delimiter\n");
    fprintf(stderr, "  -E, --block-end=STR       set end block delimiter\n");
    fprintf(stderr, "  -n, --nocase              force block delimiters to be case insensitive\n");
    fprintf(stderr, "  -k, --keepcwd             force keeping of current working directory\n");
    fprintf(stderr, "  -P, --preprocess          enable ePerl Preprocessor\n");
    fprintf(stderr, "  -C, --convert-entity      enable HTML entity conversion for ePerl blocks\n");
    fprintf(stderr, "  -L, --line-continue       enable line continuation via backslashes\n");
    fprintf(stderr, "\n");
    fprintf(stderr, "Output Options:\n");
    fprintf(stderr, "  -T, --tainting            enable Perl Tainting\n");
    fprintf(stderr, "  -w, --warnings            enable Perl Warnings\n");
    fprintf(stderr, "  -x, --debug               enable ePerl debugging output on console\n");
    fprintf(stderr, "  -m, --mode=STR            force runtime mode to FILTER, CGI or NPH-CGI\n");
    fprintf(stderr, "  -o, --outputfile=PATH     force the output to be send to this file (default=stdout)\n");
    fprintf(stderr, "  -c, --check               run syntax check only and exit (no execution)\n");
    fprintf(stderr, "\n");
    fprintf(stderr, "Giving Feedback:\n");
    fprintf(stderr, "  -r, --readme              display ePerl README file\n");
    fprintf(stderr, "  -l, --license             display ePerl license files (COPYING and ARTISTIC)\n");
    fprintf(stderr, "  -v, --version             display ePerl VERSION id\n");
    fprintf(stderr, "  -V, --ingredients         display ePerl VERSION id & compilation parameters\n");
    fprintf(stderr, "  -h, --help                display ePerl usage list (this one)\n");
    fprintf(stderr, "\n");
}

char *RememberedINC[1024] = { NULL };

void RememberINC(char *str) 
{
    int i;

    for (i = 0; RememberedINC[i] != NULL; i++)
        ;
    RememberedINC[i++] = strdup(str);
    RememberedINC[i++] = NULL;
    return;
}

void mysighandler(int rc)
{
    /* ignore more signals */
    signal(SIGINT,  SIG_IGN);
    signal(SIGTERM, SIG_IGN);

    /* restore filehandles */
    IO_restore_stdout();
    IO_restore_stderr();

    /* give interrupt information */
    fprintf(stderr, "ePerl: **INTERRUPT**\n");

    /* exit immediately */
    myexit(EX_FAIL);
}

void myinit(void)
{
    /* caught signals */
    signal(SIGINT,  mysighandler);
    signal(SIGTERM, mysighandler);
}

void myexit(int rc)
{
    /* cleanup */
#ifndef DEBUG_ENABLED
    remove_mytmpfiles();
#endif

    /* restore signals */
    signal(SIGINT,  SIG_DFL);
    signal(SIGTERM, SIG_DFL);

#ifdef DEBUG_ENABLED
#ifdef HAVE_DMALLOC
    dmalloc_shutdown();
#endif
#endif

    /* die gracefully */
    exit(rc);
}

struct option options[] = {
    { "define",         1, NULL, 'd' },
    { "setenv",         1, NULL, 'D' },
    { "includedir",     1, NULL, 'I' },
    { "block-begin",    1, NULL, 'B' },
    { "block-end",      1, NULL, 'E' },
    { "nocase",         0, NULL, 'n' },
    { "keepcwd",        0, NULL, 'k' },
    { "preprocess",     0, NULL, 'P' },
    { "convert-entity", 0, NULL, 'C' },
    { "line-continue",  0, NULL, 'L' },
    { "tainting",       0, NULL, 'T' },
    { "warnings",       0, NULL, 'w' },
    { "debug",          0, NULL, 'x' },
    { "mode",           1, NULL, 'm' },
    { "outputfile",     1, NULL, 'o' },
    { "check",          0, NULL, 'c' },
    { "readme",         0, NULL, 'r' },
    { "license",        0, NULL, 'l' },
    { "version",        0, NULL, 'v' },
    { "ingredients",    0, NULL, 'V' },
    { "help",           0, NULL, 'h' }
};

/*
 *  main procedure
 */
int main(int argc, char **argv, char **env)
{
    DECL_EXRC;
    FILE *fp = NULL;
    FILE *er = NULL;
    FILE *out = NULL;
    char *cpBuf = NULL;
    char *cpBuf2 = NULL;
    char *cpBuf3 = NULL;
    char perlscript[1024] = "";
    char perlstderr[1024] = "";
    char perlstdout[1024] = "";
    char dir_tmp[1024];
    char *dir_home;
    char *dir_script;
    char ca[1024] = "";
    int myargc;
    char *myargv[20];
    char *progname;
    int nBuf;
    int nOut;
    char *source = NULL;
    char sourcedir[2048];
    char *cp;
    static PerlInterpreter *my_perl = NULL; 
    struct stat st;
    char *cpOut = NULL;
    int size;
    struct passwd *pw;
    struct passwd *pw2;
    struct group *gr;
    int uid, gid;
    int keepcwd = FALSE;
    int c;
    char *cpScript = NULL;
    int allow;
    int i, n, k;
    char *outputfile = NULL;
    char cwd[MAXPATHLEN];
    int fCheck = FALSE;
    int fTaint = FALSE;
    int fWarn = FALSE;
    int fNoCase = FALSE;
    int fPP = FALSE;
    char *cwd2;
    int fOkSwitch;
    char *cpHost;
    char *cpPort;
    char *cpPath;
    char *cpCGIgi;
    char *cpCGIpt;
    char *cpCGIqs;

    /*  first step: our process initialisation */
    myinit();

    /*  second step: canonicalize program name */
    progname = argv[0];
    if ((cp = strrchr(progname, '/')) != NULL) {
        progname = cp+1;
    }

    /*  parse the option arguments */
    opterr = 0;
    while ((c = getopt_long(argc, argv, ":d:D:I:B:E:nkPCLTwxm:o:crlvVh", options, NULL)) != -1) {
        if (optarg == NULL) 
            optarg = "(null)";
        switch (c) {
            case 'd':
                Perl5_RememberScalar(optarg);
                break;
            case 'D':
                env = Perl5_SetEnvVar(env, optarg);
                break;
            case 'I':
                RememberINC(optarg);
                break;
            case 'B':
                ePerl_begin_delimiter = strdup(optarg);
                break;
            case 'E':
                ePerl_end_delimiter = strdup(optarg);
                break;
            case 'n':
                fNoCase = TRUE;
                break;
            case 'k':
                keepcwd = TRUE;
                break;
            case 'P':
                fPP = TRUE;
                break;
            case 'C':
                ePerl_convert_entities = TRUE;
                break;
            case 'L':
                ePerl_line_continuation = TRUE;
                break;
            case 'T':
                fTaint = TRUE;
                break;
            case 'w':
                fWarn = TRUE;
                break;
            case 'x':
                fDebug = TRUE;
                break;
            case 'm':
                if (strcasecmp(optarg, "f") == 0     ||
                    strcasecmp(optarg, "filter") == 0  ) {
                    mode = MODE_FILTER;
                }
                else if (strcasecmp(optarg, "c") == 0   ||
                         strcasecmp(optarg, "cgi") == 0   ) {
                    mode = MODE_CGI;
                }
                else if (strcasecmp(optarg, "n") == 0      ||
                         strcasecmp(optarg, "nph") == 0    ||
                         strcasecmp(optarg, "nphcgi") == 0 ||
                         strcasecmp(optarg, "nph-cgi") == 0  ) {
                    mode = MODE_NPHCGI;
                }
                else {
                    PrintError(mode, "", NULL, NULL, "Unknown runtime mode `%s'", optarg);
                    CU(EX_USAGE);
                }
                break;
            case 'o':
                outputfile = strdup(optarg);
                break;
            case 'c':
                fCheck = TRUE;
                break;
            case 'r':
                give_readme();
                myexit(EX_OK);
            case 'l':
                give_license();
                myexit(EX_OK);
            case 'v':
                give_version();
                myexit(EX_OK);
            case 'V':
                give_version_extended();
                myexit(EX_OK);
            case 'h':
                give_usage(progname);
                myexit(EX_OK);
            case '?':
                if (isprint(optopt))
                    fprintf(stderr, "ePerl:Error: Unknown option `-%c'.\n", optopt);
                else
                    fprintf(stderr, "ePerl:Error: Unknown option character `\\x%x'.\n", optopt);
                fprintf(stderr, "Try `%s --help' for more information.\n", progname);
                myexit(EX_USAGE);
            case ':':
                if (isprint(optopt))
                    fprintf(stderr, "ePerl:Error: Missing argument for option `-%c'.\n", optopt);
                else
                    fprintf(stderr, "ePerl:Error: Missing argument for option character `\\x%x'.\n", optopt);
                fprintf(stderr, "Try `%s --help' for more information.\n", progname);
                myexit(EX_USAGE);
        }
    }

    /* 
     *  determine source filename and runtime mode 
     */

    if ((cpCGIgi = getenv("GATEWAY_INTERFACE")) == NULL)
        cpCGIgi = "";
    if ((cpCGIpt = getenv("PATH_TRANSLATED")) == NULL)
        cpCGIpt = "";
    if ((cpCGIqs = getenv("QUERY_STRING")) == NULL)
        cpCGIqs = "";

    if (cpCGIgi[0] != NUL &&
        cpCGIpt[0] != NUL &&
        (optind == argc || 
         (optind == argc-1 && 
          strcmp(argv[optind], cpCGIqs) == 0) ) ) {
        /*
        **  Server-Side-Scripting-Language:
        ** 
        **  Request:
        **      /url/to/nph-eperl/url/to/script.phtml[?query-string]
        **  Environment:
        **      GATEWAY_INTERFACE=CGI/1.1
        **      SCRIPT_NAME=/url/to/nph-eperl
        **      SCRIPT_FILENAME=/path/to/nph-eperl
        **      PATH_INFO=/url/to/script.phtml
        **      PATH_TRANSLATED=/path/to/script.phtml
        **      QUERY_STRING=query-string
        **      a) optind=argc 
        **      b) optind=argc-1, argv[optind]=query-string
        */
        
        if (strncasecmp(cpCGIgi, "CGI/1", 5) != 0) {
            fprintf(stderr, "ePerl:Error: Unknown gateway interface: NOT CGI/1.x\n");
            CU(EX_IOERR);
        }

        /*  CGI/1.1 or NPH-CGI/1.1 script, 
            source in PATH_TRANSLATED. */
        source = cpCGIpt;

        /*  determine whether pure CGI or NPH-CGI mode */ 
        if ((cp = getenv("SCRIPT_FILENAME")) != NULL) { 
            strcpy(ca, cp);
            if ((cp = strrchr(ca, '/')) != NULL) 
                *cp++ = NUL;
            else 
                cp = ca;
            if (strncasecmp(cp, "nph-", 4) == 0) 
                mode = (mode == MODE_UNKNOWN ? MODE_NPHCGI : mode);
            else
                mode = (mode == MODE_UNKNOWN ? MODE_CGI : mode);
        }
        else {
            mode = (mode == MODE_UNKNOWN ? MODE_CGI : mode);
        }

        /* set the command line for ``ps'' output */
        sprintf(ca, "%s %s [%sCGI]", argv[0], source, mode == MODE_NPHCGI ? "NPH-" : "");
        argv[0] = strdup(ca);
    }

    else if (cpCGIgi[0] != NUL &&
             ((optind == argc-1 && 
               cpCGIqs[0] == NUL  ) ||
              (optind == argc-2 && 
               strcmp(argv[optind+1], cpCGIqs) == 0) ) ) {
        /*
        **
        **  Stand-Alone inside Webserver environment:
        **
        **  Request:
        **      /url/to/script.cgi[/path-info][?query-string]
        **      [script.cgi has shebang #!/path/to/eperl]
        **  Environment:
        **      GATEWAY_INTERFACE=CGI/1.1
        **      SCRIPT_NAME=/url/to/script.cgi
        **      SCRIPT_FILENAME=/path/to/script.cgi
        **      PATH_INFO=/path-info
        **      PATH_TRANSLATED=/path/to/docroot/path-info
        **      QUERY_STRING=query-string
        **      a) optind=argc-1, argv[optind]=/path/to/script.cgi
        **      b) optind=argc-2, argv[optind]=/path/to/script.cgi
        **                        argv[optind+1]=query-string
        **
        */

        if (strncasecmp(cpCGIgi, "CGI/1", 5) != 0) {
            fprintf(stderr, "ePerl:Error: Unknown gateway interface: NOT CGI/1.x\n");
            CU(EX_IOERR);
        }

        /*  CGI/1.1 or NPH-CGI/1.1 script, 
            source in ARGV */
        source = argv[optind];

        /*  determine whether pure CGI or NPH-CGI mode */ 
        if ((cp = getenv("SCRIPT_FILENAME")) != NULL) { 
            strcpy(ca, cp);
            if ((cp = strrchr(ca, '/')) != NULL) 
                *cp++ = NUL;
            else 
                cp = ca;
            if (strncasecmp(cp, "nph-", 4) == 0) 
                mode = (mode == MODE_UNKNOWN ? MODE_NPHCGI : mode);
            else
                mode = (mode == MODE_UNKNOWN ? MODE_CGI : mode);
        }
        else {
            mode = (mode == MODE_UNKNOWN ? MODE_CGI : mode);
        }

        /* set the command line for ``ps'' output */
        sprintf(ca, "%s %s [%sCGI]", argv[0], source, mode == MODE_NPHCGI ? "NPH-" : "");
        argv[0] = strdup(ca);
    }

    else if (cpCGIgi[0] == NUL &&
             cpCGIpt[0] == NUL &&
             cpCGIqs[0] == NUL &&
             optind == argc-1    ) {
        /*
        **
        **  Stand-Alone outside Webserver environment:
        **
        **  Request:
        **      eperl script
        **  Environment:
        **      GATEWAY_INTERFACE=<empty>
        **      SCRIPT_NAME=<empty>
        **      SCRIPT_FILENAME=<empty>
        **      PATH_INFO=<empty>
        **      PATH_TRANSLATED=<empty>
        **      QUERY_STRING=<empty>
        **      optind=argc-1, argv[optind]=script
        **
        */

        /*  stand-alone filter, source as argument:
            either manually on the console or via shebang */
        source = argv[optind];
        mode   = (mode == MODE_UNKNOWN ? MODE_FILTER : mode);

        /*  provide flexibility by recognizing "-" for stdin */
        if (strcmp(source, "-") == 0) {
            /* store stdin to tmpfile */
            source = mytmpfile("ePerl.stdin");
            if ((fp = fopen(source, "w")) == NULL) {
                PrintError(mode, source, NULL, NULL, "Cannot open tmpfile `%s' for writing", source);
                CU(EX_IOERR);
            }
            while ((c = fgetc(stdin)) != EOF) {
                fputc(c, fp);
            }
            fclose(fp); fp = NULL;

            /* stdin script implies keeping of cwd */
            keepcwd = TRUE;
        }
    }

    else {
        /* else we are used in a wrong way... */
        fprintf(stderr, "ePerl:Error: Missing required file to process\n");
        fprintf(stderr, "ePerl:Error: Use either a filename, `-' for STDIN or PATH_TRANSLATED.\n");
        fprintf(stderr, "Try `%s --help' for more information.\n", progname);
        myexit(EX_USAGE);
    }

    /* set default delimiters */
    if (ePerl_begin_delimiter == NULL) {
        if (mode == MODE_FILTER)
            ePerl_begin_delimiter = BEGIN_DELIMITER_FILTER;
        else
            ePerl_begin_delimiter = BEGIN_DELIMITER_CGI;
    }
    if (ePerl_end_delimiter == NULL) {
        if (mode == MODE_FILTER)
            ePerl_end_delimiter = END_DELIMITER_FILTER;
        else
            ePerl_end_delimiter = END_DELIMITER_CGI;
    }
    if (fNoCase)
        ePerl_case_sensitive_delimiters = FALSE;
    else
        ePerl_case_sensitive_delimiters = TRUE;

    /* the built-in GIF images */
    if ((mode == MODE_CGI || mode == MODE_NPHCGI) && (cp = getenv("PATH_INFO")) != NULL) { 
        if (strcmp(cp, "/logo.gif") == 0) {
            give_img_logo();
            myexit(0);
        }
        else if (strcmp(cp, "/powered.gif") == 0) {
            give_img_powered();
            myexit(0);
        }
    }

    /* CGI modes imply 
       - Preprocessor usage 
       - HTML entity conversions
       - adding of DOCUMENT_ROOT to include paths */
    if (mode == MODE_CGI || mode == MODE_NPHCGI) {
        fPP = TRUE;
        ePerl_convert_entities = TRUE;
        if ((cp = getenv("DOCUMENT_ROOT")) != NULL)
            RememberINC(cp);
    }

    /* check for valid source file */
    if (*source == NUL) {
        PrintError(mode, "", NULL, NULL, "Filename is empty");
        CU(mode == MODE_FILTER ? EX_IOERR : EX_OK);
    }

    /* check for existing source file */
    if ((stat(source, &st)) != 0) {
        PrintError(mode, source, NULL, NULL, "File `%s' not exists", source);
        CU(mode == MODE_FILTER ? EX_IOERR : EX_OK);
    }

    /*
     * Security Checks for the CGI modes
     */
    if (mode == MODE_CGI || mode == MODE_NPHCGI) {

        /*
         *
         *  == General Security ==
         *
         */

        /* general security check: allowed file extension */
        if (CGI_NEEDS_ALLOWED_FILE_EXT) {
            allow = FALSE;
            n = strlen(source);
            for (i = 0; allowed_file_ext[i] != NULL; i++) {
                k = strlen(allowed_file_ext[i]);
                if (strcmp(source+n-k, allowed_file_ext[i]) == 0) 
                    allow = TRUE;
            }
            if (!allow) {
                PrintError(mode, source, NULL, NULL, "File `%s' is not allowed to be interpreted by ePerl (wrong extension!)", source);
                CU(EX_OK);
            }
        }

        /*
         *
         *  == Perl Security ==
         *
         */

        /* perhaps force Taint mode */
        if (CGI_MODES_FORCE_TAINTING)
            fTaint = TRUE;

        /* perhaps force Warnings */
        if (CGI_MODES_FORCE_WARNINGS)
            fWarn = TRUE;

        /*
         *
         * == UID/GID switching ==
         *
         */

        /* we can only do a switching if we have euid == 0 (root) */
        if (geteuid() == 0) {

            fOkSwitch = TRUE;

            /* get our real user id (= caller uid) */
            uid = getuid();
    
            /* security check: valid caller uid */
            pw = getpwuid(uid);
            if (SETUID_NEEDS_VALID_CALLER_UID && pw == NULL) {
                if (DO_FOR_FAILED_STEP == STOP_AND_ERROR) {
                    PrintError(mode, source, NULL, NULL, "Invalid UID %d of caller", uid);
                    CU(EX_OK);
                }
                else
                    fOkSwitch = FALSE;
            }
            else {
                /* security check: allowed caller uid */
                if (SETUID_NEEDS_ALLOWED_CALLER_UID) {
                    allow = FALSE;
                    for (i = 0; allowed_caller_uid[i] != NULL; i++) {
                        if (isdigit(allowed_caller_uid[i][0]))
                            pw2 = getpwuid(atoi(allowed_caller_uid[i]));
                        else
                            pw2 = getpwnam(allowed_caller_uid[i]);
                        if (strcmp(pw->pw_name, pw2->pw_name) == 0) {
                            allow = TRUE;
                            break;
                        }
                    }
                    if (!allow) {
                        if (DO_FOR_FAILED_STEP == STOP_AND_ERROR) {
                            PrintError(mode, source, NULL, NULL, "UID %d of caller not allowed", uid);
                            CU(EX_OK);
                        }
                        else
                            fOkSwitch = FALSE;
                    }
                }
            }
    
            /* security check: valid owner UID */
            pw = getpwuid(st.st_uid);
            if (SETUID_NEEDS_VALID_OWNER_UID && pw == NULL) 
                if (DO_FOR_FAILED_STEP == STOP_AND_ERROR) {
                    PrintError(mode, source, NULL, NULL, "Invalid UID %d of owner", st.st_uid);
                    CU(EX_OK);
                }
                else
                    fOkSwitch = FALSE;
            else 
                uid = pw->pw_uid;
    
            /* security check: valid owner GID */
            gr = getgrgid(st.st_gid);
            if (SETUID_NEEDS_VALID_OWNER_GID && gr == NULL) 
                if (DO_FOR_FAILED_STEP == STOP_AND_ERROR) {
                    PrintError(mode, source, NULL, NULL, "Invalid GID %d of owner", st.st_gid);
                    CU(EX_OK);
                }
                else
                    fOkSwitch = FALSE;
            else 
                gid = gr->gr_gid;
    
            /* security check: file has to stay below owner homedir */
            if (fOkSwitch && SETUID_NEEDS_BELOW_OWNER_HOME) {
                /* preserve current working directory */
                cwd2 = getcwd(NULL, 1024);

                /* determine physical homedir of owner */
                pw = getpwuid(st.st_uid);
                if (chdir(pw->pw_dir) == -1) {
                    if (DO_FOR_FAILED_STEP == STOP_AND_ERROR) {
                        PrintError(mode, source, NULL, NULL, "Invalid homedir ``%s'' of file owner", pw->pw_dir);
                        CU(EX_OK);
                    }
                    else 
                        fOkSwitch = FALSE;
                }
                else {
                    dir_home = getcwd(NULL, 1024);

                    /* determine physical dir of file */
                    strcpy(dir_tmp, source);
                    if ((cp = strrchr(dir_tmp, '/')) == NULL) {
                        if (DO_FOR_FAILED_STEP == STOP_AND_ERROR) {
                            PrintError(mode, source, NULL, NULL, "Invalid script ``%s'': no absolute path", source);
                            CU(EX_OK);
                        }
                        else 
                            fOkSwitch = FALSE;
                    }
                    else {
                        *cp = NUL;
                        if (chdir(dir_tmp) == -1) {
                            if (DO_FOR_FAILED_STEP == STOP_AND_ERROR) {
                                PrintError(mode, source, NULL, NULL, "Invalid script ``%s'': cannot chdir to its location", source);
                                CU(EX_OK);
                            }
                            else 
                                fOkSwitch = FALSE;
                        }
                        else {
                            dir_script = getcwd(NULL, 1024);
        
                            /* dir_home has to be a prefix of dir_script */
                            if (strncmp(dir_script, dir_home, strlen(dir_home)) < 0) {
                                if (DO_FOR_FAILED_STEP == STOP_AND_ERROR) {
                                    PrintError(mode, source, NULL, NULL, "Invalid script ``%s'': does not stay below homedir of owner", source);
                                    CU(EX_OK);
                                }
                                else 
                                    fOkSwitch = FALSE;
                            }
            
                            free(dir_script);
                        }
                    }
                    free(dir_home);
                }

                /* restore original cwd */
                chdir(cwd2);
        
                free(cwd2);
            }
    
            if (fOkSwitch && uid != 0 && gid != 0) {
                /* switch to new uid/gid */
                if (((setgid(gid)) != 0) || (initgroups(pw->pw_name,gid) != 0)) {
                    PrintError(mode, source, NULL, NULL, "Unable to set GID %d: setgid/initgroups failed", gid);
                    CU(mode == MODE_FILTER ? EX_IOERR : EX_OK);
                }
                if ((setuid(uid)) != 0) {
                    PrintError(mode, source, NULL, NULL, "Unable to set UID %d: setuid failed", uid);
                    CU(mode == MODE_FILTER ? EX_IOERR : EX_OK);
                }
            }
        }
    }

    /* Security! Eliminate effective root permissions if we are running setuid */
    if (geteuid() == 0) {
        uid = getuid();
        gid = getgid();
#ifdef HAVE_SETEUID
        seteuid(uid);
#else
        /* HP/UX and others eliminate the effective UID with setuid(uid) ! */
        setuid(uid);
#endif
#ifdef HAVE_SETEGID
        setegid(uid);
#else
        /* HP/UX and others eliminate the effective GID with setgid(gid) ! */
        setgid(gid);
#endif
    }

    /* read source file into internal buffer */
    if ((cpBuf = ePerl_ReadSourceFile(source, &cpBuf, &nBuf)) == NULL) {
        PrintError(mode, source, NULL, NULL, "Cannot open source file `%s' for reading\n%s", source, ePerl_GetError);
        CU(mode == MODE_FILTER ? EX_IOERR : EX_OK);
    }

    /* strip shebang prefix */
    if (strncmp(cpBuf, "#!", 2) == 0) {
        for (cpScript = cpBuf;
             (*cpScript != ' ' && *cpScript != '\t' && *cpScript != '\n') && (cpScript-cpBuf < nBuf);
             cpScript++)
            ;
        for (cpScript = cpBuf;
             *cpScript != '\n' && (cpScript-cpBuf < nBuf);
             cpScript++)
            ;
        cpScript++;
    }
    else
        cpScript = cpBuf;

    /* now set the additional env vars */
    env = mysetenv(env, "SCRIPT_SRC_PATH", "%s", abspath(source));
    env = mysetenv(env, "SCRIPT_SRC_PATH_FILE", "%s", filename(source));
    env = mysetenv(env, "SCRIPT_SRC_PATH_DIR", "%s", abspath(dirname(source)));
    if ((cpPath = getenv("PATH_INFO")) != NULL) {
        if ((cpHost = getenv("SERVER_NAME")) == NULL)
            cpHost = "localhost";
        cpPort = getenv("SERVER_PORT");
        if (strcmp(cpPort, "80") == 0)
            cpPort = NULL;
        sprintf(ca, "http://%s%s%s%s", 
                cpHost, cpPort != NULL ? ":" : "", cpPort != NULL ? cpPort : "", cpPath);
        env = mysetenv(env, "SCRIPT_SRC_URL", "%s", ca);
        env = mysetenv(env, "SCRIPT_SRC_URL_FILE", "%s", filename(ca));
        env = mysetenv(env, "SCRIPT_SRC_URL_DIR", "%s", dirname(ca));
    }
    else {
        env = mysetenv(env, "SCRIPT_SRC_URL", "file://%s", abspath(source));
        env = mysetenv(env, "SCRIPT_SRC_URL_FILE", "%s", filename(source));
        env = mysetenv(env, "SCRIPT_SRC_URL_DIR", "file://%s", abspath(source));
    }

    env = mysetenv(env, "SCRIPT_SRC_SIZE", "%d", nBuf);
    stat(source, &st);
    env = mysetenv(env, "SCRIPT_SRC_MODIFIED", "%d", st.st_mtime);
    cp = ctime(&(st.st_mtime));
    cp[strlen(cp)-1] = NUL;
    env = mysetenv(env, "SCRIPT_SRC_MODIFIED_CTIME", "%s", cp);
    env = mysetenv(env, "SCRIPT_SRC_MODIFIED_ISOTIME", "%s", isotime(&(st.st_mtime)));
    if ((pw = getpwuid(st.st_uid)) != NULL)
        env = mysetenv(env, "SCRIPT_SRC_OWNER", "%s", pw->pw_name);
    else
        env = mysetenv(env, "SCRIPT_SRC_OWNER", "unknown-uid-%d", st.st_uid);
    env = mysetenv(env, "VERSION_INTERPRETER", "%s", ePerl_WebID);
    env = mysetenv(env, "VERSION_LANGUAGE", "Perl/%s", AC_perl_vers);

    /* optionally run the ePerl preprocessor */
    if (fPP) {
        /* switch to directory where script stays */
        getcwd(cwd, MAXPATHLEN);
        strcpy(sourcedir, source);
        for (cp = sourcedir+strlen(sourcedir); cp > sourcedir && *cp != '/'; cp--)
            ;
        *cp = NUL;
        chdir(sourcedir);
        /* run the preprocessor */
        if ((cpBuf3 = ePerl_PP(cpScript, RememberedINC)) == NULL) {
            PrintError(mode, source, NULL, NULL, "Preprocessing failed for `%s': %s", source, ePerl_PP_GetError());
            CU(mode == MODE_FILTER ? EX_IOERR : EX_OK);
        }
        cpScript = cpBuf3;
        /* switch to previous dir */
        chdir(cwd);
    }

    /* convert bristled source to valid Perl code */
    if ((cpBuf2 = ePerl_Bristled2Plain(cpScript)) == NULL) {
        PrintError(mode, source, NULL, NULL, "Cannot convert bristled code file `%s' to pure HTML", source);
        CU(mode == MODE_FILTER ? EX_IOERR : EX_OK);
    }
    cpScript = cpBuf2;

    /* write buffer to temporary script file */
    strcpy(perlscript, mytmpfile("ePerl.script"));
#ifndef DEBUG_ENABLED
    unlink(perlscript);
#endif
    if ((fp = fopen(perlscript, "w")) == NULL) {
        PrintError(mode, source, NULL, NULL, "Cannot open Perl script file `%s' for writing", perlscript);
        CU(mode == MODE_FILTER ? EX_IOERR : EX_OK);
    }
    fwrite(cpScript, strlen(cpScript), 1, fp);
    fclose(fp); fp = NULL;

    /* in Debug mode output the script to the console */
    if (fDebug) {
        if ((fp = fopen("/dev/tty", "w")) == NULL) {
            PrintError(mode, source, NULL, NULL, "Cannot open /dev/tty for debugging message");
            CU(mode == MODE_FILTER ? EX_IOERR : EX_OK);
        }
        fprintf(fp, "----internally created Perl script-----------------------------------\n");
        fwrite(cpScript, strlen(cpScript)-1, 1, fp);
        if (cpScript[strlen(cpScript)-1] == '\n') 
            fprintf(fp, "%c", cpScript[strlen(cpScript)-1]);
        else 
            fprintf(fp, "%c\n", cpScript[strlen(cpScript)-1]);
        fprintf(fp, "----internally created Perl script-----------------------------------\n");
        fclose(fp); fp = NULL;
    }

    /* open a file for Perl's STDOUT channel
       and redirect stdout to the new channel */
    strcpy(perlstdout, mytmpfile("ePerl.stdout"));
#ifndef DEBUG_ENABLED
    unlink(perlstdout);
#endif
    if ((out = fopen(perlstdout, "w")) == NULL) {
        PrintError(mode, source, NULL, NULL, "Cannot open STDOUT file `%s' for writing", perlstdout);
        CU(mode == MODE_FILTER ? EX_IOERR : EX_OK);
    }
    IO_redirect_stdout(out);

    /* open a file for Perl's STDERR channel 
       and redirect stderr to the new channel */
    strcpy(perlstderr, mytmpfile("ePerl.stderr"));
#ifndef DEBUG_ENABLED
    unlink(perlstderr);
#endif
    if ((er = fopen(perlstderr, "w")) == NULL) {
        PrintError(mode, source, NULL, NULL, "Cannot open STDERR file `%s' for writing", perlstderr);
        CU(mode == MODE_FILTER ? EX_IOERR : EX_OK);
    }
    IO_redirect_stderr(er);

    /*  now allocate the Perl interpreter  */
    my_perl = perl_alloc();   
    perl_construct(my_perl); 
    /* perl_destruct_level = 1; */

    /*  initialise the Perl Locale environment  */
#if AC_perl_vnum < 500400
    perl_init_i18nl14n(1); /* Perl 5.003 or lower */
#else
    perl_init_i18nl10n(1); /* Perl 5.004 or higher */
#endif

    /*  create command line...  */
    myargc = 0;
    /*  - program name and possible -T -w options */
    myargv[myargc++] = progname;
    if (fTaint) 
        myargv[myargc++] = "-T";
    if (fWarn) 
        myargv[myargc++] = "-w";
    /*  - previously remembered Perl 5 INC entries (option -I) */
    for (i = 0; RememberedINC[i] != NULL; i++) {
        myargv[myargc++] = "-I";
        myargv[myargc++] = RememberedINC[i];
    }
    /*  - and the script itself  */
    myargv[myargc++] = perlscript;   

    /*  now parse the script! 
        NOTICE: At this point, the script gets 
        only _parsed_, not evaluated/executed!  */
#ifdef HAVE_PERL_DYNALOADER
    rc = perl_parse(my_perl, Perl5_XSInit, myargc, myargv, env);
#else
    rc = perl_parse(my_perl, NULL, myargc, myargv, env);
#endif
    if (rc != 0) { 
        if (fCheck && mode == MODE_FILTER) {
            fclose(er); er = NULL;
            IO_restore_stdout();
            IO_restore_stderr();
            if ((cpBuf = ePerl_ReadErrorFile(perlstderr, perlscript, source)) != NULL) {
                fprintf(stderr, cpBuf);
            }
            CU(EX_IOERR);
        }
        else {
            fclose(er); er = NULL;
            PrintError(mode, source, perlscript, perlstderr, "Perl parsing error (interpreter rc=%d)", rc);
            CU(mode == MODE_FILTER ? EX_IOERR : EX_OK);
        }
    }

    /* Stop when we are just doing a syntax check */
    if (fCheck && mode == MODE_FILTER) {
        fclose(er); er = NULL;
        IO_restore_stdout();
        IO_restore_stderr();
        fprintf(stderr, "%s syntax OK\n", source);
        CU(EX_OK);
    }

    /* change to directory of script:
       this actually is not important to us, but really useful 
       for the ePerl source file programmer!! */
    cwd[0] = NUL;
    if (!keepcwd) {
        /* if running as a Unix filter remember the cwd for outputfile */
        if (mode == MODE_FILTER)
            getcwd(cwd, MAXPATHLEN);
        /* determine dir of source file and switch to it */
        strcpy(sourcedir, source);
        for (cp = sourcedir+strlen(sourcedir); cp > sourcedir && *cp != '/'; cp--)
            ;
        *cp = NUL;
        chdir(sourcedir);
    }

    /*  Set the previously remembered Perl 5 scalars (option -d) */
    Perl5_SetRememberedScalars();

    /*  Force unbuffered I/O */
    Perl5_ForceUnbufferedStdout();

    /*  NOW IT IS TIME to evaluate/execute the script!!! */
    rc = perl_run(my_perl);

    /*  pre-close the handles, to be able to check
        its size and to be able to display the contents */
    fclose(out); out = NULL;
    fclose(er);  er  = NULL;

    /*  when the Perl interpreter failed or there
        is data on stderr, we print a error page */
    if (stat(perlstderr, &st) == 0)
        size = st.st_size;
    else
        size = 0;
    if (rc != 0 || size > 0) {
        PrintError(mode, source, perlscript, perlstderr, "Perl runtime error (interpreter rc=%d)", rc);
        CU(mode == MODE_FILTER ? EX_IOERR : EX_OK);
    }

    /*  else all processing was fine, so
        we read in the stdout contents */
    if ((cpOut = ePerl_ReadSourceFile(perlstdout, &cpOut, &nOut)) == NULL) {
        PrintError(mode, source, NULL, NULL, "Cannot open STDOUT file `%s' for reading", perlstdout);
        CU(mode == MODE_FILTER ? EX_IOERR : EX_OK);
    }
    stat(perlstdout, &st);

    /* ok, now recover the stdout and stderr and
       print out the real contents on stdout or outputfile */
    IO_restore_stdout();
    IO_restore_stderr();

    /*  if we are running as a NPH-CGI/1.1 script
        we had to provide the HTTP reponse headers ourself */
    if (mode == MODE_NPHCGI) {
        HTTP_PrintResponseHeaders(cpOut);

        /* if there are no HTTP header lines, we print a basic
           Content-Type header which should be ok */
        if (!HTTP_HeadersExists(cpOut)) {
            printf("Content-Type: text/html\n");
            printf("Content-Length: %d\n", nOut);
            printf("\n");
        }
    }
    else if (mode == MODE_CGI) {
        HTTP_StripResponseHeaders(&cpOut, &nOut);

        /* if there are no HTTP header lines, we print a basic
           Content-Type header which should be ok */
        if (!HTTP_HeadersExists(cpOut)) {
            printf("Content-Type: text/html\n");
            printf("Content-Length: %d\n", nOut);
            printf("\n");
        }
    }
    else if (mode == MODE_FILTER) {
        HTTP_StripResponseHeaders(&cpOut, &nOut);
    }

    /* now when the request was not a HEAD request we create the output */
    cp = getenv("REQUEST_METHOD");
    if (! ((mode == MODE_CGI || mode == MODE_NPHCGI) &&
           cp != NULL && strcmp(cp, "HEAD") == 0)) {
        if (outputfile != NULL && strcmp(outputfile, "-") != 0) {
            /* if we remembered current working dir, restore it now */
            if (mode == MODE_FILTER && cwd[0] != NUL)
                chdir(cwd);
            /* open outputfile and write out the data */
            if ((fp = fopen(outputfile, "w")) == NULL) {
                PrintError(mode, source, NULL, NULL, "Cannot open output file `%s' for writing", outputfile);
                CU(mode == MODE_FILTER ? EX_IOERR : EX_OK);
            }
            fwrite(cpOut, nOut, 1, fp);
            fclose(fp); fp = NULL;
        }
        else {
            /* data just goes to stdout */
            fwrite(cpOut, nOut, 1, stdout);
            /* make sure that the data is out before we exit */
            fflush(stdout);
        }
    }

    CUS: /* the Clean Up Sequence */

    /* Ok, the script got evaluated. Now we can destroy 
       and de-allocate the Perl interpreter */
    if (my_perl) {
       perl_destruct(my_perl);                                                    
       perl_free(my_perl);
    }

    /* close all still open file handles */
    if (out)
        fclose(out);
    if (er)
        fclose(er);
    if (fp)
        fclose(fp);

    /* de-allocate the script buffer */
    if (cpBuf)
        free(cpBuf);
    if (cpBuf2)
        free(cpBuf2);
    if (cpOut)
        free(cpOut);

    /* remove temporary files */
#ifndef DEBUG_ENABLED
    if (*perlstderr != NUL)
        unlink(perlstderr);
    if (*perlstdout != NUL)
        unlink(perlstdout);
    if (*perlscript != NUL)
        unlink(perlscript);
#endif

    myexit(EXRC);
    return EXRC; /* make -Wall happy ;-) */
}

/*EOF*/
