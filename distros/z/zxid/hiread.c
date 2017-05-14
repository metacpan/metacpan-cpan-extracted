/* hiread.c  -  Hiquu I/O Engine Read Operations
 * Copyright (c) 2006,2012 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing. See file COPYING.
 * Special grant: hiread.c may be used with zxid open source project under
 * same licensing terms as zxid itself.
 * $Id$
 *
 * 15.4.2006, created over Easter holiday --Sampo
 * 16.8.2012, modified license grant to allow use with ZXID.org --Sampo
 * 19.8.2012, fixed serious free_pds manipulation bug in hi_pdu_alloc() --Sampo
 * 6.9.2012,  added support for TLS and SSL --Sampo
 *
 * Read more data to existing PDU (cur_pdu), or create new PDU and read data into it.
 */

#include <pthread.h>
#include <memory.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>
#include "akbox.h"
#include "hiios.h"
#include "hiproto.h"
#include "errmac.h"

#include <zx/zx.h>  /* for zx_report_openssl_err() */

extern int errmac_debug;

#define SSL_ENCRYPTED_HINT "ERROR\nmessage:tls-needed\n\nTLS or SSL connection wanted but other end did not speak protocol.\n\0"

/*() Allocate pdu.  First allocation from per thread pool is
 * attempted. This does not require any locking.  If that does not
 * work out, recourse to the shuffler level global pool, with locking, is made.
 * locking:: takes shf->pdu_mut
 * see also:: hi_pdu_free() */

/* Called by: */
struct hi_pdu* hi_pdu_alloc(struct hi_thr* hit, const char* lk)
{
  struct hi_pdu* pdu;

  HI_SANITY(hit->shf, hit);

  if (hit->free_pdus) {
    --hit->n_free_pdus;
    pdu = hit->free_pdus;
    hit->free_pdus = (struct hi_pdu*)pdu->qel.n;
    D("%s: alloc pdu_%p thr n_free=%d", lk, pdu, hit->n_free_pdus);
    ASSERTOPI(pdu->qel.intodo, ==, HI_INTODO_HIT_FREE);
    ASSERT(pdu != hit->free_pdus);
    goto retpdu;
  }

  LOCK(hit->shf->pdu_mut, "pdu_alloc");
  if (hit->shf->free_pdus) {
    pdu = hit->shf->free_pdus;
    hit->shf->free_pdus = (struct hi_pdu*)pdu->qel.n;
    D("%s: alloc pdu(%p) from shuff", lk, pdu);
    ASSERT(pdu != hit->shf->free_pdus);
    ASSERTOPI(pdu->qel.intodo, ==, HI_INTODO_SHF_FREE);
    UNLOCK(hit->shf->pdu_mut, "pdu_alloc-ok");
    goto retpdu;
  }
  UNLOCK(hit->shf->pdu_mut, "pdu_alloc-no-pdu");
  
  ERR("Out of PDUs. Use -npdu (current is %d) to specify a value at least the value of 4x nfd + 10x nthr + 5 = %d, or even bigger if there are many pending messages waiting for delivery. (%s)", hit->shf->max_pdus, hit->shf->max_ios*4+hit->shf->nthr*10+5, lk);
  return 0;

 retpdu:
  pdu->qel.intodo = HI_INTODO_PDUINUSE;
  pdu->lim = pdu->mem + HI_PDU_MEM;
  pdu->m = pdu->scan = pdu->ap = pdu->mem;
  pdu->req = pdu->parent = pdu->subresps = pdu->reals = pdu->synths = 0;
  pdu->fe = 0;
  pdu->need = 1;  /* trigger network I/O */
  pdu->n = 0;
  HI_SANITY(hit->shf, hit);
  return pdu;
}

/*() Check if there is more (than need for cur_pdu) in the input buffer.
 * Sometimes the input buffer contains more than
 * a PDU's worth and therefore needs to be prepared
 * as input for the next PDU.
 * The req->need field has to accurately reflact the size of the PDU. Typically
 * it is set in later stages of decoder.
 * As hi_checkmore() will cause cur_pdu to change, it is common to call hi_add_reqs() */

