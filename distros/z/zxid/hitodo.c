/* hitodo.c  -  Hiquu I/O Engine todo queue management
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
 * 17.9.2012, factored todo code to its own file --Sampo
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

extern int errmac_debug;

const char* qel_kind[] = {
  "OFF0",
  "poll1",
  "listen2",
  "half_accept3",
  "tcp_s4",
  "tcp_c5",
  "snmp6",
  "pdu7",
  0
};

#define QEL_KIND(x) (((x) >= 0 && (x) < sizeof(qel_kind)/sizeof(char*))?qel_kind[(x)]:"???")

/* -------- todo_queue management, waking up threads to consume work (io, pdu) -------- */

/*(-) Simple mechanics of deque operation against shf->todo_consumer */

/* Called by:  hi_todo_consume */
static struct hi_qel* hi_todo_consume_queue_inlock(struct hiios* shf)
{
  struct hi_qel* qe = shf->todo_consume;
  shf->todo_consume = qe->n;
  if (!qe->n)
    shf->todo_produce = 0;
  qe->n = 0;
  qe->intodo = qe->kind == HI_PDU_DIST ? HI_INTODO_PDUINUSE : HI_INTODO_IOINUSE;
  --shf->n_todo;
  return qe;
}

/*(-) Simple mechanics of enque operation against shf->todo_producer */

/* Called by:  hi_todo_consume, hi_todo_produce */
static void hi_todo_produce_queue_inlock(struct hiios* shf, struct hi_qel* qe)
{
  if (shf->todo_produce)
    shf->todo_produce->n = qe;
  else
    shf->todo_consume = qe;
  shf->todo_produce = qe;
  qe->n = 0;
  qe->intodo = HI_INTODO_INTODO;
  ++shf->n_todo;
}

/*(i) Consume from todo queue. If nothing is available,
 * block until there is work to do. If todo queue is
 * empty, see if we should poll again. This is the main
 * mechanism by which worker threads get something to do. */

/* Called by:  hi_shuffle */
struct hi_qel* hi_todo_consume(struct hi_thr* hit)
{
  struct hi_io* io;
  struct hi_qel* qe;
  LOCK(hit->shf->todo_mut, "todo_cons");
  D("LOCK todo_mut.thr=%lx (cond_wait)", (long)hit->shf->todo_mut.thr);

 deque_again:
  while (!hit->shf->todo_consume && hit->shf->poll_tok.proto == HIPROTO_POLL_OFF)  /* Empty? */
    ERRMAC_COND_WAIT(&hit->shf->todo_cond, hit->shf->todo_mut, "todo-cons"); /* Block until work */
  D("Out of cond_wait todo_mut.thr=%lx", (long)hit->shf->todo_mut.thr);
  
  if (!hit->shf->todo_consume) {
    ASSERT(hit->shf->poll_tok.proto);
  force_poll:
    hit->shf->poll_tok.proto = HIPROTO_POLL_OFF;
    D("UNLK cons-poll todo_mut.thr=%lx", (long)hit->shf->todo_mut.thr);
    UNLOCK(hit->shf->todo_mut, "todo_cons-poll");
    return &hit->shf->poll_tok;
  }
  
  qe = hi_todo_consume_queue_inlock(hit->shf);
  if (!ONE_OF_2(qe->kind, HI_TCP_S, HI_TCP_C)) {
    D("cons qe_%p kind(%s) intodo=%x todo_mut.thr=%lx", qe, QEL_KIND(qe->kind), qe->intodo, (long)hit->shf->todo_mut.thr);
    UNLOCK(hit->shf->todo_mut, "todo_cons");
    return qe;
  }
  
  io = (struct hi_io*)qe;
  LOCK(io->qel.mut, "n_thr-inc");
  ASSERT(!hit->cur_io);
  if (io->n_thr == HI_IO_N_THR_END_POLL) {      /* Special close end game, see hi_close() */
    io->n_thr = HI_IO_N_THR_END_GAME;
    hi_todo_produce_queue_inlock(hit->shf, qe); /* Put it back: try again later */
    UNLOCK(io->qel.mut, "n_thr-poll");
    goto force_poll;
  }
  if (io->n_thr == HI_IO_N_THR_END_GAME) {
    hit->cur_io = io;
    hit->cur_n_close = io->n_close;
    UNLOCK(io->qel.mut, "n_thr-end");
    hi_close(hit, io, "cons-end");
    goto deque_again;
  }
  if (io->fd & 0x80000000) {
    D("cons-ign-closed: LK&UNLK io(%x)->qel.thr=%lx n_thr=%d r/w=%d/%d ev=%d intodo=%x", io->fd, (long)io->qel.mut.thr, io->n_thr, io->reading, io->writing, io->events, io->qel.intodo);
    /* Let it be consumed so that r/w will fail and hi_close() is called to clean up. */
  }
  
