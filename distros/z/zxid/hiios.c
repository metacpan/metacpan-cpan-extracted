/* hiios.c  -  Hiquu I/O Engine I/O shuffler
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
 * 17.9.2012, factored init, todo, and net code to their own files --Sampo
 *
 * See http://pl.atyp.us/content/tech/servers.html for inspiration on threading strategy.
 *
 *   MANY ELEMENTS IN QUEUE            ONE ELEMENT IN Q   EMPTY QUEUE
 *   consume             produce       consume  produce   consume  produce
 *    |                   |             | ,-------'         |        |
 *    V                   V             V V                 V        V
 *   qel.n --> qel.n --> qel.n --> 0   qel.n --> 0          0        0
 *
 * *** see if edge triggered epoll has some special consideration for accept(2).
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

extern int errmac_debug;
#ifdef MUTEX_DEBUG
extern pthread_mutexattr_t MUTEXATTR_DECL;
#endif

/*() Close an I/O object (in multiple stages)
 * The close may be called in response to I/O errors or for controlled
 * disconnect. At the time of first calling close, any number of
 * threads (see io->n_thr) may be able to access the io object and the
 * io object may still be in todo queue or it may be returned by poll.
 * We need to wait for all these possibilities to flush out.
 *
 * We start by deregistering the io from poll and half closing it
 * so that no more reads are possible (write to send e.g. TLS disconnect
 * is still possible). As the different threads encounter the io
 * object unusable, they will decrement io->n_thr and call hi_close().
 *
 * It is important to not fully close(2) the socket as doing so
 * would allow an accept(2) that would almost certainly use the
 * same fd number. This would cause the still pending threads
 * to act on the new connection, which would be a serious error.
 *
 * Once the io->n_thr reaches 0, the only possible source of activity
 * for the fd is that it is returned by poll. Thus we start an end game,
 * indicated by io->n_thr == HI_IO_N_THR_END_GAME,
 * where we put to todo queue a poll and then the io object. This
 * way, if the poll were about to return the io, then it is forced
 * to do so. After poll, the io is consumed from todo the one last
 * time and we can safely close(2) the fd.
 *
 * By the time we are really ready to close the io, all associated PDUs
 * have been freed by the respective threads (usually through write
 * of response freeing both response and request).
 *
 * locking:: will take io->qel.mut */

