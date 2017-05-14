/* hiiosdump.c  -  Hiquu I/O Engine data structure dump
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
 *
 * See http://pl.atyp.us/content/tech/servers.html for inspiration on threading strategy.
 *
 *   MANY ELEMENTS IN QUEUE            ONE ELEMENT IN Q   EMPTY QUEUE
 *   consume             produce       consume  produce   consume  produce
 *    |                   |             | ,-------'         |        |
 *    v                   v             v v                 v        v
 *   qel.n --> qel.n --> qel.n --> 0   qel.n --> 0          0        0
 */

#include "platform.h"

#include <pthread.h>
#include <memory.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

#include "akbox.h"
#include "hiproto.h"
#include "hiios.h"
#include "errmac.h"

/* Current color for coloring data structures for integrity checking, e.g.
 *   gdb p hi_color+=4, hi_sanity_hit(255, hit)
 * Note that different color MUST be used for each analysis and some
 * analysis iterations involve several classes of next pointers. This
 * is solved by having different classes being represented by color plus
 * offset. However, this means that color must be incremented in steps of 4.
 *   hi_color+0 qel.n           -- free_pdus, todo_consume
 *   hi_color+1 pdu->n, io->n   -- reqs
 *   hi_color+2 pdu->wn         -- to_write
 * The color takes space as a struct field, thus only 8 or 16 bits are
 * supplied (varies over time with implementation), which should
 * allow most debugging chores, but may not be adequate for some. */
short hi_color = 4;

/*() Sanity check hiios pdu data structures.
 * Returns number of nodes scanned, or negative for errors. */

/* Called by:  hi_sanity_hit, hi_sanity_io x4, hi_sanity_pdu x3, hi_sanity_shf x2 */
int hi_sanity_pdu(int mode, struct hi_pdu* root_pdu)
{
  int errs = 0;
  int nodes = 0;
  struct hi_pdu* pdu;

  if (mode&0x80) {
    if (root_pdu->reals)
      printf("    pdu_%p  //reals  (%.*s)\n", root_pdu, (int)MIN(root_pdu->ap-root_pdu->m,4), root_pdu->m);
    else
      printf("    pdu_%p -> null [label=reals];\n", root_pdu);
  }
  for (pdu = root_pdu->reals; pdu; pdu = pdu->n) {
    if (mode&0x80) printf("    -> pdu_%p  // (%.*s)\n", pdu, (int)MIN(pdu->ap-pdu->m,4), pdu->m);
    if (pdu->color == hi_color+1) {
      printf("ERR *** pdu_%p has circular reference (color=%d) wrt pdu->reals pdu->n\n", pdu, pdu->color);
      --errs;
      break;
    } else {
      pdu->color = hi_color+1;
      ++nodes;
      if (mode&0x01) nodes += hi_sanity_pdu(mode, pdu);
    }
    if (pdu->qel.intodo != HI_INTODO_PDUINUSE) {
      printf("ERR *** pdu_%p has wrong intodo=%x expected %x\n", pdu, pdu->qel.intodo, HI_INTODO_PDUINUSE);
      --errs;
    }
  }
  if (mode&0x80 && root_pdu->reals) printf("    [label=reals];\n");

  if (mode&0x80) {
    if (root_pdu->synths)
      printf("    pdu_%p  // synths\n", root_pdu);
    else
      printf("    pdu_%p -> null [label=synths];\n", root_pdu);
  }
  for (pdu = root_pdu->synths; pdu; pdu = pdu->n) {
    if (mode&0x80) printf("    -> pdu_%p\n", pdu);
    if (pdu->color == hi_color+1) {
      printf("ERR *** pdu_%p has circular reference (color=%d) wrt pdu->synths pdu->n\n", pdu, pdu->color);
      --errs;
      break;
    } else {
      pdu->color = hi_color+1;
      ++nodes;
      if (mode&0x01) nodes += hi_sanity_pdu(mode, pdu);
    }
    if (pdu->qel.intodo != HI_INTODO_PDUINUSE) {
      printf("ERR *** pdu_%p has wrong intodo=%x expected %x\n", pdu, pdu->qel.intodo, HI_INTODO_PDUINUSE);
      --errs;
    }
  }
  if (mode&0x80 && root_pdu->synths) printf("    [label=synths];\n");

  if (mode&0x80) {
    if (root_pdu->subresps)
      printf("    pdu_%p  // subresps\n", root_pdu);
    else
      printf("    pdu_%p -> null [label=subresps];\n", root_pdu);
  }
  for (pdu = root_pdu->subresps; pdu; pdu = pdu->wn) {
    if (mode&0x80) printf("    -> pdu_%p\n", pdu);
    if (pdu->color == hi_color+2) {
      printf("ERR *** pdu_%p has circular reference (color=%d) wrt pdu->subresps pdu->wn\n", pdu, pdu->color);
      --errs;
      break;
    } else {
      pdu->color = hi_color+2;
      ++nodes;
      if (mode&0x01) nodes += hi_sanity_pdu(mode, pdu);
    }
    if (pdu->qel.intodo != HI_INTODO_PDUINUSE) {
      printf("ERR *** pdu_%p has wrong intodo=%x expected %x\n", pdu, pdu->qel.intodo, HI_INTODO_PDUINUSE);
      --errs;
    }
  }
  if (mode&0x80 && root_pdu->subresps) printf("    [label=subresps];\n");

  return errs?errs:nodes;
}

