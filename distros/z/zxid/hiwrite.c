/* hiwrite.c  -  Hiquu I/O Engine Write Operation.
 * Copyright (c) 2006,2012 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing. See file COPYING.
 * Special grant: hiwrite.c may be used with zxid open source project under
 * same licensing terms as zxid itself.
 * $Id$
 *
 * 15.4.2006, created over Easter holiday --Sampo
 * 22.4.2006, refined multi iov sends over the weekend --Sampo
 * 16.8.2012, modified license grant to allow use with ZXID.org --Sampo
 * 6.9.2012,  added support for TLS and SSL --Sampo
 *
 * Idea: Consider separate lock for maintenance of to_write queue and separate
 * for in_write, iov, and actual wrintev().
 */

#include <pthread.h>
#include <memory.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "platform.h"
#include "errmac.h"
#include "akbox.h"
#include "hiios.h"
#include <zx/zx.h>   /* for zx_report_openssl_err() */

extern int errmac_debug;

/* Alias some struct fields for headers that can not be seen together. */
/* *** this is really STOMP 1.1 specific */
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
#define zx_rcpt_sig dest

/*() Schedule to be sent a response.
 * If req is supplied, the response is taken to be response to that.
 * Otherwise resp istreated as a stand along PDU, unsolicited response if you like.
 * locking:: will take io->qel.mut */

/* Called by:  hi_send1, hi_send2, hi_send3 */
void hi_send0(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* parent, struct hi_pdu* req, struct hi_pdu* resp)
{
  struct hi_io* read_io;
  int write_now = 0;
  HI_SANITY(hit->shf, hit);
  if (req) {
    resp->req = req;
    resp->n = req->reals;
    req->reals = resp;
    req->parent = parent;
  } else {
    resp->req = resp->n = 0;
  }
  resp->parent = parent;

  LOCK(io->qel.mut, "send0");
  if (!resp->req) {
    /* resp is really a request sent by server to the client */
    /* *** this is really STOMP 1.1 specific. Ideally msg_id
     * and dest would already be set by the STOMP layer before
     * calling this - or there should be dispatch to protocol
     * specific method to recover them. */
    resp->ad.stomp.msg_id = strstr(resp->m, "\nmessage-id:");
    if (resp->ad.stomp.msg_id) {
      resp->ad.stomp.msg_id += sizeof("\nmessage-id:")-1;
      resp->n = io->pending;  /* add to io->pending, protected by io->qel.mut */
      io->pending = resp;
      resp->ad.stomp.dest = strstr(resp->m, "\ndestination:");
      if (resp->ad.stomp.dest)
	resp->ad.stomp.dest += sizeof("\ndestination:")-1;
      resp->ad.stomp.body = strstr(resp->m, "\n\n");
      if (resp->ad.stomp.body) {
	resp->ad.stomp.body += sizeof("\n\n")-1;
	resp->ad.stomp.len = resp->ap - resp->ad.stomp.body - 1 /* nul at end of frame */;
      } else
	resp->ad.stomp.len = 0;
      D("pending resp_%p msgid(%.*s)", resp, (int)(strchr(resp->ad.stomp.msg_id,'\n')-resp->ad.stomp.msg_id), resp->ad.stomp.msg_id);
    } else {
      ERR("request from server to client lacks message-id header and thus can not expect an ACK. Not scheduling as pending. %p", resp);
    }
  }
  
  if (ONE_OF_2(io->n_thr, HI_IO_N_THR_END_GAME, HI_IO_N_THR_END_POLL)) {
    D("LK&UNLK end-game io(%x)->qel.thr=%lx n_c/t=%d/%d", io->fd, (long)io->qel.mut.thr, io->n_close,io->n_thr);
    UNLOCK(io->qel.mut, "send0-end");
    return; /* Ignore write attempt. hi_todo_consume() will eventually call hi_close() last time */
  }
  D("LOCK io(%x)->qel.thr=%lx n_c/t=%d/%d", io->fd, (long)io->qel.mut.thr, io->n_close,io->n_thr);
  
  ASSERT(io->n_thr >= 0);
  if (!io->to_write_produce)
    io->to_write_consume = resp;
  else
    io->to_write_produce->qel.n = &resp->qel;
  io->to_write_produce = resp;
  resp->qel.n = 0;
  ++io->n_to_write;
  ++io->n_pdu_out;
  ++io->n_thr;           /* Account for anticipated call to hi_write() or hi_todo_produce() */
  if (!io->writing) {
    io->writing = write_now = 1;
    D("stash cur_io(%x)->n_close=%d, io(%x) n_close=%d", hit->cur_io?hit->cur_io->fd:-1, hit->cur_n_close, io->fd, io->n_close);
    read_io = hit->cur_io;
    hit->cur_io = io;
    hit->cur_n_close = io->n_close;
  }
  io->events |= EPOLLOUT;  /* Set write event in case there is no poll before write opportunity. */
  D("UNLOCK io(%x)->qel.thr=%lx", io->fd, (long)io->qel.mut.thr);
  UNLOCK(io->qel.mut, "send0");
  
  HI_SANITY(hit->shf, hit);
  ASSERT(req != resp);
  D("send fd(%x) parent_%p req_%p resp_%p n_iov=%d iov0(%.*s)", io->fd, parent, req, resp, resp->n_iov, (int)MIN(resp->iov->iov_len,3), (char*)resp->iov->iov_base);

  if (write_now) {
    /* Try cranking the write machine right away! *** should we fish out any todo queue item that may stomp on us? How to deal with thread that has already consumed from the todo_queue? */
    hi_write(hit, io);   /* Will decrement io->n_thr for write */
    hit->cur_io = read_io;
    if (read_io) {
      hit->cur_n_close = read_io->n_close;
      D("restored cur_io(%x)->n_close=%d", hit->cur_io?hit->cur_io->fd:-1, hit->cur_n_close);
    }
  } else {
    hi_todo_produce(hit, &io->qel, "send0", 0);
  }
}