/* Called by:  hi_in_out x2, hi_read x2, hi_todo_consume, hi_write */
void hi_close(struct hi_thr* hit, struct hi_io* io, const char* lk)
{
  struct hi_pdu* pdu;
  int fd = io->fd;
  DD("%s: closing(%x) n_c/t=%d/%d", lk, fd, io->n_close, io->n_thr);
  LOCK(io->qel.mut, "hi_close");
  D("LOCK io(%x)->qel.thr=%lx n_c/t=%d/%d", fd, (long)io->qel.mut.thr, io->n_close, io->n_thr);

  if (fd&0x80000000) {
    D("%s: 2nd close(%x) n_c/t=%d/%d", lk, fd, io->n_close, io->n_thr);
  } else {
    INFO("%s: 1st close(%x) n_c/t=%d/%d", lk, fd, io->n_close, io->n_thr);
    if (shutdown(fd, SHUT_RD))
      ERR("%s: shutdown(%x) %d %s", lk, fd, errno, STRERROR(errno));
    hi_del_fd(hit, fd);    /* stop poll from returning this fd */
    io->fd |= 0x80000000;  /* mark as closed */
    ASSERTOPI(io->n_thr, >, 0);
    --io->n_thr;  /* Will not be returned by poll any more, thus remove poll "virtual thread" */
  }

  ASSERT(io->qel.intodo != HI_INTODO_SHF_FREE);
  ASSERT(hit->cur_io == io);
  if (hit->cur_n_close != io->n_close) {
    ERR("%s: already closed(%x) cur_n_close=%d != n_close=%d",lk,fd,hit->cur_n_close,io->n_close);
    hit->cur_io = 0;
    D("UNLOCK io(%x)->qel.thr=%lx", fd, (long)io->qel.mut.thr);
    UNLOCK(io->qel.mut, "hi_close-already");
    return;
  }
  
  /* N.B. n_thr manipulations should be done before calling hi_close() */
  if (io->n_thr > 0) {
    D("%s: close-wait(%x) n_c/t=%d/%d intodo=%x", lk, fd, io->n_close, io->n_thr, io->qel.intodo);
    hit->cur_io = 0;
    D("UNLOCK io(%x)->qel.thr=%lx", fd, (long)io->qel.mut.thr);
    UNLOCK(io->qel.mut, "hi_close-wait");
    return;
  }
  if (io->n_thr == 0) {
    io->n_thr = HI_IO_N_THR_END_POLL;
    D("%s: close-poll(%x) n_c/t=%d/%d intodo=%x", lk, fd, io->n_close, io->n_thr, io->qel.intodo);
    hit->cur_io = 0;
    D("UNLOCK io(%x)->qel.thr=%lx", fd, (long)io->qel.mut.thr);
    UNLOCK(io->qel.mut, "hi_close-poll");
    hi_todo_produce(hit, &io->qel, "close-poll", 0); /* Trigger 1st poll, see hi_todo_consume() */
    return;
  }
  if (io->n_thr != HI_IO_N_THR_END_GAME) {
    ERR("%s: close-n_thr(%x) n_c/t=%d/%d intodo=%x", lk,fd,io->n_close,io->n_thr,io->qel.intodo);
    ASSERTOPI(io->n_thr, ==, HI_IO_N_THR_END_GAME);
    hit->cur_io = 0;
    D("UNLOCK io(%x)->qel.thr=%lx", fd, (long)io->qel.mut.thr);
    UNLOCK(io->qel.mut, "hi_close-n_thr");
    return;
  }
  
  /* Now we are ready to really close */

  D("%s: close-final(%x) n_c/t=%d/%d", lk, io->fd, io->n_close, io->n_thr);

  for (pdu = io->reqs; pdu; pdu = pdu->n)
    hi_free_req(hit, pdu, "close-reqs ");
  io->reqs = 0;
  for (pdu = io->pending; pdu; pdu = pdu->n)
    hi_free_req(hit, pdu, "close-pend ");
  io->pending = 0;
  
  if (io->cur_pdu) {
    hi_free_req(hit, io->cur_pdu, "close-cur ");
    io->cur_pdu = hi_pdu_alloc(hit, "cur_pdu-clo");  /* *** Could we recycle the PDU without freeing? */
    io->cur_pdu->fe = io;
  }
#ifdef ENA_S5066
  void sis_clean(struct hi_io* io);
  sis_clean(io);
#endif
  
  /* Clear the association with entity as late as possible so ACKs may
   * get a chance of being processed and written. */
  if (io->ent) {
    if (io->ent->io == io) {
      io->ent->io = 0;
      /*INFO("Dissociate ent_%p (%s) from io(%x)", io->ent, io->ent->eid, io->fd);*/
      INFO("Dissociate ent_%p from io(%x)", io->ent, io->fd);
    } else {
      WARN("io(%x)->ent and ent->io(%x) are diff", io->fd, io->ent->io?io->ent->io->fd:-1);
    }
    io->ent = 0;
  } else {
    ERR("io(%x) has no entity associated", io->fd);
  }
  
#ifdef USE_OPENSSL
  if (io->ssl) {
    SSL_shutdown(io->ssl);
    SSL_free(io->ssl);
    io->ssl = 0;
  }
#endif
  ASSERTOPI(io->qel.intodo, ==, HI_INTODO_IOINUSE); /* HI_INTODO_INTODO should not be possible anymore. */
  io->qel.intodo = HI_INTODO_SHF_FREE;
  io->n_thr = 0;
  ++io->n_close;
  hit->cur_io = 0;
  close(io->fd & 0x7ffffff); /* Now some other thread may reuse the slot by accept()ing same fd */
  INFO("%s: CLOSED(%x) n_close=%d", lk, io->fd, io->n_close);

  /* Must let go of the lock only after close so no read can creep in. */
  D("UNLOCK io(%x)->qel.thr=%lx", fd, (long)io->qel.mut.thr);
  UNLOCK(io->qel.mut, "hi_close");
}