/*() Sanity check hiios io data structures.
 * Returns number of nodes scanned, or negative for errors. */

/* Called by:  hi_sanity_shf */
int hi_sanity_io(int mode, struct hi_io* root_io)
{
  int errs = 0;
  int nodes = 0;
  struct hi_pdu* pdu;
  
  if (root_io->fd & 0x80000000 || root_io->fd == 0) {
    if (mode&0x80) printf("io_%p [label=nc];  // fd=0x%x\n", root_io, root_io->fd);
    return 0;
  }
  
  if (mode&0x80) printf("  io_%p -> pdu_%p [label=cur_pdu]; // fd=0x%x\n", root_io, root_io->cur_pdu, root_io->fd);
  if (root_io->cur_pdu)
    root_io->cur_pdu->color = hi_color+1;  /* cur_pdu is mutually exclusive with io->reqs */

  if (mode&0x80) {
    if (root_io->reqs)
      printf("  io_%p  // reqs\n", root_io);
    else
      printf("  io_%p -> null [label=reqs];\n", root_io);
  }
  for (pdu = root_io->reqs; pdu; pdu = pdu->n) {
    if (mode&0x80) printf("    -> pdu_%p  // (%.*s)\n", pdu, (int)MIN(pdu->ap-pdu->m,4), pdu->m);
    if (pdu->color == hi_color+1) {
      printf("ERR *** pdu_%p has circular reference (color=%d) wrt io->reqs pdu->n\n", pdu, pdu->color);
      --errs;
      break;
    } else {
      pdu->color = hi_color+1;
      ++nodes;
      if (mode&0x02) nodes += hi_sanity_pdu(mode, pdu);
    }
    if (pdu->qel.intodo != HI_INTODO_PDUINUSE) {
      printf("ERR *** pdu_%p has wrong intodo=%x expected %x\n", pdu, pdu->qel.intodo, HI_INTODO_PDUINUSE);
      --errs;
    }
  }
  if (mode&0x80 && root_io->reqs) printf("[label=reqs];\n");

  if (mode&0x80) {
    if (root_io->pending)
      printf("  io_%p  // pending\n", root_io);
    else
      printf("  io_%p -> null [label=pending];\n", root_io);
  }
  for (pdu = root_io->pending; pdu; pdu = pdu->n) {
    if (mode&0x80) printf("    -> pdu_%p  // (%.*s)\n", pdu, (int)MIN(pdu->ap-pdu->m,4), pdu->m);
    if (pdu->color == hi_color+1) {
      printf("ERR *** pdu_%p has circular reference (color=%d) wrt io->pending pdu->n\n", pdu, pdu->color);
      --errs;
      break;
    } else {
      pdu->color = hi_color+1;
      ++nodes;
      if (mode&0x02) nodes += hi_sanity_pdu(mode, pdu);
    }
    if (pdu->qel.intodo != HI_INTODO_PDUINUSE) {
      printf("ERR *** pdu_%p has wrong intodo=%x expected %x\n", pdu, pdu->qel.intodo, HI_INTODO_PDUINUSE);
      --errs;
    }
  }
  if (mode&0x80 && root_io->reqs) printf("[label=pending];\n");

  if (mode&0x80) {
    if (root_io->to_write_produce) {
      printf("  io_%p -> pdu_%p [label=to_write_produce]; // (%.*s)\n", root_io, root_io->to_write_produce, (int)MIN(root_io->to_write_produce->ap-root_io->to_write_produce->m,4), root_io->to_write_produce->m);
      ASSERT(root_io->to_write_produce->wn == 0);
      /*if (mode&0x02) nodes += hi_sanity_pdu(mode, root_io->to_write_produce);*/
      if (pdu->qel.intodo != HI_INTODO_PDUINUSE) {
	printf("ERR *** pdu_%p has wrong intodo=%x expected %x\n", pdu, pdu->qel.intodo, HI_INTODO_PDUINUSE);
	--errs;
      }
    } else
      printf("  io_%p -> null [label=to_write_produce];\n", root_io);
  }

  if (mode&0x80) {
    if (root_io->to_write_consume)
      printf("  io_%p  // to_write_consume\n", root_io);
    else
      printf("  io_%p -> null [label=to_write_consume];  // n_to_write=%d\n", root_io, root_io->n_to_write);
  }
  for (pdu = root_io->to_write_consume; pdu; pdu = pdu->wn) {
    if (mode&0x80) printf("    -> pdu_%p  // (%.*s)\n", pdu, (int)MIN(pdu->ap-pdu->m,4), pdu->m);
    if (pdu->color == hi_color+2) {
      printf("ERR *** pdu_%p has circular reference (color=%d) wrt io->to_write_consume pdu->wn\n", pdu, pdu->color);
      --errs;
      break;
    } else {
      pdu->color = hi_color+2;
      ++nodes;
      if (mode&0x02) nodes += hi_sanity_pdu(mode, pdu);
    }
    if (pdu->qel.intodo != HI_INTODO_PDUINUSE) {
      printf("ERR *** pdu_%p has wrong intodo=%x expected %x\n", pdu, pdu->qel.intodo, HI_INTODO_PDUINUSE);
      --errs;
    }
  }
  if (mode&0x80 && root_io->to_write_consume) printf("[label=to_write_consume];  // n_to_write=%d\n", root_io->n_to_write);
  
  if (mode&0x80) {
    if (root_io->in_write)
      printf("io_%p  // in_write\n", root_io);
    else
      printf("  io_%p -> null [label=in_write];\n", root_io);
  }
  for (pdu = root_io->in_write; pdu; pdu = pdu->wn) {
    if (mode&0x80) printf("-> pdu_%p  // (%.*s)\n", pdu, (int)MIN(pdu->ap-pdu->m,4), pdu->m);
    if (pdu->color == hi_color+2) {
      printf("ERR *** pdu_%p has circular reference (color=%d) wrt io->in_write pdu->wn\n", pdu, pdu->color);
      --errs;
      break;
    } else {
      pdu->color = hi_color+2;
      ++nodes;
      if (mode&0x02) nodes += hi_sanity_pdu(mode, pdu);
    }
    if (pdu->qel.intodo != HI_INTODO_PDUINUSE) {
      printf("ERR *** pdu_%p has wrong intodo=%x expected %x\n", pdu, pdu->qel.intodo, HI_INTODO_PDUINUSE);
      --errs;
    }
  }
  if (mode&0x80 && root_io->in_write) printf("[label=in_write];\n");
  
  return errs?errs:nodes;
}