/*() Frontend to hi_send1() which uses hi_send0() to send one segment message. */

/* Called by:  http_send_err, test_ping_reply */
void hi_send(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* parent, struct hi_pdu* req, struct hi_pdu* resp)
{
  hi_send1(hit, io, parent, req, resp, resp->need, resp->m);
}

/*() Uses hi_send0() to send one segment message. */

/* Called by:  hi_send, hi_sendf, smtp_resp_wait_250_from_ehlo, smtp_resp_wait_354_from_data, smtp_send */
void hi_send1(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* parent, struct hi_pdu* req, struct hi_pdu* resp, int len0, char* d0)
{
  resp->n_iov = 1;
  resp->iov[0].iov_len = len0;
  resp->iov[0].iov_base = d0;
  //HEXDUMP("iov0: ", d0, d0+len0, 800);
  hi_send0(hit, io, parent, req, resp);
}

/*() Uses hi_send0() to send two segment message. */

/* Called by:  hmtp_send */
void hi_send2(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* parent, struct hi_pdu* req, struct hi_pdu* resp, int len0, char* d0, int len1, char* d1)
{
  resp->n_iov = 2;
  resp->iov[0].iov_len  = len0;
  resp->iov[0].iov_base = d0;
  resp->iov[1].iov_len  = len1;
  resp->iov[1].iov_base = d1;
  //HEXDUMP("iov0: ", d0, d0+len0, 800);
  //HEXDUMP("iov1: ", d1, d1+len1, 800);
  hi_send0(hit, io, parent, req, resp);
}

/*() Uses hi_send0() to send three segment message. */

/* Called by:  hmtp_send */
void hi_send3(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* parent, struct hi_pdu* req, struct hi_pdu* resp, int len0, char* d0, int len1, char* d1, int len2, char* d2)
{
  resp->n_iov = 3;
  resp->iov[0].iov_len  = len0;
  resp->iov[0].iov_base = d0;
  resp->iov[1].iov_len  = len1;
  resp->iov[1].iov_base = d1;
  resp->iov[2].iov_len  = len2;
  resp->iov[2].iov_base = d2;
  //HEXDUMP("iov0: ", d0, d0+len0, 800);
  //HEXDUMP("iov1: ", d1, d1+len1, 800);
  //HEXDUMP("iov2: ", d2, d2+len2, 800);
  hi_send0(hit, io, parent, req, resp);
}