/* ---------- shuffler ---------- */

/*() For a fd that was consumed from todo, deal with potential reads and writes */

/* Called by:  hi_shuffle */
void hi_in_out(struct hi_thr* hit, struct hi_io* io)
{
  int reading;  
  
  LOCK(io->qel.mut, "in_out");
  D("LOCK io(%x)->qel.thr=%lx r/w=%d/%d ev=%x", io->fd, (long)io->qel.mut.thr, io->reading, io->writing, io->events);
  if (io->events & (EPOLLHUP | EPOLLERR)) {
    D("HUP or ERR on fd=%x events=0x%x", io->fd, io->events);
  close:
    io->n_thr -= 2;                   /* Remove both counts (write and read) */
    ASSERT(io->n_thr >= 0);
    UNLOCK(io->qel.mut, "in_out-hup");
    hi_close(hit, io, "hi_in_out-hup");
    return;
  }
  
  /* We must ensure that only one thread is trying to write. The poll may
   * still report the io as writable after a thread has taken the
   * task, in that case we want the second thread to skip write and
   * go process the read. */
  if (io->events & EPOLLOUT && !io->writing) {
    D("OUT fd=%x n_iov=%d n_to_write=%d writing", io->fd, io->n_iov, io->n_to_write);

    /* Although in_write is checked in hi_write() as well, take the opportunity
     * to check it right here while we already hold the lock. */
    if (!io->in_write)  /* Need to prepare new iov? */
      hi_make_iov_nolock(io);
    if (io->in_write) {
      io->writing = 1;
      D("UNLOCK io(%x)->qel.thr=%lx", io->fd, (long)io->qel.mut.thr);
      UNLOCK(io->qel.mut, "check-writing-enter");
    
      if (hi_write(hit, io))  { /* will clear io->writing */
	LOCK(io->qel.mut, "n_thr-dec2");
	D("IN_OUT: LOCK & UNLOCK io(%x)->qel.thr=%lx closed", io->fd, (long)io->qel.mut.thr);
	--io->n_thr;            /* Remove read count, write count already removed by hi_write() */
	ASSERT(io->n_thr >= 0);
	ASSERT(hit->cur_io == io);
	ASSERT(hit->cur_n_close == io->n_close);
	UNLOCK(io->qel.mut, "n_thr-dec2");
	hi_close(hit, io, "write-shortcircuit-close");  /* Close again, now n_thr was reduced */
	return; /* Write caused close, read will be futile */
      } else {
	LOCK(io->qel.mut, "check-reading");
	D("LOCK io(%x)->qel.thr=%lx", io->fd, (long)io->qel.mut.thr);
      }
    } else {
      if (io->fd & 0x80000000) {
	/* Seems it was already a closed one, but due to no write, no opportunity for error. */
	D("nothing to write and closed io(%x)->n_thr=%d", io->fd, io->n_thr);
	goto close;
      }
      --io->n_thr;              /* Remove write count as no write happened. */
      D("no inwrite io(%x)->n_thr=%d", io->fd, io->n_thr);
    }
  } else {
    --io->n_thr;              /* Remove write count as no write happened. */
    D("no EPOLLOUT io(%x)->n_thr=%d", io->fd, io->n_thr);
  }
  ASSERT(io->n_thr > 0 || io->n_thr == HI_IO_N_THR_END_GAME);  /* Read cnt should still be there */
  io->events &= ~EPOLLOUT;  /* Clear poll flag in case we get read rescheduling */
  
  if (io->events & EPOLLIN) {
    /* A special problem with EAGAIN: read(2) is not guaranteed to arm edge triggered epoll(2)
     * unless at least one EAGAIN read has happened. The problem is that as we are still
     * in io->reading, if after this EAGAIN another thread polls and consumes from todo, it
     * will not be able to read due to io->reading even though poll told it to read. After
     * missing the opportunity, the next poll will not report fd anymore because no read has
     * happened since previous report. Ouch!
     * Solution attempt: if read was polled, but could not be served due to io->reading.
     * the PDU is added back to the todo queue. This may cause the other thread to spin
     * for a while, but at least things will move on eventually. */
    if (!io->reading) {
      D("IN fd=%x cur_pdu=%p need=%d", io->fd, io->cur_pdu, io->cur_pdu->need);
      /* Poll says work is possible: sched wk for io if not under wk yet, or cur_pdu needs wk.
       * The inverse is also important: if io->cur_pdu is set, but pdu->need is not, then someone
       * is alredy working on decoding the cur_pdu and we should not interfere. */
      reading = io->reading = io->cur_pdu->need; /* only place where io->reading is set */
      D("UNLOCK io(%x)->qel.thr=%lx", io->fd, (long)io->qel.mut.thr);
      UNLOCK(io->qel.mut, "check-reading");
      if (reading) {
	hi_read(hit, io);       /* io->n_thr and hit->cur_io have already been updated */
	ASSERT(!hit->cur_io);
      } else {
	LOCK(io->qel.mut, "n_thr-dec3");
	D("IN_OUT: LOCK & UNLOCK io(%x)->qel.thr=%lx", io->fd, (long)io->qel.mut.thr);
	--io->n_thr;            /* Remove read count as no read happened. */
	ASSERT(io->n_thr >= 0);
	ASSERT(hit->cur_io == io);
	ASSERT(hit->cur_n_close == io->n_close);
	hit->cur_io = 0;
	UNLOCK(io->qel.mut, "n_thr-dec3");
      }
    } else {
      ASSERT(io->n_thr > 0);
      ASSERT(hit->cur_io == io);
      ASSERT(hit->cur_n_close == io->n_close);
      /*--io->n_thr;     * Do not decrement. We need to keep n_thr until we are in todo queue. */
      hit->cur_io = 0;
      D("UNLOCK io(%x)->qel.thr=%lx", io->fd, (long)io->qel.mut.thr);
      UNLOCK(io->qel.mut, "n_thr-dec4");
      D("resched(%x) to avoid miss poll read n_thr=%d", io->fd, io->n_thr);
      hi_todo_produce(hit, &io->qel, "reread", 0);  /* try again so read poll is not lost */
    }
  } else {
    --io->n_thr;              /* Remove read count as no read happened. */
    ASSERT(io->n_thr >= 0);
    ASSERT(hit->cur_io == io);
    ASSERT(hit->cur_n_close == io->n_close);
    hit->cur_io = 0;
    D("UNLOCK io(%x)->qel.thr=%lx", io->fd, (long)io->qel.mut.thr);
    UNLOCK(io->qel.mut, "n_thr-dec5");
  }
}