/*() Sanity check hiios thread data structures.
 * Returns number of nodes scanned, or negative for errors. */

/* Called by:  hi_dump, hi_sanity */
int hi_sanity_hit(int mode, struct hi_thr* root_hit)
{
  int errs = 0;
  int nodes = 0;
  struct hi_pdu* pdu;

  printf("hit_%p [label=\"tid_%x\"];\n", root_hit, (unsigned int)root_hit->self);
  if (mode&0x80) {
    if (root_hit->free_pdus)
      printf("hit_%p  // free_pdus\n", root_hit);
    else
      printf("hit_%p -> null [label=free_pdus];\n", root_hit);
  }
  for (pdu = root_hit->free_pdus; pdu; pdu = (struct hi_pdu*)pdu->qel.n) {
    if (mode&0x80) printf("-> pdu_%p  // (%.*s)\n", pdu, (int)MIN(pdu->ap-pdu->m,4), pdu->m);
    if (pdu->color == hi_color+1) {
      printf("ERR *** pdu_%p in hit->free_pdus is also in reqs list (color=%d)\n", pdu, pdu->color);
      --errs;
      break;
    }
    if (pdu->color == hi_color+0) {
      printf("ERR *** pdu_%p has circular reference (color=%d) wrt hit->free_pdus pdu->qel.n\n", pdu, pdu->color);
      --errs;
      break;
    }
    if (pdu->qel.intodo != HI_INTODO_HIT_FREE) {
      printf("ERR *** pdu_%p has wrong intodo=%x expected %x\n", pdu, pdu->qel.intodo, HI_INTODO_HIT_FREE);
      --errs;
    }
    pdu->color = hi_color+0;
    ++nodes;
    if (!(mode&0x08)) nodes += hi_sanity_pdu(mode, pdu);
  }
  if (mode&0x80 && root_hit->free_pdus) printf("[label=free_pdus];\n");

  return errs?errs:nodes;
}

