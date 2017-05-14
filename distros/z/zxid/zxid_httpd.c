/* zxid_httpd - small zxid enabled HTTP server derived from mini_httpd-1.19
 * Copyright (c) 2013-2015 Synergetics NV (sampo@synergetics.be)
 * All Rights Reserverd.
 * New bugs are mine, do not bother Jef with them. --Sampo */
/* mini_httpd - small HTTP server
**
** Copyright © 1999,2000 by Jef Poskanzer <jef@acme.com>.
** All rights reserved.
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions
** are met:
** 1. Redistributions of source code must retain the above copyright
**    notice, this list of conditions and the following disclaimer.
** 2. Redistributions in binary form must reproduce the above copyright
**    notice, this list of conditions and the following disclaimer in the
**    documentation and/or other materials provided with the distribution.
**
** THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
** ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
** IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
** ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
** FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
** DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
** OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
** HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
** LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
** OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
** SUCH DAMAGE.
*/

#include <zx/platform.h>
#include <zx/errmac.h>
#include <zx/zxid.h>
#include <zx/zxidutil.h>
#include <zx/zxidpriv.h>
#include <zx/c/zxidvers.h>

#ifdef MINGW
#define _POSIX
#define __USE_MINGW_ALARM
#include <process.h>
#endif

zxid_ses* zxid_mini_httpd_filter(zxid_conf* cf, const char* method, const char* uri_path, const char* qs, const char* cookie_hdr);
void zxid_mini_httpd_wsp_response(zxid_conf* cf, zxid_ses* ses, int rfd, char** response, size_t* response_size, size_t* response_len, int br_ix);
int zxid_pool2env(zxid_conf* cf, zxid_ses* ses, char** envp, int envn, int max_envn, const char* uri_path, const char* qs);
zxid_ses* zxid_mini_httpd_step_up(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, const char* uri_path, const char* cookie_hdr);

zxid_conf* zxid_cf;      /* ZXID enable flag and config string, zero initialized per POSIX */
zxid_ses* zxid_session;  /* Non-null if SSO or session from cookie or WSP validate */
int zxid_is_wsp;         /* Flag to trigger WSP response decoration. */
char* zxid_conf_str = 0;
char server_port_buf[32];
char http_host_buf[256];
char script_name_buf[256];

#define SERVER_SOFTWARE "zxid_httpd/" ZXID_REL " (based on mini_httpd/1.19 19dec2003)"
#define SERVER_URL "http://zxid.org/"

#include <unistd.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <limits.h>
#include <errno.h>
#include <sys/param.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <dirent.h>
#include <time.h>
#include <signal.h>
#ifndef MINGW
#include <sys/mman.h>
#include <syslog.h>
#include <pwd.h>
#include <grp.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <sys/wait.h>
#include <sys/socket.h>
#include <netdb.h>
#endif

#include "port.h"
extern time_t tdate_parse( char* str );

#ifdef HAVE_SENDFILE
# ifdef HAVE_LINUX_SENDFILE
#  include <sys/sendfile.h>
# else /* HAVE_LINUX_SENDFILE */
#  include <sys/uio.h>
# endif /* HAVE_LINUX_SENDFILE */
#endif /* HAVE_SENDFILE */

#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/des.h>
#define crypt(pw,salt) DES_crypt((pw),(salt))

#if defined(AF_INET6) && defined(IN6_IS_ADDR_V4MAPPED)
#define USE_IPV6
#endif

#ifndef SHUT_WR
#define SHUT_WR 1
#endif

#ifndef SIZE_T_MAX
#define SIZE_T_MAX 2147483647L
#endif

#ifndef HAVE_INT64T
typedef long long int64_t;
#endif

#ifndef ERR_DIR
#define ERR_DIR "errors"
#endif /* ERR_DIR */
#ifndef DEFAULT_HTTP_PORT
#define DEFAULT_HTTP_PORT 80
#endif /* DEFAULT_HTTP_PORT */
#ifndef DEFAULT_HTTPS_PORT
#define DEFAULT_HTTPS_PORT 443
#endif /* DEFAULT_HTTPS_PORT */
#ifndef DEFAULT_USER
#define DEFAULT_USER "nobody"
#endif /* DEFAULT_USER */
#ifndef CGI_NICE
#define CGI_NICE 10
#endif /* CGI_NICE */
#ifndef CGI_PATH
#define CGI_PATH "/usr/local/bin:/usr/ucb:/bin:/usr/bin"
#endif /* CGI_PATH */
#ifndef CGI_LD_LIBRARY_PATH
#define CGI_LD_LIBRARY_PATH "/usr/local/lib:/usr/lib"
#endif /* CGI_LD_LIBRARY_PATH */
#ifndef AUTH_FILE
#define AUTH_FILE ".htpasswd"
#endif /* AUTH_FILE */
#ifndef READ_TIMEOUT
#define READ_TIMEOUT 60
#endif /* READ_TIMEOUT */
#ifndef WRITE_TIMEOUT
#define WRITE_TIMEOUT 300
#endif /* WRITE_TIMEOUT */
#ifndef MINI_DEFAULT_CHARSET
#define MINI_DEFAULT_CHARSET "iso-8859-1"
#endif /* MINI_DEFAULT_CHARSET */

#define METHOD_UNKNOWN 0
#define METHOD_GET 1
#define METHOD_HEAD 2
#define METHOD_POST 3

/* A multi-family sockaddr. */
typedef union {
  struct sockaddr sa;
  struct sockaddr_in sa_in;
#ifdef USE_IPV6
  struct sockaddr_in6 sa_in6;
  struct sockaddr_storage sa_stor;
#endif /* USE_IPV6 */
} usockaddr;

static char* argv0;
static unsigned short port;
static char* dir;
static char* data_dir;
static int do_chroot;
static int vhost;
static char* user;
static char* cgi_pattern;
static char* url_pattern;
static int no_empty_referers;
static char* local_pattern;
static char* hostname;
static char hostname_buf[256];
static char* logfile;
static char* pidfile;
static char* charset;
static char* p3p;
static int max_age;
static int read_timeout = READ_TIMEOUT;
static int write_timeout = WRITE_TIMEOUT;
static FILE* logfp;
static int listen_fd;
static int do_ssl;
static char* certfile;
static char* cipher;
static SSL_CTX* ssl_ctx;
static char cwd[MAXPATHLEN];
static int got_hup;

/* Request variables. */
static int conn_fd;
static SSL* ssl;
static usockaddr client_addr;
char* request;
size_t request_size, request_len, request_idx;
static char* method;
char* path;
static char* file;
static char* pathinfo;  /* the stuff after a file in filesystem */
struct stat sb;         /* single threaded so we can share stat buffer */
static char* query;
static char* protocol;
static int status;
static off_t bytes;
static char* req_hostname;

char* authorization;
size_t content_length;
static char* content_type;
static char* cookie;
static char* host;
static time_t if_modified_since;
static char* referer;
static char* useragent;
static char* paos;
static char* range;

char* remoteuser;

/* Forwards. */
static int initialize_listen_socket(usockaddr* usaP);
static void handle_request(void);
static void de_dotdot(char* file);
static int get_pathinfo(void);
static void do_file(void);
static void do_dir(void);
static void do_cgi(void);
static void cgi_interpose_input(int wfd);
static void cgi_interpose_output(int rfd, int parse_headers);
static char** make_argp(void);
static char** make_envp(void);
static void auth_check(char* dirname);
static char* virtual_file(char* file);
void send_error_and_exit(int s, char* title, char* extra_header, char* text);
void add_headers(int s, char* title, char* extra_header, char* me, char* mt, off_t b, time_t mod);
static void start_request(void);
void add_to_request(char* str, size_t len);
static char* get_request_line(void);
static void start_response(void);
static void send_via_write(int fd, off_t size, off_t start);
static void make_log_entry(void);
static void check_referer(void);

/* ------------- Error and syslog ----------- */

/* Called by:  add_password, main x18 */
static void usage(void) {
  (void) fprintf(stderr, "usage:  %s [-S certfile] [-Y cipher] [-p port] [-d dir] [-dd data_dir] [-c cgipat] [-u user] [-h hostname] [-r] [-v] [-l logfile] [-i pidfile] [-T charset] [-P P3P] [-M maxage] [-RT read_timeout_secs] [-WT write_timeout_secs] [-zx CONF]\n", argv0);
  exit(1);
}

/* Called by:  e_malloc, e_realloc, e_strdup */
static void die_oom() {
  syslog(LOG_CRIT, "out of memory");
  (void) fprintf(stderr, "%s: out of memory\n", argv0);
  exit(1);
}

/* Called by:  main x11, re_open_logfile */
static void die_perror(const char* what) {
#ifdef MINGW
  ERR("WSAGetLastError=%d", WSAGetLastError());
#endif
  perror(what);
  syslog(LOG_CRIT, "%s - %m", what);
  exit(1);
}

/* Called by:  initialize_listen_socket x4 */
static int ret_crit_perror(const char* what) {
  perror(what);
  syslog(LOG_CRIT, "%s - %m", what);
  return -1;
}

/* ------------- Memory alloc utils ----------- */

/* Called by:  add_to_buf, build_env, really_check_referer */
static void* e_malloc(size_t size) {
  void* ptr = malloc(size);
  if (!ptr) die_oom();
  return ptr;
}

/* Called by:  add_to_buf, build_env */
static void* e_realloc(void* optr, size_t size) {
  void* ptr = realloc(optr, size);
  if (!ptr) die_oom();
  return ptr;
}

/* Called by:  build_env, do_cgi */
static char* e_strdup(char* ostr) {
  char* str = strdup(ostr);
  if (!str) die_oom();
  return str;
}

/* ------------- decode ----------- */

/* Called by:  strdecode x2 */
static int hexit(char c) {
  if (c >= '0' && c <= '9')
    return c - '0';
  if (c >= 'a' && c <= 'f')
    return c - 'a' + 10;
  if (c >= 'A' && c <= 'F')
    return c - 'A' + 10;
  return 0;           /* shouldn't happen, we're guarded by isxdigit() */
}

/* Copies and decodes a string.  It's ok for from and to to be the same string. */
/* Called by:  handle_request, make_argp x2 */
static void strdecode(char* to, char* from) {
  for (; *from != '\0'; ++to, ++from) {
    if (from[0] == '%' && isxdigit(from[1]) && isxdigit(from[2]))
      {
	*to = hexit(from[1]) * 16 + hexit(from[2]);
	from += 2;
      }
    else
      *to = *from;
  }
  *to = '\0';
}

/* Called by:  auth_check */
static int b64_decode(const char* str, unsigned char* space, int size) {
  unsigned char* q;
  int len = strlen(str);
  if (SIMPLE_BASE64_PESSIMISTIC_DECODE_LEN(len)>size) {
    ERR("Decode might exceed the buffer: estimated=%d available size=%d",SIMPLE_BASE64_PESSIMISTIC_DECODE_LEN(len),size);
    return 0;
  }
  q = (unsigned char*)unbase64_raw(str, str+len, (char*)space, zx_std_index_64);
  return q-space;
}

#ifdef HAVE_SCANDIR
/* Called by:  file_details */
static void str_copy_and_url_encode(char* to, size_t tosize, const char* from) {
  int tolen;

  for (tolen = 0; *from != '\0' && tolen + 4 < tosize; ++from) {
    if (isalnum(*from) || strchr("/_.-~", *from)) {
      *to = *from;
      ++to;
      ++tolen;
    } else {
      (void) sprintf(to, "%%%02x", (int) *from & 0xff);
      to += 3;
      tolen += 3;
    }
  }
  *to = '\0';
}

/* Called by:  do_dir */
static char* file_details(const char* dir, const char* name) {
  char f_time[20];
  static char encname[1000];
  static char buf[2000];
  struct group* grp;

  (void) snprintf(buf, sizeof(buf), "%s/%s", dir, name);
  if (lstat(buf, &sb) < 0)
    return "???";
#if 0
  (void) strftime(f_time, sizeof(f_time), "%d%b%Y %H:%M", localtime(&sb.st_mtime));
  str_copy_and_url_encode(encname, sizeof(encname), name);
  (void) snprintf(buf, sizeof(buf), "<A HREF=\"%s\">%-32.32s</A>    %15s %14lld\n",
		  encname, name, f_time, (long long int)sb.st_size);
#else
  (void) strftime(f_time, sizeof(f_time), "%Y%m%d-%H:%Mz", gmtime(&sb.st_mtime));
  str_copy_and_url_encode(encname, sizeof(encname), name);
  grp = getgrgid(sb.st_gid);
  (void) snprintf(buf, sizeof(buf), "%15s %c%c %-8.8s %14lld <A HREF=\"%s\">%s</A>\n",
		  f_time,
		  sb.st_mode & S_IRGRP ? 'g' : '-',
		  sb.st_mode & S_IROTH ? 'o' : '-',
		  grp?grp->gr_name:"?",
		  (long long int)sb.st_size, encname, name);
#endif
  return buf;
}

