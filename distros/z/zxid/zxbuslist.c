/* zxbuslist.c  -  Utility for listening for events on zxbus
 * Copyright (c) 2012 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id$
 *
 * 27.8.2012, created --Sampo
 */

#include "platform.h"  /* for dirent.h and unistd.h */

#include <signal.h>
#include <string.h>
#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/wait.h>

#include "errmac.h"
#include "zx.h"
#include "zxid.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "c/zxidvers.h"
#include "c/zx-const.h"
#include "c/zx-ns.h"
#include "c/zx-data.h"

char* help =
"zxbuslist  -  Listen to zxbus and send output to stdout R" ZXID_REL "\n\
zxbus is an Audit Bus for TAS3 or end2end Trus Assurance (e2eTA).\n\
Copyright (c) 2012 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.\n\
NO WARRANTY, not even implied warranties. Licensed under Apache License v2.0\n\
See http://www.apache.org/licenses/LICENSE-2.0\n\
Send well researched bug reports to the author. Home: zxid.org\n\
\n\
Usage: zxbuslist [options] > bus-traffic\n\
  -c CONF          Optional configuration string (default -c PATH=/var/zxid/)\n\
                   Most of the configuration is read from " ZXID_CONF_PATH "\n\
  -c 'BUS_URL=stomps://localhost:2229/'   -- Typical invocation, indicates zxbusd to contact\n\
  -ch CHAN         Indicate channel to subscribe to\n\
  -o N             One-shot mode. Receive N messages and then exit. If -1, get all available.\n\
  -it N            Number of threads launching parallel sessions, for benchmarking.\n\
  -pid PATH        Write process id in the supplied path\n\
  -p               Do not persist. Default is to persist in style similar to zxbus,\n\
                   in /var/zxid/HOST/ch/DEST directory\n\
  -v               Verbose messages.\n\
  -q               Be extra quiet.\n\
  -d               Turn on debugging.\n\
  -dc              Dump config.\n\
  -a -a            Turn on ascii coloring for stdout.\n\
  -h               This help message\n\
  --               End of options\n\
\n";

extern int zxbus_ascii_color;
int dryrun  = 0;
extern int zxbus_verbose;
int n_thr = 1;
char* pid_path = 0;
char* chan = "default";
zxid_conf* cf;
int zxbus_oneshot = -2;  /* -2=Infinite listen (blocks as needed), -1=get all immediately available, >1, get specified number of messages (blocking if needed). */
extern int zxbus_persist_flag;

/* Called by:  main x8, zxbusd_main, zxbuslist_main, zxbustailf_main, zxcall_main, zxcot_main, zxdecode_main */
static void opt(int* argc, char*** argv, char*** env)
{
  struct zx_str* ss;
  if (*argc <= 1) return;
  
  while (1) {
    ++(*argv); --(*argc);
    
    if (!(*argc) || ((*argv)[0][0] != '-')) break;  /* normal exit from options loop */
    
    switch ((*argv)[0][1]) {
    case '-': if ((*argv)[0][2]) break;
      ++(*argv); --(*argc);
      DD("End of options by --");
      return;  /* -- ends the options */

    case 'a':
      switch ((*argv)[0][2]) {
      case '\0':
	++zxbus_ascii_color;;
	continue;
      }
      break;

    case 'c':
      switch ((*argv)[0][2]) {
      case '\0':
	++(*argv); --(*argc);
	if ((*argc) < 1) break;
	zxid_parse_conf(cf, (*argv)[0]);
	continue;
      case 'h':
	++(*argv); --(*argc);
	if ((*argc) < 1) break;
	chan = (*argv)[0];
	continue;
      }
      break;

    case 'd':
      switch ((*argv)[0][2]) {
      case '\0':
	++errmac_debug;
	if (errmac_debug == 2)
	  strncpy(errmac_instance, "\t\e[43mzxbuslist\e[0m", sizeof(errmac_instance));
	continue;
      case 'c':
	ss = zxid_show_conf(cf);
	if (zxbus_verbose>1) {
	  fprintf(stdout, "\n======== CONF ========\n%.*s\n^^^^^^^^ CONF ^^^^^^^^\n",ss->len,ss->s);
	  exit(0);
	}
	fprintf(stderr, "\n======== CONF ========\n%.*s\n^^^^^^^^ CONF ^^^^^^^^\n",ss->len,ss->s);
	continue;
      }
      break;

    case 'i':
      switch ((*argv)[0][2]) {
      case 't':
	if ((*argv)[0][3]) break;
	++(*argv); --(*argc);
	if (!(*argc)) break;
	n_thr = atoi((*argv)[0]);
	continue;
      }
      break;

    case 'o':
      switch ((*argv)[0][2]) {
      case '\0':
	++(*argv); --(*argc);
	if (!(*argc)) break;
	zxbus_oneshot = atoi((*argv)[0]);
	continue;
      }
      break;

    case 'p':
      switch ((*argv)[0][2]) {
      case '\0':
	--zxbus_persist_flag;
	continue;
      case 'i':
	if (!strcmp((*argv)[0],"-pid")) {
	  ++(*argv); --(*argc);
	  if (!(*argc)) break;
	  pid_path = (*argv)[0];
	  continue;
	}
	break;
      }
      break;

    case 'n':
      switch ((*argv)[0][2]) {
      case '\0':
	++dryrun;
	continue;
      }
      break;

    case 'q':
      switch ((*argv)[0][2]) {
      case '\0':
	zxbus_verbose = 0;
	continue;
      }
      break;

    case 'v':
      switch ((*argv)[0][2]) {
      case '\0':
	++zxbus_verbose;
	continue;
      }
      break;

    } 
    /* fall thru means unrecognized flag */
    if (*argc)
      fprintf(stderr, "Unrecognized flag `%s'\n", (*argv)[0]);
help:
    if (zxbus_verbose>1) {
      fprintf(stdout, "%s", help);
      exit(0);
    }
    fprintf(stderr, "%s", help);
    /*fprintf(stderr, "version=0x%06x rel(%s)\n", zxid_version(), zxid_version_str());*/
    exit(3);
  }
}