/*() Sanity check hiios shuffler data structures, i.e. practically everything.
 * Mainly meant to be called from gdb like this: p hi_color+=4, hi_sanity(255, shf)
 * The mode argument controls recursion and output of a visualization
 * of the data structure. It consists of bits as follows
 *  76543210
 *  |   |||`-- recurse on sub PDU         (0x01)
 *  |   ||`--- recurse on PDU             (0x02)
 *  |   |`---- recurse on IO              (0x04)
 *  |   `----- do not recurse on free_pdu (0x08)
 *  `--------- print                      (0x80)
 * Simple way to enable all recusion is to use mode=127 or mode=255 if print is desired
 * Returns negative number (of errors) if errors are found. Otherwise positive
 * number representing the rough number of nodes traversed (size of the data structure)
 * is returned.
 * hi_sanity() will most probably crash upon corrupt pointers. It will make
 * an attempt to detect illegal circular data structures (see hi_color).
 *   (gdb) p hi_color+=4, hi_sanity(255, shuff)
 */

/* Called by:  hi_dump, hi_sanity, hi_shuffle, zxbusd_main */
int hi_sanity_shf(int mode, struct hiios* root_shf)
{
  int res;
  int errs = 0;
  int nodes = 0;
  struct hi_qel* qe;
  struct hi_pdu* pdu;
  struct hi_io* io;

  if (mode&0x80) {
    if (root_shf->ios)
      printf("shf_%p  // max_ios=%d\n", root_shf, root_shf->max_ios);
    else
      printf("shf_%p -> null [label=ios];\n", root_shf);
  }
  for (io = root_shf->ios; io < root_shf->ios + root_shf->max_ios; ++io) {
    if (!io->n_thr && (io->fd & 0x80000000 || io->fd == 0)) {
      /*ASSERT(io->qel.intodo == HI_INTODO_SHF_FREE);  doesn't hold betw 1st close and end game */
      printf("io_%p  // free? fd(%x) n_c/t=%d/%d in_todo=%d\n", io, io->fd, io->n_close, io->n_thr, io->qel.intodo);
      continue;   /* ios slot not in use */
    }
    if (mode&0x80) printf("-> io_%p\n", io);
    ++nodes;
    if (mode&0x04) {
      res = hi_sanity_io(mode, io);
      if (res < 0)
	errs += res;
      else
	nodes += res;
    }
  }
  if (mode&0x80 && root_shf->ios) printf("[label=ios];\n");

  if (mode&0x80) {
    if (root_shf->todo_consume)
      printf("shf_%p   // todo_consume (color=%d)\n", root_shf, hi_color+0);
    else
      printf("shf_%p -> null [label=todo_consume];\n", root_shf);
  }
  for (qe = root_shf->todo_consume; qe; qe = qe->n) {
    if (mode&0x80) printf("-> qe_%p\n", qe);
#if 0
    if (pdu->color == hi_color+0) {
      printf("ERR *** pdu_%p has circular reference (color=%d) wrt hit->free_pdus pdu->qel.n\n", pdu, pdu->color);
      --errs;
      break;
    }
    pdu->color = hi_color+0;
    ++nodes;
    if (!(mode&0x08)) {
      res = hi_sanity_pdu(mode, pdu);
      if (res < 0)
	errs += res;
      else
	nodes += res;
    }
#endif
    if (qe->intodo != HI_INTODO_INTODO) {
      printf("ERR *** qe_%p has wrong intodo=%x expected %x\n", qe, qe->intodo, HI_INTODO_INTODO);
      --errs;
    }
  }
  if (mode&0x80 && root_shf->todo_consume) printf("[label=todo_consume];\n");

  if (mode&0x80) {
    if (root_shf->free_pdus)
      printf("shf_%p   // free_pdus (color=%d)\n", root_shf, hi_color+0);
    else
      printf("shf_%p -> null [label=free_pdus];\n", root_shf);
  }
  for (pdu = root_shf->free_pdus; pdu; pdu = (struct hi_pdu*)pdu->qel.n) {
    if (mode&0x80) printf("-> pdu_%p ", pdu);
    if (pdu->color == hi_color+1) {
      printf("ERR *** pdu_%p in free list is also in reqs list (color=%d)\n", pdu, pdu->color);
      --errs;
      break;
    }
    if (pdu->color == hi_color+0) {
      printf("ERR *** pdu_%p has circular reference (color=%d) wrt hit->free_pdus pdu->qel.n\n", pdu, pdu->color);
      --errs;
      break;
    }
    if (pdu->qel.intodo != HI_INTODO_SHF_FREE) {
      printf("ERR *** pdu_%p has wrong intodo=%x expected %x\n", pdu, pdu->qel.intodo, HI_INTODO_SHF_FREE);
      --errs;
    }
    pdu->color = hi_color+0;
    ++nodes;
    if (!(mode&0x08)) {
      res = hi_sanity_pdu(mode, pdu);
      if (res < 0)
	errs += res;
      else
	nodes += res;
    }
  }
  if (mode&0x80 && root_shf->free_pdus) printf("[label=free_pdus];\n");

  return errs?errs:nodes;
}