/*() Send formatted response.
 * Uses underlying machiner of hi_send0().
 * *** As req argument is entirely lacking, this must be to send unsolicited responses. */

/* Called by:  hi_accept_book, smtp_data, smtp_ehlo, smtp_mail_from x2, smtp_rcpt_to x3, smtp_resp_wait_220_greet, smtp_resp_wait_250_msg_sent, stomp_cmd_ni, stomp_err, stomp_got_login, stomp_got_send, stomp_msg_deliver, stomp_send_receipt */
void hi_sendf(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* parent, struct hi_pdu* req, char* fmt, ...)
{
  va_list pv;
  struct hi_pdu* pdu = hi_pdu_alloc(hit, "send");
  if (!pdu) { hi_dump(hit->shf); NEVERNEVER("Out of PDUs in bad place. fmt(%s)", fmt); }
  
  va_start(pv, fmt);
  pdu->need = vsnprintf(pdu->m, pdu->lim - pdu->m, fmt, pv);
  va_end(pv);
  
  pdu->ap += pdu->need;
  hi_send1(hit, io, parent, req, pdu, pdu->need, pdu->m);
}

/*() Process io->to_write_consume to produce an iov and move the PDUs to io->in_write.
 * This is the main (only?) way how writes end up in hiios poll machinery to be written.
 * The only consumer of the io->to_write_consume queue.
 * Must only be called with io->qel.mut held. */

/* Called by:  hi_in_out, hi_make_iov */
void hi_make_iov_nolock(struct hi_io* io)
{
  struct hi_pdu* pdu;
  struct iovec* lim = io->iov+HI_N_IOV;
  struct iovec* cur = io->iov_cur = io->iov;
  D("make_iov(%x) n_to_write=%d", io->fd, io->n_to_write);
  while ((pdu = io->to_write_consume) && (cur + pdu->n_iov) <= lim) {
    memcpy(cur, pdu->iov, pdu->n_iov * sizeof(struct iovec));
    cur += pdu->n_iov;
    
    if (!(io->to_write_consume = pdu->wn)) /* consume from to_write */
      io->to_write_produce = 0;
    --io->n_to_write;
    pdu->wn = io->in_write;                /* produce to in_write so pdu can eventually be freed */
    io->in_write = pdu;
    
    ASSERT(io->n_to_write >= 0);
    ASSERT(pdu->n_iov && pdu->iov[0].iov_len);   /* Empty writes can lead to infinite loops */
    D("make_iov(%x) added pdu(%p) n_iov=%d", io->fd, pdu, (int)(cur - io->iov_cur));
  }
  io->n_iov = cur - io->iov_cur;
}

/*() The locked (and usual) way of calling hi_make_iov_nolock() */

/* Called by:  hi_write */
static void hi_make_iov(struct hi_io* io)
{
  LOCK(io->qel.mut, "make_iov");
  D("LOCK io(%x)->qel.thr=%lx", io->fd, (long)io->qel.mut.thr);
  hi_make_iov_nolock(io);
  D("UNLOCK io(%x)->qel.thr=%lx", io->fd, (long)io->qel.mut.thr);
  UNLOCK(io->qel.mut, "make_iov");
}

#define HIT_FREE_HIWATER 10  /* Maximum number of per thread free PDUs */
#define HIT_FREE_LOWATER 5   /* How many PDS to move from hit to shf if HIWATER is exceeded. */

/*() Low level call to Free a PDU. Usually you would call hi_free_resp() instead.
 * Usually frees to hit->free_pdus, but if that grows
 * too long, then to shf->free_pdus, to avoid over accumulation
 * of PDUs in single thread (i.e. allocated in one, but freed in another).
 * locking:: will use shf->pdu_mut
 * see also:: hi_pdu_alloc() */