/* Alias some struct fields for headers that can not be seen together. */
#define receipt   host
#define rcpt_id   host
#define acpt_vers vers
#define tx_id     vers
#define session   login
#define subs_id   login
#define subsc     login
#define server    pw
#define ack       pw
#define msg_id    pw
#define heart_bt  dest

#ifndef zxbuslist_main
#define zxbuslist_main main
#endif
extern int zxid_suppress_vpath_warning;

/* Called by: */
static void sig_alarm_to_stop_blocking_read(int signum)
{
  D("blocking read interrupted signum(%d)", signum);
  exit(0);
}

/*() Audit Bus listening tool */

/* Called by: */
int zxbuslist_main(int argc, char** argv, char** env)
{
  int len,nt,pid;
  struct zxid_bus_url* bu;
  pid_t* kids;
  strncpy(errmac_instance, "\tzxbuslist", sizeof(errmac_instance));
  zxbus_verbose = 1;
  zxid_suppress_vpath_warning = 1;
  cf = zxid_new_conf_to_cf(0);
  opt(&argc, &argv, &env);
  
  if (pid_path) {
    int len;
    char buf[INTSTRLEN];
    len = sprintf(buf, "%d", (int)getpid());
    DD("pid_path=`%s'", pid_path);
    if (write2_or_append_lock_c_path(pid_path,0,0,len,buf, "write pid", SEEK_SET, O_TRUNC) <= 0) {
      ERR("Failed to write PID file(%s). Exiting. (Do not supply -pid if you do not want pid file.)", pid_path);
      exit(1);
    }
  }

  /* Cause exit(3) to be called with the intent that any gcov profiling will get
   * written to disk before we die. If zxbusd is not stopped with `kill -USR1' and you
   * use plain kill instead, the profile will indicate many unexecuted (#####) lines. */
  if (signal(SIGUSR1, exit) == SIG_ERR) {
    perror("signal USR1 exit");
    exit(2);
  }
  
  if (n_thr > 1) {
    /* Fork test clients in great (specified) numbers. */
    kids = ZX_ALLOC(cf->ctx, n_thr * sizeof(pid_t));
    
    for (nt = 0; nt < n_thr; ++nt) {
      if ((kids[nt] = fork()) == -1) { perror("fork"); exit(1); }
      if (!kids[n_thr])
	goto kid;
    }
    D("All forked (%d), now waiting...", n_thr);
    for (nt = 0; nt < n_thr; ++nt) {
      if ((pid = wait(&len))==-1) { perror("wait"); exit(1); }
      if (WIFEXITED(len)) {
	if (WEXITSTATUS(len)) {
	  ERR("wait(%d): Process exited with nozero status %x.", pid, WEXITSTATUS(len));
	}
      } else {
	ERR("wait(%d): Process died abnormally %x.", pid, len);
      }
    }
    D("All waited (%d), done.", n_thr);
    return 0;
  } else {
    nt = -1;
  }
 kid:

  bu = cf->bus_url;
  if (!bu || !bu->s || !bu->s[0]) {
    ERR("No bus_url configured means audit bus reporting is disabled. %p", bu);
    return 1;
  }
  
  /* *** implement intelligent lbfo algo */
  
  if (!bu->fd)
    zxbus_open_bus_url(cf, bu);
  if (!bu->fd)
    return 1;
  zxbus_send_cmdf(cf, bu, 0, 0, "SUBSCRIBE\ndestination:%s\nid:0\nack:client-individual\nreceipt:%d\n\n", chan, bu->cur_rcpt++);
  
  if (zxbus_oneshot == -1) {
    /* In case we hit a blocking read, then this alarm will unblock us
     * and allow return. */
    signal(SIGALRM, (void*)sig_alarm_to_stop_blocking_read);
    alarm(1);
  }
  while (zxbus_oneshot && zxbus_listen_msg(cf, bu))
    --zxbus_oneshot;
  zxbus_close_all(cf);
  return 0;
}

/* EOF  --  zxbuslist.c */
