/* zxbusd.c  -  Audit bus daemon using STOMP 1.1
 * Copyright (c) 2006,2012 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing. See file COPYING.
 * Special grant: zxbusd.c may be used with zxid open source project under
 * same licensing terms as zxid itself.
 * $Id$
 *
 * 15.4.2006, started work over Easter holiday --Sampo
 * 22.4.2006, added more options over the weekend --Sampo
 * 16.8.2012, modified license grant to allow use with ZXID.org --Sampo
 *
 * This file contains option processing, configuration, and main().
 *
 * To create bus users, you should follow these steps
 * 1. Run ./zxbuslist -c 'BURL=https://sp.foo.com/' -dc to determine the entity ID
 * 2. Convert entity ID to SHA1 hash: ./zxcot -p 'https://sp.foo.com?o=B'
 * 3. Create the user: ./zxpasswd -a 'eid: https://sp.foo.com?o=B' -new G2JpTSX_dbdJ7frhYNpKWGiMdTs /var/zxid/bus/uid/ <passwd
 * 4. To enable ClientTLS authentication, determine the subject_hash of
 *    the encryption certificate and symlink that to the main account:
 *      > openssl x509 -subject_hash -noout </var/zxid/buscli/pem/enc-nopw-cert.pem
 *      162553b8
 *      > ln -s /var/zxid/bus/uid/G2JpTSX_dbdJ7frhYNpKWGiMdTs /var/zxid/bus/uid/162553b8
 */

#include <pthread.h>
#include <signal.h>
#include <fcntl.h>
#include <netdb.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>

#ifdef HAVE_NET_SNMP
#include "snmpInterface.h"
#endif

/*#include "dialout.h"       / * Async serial support */
/*#include "serial_sync.h"   / * Sync serial support */
#include "errmac.h"
#include "hiios.h"
#include "hiproto.h"
#include "akbox.h"
#include "c/zxidvers.h"
#include <zx/zxid.h>
#include <zx/zxidutil.h>

#define ZXBUS_PATH "/var/zxid/bus/"

const char* help =
"zxbusd  -  Audit bus daemon using STOMP 1.1 - R" ZXID_REL "\n\
Copyright (c) 2006,2012 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.\n\
NO WARRANTY, not even implied warranties.\n\
Send well researched bug reports to the author. Home: zxid.org\n\
\n\
Usage: zxbusd [options] PROTO:REMOTEHOST:PORT\n\
       echo secret | zxbusd -p sis::5066 -c AES256 -k 0 dts:quebec.cellmail.com:5067\n\
       echo secret | zxbusd -p sis::5066 -c AES256 -k 0 dts:/dev/se_hdlc1:S-9600-1000-8N1\n\
       zxbusd -p smtp::25 sis:localhost:5066 smtp:mail.cellmail.com:25\n\
  -c CONF          Optional configuration string (default -c PATH=" ZXBUS_PATH ")\n\
                   Most of the configuration is read from " ZXBUS_PATH ZXID_CONF_FILE "\n\
  -cp PATH         Path for message and user databases. Default: " ZXBUS_PATH "\n\
  -p  PROT:IF:PORT Protocol, network interface and TCP port for listening\n\
                   connections. If you omit interface, all interfaces are bound.\n\
                     stomp:0.0.0.0:2229 - Listen for STOMP 1.1 (default if no -p supplied)\n\
                     smtp:0.0.0.0:25    - Listen for SMTP (RFC 2821)\n\
                     http:0.0.0.0:80    - Listen for HTTP/1.0 (simplified)\n\
                     tp:0.0.0.0:5068    - Listen for test ping protocol\n\
  -t  SECONDS      Connection timeout. Default: 0=no timeout.\n\
  -cy CIPHER       Enable crypto on DTS interface using specified cipher. Use '?' for list.\n\
  -k  FDNUMBER     File descriptor for reading symmetric key. Use 0 for stdin.\n\
  -nfd  NUMBER     Maximum number of file descriptors, i.e. simultaneous\n\
                   connections. Default 20 (about 16 connections).\n\
  -npdu NUMBER     Maximum number of simultaneously active PDUs. Default 60.\n\
  -nch  NUMBER     Maximum number of subscribable channels. Default 10.\n\
  -nthr NUMBER     Number of threads. Default 1. Should not exceed number of CPUs.\n\
  -nkbuf BYTES     Size of kernel buffers. Default is not to change kernel buffer size.\n\
  -nlisten NUMBER  Listen backlog size. Default 128.\n\
  -egd PATH        Specify path of Entropy Gathering Daemon socket, default on\n\
                   Solaris: /tmp/entropy. On Linux /dev/urandom is used instead\n\
                   See http://www.lothar.com/tech/crypto/ or\n\
                   http://www.aet.tu-cottbus.de/personen/jaenicke/postfix_tls/prngd.html\n\
  -rand PATH       Location of random number seed file. On Solaris EGD is used.\n\
                   On Linux the default is /dev/urandom. See RFC1750.\n\
  -snmp PORT       Enable SNMP agent (if compiled with Net SNMP).\n\
  -uid UID:GID     If run as root, drop privileges and assume specified uid and gid.\n\
  -pid PATH        Write process id in the supplied path\n\
  -watchdog        Enable built-in watch dog\n\
  -kidpid PATH     Write process id of the child of watchdog in the supplied path\n\
  -ak size_MB      Turn on Application Flight Recorder. size_MB is per thread buffer.\n\
  -v               Verbose messages.\n\
  -q               Be extra quiet.\n\
  -d               Turn on debugging.\n\
  -dc              Dump config.\n\
  -license         Show licensing details\n\
  -h               This help message\n\
  --               End of options\n\
N.B. Although zxbusd is a 'daemon', it does not daemonize itself. You can always say zxbusd&\n";

