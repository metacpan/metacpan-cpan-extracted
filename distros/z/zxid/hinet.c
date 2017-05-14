/* hinet.c  -  Hiquu I/O Engine I/O shuffler TCP/IP network connect and accept
 * Copyright (c) 2006,2012 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing. See file COPYING.
 * Special grant: hiios.c may be used with zxid open source project under
 * same licensing terms as zxid itself.
 * $Id$
 *
 * 15.4.2006, created over Easter holiday --Sampo
 * 16.8.2012, modified license grant to allow use with ZXID.org --Sampo
 * 6.9.2012,  added support for TLS and SSL --Sampo
 * 17.9.2012, factored net code to its own file --Sampo
 *
 * See http://pl.atyp.us/content/tech/servers.html for inspiration on threading strategy.
 *
 *   MANY ELEMENTS IN QUEUE            ONE ELEMENT IN Q   EMPTY QUEUE
 *   consume             produce       consume  produce   consume  produce
 *    |                   |             | ,-------'         |        |
 *    V                   V             V V                 V        V
 *   qel.n --> qel.n --> qel.n --> 0   qel.n --> 0          0        0
 *
 ****
 * accept() blocks (after accept returned EAGAIN) - see if this is a blocking socket
 * see if edge triggered epoll has some special consideration for accept(2).
 */

#include "platform.h"

#include <pthread.h>
#include <memory.h>
#include <stdlib.h>
//#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <errno.h>
#include <string.h>

#include <zx/zxid.h>
#include "akbox.h"
#include "hiproto.h"
#include "hiios.h"
#include "errmac.h"

extern zxid_conf* zxbus_cf;
extern int errmac_debug;
#ifdef MUTEX_DEBUG
extern pthread_mutexattr_t MUTEXATTR_DECL;
#endif

#define SSL_ENCRYPTED_HINT "ERROR\nmessage:tls-needed\n\nTLS or SSL connection wanted but other end did not speak protocol.\n\0"

/*() Verify peer ClientTLS credential.
 * If known peer, eid should be the eid of the peer and is used to look up
 * the metadata if the peer. The general strategy is that verification
 * is done only after TLS handshake. This ie either achived by supplying
 * SSL_VERIFY_NONE or SSL_VERIFY_PEER with verify callback that causes any
 * certificate to be accepted. In case of STOMP, the STOMP (or CONNECT) connect
 * message will contain the appropriate eid in login header. In case of client
 * side, the client knows which server it is contacting so it can look up
 * the eid for that server.
 * return:: 0 on error, 1 on success */

/* Called by:  hi_open_tcp, zxbus_login_ent */
int hi_vfy_peer_ssl_cred(struct hi_thr* hit, struct hi_io* io, const char* eid)
{
#ifdef USE_OPENSSL
  X509* peer_cert;
  zxid_entity* meta;
  long vfy_err;
  
  if (errmac_debug>1) D("SSL_version(%s) cipher(%s)",SSL_get_version(io->ssl),SSL_get_cipher(io->ssl));
  
  vfy_err = SSL_get_verify_result(io->ssl);
  switch (vfy_err) {
  case X509_V_OK: break;
  case X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT:
    D("TLS/SSL connection to(%s) made, with certificate err that will be ignored. (%ld)", eid, vfy_err);
    zx_report_openssl_err("open_bus_url-verify_res");
    break;
  default:
    ERR("TLS/SSL connection to(%s) made, but certificate not acceptable. (%ld)", eid, vfy_err);
    zx_report_openssl_err("open_bus_url-verify_res");
    return 0;
  }
  if (!(peer_cert = SSL_get_peer_certificate(io->ssl))) {
    ERR("TLS/SSL connection to(%s) made, but peer did not send certificate", eid);
    zx_report_openssl_err("peer_cert");
    return 0;
  }
  meta = zxid_get_ent(zxbus_cf, eid);
  if (!meta) {
    ERR("Unable to find metadata for eid(%s) in verify peer cert", eid);
    return 0;
  }
  if (!meta->enc_cert) {
    ERR("Metadata for eid(%s) does not contain enc cert", eid);
    return 0;
  }
  if (X509_cmp(meta->enc_cert, peer_cert)) {
    ERR("Peer certificate does not match metadata for eid(%s)", eid);
    D("compare: %d", memcmp(meta->enc_cert->sha1_hash, peer_cert->sha1_hash, SHA_DIGEST_LENGTH));
    PEM_write_X509(ERRMAC_DEBUG_LOG, peer_cert);
    return 0;
  }
#endif
  return 1;
}

