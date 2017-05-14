/* zxbusdist.c  -  Message persist and distribution, subscription management
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
 *
 * Subscriptions are organized by destination channel. First the
 * channel is looked up and then list of entity objects is chased to
 * deliver the message to each of them. If an entity is currently
 * logged in, it will have an io object and we deliver
 * immediately. Entities that are subscribed, but not currently logged
 * in will cause pending delivery. In fact all entities should be
 * considered pending until ACK has been received WRT to the message.
 * Hence we opt to remember the ACK'd entities rather than the pending
 * ones. (A slight side effect of this is that you can subscribe to a
 * channel and receive messages that were generated prior to your
 * subscription having been created.)
 *
 * The records about ACKs are kept in append only files under
 * ch/DEST/.ack/SHA1.ack which has one per line the entity IDs that
 * have ACKd (AB0 format). This file might also contain cryptographic
 * signature proof of the ACK. In that case the first 3 characters of
 * the line specify the version and type of line (initially "AB1 " -
 * note the space), followed by the entity id and safe-base64 of the
 * signature, separated by a space (n.b. the filename itself is a SHA1
 * hash of the content of the message).
 *
 * When it has been determined that all entities have ACKd a message
 * it is retired either by deleting it or by moving it to .del/
 * directory.  The latter option allows some post processing before
 * removal - or simply can act as a convenient cache of recent
 * messages for debugging purposes.  .del/ SHOULD be cleaned
 * periocially by a cron job.
 *
 * When an entity sends SUBSCRIBE command, all messages pending for
 * the entity on that channel are sent. This will force scanning the
 * ACK receipt files to determine if all subscribers have ACKd so that
 * message retirement can be triggered. To avoid a full matrix of acks
 * and nacks, we maintain counts. *** counts may be thrown off if an
 * entity joins in middle of delivery attempt.
 *
 * Number of channels is expected to be relatively small, except for
 * per user channels that are handled as a special case. The number of
 * subscribers to common channels is expected to be extremely large,
 * The number of subscribers for per user channel are expected to be
 * relatively small. Thus alternative structure is to simply scan the
 * io object array. This has the advantage of not maintaining a
 * separate data structure that would require additional pointer
 * fields and additional locking.
 *
 * Persistent store of channel subscriptions is realized by having in
 * each channel directory a special file .subs which lists the entity
 * IDs of the subscribers, one per line. When zxbusd starts, it loads
 * this persisted data to memory. When new subscriptions are made, the
 * subscription is "written through" to persistent storage and the
 * in-memory data structure is updated as well.
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
extern zxid_conf* zxbus_cf;
extern char* zxbus_path;

/*() Read the .ack/SHA1 file for a message and parse it into linked
 * lists of hi_ack nodes attached to entities. The file consists
 * of lines like
 *   AB1 eid ACK sig
 * The pdu should be the delivery or pending bitch PDU.
 * locking:: whill take hit->shf->ent_mut */

/* Called by:  zxbus_sched_pending_delivery */
static void zxbus_load_acks(struct hi_thr* hit, struct hi_pdu* pdu, int fd)
{
  struct hi_ack* ack;
  struct hi_ent* ent;
  char* p;
  char* nl;
  char* aa;
  char* buf;
  int gotall, len = get_file_size(fd);
  ZMALLOCN(buf, len+1);
  if (read_all_fd(fd, buf, len, &gotall) == -1) {
    D("reading acks failed gotall=%d",gotall);
    FREE(buf);
    return;
  }
  buf[gotall] = 0;
  
  LOCK(hit->shf->ent_mut, "load-acks");  // *** very big lock
  D("LOCK ent_mut->thr=%lx (%s:%d)", (long)hit->shf->ent_mut.thr, hit->shf->ent_mut.func, hit->shf->ent_mut.line);
  for (p = buf; p < buf+gotall; p = nl+1) {
    if (!(nl = strchr(p, '\n')))
      nl = buf+gotall;
    if (!memcmp(p, "AB1 ", sizeof("AB1 ")-1)) {
      if (aa = zx_memmem(p+sizeof("AB1 ")-1, nl-p, " ACK", sizeof(" ACK")-1)) {
	if (ent = zxbus_load_ent(hit->shf, aa-(p+sizeof("AB1 ")-1), p+sizeof("AB1 ")-1)) {
	  ZMALLOC(ack);
	  ack->pdu = pdu;
	  ack->n = ent->acks;
	  ent->acks = ack;
	  D("Added ack pdu_%p to ent_%p eid(%s)", pdu, ent, ent->eid);
	} else {
	  ERR("Entity of the ACK not found. line(%.*s), skipping", (int)(nl-p), p);
	}
      } else {
	ERR("Not an ACK line(%.*s) in acks, skipping", (int)(nl-p), p);
      }
    } else {
      ERR("Bad line(%.*s) in acks, skipping", (int)(nl-p), p);
    }
  }
  D("UNLOCK ent_mut->thr=%lx (%s:%d)", (long)hit->shf->ent_mut.thr, hit->shf->ent_mut.func, hit->shf->ent_mut.line);
  UNLOCK(hit->shf->ent_mut, "load-acks");
  FREE(buf);
}