char* instance = "zxbusd";  /* how this server is identified in logs */
char* zxbus_path = ZXBUS_PATH;
zxid_conf* zxbus_cf;
int ak_buf_size = 0;
int verbose = 1;
extern int errmac_debug;
int debugpoll = 0;
int timeout = 0;
int nfd = 20;
int npdu = 60;
int nch = 10;
int nthr = 1;
int nkbuf = 0;
int listen_backlog = 128;   /* what is right tuning for this? */
int gcthreshold = 0;
int leak_free = 0;
//int assert_nonfatal = 0;
int drop_uid = 0;
int drop_gid = 0;
int watchdog;
int snmp_port = 0;
char* pid_path = 0;
char* kidpid_path = 0;
char* rand_path;
char* egd_path;
char  symmetric_key[1024];
int symmetric_key_len;
struct hi_host_spec* listen_ports = 0;
struct hi_host_spec* remotes = 0;

struct hi_proto hi_prototab[] = {  /* n.b. order in this table must match constants in hiproto.h */
  { "dummy0",  0, 0, 0 },
  { "pollon",  0, 0, 0 },
  { "sis",    5066, 0, 0 },
  { "dts",    5067, 0, 0 },
  { "smtp",     25, 0, 0 },
  { "http",   8080, 0, 0 },
  { "tp",     5068, 0, 0 },  /* testping (6) */
  { "stomp",  2228, 0, 0 },  /* 7 */
  { "stomps", 2229, 1, 0 },  /* 8 n.b. 2229 is zxbus assigned port. Normal STOMP port is 61613 */
  { "", 0 }
};

char remote_station_addr[] = { 0x61, 0x89, 0x00, 0x00 };   /* *** temp kludge */
struct hiios* shuff;        /* Main I/O shuffler object (global to help debugging) */

#define SNMPLOGFILE "/var/zxid/log/snmp.log"

/* proto:host:port or proto:host or proto::port */