/*() Set socket to be nonblocking.
 * Our I/O strategy (edge triggered epoll or /dev/poll) depends on nonblocking fds. */

/* Called by: */
void nonblock(int fd)
{
#ifdef MINGW
  u_long arg = 1;
  if (ioctlsocket(fd, FIONBIO, &arg) == SOCKET_ERROR) {
    ERR("Unable to ioctlsocket(%d, FIONBIO, 1): %d %s", fd, errno, STRERROR(errno));
    exit(2);
  }
#else
#if 0
  int fflags = fcntl(fd, F_GETFL, 0);
  if (fflags == -1) {
    ERR("Unable to fcntl(F_GETFL) on socket %d: %d %s", fd, errno, STRERROR(errno));
    exit(2);
  }
  fflags |= O_NONBLOCK | O_NDELAY;  /* O_ASYNC would be synonymous */
#endif

  if( fcntl(fd, F_SETFL, O_NONBLOCK | O_NDELAY) == -1) {
    ERR("Unable to fcntl(F_SETFL) on socket %d: %d %s", fd, errno, STRERROR(errno));
    exit(2);
  }

#if 0
  if (fcntl(fd, F_SETFD, FD_CLOEXEC) == -1) {
    ERR("fcntl(F_SETFD,FD_CLOEXEC) system call failed for %d: %d %s", fd, errno, STRERROR(errno));
    exit(2);
  }
#endif
#endif
}

/* Tweaking kernel buffers to be smaller can be a win if a massive number
 * of connections are simultaneously open. On many systems default buffer
 * size is 64KB in each direction, leading to 128KB memory consumption. Tweaking
 * to only, say, 8KB can bring substantial savings (but may hurt TCP performance). */

/* Called by: */
void setkernelbufsizes(int fd, int tx, int rx)
{
  /* See `man 7 tcp' for TCP_CORK, TCP_NODELAY, etc. */
  if (setsockopt(fd, SOL_SOCKET, SO_SNDBUF, (char*)&tx, sizeof(tx)) == -1) {
    ERR("setsockopt(SO_SNDBUF, %d) on fd=%d: %d %s", tx, fd, errno, STRERROR(errno));
    exit(2);
  }
  if (setsockopt(fd, SOL_SOCKET, SO_RCVBUF, (char*)&rx, sizeof(rx)) == -1) {
    ERR("setsockopt(SO_RCVBUF, %d) on fd=%d: %d %s", rx, fd, errno, STRERROR(errno));
    exit(2);
  }
}

extern int nkbuf;
extern int listen_backlog;

/* Called by:  zxbusd_main */
struct hi_io* hi_open_listener(struct hiios* shf, struct hi_host_spec* hs, int proto)
{
  struct hi_io* io;
  int fd, tmp;
  /* socket(domain,type,proto): leaving proto as 0 chooses the appropriate
     one given domain and type, see man 2 socket, near middle. */
  if ((fd = socket(AF_INET, SOCK_STREAM, 0))== -1) {
    ERR("listen: Unable to create socket(AF_INET, SOCK_STREAM, 0) %d %s", errno, STRERROR(errno));
    return 0;
  }
  if (fd >= shf->max_ios) {
    ERR("listen: File descriptor limit(%d) exceeded fd=%d. Consider increasing the limit with -nfd flag, or figure out if there are any descriptor leaks.", shf->max_ios, fd);
    close(fd);
    return 0;
  }
  nonblock(fd);
  if (nkbuf)
    setkernelbufsizes(fd, nkbuf, nkbuf);

