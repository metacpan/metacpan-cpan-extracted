/* zxidwspcgi.c  -  WSP CGI shell script connector
 * Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidhrxmlwsp.c,v 1.14 2009-11-29 12:23:06 sampo Exp $
 *
 * 9.2.2010, created --Sampo
 *
 * See also: http://hoohoo.ncsa.uiuc.edu/cgi/interface.html (CGI specification)
 *           mini_httpd_filter.c
 */

#include <zx/platform.h>

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>

#include <zx/errmac.h>
#include <zx/zxid.h>      /* ZXID main API, including zxid_simple(). */
#include <zx/zxidutil.h>
#include <zx/zxidconf.h>  /* Default and compile-time configuration options. */
#include <zx/c/zxidvers.h>

#define CONF "PATH=/var/zxid/"

char* help =
"zxidwspcgi  -  ID-WSF 2.0 WSP CGI - R" ZXID_REL "\n\
SAML 2.0 and ID-WSF 2.0 are standards for federated identity and web services.\n\
Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.\n\
NO WARRANTY, not even implied warranties. Licensed under Apache License v2.0\n\
See http://www.apache.org/licenses/LICENSE-2.0\n\
Send well-researched bug reports to the author. Home: zxid.org\n\
\n\
Usage: zxidwspcgi [options]   (when used as CGI, no options can be supplied)\n\
  -h               This help message\n\
  --               End of options\n\
\n\
Built-in configuration: " CONF "\n\
\n\
This C program implements a generic Web Services Provider. It is meant\n\
to be run as a cgi script from a web server. It will validate\n\
an incoming web service request and then pass it to sysadmin-supplied\n\
external program on stdin. The external program could be a shell script or\n\
a perl program - whatever you want. The external program reads the payload\n\
request from stdin and prints the payload response to stdout. zxidwspcgi\n\
handles the pipe-in - pipe-out deadlock dilemma by forking a process to\n\
perform the feeding in, while the original process will receive the\n\
stdout of the subprocess. Once entire payload response has been received,\n\
the response will be decorated with ID-WSF headers and sent as response\n\
to the original caller.\n";

char buf[256*1024];  /* *** should figure the size dynamically */
int child_in_fds[2];   /* Parent out */
int child_out_fds[2];  /* Parent in */

/*() Send data to script using child process */

/* Called by:  zxidwspcgi_main */
static int zxidwspcgi_child(zxid_conf* cf, int len, char* buf, char* sid, char* nid)
{
  int status;
  pid_t pid;
  close(0);
  close(1);
  if (pid = fork()) {  /* Parent pumps child's input */
    close(child_out_fds[0]);
    close(child_out_fds[1]);
    close(child_in_fds[0]);
    D("Writing %d bytes to child pid=%d", len, pid);
    write_all_fd(child_in_fds[1], buf, len);
    D("Waiting for child pid=%d", pid);
    if (waitpid(pid, &status, 0) == -1) {
      perror("waitpid");
    }
    return status;
  } else {
    close(child_out_fds[0]);
    close(child_in_fds[1]);
    if (dup(child_in_fds[0]) != 0) {
      perror("dup stdin");
      return 1;
    }
    if (dup(child_out_fds[1]) != 1) {
      perror("dup stdout");
      return 1;
    }
    setenv("idpnid", nid, 1);
    setenv("sid", sid, 1);
    D("exec(%s)", cf->wspcgicmd);
    execl(cf->wspcgicmd, cf->wspcgicmd);     /* At least gcc-3.4.6 gives bogus "warning: not enough variable arguments to fit a sentinel [-Wformat]" on this line. AFAIK you can safely ignore the warning. --Sampo */
    perror("exec");
    ERR("Exec(%s) failed: errno=%d", cf->wspcgicmd, errno);
    return 1;
  }
  return 0;
}

/*() Read from script using parent, and send resp. */

/* Called by:  zxidwspcgi_main */
static int zxidwspcgi_parent(zxid_conf* cf, zxid_ses* ses, int pid)
{
  struct zx_str* ss;
  int got_all;
  if (pid == -1) {
    perror("first fork");
    return 1;
  }
  close(child_out_fds[1]);
  close(child_in_fds[0]);
  close(child_in_fds[1]);
  D("Reading from child writer_pid=%d", pid);
  read_all_fd(child_out_fds[0], buf, sizeof(buf)-1, &got_all);
  buf[got_all] = 0;
  D("Got from child %d bytes", got_all);
  ss = zxid_wsp_decorate(cf, ses, 0, buf);
  fprintf(stdout, "CONTENT-TYPE: text/xml\r\nCONTENT-LENGTH: %d\r\n\r\n%.*s", ss->len, ss->len, ss->s);
  fflush(stdout);
  if (waitpid(pid, &got_all, 0) == -1) {
    perror("waitpid");
  }
  return 0;
}