/* Called by:  opt x2 */
int parse_port_spec(char* arg, struct hi_host_spec** head, char* default_host)
{
  struct hostent* he;
  char prot[8];
  char host[256];
  int proto, port, ret;
  struct hi_host_spec* hs;
  
  ret = sscanf(arg, "%8[^:]:%255[^:]:%i", prot, host, &port);
  switch (ret) {
  case 2:
    port = -1;   /* default */
  case 3:
    if (!strlen(prot)) {
      ERR("Bad proto:host:port spec(%s). You MUST specify proto.", arg);
      exit(5);
    }
    for (proto = 0; hi_prototab[proto].name[0]; ++proto)
      if (!strcmp(hi_prototab[proto].name, prot))
	break;
    if (!hi_prototab[proto].name[0]) {
      ERR("Bad proto:host:port spec(%s). Unknown proto.", arg);
      exit(5);
    }
    if (port == -1)
      port = hi_prototab[proto].default_port;
    if (strlen(host))
      default_host = host;
    break;
  default:
    ERR("Bad proto:host:port spec(%s). %d", arg, ret);
    return 0;
  }
  
  D("arg(%s) parsed as proto(%s)=%d host(%s) port(%d)", arg, prot, proto, host, port);
  ZMALLOC(hs);
  
  if (default_host[0] == '/') {  /* Its a serial port */
    hs->sin.sin_family = (unsigned short int)0xfead;
  } else {
    he = gethostbyname(default_host);
    if (!he) {
      ERR("hostname(%s) did not resolve(%d)", default_host, h_errno);
      exit(5);
    }
    
    hs->sin.sin_family = AF_INET;
    hs->sin.sin_port = htons(port);
    memcpy(&(hs->sin.sin_addr.s_addr), he->h_addr, sizeof(hs->sin.sin_addr.s_addr));
  }
  hs->specstr = arg;
  hs->proto = proto;
  hs->next = *head;
  *head = hs;
  return 1;
}