  tmp = 1;
  if (setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, (char*)&tmp, sizeof(tmp)) == -1) {
    ERR("listen: Failed to call setsockopt(REUSEADDR) on %d: %d %s", fd, errno, STRERROR(errno));
    exit(2);
  }

  if (bind(fd, (struct sockaddr*)&hs->sin, sizeof(struct sockaddr_in))) {
    ERR("listen: Unable to bind socket %d (%s): %d %s (trying again in 2 secs)",
	fd, hs->specstr, errno, STRERROR(errno));
    /* It appears to be a problem under 2.5.7x series kernels that if you kill a process that
     * was listening to a port, you can not immediately bind on that same port again. */
    sleep(2);
    if (bind (fd, (struct sockaddr*)&hs->sin, sizeof(struct sockaddr_in))) {
      ERR("listen: Unable to bind socket %d (%s): %d %s (giving up)",
	  fd, hs->specstr, errno, STRERROR(errno));
      close(fd);
      return 0;
    }
  }
  
  if (listen(fd, listen_backlog)) {
    ERR("Unable to listen(%d, %d) (%s): %d %s",
	fd, listen_backlog, hs->specstr, errno, STRERROR(errno));
    close(fd);
    return 0;
  }

  io = shf->ios + fd;

#ifdef LINUX
  {
    struct epoll_event ev;
    ev.events = EPOLLIN | EPOLLET;  /* ET == EdgeTriggered */
    ev.data.ptr = io;
    if (epoll_ctl(shf->ep, EPOLL_CTL_ADD, fd, &ev)) {
      ERR("Unable to epoll_ctl(%d) (%s): %d %s", fd, hs->specstr, errno, STRERROR(errno));
      close(fd);
      return 0;
    }
  }
#endif
#ifdef SUNOS
  {
    struct pollfd pfd;
    pfd.fd = fd;
    pfd.events = POLLIN | POLLERR;
    if (write(shf->ep, &pfd, sizeof(pfd)) == -1) {
      ERR("Unable to write to /dev/poll fd(%d) (%s): %d %s", fd, hs->specstr, errno, STRERROR(errno));
      close(fd);
      return 0;
    }
  }
#endif
#if defined(MACOSX) || defined(FREEBSD)
  {
    struct kevent kev;
    EV_SET(kev, fd, EVFILT_READ, EV_ADD, 0, 0, &zero_timeout);
    if (kevent(hit->shf->ep, &kev, 1, 0,0,0) == -1) {
      ERR("kevent: fd(%d): %d %s", fd, errno, STRERROR(errno));
      close(fd);
      return 0;
    }
  }
#endif

  io->fd = fd;
  io->qel.kind = HI_LISTENT;
  io->qel.proto = proto;
  D("listen(%x) hs(%s)", fd, hs->specstr);
  return io;
}

#if defined(MACOSX) || defined(FREEBSD)
const struct timespec* zero_timeout = {0,0};
#endif

/*() When poll marker is consumed from the todo, perform OS dependent epoll(2) or similar. */

