/* zxid.c  -  CGI binary for SAML 2 SP
 * Copyright (c) 2006 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxid.c,v 1.42 2009-11-24 23:53:40 sampo Exp $
 *
 * 15.4.2006, started work over Easter holiday --Sampo
 * 22.4.2006, added more options over the weekend --Sampo
 * 28.5.2006, adopted structure from s5066d --Sampo
 * 30.9.2006, added signature verification --Sampo
 *
 * This file contains option processing, configuration, and main().
 *
 * See also: http://hoohoo.ncsa.uiuc.edu/cgi/interface.html (CGI specification)
 *
 * WARNING: This file is outdated. See zxidhlo.c instead.
 */

#include "platform.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
//#include <sys/wait.h>
//#include <pthread.h>
#include <signal.h>
#include <fcntl.h>
//#include <netdb.h>

#ifdef USE_CURL
#include <curl/curl.h>
#endif

#include <zx/errmac.h>
#include <zx/zx.h>
#include <zx/zxid.h>
#include <zx/zxidpriv.h>
#include <zx/zxidutil.h>
#include <zx/zxidconf.h>
#include <zx/c/zxidvers.h>
#include <zx/c/zx-ns.h>
#include <zx/c/zx-md-data.h>

char* help =
"zxid  -  SAML 2.0 SP CGI - R" ZXID_REL "\n\
SAML 2.0 is a standard for federated identity and Single Sign-On.\n\
Copyright (c) 2006 Symlabs (symlabs@symlabs.com), All Rights Reserved.\n\
Author: Sampo Kellomaki (sampo@iki.fi)\n\
NO WARRANTY, not even implied warranties. Licensed under Apache License v2.0\n\
See http://www.apache.org/licenses/LICENSE-2.0\n\
Send well researched bug reports to the author. Home: zxid.org\n\
\n\
Usage: zxid [options]   (when used as CGI, no options can be supplied)\n\
  -meta            Dump our own metadata to stdout.\n\
  -import URL      Import metadata of others from URL, usually their Entity ID\n\
                   or Provider ID, aka well known location. The imported metadata\n\
                   is written to CoT cache directory.\n\
  -fileimport FILE Import metadata of others from file.\n\
  -C CONFPATH      Path to (optional) config file, default " ZXID_CONF_PATH "\n\
  -c OPT=VAL       Override default or config file option. Only after -C, if any.\n\
  -t SECONDS       Timeout. Default: 0=no timeout.\n\
  -k FDNUMBER      File descriptor for reading symmetric key. Use 0 for stdin.\n\
  -egd PATH        Specify path of Entropy Gathering Daemon socket, default on\n\
                   Solaris: /tmp/entropy. On Linux /dev/urandom is used instead\n\
                   See http://www.lothar.com/tech/crypto/ or\n\
                   http://www.aet.tu-cottbus.de/personen/jaenicke/postfix_tls/prngd.html\n\
  -rand PATH       Location of random number seed file. On Solaris EGD is used.\n\
                   On Linux the default is /dev/urandom. See RFC1750.\n\
  -uid UID:GID     If run as root, drop privileges and assume specified uid and gid.\n\
  -v               Verbose messages.\n\
  -q               Be extra quiet.\n\
  -d               Turn on debugging.\n\
  -license         Show licensing details, including NATO C3 Agency disclaimer.\n\
  -h               This help message\n\
  --               End of options\n";

int ak_buf_size = 0;
int verbose = 1;
int timeout = 0;
int gcthreshold = 0;
int leak_free = 0;
int drop_uid = 0;
int drop_gid = 0;
char* rand_path;
char* egd_path;
char  symmetric_key[1024];
int symmetric_key_len;
char buf[32*1024];

/* N.B. This options processing is a skeleton. In reality CGI scripts do not have
 * an opportunity to process any options. */