  ++io->n_thr;  /* Increase two counts: once for write, and once for read, decrease for intodo ending. Net is +1. */
  hit->cur_io = io;
  hit->cur_n_close = io->n_close;
  D("cons: LK&UNLK io(%x)->qel.thr=%lx n_thr=%d r/w=%d/%d ev=%x intodo=%x", io->fd, (long)io->qel.mut.thr, io->n_thr, io->reading, io->writing, io->events, io->qel.intodo);
  UNLOCK(io->qel.mut, "n_thr-inc");
  D("UNLK todo_mut.thr=%lx", (long)hit->shf->todo_mut.thr);
  UNLOCK(hit->shf->todo_mut, "todo_cons-tcp");
  return qe;
}

/*(i) Schedule new work to be done, potentially waking up the consumer threads!
 * It is important that for HI_TCP_S and HI_TCP_C ios the n_thr is nonzero
 * while calling this. This is to block a race to hi_close(). For poll,
 * listener, or pdu type todos there is no such consideration.
 * locking:: Takes todo_mut and io->qel.mut */

/* Called by:  hi_accept, hi_accept_book, hi_close, hi_in_out, hi_poll x3, hi_send0, stomp_msg_deliver, zxbus_sched_new_delivery, zxbus_sched_pending_delivery */
void hi_todo_produce(struct hi_thr* hit, struct hi_qel* qe, const char* lk, int from_poll)
{
  struct hi_io* io;
  LOCK(hit->shf->todo_mut, "todo_prod");
  D("%s: LOCK todo_mut.thr=%lx", lk, (long)hit->shf->todo_mut.thr);

  if (qe->intodo == HI_INTODO_INTODO) {
    if (ONE_OF_2(qe->kind, HI_TCP_S, HI_TCP_C)) {
      io = ((struct hi_io*)qe);
      D("%s: prod already in todo(%x) n_thr=%d r/w=%d/%d ev=%x", lk, io->fd, io->n_thr, io->reading, io->writing, io->events);
      if (io->fd & 0x80000000)
	D("%s: prod-closed fd(%x) intodo! n_thr=%d r/w=%d/%d ev=%x intodo=%x", lk, io->fd, io->n_thr, io->reading, io->writing, io->events, io->qel.intodo);
    } else {
      D("%s: prod already in todo qe_%p kind(%s)", lk, qe, QEL_KIND(qe->kind));
    }
    goto out;
  }
  
  if (!ONE_OF_2(qe->kind, HI_TCP_S, HI_TCP_C)) {
    D("%s: prod qe(%p) kind(%s)", lk, qe, QEL_KIND(qe->kind));
    goto produce;
  }

  io = (struct hi_io*)qe;
  LOCK(io->qel.mut, "n_thr-inc-todo");
  if (from_poll) {
    /* Detect already closed (or even end game) io, see hi_close(). Note that
     * this detection only needs to apply to produce from poll. */
    if (io->n_thr == HI_IO_N_THR_END_POLL || io->fd & 0x80000000) {
      D("%s: prod(%x)-ign LK&UNLK n_c/t=%d/%d r/w=%d/%d ev=%x", lk, io->fd, io->n_close, io->n_thr, io->reading, io->writing, io->events);
      UNLOCK(io->qel.mut, "n_thr-inc-ign");
      goto out;
    }
    ASSERTOPI(io->n_thr, >=, 0);
    ++io->n_thr;  /* Should have been done already by caller, but for poll optimize lock. */
  } else {
    if (io->n_thr != HI_IO_N_THR_END_POLL) {
      ASSERTOPI(io->n_thr, >=, 0);
    }
  }
  //if (io->fd & 0x80000000) { /* *** fast fail hi_close() ? */ }
  D("%s: prod(%x) LK&UNLK n_c/t=%d/%d r/w=%d/%d ev=%x", lk, io->fd, io->n_close, io->n_thr, io->reading, io->writing, io->events);
  UNLOCK(io->qel.mut, "n_thr-inc-todo");

produce:
  hi_todo_produce_queue_inlock(hit->shf, qe);
  ERRMAC_COND_SIG(&hit->shf->todo_cond, "todo-prod");  /* Wake up consumers */

 out:
  D("%s: UNLOCK todo_mut.thr=%lx", lk, (long)hit->shf->todo_mut.thr);
  UNLOCK(hit->shf->todo_mut, "todo_prod");
}

/* EOF  --  hitodo.c */