/* Called by:  hi_shuffle */
void hi_poll(struct hi_thr* hit)
{
  struct hi_io* io;
  int i;
  D("epoll(%x)", hit->shf->ep);
 retry:
#ifdef LINUX
  hit->shf->n_evs = epoll_wait(hit->shf->ep, hit->shf->evs, hit->shf->max_evs, -1);
  if (hit->shf->n_evs == -1) {
    if (errno == EINTR) {
      D("EINTR fd(%x)", hit->shf->ep);
      goto retry;
    }
    ERR("epoll_wait(%x): %d %s", hit->shf->ep, errno, STRERROR(errno));
    return;
  }
  for (i = 0; i < hit->shf->n_evs; ++i) {
    io = (struct hi_io*)hit->shf->evs[i].data.ptr;
    io->events = hit->shf->evs[i].events;
    /* *** Should the todo_mut lock be batched? The advantage might not be big
     * as we need to either do pthread_cond_signal(3) to wake up one worker
     * or pthread_cond_broadcast(3) to wake them up all, which may be overkill.
     * N.B. hi_todo_produce() has logic to avoid enqueuing io that is closed. */
    hi_todo_produce(hit, &io->qel, "poll", 1);
  }
#endif
#ifdef SUNOS
  {
    struct dvpoll dp;
    dp.dp_timeout = -1;
    dp.dp_nfds = hit->shf->max_evs;
    dp.dp_fds = hit->shf->evs;
    hit->shf->n_evs = ioctl(hit->shf->ep, DP_POLL, &dp);
    if (hit->shf->n_evs < 0) {
      if (errno == EINTR) {
	D("EINTR fd(%x)", hit->shf->ep);
	goto retry;
      }
      ERR("/dev/poll ioctl(%x): %d %s", hit->shf->ep, errno, STRERROR(errno));
      return;
    }
    for (i = 0; i < hit->shf->n_evs; ++i) {
      io = hit->shf->ios + hit->shf->evs[i].fd;
      io->events = hit->shf->evs[i].revents;
      /* Poll says work is possible: sched wk for io if not under wk yet, or cur_pdu needs wk. */
      /*if (!io->cur_pdu || io->cur_pdu->need)   *** cur_pdu is always set */
      hi_todo_produce(hit, &io->qel, "poll", 1); /* *** should the todo_mut lock be batched? */
    }
  }
#endif
#if defined(MACOSX) || defined(FREEBSD)
  hit->shf->n_evs = kevent(hit->shf->ep, 0,0, hit->shf->evs, hit->shf->max_evs, &zero_timeout);
  if (hit->shf->n_evs == -1) {
    if (errno == EINTR) {
      D("EINTR fd(%x)", hit->shf->ep);
      goto retry;
    }
    ERR("epoll_wait(%x): %d %s", hit->shf->ep, errno, STRERROR(errno));
    return;
  }
  /* *** double check whether the evs (array of kevents) is in filedescriptor order */
  for (i = 0; i < hit->shf->n_evs; ++i) {
    io = (struct hi_io*)hit->shf->evs[i].data.ptr;
    io->events = hit->shf->evs[i].events;
    /* *** Should the todo_mut lock be batched? The advantage might not be big
     * as we need to either do pthread_cond_signal(3) to wake up one worker
     * or pthread_cond_broadcast(3) to wake them up all, which may be overkill.
     * N.B. hi_todo_produce() has logic to avoid enqueuing io that is closed. */
    hi_todo_produce(hit, &io->qel, "poll", 1);
  }
#endif
  LOCK(hit->shf->todo_mut, "todo_poll");
  D("POLL LK&UNLK todo_mut.thr=%lx repoll", (long)hit->shf->todo_mut.thr);
  hit->shf->poll_tok.proto = HIPROTO_POLL_ON;  /* special "on" flag - not a real protocol */
  UNLOCK(hit->shf->todo_mut, "todo_poll");
}

/*() Add file descriptor to poll
 * locking:: must be called inside io->qel.mut */

/* Called by:  hi_accept_book, hi_open_tcp x2, serial_init */
struct hi_io* hi_add_fd(struct hi_thr* hit, struct hi_io* io, int fd, int kind)
{
  ASSERTOPI(fd, <, hit->shf->max_ios);
  ASSERTOPI(io->n_thr, ==, 0);
  ++io->n_thr;  /* May be returned by poll at any time, thus there is "virtual thread" */
  
#ifdef LINUX
  {
    struct epoll_event ev;
    ev.events = EPOLLIN | EPOLLOUT | EPOLLERR | EPOLLHUP | EPOLLET;  /* ET == EdgeTriggered */
    ev.data.ptr = io;
    if (epoll_ctl(hit->shf->ep, EPOLL_CTL_ADD, fd, &ev)) {
      ERR("Unable to epoll_ctl(%d): %d %s", fd, errno, STRERROR(errno));
#ifdef USE_OPENSSL
      if (io->ssl) {
	SSL_free(io->ssl);
	io->ssl = 0;
      }
#endif
      close(fd);
      return 0;
    }
  }
#endif
#ifdef SUNOS
  {
    struct pollfd pfd;
    pfd.fd = fd;
    pfd.events = POLLIN | POLLOUT | POLLERR | POLLHUP;
    if (write(hit->shf->ep, &pfd, sizeof(pfd)) == -1) {
      ERR("Unable to write to /dev/poll fd(%d): %d %s", fd, errno, STRERROR(errno));
#ifdef USE_OPENSSL
      if (io->ssl) {
	SSL_free(io->ssl);
	io->ssl = 0;
      }
#endif
      close(fd);
      return 0;
    }
  }
#endif

#if defined(MACOSX) || defined(FREEBSD)
  {
    struct kevent kev;
    EV_SET(kev, fd, EVFILT_READ | EVFILT_WRITE, EV_ADD, 0, 0, &zero_timeout);
    if (kevent(hit->shf->ep, &kev, 1, 0,0,0) == -1) {
      ERR("kevent: fd(%d): %d %s", fd, errno, STRERROR(errno));
#ifdef USE_OPENSSL
      if (io->ssl) {
	SSL_free(io->ssl);
	io->ssl = 0;
      }
#endif
      close(fd);
      return 0;
    }
  }
#endif