/* Called by:  hi_add_to_reqs */
static void hi_checkmore(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* req, int minlen)
{
  int n = req->ap - req->m;

  /* Allocate next io->cur_pdu here
   * a. because we already hold io->qel.mut (saves lock, otherwise hi_read() will alloc)
   * b. because we might need to copy tail of previous req to it */

  io->cur_pdu = hi_pdu_alloc(hit, "cur_pdu-ckm");
  if (!io->cur_pdu) {  hi_dump(hit->shf); NEVERNEVER("*** out of pdus in bad place %d", n); }
  io->cur_pdu->fe = io;
  io->cur_pdu->need = minlen;
  ++io->n_pdu_in;   /* stats */
  
  D("Chkmore(%x) mn=%d n=%d req_%p->need=%d", io->fd, minlen, n, req, req->need);
  ASSERT(minlen > 0);  /* If this is ever zero it will prevent hi_poll() from producing. */
  if (n > req->need) {
    memcpy(io->cur_pdu->ap, req->m + req->need, n - req->need);
    io->cur_pdu->ap += n - req->need;
    req->ap = req->m + req->need;      /* final length of decoded PDU */
  }
}

/*() Add a PDU to the reqs associated with the io object.
 * Often moving PDU to reqs means it should stop being cur_pdu.
 * If minlen (protocol dependent PDU minimum length) is passed,
 * hi_checkmore() processing is triggered and cur_pdu dealt with.
 * Clearing cur_pdu is important to enable the hi_in_out() to
 * admit new worker thread to perform read work.
 * locking:: takes io->qel.mut
 * see also:: hi_del_from_reqs() */

/* Called by:  http_decode, stomp_decode, stomp_frame_err, test_ping */
void hi_add_to_reqs(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* req, int minlen)
{
  LOCK(io->qel.mut, "add_to_reqs");
  D("LOCK io(%x)->qel.thr=%lx", io->fd, (long)io->qel.mut.thr);
  if (minlen) {
    ASSERTOPP(io->cur_pdu, ==, req);
    ASSERT(io->reading);
    io->reading = 0;  /* reading was set in hi_in_out() */
    D("Out of reading(%x) n_thr=%d (reset cur_pdu)", io->fd, io->n_thr);
    hi_checkmore(hit, io, req, minlen);
  }
  /* --io->n_thr; ASSERT(io->n_thr >= 0);  N.B. dec n_thr for read is handled in hi_read() */
  ASSERTOPP(req->fe, ==, io);
  req->n = io->reqs;
  io->reqs = req;
  D("UNLOCK io(%x)->qel.thr=%lx req_%p", io->fd, (long)io->qel.mut.thr, req);
  UNLOCK(io->qel.mut, "add_to_reqs");
}

/*() Read from the network, with all the repercussions.
 * When entering, n_thr will have been incremented for the read count.
 * No matter how many iterations may happen (and PDUs be processed),
 * the n_thr count will be decremented by one in end of this
 * function. There is no need to manipulate n_thr in decoders, but if
 * decoder also engages in write, this is handled in hi_send0(). */