/*() Check if pdu is in the entity's already acked list.
 * The pdu should be the delivery or pending bitch PDU.
 * locking:: caller MUST hold shf->ent_mut
 * return:: 1 if found (and as side effect remove), 0=not found */

/* Called by:  stomp_msg_deliver */
static int zxbus_already_ackd(struct hi_ent* ent, struct hi_pdu* pdu)
{
  struct hi_ack* prev;
  struct hi_ack* ack = ent->acks;
  D("Checking ent_%p eid(%s) io(%x) acks_%p pdu_%p", ent, ent->eid, ent->io?ent->io->fd:0xdeadbeef, ack, pdu);
  if (!ack)
    return 0;
  if (ack->pdu == pdu) {
    D("Already ACKd by eid(%s)", ent->eid);
    ent->acks = ack->n;
    FREE(ack);
    return 1;
  }
  for (prev = ack, ack = ack->n; ack; prev = ack, ack = ack->n)
    if (ack->pdu == pdu) {
      D("Already ACKd by eid(%s)", ent->eid);
      prev->n = ack->n;
      FREE(ack);
      return 1;
    }
  return 0;
}

/*() Handle special "delivery bitch" PDU that represents need to
 * send a message to listeners of a channel (aka destination).
 * zxbus_persist() creates a synthetic PDU which is scheduled for the delivery
 * work in todo queue. This PDU is not associated to any particular
 * io object and will keep on rescheduling itself until its job
 * has been done. At that point it will free itself.
 * locking:: whill take hit->shf->ent_mut */

/* Called by:  hi_shuffle */
void stomp_msg_deliver(struct hi_thr* hit, struct hi_pdu* db_pdu)
{
  struct hi_ent* ent;
  struct hi_ch* ch;
  int ch_num;
  D("db_pdu(%p) events=0x%x", db_pdu, db_pdu->events);

  ch = zxbus_find_ch(hit->shf, -2, db_pdu->ad.delivb.dest);
  if (!ch)
    return;
  ch_num = ch - hit->shf->chs;
  LOCK(hit->shf->ent_mut, "deliver"); // *** very big lock, held across I/O. Consider per ent lock
  for (ent = hit->shf->ents; ent; ent = ent->n)
    if (ent->chs[ch_num]) {  /* entity listens on this channel? */
      if (zxbus_already_ackd(ent, db_pdu)) {
	DD("Already ACKd eid(%s)", ent->eid);
      } else if (ent->io && ent->chs[ch_num] == HI_SUBS_ON) {
	hi_sendf(hit, ent->io, db_pdu, 0,
		 "MESSAGE\nsubscription:%s\nmessage-id:%d\ndestination:%.*s\ncontent-length:%d\n\n%.*s%c",
		 "0", ent->io->ad.stomp.msgid++,
		 (strchr(db_pdu->ad.delivb.dest, '\n') - db_pdu->ad.delivb.dest), db_pdu->ad.delivb.dest,
		 db_pdu->ad.delivb.len, db_pdu->ad.delivb.len,
		 db_pdu->ad.delivb.body, 0);
	/* the receiving half will decrement  ++(int)db_pdu->ad.delivb.acks */
	++(db_pdu->ad.delivb.acks); /* number of ACKs pending due to MESSAGEs sent */
      } else {
	D("Can not deliver. entity(%s) not connected at the moment?", ent->eid);
	ent->chs[ch_num] = HI_SUBS_PEND;
	++(db_pdu->ad.delivb.nacks);
      }
    }
  UNLOCK(hit->shf->ent_mut, "deliver");
#if 0
  if (db_pdu->ad.delivb.acks)  /* still something pending? */
    hi_todo_produce(hit, &db_pdu->qel, "deliv-bitch-again", 0);
  else
    hi_free_req(hit, db_pdu, "db_pdu ");
#else
  /* No rescheduling. Operate in one-shot mode: all connected ones get delivery attempt.
   * The cleanup will happen when last ACK is received and db_pdu->ad.delivb.acks
   * count has dropped to zero. Redelivery attempts later are handled separately. */
#endif
}