#endif /* HAVE_SCANDIR */

/* ------------- Read Write Utils ----------- */

/* Called by:  cgi_interpose_input, handle_request, zxid_mini_httpd_read_post */
ssize_t conn_read(char* buf, size_t size) {
  DD("size=%d", size);
  if (do_ssl)
    size = SSL_read(ssl, buf, size);
  else
    size = read(conn_fd, buf, size);
  DD("got size=%d buf(%.*s)", size, MIN(size, 100), buf);
  return size;
}

/* Called by:  cgi_interpose_output x6, send_response, send_via_write x2, zxid_mini_httpd_wsp_response x2 */
ssize_t conn_write(char* buf, size_t size) {
  DD("size=%d buf(%.*s)", size, MIN(size, 100), buf);
  if (do_ssl)
    size = SSL_write(ssl, buf, size);
  else
    size = write(conn_fd, buf, size);
  DD("wrote size=%d", size);
  return size;
}

#ifdef HAVE_SENDFILE
/* Called by:  do_file */
static int conn_sendfile(int fd, size_t nbytes) {
#ifdef HAVE_LINUX_SENDFILE
  return sendfile(conn_fd, fd, 0, nbytes);
#else /* HAVE_LINUX_SENDFILE */
  return sendfile(fd, conn_fd, 0, nbytes, (struct sf_hdtr*) 0, (off_t*) 0, 0);
#endif /* HAVE_LINUX_SENDFILE */
}
#endif /* HAVE_SENDFILE */

/* ------------- Buffer manipulation ----------- */

/* Called by:  add_to_request, add_to_response, cgi_interpose_output x2, do_dir x4, zxid_mini_httpd_wsp_response */
void add_to_buf(char** bufP, size_t* bufsizeP, size_t* buflenP, char* str, size_t len) {
  if (!*bufsizeP) {
    *bufsizeP = len + 500;
    *buflenP = 0;
    *bufP = (char*) e_malloc(*bufsizeP);
  } else if (*buflenP + len >= *bufsizeP) {
    *bufsizeP = *buflenP + len + 500;
    *bufP = (char*) e_realloc((void*) *bufP, *bufsizeP);
  }
  (void) memmove(&((*bufP)[*buflenP]), str, len);
  *buflenP += len;
  (*bufP)[*buflenP] = '\0';
}


/* Called by:  handle_request */
static void start_request(void) {
  request_size = 0;
  request_idx = 0;
}

/* Called by:  handle_request, zxid_mini_httpd_read_post */
void add_to_request(char* str, size_t len) {
  add_to_buf(&request, &request_size, &request_len, str, len);
}

/* Called by:  handle_request x2 */
static char* get_request_line(void) {
  int i;
  char c;
  
  for (i = request_idx; request_idx < request_len; ++request_idx) {
    c = request[request_idx];
    if (c == '\012' || c == '\015')
      {
	request[request_idx] = '\0';
	++request_idx;
	if (c == '\015' && request_idx < request_len &&
	    request[request_idx] == '\012')
	  {
	    request[request_idx] = '\0';
	    ++request_idx;
	  }
	return &(request[i]);
      }
  }
  return 0;
}

static char* response;
static size_t response_size, response_len;

/* Called by:  add_headers */
static void start_response(void) {
  response_size = 0;
}

/* Called by:  add_headers x14, do_dir, send_error_and_exit x5, send_error_file, zxid_mini_httpd_sso */
void add_to_response(char* str, size_t len) {
  add_to_buf(&response, &response_size, &response_len, str, len);
}

/* Called by:  do_dir, do_file x2, send_error_and_exit, zxid_mini_httpd_sso */
void send_response(void) {
  (void) conn_write(response, response_len);
}

static void send_via_read_write(int fd, off_t size) {
  char buf[32*1024];
  ssize_t r, r2;
  
  for (;;) {
    r = read(fd, buf, sizeof(buf));
    if (r < 0 && (errno == EINTR || errno == EAGAIN)) {
      sleep(1);
      continue;
    }
    if (r <= 0)
      return;
    for (;;) {
      r2 = conn_write(buf, r);
      if (r2 < 0 && (errno == EINTR || errno == EAGAIN)) {
	sleep(1);
	continue;
      }
      if (r2 != r)
	return;
      break;
    }
  }
}

/*() Send file to connection.
 * Called if sendfile(2) is not available or SSL is used.
 * This function uses mmap(2) optimization for sending
 * plain files. If Range causes offset (start), then mmap(2)
 * is not used (even if by accident start would fall on page boundary). */

/* Called by:  do_file x2 */
static void send_via_write(int fd, off_t size, off_t start) {
#ifndef MINGW
  if (size <= SIZE_T_MAX && !start) {
    size_t size_size = (size_t) size;
    void* ptr = mmap(0, size_size, PROT_READ, MAP_PRIVATE, fd, 0);
    if (ptr != (void*) -1) {
#ifdef MADV_SEQUENTIAL
      /* If we have madvise, might as well call it.  Although sequential
      ** access is probably already the default. */
      (void) madvise(ptr, size_size, MADV_SEQUENTIAL|MADV_WILLNEED);
#endif /* MADV_SEQUENTIAL */
      (void) conn_write(ptr, size_size);
      (void) munmap(ptr, size_size);
    }
  } else
#endif
    /* mmap can't deal with files larger than 2GB. */
    send_via_read_write(fd, size);
}

/* ------------- name resolution & misc I/O tweaking ----------- */

/* Called by:  initialize_listen_socket */
static int sockaddr_check(usockaddr* usaP) {
  switch (usaP->sa.sa_family) {
  case AF_INET: return 1;
#ifdef USE_IPV6
  case AF_INET6: return 1;
#endif /* USE_IPV6 */
  default:
    return 0;
  }
}

/* Called by:  initialize_listen_socket, ntoa */
static size_t sockaddr_len(usockaddr* usaP) {
  switch (usaP->sa.sa_family) {
  case AF_INET: return sizeof(struct sockaddr_in);
#ifdef USE_IPV6
  case AF_INET6: return sizeof(struct sockaddr_in6);
#endif /* USE_IPV6 */
  default:
    return 0;	/* shouldn't happen */
  }
}

/* Called by:  main */
static void lookup_hostname(usockaddr* usa4P, size_t sa4_len, int* gotv4P, usockaddr* usa6P, size_t sa6_len, int* gotv6P) {
  (void) memset(usa4P, 0, sa4_len);
  usa4P->sa.sa_family = AF_INET;
  usa4P->sa_in.sin_addr.s_addr = htonl(INADDR_ANY);
  usa4P->sa_in.sin_port = htons(port);
  *gotv4P = 1;
  *gotv6P = 0; /* *** how do you bind INADDR_ANY for IP6? */
}

/* Called by:  auth_check, check_referer, do_dir, do_file x2, handle_read_timeout, handle_write_timeout, make_envp, make_log_entry, virtual_file */
static char* ntoa(usockaddr* usaP) {
#ifdef USE_IPV6
  static char str[200];
  if (getnameinfo(&usaP->sa, sockaddr_len(usaP), str, sizeof(str), 0, 0, NI_NUMERICHOST)) {
    str[0] = '?';
    str[1] = '\0';
  } else if (IN6_IS_ADDR_V4MAPPED(&usaP->sa_in6.sin6_addr) && !strncmp(str, "::ffff:", 7))
    (void) strcpy(str, &str[7]);     /* Elide IPv6ish prefix for IPv4 addresses. */

  return str;
#else /* USE_IPV6 */
  return inet_ntoa(usaP->sa_in.sin_addr);
#endif /* USE_IPV6 */
}

/* Called by:  main x2 */
static int initialize_listen_socket(usockaddr* usaP)
{
  int listen_fd, i=1;

  if (!sockaddr_check(usaP)) {
    syslog(LOG_ERR, "unknown sockaddr family on listen socket - %d", usaP->sa.sa_family);
    (void) fprintf(stderr, "%s: unknown sockaddr family on listen socket - %d\n",
		   argv0, usaP->sa.sa_family);
    return -1;
  }

  D("bind addr(%s) family=%d", ntoa(usaP), usaP->sa.sa_family);
  listen_fd = socket(usaP->sa.sa_family, SOCK_STREAM, 6 /* tcp */);
  if (listen_fd < 0) return ret_crit_perror("socket");
  (void) fcntl(listen_fd, F_SETFD, 1);  /* close on exec (FD_CLOEXEC) */
  if (setsockopt(listen_fd, SOL_SOCKET, SO_REUSEADDR, (void*) &i, sizeof(i)) < 0)
    return ret_crit_perror("setsockopt SO_REUSEADDR");
  if (bind(listen_fd, &usaP->sa, sockaddr_len(usaP)) < 0) return ret_crit_perror("bind");
  if (listen(listen_fd, 1024) < 0) return ret_crit_perror("listen");

#ifdef HAVE_ACCEPT_FILTERS
  {
    struct accept_filter_arg af;
    (void) bzero(&af, sizeof(af));
    (void) strcpy(af.af_name, ACCEPT_FILTER_NAME);
    (void) setsockopt(listen_fd, SOL_SOCKET, SO_ACCEPTFILTER, (char*) &af, sizeof(af));
  }
#endif /* HAVE_ACCEPT_FILTERS */
  return listen_fd;
}

/* Set NDELAY mode on a socket. */
/* Called by:  post_post_garbage_hack */
static void set_ndelay(int fd) {
  int flags, newflags;

  flags = fcntl(fd, F_GETFL, 0);
  if (flags != -1) {
    newflags = flags | (int) O_NDELAY;
    if (newflags != flags)
      (void) fcntl(fd, F_SETFL, newflags);
  }
}

/* Clear NDELAY mode on a socket. */
/* Called by:  post_post_garbage_hack */
static void clear_ndelay(int fd) {
  int flags, newflags;

  flags = fcntl(fd, F_GETFL, 0);
  if (flags != -1) {
    newflags = flags & ~ (int) O_NDELAY;
    if (newflags != flags)
      (void) fcntl(fd, F_SETFL, newflags);
  }
}

/* Special hack to deal with broken browsers that send a LF or CRLF
** after POST data, causing TCP resets - we just read and discard up
** to 2 bytes.  Unfortunately this doesn't fix the problem for CGIs
** which avoid the interposer process due to their POST data being
** short.  Creating an interposer process for all POST CGIs is
** unacceptably expensive. */
/* Called by:  cgi_interpose_input */
static void post_post_garbage_hack(void) {
  char buf[2];

  if (do_ssl)
    /* We don't need to do this for SSL, since the garbage has
    ** already been read.  Probably. */
    return;

  set_ndelay(conn_fd);
  (void)read(conn_fd, buf, sizeof(buf));
  clear_ndelay(conn_fd);
}

/* ------------- mime ----------- */

