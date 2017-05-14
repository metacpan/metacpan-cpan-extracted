/* zxbussubs.c  -  Audit Bus subscription management
 * Copyright (c) 2012 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing. See file COPYING.
 * Special grant: http.c may be used with zxid open source project under
 * same licensing terms as zxid itself.
 * $Id$
 *
 * 16.8.2012, created --Sampo
 * 30.8.2012, added subscription mechanisms --Sampo
 * 5.9.2012,  separated entity management and subscriptions to own source files --Sampo
 */

#include "platform.h"
#include "errmac.h"
#include "akbox.h"
#include "hiios.h"
#include "hiproto.h"
#include <zx/zxidconf.h>
#include <zx/zxidutil.h>

#define __USE_GNU 1  /* for O_DIRECT */

#include <ctype.h>
#include <memory.h>
#include <stdlib.h>
#include <netinet/in.h> /* htons(3) and friends */
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>

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
#define zx_rcpt_sig dest

extern int verbose;  /* defined in option parsing in zxbusd.c */
extern char* zxbus_path;

/*() Find the channel in shf->chs array.
 * N.B. The channel composition is fixed at boot time so no locking is needed.
 * return:: hi_ch pointer on success, 0 on not found */

/* Called by:  stomp_msg_deliver, zxbus_subscribe */
struct hi_ch* zxbus_find_ch(struct hiios* shf, int len, const char* dest)
{
  int n;
  struct hi_ch* ch;
  if (len == -1)
    len = strlen(dest);
  else if (len == -2)
    len = strchr(dest, '\n') - dest;
  for (n = shf->max_chs, ch = shf->chs; n; --n, ++ch) {
    if (!ch->dest)
      break;
    if (!memcmp(ch->dest, dest, len) && ONE_OF_2(dest[len],'\n','\0')) {
      D("found ch(%s)", ch->dest);
      return ch;
    }
  }
  D("channel(%.*s) not found", len, dest);
  return 0;
}

/*() Write subscriptions of a channel.
 * Called when new subscription is added at run time.
 * Will walk the entities and subscriptions relating to that channel.
 * locking:: shf->ent_mut must be held when calling this function
 */

/* Called by:  zxbus_subscribe */
static int zxbus_write_ch_subs(struct hiios* shf, struct hi_ch* ch)
{
#ifndef PATH_MAX
#define PATH_MAX ZXID_MAX_BUF
#endif
  char err_buf[PATH_MAX];
  int ch_num = ch - shf->chs;
  struct hi_ent* ent;
  char buf[ZXID_MAX_BUF];
  FILE* out;

  D("writing .subs for ch(%s) ch_num=%d", ch->dest, ch_num);
  name_from_path(buf, sizeof(buf), "%s" ZXBUS_CH_DIR "%s/.subs", zxbus_path, ch->dest);
  if (!(out = fopen(buf, "wb"))) {
    perror("open");
    ERR("writing subscriptions: File(%s) not writable errno=%d err(%s). euid=%d egid=%d cwd(%s)", buf, errno, STRERROR(errno), geteuid(), getegid(), getcwd(err_buf, sizeof(err_buf)));
    return 0;
  }

  for (ent = shf->ents; ent; ent = ent->n)
    if (ent->chs[ch_num]) {
      D("eid(%s)", ent->eid);
      fprintf(out, "%s\n", ent->eid);
    }
  fclose(out);
  return 1;
}

/*() Load subscriptions of a channel. Called once at startup.
 * N.B. The channel composition is fixed at boot time so no locking is needed. */

/* Called by:  zxbus_load_subs */
static int zxbus_load_ch_subs(struct hiios* shf, struct hi_ch* ch)
{
  int ch_num = ch - shf->chs;
  char* buf;
  char* p;
  char* nl;
  struct hi_ent* ent;

  D("Loading subs for ch(%s) ch_num=%d", ch->dest, ch_num);
  buf = p = read_all_malloc("load_ch_subs",1,0, "%s" ZXBUS_CH_DIR "%s/.subs", zxbus_path, ch->dest);
  if (!p)
    return 0;
  while (nl = strchr(p, '\n')) {
    *nl = 0;
    if (ent = zxbus_load_ent(shf, -1, p)) {
      ent->chs[ch_num] = HI_SUBS;
    } else {
      ERR("entity(%s) does not exist, in %s/.subs", p, ch->dest);
    }
    p = nl+1;
  }
  FREE(buf);
  return 1;
}