/* Called by:  main x8, zxbusd_main, zxbuslist_main, zxbustailf_main, zxcall_main, zxcot_main, zxdecode_main */
void opt(int* argc, char*** argv, char*** env, zxid_conf* cf, zxid_cgi* cgi)
{
  char* conf_path = 0;
  if (*argc <= 1) return;
  
  while (1) {
    ++(*argv); --(*argc);
    
    if (!(*argc) || ((*argv)[0][0] != '-')) break;  /* normal exit from options loop */
    
    switch ((*argv)[0][1]) {
    case '-': if ((*argv)[0][2]) break;
      ++(*argv); --(*argc);
      DD("End of options by --");
      return;  /* -- ends the options */

    case 'C': if ((*argv)[0][2]) break;
      ++(*argv); --(*argc);
      if (!(*argc)) break;
      conf_path = **argv;
      continue;

    case 'c': if ((*argv)[0][2]) break;
      ++(*argv); --(*argc);
      if (!(*argc)) break;
      if (conf_path != (char*)1) {
	if (conf_path)
	  read_all(sizeof(buf), buf, "new conf path in opt", 1, "%s", conf_path);
	else
	  read_all(sizeof(buf), buf, "no conf path in opt", 1, "%s" ZXID_CONF_FILE, cf->cpath);
	zxid_parse_conf(cf, buf);
	conf_path = (char*)1;
      }
      zxid_parse_conf(cf, **argv);
      continue;

    case 'd':
      switch ((*argv)[0][2]) {
      case '\0':
	++errmac_debug;
	continue;
      case 'i':  if ((*argv)[0][3]) break;
	++(*argv); --(*argc);
	if (!(*argc)) break;
	strcpy(errmac_instance, (*argv)[0]);
	continue;
      }
      break;

    case 'e':
      switch ((*argv)[0][2]) {
      case 'g': if ((*argv)[0][3] != 'd' || (*argv)[0][4]) break;
	++(*argv); --(*argc);
	if (!(*argc)) break;
	egd_path = (*argv)[0];
	continue;
      }
      break;
      
    case 'i':
      switch ((*argv)[0][2]) {
      case 'm':
	if (!strcmp((*argv)[0],"-import")) {
	  zxid_entity* ent;
	  ++(*argv); --(*argc);
	  if (!(*argc)) break;
	  cf->ctx->ns_tab = zx_ns_tab;
	  ent = zxid_get_meta(cf, (*argv)[0]);
	  if (ent)
	    zxid_write_ent_to_cache(cf, ent);
	  exit(0);
	}
	break;
      }
      break;
#if 0
    case 'f':
      switch ((*argv)[0][2]) {
      case 'i':
	if (!strcmp((*argv)[0],"-fileimport")) {
	  zxid_entity* ent;
	  ++(*argv); --(*argc);
	  if (!(*argc)) break;
	  cf->ctx->ns_tab = zx_ns_tab;
	  ent = zxid_get_meta(cf, (*argv)[0]);
	  if (ent)
	    zxid_write_ent_to_cache(cf, ent);
	  exit(0);
	}
	break;
      }
      break;
#endif
#ifndef MINGW
    case 'k':
      switch ((*argv)[0][2]) {
      case '\0':
	++(*argv); --(*argc);
	if (!(*argc)) break;
	read_all_fd((fdtype)atoi((*argv)[0]), symmetric_key, sizeof(symmetric_key), &symmetric_key_len);
	D("Got %d characters of symmetric key", symmetric_key_len);
	continue;
      }
      break;
#endif

    case 'l':
      switch ((*argv)[0][2]) {
      case 'i':
	if (!strcmp((*argv)[0],"-license")) {
	  extern char* license;
	  fprintf(stderr, "%s", license);
	  exit(0);
	}
	break;
      }
      break;

    case 'm':
      switch ((*argv)[0][2]) {
      case 'e':
	if (!strcmp((*argv)[0],"-meta")) {
	  cf->ctx->ns_tab = zx_ns_tab;
	  zxid_send_sp_meta(cf, cgi);
	  exit(0);
	}
	break;
      }
      break;

    case 'q':
      switch ((*argv)[0][2]) {
      case '\0':
	verbose = 0;
	continue;
      }
      break;

    case 'r':
      switch ((*argv)[0][2]) {
      case 'f':
	/*AK_TS(LEAK, 0, "memory leaks enabled");*/
	ERR("*** WARNING: You have turned memory frees to memory leaks. We will (eventually) run out of memory. Using -rf is not recommended. %d\n", 0);
	++leak_free;
	continue;
#if 0
      case 'e':  /* -re */
	if ((*argv)[0][3]) break;
	++(*argv); --(*argc);
	if ((*argc) < 4) break;
	sscanf((*argv)[0], "%i", &abort_funcno);
	++(*argv); --(*argc);
	sscanf((*argv)[0], "%i", &abort_line);
	++(*argv); --(*argc);
	sscanf((*argv)[0], "%i", &abort_error_code);
	++(*argv); --(*argc);
	sscanf((*argv)[0], "%i", &abort_iter);
	fprintf(stderr, "Will force core upon %x:%x err=%d iter=%d\n",
		abort_funcno, abort_line, abort_error_code, abort_iter);
	continue;
#endif
      case 'g':  /* -rg */
	if ((*argv)[0][3]) break;
	++(*argv); --(*argc);
	if (!(*argc)) break;
	gcthreshold = atoi((*argv)[0]);
	if (!gcthreshold)
	  ERR("*** WARNING: You have disabled garbage collection. This may lead to increased memory consumption for scripts that handle a lot of PDUs or run for long time. Using `-rg 0' is not recommended. %d\n", 0);
	continue;
      case 'a': /* -ra */
	if ((*argv)[0][3] == 0) {
	  /*AK_TS(ASSERT_NONFATAL, 0, "assert nonfatal enabled");*/
#if 1
	  ERR("*** WARNING: YOU HAVE TURNED ASSERTS OFF USING -ra FLAG. THIS MEANS THAT YOU WILL NOT BE ABLE TO OBTAIN ANY SUPPORT. IF PROGRAM NOW TRIES TO ASSERT IT MAY MYSTERIOUSLY AND UNPREDICTABLY CRASH INSTEAD, AND NOBODY WILL BE ABLE TO FIGURE OUT WHAT WENT WRONG OR HOW MUCH DAMAGE MAY BE DONE. USING -ra IS NOT RECOMMENDED. %d\n", assert_nonfatal);
#endif
	  ++assert_nonfatal;
	  continue;
	}
	if (!strcmp((*argv)[0],"-rand")) {
	  ++(*argv); --(*argc);
	  if (!(*argc)) break;
	  rand_path = (*argv)[0];
	  continue;
	}
	break;
      }
      break;

    case 't': if ((*argv)[0][2]) break;
      ++(*argv); --(*argc);
      if (!(*argc)) break;
      timeout = atoi((*argv)[0]);
      continue;

    case 'u':
      switch ((*argv)[0][2]) {
      case 'i': if ((*argv)[0][3] != 'd' || (*argv)[0][4]) break;
	++(*argv); --(*argc);
	if (!(*argc)) break;
	sscanf((*argv)[0], "%i:%i", &drop_uid, &drop_gid);
	continue;
      }
      break;

    case 'v':
      switch ((*argv)[0][2]) {
      case '\0':
	++verbose;
	continue;
      }
      break;

    } 
    /* fall thru means unrecognized flag */
    if (*argc)
      fprintf(stderr, "Unrecognized flag `%s'\n", (*argv)[0]);
    fprintf(stderr, "%s", help);
    fprintf(stderr, "version=0x%06x rel(%s)\n", zxid_version(), zxid_version_str());
    exit(3);
  }
  if (conf_path != (char*)1) {
    if (conf_path)
      read_all(sizeof(buf), buf, "conf_path in end of opt", 1, "%s", conf_path);
    else
      read_all(sizeof(buf), buf, "no conf_path in end of opt", 1, "%szxid.conf", cf->cpath);
    zxid_parse_conf(cf, buf);
  }
}