/* Called by:  hi_free_req x2, hi_free_resp */
static void hi_pdu_free(struct hi_thr* hit, struct hi_pdu* pdu, const char* lk1, const char* lk2)
{
  int i;

  ASSERT(!ONE_OF_2(pdu->qel.intodo, HI_INTODO_SHF_FREE, HI_INTODO_HIT_FREE));
  pdu->qel.n = &hit->free_pdus->qel;         /* move to hit free list */
  hit->free_pdus = pdu;
  ++hit->n_free_pdus;
  pdu->qel.intodo = HI_INTODO_HIT_FREE;
  D("%s%s: pdu_%p freed (%.*s) n_free=%d",lk1,lk2, pdu, (int)MIN(pdu->ap - pdu->m,3), pdu->m, hit->n_free_pdus);
  
  if (hit->n_free_pdus <= HIT_FREE_HIWATER)  /* high water mark */
    return;

  D("%s%s: pdu_%p mv some hit->free_pdus to shf",lk1,lk2,pdu);
  LOCK(hit->shf->pdu_mut, "pdu_free");
  for (i = HIT_FREE_LOWATER; i; --i) {
    pdu = hit->free_pdus;
    hit->free_pdus = (struct hi_pdu*)pdu->qel.n;

    D("%s%s: mv hit free pdu_%p to shf",lk1,lk2,pdu);

    pdu->qel.n = &hit->shf->free_pdus->qel;         /* move to free list */
    hit->shf->free_pdus = pdu;
    ASSERTOPI(pdu->qel.intodo, ==, HI_INTODO_HIT_FREE);
    pdu->qel.intodo = HI_INTODO_SHF_FREE;
  }
  UNLOCK(hit->shf->pdu_mut, "pdu_free");
  hit->n_free_pdus -= HIT_FREE_LOWATER;
}

/*() Free a response PDU.
 * *** Here complex determination about freeability of a PDU needs to be done.
 * For now we "fake" it by assuming that a response sufficies to free request.
 * In real life you would have to consider
 * a. multiple responses
 * b. subrequests and their responses
 * c. possibility of sending a response before processing of request itself has ended
 * locking:: Called outside io->qel.mut */

/* Called by:  hi_free_in_write, stomp_got_ack x2, stomp_got_nack */
void hi_free_resp(struct hi_thr* hit, struct hi_pdu* resp, const char* lk1)
{
  struct hi_pdu* pdu = resp->req->reals;
  
  HI_SANITY(hit->shf, hit);

  /* Remove resp from request's real response list. resp MUST be in this list: if it
   * is not, pdu->n (next) pointer chasing will lead to NULL dereference (by design). */
  
  if (resp == pdu)
    resp->req->reals = pdu->n;
  else
    for (; pdu; pdu = pdu->n)
      if (pdu->n == resp) {
	pdu->n = resp->n;
	break;
      }
  
  hi_pdu_free(hit, resp, lk1, "free_resp");
  HI_SANITY(hit->shf, hit);
}

/*() Free a request, and transitively its real consequences (response, subrequests, etc.).
 * May be called either because individual resp was done, or because of connection close.
 * locking:: Called outside io->qel.mut */

/* Called by:  hi_close x3, hi_free_req_fe, stomp_got_ack, stomp_got_nack, stomp_msg_deliver */
void hi_free_req(struct hi_thr* hit, struct hi_pdu* req, const char* lk1)
{
  struct hi_pdu* pdu;
  
  HI_SANITY(hit->shf, hit);

  for (pdu = req->reals; pdu; pdu = pdu->n)  /* free dependent resps */
    hi_pdu_free(hit, pdu, lk1, "free_req-real");
  
  hi_pdu_free(hit, req, lk1, "free_req");
  HI_SANITY(hit->shf, hit);
}

/*() Remove a PDU from the reqs list of an io object.
 * Also looks in the pending list.
 * locking:: takes io->qel.mut
 * see also:: hi_add_to_reqs() */

/* Called by:  hi_free_req_fe, stomp_got_ack */
void hi_del_from_reqs(struct hi_io* io, struct hi_pdu* req)
{
  struct hi_pdu* pdu;
  LOCK(io->qel.mut, "del-from-reqs");
  pdu = io->reqs;
  if (pdu == req) {
    io->reqs = req->n;
  } else {
    for (; pdu; pdu = pdu->n) {
      if (pdu->n == req) {
	pdu->n = req->n;
	goto out;
      }
    }
    pdu = io->pending;
    if (pdu == req) {
      io->pending = req->n;
    } else {
      for (; pdu; pdu = pdu->n) {
	if (pdu->n == req) {
	  pdu->n = req->n;
	  goto out;
	}
      }
    }
    ERR("req(%p) not found in fe(%x)->reqs or pending", req, io->fd);
    /*NEVERNEVER("req not found in fe(%x)->reqs or pending", io->fd); can happen for cur_pdu */
  out: ;
  }
  UNLOCK(io->qel.mut, "del-from-reqs");
}