/* Called by:  main x8, zxbusd_main, zxbuslist_main, zxbustailf_main, zxcall_main, zxcot_main, zxdecode_main */
void opt(int* argc, char*** argv, char*** env)
{
  struct zx_str* ss;
  if (*argc <= 1) goto argerr;
  
  while (1) {
    ++(*argv); --(*argc);
    
    if (!(*argc) || ((*argv)[0][0] != '-')) break;  /* probably the remote host and port */
    
    switch ((*argv)[0][1]) {
    case '-': if ((*argv)[0][2]) break;
      ++(*argv); --(*argc);
      DD("End of options by --");
      return;  /* -- ends the options */

    case 'a': if ((*argv)[0][2] != 'k' || (*argv)[0][3]) break;
      ++(*argv); --(*argc);
      if (!(*argc)) break;
      ak_buf_size = atoi((*argv)[0]);
      ak_buf_size = ak_buf_size << 20;  /* Mega bytes */
      if (ak_buf_size)
	ak_add_thread(ak_buf_size,1);   /* Add current "main" thread. */
      continue;

    case 'n':
      switch ((*argv)[0][2]) {
      case 'f': if ((*argv)[0][3] != 'd' || (*argv)[0][4]) break;
	++(*argv); --(*argc);
	if (!(*argc)) break;
	nfd = atoi((*argv)[0]);
	continue;
      case 'c': if ((*argv)[0][3] != 'h' || (*argv)[0][4]) break;
	++(*argv); --(*argc);
	if (!(*argc)) break;
	nch = atoi((*argv)[0]);
	continue;
      case 'p': if ((*argv)[0][3] != 'd' || (*argv)[0][4] != 'u' || (*argv)[0][5]) break;
	++(*argv); --(*argc);
	if (!(*argc)) break;
	npdu = atoi((*argv)[0]);
	continue;
      case 't': if ((*argv)[0][3] != 'h' || (*argv)[0][4] != 'r' || (*argv)[0][5]) break;
	++(*argv); --(*argc);
	if (!(*argc)) break;
	nthr = atoi((*argv)[0]);
	continue;
      case 'k': if ((*argv)[0][3] != 'b' || (*argv)[0][4] != 'u' || (*argv)[0][5] != 'f' || (*argv)[0][6]) break;
	++(*argv); --(*argc);
	if (!(*argc)) break;
	nkbuf = atoi((*argv)[0]);
	continue;
      case 'l': if ((*argv)[0][3] != 'i' || (*argv)[0][4] != 's' || (*argv)[0][5]) break;
	++(*argv); --(*argc);
	if (!(*argc)) break;
	listen_backlog = atoi((*argv)[0]);
	continue;
      }
      break;

    case 's':
      switch ((*argv)[0][2]) {
      case 'n': if ((*argv)[0][3] != 'm' || (*argv)[0][4] != 'p' || (*argv)[0][5]) break;
	++(*argv); --(*argc);
	if (!(*argc)) break;
	snmp_port = atoi((*argv)[0]);
	continue;
      }
      break;

    case 't': if ((*argv)[0][2]) break;
      ++(*argv); --(*argc);
      if (!(*argc)) break;
      timeout = atoi((*argv)[0]);
      continue;

    case 'd':
      switch ((*argv)[0][2]) {
      case '\0':
	++errmac_debug;
	continue;
      case 'p':  if ((*argv)[0][3]) break;
	++debugpoll;
	continue;
      case 'i':  if ((*argv)[0][3]) break;
	++(*argv); --(*argc);
	if (!(*argc)) break;
	instance = (*argv)[0];
	continue;
      case 'c':
	ss = zxid_show_conf(zxbus_cf);
	if (verbose>1) {
	  printf("\n======== CONF ========\n%.*s\n^^^^^^^^ CONF ^^^^^^^^\n",ss->len,ss->s);
	  exit(0);
	}
	fprintf(stderr, "\n======== CONF ========\n%.*s\n^^^^^^^^ CONF ^^^^^^^^\n",ss->len,ss->s);
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

    case 'q':
      switch ((*argv)[0][2]) {
      case '\0':
	verbose = 0;
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
      
    case 'r':
      switch ((*argv)[0][2]) {
      case 'f':
	AK_TS(LEAK, 0, "memory leaks enabled");
#if 1
	ERR("*** WARNING: You have turned memory frees to memory leaks. We will (eventually) run out of memory. Using -rf is not recommended. %d\n", 0);
#endif
	++leak_free;
	continue;
#if 0
      case 'e':
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
      case 'g':
	if ((*argv)[0][3]) break;
	++(*argv); --(*argc);
	if (!(*argc)) break;
	gcthreshold = atoi((*argv)[0]);
	if (!gcthreshold)
	  ERR("*** WARNING: You have disabled garbage collection. This may lead to increased memory consumption for scripts that handle a lot of PDUs or run for long time. Using `-rg 0' is not recommended. %d\n", 0);
	continue;
      case 'a':
	if ((*argv)[0][3] == 0) {
	  AK_TS(ASSERT_NONFATAL, 0, "assert nonfatal enabled");
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

    case 'w':
      switch ((*argv)[0][2]) {
      case 'a':
	if (!strcmp((*argv)[0],"-watchdog")) {
	  ++watchdog;
	  continue;
	}
	break;
      }
      break;

    case 'p':
      switch ((*argv)[0][2]) {
      case '\0':
	++(*argv); --(*argc);
	if (!(*argc)) break;
	if (!parse_port_spec((*argv)[0], &listen_ports, "0.0.0.0")) break;
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

    case 'k':
      switch ((*argv)[0][2]) {
      case 'i':
	if (!strcmp((*argv)[0],"-kidpid")) {
	  ++(*argv); --(*argc);
	  if (!(*argc)) break;
	  kidpid_path = (*argv)[0];
	  continue;
	}
	break;
      case '\0':
	++(*argv); --(*argc);
	if (!(*argc)) break;
	read_all_fd(atoi((*argv)[0]), symmetric_key, sizeof(symmetric_key), &symmetric_key_len);
	D("Got %d characters of symmetric key", symmetric_key_len);
	continue;
      }
      break;

    case 'c':
      switch ((*argv)[0][2]) {
      case '\0':
	++(*argv); --(*argc);
	if ((*argc) < 1) break;
	zxid_parse_conf(zxbus_cf, (*argv)[0]);
	continue;
      case 'y':
	++(*argv); --(*argc);
	if (!(*argc)) break;
#ifndef ENCRYPTION
	ERR("Encryption not compiled in. %d",0);
#endif
	continue;
      case 'p':
	++(*argv); --(*argc);
	if (!(*argc)) break;
	zxbus_path = (*argv)[0];	
	continue;
      }
      break;

    case 'u':
      switch ((*argv)[0][2]) {
      case 'i': if ((*argv)[0][3] != 'd' || (*argv)[0][4]) break;
	++(*argv); --(*argc);
	if (!(*argc)) break;
	sscanf((*argv)[0], "%i:%i", &drop_uid, &drop_gid);
	continue;
      }
      break;

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

    } 
    /* fall thru means unrecognized flag */
    if (*argc)
      fprintf(stderr, "Unrecognized flag `%s'\n", (*argv)[0]);
  argerr:
    fprintf(stderr, "%s", help);
    exit(3);
  }

#if 0  
  /* Remaining commandline is the remote host spec for DTS */
  while (*argc) {
    if (!parse_port_spec((*argv)[0], &remotes, "127.0.0.1")) break;
    ++(*argv); --(*argc);
  }
#endif

  if (nfd < 1)  nfd = 1;
  if (npdu < 1) npdu = 1;
  if (nthr < 1) nthr = 1;
}

/* Parse serial port config string and do all the ioctls to get it right. */

/* Called by:  zxbusd_main */
static struct hi_io* serial_init(struct hi_thr* hit, struct hi_host_spec* hs)
{
#ifdef ENA_SERIAL
  struct hi_io* io;
  char tty[256];
  char sync = 'S', parity = 'N';
  int fd, ret, baud = 9600, bits = 8, stop = 1, framesize = 1000;
  ret = sscanf(hs->specstr, "dts:%255[^:]:%c-%d-%d-%d%c%d",
	       tty, &sync, &baud, &framesize, &bits, &parity, &stop);
  if (ret < 4) {
    fprintf(stderr, "You must supply serial port name and config, e.g. `dts:/dev/ttyS0:A-9600-8N1'. You gave(%s). You loose.\n", hs->specstr);
    exit(3);
  }
  fd = open(tty, O_RDWR | O_NOCTTY | O_NDELAY);
  if (fd == -1) {
    ERR("open(%s): Error opening serial port: %d %s", tty, errno, STRERROR(errno));
    exit(3);
  }
  if (fd >= shf->max_ios) {
    ERR("serial: File descriptor limit(%d) exceeded fd=%d. Consider increasing the limit with -nfd flag, or figure out if there are any descriptor leaks.", shf->max_ios, fd);
    close(fd);
    return 0;
  }
  io = hit->shf->ios + fd;
  io->qel.proto = hs->proto;
  if (verbose)
    log_port_info(fd, tty, "before");
  if (set_baud_rate(fd, tty, baud) == -1)
    exit(3);
  if (set_frame_size(fd, tty, framesize) == -1)
    exit(3);
  if (verbose)
    log_port_info(fd, tty, "after");
  nonblock(fd);
  LOCK(io->qel.mut, "serial_init");
  hi_add_fd(hit, io, fd, HI_TCP_C);
  UNLOCK(io->qel.mut, "serial_init");
  return io;
#else
  return 0;
#endif
}

/*() New born threads start here. hit is allocated from stack.
 * In principle all threads are created equal and any one of
 * then can act as the shuffler on its turn. */

/* Called by: */
void* thread_loop(void* _shf)
{
  struct hi_thr hit;
  struct hiios* shf = (struct hiios*)_shf;
  hi_hit_init(&hit);
  if (ak_buf_size)
    ak_add_thread(ak_buf_size, 1);  /* Add newly born thread */
  hi_shuffle(&hit, shf);            /* Never returns. */
  return 0;
}

/* ============== M A I N ============== */

pthread_mutexattr_t MUTEXATTR_DECL;
extern int zxid_suppress_vpath_warning;

#ifndef zxbusd_main
#define zxbusd_main main
#endif

/* Called by: */
int zxbusd_main(int argc, char** argv, char** env)
{ 
  struct hi_thr hit;
  hi_hit_init(&hit);
  ak_init(*argv);
#ifdef MINGW
  pthread_mutex_init(&dbilock, 0);
  pthread_mutex_init(&shuff_mutex, 0);
  pthread_mutex_init(&gethostbyname_mutex, 0);
  {
    WSADATA wsaDat;
    WORD vers = MAKEWORD(2,2);  /* or 2.0? */
    ret = WSAStartup(vers, &wsaDat);
    if (ret) {
      ERR("WinSock DLL could not be initialized: %d", ret);
      return -1;
    }
  }
#endif
#if !defined(MACOS) && !defined(MINGW)
# ifdef MUTEX_DEBUG
#  ifndef PTHREAD_MUTEX_ERRORCHECK_NP
#   define PTHREAD_MUTEX_ERRORCHECK_NP 2
#  endif
  if (pthread_mutexattr_init(MUTEXATTR)) NEVERNEVER("unable to initialize mutexattr %d",argc);
#  ifndef __dietlibc__
  if (pthread_mutexattr_settype(MUTEXATTR, PTHREAD_MUTEX_ERRORCHECK_NP))
    NEVERNEVER("unable to set mutexattr %d",argc);
#  endif
# endif
#endif
#ifdef COMPILED_DATE
  int now = time(0);
  if (COMPILED_DATE + TWO_MONTHS < now) {   /* *** this logic needs refinement and error code of its own --Sampo */
     if (COMPILED_DATE + THREE_MONTHS < now){ 
        ERR("Evaluation copy expired. %d",0);
	exit(4);
     } else
        ERR("Evaluation copy expired, in %d secs this program will stop working", COMPILED_DATE + THREE_MONTHS-now);
  } else {
    if (now + ONE_DAY < COMPILED_DATE){
      ERR("Check for demo erroneus. Clock set too far in past? %d",0);
      exit(4);
    }
  }
#endif
  
  zxid_suppress_vpath_warning = 1;
  zxbus_cf = zxid_new_conf_to_cf("PATH=" ZXBUS_PATH);
  /*openlog("zxbusd", LOG_PID, LOG_LOCAL0);     *** Do we want syslog logging? */
  opt(&argc, &argv, &env);
  zxbus_path = zxbus_cf->cpath;

  /*if (stats_prefix) init_cmdline(argc, argv, env, stats_prefix);*/
  CMDLINE("init");

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
  
  if (watchdog) {
#ifdef MINGW
    ERR("Watch dog feature not supported on Windows.");
#else
    int ret, watch_dog_iteration = 0;
    while (1) {
      ++watch_dog_iteration;
      D("Watch dog loop %d", watch_dog_iteration);
      switch (ret = fork()) {
      case -1:
	ERR("Watch dog %d: attempt to fork() real server failed: %d %s. Perhaps max number of processes has been reached or we are out of memory. Will try again in a sec. To stop a vicious cycle `kill -9 %d' to terminate this watch dog.", watch_dog_iteration, errno, STRERROR(errno), getpid());
	break;
      case 0:   goto normal_child;  /* Only way out of this loop */
      default:
	/* Reap the child */
	switch (waitpid(ret, &ret, 0)) {
	case -1:
	  ERR("Watch dog %d: attempt to waitpid() real server failed: %d %s. To stop a vicious cycle `kill -9 %d' to terminate this watch dog.", watch_dog_iteration, errno, STRERROR(errno), getpid());
	  break;
	default:
	  ERR("Watch dog %d: Real server exited. Will restart in a sec. To stop a vicious cycle `kill -9 %d' to terminate this watch dog.", watch_dog_iteration, getpid());
	}
      }
      sleep(1); /* avoid spinning tightly */
    }
#endif
  }

 normal_child:
  D("Real server pid %d", getpid());

  if (kidpid_path) {
    int len;
    char buf[INTSTRLEN];
    len = sprintf(buf, "%d", (int)getpid());
    if (write2_or_append_lock_c_path(pid_path,0,0,len,buf,"write kidpid",SEEK_SET,O_TRUNC) <= 0) {
      ERR("Failed to write kidpid file(%s). If you do not want kidpid file, do not supply -kidpid option. Continuing anyway.", pid_path);
    }
  }

#ifndef MINGW  
  if (signal(SIGPIPE, SIG_IGN) == SIG_ERR) {   /* Ignore SIGPIPE */
    perror("signal ignore pipe");
    exit(2);
  }

  /* Cause exit(3) to be called with the intent that any gcov profiling will get
   * written to disk before we die. If zxbusd is not stopped with `kill -USR1' and you
   * use plain kill instead, the profile will indicate many unexecuted (#####) lines. */
  if (signal(SIGUSR1, exit) == SIG_ERR) {
    perror("signal USR1 exit");
    exit(2);
  }
#endif

  shuff = hi_new_shuffler(&hit, nfd, npdu, nch, nthr);
  {
    struct hi_io* io;
    struct hi_host_spec* hs;
    struct hi_host_spec* hs_next;

    /* Prepare listeners first so we can then later connect to ourself. */
    CMDLINE("listen");

    for (hs = listen_ports; hs; hs = hs->next) {
      io = hi_open_listener(shuff, hs, hs->proto);
      if (!io)
	break;
      io->n = hs->conns;
      hs->conns = io;
    }
    
    for (hs = remotes; hs; hs = hs_next) {
      hs_next = hs->next;
      hs->next = hi_prototab[hs->proto].specs;
      hi_prototab[hs->proto].specs = hs;
      if (hs->proto == HIPROTO_SMTP)
	continue;  /* SMTP connections are opened later, when actual data from SIS arrives. */

      if (hs->sin.sin_family == (unsigned short int)0xfead)
	io = serial_init(&hit, hs);
      else
	io = hi_open_tcp(&hit, hs, hs->proto);
      if (!io)
	break;
      io->n = hs->conns;
      hs->conns = io;
#ifdef ENA_S5066
      switch (hs->proto) {
      case S5066_SIS:   /* *** Always bind as HMTP. Make configurable. */
	sis_send_bind(&hit, io, SAP_ID_HMTP, 0, 0x0200);  /* 0x0200 == nonarq, no repeats */
	break;
      case S5066_DTS:
	ZMALLOC(io->ad.dts);
	io->ad.dts->remote_station_addr[0] = 0x61;   /* three nibbles long (padded with zeroes) */
	io->ad.dts->remote_station_addr[1] = 0x23;
	io->ad.dts->remote_station_addr[2] = 0x00;
	io->ad.dts->remote_station_addr[3] = 0x00;
	break;
      }
#endif
    }
  }

  if (snmp_port) {
#ifdef HAVE_NET_SNMP
    initializeSNMPSubagent("open5066", SNMPLOGFILE);
    /* *** we need to discover the SNMP socket somehow so we can insert it to
     * our file descriptor table so it gets properly polled, etc. --Sampo */
#else
    ERR("This binary was not compiled to support SNMP (%d). Continuing without.", snmp_port);
#endif
  }
  
  /* Drop privileges, if requested. */
  
  if (drop_gid) if (setgid(drop_gid)) { perror("setgid"); exit(1); }
  if (drop_uid) if (setuid(drop_uid)) { perror("setuid"); exit(1); }

  CMDLINE("load_subs");
  zxbus_load_subs(shuff);
  
  hi_sanity_shf(255, shuff);
  
  /* Unleash threads so that the listeners are served. */
  
  CMDLINE("unleash");
  {
    int err;
    pthread_t tid;
    for (--nthr; nthr; --nthr)
      if ((err = pthread_create(&tid, 0, thread_loop, shuff))) {
	ERR("pthread_create() failed: %d (nthr=%d)", err, nthr);
	exit(2);
      }
  }
  
  hi_shuffle(&hit, shuff);  /* main thread becomes one of the workers */
  return 0; /* never really happens because hi_shuffle() never returns */
}

//char* assert_msg = "%s: Internal error caused an ASSERT to fire. Deliberately provoking a core dump.\nSorry for the inconvenience and thank you for your collaboration.\n";

/* EOF  --  zxbusd.c */