/* ============== Management Screen ============== */

/* This screen is only invoked if session is active. Zero return
 * value causes the login screen to be rendered. */

/* Called by:  main x7 */
int zxid_mgmt(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses)
{
  struct zx_str* ss;
  D("op(%c)", cgi->op);
  switch (cgi->op) {
  case 'l':
    zxid_del_ses(cf, ses);
    cgi->msg = "Local logout Ok. Session terminated.";
    return 0;  /* Simply abandon local session. Falls thru to login screen. */
  case 'r':
    ss = zxid_sp_slo_redir(cf, cgi, ses);
    zxid_del_ses(cf, ses);
    printf("%.*s", ss->len, ss->s);
    zx_str_free(cf->ctx, ss);
    fflush(stdout);
    return 1;  /* Redirect already happened. Do not show login screen. */
  case 's':
    zxid_sp_slo_soap(cf, cgi, ses);
    zxid_del_ses(cf, ses);
    cgi->msg = "SP Initiated logout (SOAP). Session terminated.";
    return 0;  /* Falls thru to login screen. */
  case 't':
    ss = zxid_sp_mni_redir(cf, cgi, ses, 0);
    printf("%.*s", ss->len, ss->s);
    zx_str_free(cf->ctx, ss);
    fflush(stdout);
    return 1;  /* Redirect already happened. Do not show login screen. */
  case 'u':
    zxid_sp_mni_soap(cf, cgi, ses, 0);
    cgi->msg = "SP Initiated defederation (SOAP).";
    break;     /* Defederation does not have to mean SLO */
  case 'P':
  case 'Q':
    ss = zxid_sp_dispatch(cf, cgi, ses);
    switch (ss->s[0]) {
    case 'K': return 0;
    case 'L':
      printf("%.*s", ss->len, ss->s);
      zx_str_free(cf->ctx, ss);
      fflush(stdout);
      return 1;
    }
    break;
  }

  //printf("COOKIE: foo\r\n");
  printf("Content-Type: text/html\r\n\r\n");
  printf("<title>ZXID SP Mgmt</title>" ZXID_BODY_TAG "<h1>ZXID SP Management (user logged in, session active)</h1><pre>\n");
  //if (qs) printf("QS(%s)\n", qs);
  //if (got>0) printf("GOT(%.*s)\n", got, buf);
  printf("</pre><form method=post action=\"zxid?o=P\">");
  if (cgi->err)
    printf("<p><font color=red><i>%s</i></font></p>\n", cgi->err);
  if (cgi->msg)
    printf("<p><i>%s</i></p>\n", cgi->msg);
  //printf("User:<input name=user> PW:<input name=pw type=password>");
  //printf("<input name=login value=\" Login \" type=submit>");
  printf("<input type=hidden name=s value=\"%s\">", ses->sid);
  printf("<input type=submit name=gl value=\" Local Logout \">\n");
  printf("<input type=submit name=gr value=\" Single Logout (Redir) \">\n");
  printf("<input type=submit name=gs value=\" Single Logout (SOAP) \">\n");
  printf("<input type=submit name=gt value=\" Defederate (Redir) \">\n");
  printf("<input type=submit name=gu value=\" Defederate (SOAP) \">\n");

  printf("<h3>Technical options (typically hidden fields on production site)</h3>\n");
  
  printf("sid(%s) nid(%s) <a href=\"zxid?s=%s\">Reload</a>", ses->sid, ses->nid, ses->sid);

  printf("</form><hr>");
  printf("<a href=\"http://zxid.org/\">zxid.org</a>, %s", zxid_version_str());
  if (cgi->dbg)
    printf("<p><form><textarea cols=100 row=10>%s</textarea></form>\n", cgi->dbg);
  return 1;
}

