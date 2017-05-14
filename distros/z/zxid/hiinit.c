/* hiinit.c  -  Hiquu I/O Engine Initialization
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
 * 17.9.2012, factored init code to its own file --Sampo
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

/* Called by:  thread_loop, zxbusd_main */
void hi_hit_init(struct hi_thr* hit)
{
  memset(hit, 0, sizeof(struct hi_thr));
  hit->self = pthread_self();
}

#ifdef USE_OPENSSL
//int zxbus_cert_verify_cb(X509_STORE_CTX* st_ctx, void* arg) {  zxid_conf* cf = arg;  return 0; }
/* Called by: */
static int zxbus_verify_cb(int preverify_ok, X509_STORE_CTX* st_ctx)
{
  //X509* err_cert = X509_STORE_CTX_get_current_cert(st_ctx);
  int err;

  if (preverify_ok)
    return 1;  /* Always Good! */
  err = X509_STORE_CTX_get_error(st_ctx);
  D("verify err %d %s", err, X509_verify_cert_error_string(err));
  if (ONE_OF_4(err,
	       X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT,
	       X509_V_ERR_SELF_SIGNED_CERT_IN_CHAIN,
	       X509_V_ERR_UNABLE_TO_VERIFY_LEAF_SIGNATURE,
	       X509_V_ERR_CERT_UNTRUSTED))
    return 1;  /* ignore errors relating cert not being trusted */
  ERR("verify fail %d %s", err, X509_verify_cert_error_string(err));
  return 0;
}

/* Called by: */
static void zxbus_info_cb(const SSL *ssl, int where, int ret)
{
  const char *str;
  
  if ((where & ~SSL_ST_MASK) & SSL_ST_CONNECT) str="SSL_connect";
  else if ((where & ~SSL_ST_MASK) & SSL_ST_ACCEPT) str="SSL_accept";
  else str="undefined";
  
  if (where & SSL_CB_LOOP) {
    D("ssl_%p %s:%s", ssl, str, SSL_state_string_long(ssl));
  } else if (where & SSL_CB_ALERT) {
    str=(where & SSL_CB_READ)?"read":"write";
    D("ssl_%p SSL3 alert %s:%s:%s", ssl, str, SSL_alert_type_string_long(ret), SSL_alert_desc_string_long(ret));
  } else if (where & SSL_CB_EXIT) {
    if (ret == 0)
      D("ssl_%p %s:failed in %s", ssl, str, SSL_state_string_long(ssl));
    else if (ret < 0)
      D("ssl_%p %s:error in %s", ssl, str, SSL_state_string_long(ssl));
  }
}
#endif

/*() Allocate io structure (connection) pool and global PDU
 * pool, from which per thread pools will be plensihed - see
 * hi_pdu_alloc() - and initialize syncronization primitives. */

/* Called by:  zxbusd_main */
struct hiios* hi_new_shuffler(struct hi_thr* hit, int nfd, int npdu, int nch, int nthr)
{
  int i;
  struct hiios* shf;

  ZMALLOC(shf);
  hit->shf = shf;
  shf->nthr = nthr;
  
  /* Allocate global pool of PDUs (as a blob) */

  ZMALLOCN(shf->pdu_buf_blob, sizeof(struct hi_pdu)*npdu);
  shf->max_pdus = npdu;
  for (i = npdu - 1; i; --i) {  /* Link the PDUs to a list. */
    shf->pdu_buf_blob[i-1].qel.n = (struct hi_qel*)(shf->pdu_buf_blob + i);
    pthread_mutex_init(&shf->pdu_buf_blob[i].qel.mut.ptmut, MUTEXATTR);
  }
  pthread_mutex_init(&shf->pdu_buf_blob[0].qel.mut.ptmut, MUTEXATTR);
  shf->free_pdus = shf->pdu_buf_blob;  /* Make PDUs available as free. */
  pthread_mutex_init(&shf->pdu_mut.ptmut, MUTEXATTR);

  /* Allocate ios array as a blob and prepare them for I/O (by allocating cur_pdu) */
  
  ZMALLOCN(shf->ios, sizeof(struct hi_io) * nfd);
  shf->max_ios = nfd;
  for (i = 0; i < nfd; ++i) {
    pthread_mutex_init(&shf->ios[i].qel.mut.ptmut, MUTEXATTR);
    if (!(shf->ios[i].cur_pdu = hi_pdu_alloc(hit, "new_shuffler"))) {
      ERR("Out of PDUs when preparing cur_pdu for each I/O object. Use -npdu to specify a value at least twice the value of -nfd. Current values: npdu=%d, nfd=%d", npdu, nfd);
      exit(1);
    }
    shf->ios[i].cur_pdu->fe = &shf->ios[i];
  }
  