/*() Schedule new delivery to happen. See stomp_msg_deliver() for what happens next.
 * We create a synthetic PDU which is scheduled for the delivery
 * work in todo queue. This PDU is not associated to any particular
 * io object (and will keep on rescheduling itself until its job
 * has been done (??? may be not)). At that point it will free itself.
 * The acks will be written to ack_fd (to avoid 99% of the double delivery, and
 * to have an audit trail on our side about deliveries. */

/* Called by:  zxbus_persist */
static void zxbus_sched_new_delivery(struct hi_thr* hit, struct hi_pdu* req, const char* sha1name, int dest_len, const char* dest)
{
  struct hi_pdu* pdu = hi_pdu_alloc(hit, "deliv-bitch");
  pdu->qel.kind = HI_PDU_DIST;
  memcpy(pdu->m, req->m, req->need);  /* copy PDU substance */
  pdu->ap += req->need;
  pdu->ad.delivb.len = req->ad.delivb.len;
  pdu->ad.delivb.body = pdu->m + (req->ad.stomp.body - req->m);
  pdu->ad.delivb.dest = pdu->m + (req->ad.stomp.dest - req->m);

  pdu->ad.delivb.acks = 0;
  pdu->ad.delivb.nacks = 0;

  //  | O_DIRECT  -- seems to give alignment problems, i.e. 22 EINVAL Invalid Argument
  pdu->ad.delivb.ack_fd = open_fd_from_path(O_CREAT | O_WRONLY | O_APPEND | O_SYNC, 0666, "sched deliv", 1, "%s" ZXBUS_CH_DIR "%.*s/.ack/%s", zxbus_path, dest_len, dest, sha1name);
  hi_todo_produce(hit, &pdu->qel, "deliv-bitch", 0);
}

/*() Scan messages in channel directory and schedule pending ones for delivery.
 * We avoid delivering to listeners that have already received the PDU
 * by reading in the .ack/SHA1 file and attaching to pending bitch PDU
 * a linked list of already successful entities. Linked list because
 * it is simplest, but a hash table could be more effective. */

/* Called by:  zxbus_subscribe */
void zxbus_sched_pending_delivery(struct hi_thr* hit, const char* dest)
{
  char path[ZXID_MAX_BUF];
  struct dirent* de;
  DIR* dir;
  struct hi_pdu* pdu;
  
  name_from_path(path, sizeof(path), "%s" ZXBUS_CH_DIR "%s", zxbus_path, dest);
  dir = opendir(path);
  if (!dir) {
    perror("opendir for /var/zxid/bus/ch/DEST (or other if configured)");
    D("failed path(%s) dest(%s)", path, dest);
    return;
  }
  
  while (de = readdir(dir))  /* iterate over messages in the channel directory */
    if (de->d_name[0] != '.' && de->d_name[strlen(de->d_name)-1] != '~') { /* ign hidden&backup */
      if (!(pdu = hi_pdu_alloc(hit, "pend-bitch")))
	break;
      pdu->qel.kind = HI_PDU_DIST;
      pdu->ap += read_all(pdu->lim - pdu->ap, pdu->ap, "pend-bitch", 1,
			  "%s" ZXBUS_CH_DIR "%s/%s", zxbus_path, dest, de->d_name);
      
      if (stomp_parse_pdu(pdu))
	continue;  /* parse error in PDU */
      
      pdu->ad.delivb.acks = 0;
      pdu->ad.delivb.nacks = 0;

      //  | O_DIRECT  -- seems to give alignment problems, i.e. 22 EINVAL Invalid Argument
      pdu->ad.delivb.ack_fd = open_fd_from_path(O_CREAT | O_RDWR | O_APPEND | O_SYNC, 0666, "pend", 1, "%s" ZXBUS_CH_DIR "%s/.ack/%s", zxbus_path, dest, de->d_name);
      zxbus_load_acks(hit, pdu, pdu->ad.delivb.ack_fd);
      hi_todo_produce(hit, &pdu->qel, "pend-bitch", 0);
    }
  closedir(dir);
}

/*() Retire fully delivered message.
 * The message is moved to .del/ for later removal if it exists,
 * or just unlinked on the spot.
 * return:: 0 on fail, 1 on rename to .del, 2 on unlink */