struct mime_entry {
  const char* ext;
  const char* val;
};
/* Keep tables in most likely first order*/
static const struct mime_entry enc_tab[] = {
{ "gz", "gzip" },
{ "Z", "compress" },
{ "uu", "x-uuencode" },
};
static const int n_enc_tab = sizeof(enc_tab) / sizeof(*enc_tab);
static const struct mime_entry typ_tab[] = {
{ "gif",  "image/gif" },
{ "png",  "image/png" },
{ "jpg",  "image/jpeg" },
{ "js",   "application/x-javascript" },
{ "css",  "text/css" },
{ "html", "text/html; charset=%s" },
{ "htm",  "text/html; charset=%s" },
{ "pdf",  "application/pdf" },
{ "ico",  "image/x-icon" },  /* image/vnd.microsoft.icon does not work in some versions of IE */
{ "jpeg", "image/jpeg" },
{ "jfif", "image/jpeg" },
{ "jpe", "image/jpeg" },
{ "pbm", "image/x-portable-bitmap" },
{ "pgm", "image/x-portable-graymap" },
{ "pnm", "image/x-portable-anymap" },
{ "ppm", "image/x-portable-pixmap" },
{ "xpm", "image/x-xpixmap" },
{ "svg", "image/svg+xml" },
{ "svgz", "image/svg+xml" },
{ "swf", "application/x-shockwave-flash" },
{ "xht", "application/xhtml+xml" },
{ "xhtml", "application/xhtml+xml" },
{ "xml", "text/xml" },
{ "xsl", "text/xml" },
{ "tif", "image/tiff" },
{ "tiff", "image/tiff" },
{ "vrml", "model/vrml" },
{ "rss", "application/rss+xml" },
{ "snd", "audio/basic" },
{ "wav", "audio/x-wav" },
{ "wmv", "video/x-ms-wmv" },
{ "avi", "video/x-msvideo" },
{ "mp2", "audio/mpeg" },
{ "mp3", "audio/mpeg" },
{ "mp4", "video/mp4" },
{ "mpe", "video/mpeg" },
{ "mpeg", "video/mpeg" },
{ "mpg", "video/mpeg" },
{ "mpga", "audio/mpeg" },
{ "ogg", "application/x-ogg" },
{ "mid", "audio/midi" },
{ "midi", "audio/midi" },
{ "mime", "message/rfc822" },
{ "mov", "video/quicktime" },
{ "movie", "video/x-sgi-movie" },
{ "class", "application/x-java-vm" },
{ "a",   "application/octet-stream" },
{ "lib", "application/octet-stream" },
{ "so",  "application/octet-stream" },
{ "o",   "application/octet-stream" },
{ "obj", "application/octet-stream" },
{ "bin", "application/octet-stream" },
{ "dll", "application/octet-stream" },
{ "exe", "application/octet-stream" },
{ "lha", "application/octet-stream" },
{ "lzh", "application/octet-stream" },
{ "tgz", "application/x-tar" },
{ "tar", "application/x-tar" },
{ "jar", "application/x-java-archive" },
{ "zip", "application/zip" },
{ "doc", "application/msword" },
{ "docx", "application/msword" },
{ "ppt",  "application/vnd.ms-powerpoint" },
{ "pptx", "application/vnd.ms-powerpoint" },
{ "xls", "application/vnd.ms-excel" },
{ "xlsx", "application/vnd.ms-excel" },
{ "crl", "application/x-pkcs7-crl" },
{ "crt", "application/x-x509-ca-cert" },
  /*#include "mime_types.h"*/
};
static const int n_typ_tab = sizeof(typ_tab) / sizeof(*typ_tab);

/* Figure out MIME encodings and type based on the filename.  Multiple
** encodings are separated by commas, and are listed in the order in
** which they were applied to the file.
*/
/* Called by:  do_file */
static const char* figure_mime(char* name, char* me, size_t me_size)
{
  char* prev_dot;
  char* dot;
  char* ext;
  int me_indexes[10];
  int n_me_indexes;
  size_t ext_len, me_len;
  int i, mei, len;
  const char* mime_type = "text/plain; charset=%s";

  /* Peel off encoding extensions until there aren't any more. */
  n_me_indexes = 0;
  for (prev_dot = name + strlen(name); ; prev_dot = dot) {
    for (dot = prev_dot - 1; dot >= name && *dot != '.'; --dot) ;
    if (dot < name) {
      /* No dot found.  No more encoding extensions, and no type extension either. */
      goto done;
    }
    ext = dot + 1;
    ext_len = prev_dot - ext;
    /* Search the encodings table.  Linear search is fine here, there are only a few entries. */
    for (i = 0; i < n_enc_tab; ++i) {
      /* name == file is nul terminated and ext is either nul or . terminated.
       * It is safe to do strncasecmp() */
      if (!strncasecmp(enc_tab[i].ext, ext, ext_len) && !enc_tab[i].ext[ext_len]) {
	if (n_me_indexes < sizeof(me_indexes)/sizeof(*me_indexes)) {
	  me_indexes[n_me_indexes] = i;
	  ++n_me_indexes;
	}
	goto continue_prevdot;
      }
    }
    break;  /* No encoding extension found.  Break and look for a type extension. */
    
  continue_prevdot: ;
  }
  
  /* Linear search, with most common assumed to be first. ext and ext_len from enc search. */
  for (i = 0; i < n_typ_tab; ++i) {
    /* name == file is nul terminated and ext is either nul or . terminated.
     * It is safe to do strncasecmp() */
    if (!strncasecmp(typ_tab[i].ext, ext, ext_len) && !typ_tab[i].ext[ext_len]) {
      mime_type = typ_tab[i].val;
      goto done;
    }
  }

 done:

  /* The last thing we do is actually generate the mime-encoding header in buffer me */
  me[0] = '\0';
  me_len = 0;
  for (i = n_me_indexes - 1; i >= 0; --i) {
    mei = me_indexes[i];
    len = strlen(enc_tab[mei].val);  /* was enc_tab[mei].val_len */
    if (me_len + len + 1 < me_size) {
      if (me[0] != '\0')
	me[me_len++] = ',';
      (void) strcpy(me+me_len, enc_tab[mei].val);
      me_len += len;
    }
  }
  
  return mime_type;
}

/* ------------- signal handling ----------- */

/* Called by: */
static void handle_sigterm(int sig) {
  /* Don't need to set up the handler again, since it's a one-shot. */

  syslog(LOG_NOTICE, "exiting due to signal %d", sig);
  (void) fprintf(stderr, "%s: exiting due to signal %d\n", argv0, sig);
  closelog();
  exit(1);
}

/* SIGHUP says to re-open the log file. */
/* Called by: */
static void handle_sighup(int sig) {
  const int oerrno = errno;

#ifndef HAVE_SIGSET
  /* Set up handler again. */
  (void) signal(SIGHUP, handle_sighup);
#endif /* ! HAVE_SIGSET */

  /* Just set a flag that we got the signal. */
  got_hup = 1;
	
  /* Restore previous errno. */
  errno = oerrno;
}

#ifndef MINGW
/* Called by: */
static void handle_sigchld(int sig) {
  const int oerrno = errno;
  pid_t pid;
  int status;

#ifndef HAVE_SIGSET
  /* Set up handler again. */
  (void) signal(SIGCHLD, handle_sigchld);
#endif /* ! HAVE_SIGSET */

  /* Reap defunct children until there aren't any more. */
  for (;;) {
#ifdef HAVE_WAITPID
    pid = waitpid((pid_t) -1, &status, WNOHANG);
#else /* HAVE_WAITPID */
    pid = wait3(&status, WNOHANG, (struct rusage*) 0);
#endif /* HAVE_WAITPID */
    if ((int) pid == 0)		/* none left */
      break;
    if ((int) pid < 0)
      {
	if (errno == EINTR || errno == EAGAIN)
	  continue;
	/* ECHILD shouldn't happen with the WNOHANG option,
	** but with some kernels it does anyway.  Ignore it.
	*/
	if (errno != ECHILD) {
	  perror("child wait");
	  syslog(LOG_ERR, "child wait - %m");
	}
	break;
      }
  }

  /* Restore previous errno. */
  errno = oerrno;
}
#endif

/* Called by:  main x2 */
static void re_open_logfile(void) {
  if (logfp != (FILE*) 0) {
    (void) fclose(logfp);
    logfp = (FILE*) 0;
  }
  if (logfile) {
    syslog(LOG_NOTICE, "(re)opening logfile");
    logfp = fopen(logfile, "a");
    if (logfp == (FILE*) 0) die_perror(logfile);
  }
}

/* Called by: */
static void handle_read_timeout(int sig) {
  syslog(LOG_INFO, "%.80s connection timed out reading", ntoa(&client_addr));
  send_error_and_exit(408, "Request Timeout", "",
		      "No request appeared within a reasonable time period.");
}

/* Called by: */
static void handle_write_timeout(int sig) {
  syslog(LOG_INFO, "%.80s connection timed out writing", ntoa(&client_addr));
  exit(1);
}

/* Called by:  main */
static void init_catch_sigs() {
#ifdef HAVE_SIGSET
  (void) sigset(SIGTERM, handle_sigterm);
  (void) sigset(SIGINT, handle_sigterm);
  (void) sigset(SIGUSR1, handle_sigterm);
  (void) sigset(SIGHUP, handle_sighup);
  (void) sigset(SIGCHLD, handle_sigchld);
  (void) sigset(SIGPIPE, SIG_IGN);
#else /* HAVE_SIGSET */
  (void) signal(SIGTERM, handle_sigterm);
  (void) signal(SIGINT, handle_sigterm);
#ifndef MINGW
  (void) signal(SIGUSR1, handle_sigterm);
  (void) signal(SIGCHLD, handle_sigchld);
#endif
  (void) signal(SIGHUP, handle_sighup);
  (void) signal(SIGPIPE, SIG_IGN);
#endif /* HAVE_SIGSET */
  got_hup = 0;
}

/* =================== M A I N =================== */