/* ============== M A I N ============== */

/* Called by: */
int main(int argc, char** argv, char** env)
{
  zxid_conf* cf = zxid_new_conf(ZXID_PATH);
  zxid_ses ses;
  zxid_cgi cgi;
  int got;
  char* qs;
  char* cont_len;
  struct zx_str* ss;
  char* eid;
  zxid_entity* idp;
  
#if 1
  /* Helps debugging CGI scripts if you see stderr. */
  close(2);
  got = open("zxid.stderr", O_WRONLY | O_CREAT | O_APPEND, 0666);
  if (got != 2)
    exit(2);
  fprintf(stderr, "=================== Running ===================\n");
  ++errmac_debug;
  zxid_set_opt(cf, 6, 0);
#endif
  cf->nosig_fatal = 0;  // *** For SimpleSign the signature is checked at other level

  opt(&argc, &argv, &env, cf, &cgi);

  /*if (stats_prefix) init_cmdline(argc, argv, env, stats_prefix);*/
  CMDLINE("init");
  
#ifndef MINGW  
  /* *** all this cruft does not work on MINGW, but perhaps it should not even exist for Unix */
  if (signal(SIGPIPE, SIG_IGN) == SIG_ERR) {   /* Ignore SIGPIPE */
    perror("Init: signal ignore pipe");
    exit(2);
  }

  /* Cause exit(3) to be called with the intent that any gcov profiling will get
   * written to disk before we die. If not stopped with `kill -USR1' but you
   * use plain kill instead, the profile will indicate many unexecuted (#####) lines. */
  if (signal(SIGUSR1, exit) == SIG_ERR) {
    perror("Init: signal USR1 exit");
    exit(2);
  }
  
  /* Drop privileges, if requested. */
  
  if (drop_gid) if (setgid(drop_gid)) { perror("Init: setgid"); exit(1); }
  if (drop_uid) if (setuid(drop_uid)) { perror("Init: setuid"); exit(1); }
#endif

  /* Pick up application variables from query string and post content (indicated by o=P in QS) */
  
  ZERO(&cgi, sizeof(cgi));
  qs = getenv("QUERY_STRING");
  if (qs) {
    D("QS(%s)", qs);
    zxid_parse_cgi(cf, &cgi, qs);
    if (cgi.op == 'P') {
      cont_len = getenv("CONTENT_LENGTH");
      if (cont_len) {
	sscanf(cont_len, "%d", &got);
	if (read_all_fd(fdstdin, buf, got, &got) == -1) {
	  perror("Trouble reading post content");
	} else {
	  buf[got] = 0;
	  D("POST(%s) got=%d cont_len(%s)", buf, got, cont_len);
	  if (buf[0] == '<') {  /* No BOM and looks XML */
	    return zxid_sp_soap_parse(cf, &cgi, &ses, got, buf);
	  }
	  if (buf[2] == '<') {  /* UTF-16 BOM and looks XML */
	    return zxid_sp_soap_parse(cf, &cgi, &ses, got-2, buf+2);
	  }
	  if (buf[3] == '<') {  /* UTF-8 BOM and looks XML */
	    return zxid_sp_soap_parse(cf, &cgi, &ses, got-3, buf+3);
	  }
	  zxid_parse_cgi(cf, &cgi, buf);
	}
      }
    }
  } else
    cgi.op = 'M';  /* Bare `/zxid' as a URL means same as `/zxid?o=M' */
  
  D("op(%c) sid(%s)", cgi.op, cgi.sid?cgi.sid:"-");

  /* Check if user already has working session. */
  
  if (cgi.sid) {
    if (zxid_get_ses(cf, &ses, cgi.sid))
      if (zxid_mgmt(cf, &cgi, &ses))
	return 0;
  }
  ZERO(&ses, sizeof(ses));
  
  switch (cgi.op) {
  case 'M':  /* Invoke LECP or redirect to CDC reader. */
    if (zxid_lecp_check(cf, &cgi))
      return 0;
    printf("Location: %s?o=C\r\n\r\n", ZXID_CDC_URL);
    return 0;
  case 'C':  /* CDC Read: Common Domain Cookie Reader */
    if (zxid_cdc_read(cf, &cgi))
      return 0;
    return 1;
  case 'E':  /* Return from CDC read, or start here to by-pass CDC read. */
    if (zxid_lecp_check(cf, &cgi))
      return 0;    
    if (zxid_cdc_check(cf, &cgi))
      return 0;
    break;
  case 'L':
    if (ss = zxid_start_sso_location(cf, cgi)) {
      printf("%.*s", ss->len, ss->s);
      return 0;
    }
    break;
  case 'A':
    D("Process artifact(%s)", cgi.saml_art);
    switch (zxid_sp_deref_art(cf, &cgi, &ses)) {
    case ZXID_REDIR_OK: return 0;
    case ZXID_SSO_OK:
      if (zxid_mgmt(cf, &cgi, &ses))
	return 0;
    }
    break;
  case 'P':
  case 'Q':
    DD("Process response(%s)", cgi.saml_resp);
    ss = zxid_sp_dispatch(cf, &cgi, &ses);
    switch (ss->s[0]) {
    case 'L':
      printf("%.*s", ss->len, ss->s);
      zx_str_free(cf->ctx, ss);
      fflush(stdout);
      return 0;
    case 'O':
      if (zxid_mgmt(cf, &cgi, &ses))
	return 0;
    }
    break;
  case 'B':  /* Metadata */
    write_all_fd(fdstdout, "Content-Type: text/xml\r\n\r\n", sizeof("Content-Type: text/xml\r\n\r\n")-1);
    return zxid_send_sp_meta(cf, &cgi);
  default: D("unknown op(%c)", cgi.op);
  }
  
  //printf("COOKIE: foo\r\n");
  printf("Content-Type: text/html\r\n\r\n");
  printf("<title>ZXID SP SSO</title>" ZXID_BODY_TAG "<h1>ZXID SP Federated SSO (user NOT logged in, no session)</h1><pre>\n");
  //if (qs) printf("QS(%s)\n", qs);
  //if (got>0) printf("GOT(%.*s)\n", got, buf);
  printf("</pre><form method=post action=\"zxid?o=P\">");
  if (cgi.err)
    printf("<p><font color=red><i>%s</i></font></p>\n", cgi.err);
  if (cgi.msg)
    printf("<p><i>%s</i></p>\n", cgi.msg);
  //printf("User:<input name=user> PW:<input name=pw type=password>");
  //printf("<input name=login value=\" Login \" type=submit>");

  printf("<h3>Login Using New IdP</h3>\n");
  printf("<i>A new IdP is one whose metadata we do not have yet. We need to know the Entity ID in order to fetch the metadata using the well known location method. You will need to ask the adminstrator of the IdP to tell you what the EntityID is.</i>\n");
  printf("<p>IdP EntityID URL <input name=e size=100>");
  printf("<input type=submit name=l1 value=\" Login (SAML20:Artifact) \">\n");
  printf("<input type=submit name=l2 value=\" Login (SAML20:POST) \"><br>\n");

  idp = zxid_load_cot_cache(cf);
  
  if (idp) {
    printf("<h3>Login Using Known IdP</h3>\n");
    for (; idp; idp = idp->n) {
      if (!idp->ed->IDPSSODescriptor)
	continue;
      printf("<input type=submit name=\"l0%s\" value=\" Login to %s (SAML20:any) \">\n",
	     idp->eid, idp->eid);
      printf("<input type=submit name=\"l1%s\" value=\" Login to %s (SAML20:Artifact) \">\n",
	     idp->eid, idp->eid);
      printf("<input type=submit name=\"l2%s\" value=\" Login to %s (SAML20:POST) \">\n",
	     idp->eid, idp->eid);
      printf("<input type=submit name=\"l5%s\" value=\" Login to %s (SAML20:SimpleSign) \">\n",
	     idp->eid, idp->eid);
    }
  }
  
#if 0
  printf("<h3>Login Using IdP Discovered from Common Domain Cookie (CDC)</h3>\n");

  printf("<input type=submit name=\"l1https://s-ps.liberty-iop.org:8881/idp.xml\" value=\" Login to test-idp3 (SAML20:Artifact) \">\n");
  printf("<input type=submit name=\"l2https://s-ps.liberty-iop.org:8881/idp.xml\" value=\" Login to test-idp3 (SAML20:POST) \">\n");
#endif

  printf("<h3>CoT configuration parameters your IdP may need to know</h3>\n");
  eid = zxid_my_ent_id_cstr(cf);
  printf("Entity ID of this SP: <a href=\"%s\">%s</a> (Click on the link to fetch SP metadata.)\n", eid, eid);

  printf("<h3>Technical options (typically hidden fields on production site)</h3>\n");
  printf("<input type=checkbox name=fc value=1 checked> Allow new federation to be created<br>\n");
  printf("<input type=checkbox name=fp value=1> Do not allow IdP to interact (e.g. ask password) (IsPassive flag)<br>\n");
  printf("<input type=checkbox name=ff value=1> IdP should reauthenticate user (ForceAuthn flag)<br>\n");

  printf("NID Format: <select name=fn><option value=prstnt>Persistent<option value=trnsnt>Transient<option value=\"\">(none)</select><br>\n");
  printf("Affiliation: <select name=fq><option value=\"\">(none)</select><br>\n");
  printf("Consent: <select name=fy><option value=\"\">(empty)<option value=\"urn:liberty:consent:obtained\">obtained<option value=\"urn:liberty:consent:obtained:prior\">obtained:prior<option value=\"urn:liberty:consent:obtained:current:implicit\">obtained:current:implicit<option value=\"urn:liberty:consent:obtained:current:explicit\">obtained:current:explicit<option value=\"urn:liberty:consent:unavailable\">unavailable<option value=\"urn:liberty:consent:inapplicable\">inapplicable</select><br>\n");
  printf("Authn Req Context: <select name=fa><option value=\"\">(none)<option value=pw>Password<option value=pwp>Password with Protected Transport<option value=clicert>TLS Client Certificate</select><br>\n");
  printf("Matching Rule: <select name=fm><option value=exact>Exact<option value=minimum>Min<option value=maximum>Max<option value=better>Better<option value=\"\">(none)</select><br>\n");
  printf("RelayState: <input name=fr value=\"rs123\"><br>\n");

  printf("</form><hr>");
  printf("<a href=\"http://zxid.org/\">zxid.org</a>, %s", zxid_version_str());
  if (cgi.dbg)
    printf("<p><form><textarea cols=100 row=10>%s</textarea></form>\n", cgi.dbg);
  return 0;
}

/* EOF  --  zxid.c */