/*() Load subscriptions of all channels. Called once at startup.
 * N.B. The channel composition is fixed at boot time so no locking is needed. */

/* Called by:  zxbusd_main */
int zxbus_load_subs(struct hiios* shf)
{
  char path[ZXID_MAX_BUF];
  struct dirent* de;
  DIR* dir;
  struct hi_ch* ch = shf->chs;
  int n = 0;
  
  name_from_path(path, sizeof(path), "%s" ZXBUS_CH_DIR, zxbus_path);
  dir = opendir(path);
  if (!dir) {
    perror("opendir for /var/zxid/bus/ch/ (or other if configured)");
    D("failed path(%s)", path);
    return 0;
  }
  
  while (de = readdir(dir))
    if (de->d_name[0] != '.' && de->d_name[strlen(de->d_name)-1] != '~') { /* ign hidden&backup */
      if (++n > shf->max_chs) {
	ERR("More channels in directory(%s) than fit in array. Consider increasing -nch", path);
	break;
      }
      ch->dest = strdup(de->d_name);
      zxbus_load_ch_subs(shf, ch++);
    }
  closedir(dir);
  return 1;
}

/*() Persist a subscription and book it into data structure.
 * Returns:: 1 on success, 0 on failure. */

/* Called by:  stomp_got_subsc */
int zxbus_subscribe(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* req)
{
  struct hi_ch* ch;
  struct hi_ent* ent;

  if (!req || !req->ad.stomp.dest || !*req->ad.stomp.dest) {
    ERR("Subscription missing destination %p", req);
    return 0;
  }
  
  LOCK(io->qel.mut, "login");
  D("LK&UNLK io(%x)->qel.mut->thr=%lx (%s:%d)", io->fd, (long)io->qel.mut.thr, io->qel.mut.func, io->qel.mut.line);
  ent = io->ent;
  UNLOCK(io->qel.mut, "login");
  if (!ent) {
    ERR("No entity associated with io_%p", io);
    return 0;
  }
  
  ch = zxbus_find_ch(hit->shf, -2, req->ad.stomp.dest);    /* Check that the channel exists. */
  if (!ch) {
    ERR("%s: attempted subscription to nonexistent channel(%.*s)", ent->eid, (int)(strchr(req->ad.stomp.dest, '\n') - req->ad.stomp.dest), req->ad.stomp.dest);
    return 0;
  }

  /* N.B. The receipt needs to be sent before registering subscription and
   * scheduling pending deliveries, lest the simple listener clients
   * get confused by seeing a MESSAGE when expecting RECEIPT. */
  stomp_send_receipt(hit, io, req);

  /* Check whether entity is already subscribed. The channel arrays are
   * in alignment so we only need to look at the corresponding slot. */
  
  LOCK(hit->shf->ent_mut, "subscribe");
  D("LOCK ent_mut->thr=%lx (%s:%d)", (long)hit->shf->ent_mut.thr, hit->shf->ent_mut.func, hit->shf->ent_mut.line);
  if (ent->chs[ch - hit->shf->chs]) {
    ent->chs[ch - hit->shf->chs] = HI_SUBS_ON;
    D("UNLOCK ent_mut->thr=%lx (%s:%d)", (long)hit->shf->ent_mut.thr, hit->shf->ent_mut.func, hit->shf->ent_mut.line);
    UNLOCK(hit->shf->ent_mut, "subscribed");
    D("Already subscribed to(%s)", ch->dest);
  } else {
    ent->chs[ch - hit->shf->chs] = HI_SUBS_ON;
    zxbus_write_ch_subs(hit->shf, ch);
    D("UNLOCK ent_mut->thr=%lx (%s:%d)", (long)hit->shf->ent_mut.thr, hit->shf->ent_mut.func, hit->shf->ent_mut.line);
    UNLOCK(hit->shf->ent_mut, "subscribe2");
  }
  zxbus_sched_pending_delivery(hit, ch->dest);
  return 1;
}

/* EOF  --  zxbussubs.c */