/* Called by:  hi_in_out */
int hi_read(struct hi_thr* hit, struct hi_io* io)
{
  int ret,err;
  struct hi_pdu* pdu;
  while (1) {  /* eagerly read until we exhaust the read (c.f. edge triggered epoll) */
    ASSERT(io->reading);
    pdu = io->cur_pdu;
    D("loop(%x)->cur_pdu=%p ssl_%p", io->fd, pdu, io->ssl);
    ASSERT(pdu);  /* Exists either through hi_shuff_init() or through hi_check_more() */
  retry:
    D("read(%x) have=%d need=%d buf_avail=%d", io->fd, (int)(pdu->ap-pdu->m), pdu->need, (int)(pdu->lim-pdu->ap));
    ASSERT(io->reading);
#ifdef USE_OPENSSL
    if (io->ssl) {
      ret = SSL_read(io->ssl, pdu->ap, pdu->lim - pdu->ap);
      switch (err = SSL_get_error(io->ssl, ret)) {
      case SSL_ERROR_NONE: break; /* Something read case */
      case SSL_ERROR_WANT_READ:
	D("SSL EAGAIN READ fd(%x)", io->fd); /* Comparable to EAGAIN. Should we remember which? */
	//h->ioflags |= IO_MISSPOLL; /** Need more data after poll() **/
	zx_report_openssl_err("SSL again read"); /* *** do we need this to clear error stack? */
	goto eagain_out;
      case SSL_ERROR_WANT_WRITE:
	D("SSL EAGAIN WRITE fd(%x)", io->fd); /* Comparable to EAGAIN. Should we remember which? */
	zx_report_openssl_err("SSL again write"); /* *** do we need this to clear error stack? */
	goto eagain_out;
      case SSL_ERROR_ZERO_RETURN: D("SSL EOF fd(%x)", io->fd);	goto conn_close;
      default:
	ERR("SSL_read(%x) ret=%d err=%d", io->fd, ret, err);
	zx_report_openssl_err("SSL_read");
	if (!io->n_read) {
	  ERR("SSL Conn. failed(%x) ret=%d err=%d errno=%d %s", io->fd, ret, err, errno, STRERROR(errno));
	  if (errno != ECONNREFUSED)
	    write(io->fd, SSL_ENCRYPTED_HINT, sizeof(SSL_ENCRYPTED_HINT)-1);
	}
	/* N.B. A socket layer EOF not detected, but would be an I/O error from SSL perspective. */
	goto conn_close;
      }
    } else
#endif
    {
      ret = read(io->fd&0x7fffffff, pdu->ap, pdu->lim - pdu->ap); /* *** vs. need */
      switch (ret) {
      case 0:
	/* *** any provision to process still pending PDUs? */
	D("EOF fd(%x)", io->fd);
	goto conn_close;
      case -1:
	switch (errno) {
	case EINTR:  D("EINTR fd(%x)", io->fd); goto retry;
	case EAGAIN: D("EAGAIN READ fd(%x)", io->fd); goto eagain_out;  /* read(2) exhausted (c.f. edge triggered epoll) */
	default:
	  ERR("read(%x) failed: %d %s (closing connection)", io->fd, errno, STRERROR(errno));
	  goto conn_close;
	}
      }
    }
    /* something was read, invoke PDU parsing layer */
    D("got(%x)=%d, proto=%d cur_pdu(%p) need=%d", io->fd, ret, io->qel.proto, pdu, pdu->need);
    HEXDUMP("got:", pdu->ap, pdu->ap + ret, /*16*/ 256);
    pdu->ap += ret;
    io->n_read += ret;
    while (pdu
	   && pdu->need   /* no further I/O desired */
	   && pdu->need <= (pdu->ap - pdu->m)) {
      D("decode_loop io(%x)->cur_pdu=%p need=%d", io->fd, pdu, pdu?pdu->need:-99);
      ASSERTOPP(pdu, ==, io->cur_pdu);
      switch (io->qel.proto) {
	/* DISPATCH: Following decoders MUST either
	 * a. drop connection in which case any rescheduling is moot
	 * b. consume cur_pdu (set it to 0 or new PDU). This will cause
	 *    read to be consumed until exhausted, and later trigger new todo
	 *    when there is more data to be had, see hi_poll()
	 * c. take some other action such as scheduling PDU to todo. Typically
	 *    the req->need is zero when I/O is not expected.	   */
#ifdef ENA_S5066
      case HIPROTO_SIS:   if (sis_decode(hit, io))   goto conn_close;  break; /* *** use ret */
      case HIPROTO_DTS:   if (dts_decode(hit, io))   goto conn_close;  break; /* *** use ret */
#endif
      case HIPROTO_HTTP:  if (http_decode(hit, io))  goto conn_close;  break; /* *** use ret */
	//case HIPROTO_STOMP: if (stomp_decode(hit, io)) goto conn_close;  break;
      case HIPROTO_STOMP: ret = stomp_decode(hit, io);  break;
      case HIPROTO_TEST_PING: test_ping(hit, io);  break; /* *** use ret */
      case HIPROTO_SMTP: /* *** use ret */
	if (io->qel.kind == HI_TCP_C) {
	  if (smtp_decode_resp(hit, io))  goto out;
	} else {
	  if (smtp_decode_req(hit, io))   goto out;
	}
	break;
	/* *** add here a project dependent include? Or a macro. */
      default: NEVERNEVER("unknown proto(%x)", io->qel.proto);
      }
      
      /* Take another iteration. io->reading may have already been set (incompletely decoded
       * PDU) or it may have been cleared (completely decoded PDU). Additional
       * complication is that it may have been cleared during PDU processing, but
       * then set again bu a different thread, such as second reader. *** */
      
      switch (ret) {
      case HI_NOERR: /* 0: In this case io->reading has been cleared at hi_add_req() due to
		      * completely decoded PDU. It may have been acquired by other thread. */
	LOCK(io->qel.mut, "reset-reading");
	D("LOCK io(%x)->qel.thr=%lx n_c/t=%d/%d", io->fd, (long)io->qel.mut.thr, io->n_close, io->n_thr);
	if (io->reading) {
	  D("Somebody else already reading n_thr=%d", io->n_thr);
	  --io->n_thr;              /* Remove read count. */
	  ASSERT(io->n_thr >= 0);
	  ASSERT(hit->cur_io == io);
	  ASSERT(hit->cur_n_close == io->n_close);
	  hit->cur_io = 0;
	  D("UNLOCK io(%x)->qel.thr=%lx", io->fd, (long)io->qel.mut.thr);
	  UNLOCK(io->qel.mut, "reset-reading-abort");
	  return 0;
	}
	io->reading = 1;  /* reacquire */
	pdu = io->cur_pdu;
	D("reacquired reading(%x) n_thr=%d", io->fd, io->n_thr);
	D("UNLOCK io(%x)->qel.thr=%lx", io->fd, (long)io->qel.mut.thr);
	UNLOCK(io->qel.mut, "reset-reading");
	break;
      case HI_CONN_CLOSE:         goto conn_close_not_reading;
      case HI_NEED_MORE: /* 2: Incomplete decode, we still hold io->reading. */
	ASSERT(io->reading);
	break;
      }
    }
  }

 eagain_out:
  /* A special problem with EAGAIN: read(2) is not guaranteed to arm edge triggered epoll(2)
   * unless at least one EAGAIN read has happened. The problem is that as we are still
   * in io->reading, if after this EAGAIN another thread polls and consumes from todo, it
   * will not be able to read due to io->reading even though poll told it to read. After
   * missing the opportunity, the next poll will not report fd anymore because no read has
   * happened since previous report. Ouch!
   * Solution attempt: if read was polled, but could not be served due to io->reading.
   * the PDU is added back to the todo queue. This may cause the other thread to spin
   * for a while, but at least things will move on eventually. */
 out:
  LOCK(io->qel.mut, "clear-reading");
  D("RD-OUT: LOCK & UNLOCK io(%x)->qel.thr=%lx", io->fd, (long)io->qel.mut.thr);
  ASSERT(io->reading);
  io->reading = 0;
  --io->n_thr;              /* Remove read count. */
  ASSERT(hit->cur_io == io);
  ASSERT(hit->cur_n_close == io->n_close);
  hit->cur_io = 0;
  D("out of reading(%x) n_thr=%d", io->fd, io->n_thr);
  ASSERT(io->n_thr >= 0);
  UNLOCK(io->qel.mut, "clear-reading");
  return 0;

 conn_close:
  /* Connection close due to EOF, etc. We are still in io->reading. */
  LOCK(io->qel.mut, "clear-reading-close");
  D("RD-CLO: LOCK & UNLOCK io(%x)->qel.thr=%lx", io->fd, (long)io->qel.mut.thr);
  ASSERT(io->reading);
  io->reading = 0;
  --io->n_thr;                 /* Remove read count. */
  ASSERT(io->n_thr >= 0);
  D("out of reading(%x) n_thr=%d (close)", io->fd, io->n_thr);
  UNLOCK(io->qel.mut, "clear-reading-close");
  hi_close(hit, io, "hi_read");  /* will clear hit->cur_io */
  return 1;

 conn_close_not_reading:
  /* Connection close after PDU has been read, e.g. protocol level DISCONNECT.
   * We are no longer in io->reading (but other thread might be).
   * io->n_thr still needs to be decremented. */
  LOCK(io->qel.mut, "clear-reading-close");
  D("RD-NRC: LOCK & UNLOCK io(%x)->qel.thr=%lx", io->fd, (long)io->qel.mut.thr);
  /*ASSERT(!io->reading); This can not be asserted as other thread might have gone to read. */
  --io->n_thr;              /* Remove read count. */
  D("not_reading-close(%x) n_thr=%d r/w=%d/%d ev=%d", io->fd, io->n_thr, io->reading, io->writing, io->events);
  ASSERT(io->n_thr >= 0);
  UNLOCK(io->qel.mut, "not_reading-close");
  hi_close(hit, io, "hi_read-no_reading");  /* will clear hit->cur_io */
  return 1;
}