/*() Free a request, assuming it is associated with a frontend.
 * Will also remove the PDU from the frontend reqs queue.
 * locking:: called outside io->qel.mut, takes it indirectly */

/* Called by:  hi_free_in_write */
static void hi_free_req_fe(struct hi_thr* hit, struct hi_pdu* req)
{
  ASSERT(req->fe);
  if (!req->fe)
    return;
  HI_SANITY(hit->shf, hit);

  /* Scan the frontend to find the reference. The theory is that
   * hi_free_req_fe() only gets called when its known that the request is in the queue.
   * If it is not, the loop will run off the end and crash with NULL pointer. */
  hi_del_from_reqs(req->fe, req);
  HI_SANITY(hit->shf, hit);
  hi_free_req(hit, req, "req_fe ");
}

/*() Free the contents of io->in_write list and anything that depends from it.
 * This is called either after successful write, by hi_clear_iov(), or failed
 * write when close will mean that no further writes will be attempted.
 * locking:: called outside io->qel.mut */

/* Called by:  hi_clear_iov, hi_write */
static void hi_free_in_write(struct hi_thr* hit, struct hi_io* io)
{
  struct hi_pdu* req;
  struct hi_pdu* resp;
  D("freeing resps&reqs io(%x)->in_write=%p", io->fd, io->in_write);

  while (resp = io->in_write) {
    io->in_write = resp->wn;
    resp->wn = 0;
    
    if (!(req = resp->req)) continue;  /* It is a request */
    
    /* Only a response can cause anything freed, and every response is freeable upon write. */
    
    hi_free_resp(hit, resp, "in_write ");
    if (!req->reals)                   /* last response, free the request */
      hi_free_req_fe(hit, req);
  }
}

/*() Post process iov after write.
 * Determine if any (resp) PDUs got completely written and
 * warrant deletion of entire chaing of req and responses,
 * including subreqs and their responses.
 * locking:: called outside io->qel.mut */

/* Called by:  hi_write x2 */
static void hi_clear_iov(struct hi_thr* hit, struct hi_io* io, int n)
{
  io->n_written += n;
  while (io->n_iov && n) {
    if (n >= io->iov_cur->iov_len) {
      n -= io->iov_cur->iov_len;
      ++io->iov_cur;
      --io->n_iov;
      ASSERTOPP(io->iov_cur, >=, 0);
    } else {
      /* partial write: need to adjust iov_cur->iov_base */
      io->iov_cur->iov_base = ((char*)(io->iov_cur->iov_base)) + n;
      io->iov_cur->iov_len -= n;
      return;  /* we are not in end so nothing to free */
    }
  }
  ASSERTOPI(n, ==, 0);
  if (io->n_iov)
    return;
  
  /* Everything has now been written. Time to free in_write list. */
  
  hi_free_in_write(hit, io);
}

/*() Attempt to write pending iovs.
 * This function can only be called by one thread at a time because the todo_queue
 * only admits an io object once and only one thread can consume it. Thus locking
 * is really needed only to protect the to_write queue, see hi_make_iov().
 * Return:: 1 if connection got closed (and n_thr decremented),
 *     0 if connection remains open (permitting, e.g., a read(2)). */