/* Called by: */
int main(int argc, char** av)
{
  struct passwd* pwd;
  uid_t uid = 32767;
  gid_t gid = 32767;
  usockaddr host_addr4;
  usockaddr host_addr6;
  int gotv4, gotv6;
  usockaddr usa;
  socklen_t sz;
  int an, r;
  char* cp;
  
  argv0 = av[0];
  port = 0;
  dir = 0;
  data_dir = 0;
  do_chroot = 0;
  vhost = 0;
  cgi_pattern = 0;
  url_pattern = 0;
  no_empty_referers = 0;
  local_pattern = 0;
  charset = MINI_DEFAULT_CHARSET;
  p3p = 0;
  max_age = -1;
  user = DEFAULT_USER;
  hostname = 0;
  logfile = 0;
  pidfile = 0;
  logfp = 0;
  do_ssl = 0;
  cipher = 0;
  memset(&usa, 0, sizeof(usa));  /* *** avoid valgrind complaints */

  /* Parse args. */
  for (an = 1; an < argc && av[an][0] == '-'; ++an) {
#ifdef MINGW
    if (!strcmp(av[an], "-child")) {
      /* Child process to handle request. */
      client_addr = usa;
      handle_request();
      exit(0);
    }
    if (!strcmp(av[an], "-cgiin-child")) {
      /* Child process to handle cgi input: shuffle input from conn_fd to write end of pipeA */
      conn_fd = atoll(av[an+1]);
      cgi_interpose_input(atoll(av[an+3]));
    }
    if (!strcmp(av[an], "-cgiout-child")) {
      /* Child process to handle cgi output: shuffle output from read end of pipeB to conn_fd */
      conn_fd = atoll(av[an+1]);
      cgi_interpose_output(atoll(av[an+2]), 1);
    }
#endif
    if (!strcmp(av[an], "-V")) {
      (void) printf("%s\n", SERVER_SOFTWARE);
      exit(0);
    }
    if (!strcmp(av[an], "-D")) ++errmac_debug; /* zxid_httpd runs always in -D mode */
    else if (!strcmp(av[an], "-S") && an + 1 < argc)  { ++an; certfile = av[an]; do_ssl = 1; }
    else if (!strcmp(av[an], "-Y") && an + 1 < argc)  { ++an; cipher = av[an]; }
    else if (!strcmp(av[an], "-zx") && an + 1 < argc) { ++an; zxid_conf_str = av[an]; }
    else if (!strcmp(av[an], "-RT") && an + 1 < argc) { ++an; read_timeout = atoi(av[an]); }
    else if (!strcmp(av[an], "-WT") && an + 1 < argc) { ++an; write_timeout = atoi(av[an]); }
    else if (!strcmp(av[an], "-p") && an + 1 < argc)  { ++an; port =(unsigned short)atoi(av[an]); }
    else if (!strcmp(av[an], "-d") && an + 1 < argc)  { ++an; dir = av[an]; }
    else if (!strcmp(av[an], "-dd") && an + 1 < argc) { ++an; data_dir = av[an]; }
    else if (!strcmp(av[an], "-c") && an + 1 < argc)  { ++an; cgi_pattern = av[an]; }
    else if (!strcmp(av[an], "-u") && an + 1 < argc)  { ++an; user = av[an]; }
    else if (!strcmp(av[an], "-h") && an + 1 < argc)  { ++an; hostname = av[an]; }
    else if (!strcmp(av[an], "-r")) do_chroot = 1;
    else if (!strcmp(av[an], "-v")) vhost = 1;
    else if (!strcmp(av[an], "-l") && an + 1 < argc)  { ++an; logfile = av[an]; }
    else if (!strcmp(av[an], "-i") && an + 1 < argc)  { ++an; pidfile = av[an]; }
    else if (!strcmp(av[an], "-T") && an + 1 < argc)  { ++an; charset = av[an]; }
    else if (!strcmp(av[an], "-P") && an + 1 < argc)  { ++an; p3p = av[an]; }
    else if (!strcmp(av[an], "-M") && an + 1 < argc)  { ++an; max_age = atoi(av[an]); }
    else usage();
  }
  if (an != argc) usage();
  
  cp = strrchr(argv0, '/');
  if (cp)
    ++cp;
  else
    cp = argv0;
  openlog(cp, LOG_NDELAY|LOG_PID, LOG_DAEMON);

  if (!port) {
    if (do_ssl)
      port = DEFAULT_HTTPS_PORT;
    else
      port = DEFAULT_HTTP_PORT;
  }
  snprintf(server_port_buf, sizeof(server_port_buf), "SERVER_PORT=%d", port);
  putenv(server_port_buf);

#ifndef MINGW
  /* If we're root and we're going to become another user, get the uid/gid now. */
  if (!getuid()) {
    pwd = getpwnam(user);
    if (pwd == (struct passwd*) 0) {
      syslog(LOG_CRIT, "unknown user - '%s'", user);
      (void) fprintf(stderr, "%s: unknown user - '%s'\n", argv0, user);
      exit(1);
    }
    uid = pwd->pw_uid;
    gid = pwd->pw_gid;
  }
#endif

  /* Log file. */
  if (logfile) {
    re_open_logfile();
    if (logfile[0] != '/') {
      syslog(LOG_WARNING, "logfile is not an absolute path, you may not be able to re-open it");
      (void) fprintf(stderr, "%s: logfile is not an absolute path, you may not be able to re-open it\n", argv0);
    }
#ifndef MINGW
    if (!getuid()) {
      /* If we are root then we chown the log file to the user we'll
      ** be switching to.
      */
      if (fchown(fileno(logfp), uid, gid) < 0) {
	perror("fchown logfile");
	syslog(LOG_WARNING, "fchown logfile - %m");
      }
    }
#endif
  }

  /* Look up hostname. */
  lookup_hostname(&host_addr4, sizeof(host_addr4), &gotv4,
		  &host_addr6, sizeof(host_addr6), &gotv6);
  if (!hostname) {
    (void) gethostname(hostname_buf, sizeof(hostname_buf));
    hostname_buf[sizeof(hostname_buf)-1]=0;
    hostname = hostname_buf;
  }
  if (! (gotv4 || gotv6)) {
    syslog(LOG_CRIT, "can't find any valid address");
    (void) fprintf(stderr, "%s: can't find any valid address\n", argv0);
    exit(1);
  }

  /* Initialize listen sockets.  Try v6 first because of a Linux peculiarity;
  ** like some other systems, it has magical v6 sockets that also listen for
  ** v4, but in Linux if you bind a v4 socket first then the v6 bind fails. */
  if (gotv6)
    listen_fd = initialize_listen_socket(&host_addr6);
  else if (gotv4)
    listen_fd = initialize_listen_socket(&host_addr4);
  else
    listen_fd = -1;
  /* If we didn't get any valid sockets, fail. */
  if (listen_fd == -1) {
    D("gotv4=%d gotv6=%d  ip4(%s) ip6(%s)", gotv4, gotv6, ntoa(&host_addr4), ntoa(&host_addr6));
    die_perror("listen(2): can't bind to any address");
  }

  if (do_ssl)	{
    SSL_load_error_strings();
    SSLeay_add_ssl_algorithms();
    ssl_ctx = SSL_CTX_new(SSLv23_server_method());
    if (certfile[0] != '\0')
      if (!SSL_CTX_use_certificate_file(ssl_ctx, certfile, SSL_FILETYPE_PEM) ||
	  !SSL_CTX_use_PrivateKey_file(ssl_ctx, certfile, SSL_FILETYPE_PEM) ||
	  !SSL_CTX_check_private_key(ssl_ctx)) {
	ERR_print_errors_fp(stderr);
	exit(1);
      }
    if (cipher) {
      if (!SSL_CTX_set_cipher_list(ssl_ctx, cipher)) {
	ERR_print_errors_fp(stderr);
	exit(1);
      }
    }
  }
  
#ifdef HAVE_SETSID
  /* Even if we don't daemonize, we still want to disown our parent
  ** process.
  */
  (void) setsid();
#endif /* HAVE_SETSID */

  if (pidfile) {
    /* Write the PID file. */
    FILE* pidfp = fopen(pidfile, "w");
    if (pidfp == (FILE*) 0) die_perror(pidfile);
    (void) fprintf(pidfp, "%d\n", (int) getpid());
    (void) fclose(pidfp);
  }
  
#ifndef MINGW
  /* If we're root, start becoming someone else. */
  if (!getuid()) {
    /* Set aux groups to null. */
    if (setgroups(0, (gid_t*) 0) < 0) die_perror("setgroups");
    /* Set primary group. */
    if (setgid(gid) < 0) die_perror("setgid");
    /* Try setting aux groups correctly - not critical if this fails. */
    if (initgroups(user, gid) < 0) {
      perror("initgroups");
      syslog(LOG_ERR, "initgroups - %m");
    }
#ifdef HAVE_SETLOGIN
    /* Set login name. */
    (void) setlogin(user);
#endif /* HAVE_SETLOGIN */
  }
#endif /* !MINGW */

  /* Switch directories if requested. */
  if (dir) {
    if (chdir(dir) < 0) die_perror("chdir");
  }

  /* Get current directory. */
  (void) getcwd(cwd, sizeof(cwd) - 1);
  if (cwd[strlen(cwd) - 1] != '/')
    (void) strcat(cwd, "/");

#ifndef MINGW
  /* Chroot if requested. */
  if (do_chroot) {
    if (chroot(cwd) < 0) die_perror("chroot");
    /* If we are logging and the logfile's pathname begins with the
    ** chroot tree's pathname, then elide the chroot pathname so
    ** that the logfile pathname still works from inside the chroot tree. */
    if (logfile)
      if (!strncmp(logfile, cwd, strlen(cwd))) {
	(void) strcpy(logfile, &logfile[strlen(cwd) - 1]);
	/* (We already guaranteed that cwd ends with a slash, so leaving
	** that slash in logfile makes it an absolute pathname within
	** the chroot tree.) */
      } else {
	syslog(LOG_WARNING, "logfile is not within the chroot tree, you will not be able to re-open it");
	(void) fprintf(stderr, "%s: logfile is not within the chroot tree, you will not be able to re-open it\n", argv0);
      }
    (void) strcpy(cwd, "/");
    /* Always chdir to / after a chroot. */
    if (chdir(cwd) < 0) die_perror("chroot chdir");
  }
#endif
  
  /* Switch directories again if requested. */
  if (data_dir) {
    if (chdir(data_dir) < 0) die_perror("data_dir chdir");
  }

#ifndef MINGW
  /* If we're root, become someone else. */
  if (!getuid()) {
    /* Set uid. */
    if (setuid(uid) < 0) die_perror("setuid");
    /* Check for unnecessary security exposure. */
    if (! do_chroot) {
      syslog(LOG_WARNING,
	     "started as root without requesting chroot(), warning only");
      (void)fprintf(stderr, "%s: started as root without chroot(), warning only\n", argv0);
    }
  }
#endif

  init_catch_sigs();

  syslog(LOG_NOTICE, "%.80s starting on %.80s, port %d", SERVER_SOFTWARE, hostname?hostname:"0.0.0.0", (int) port);

  /* ----- Main loop ----- */
  for (;;) {
    if (got_hup) {           /* Do we need to re-open the log file? */
      re_open_logfile();
      got_hup = 0;
    }

    sz = sizeof(usa);        /* Accept the new connection (blocks). */
    conn_fd = accept(listen_fd, &usa.sa, &sz);
    if (conn_fd < 0) {
      if (errno == EINTR || errno == EAGAIN)
	continue;	/* try again */
#ifdef EPROTO
      if (errno == EPROTO)
	continue;	/* try again */
#endif
      die_perror("accept");
    }

    /* Fork a sub-process to handle the connection, see handle_request() */
#ifdef MINGW
    /* *** determine whole path. For now we assume working directory contains mini_httpd */
    r = spawnlp(P_NOWAIT, ".", argv0, "-child");
    /* Parent comes here. child is processed where option -child is processed. */
    if (r) {
      perror("spawnlp");
      ERR("spawn failed to create subprocess to handle connection. r=%d errno=%d %s",r,errno,STRERROR(errno));
      exit(1);
    }
    close(conn_fd);
#else
    r = fork();
    if (r < 0) die_perror("fork");
    if (!r) {
      /* Child process. */
      DD("child for handle_request() conn_fd=%d", conn_fd);
      client_addr = usa;
      if (listen_fd != -1)
	(void) close(listen_fd);
      handle_request();
      exit(0);
    }
    (void) close(conn_fd);
#endif
  }
}