/*() Main I/O shuffling loop. Never returns. Main loop of most (all?) threads. */

/* Called by:  thread_loop, zxbusd_main */
void hi_shuffle(struct hi_thr* hit, struct hiios* shf)
{
  struct hi_qel* qe;
  hit->shf = shf;
  LOCK(shf->todo_mut, "add-thread");
  hit->n = shf->threads;
  shf->threads = hit;
  UNLOCK(shf->todo_mut, "add-thread");
  INFO("Start shuffling hit(%p) shf(%p)", hit, shf);
  hi_sanity_shf(255, shf);
  while (1) {
    HI_SANITY(hit->shf, hit);
    qe = hi_todo_consume(hit);  /* Wakes up the heard to receive work. */
    switch (qe->kind) {
    case HI_POLLT:    hi_poll(hit); break;
    case HI_LISTENT:  hi_accept(hit, (struct hi_io*)qe); break;
    case HI_HALF_ACCEPT: hi_accept_book(hit, (struct hi_io*)qe, ((struct hi_io*)qe)->fd);
    case HI_TCP_C:
    case HI_TCP_S:    hi_in_out(hit, (struct hi_io*)qe); break;
    case HI_PDU_DIST: stomp_msg_deliver(hit, (struct hi_pdu*)qe); break;
#ifdef HAVE_NET_SNMP
    case HI_SNMP:     if (snmp_port) processSNMP(); break; /* *** needs more thought */
#endif
    default: NEVER("unknown qel->kind 0x%x", qe->kind);
    }
  }
}

/* EOF  --  hiios.c */