/* EOF  --  hiread.c */

#if 0

N.B. Be careful to link against same OPenSSL libraries as headers. Otherwise
reference count errors may appers (at least with 1.0.1 headers agains 1.0.0 libs).

Mystery SSL error (in the end caused by errors left in SSL stack by private key reading)

On LinuxMint 12 / Ubuntu / Debian
tb784d6e0    hiios.c:201 hi_new_shuffler  	zx d OpenSSL header-version(1000005f) lib-version(OpenSSL 1.0.0e 6 Sep 2011) cflags(compiler: cc -fPIC -DOPENSSL_PIC -DZLIB -DOPENSSL_THREADS -D_REENTRANT -DDSO_DLFCN -DHAVE_DLFCN_H -DL_ENDIAN -DTERMIO -O3 -Wa,--noexecstack -g -Wall) builton(built on: Thu Feb  9 00:57:05 UTC 2012) platform(platform: debian-i386) dir(OPENSSLDIR: "/usr/lib/ssl")

// On first connection, after several successful reads and writes

tb784d6e0   hiread.c:164 hi_read          	zx d read(9) have=0 need=6 buf_avail=3072
tb784d6e0   hiread.c:182 hi_read          	zx E SSL_read ret=-1 err=1
tb784d6e0    zxsig.c:404 zx_report_openssl_err 	zx E SSL_read: OpenSSL error(218529960) error:0D0680A8:asn1 encoding routines:ASN1_CHECK_TLEN:wrong tag (tasn_dec.c:1319): ? 0
tb784d6e0    zxsig.c:404 zx_report_openssl_err 	zx E SSL_read: OpenSSL error(218546234) error:0D06C03A:asn1 encoding routines:ASN1_D2I_EX_PRIMITIVE:nested asn1 error (tasn_dec.c:831): ? 0
tb784d6e0    zxsig.c:404 zx_report_openssl_err 	zx E SSL_read: OpenSSL error(218640442) error:0D08303A:asn1 encoding routines:ASN1_TEMPLATE_NOEXP_D2I:nested asn1 error (tasn_dec.c:751): Field=n, Type=RSA 3
tb784d6e0    zxsig.c:404 zx_report_openssl_err 	zx E SSL_read: OpenSSL error(67710980) error:04093004:rsa routines:OLD_RSA_PRIV_DECODE:RSA lib (rsa_ameth.c:115): ? 0