/*() This runs in a child process, and exits when done, so cleanup is not needed. */
/* Called by:  main x2 */
static void handle_request(void)
{
  char* method_str;
  char* line;
  char* cp;
  int ret, file_len, i;
  const char* index_names[] = {
    "index.html", "index.htm", "index.xhtml", "index.xht", "Default.htm",
    "index.cgi" };
  char cwdbuf[1024];

  /* Set up the timeout for reading. */
#ifdef HAVE_SIGSET
  (void) sigset(SIGALRM, handle_read_timeout);
#else /* HAVE_SIGSET */
  (void) signal(SIGALRM, handle_read_timeout);
#endif /* HAVE_SIGSET */
  (void) alarm(read_timeout);

  /* Initialize the request variables. */
  remoteuser = 0;
  method = "UNKNOWN";
  path = 0;
  file = 0;
  pathinfo = 0;
  query = "";
  protocol = 0;
  status = 0;
  bytes = -1;
  req_hostname = 0;

  authorization = 0;
  content_type = 0;
  content_length = -1;
  cookie = 0;
  host = 0;
  if_modified_since = (time_t) -1;
  referer = "";
  useragent = "";
  paos = "";

#ifdef TCP_NOPUSH
  /* Set the TCP_NOPUSH socket option, to try and avoid the 0.2 second
  ** delay between sending the headers and sending the data.  A better
  ** solution is writev() (as used in thttpd), or send the headers with
  ** send(MSG_MORE) (only available in Linux so far). */
  i = 1;
  (void) setsockopt(conn_fd, IPPROTO_TCP, TCP_NOPUSH, (void*) &i, sizeof(i));
#endif /* TCP_NOPUSH */

  if (do_ssl) {
    ssl = SSL_new(ssl_ctx);
    SSL_set_fd(ssl, conn_fd);
    if (!SSL_accept(ssl)) {
      ERR_print_errors_fp(stderr);
      exit(1);
    }
  }

  /* Read in the request. */
  start_request();
  for (;;) {
    char buf[10000];
    int got = conn_read(buf, sizeof(buf));
    if (got < 0 && (errno == EINTR || errno == EAGAIN))
      continue;
    if (got <= 0)
      break;
    (void) alarm(read_timeout);
    add_to_request(buf, got);
    if (strstr(request, "\015\012\015\012") || strstr(request, "\012\012"))
      break;  /* Empty line ending headers detected. */
  }

  /* Parse the first line of the request. */
  method_str = get_request_line();
  if (!method_str) send_error_and_exit(400, "Bad Request", "", "Can't parse request. 1");
  path = strpbrk(method_str, " \t\012\015");
  if (!path)       send_error_and_exit(400, "Bad Request", "", "Can't parse request. 2");
  *path++ = '\0';
  path += strspn(path, " \t\012\015");
  protocol = strpbrk(path, " \t\012\015");
  if (!protocol)   send_error_and_exit(400, "Bad Request", "", "Can't parse request. 3");
  *protocol++ = '\0';
  protocol += strspn(protocol, " \t\012\015");
  query = strchr(path, '?');
  if (!query)
    query = "";
  else
    *query++ = '\0';

  /* Parse the rest of the request headers. */
  while (line = get_request_line()) {
    if (line[0] == '\0')
      break;
    else if (!strncasecmp(line, "Authorization:", 14)) {
      cp = &line[14];
      cp += strspn(cp, " \t");
      authorization = cp;
    } else if (!strncasecmp(line, "Content-Length:", 15)) {
      cp = &line[15];
      cp += strspn(cp, " \t");
      content_length = atol(cp);
    } else if (!strncasecmp(line, "Content-Type:", 13)) {
      cp = &line[13];
      cp += strspn(cp, " \t");
      content_type = cp;
    } else if (!strncasecmp(line, "Cookie:", 7)) {
      cp = &line[7];
      cp += strspn(cp, " \t");
      cookie = cp;
    } else if (!strncasecmp(line, "Host:", 5)) {
      cp = &line[5];
      cp += strspn(cp, " \t");
      host = cp;
      if (strchr(host, '/') || host[0] == '.')
	send_error_and_exit(400, "Bad Request", "", "Can't parse request.");
    } else if (!strncasecmp(line, "If-Modified-Since:", 18)) {
      cp = &line[18];
      cp += strspn(cp, " \t");
      if_modified_since = tdate_parse(cp);
    } else if (!strncasecmp(line, "Referer:", 8)) {
      cp = &line[8];
      cp += strspn(cp, " \t");
      referer = cp;
    } else if (!strncasecmp(line, "User-Agent:", 11)) {
      cp = &line[11];
      cp += strspn(cp, " \t");
      useragent = cp;
    } else if (!strncasecmp(line, "Range:", 6)) {
      cp = &line[11];
      cp += strspn(cp, " \t");
      range = cp;
    } else if (!strncasecmp(line, "PAOS:", 5)) {
      cp = &line[11];
      cp += strspn(cp, " \t");
      paos = cp;
    }
  }

  if (     !strcasecmp(method_str, "GET"))  method = "GET";
  else if (!strcasecmp(method_str, "HEAD")) method = "HEAD";
  else if (!strcasecmp(method_str, "POST")) method = "POST";
  else
    send_error_and_exit(501, "Not Implemented", "", "That method is not implemented.");

  strdecode(path, path);
  if (path[0] != '/')
    send_error_and_exit(400, "Bad Request", "", "Bad filename.");
  file = &(path[1]);
  de_dotdot(file);
  if (file[0] == '\0')
    file = "./";
  if (file[0] == '/' ||
      (file[0] == '.' && file[1] == '.' &&
       (file[2] == '\0' || file[2] == '/')))
    send_error_and_exit(400, "Bad Request", "", "Illegal filename.");
  if (vhost)
    file = virtual_file(file);

  /* Set up the timeout for writing. */
#ifdef HAVE_SIGSET
  (void) sigset(SIGALRM, handle_write_timeout);
#else /* HAVE_SIGSET */
  (void) signal(SIGALRM, handle_write_timeout);
#endif /* HAVE_SIGSET */
  (void) alarm(write_timeout);

  if (zxid_conf_str) {
    /* We recreate the configuration every time. This is to allow
     * features such as virtual hosting (VPATH and VURL) to work. */
    snprintf(http_host_buf, sizeof(http_host_buf), "HTTP_HOST=%s",
	     host?host:(req_hostname?req_hostname:(hostname?hostname:"UNKNOWN_HOST")));
    putenv(http_host_buf);
    snprintf(script_name_buf, sizeof(script_name_buf), "SCRIPT_NAME=%s", path);
    putenv(script_name_buf);
    strcpy(errmac_instance, CC_GREENY("\tminizx"));
    zxid_cf = zxid_new_conf_to_cf(zxid_conf_str);

    /* Since the filter may read rest of the post data, request buffer
     * may be reallocated, thus invalidating old pointers. Make copies
     * to stay safe. */
    protocol = strdup(protocol);
    path = strdup(path);
    file = strdup(file);
    query = strdup(query);
    if (authorization) authorization = strdup(authorization);
    if (content_type)  content_type  = strdup(content_type);
    if (cookie)    cookie = strdup(cookie);
    if (host)      host = strdup(host);
    if (referer)   referer = strdup(referer);
    if (useragent) useragent = strdup(useragent);
    if (paos)      paos = strdup(paos);
    zxid_session = zxid_mini_httpd_filter(zxid_cf, method, path, query, cookie);
  }

  ret = stat(file, &sb);
  D("handle request stat(%s)=%d st_mode=%o cwd(%s)", file, ret, sb.st_mode, getcwd(cwdbuf, sizeof(cwdbuf)));
  if (ret < 0)
    ret = get_pathinfo();
  if (ret < 0)
    send_error_and_exit(404, "Not Found", "", "File not found. 1");
  file_len = strlen(file);
  if (! S_ISDIR(sb.st_mode)) {
    /* Not a directory. */
    for (; file[file_len - 1] == '/'; --file_len)
      file[file_len - 1] = '\0';
    do_file();  /* also handles CGI */
  } else {
    char idx[10000];
    
    /* The filename is a directory.  Is it missing the trailing slash? */
    if (file[file_len - 1] != '/' && !pathinfo) {
      char location[10000];
      if (query[0] != '\0')
	(void) snprintf(location, sizeof(location), "Location: %s/?%s", path, query);
      else
	(void) snprintf(location, sizeof(location), "Location: %s/", path);
      send_error_and_exit(302, "Found", location, "Directories must end with a slash.");
    }

    /* Check for an index file. */
    for (i = 0; i < sizeof(index_names) / sizeof(char*); ++i) {
      (void) snprintf(idx, sizeof(idx), "%s%s", file, index_names[i]);
      if (stat(idx, &sb) >= 0) {
	file = idx;
	do_file();
	goto got_one;
      }
    }

    /* Nope, no index file, so it's an actual directory request. */
    do_dir();

  got_one: ;
  }
  
  SSL_free(ssl);
}

/* Called by:  handle_request */
static void de_dotdot(char* file)
{
  char* cp;
  char* cp2;
  int l;

  /* Collapse any multiple / sequences. */
  while (cp = strstr(file, "//")) {
    for (cp2 = cp + 2; *cp2 == '/'; ++cp2)
      continue;
    (void) strcpy(cp + 1, cp2);
  }

  /* Remove leading ./ and any /./ sequences. */
  while (!strncmp(file, "./", 2))
    (void) strcpy(file, file + 2);
  while (cp = strstr(file, "/./"))
    (void) strcpy(cp, cp + 2);

  /* Alternate between removing leading ../ and removing xxx/../ */
  for (;;) {
    while (!strncmp(file, "../", 3))
      (void) strcpy(file, file + 3);
    if (!(cp = strstr(file, "/../")))
      break;
    for (cp2 = cp - 1; cp2 >= file && *cp2 != '/'; --cp2)
      continue;
    (void) strcpy(cp2 + 1, cp + 4);
  }

  /* Also elide any xxx/.. at the end. */
  while ((l = strlen(file)) > 3 && !strcmp((cp = file + l - 3), "/..")) {
    for (cp2 = cp - 1; cp2 >= file && *cp2 != '/'; --cp2)
      continue;
    if (cp2 < file)
      break;
    *cp2 = '\0';
  }
}

/*() Walk file name buffer backwards to extract the longest
 * prefix that corresponds to stat'able file. Anything
 * beyond this is considered PATH_INFO. */

/* Called by:  handle_request */
static int get_pathinfo(void) {
  int r;
  pathinfo = file+strlen(file);
  for (;;) {
    do {
      --pathinfo;
      if (pathinfo <= file) {
	pathinfo = 0;
	return -1;      /* exhausted file without finding slash or pathinfo */
      }
    } while (*pathinfo != '/');
    *pathinfo = '\0';   /* nul terminate file */
    r = stat(file, &sb);
    if (r >= 0) {
      ++pathinfo;       /* pathinfo is the part of the path after matching file */
      return r;
    } else
      *pathinfo = '/';  /* restore slash */
  }
}

/* Called by:  handle_request x2 */
static void do_file(void) {
  char buf[10000];
  char mime_encodings[500];
  const char* mime_type;
  char fixed_mime_type[500];
  char* cp;
  int fd,len, rstart=-1, rend=-1;

  /* Check authorization for this directory. */
  (void) strncpy(buf, file, sizeof(buf));
  cp = strrchr(buf, '/');
  if (!cp)
    (void) strcpy(buf, ".");
  else
    *cp = '\0';
  auth_check(buf);

  /* Check if the filename is the AUTH_FILE itself - that's verboten. */
  len = strlen(file);
  if (len >= sizeof(AUTH_FILE)-1
      &&(!strcmp(file, AUTH_FILE) ||
	 (!strcmp(&(file[len - sizeof(AUTH_FILE) + 1]), AUTH_FILE) &&
	  file[len - sizeof(AUTH_FILE)] == '/'))) {
    syslog(LOG_NOTICE, "%.80s URL \"%.80s\" tried to retrieve an auth file",
	   ntoa(&client_addr), path);
    send_error_and_exit(403, "Forbidden", "", "File is protected. 1");
  }

  check_referer();

  if (cgi_pattern && zx_match(cgi_pattern, file)) {  /* Is it CGI? */
    do_cgi();
    return;
  }
  if (pathinfo)
    send_error_and_exit(404, "Not Found", "", "File not found. 2");

  fd = open(file, O_RDONLY);
  if (fd < 0) {
    syslog(LOG_INFO, "%.80s File \"%.80s\" is protected", ntoa(&client_addr), path);
    send_error_and_exit(403, "Forbidden", "", "File is protected. 2");
  }
  mime_type = figure_mime(file, mime_encodings, sizeof(mime_encodings));
  (void) snprintf(fixed_mime_type, sizeof(fixed_mime_type), mime_type, charset);
  if (if_modified_since != (time_t) -1 &&
      if_modified_since >= sb.st_mtime) {
    add_headers(304, "Not Modified", "", mime_encodings, fixed_mime_type,
		(off_t) -1, sb.st_mtime);
    send_response();
    return;
  }
  if (range) {
    sscanf(range, " bytes=%d-%d", &rstart, &rend);
    if (rstart > sb.st_size)
      send_error_and_exit(416, "Request Range Not Satisfiable", "", "Start of Range is beyond end of file");
    if (ONE_OF_2(rend, 0, -1) || rend >= sb.st_size)
      rend = sb.st_size-1;
    if (rstart == -1)
      rstart = sb.st_size - rend;
    if (rstart == 0 && rend == sb.st_size-1) {
      D("Range %d-%d includes whole file", rstart, rend);
      add_headers(200, "Ok", "", mime_encodings, fixed_mime_type, sb.st_size, sb.st_mtime);
    } else {
      D("206 Content-Range %d-%d/%d", rstart, rend, (int)sb.st_size);
      sprintf(buf, "Content-Range: %d-%d/%lld", rstart, rend, (long long int)sb.st_size);
      add_headers(206, "Partial Content", buf, mime_encodings, fixed_mime_type,
		  rend-rstart+1, sb.st_mtime);
      lseek(fd, rstart, SEEK_SET);
    }
  } else {
    rstart = 0;
    rend = sb.st_size-1;
    add_headers(200, "Ok", "", mime_encodings, fixed_mime_type, sb.st_size, sb.st_mtime);
  }
  send_response();
  if (*method == 'H' /* HEAD */)
    return;

  if (sb.st_size > 0) {	/* ignore zero-length files */
#ifdef HAVE_SENDFILE
    if (do_ssl)
      send_via_write(fd, rend-rstart+1, rstart);
    else
      (void) conn_sendfile(fd, rend-rstart+1);
#else
    send_via_write(fd, rend-rstart+1, rstart);
#endif
  }

  (void) close(fd);
}