  /* memset(io, 0, sizeof(struct hi_io)); *** MUST NOT clear as there are important fields like cur_pdu and lock initializations already set. All memory was zeroed in hi_new_shuff(). After that all changes should be field by field. */
  ASSERTOPI(io->writing, ==, 0);
  ASSERTOPI(io->reading, ==, 0);
  ASSERTOPI(io->n_to_write, ==, 0);
  ASSERTOPP(io->in_write, ==, 0);
  ASSERTOPP(io->to_write_consume, ==, 0);
  ASSERTOPP(io->to_write_produce, ==, 0);
  ASSERT(io->cur_pdu);  /* cur_pdu is always set to some value */
  ASSERTOPP(io->reqs, ==, 0);
  ASSERTOPP(io->pending, ==, 0);
  ASSERTOPI(io->qel.intodo, ==, HI_INTODO_SHF_FREE);
  io->qel.intodo = HI_INTODO_IOINUSE;
  //io->ap = io->m;       /* Nothing read yet */
  io->ent = 0;          /* Not authenticated yet */
  io->qel.kind = kind;
  io->fd = fd;          /* This change marks the slot as used in the big table. */
  return io;
}

/*() Remove files descriptor from poll. */

/* Called by:  hi_close */
void hi_del_fd(struct hi_thr* hit, int fd)
{
  ASSERTOPI(fd, <, hit->shf->max_ios);
#ifdef LINUX
  {
    if (epoll_ctl(hit->shf->ep, EPOLL_CTL_DEL, fd&0x7fffffff, 0)) {
      ERR("Unable to epoll_ctl(%x): %d %s", fd, errno, STRERROR(errno));
      /* N.B. Even if it fails, do not close the fd as we depend on that as synchronization. */
    }
  }
#endif
#ifdef SUNOS
  {
    struct pollfd pfd;
    pfd.fd = fd&0x7fffffff;
    pfd.events = 0 /*POLLIN | POLLOUT | POLLERR | POLLHUP*/; /* *** not sure if this is right */
    if (write(hit->shf->ep, &pfd, sizeof(pfd)) == -1) {
      ERR("Unable to write to /dev/poll fd(%x): %d %s", fd, errno, STRERROR(errno));
    }
  }
#endif
#if defined(MACOSX) || defined(FREEBSD)
  {
    struct kevent kev;
    EV_SET(kev, fd&0x7fffffff, EVFILT_READ | EVFILT_WRITE, EV_DEL, 0, 0, &zero_timeout);
    if (kevent(hit->shf->ep, &kev, 1, 0,0,0) == -1) {
      ERR("kevent: fd(%d): %d %s", fd, errno, STRERROR(errno));
    }
  }
#endif
}

/*() Create client socket. */