/* ============== M A I N ============== */

#ifndef zxidwspcgi_main
#define zxidwspcgi_main main
#endif

/* Called by: */
int zxidwspcgi_main(int argc, char** argv)
{
  zxid_conf* cf;
  zxid_ses sess;
  zxid_ses* ses = &sess;
  char* nid;
  char* p;
  char* res;
  char urlbuf[256];
  int got, cl=0;
  char* qs;
  char* qs2;
  pid_t pid;
  ZERO(ses, sizeof(zxid_ses));

#if 1
  /* Helps debugging CGI scripts if you see stderr. */
  /* Reopen stderr only in mini_httpd case */
  p = getenv("SERVER_SOFTWARE");
  if (p && !memcmp(p, "mini_httpd", sizeof("mini_httpd")-1)) {
    close(2);
    if (open("/var/tmp/zxidwspcgi.stderr", O_WRONLY | O_CREAT | O_APPEND, 0666) != 2)
      exit(2);
  }
  fprintf(stderr, "=================== Running zxidwspcgi %s ===================\n", ZXID_REL);
  errmac_debug = 1;
#endif

  qs = getenv("CONTENT_LENGTH");
  if (qs)
    sscanf(qs, "%d", &cl);

  if (cl) {
    read_all_fd(fdstdin, buf, MIN(cl, sizeof(buf)-1), &got);
    buf[got] = 0;
    qs2 = buf;
  } else {
    qs2 = getenv("QUERY_STRING");
    if (!qs2)
      qs2 = "";
    cl = strlen(qs2);
  }
  qs = strdup(qs2);
  D("qs(%s)", qs);

  if (argc > 1) {
    fprintf(stderr, "This is a CGI script (written in C). No arguments are accepted.\n%s", help);
    return 1;
  }

  cf = zxid_new_conf_to_cf(CONF);

  /* Dynamic construction of URL configuration parameter */

#if 0  
#define PROTO_STR "https://"
#else
#define PROTO_STR "http://"
#endif

#if 1
  /* Is this virtual hosting section still needed given that VHOST and VURL are
   * supported directly by the configuration syntax? *** */
  strcpy(urlbuf, PROTO_STR);
  p = urlbuf + sizeof(PROTO_STR)-1;
  res = getenv("HTTP_HOST");
  if (res) {
    strcpy(p, res);
    p+=strlen(res);
  }
  res = getenv("SCRIPT_NAME");
  if (res) {
    strcpy(p, res);
    p+=strlen(res);
  }
  if (p > urlbuf + sizeof(urlbuf))
    exit(1);
  zxid_url_set(cf, urlbuf);
#endif

  //if (!memcmp(qs+cl-4, "?o=B", 4)) {
  if (qs[0] == 'o' && qs[1] == '=' && ONE_OF_2(qs[2], 'B', 'd')) {
    D("Metadata qs(%s)", qs);
    //cf = zxid_new_conf_to_cf(CONF);
    
    res = zxid_simple_cf(cf, cl, qs, 0, 0x1fff);
    switch (res[0]) {
    default:
      ERR("Unknown zxid_simple() response(%s)", res);
    case 'd': break; /* Logged in case */
    }
    ERR("Not a metadata qs(%s)",qs);
    return 1;
  }

  nid = zxid_wsp_validate(cf, ses, 0, buf);
  if (!nid) {
    ERR("Request validation failed buf(%.*s)", got, buf);
    return 1;
  }
  D("target nid(%s)", nid);

  if (pipe(child_in_fds) == -1) {
    perror("pipe");
    return 1;
  }
  if (pipe(child_out_fds) == -1) {
    perror("pipe");
    return 1;
  }
  if (pid = fork())
    return zxidwspcgi_parent(cf, ses, pid); /* Read from script using parent, and send resp. */
  else
    return zxidwspcgi_child(cf, got, buf, ses->sid, nid);  /* Send data to script using child process */
}

/* EOF  --  zxidwspcgi.c */