/* Called by:  handle_request */
static void do_dir(void)
{
  char buf[10000];
  size_t buflen;
  char* contents;
  size_t contents_size, contents_len;
#ifdef HAVE_SCANDIR
  int n, i;
  struct dirent **dl;
  char* name_info;
#else /* HAVE_SCANDIR */
  char command[10000];
  FILE* fp;
#endif /* HAVE_SCANDIR */
  
  if (pathinfo)
    send_error_and_exit(404, "Not Found", "", "File not found. 3");

  auth_check(file);
  check_referer();

#ifdef HAVE_SCANDIR
  n = scandir(file, &dl, NULL, alphasort);
  if (n < 0) {
    syslog(LOG_INFO, "%.80s Directory \"%.80s\" is protected", ntoa(&client_addr), path);
    send_error_and_exit(403, "Forbidden", "", "Directory is protected.");
  }
#endif /* HAVE_SCANDIR */

  contents_size = 0;
  buflen = snprintf(buf, sizeof(buf), "<TITLE>Index of %s</TITLE>\n\
<BODY BGCOLOR=\"#99cc99\" TEXT=\"#000000\" LINK=\"#2020ff\" VLINK=\"#4040cc\">\n\
<H4>Index of %s</H4>\n\
<PRE>\n", file, file);
  add_to_buf(&contents, &contents_size, &contents_len, buf, buflen);

#ifdef HAVE_SCANDIR
  for (i = 0; i < n; ++i) {
    name_info = file_details(file, dl[i]->d_name);
    add_to_buf(&contents, &contents_size, &contents_len, name_info, strlen(name_info));
  }
#else /* HAVE_SCANDIR */
      /* Magic HTML ls command! */
  if (!strchr(file, '\'')) {
    (void) snprintf(command, sizeof(command),
		    "ls -lgF '%s' | tail +2 | sed -e 's/^\\([^ ][^ ]*\\)\\( *[^ ][^ ]*  *[^ ][^ ]*  *[^ ][^ ]*\\)\\( *[^ ][^ ]*\\)  *\\([^ ][^ ]*  *[^ ][^ ]*  *[^ ][^ ]*\\)  *\\(.*\\)$/\\1 \\3  \\4  |\\5/' -e '/ -> /!s,|\\([^*]*\\)$,|<A HREF=\"\\1\">\\1</A>,' -e '/ -> /!s,|\\(.*\\)\\([*]\\)$,|<A HREF=\"\\1\">\\1</A>\\2,' -e '/ -> /s,|\\([^@]*\\)\\(@* -> \\),|<A HREF=\"\\1\">\\1</A>\\2,' -e 's/|//'",
		    file);
    fp = popen(command, "r");
    for (;;) {
      size_t r;
      r = fread(buf, 1, sizeof(buf), fp);
      if (!r)
	break;
      add_to_buf(&contents, &contents_size, &contents_len, buf, r);
    }
    (void) pclose(fp);
  }
#endif /* HAVE_SCANDIR */

  buflen = snprintf(buf, sizeof(buf), "</PRE>\n<HR>\n<ADDRESS><A HREF=\"%s\">%s</A></ADDRESS>\n",
		    SERVER_URL, SERVER_SOFTWARE);
  add_to_buf(&contents, &contents_size, &contents_len, buf, buflen);

  add_headers(200, "Ok", "", "", "text/html; charset=%s", contents_len, sb.st_mtime);
  if (*method != 'H' /*HEAD*/)
    add_to_response(contents, contents_len);
  send_response();
}

/* Called by:  do_cgi x2 */
static int pipe_and_fork(int* p, const char* next_step_flag) {
  int ret;

  if (pipe(p) < 0) {
    perror("pipe");
    syslog(LOG_CRIT, "pipe - %m");
    send_error_and_exit(500, "Internal Error","","Something unexpected went wrong making a pipe.");
  }

#ifdef MINGW
  /* *** how to pass global variables and other processing context across the spawn? need to construct complicated environment. */
  /* *** determine whole path. for now we assume working directory contains mini_httpd */
  {
    char conn_fd_buf[32];
    char rfd_buf[32];
    char wfd_buf[32];
    snprintf(conn_fd_buf, sizeof(conn_fd_buf), "%lld", (long long)conn_fd);
    conn_fd_buf[sizeof(conn_fd_buf)-1] = 0;
    snprintf(rfd_buf, sizeof(rfd_buf), "%lld", (long long)p[1]);
    rfd_buf[sizeof(rfd_buf)-1] = 0;
    snprintf(wfd_buf, sizeof(wfd_buf), "%lld", (long long)p[1]);
    wfd_buf[sizeof(wfd_buf)-1] = 0;
    D("spawing interposer wfd=%d conn_fd=%d", p[1], conn_fd);
    ret = spawnlp(P_NOWAIT, ".", argv0, next_step_flag, conn_fd_buf, rfd_buf, wfd_buf);
  }
  /* Parent comes here. child is processed where option -cgiin-child is processed. */
  if (ret) {
    perror("spawnlp");
    ERR("spawn failed to create subprocess (%s) to handle connection. ret=%d errno=%d %s", argv0, ret, errno, STRERROR(errno));
    send_error_and_exit(500, "Internal Error", "", "Something unexpected went wrong spawning an interposer.");
  }
  return 1; /* indicate parent, the child is handled by reinvokcation with command line flag. */
#else
  ret = fork();
  if (ret < 0) {
    syslog(LOG_CRIT, "fork - %m");
    perror("fork");
    send_error_and_exit(500, "Internal Error", "", "Something unexpected went wrong forking an interposer.");
  }
  return ret;
#endif
}

/* Called by:  do_file */
static void do_cgi(void) {
  char** argp;
  char** envp;
  int parse_headers;
  char* cgi_binary;
  char* directory;
  int p[2];

  if (*method != 'G' && *method != 'P')
    send_error_and_exit(501, "Not Implemented", "", "That method is not implemented for CGI.");

  D("stdin_fd=%d stdout_fd=%d stderr_fd=%d conn_fd=%d", fileno(stdin), fileno(stdout), fileno(stderr), conn_fd);
  /* If the socket happens to be using one of the stdin/stdout/stderr
  ** descriptors, move it to another descriptor so that the dup2 calls
  ** below don't screw things up.  We arbitrarily pick fd 3 - if there
  ** was already something on it, we clobber it, but that doesn't matter
  ** since at this point the only fd of interest is the connection.
  ** All others will be closed on exec. */
  if (conn_fd == fileno(stdin) || conn_fd == fileno(stdout) || conn_fd == fileno(stderr)) {
    int newfd = dup2(conn_fd, fileno(stderr) + 1);
    if (newfd >= 0)
      conn_fd = newfd;
    /* If the dup2 fails, shrug.  We'll just take our chances. Shouldn't happen though. */
  }

  /* Set up stdin.  For POSTs we may have to set up a pipe from an
  ** interposer process, depending on if we've read some of the data
  ** into our buffer.  We also have to do this for all SSL CGIs. */
  if ((*method == 'P' && request_len > request_idx) || do_ssl) {
    DD("about to fork interpose_input p0=%d p1=%d", p[0], p[1]);
    if (!pipe_and_fork(p,"-cgiin-child")) {
      /* Child: Interposer process. */
      (void) close(p[0]);        /* the read end will be stdin of the CGI script */
      cgi_interpose_input(p[1]); /* shuffle input from conn_fd to write end of the pipe */
    }
    /* parent (the future CGI script) *** we should write captured POST input to the child */
    (void) close(p[1]);
    if (p[0] != fileno(stdin)) {           /* wire read end to be CGI stdin (if not already) */
      (void) dup2(p[0], fileno(stdin));
      (void) close(p[0]);
    }
  } else {
    if (conn_fd != fileno(stdin))          /* Otherwise, the request socket is stdin. */
      (void) dup2(conn_fd, fileno(stdin));
  }

  envp = make_envp();
  argp = make_argp();

  /* Set up stdout/stderr.  For SSL, or if we're doing CGI header parsing,
  ** we need an output interposer too.  */
  if (!strncmp(argp[0], "nph-", 4))
    parse_headers = 0;
  else
    parse_headers = 1;
  if (parse_headers || do_ssl) {
    DD("about to fork interpose_output p0=%d p1=%d", p[0], p[1]);
    if (!pipe_and_fork(p,"-cgiout-child")) {
      /* Child: Interposer process. */
      (void) close(p[1]);        /* the write end will be stdout of the CGI script */
      cgi_interpose_output(p[0], parse_headers); /* shuffle output from read end to conn_fd */
    }
    DD("Parent %d", p[0]);
    (void) close(p[0]);  /* parent (the future CGI): assign stdout to write end */
    if (p[1] != fileno(stdout))
      (void) dup2(p[1], fileno(stdout));
    //if (p[1] != STDERR_FILENO)            // perhaps we do not want to capture stderr
    //  (void) dup2(p[1], STDERR_FILENO);
    if (p[1] != fileno(stdout) && p[1] != fileno(stderr))
      (void) close(p[1]);
  } else {
    if (conn_fd != fileno(stdout))
      (void) dup2(conn_fd, fileno(stdout)); /* Otherwise, the request socket is stdout/stderr. */
    //if (conn_fd != STDERR_FILENO)        // perhaps we do not want to capture stderr
    //  (void) dup2(conn_fd, STDERR_FILENO);
  }
  
  /* At this point we would like to set conn_fd to be close-on-exec.
  ** Unfortunately there seems to be a Linux problem here - if we
  ** do this close-on-exec in Linux, the socket stays open but stderr
  ** gets closed - the last fd duped from the socket.  What a mess.
  ** So we'll just leave the socket as is, which under other OSs means
  ** an extra file descriptor gets passed to the child process.  Since
  ** the child probably already has that file open via stdin stdout
  ** and/or stderr, this is not a problem. */
  /* (void) fcntl(conn_fd, F_SETFD, 1); */

  if (logfp)
    (void) fclose(logfp);  /* Close the log file. */
  closelog();              /* Close syslog. */
  (void) nice(CGI_NICE);

  /* Split the program into directory and binary, so we can chdir()
  ** to the program's own directory.  This isn't in the CGI 1.1
  ** spec, but it's what other HTTP servers do. */
  directory = e_strdup(file);
  cgi_binary = strrchr(directory, '/');
  if (!cgi_binary)
    cgi_binary = file;
  else {
    *cgi_binary++ = '\0';
    (void) chdir(directory);	/* ignore errors */
  }

  /* Default behavior for SIGPIPE. */
#ifdef HAVE_SIGSET
  (void) sigset(SIGPIPE, SIG_DFL);
#else /* HAVE_SIGSET */
  (void) signal(SIGPIPE, SIG_DFL);
#endif /* HAVE_SIGSET */

  DD("about to exec CGI(%s)", cgi_binary);
  (void) execve(cgi_binary, argp, envp);  /* Run the CGI script. */
  send_error_and_exit(500, "Internal Error", "", "Something unexpected went wrong launching a CGI program. Bad nonexistent path to CGI? No execute permission?");
}

/* This routine is used only for POST requests.  It reads the data
** from the request and sends it to the child process.  The only reason
** we need to do it this way instead of just letting the child read
** directly is that we have already read part of the data into our
** buffer.
**
** Oh, and it's also used for all SSL CGIs.
*/
/* Called by:  do_cgi, main */
static void cgi_interpose_input(int wfd)
{
  size_t cnt;
  ssize_t r2;
  ssize_t got = 0;
  char buf[1024];

  cnt = request_len - request_idx;
  D("write wfd=%d buffered post cnt=%d content_length=%d", (int)wfd, (int)cnt,(int)content_length);
  if (cnt > 0) {
    // *** MINGW problem: after spawn the read buffer global is no longer available
    if ((r2 = write(wfd, request+request_idx, cnt)) != cnt)
      exit(0);
  }
  while ((int)cnt < (int)content_length) {  /* without the cast 0 < -1 seems to be true */
    got = conn_read(buf, MIN(sizeof(buf), content_length - cnt));
    if (got < 0 && (errno == EINTR || errno == EAGAIN)) {
      sleep(1);
      continue;
    }
    if (got <= 0)
      exit(0);
    for (;;) {
      DD("writing input wfd=%d cnt=%d got=%d", wfd, cnt, got);
      r2 = write(wfd, buf, got);
      DD("got r2=%d", r2);
      if (r2 < 0 && (errno == EINTR || errno == EAGAIN)) {
	sleep(1);
	continue;
      }
      if (r2 != got)
	exit(0);
      break;
    }
    cnt += got;
  }
  D("done got=%d", (int)got);
  post_post_garbage_hack();
  exit(0);
}