/* Called by:  smtp_send, zxbusd_main */
struct hi_io* hi_open_tcp(struct hi_thr* hit, struct hi_host_spec* hs, int proto)
{
  struct hi_io* io;
  int fd;
  if ((fd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
    ERR("Unable to create socket(AF_INET, SOCK_STREAM, 0) %d %s", errno, STRERROR(errno));
    return 0;
  }

  if (fd >= hit->shf->max_ios) {
    ERR("File descriptor limit(%d) exceeded fd=%d. Consider increasing the limit with -nfd flag, or figure out if there are any descriptor leaks.", hit->shf->max_ios, fd);
    goto errout;
  }
  io = hit->shf->ios + fd;
  io->qel.proto = proto;

  nonblock(fd);
  if (nkbuf)
    setkernelbufsizes(fd, nkbuf, nkbuf);
  
  if ((connect(fd, (struct sockaddr*)&hs->sin, sizeof(hs->sin)) == -1)
      && (errno != EINPROGRESS)) {
    ERR("Connection to %s failed: %d %s", hs->specstr, errno, STRERROR(errno));
    goto errout;
  }
  
  D("connect(%x) hs(%s)", fd, hs->specstr);
  /*SSL_CTX_add_extra_chain_cert(hit->shf->ssl_ctx, ca_cert);*/

#ifdef USE_OPENSSL
  if (hi_prototab[proto].is_tls) {
    --io->qel.proto;  /* Nonssl protocol is always one smaller than SSL variant. */
    io->ssl = SSL_new(hit->shf->ssl_ctx);
    if (!io->ssl) {
      ERR("TLS/SSL connect to(%s): SSL object initialization problem", hs->specstr);
      zx_report_openssl_err("open_tcp-ssl");
      goto errout;
    }
    if (!SSL_set_fd(io->ssl, fd)) {
      ERR("TLS/SSL connect to(%s): SSL fd(%x) initialization problem", hs->specstr, fd);
      zx_report_openssl_err("open_tcp-set_fd");
      goto sslerrout;
    }
    
#ifdef SSL_IMMEDIATE    
    switch (err = SSL_get_error(io->ssl, SSL_connect(io->ssl))) {
    case SSL_ERROR_NONE: break;
      /*case SSL_ERROR_WANT_ACCEPT:  documented, but undeclared */
    case SSL_ERROR_WANT_READ:
    case SSL_ERROR_WANT_CONNECT:
    case SSL_ERROR_WANT_WRITE: break;
    default:
      ERR("TLS/SSL connect to(%s): handshake problem (%d)", hs->specstr, err);
      zx_report_openssl_err("open_tcp-ssl_connect");
      write(fd, SSL_ENCRYPTED_HINT, sizeof(SSL_ENCRYPTED_HINT)-1);
      goto sslerrout;
    }
    if (!hi_vfy_peer_ssl_cred(hit, io, hs->specstr))
      goto sslerrout;
#else
    SSL_set_connect_state(io->ssl);
    /* *** how/when to hi_vfy_peer_ssl_cred() ? */
#endif
  }
  LOCK(io->qel.mut, "hi_open_tcp");
  hi_add_fd(hit, io, fd, HI_TCP_C);
  UNLOCK(io->qel.mut, "hi_open_tcp");
  return io;
 sslerrout:
  if (io->ssl) {
    SSL_free(io->ssl);
    io->ssl = 0;
  }
#else
  io->ssl = 0;
  LOCK(io->qel.mut, "hi_open_tcp-2");
  hi_add_fd(hit, io, fd, HI_TCP_C);
  UNLOCK(io->qel.mut, "hi_open_tcp-2");
  return io;
#endif
 errout:
  close(fd);
  return 0;
}

/*() Process half accepted socket (already accepted at socket layer, but
 * not yet booked in our data structures - perhaps due to delayed
 * booking used to cope with threads that are still looking at
 * the old connection. */

/* Called by:  hi_accept, hi_shuffle */
void hi_accept_book(struct hi_thr* hit, struct hi_io* io, int fd)
{
  int n_thr;
  struct hi_io* nio;

#ifdef USE_OPENSSL
  io->ssl = 0;
  D("proto(%d), is_tls=%d", io->qel.proto, hi_prototab[io->qel.proto].is_tls);
  if (hi_prototab[io->qel.proto].is_tls) {
    --io->qel.proto;  /* Non SSL protocol is always one smaller */
    D("SSL proto(%d)", io->qel.proto);
    io->ssl = SSL_new(hit->shf->ssl_ctx);
    if (!io->ssl) {
      ERR("TLS/SSL accept: SSL object initialization problem %d", 0);
      zx_report_openssl_err("accept-ssl");
      goto errout;
    }
    if (!SSL_set_fd(io->ssl, fd)) {
      ERR("TLS/SSL accept: fd(%x) SSL initialization problem", fd);
      zx_report_openssl_err("accept-set_fd");
      goto sslerrout;
    }

#ifdef SSL_IMMEDIATE    
    switch (err = SSL_get_error(io->ssl, SSL_accept(io->ssl))) {
    case SSL_ERROR_NONE: break;
      /*case SSL_ERROR_WANT_ACCEPT:  documented, but undeclared */
    case SSL_ERROR_WANT_READ:
    case SSL_ERROR_WANT_CONNECT:
    case SSL_ERROR_WANT_WRITE: break;
    default:
      ERR("TLS/SSL accept: connect or handshake problem (%d)", err);
      zx_report_openssl_err("accept-ssl_accept");
      write(fd, SSL_ENCRYPTED_HINT, sizeof(SSL_ENCRYPTED_HINT)-1);
      goto sslerrout;
    }
#else
    SSL_set_accept_state(io->ssl);
#endif
  }
#endif
  
  /* We may accept new connection with same fd as an old one before all references
   * to the old one are gone. We could try reference counting - or we can delay
   * fully closing the fd before every reference has gone away.
   * *** Arguably this should never happen due to our half close strategy
   * keeping the fd occupied until all threads really are gone. */
  LOCK(io->qel.mut, "hi_accept");
  D("ACCEPT LK&UNLK io(%x)->qel.thr=%lx", fd, (long)io->qel.mut.thr);
  n_thr = io->n_thr;
  if (n_thr) {
    D("old fd(%x) n_thr=%d still going", fd, n_thr);
    NEVERNEVER("NOT POSSIBLE due to half close n_thr=%d", n_thr);
    io->qel.kind = HI_HALF_ACCEPT;
    UNLOCK(io->qel.mut, "hi_accept-fail");
    hi_todo_produce(hit, &io->qel, "accept", 0);  /* schedule a new try */
    return;
  }

  nio = hi_add_fd(hit, io, fd, HI_TCP_S);
  UNLOCK(io->qel.mut, "hi_accept");
  if (!nio || nio != io) {
    ERR("Adding fd failed: io=%p nio=%p", io, nio);
    goto sslerrout;
  }
  INFO("ACCEPTed and booked(%x)", io->fd);  /* add IP and port of client */
  
  switch (io->qel.proto) {
  case HIPROTO_STOMP:
    /* *** Go straight to reading STOMP/CONNECT pdu without passing through TODO */
    break;
  case HIPROTO_SMTP: /* In SMTP, server starts speaking first */
    hi_sendf(hit, io, 0, 0, "220 %s smtp ready\r\n", SMTP_GREET_DOMAIN);
    io->ad.smtp.state = SMTP_START;
    break;
#ifdef ENA_S5066
  case HIPROTO_DTS:
    {
      struct hi_host_spec* hs;
      ZMALLOC(io->ad.dts);
      io->ad.dts->remote_station_addr[0] = 0x61;   /* three nibbles long (padded with zeroes) */
      io->ad.dts->remote_station_addr[1] = 0x45;
      io->ad.dts->remote_station_addr[2] = 0x00;
      io->ad.dts->remote_station_addr[3] = 0x00;
      if (!(hs = hi_prototab[HIPROTO_DTS].specs)) {
	ZMALLOC(hs);
	hs->proto = HIPROTO_DTS;
	hs->specstr = "dts:accepted:connections";
	hs->next = hi_prototab[HIPROTO_DTS].specs;
	hi_prototab[HIPROTO_DTS].specs = hs;
      }
      io->n = hs->conns;
      hs->conns = io;
    }
    break;
#endif
  }
  return;

 sslerrout:
#ifdef USE_OPENSSL
  if (io->ssl) {
    SSL_shutdown(io->ssl);
    SSL_free(io->ssl);
    io->ssl = 0;
  }
#endif
 errout:
  close(fd);
}

/*() Create server side worker socket by accept(2)ing from listener socket. */

/* Called by:  hi_shuffle */
void hi_accept(struct hi_thr* hit, struct hi_io* listener)
{
  struct hi_io* io;
  struct sockaddr_in sa;
  int fd;
  size_t size;
  size = sizeof(sa);
  D("accept from(%x)", listener->fd);
  if ((fd = accept(listener->fd, (struct sockaddr*)&sa, &size)) == -1) {
    if (errno != EAGAIN)
      ERR("Unable to accept from %x: %d %s", listener->fd, errno, STRERROR(errno));
    else
      D("accept(%x): EAGAIN", listener->fd);
    return;
  }
  if (fd >= hit->shf->max_ios) {
    ERR("accept: File descriptor limit(%d) exceeded fd=%d. Consider increasing the limit with -nfd flag, or figure out if there are any descriptor leaks.", hit->shf->max_ios, fd);
    close(fd);
    return;
  }
  nonblock(fd);
  if (nkbuf)
    setkernelbufsizes(fd, nkbuf, nkbuf);

  ++listener->n_read;  /* n_read counter is used for accounting accepts */
  io = hit->shf->ios + fd;
  io->qel.proto = listener->qel.proto;
  hi_accept_book(hit, io, fd);
  hi_todo_produce(hit, &listener->qel, "relisten", 0); /* Must exhaust accept: reenqueue (could also loop) */
}

/* EOF  --  hinet.c */