/*() hi_sanity is called by macro HI_SANITY() and is meant to be called from gdb interactively.
 * Returns number of nodes scanned, or negative for errors. */

/* Called by: */
int hi_sanity(int mode, struct hiios* root_shf, struct hi_thr* root_hit, const char* fn, int line)
{
  int res;
  hi_color += 4;
  if (root_shf) {
    res = hi_sanity_shf(mode, root_shf);
    D("Data structure dump %d\n---------------------- %s:%d", res, fn, line);
    ASSERT(res >= 0);
  }
  if (root_hit) {
    res = hi_sanity_hit(mode, root_hit);
    D("Hit structure dump %d\n====================== %s:%d", res, fn, line);
    ASSERT(res >= 0);
  }
  return 0;
}

/*() All thread data structure check.
 * Returns number of nodes scanned, or negative for errors. */

/* Called by: */
int hi_dump(struct hiios* shf)
{
  struct hi_thr* hit;
  int res = hi_sanity_shf(255, shf);
  hi_color += 4;
  D("Dumping shf=%p hi_color=%d", shf, hi_color);
  printf("Data structure dump %d\n----------------------\n", res);
  for (hit = shf->threads; hit; hit = hit->n) {
    res = hi_sanity_hit(255, hit);
    printf("Hit structure dump %d\n======================\n", res);
  }
  return res;
}

/* EOF  --  hiiosdump.c */