/* This routine is used for parsed-header CGIs and for all SSL CGIs. */
/* Called by:  do_cgi, main */
static void cgi_interpose_output(int rfd, int parse_headers)
{
  ssize_t got, r2;
  char buf[4096];

  D("ph=%d, rfd=%d conn_fd=%d", parse_headers, rfd, conn_fd);
  if (!parse_headers) {
    /* If we're not parsing headers, write out the default status line
    ** and proceed to the echo phase. */
    char http_head[] = "HTTP/1.0 200 OK\015\012";
    (void) conn_write(http_head, sizeof(http_head));
  } else {
    /* Header parsing.  The idea here is that the CGI can return special
    ** headers such as "Status:" and "Location:" which change the return
    ** status of the response.  Since the return status has to be the very
    ** first line written out, we have to accumulate all the headers
    ** and check for the special ones before writing the status.  Then
    ** we write out the saved headers and proceed to echo the rest of
    ** the response. */
    size_t headers_size, headers_len;
    char* headers;
    char* br;
    int status, buflen;
    char* title;
    char* cp;
    
    /* Slurp in all headers. */
    headers_size = 0;  /* 0 = force allocation */
    add_to_buf(&headers, &headers_size, &headers_len, 0, 0);
    for (;;) {
      DD("read rfd=%d", rfd);
      got = read(rfd, buf, sizeof(buf));
      DD("got=%d (%.*s)", got, MIN(got, 100), buf);
      if (got < 0 && (errno == EINTR || errno == EAGAIN)) {
	sleep(1);
	continue;
      }
      if (got <= 0) {
	br = &(headers[headers_len]);
	break;
      }
      add_to_buf(&headers, &headers_size, &headers_len, buf, got);
      if ((br = strstr(headers, "\015\012\015\012")) ||
	  (br = strstr(headers, "\012\012")))
	break;
    }

    if (headers[0] == '\0')    /* If there were no headers, bail. */
      goto done;

    status = 200;
    if ((cp = strstr(headers, "Status:")) && cp < br &&	(cp == headers || *(cp-1) == '\012')) {
      cp += 7;
      cp += strspn(cp, " \t");
      status = atoi(cp);
    }
    if ((cp = strstr(headers, "Location:")) && cp < br && (cp == headers || *(cp-1) == '\012'))
      status = 302;

    /* Write the status line. */
    switch (status) {
    case 200: title = "OK"; break;
    case 302: title = "Found"; break;
    case 304: title = "Not Modified"; break;
    case 400: title = "Bad Request"; break;
    case 401: title = "Unauthorized"; break;
    case 403: title = "Forbidden"; break;
    case 404: title = "Not Found"; break;
    case 408: title = "Request Timeout"; break;
    case 500: title = "Internal Error"; break;
    case 501: title = "Not Implemented"; break;
    case 503: title = "Service Temporarily Overloaded"; break;
    default:  title = "Something"; break;
    }
    buflen = snprintf(buf, sizeof(buf), "HTTP/1.0 %d %s\015\012", status, title);
    (void) conn_write(buf, buflen);
    
    // *** MINGW: recreate zxid_cf and zxid_session
    if (zxid_cf && zxid_session) {
      if (zxid_is_wsp) {
	zxid_mini_httpd_wsp_response(zxid_cf, zxid_session, rfd,
				     &headers, &headers_size, &headers_len, br-headers);
	goto done;
      } else {
	if (zxid_session->setcookie) {
	  buflen = snprintf(buf, sizeof(buf), "Set-Cookie: %s\015\012",zxid_session->setcookie);
	  conn_write(buf, buflen);
	}
	if (zxid_session->setptmcookie) {
	  buflen = snprintf(buf, sizeof(buf), "Set-Cookie: %s\015\012",zxid_session->setptmcookie);
	  conn_write(buf, buflen);
	}
      }
    }
    /* Write the saved headers (and any beginning of payload). */
    (void) conn_write(headers, headers_len);
  }

  /* Echo the rest of the output. */
  for (;;) {
    DD("read rfd=%d", rfd);
    got = read(rfd, buf, sizeof(buf));
    DD("got=%d (%.*s)", got, MIN(got, 100), buf);
    if (got < 0 && (errno == EINTR || errno == EAGAIN)) {
      sleep(1);
      continue;
    }
    if (got <= 0)
      goto done;
    for (;;) {
      r2 = conn_write(buf, got);
      if (r2 < 0 && (errno == EINTR || errno == EAGAIN)) {
	sleep(1);
	continue;
      }
      if (r2 != got)
	goto done;
      break;
    }
  }
 done:
  D("done conn_fd=%d", conn_fd);
  shutdown(conn_fd, SHUT_WR);
  exit(0);
}

/* Set up CGI argument vector.  We don't have to worry about freeing
** stuff since we're a sub-process.  This gets done after make_envp() because
** we scribble on query. */
/* Called by:  do_cgi */
static char** make_argp(void)
{
  char** argp;
  int an;
  char* cp1;
  char* cp2;

  /* By allocating an arg slot for every character in the query, plus
  ** one for the filename and one for the NULL, we are guaranteed to
  ** have enough.  We could actually use strlen/2.  */
  argp = (char**) malloc((strlen(query) + 2) * sizeof(char*));
  if (!argp) die_oom();

  argp[0] = strrchr(file, '/');
  if (argp[0])
    ++argp[0];
  else
    argp[0] = file;

  an = 1;
  /* According to the CGI spec at http://hoohoo.ncsa.uiuc.edu/cgi/cl.html,
  ** "The server should search the query information for a non-encoded =
  ** character to determine if the command line is to be used, if it finds
  ** one, the command line is not to be used."  */
  if (!strchr(query, '=')) {
    for (cp1 = cp2 = query; *cp2 != '\0'; ++cp2) {
      if (*cp2 == '+') {
	*cp2 = '\0';
	strdecode(cp1, cp1);
	argp[an++] = cp1;
	cp1 = cp2 + 1;
      }
    }
    if (cp2 != cp1) {
      strdecode(cp1, cp1);
      argp[an++] = cp1;
    }
  }
  
  argp[an] = 0;
  return argp;
}

/* Called by:  make_envp x23 */
static char* build_env(char* fmt, char* arg)
{
  char* cp;
  int size;
  static char* buf;
  static int maxbuf = 0;

  size = strlen(fmt) + strlen(arg);
  if (size > maxbuf) {
    if (maxbuf == 0) {
      maxbuf = MAX(200, size + 100);
      buf = (char*) e_malloc(maxbuf);
    } else {
      maxbuf = MAX(maxbuf * 2, size * 5 / 4);
      buf = (char*) e_realloc((void*) buf, maxbuf);
    }
  }
  (void) snprintf(buf, maxbuf, fmt, arg);
  cp = e_strdup(buf);
  return cp;
}

/* Set up CGI environment variables. Be real careful here to avoid
** letting malicious clients overrun a buffer.  We don't have
** to worry about freeing stuff since we're a sub-process. */
/* Called by:  do_cgi */
static char** make_envp(void)
{
  static char* envp[50+200];
  int envn;
  char* cp;
  char buf[256];

  envn = 0;
  envp[envn++] = build_env("PATH=%s", CGI_PATH);
  envp[envn++] = build_env("LD_LIBRARY_PATH=%s", CGI_LD_LIBRARY_PATH);
  envp[envn++] = build_env("SERVER_SOFTWARE=%s", SERVER_SOFTWARE);
  if (! vhost)
    cp = hostname;
  else
    cp = req_hostname;	/* already computed by virtual_file() */
  if (cp) envp[envn++] = build_env("SERVER_NAME=%s", cp);
  envp[envn++] = "GATEWAY_INTERFACE=CGI/1.1";
  envp[envn++] = "SERVER_PROTOCOL=HTTP/1.0";
  (void) snprintf(buf, sizeof(buf), "%d", (int) port);
  envp[envn++] = build_env("SERVER_PORT=%s", buf);
  envp[envn++] = build_env("REQUEST_METHOD=%s",  method);
  envp[envn++] = build_env("SCRIPT_NAME=%s", path);
  if (pathinfo) {
    envp[envn++] = build_env("PATH_INFO=/%s", pathinfo);
    (void) snprintf(buf, sizeof(buf), "%s%s", cwd, pathinfo);
    envp[envn++] = build_env("PATH_TRANSLATED=%s", buf);
  }
  if (query[0] != '\0')
    envp[envn++] = build_env("QUERY_STRING=%s", query);
  envp[envn++] = build_env("REMOTE_ADDR=%s", ntoa(&client_addr));
  if (referer[0] != '\0')           envp[envn++] = build_env("HTTP_REFERER=%s", referer);
  if (useragent[0] != '\0')         envp[envn++] = build_env("HTTP_USER_AGENT=%s", useragent);
  if (cookie)                       envp[envn++] = build_env("HTTP_COOKIE=%s", cookie);
  if (host)                         envp[envn++] = build_env("HTTP_HOST=%s", host);
  if (content_type)                 envp[envn++] = build_env("CONTENT_TYPE=%s", content_type);
  if (content_length != -1) {
    (void) snprintf(buf, sizeof(buf), "%lu", (unsigned long) content_length);
    envp[envn++] = build_env("CONTENT_LENGTH=%s", buf);
  }
  if (authorization)                {
    envp[envn++] = build_env("AUTH_TYPE=%s", "Basic");                 /* Of dubious value */
    envp[envn++] = build_env("HTTP_AUTHORIZATION=%s", authorization);  /* Allow CGI to see it */
  }
  if (cp = getenv("TZ"))            envp[envn++] = build_env("TZ=%s", cp);
  if (cp = getenv("MALLOC_CHECK_")) envp[envn++] = build_env("MALLOC_CHECK_=%s", cp);
  if (paos[0] != '\0')              envp[envn++] = build_env("HTTP_PAOS=%s", paos);
  if (cp = getenv("ZXID_PRE_CONF")) envp[envn++] = build_env("ZXID_PRE_CONF=%s", cp);
  if (cp = getenv("ZXID_CONF"))     envp[envn++] = build_env("ZXID_CONF=%s", cp);
  if (zxid_session)
    envn = zxid_pool2env(zxid_cf, zxid_session, envp, envn, sizeof(envp)/sizeof(char*), path, query);
  if (remoteuser != 0)
    envp[envn++] = build_env("REMOTE_USER=%s", remoteuser);

  envp[envn] = 0;
  return envp;
}

/*() Start a response by rendering typical headers
 *
 * s:: status code (e.g. 200=OK)
 * title:: status code explanation, e.g. "OK"
 * extra_header:: One or more fully formated headers, or null for none.
 * me:: MIME Encoding, if any, for Content-Encoding header
 * mt:: MIME type for Content-Type header
 * byt:: bytes for Content-Length
 * mod:: Last-Modified time
 */

/* Called by:  do_dir, do_file x2, send_error_and_exit, zxid_mini_httpd_sso */
void add_headers(int s, char* title, char* extra_header, char* me, char* mt, off_t byt, time_t mod)
{
  time_t now, expires;
  char timebuf[100];
  char buf[10000];
  int buflen;
  int s100;
  const char* rfc1123_fmt = "%a, %d %b %Y %H:%M:%S GMT";
  
  D("status=%d %s", s, title);
  status = s;
  bytes = byt;
  make_log_entry();
  start_response();
  buflen = snprintf(buf, sizeof(buf), "%s %d %s\015\012", protocol, status, title);
  add_to_response(buf, buflen);
  buflen = snprintf(buf, sizeof(buf), "Server: %s\015\012", SERVER_SOFTWARE);
  add_to_response(buf, buflen);
  now = time((time_t*) 0);
  (void) strftime(timebuf, sizeof(timebuf), rfc1123_fmt, gmtime(&now));
  buflen = snprintf(buf, sizeof(buf), "Date: %s\015\012", timebuf);
  add_to_response(buf, buflen);
  s100 = status / 100;
  if (s100 != 2 && s100 != 3) {
    buflen = snprintf(buf, sizeof(buf), "Cache-Control: no-cache,no-store\015\012");
    add_to_response(buf, buflen);
  }
  if (extra_header != 0 && extra_header[0] != '\0') {
    buflen = strlen(extra_header);
    for (; buflen > 0 && ONE_OF_2(extra_header[buflen], '\015', '\012');
	 --buflen) ; /* eliminate trailing CRLFs, e.g. from zxid_simple() */
    buflen = snprintf(buf, sizeof(buf), "%.*s\015\012", buflen, extra_header);
    add_to_response(buf, buflen);
  }
  if (me != 0 && me[0] != '\0') {
    buflen = snprintf(buf, sizeof(buf), "Content-Encoding: %s\015\012", me);
    add_to_response(buf, buflen);
  }
  if (mt != 0 && mt[0] != '\0') {
    buflen = snprintf(buf, sizeof(buf), "Content-Type: %s\015\012", mt);
    add_to_response(buf, buflen);
  }
  if (bytes >= 0) {
    buflen = snprintf(buf, sizeof(buf), "Content-Length: %lld\015\012", (long long int) bytes);
    add_to_response(buf, buflen);
  }
  if (p3p != 0 && p3p[0] != '\0') {
    buflen = snprintf(buf, sizeof(buf), "P3P: %s\015\012", p3p);
    add_to_response(buf, buflen);
  }
  if (max_age >= 0) {
    expires = now + max_age;
    (void) strftime(timebuf, sizeof(timebuf), rfc1123_fmt, gmtime(&expires));
    buflen = snprintf(buf, sizeof(buf),
		      "Cache-Control: max-age=%d\015\012Expires: %s\015\012", max_age, timebuf);
    add_to_response(buf, buflen);
  }
  if (mod != (time_t) -1) {
    (void) strftime(timebuf, sizeof(timebuf), rfc1123_fmt, gmtime(&mod));
    buflen = snprintf(buf, sizeof(buf), "Last-Modified: %s\015\012", timebuf);
    add_to_response(buf, buflen);
  }
  D("zxid_cf=%p zxid_session=%p", zxid_cf, zxid_session);
  if (zxid_cf && zxid_session) {
    if (zxid_is_wsp) {
      /* Nothing to add, not even likely to occur */
      D("zxid_is_wsp=%d", zxid_is_wsp);
    } else {
      if (zxid_session->setcookie) {
	buflen = snprintf(buf, sizeof(buf), "Set-Cookie: %s\015\012", zxid_session->setcookie);
	D("set-cookie(%.*s)", buflen, buf);
	add_to_response(buf, buflen);
      }
      if (zxid_session->setptmcookie) {
	buflen = snprintf(buf, sizeof(buf), "Set-Cookie: %s\015\012", zxid_session->setptmcookie);
	D("set-cookie(%.*s)", buflen, buf);
	add_to_response(buf, buflen);
      }
    }
  }
  buflen = snprintf(buf, sizeof(buf), "Connection: close\015\012\015\012");
  add_to_response(buf, buflen);
}