  pthread_cond_init(&shf->todo_cond, 0);
  pthread_mutex_init(&shf->todo_mut.ptmut, MUTEXATTR);

  shf->poll_tok.kind = HI_POLLT;          /* Permanently labeled as poll_tok (there is only 1) */
  shf->poll_tok.proto = HIPROTO_POLL_ON;  /* Mark poll token as available */

  shf->max_evs = MIN(nfd, 1024);
#ifdef LINUX
  shf->ep = epoll_create(nfd);
  if (shf->ep == -1) { perror("epoll"); exit(1); }
  ZMALLOCN(shf->evs, sizeof(struct epoll_event) * shf->max_evs);
#endif
#ifdef SUNOS
  shf->ep = open("/dev/poll", O_RDWR);
  if (shf->ep == -1) { perror("open(/dev/poll)"); exit(1); }
  ZMALLOCN(shf->evs, sizeof(struct pollfd) * shf->max_evs);
#endif
#if defined(MACOSX) || defined(FREEBSD)
  shf->ep = kqueue();
  if (shf->ep == -1) { perror("kqueue()"); exit(1); }
  ZMALLOCN(shf->evs, sizeof(struct kevent) * shf->max_evs);
#endif

  pthread_mutex_init(&shf->ent_mut.ptmut, MUTEXATTR);

  shf->max_chs = nch;
  ZMALLOCN(shf->chs, sizeof(struct hi_ch) * shf->max_chs);

#ifdef USE_OPENSSL
  SSL_load_error_strings();
  SSL_library_init();
#if 0
  shf->ssl_ctx = SSL_CTX_new(SSLv23_method());
#else
  shf->ssl_ctx = SSL_CTX_new(TLSv1_method());
#endif
  if (!shf->ssl_ctx) {
    ERR("SSL context initialization problem %d", 0);
    zx_report_openssl_err("new_shuffler-ssl_ctx");
    return 0;
  }
  INFO("OpenSSL header-version(%lx) lib-version(%lx)(%s) %s %s %s %s", OPENSSL_VERSION_NUMBER, SSLeay(), SSLeay_version(SSLEAY_VERSION), SSLeay_version(SSLEAY_CFLAGS), SSLeay_version(SSLEAY_BUILT_ON), SSLeay_version(SSLEAY_PLATFORM), SSLeay_version(SSLEAY_DIR));
  if (errmac_debug>1)
    SSL_CTX_set_info_callback(shf->ssl_ctx, zxbus_info_cb);

  /*SSL_CTX_set_mode(shf->ssl_ctx, SSL_MODE_AUTO_RETRY); R/W only return w/complete. We use nonblocking I/O. */

  /* Verification strategy: do not attempt verification at SSL layer. Instead
   * check the result afterwards against metadata based cert. However,
   * we need to specify SSL_VERIFY_PEER to cause server to ask for ClientTLS.
   * Normally this would cause the verification to happen, but we supply
   * a callback that effectively causes verification to pass in any case,
   * so that we postpone it to the moment when we see CONNECT. */
  SSL_CTX_set_verify(shf->ssl_ctx, SSL_VERIFY_PEER | SSL_VERIFY_CLIENT_ONCE, zxbus_verify_cb);
  //SSL_CTX_set_cert_verify_callback(shf->ssl_ctx, zxbus_cert_verify_cb, cf);

  /*SSL_CTX_load_verify_locations() SSL_CTX_set_client_CA_list(3) SSL_CTX_set_cert_store(3) */
  if (!zxbus_cf->enc_cert)
    zxbus_cf->enc_cert = zxid_read_cert(zxbus_cf, "enc-nopw-cert.pem");
  if (!zxbus_cf->enc_pkey)
    zxbus_cf->enc_pkey = zxid_read_private_key(zxbus_cf, "enc-nopw-cert.pem");
  if (!SSL_CTX_use_certificate(shf->ssl_ctx, zxbus_cf->enc_cert)) {
    ERR("SSL certificate problem %d", 0);
    zx_report_openssl_err("new_shuffler-cert");
    return 0;
  }
  if (!SSL_CTX_use_PrivateKey(shf->ssl_ctx, zxbus_cf->enc_pkey)) {
    ERR("SSL private key problem %d", 0);
    zx_report_openssl_err("new_shuffler-privkey");
    return 0;
  }
  if (!SSL_CTX_check_private_key(shf->ssl_ctx)) {
    ERR("SSL certificate-private key consistency problem %d", 0);
    zx_report_openssl_err("new_shuffler-chk-privkey");
    return 0;
  }
#endif
  return shf;
}

/* EOF  --  hiinit.c */