/* Called by:  hi_in_out, hi_send0 */
int hi_write(struct hi_thr* hit, struct hi_io* io)
{
  int ret,err;
  ASSERT(io->writing);
  while (1) {   /* Write until exhausted! */
    if (!io->in_write)  /* Need to prepare new iov? */
      hi_make_iov(io);
    if (!io->in_write)
      goto out;         /* Nothing further to write */
  retry:
    ASSERT(io->writing);
#ifdef USE_OPENSSL
    if (io->ssl) {
      D("SSL_write(%x) n_iov=%d n_thr=%d r/w=%d/%d ev=%x", io->fd, io->n_iov, io->n_thr, io->reading, io->writing, io->events);
      HEXDUMP("iov0:", io->iov_cur->iov_base, io->iov_cur->iov_base + io->iov_cur->iov_len, /*16*/ 256);
      /* N.B. As SSL_write() does not support vector of iovs, we just write the
       * first iov here. Eventually the loop will iterate and others get written. */
      ret = SSL_write(io->ssl, io->iov_cur->iov_base, io->iov_cur->iov_len);
      ASSERT(io->writing);
      switch (err = SSL_get_error(io->ssl, ret)) {
      case SSL_ERROR_NONE:  /* Something written case */
	D("SSL_wrote(%x) %d bytes n_thr=%d r/w=%d/%d ev=%x", io->fd, ret, io->n_thr, io->reading, io->writing, io->events);
	hi_clear_iov(hit, io, ret);
	break; /* iterate write loop again */
      case SSL_ERROR_WANT_READ:
	D("SSL EAGAIN READ fd(%x)", io->fd);
	zx_report_openssl_err("SSL again read"); /* *** do we need this to clear error stack? */
	goto out; /* Comparable to EAGAIN. Should we remember which? */
      case SSL_ERROR_WANT_WRITE:
	D("SSL EAGAIN WRITE fd(%x)", io->fd);
	zx_report_openssl_err("SSL again write"); /* *** do we need this to clear error stack? */
	goto out; /* Comparable to EAGAIN. Should we remember which? */
      case SSL_ERROR_ZERO_RETURN: /* Probably close from other end */
      default:
	ERR("SSL_write ret=%d err=%d", ret, err);
	zx_report_openssl_err("SSL_write");
	goto clear_writing_err;
      }
    } else
#endif
    {
      D("writev(%x) n_iov=%d n_thr=%d r/w=%d/%d ev=%x", io->fd, io->n_iov, io->n_thr, io->reading, io->writing, io->events);
      HEXDUMP("iov0:", io->iov_cur->iov_base, io->iov_cur->iov_base + io->iov_cur->iov_len, /*16*/ 256);
      ret = writev(io->fd&0x7fffffff /* in case of write after close */, io->iov_cur, io->n_iov);
      ASSERT(io->writing);
      switch (ret) {
      case 0: NEVERNEVER("writev on %x returned 0", io->fd);
      case -1:
	switch (errno) {
	case EINTR:  D("EINTR fd(%x)", io->fd); goto retry;
	case EAGAIN: D("EAGAIN WRITE fd(%x)", io->fd); goto out;   /* writev(2) exhausted (c.f. edge triggered epoll) */
	default:
	  ERR("writev(%x) failed: %d %s (closing connection)", io->fd, errno, STRERROR(errno));
	  goto clear_writing_err;
	}
      default:  /* something was written, deduce it from the iov */
	D("wrote(%x) %d bytes n_thr=%d r/w=%d/%d ev=%x", io->fd, ret, io->n_thr, io->reading, io->writing, io->events);
	hi_clear_iov(hit, io, ret);
      }
    }
  }
 out:
  LOCK(io->qel.mut, "clear-writing");   /* The io->writing was set in hi_in_out() or hi_send0() */
  D("WR-OUT: LOCK & UNLOCK io(%x)->qel.thr=%lx", io->fd, (long)io->qel.mut.thr);
  ASSERT(io->writing);
  io->writing = 0;
  --io->n_thr;
  ASSERT(io->n_thr >= 0);
  UNLOCK(io->qel.mut, "clear-writing");
  return 0;

 clear_writing_err:
  hi_free_in_write(hit, io);
  LOCK(io->qel.mut, "clear-writing-err");   /* The io->writing was set in hi_in_out() */
  D("WR-FAIL: LK&UNLK io(%x)->qel.thr=%lx", io->fd, (long)io->qel.mut.thr);
  ASSERT(io->writing);
  io->writing = 0;
  --io->n_thr;
  ASSERT(io->n_thr >= 0);
  UNLOCK(io->qel.mut, "clear-writing-err");
  hi_close(hit, io, "hi_write");
  return 1;
}

/* EOF  --  hiwrite.c */