/* Called by:  handle_request */
static char* virtual_file(char* file) {
  char* cp;
  static char vfile[10000];

  /* Use the request's hostname, or fall back on the IP address. */
  if (host != 0)
    req_hostname = host;
  else
    {
      usockaddr usa;
      socklen_t sz = sizeof(usa);
      if (getsockname(conn_fd, &usa.sa, &sz) < 0)
	req_hostname = "UNKNOWN_HOST";
      else
	req_hostname = ntoa(&usa);
    }
  /* Pound it to lower case. */
  for (cp = req_hostname; *cp != '\0'; ++cp)
    if (isupper(*cp))
      *cp = tolower(*cp);
  (void) snprintf(vfile, sizeof(vfile), "%s/%s", req_hostname, file);
  return vfile;
}

/* Called by:  send_error_and_exit x2 */
static int send_error_file(char* filename) {
  FILE* fp;
  char buf[1000];
  size_t r;

  fp = fopen(filename, "r");
  if (!fp)
    return 0;
  for (;;) {
    r = fread(buf, 1, sizeof(buf), fp);
    if (!r)
      break;
    add_to_response(buf, r);
  }
  (void) fclose(fp);
  return 1;
}

/* Called by:  auth_check, check_referer, do_cgi x2, do_dir x2, do_file x3, handle_read_timeout, handle_request x9, pipe_and_fork x3, send_authenticate, zxid_mini_httpd_sso x3, zxid_mini_httpd_wsp x2 */
void send_error_and_exit(int err_code, char* title, char* extra_header, char* text) {
  char buf[4000];
  int buflen;

  add_headers(err_code, title, extra_header, "", "text/html; charset=%s", (off_t) -1, (time_t) -1);

  if (vhost && req_hostname) {
    /* Try virtual-host custom error page. */
    (void) snprintf(buf, sizeof(buf), "%s/%s/err%d.html", req_hostname, ERR_DIR, err_code);
    if (send_error_file(buf))
      exit(1);
  }
  
  /* Try server-wide custom error page. */
  (void) snprintf(buf, sizeof(buf), "%s/err%d.html", ERR_DIR, err_code);
  if (send_error_file(buf))
    exit(1);
  
  /* Send built-in error page. */
  buflen = snprintf(buf, sizeof(buf), "<TITLE>%d %s</TITLE><BODY BGCOLOR=\"#cc9999\" TEXT=\"#000000\" LINK=\"#2020ff\" VLINK=\"#4040cc\">\n<H4>%d %s</H4>\n%s\n",err_code,title,err_code,title,text);
  add_to_response(buf, buflen);

  if (zx_match("**MSIE**", useragent)) {
    int n;
    buflen = snprintf(buf, sizeof(buf), "<!--\n");
    add_to_response(buf, buflen);
    for (n = 0; n < 6; ++n)
      {
	buflen = snprintf(buf, sizeof(buf), "Padding so that MSIE deigns to show this error instead of its own canned one.\n");
	add_to_response(buf, buflen);
      }
    buflen = snprintf(buf, sizeof(buf), "-->\n");
    add_to_response(buf, buflen);
  }
  
  buflen = snprintf(buf, sizeof(buf), "<HR>\n<ADDRESS><A HREF=\"%s\">%s</A></ADDRESS>\n",
		    SERVER_URL, SERVER_SOFTWARE);
  add_to_response(buf, buflen);
  send_response();
  SSL_free(ssl);
  exit(1);
}

/* Called by:  auth_check x5 */
static void send_authenticate(char* realm) {
  char header[1000];
  (void) snprintf(header, sizeof(header), "WWW-Authenticate: Basic realm=\"%s\"", realm);
  send_error_and_exit(401, "Unauthorized", header, "Authorization required.");
}

/*() Check that file (or CGI or directory) access is permitted.
 * First, if UNIX_GROUP_AZ_MAP has been configured, the current
 * user's attributes, typically role or o (organization), are checked
 * against the group. This is typically used with SSO.
 * Second, the .htaccess file in the directory, if any, is checked (i.e. HTTP
 * Basic Auth with usename and password).
 */
/* Called by:  do_dir, do_file */
static void auth_check(char* dirname)
{
  char authpath[10000];
  char authinfo[500];
  char* authpass;
  char* colon;
  static char line[10000];
  int len;
  FILE* fp;
  char* cryp;
  zxid_cgi cgi;

  if (zxid_cf && zxid_cf->unix_grp_az_map) {
    D("Checking unix_grp_az_map st_mode=%o", sb.st_mode);
    /* The stat buffer has already been filled by caller */
    if (sb.st_mode & S_IROTH)
      return;    /* Ok. World readable file, directory, or executable. */
    if (sb.st_mode & S_IRGRP) {
      D("HERE2 st_mode=%o", sb.st_mode);
      if (zxid_unix_grp_az_check(zxid_cf, zxid_session, sb.st_gid))
	return;  /* Permit */
      if (!zxid_session || !zxid_session->nid || !zxid_session->nid[0]) {
	D("HERE3 st_mode=%o", sb.st_mode);
	/* User had not logged in yet */
	ZERO(&cgi, sizeof(zxid_cgi));
	cgi.op = 'E';
	cgi.uri_path = path;
	zxid_mini_httpd_step_up(zxid_cf, &cgi, 0, path, 0);
	exit(0);
      }
      D("HERE8 st_mode=%o", sb.st_mode);
    }
    send_error_and_exit(403, "Forbidden", "", "File is protected. 3");
  }

  if (dirname[strlen(dirname) - 1] == '/')
    (void) snprintf(authpath, sizeof(authpath), "%s%s", dirname, AUTH_FILE);
  else
    (void) snprintf(authpath, sizeof(authpath), "%s/%s", dirname, AUTH_FILE);
  if (stat(authpath, &sb) < 0)  /* Does this directory have an auth file? */
    return;                     /* Nope, let the request go through. */
  if (!authorization)           /* Does this request contain authorization info? */
    send_authenticate(dirname); /* Nope, return a 401 Unauthorized. */

  if (strncmp(authorization, "Basic ", 6))  /* Basic authorization info? */
    send_authenticate(dirname);
  
  len = b64_decode(&(authorization[6]), (unsigned char*) authinfo, sizeof(authinfo) - 1);
  authinfo[len] = '\0';
  authpass = strchr(authinfo, ':');  /* Split into user and password. */
  if (!authpass)
    send_authenticate(dirname);      /* No colon?  Bogus auth info. */
  *authpass++ = '\0';
  colon = strchr(authpass, ':');     /* If there are more fields, cut them off. */
  if (colon)
    *colon = '\0';

  fp = fopen(authpath, "r");    /* Open the password file. */
  if (fp == (FILE*) 0) {
    syslog(LOG_ERR, "%.80s auth file %.80s could not be opened - %m",ntoa(&client_addr),authpath);
    send_error_and_exit(403, "Forbidden", "", "File is protected. 4");
  }

  while (fgets(line, sizeof(line), fp)) {
    len = strlen(line);
    if (line[len - 1] == '\n')
      line[len - 1] = '\0';     /* Nuke newline. */
    cryp = strchr(line, ':');   /* Split into user and encrypted password. */
    if (!cryp)
      continue;
    *cryp++ = '\0';
    if (!strcmp(line, authinfo)) {   /* Is this the right user? */
      (void) fclose(fp);
      if (!strcmp(crypt(authpass, cryp), cryp)) { /* Yes, So is the password right? */
	remoteuser = line;
	return; /* Ok! */
      } else /* Wrong password */
	send_authenticate(dirname);
    }
  }

  (void) fclose(fp);
  send_authenticate(dirname);   /* Didn't find that user.  Access denied. */
}

/* Returns 1 if ok to serve the url, 0 if not. */
/* Called by:  check_referer */
static int really_check_referer(void)
{
  char* cp1;
  char* cp2;
  char* cp3;
  char* refhost;
  char *lp;

  /* Check for an empty referer. */
  if (!referer || !*referer || !(cp1 = strstr(referer, "//"))) {
    /* Disallow if we require a referer and the url matches. */
    if (no_empty_referers && zx_match(url_pattern, path))
      return 0;
    /* Otherwise ok. */
    return 1;
  }

  /* Extract referer host. */
  cp1 += 2;
  for (cp2 = cp1; *cp2 != '/' && *cp2 != ':' && *cp2 != '\0'; ++cp2)
    continue;
  refhost = (char*) e_malloc(cp2 - cp1 + 1);
  for (cp3 = refhost; cp1 < cp2; ++cp1, ++cp3)
    if (isupper(*cp1))
      *cp3 = tolower(*cp1);
    else
      *cp3 = *cp1;
  *cp3 = '\0';

  /* Local pattern? */
  if (local_pattern)
    lp = local_pattern;
  else {
    /* No local pattern.  What's our hostname? */
    if (!vhost) {
      /* Not vhosting, use the server name. */
      lp = hostname;
      if (!lp)
	return 1; /* Couldn't figure out local hostname - give up. */
    } else {
      /* We are vhosting, use the hostname on this connection. */
      lp = req_hostname;
      if (!lp)
	/* Oops, no hostname.  Maybe it's an old browser that
	 * doesn't send a Host: header.  We could figure out
	 * the default hostname for this IP address, but it's
	 * not worth it for the few requests like this. */
	return 1;
    }
  }
  
  /* If the referer host doesn't match the local host pattern, and
  ** the URL does match the url pattern, it's an illegal reference. */
  if (! zx_match(lp, refhost) && zx_match(url_pattern, path))
    return 0;
  /* Otherwise ok. */
  return 1;
}

/* Returns if it's ok to serve the url, otherwise generates an error and exits. */
/* Called by:  do_dir, do_file */
static void check_referer(void)
{
  char* cp;
  if (!url_pattern) 
    return;  /*Not doing referer checking at all. */

  if (really_check_referer())
    return; /* Ok */

  /* Lose. */
  if (!(cp = vhost && req_hostname ? req_hostname : hostname))
    cp = "";
  syslog(LOG_INFO, "%.80s non-local referer \"%.80s%.80s\" \"%.80s\"",
	 ntoa(&client_addr), cp, path, referer);
  send_error_and_exit(403, "Forbidden", "", "You must supply a local referer.");
}

/* Called by:  add_headers */
static void make_log_entry(void)
{
  char url[500];
  char bytes_str[40];
  time_t now;
  char date[100];

  if (!logfp)
    return;  /* no logging */

  /* If we're vhosting, prepend the hostname to the url. Separate files are not supported. */
  if (vhost)
    (void) snprintf(url, sizeof(url), "/%s%s", req_hostname?req_hostname:hostname, path?path:"");
  else
    (void) snprintf(url, sizeof(url), "%s", path?path:"");
  if (bytes >= 0)
    (void) snprintf(bytes_str, sizeof(bytes_str), "%lld", (long long int)bytes);
  else
    (void) strcpy(bytes_str, "-");
  now = time(0);
  (void) strftime(date, sizeof(date), "%d/%b/%Y:%H:%M:%S +0000", gmtime(&now)); /* always gmt */
  (void) fprintf(logfp, "%.80s - %.80s [%s] \"%.80s %.200s %.80s\" %d %s \"%.200s\" \"%.200s\"\n",
		 ntoa(&client_addr), remoteuser?remoteuser:"-", date, method,
		 url, protocol?protocol:"UNKNOWN", status, bytes_str, referer, useragent);
  (void) fflush(logfp);
}

/* EOF */
