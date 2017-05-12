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
**  eperl_proto.h -- ePerl ANSI C prototypes
*/
#ifndef EPERL_PROTO_H
#define EPERL_PROTO_H 1

/*_BEGIN_PROTO_*/

/* eperl_main.c */
extern int mode;
extern char *allowed_file_ext[];
extern char *allowed_caller_uid[];
extern void PrintError(int mode, char *scripturl, char *scriptfile, char *logfile, char *str, ...);
extern void give_version(void);
extern void give_version_extended(void);
extern void give_readme(void);
extern void give_license(void);
extern void give_img_logo(void);
extern void give_img_powered(void);
extern void give_usage(char *name);
extern char *RememberedINC[1024];
extern void RememberINC(char *str);
extern void mysighandler(int rc);
extern void myinit(void);
extern void myexit(int rc);
extern struct option options[];
extern int main(int argc, char **argv, char **env);

/* eperl_perl5.c */
extern void Perl5_XSInit(void);
extern void Perl5_ForceUnbufferedStdout(void);
extern char **Perl5_SetEnvVar(char **env, char *str);
extern void Perl5_SetScalar(char *pname, char *vname, char *vvalue);
extern char *Perl5_RememberedScalars[1024];
extern void Perl5_RememberScalar(char *str);
extern void Perl5_SetRememberedScalars(void);

/* eperl_parse.c */
extern char *ePerl_begin_delimiter;
extern char *ePerl_end_delimiter;
extern int ePerl_case_sensitive_delimiters;
extern int ePerl_convert_entities;
extern int ePerl_line_continuation;
extern void ePerl_SetError(char *str, ...);
extern char *ePerl_GetError(void);
extern char *ePerl_fprintf(char *cpOut, char *str, ...);
extern char *ePerl_fwrite(char *cpBuf, int nBuf, int cNum, char *cpOut);
extern char *ePerl_Efwrite(char *cpBuf, int nBuf, int cNum, char *cpOut);
extern char *ePerl_Cfwrite(char *cpBuf, int nBuf, int cNum, char *cpOut);
extern char *strnchr(char *buf, char chr, int n);
extern char *strnstr(char *buf, char *str, int n);
extern char *strncasestr(char *buf, char *str, int n);
extern char *strndup(char *buf, int n);
extern char *ePerl_Bristled2Plain(char *cpBuf);

/* eperl_pp.c */
extern void ePerl_PP_SetError(char *str, ...);
extern char *ePerl_PP_GetError(void);
extern char *ePerl_PP_Process(char *cpInput, char **cppINC, int mode);
extern char *ePerl_PP(char *cpBuf, char **cppINC);

/* eperl_sys.c */
extern char **mysetenv(char **env, char *var, char *str, ...);
extern void IO_redirect_stdin(FILE *fp);
extern void IO_redirect_stdout(FILE *fp);
extern void IO_redirect_stderr(FILE *fp);
extern int IO_is_stdin_redirected(void);
extern int IO_is_stdout_redirected(void);
extern int IO_is_stderr_redirected(void);
extern void IO_restore_stdin(void);
extern void IO_restore_stdout(void);
extern void IO_restore_stderr(void);
extern char *mytmpfile(char *id);
extern void remove_mytmpfiles(void);
extern char *isotime(time_t *t);
extern char *ePerl_ReadSourceFile(char *filename, char **cpBufC, int *nBufC);
extern char *ePerl_ReadErrorFile(char *filename, char *scriptfile, char *scripturl);
extern char *filename(char *path);
extern char *dirname(char *path);
extern char *abspath(char *path);

/* eperl_http.c */
extern void HTTP_PrintResponseHeaders(char *cpBuf);
extern void HTTP_StripResponseHeaders(char **cpBuf, int *nBuf);
extern int HTTP_IsHeaderLine(char *cp1, char *cp2);
extern int HTTP_HeadersExists(char *cpBuf);
extern int HTTP_HeaderLineExists(char *cpBuf, char *name);
extern char *WebTime(void);
extern FILE *HTTP_openURLasFP(char *url);

/* eperl_debug.c */
extern int fDebug;
extern char *cpDebugFile;
extern void Debug(char *str, ...);

/* eperl_config.c */

/* eperl_version.c */
extern char ePerl_Version[];
extern char ePerl_Hello[];
extern char ePerl_GNUVersion[];
extern char ePerl_WhatID[];
extern char ePerl_RCSIdentID[];
extern char ePerl_WebID[];
extern char ePerl_PlainID[];

/* eperl_readme.c */
extern char *ePerl_README;

/* eperl_license.c */
extern char *ePerl_LICENSE;

/* eperl_logo.c */
extern int ePerl_LOGO_size;
extern char ePerl_LOGO_data[];

/* eperl_powered.c */
extern int ePerl_POWERED_size;
extern char ePerl_POWERED_data[];
/*_END_PROTO_*/

#endif /* EPERL_PROTO_H */
/*EOF*/