// On subsequent connections

tb784d6e0   hiread.c:164 hi_read          	zx d read(a) have=0 need=6 buf_avail=3072
tb784d6e0    hiios.c:116 zxbus_info_cb    	zx d SSL3 alert write:fatal:protocol version

tb784d6e0   hiread.c:182 hi_read          	zx E SSL_read ret=-1 err=1
tb784d6e0    zxsig.c:404 zx_report_openssl_err 	zx E SSL_read: OpenSSL error(336130315) error:1408F10B:SSL routines:SSL3_GET_RECORD:wrong version number (s3_pkt.c:339): ? 0

// Someone one the net has similar problem with postfix mail

http://old.nabble.com/error%3A1408F10B%3ASSL-routines%3ASSL3_GET_RECORD%3Awrong-version-number-td33867821.html

Known issue (20120518)

http://cvs.openssl.org/chngview?cn=22565

openssl/ssl/s3_pkt.c 1.72.2.7.2.15 -> 1.72.2.7.2.16

--- s3_pkt.c	2012/04/17 13:20:19	1.72.2.7.2.15
+++ s3_pkt.c	2012/05/11 13:32:26	1.72.2.7.2.16
@@ -744,6 +744,7 @@
 	 * bytes and record version number > TLS 1.0
 	 */
 	if (s->state == SSL3_ST_CW_CLNT_HELLO_B
+				&& !s->renegotiate
 				&& TLS1_get_version(s) > TLS1_VERSION)
 		*(p++) = 0x1;
 	else


#endif