/* Called by:  stomp_got_ack */
int zxbus_retire(struct hi_thr* hit, struct hi_pdu* db_pdu)
{
  int len, dest_len;
  char c_path[ZXID_MAX_BUF];  /* current channel path */
  char d_path[ZXID_MAX_BUF];  /* .del path after atomic rename */

  dest_len = strchr(db_pdu->ad.delivb.dest, '\n')-db_pdu->ad.delivb.dest;
  len = name_from_path(c_path, sizeof(c_path), "%sch/%.*s/", zxbus_path, dest_len, db_pdu->ad.delivb.dest);
  if (sizeof(c_path)-len < 28+5 /* +5 accounts for d_path having 5 more chars (.del/) */) {
    ERR("The c_path for retiring exceeds limit. len=%d", len);
    return 0;
  }
  DD("c_path(%s) len=%d", c_path, len);
  DD("sha1_input(%.*s) len=%d", db_pdu->ap - db_pdu->m, db_pdu->m, db_pdu->ap - db_pdu->m);
  sha1_safe_base64(c_path+len, db_pdu->ap - db_pdu->m, db_pdu->m);
  c_path[len+27] = 0;
  DD("c_path(%s)", c_path);
  
  len = name_from_path(d_path, sizeof(d_path), "%sch/%.*s/.del/%s", zxbus_path, dest_len, db_pdu->ad.delivb.dest, c_path+len);
  DD("d_path(%s)", d_path);
      
  if (!rename(c_path, d_path))
    return 1;

  D("Retire: Renaming file(%s) to(%s) failed: %d %s. Defaulting to deleting the file altogether. Check permissions and that directories exist if you do not want deletion. For rename(2) to work, directories must be on the same filesystem. euid=%d egid=%d", c_path, d_path, errno, STRERROR(errno), geteuid(), getegid());

  if (!unlink(c_path))
    return 2;

  ERR("Retire: Renaming file(%s) to(%s) as well as unlinking it failed: %d %s. Check permissions and that directories exist and that they are on the same filesystem. euid=%d egid=%d", c_path, d_path, errno, STRERROR(errno), geteuid(), getegid());
  return 0;
}

/*() Attempt to presist a message.
 * Persisting involves synchronous write and an atomic filesystem rename
 * operation, ala Maildir. The persisted message is a file that contains
 * the entire STOMP 1.1 PDU including headers and body. Filename is the sha1
 * hash of the contents of the file.
 * return:: 0 on failure, 1 on success.
 * see also:: persist feature in zxbus_listen_msg() */

/* Called by:  stomp_got_send */
int zxbus_persist(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* req)
{
  int len, dest_len;
  char* dest;
  char* nl;
  char c_path[ZXID_MAX_BUF];  /* channel destination path after atomic rename */
  
  if (!(dest = req->ad.stomp.dest)) {
    stomp_err(hit,io,req,"no destination - client error","SEND MUST specify destination header, i.e. channel to send to.");
    return 0;
  }
  nl = memchr(dest, '\n', req->ap - dest);
  dest_len = nl-dest;
  DD("persist(%.*s)", dest_len, dest);
  
  if (!(len = zxbus_persist_msg(zxbus_cf, sizeof(c_path), c_path,
			       dest_len, dest, req->ap-req->m, req->m))) {
    stomp_err(hit,io,req,"persist failure at server","Unable to persist message. Can not guarantee reliable delivery, therefore rejecting.");    
    /* *** should we make an effort to close the connection? */
    return 0;
  }
  D("persisted at(%s) (%.*s) len=%d", c_path, (int)MIN(req->ap-req->ad.stomp.body, 10), req->ad.stomp.body, (int)(req->ap-req->m));
  if (verbose) {
    if (req->ad.stomp.receipt)
      nl = memchr(req->ad.stomp.receipt, '\n', req->ap - req->ad.stomp.receipt);
    else
      nl = 0;
    printf("FMT0 persist at %s '%.*s' len=%d rcpt(%.*s)\n", c_path, (int)MIN(req->ap-req->ad.stomp.body, 10), req->ad.stomp.body, (int)(req->ap-req->m), nl?((int)(nl-req->ad.stomp.receipt)):0, nl?req->ad.stomp.receipt:"");
  }
  zxbus_sched_new_delivery(hit, req, c_path+len-27, dest_len, dest);
  return 1;
}

/* EOF  --  zxbusdist.c */
