/* stomp.c  -  STOMP 1.1 protocol for HIIOS engine
 * Copyright (c) 2012 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing. See file COPYING.
 * Special grant: http.c may be used with zxid open source project under
 * same licensing terms as zxid itself.
 * $Id$
 *
 * 16.8.2012, created, based on http and smtp --Sampo
 * 19.8.2012, added tolerance for CRLF where strictly LF is meant --Sampo
 *
 * STOMP 1.1 frame is considered a PDU and consists of
 *
 *   \n              -- zero, or more in case of heart beats
 *   COMMAND\n       -- lines end in LF (not CRLF)
 *   header:value\n  -- zero or more
 *   \n              -- blank line separates headers and body
 *   payload
 *   \0
 *   \n              -- zero, or more in case of heart beats
 *
 * See also:  http://stomp.github.com/stomp-specification-1.1.html (20110331)
 * Todo: implement heart beat generation and checking
 */

#include "platform.h"
#include "errmac.h"
#include "akbox.h"
#include "hiios.h"
#include "hiproto.h"
#include <zx/zxidconf.h>
#include <zx/zxidutil.h>

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
#define STOMP_MIN_PDU_SIZE (sizeof("ACK\n\n\0")-1)

extern int verbose;  /* defined in option parsing in zxbusd.c */
extern zxid_conf* zxbus_cf;

#if 0
/* Called by: */
static struct hi_pdu* stomp_encode_start(struct hi_thr* hit)
{
  struct hi_pdu* resp = hi_pdu_alloc(hit,"stomp_enc_start");
  if (!resp) { hi_dump(hit->shf); NEVERNEVER("*** out of pdus in bad place %d", 0); }
  return resp;
}
#endif

/*() Send ERROR to remote client. */

/* Called by:  stomp_frame_err, stomp_got_login x2, zxbus_persist x2 */
int stomp_err(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* req, const char* ecode, const char* emsg)
{
  int len;
  char* rcpt;
  if ((rcpt = req->ad.stomp.receipt)) {
    len = memchr(rcpt, '\n', req->ap - rcpt) - (void*)rcpt;
  } else {
    len = 1;
    rcpt = "-";
  }
  ERR("%s", emsg);
  hi_sendf(hit, io, 0, req, "ERROR\nmessage:%s\nreceipt-id:%.*s\ncontent-type:text/plain\ncontent-length:%d\n\n%s%c", ecode, len, rcpt, strlen(emsg), emsg, 0);
  return HI_CONN_CLOSE;
}

/*() Send an error early on in decode process */

/* Called by:  stomp_decode x2 */
static int stomp_frame_err(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* req, const char* emsg)
{
  /* At this early stage the req is still a io->cur_pdu. We need to
   * promote it to a real request so that the free logic will work right. */
  hi_add_to_reqs(hit, io, req, STOMP_MIN_PDU_SIZE);
  return stomp_err(hit,io,req,"malformed frame received",emsg);
}

#define CMD_NI_MSG "Command(%.*s) not implemented by server."

/*() Send not implemented ERROR to remote client. */

/* Called by:  stomp_decode x7, stomp_got_unsubsc */
static int stomp_cmd_ni(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* req, const char* cmd)
{
  const char* nl = strchr(cmd, '\n');
  int len;
  char* rcpt;
  if ((rcpt = req->ad.stomp.receipt)) {
    len = memchr(rcpt, '\n', req->ap - rcpt) - (void*)rcpt;
  } else {
    len = 1;
    rcpt = "-";
  }
  ERR(CMD_NI_MSG, (int)(nl-cmd), cmd);
  hi_sendf(hit, io, 0, req, "ERROR\nmessage:command not implemented by server\nreceipt-id:%.*s\ncontent-type:text/plain\ncontent-length:%d\n\n" CMD_NI_MSG "%c", len, rcpt, sizeof(CMD_NI_MSG)-3+(nl-cmd), nl-cmd, cmd, 0);
  return HI_CONN_CLOSE;
}

/*() Got ERROR from remote client. */

/* Called by:  stomp_decode */
static int stomp_got_err(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* req)
{
  /*struct hi_pdu* resp = stomp_encode_start(hit);*/
  /*hi_sendv(hit, io, 0, req, resp, len, resp->m, size, req->m + len);*/
  ERR("remote sent error(%.*s)", (int)(req->ap-req->m), req->m);
  return HI_CONN_CLOSE;
}

/*() Send a receipt to client. */

/* Called by:  stomp_got_disc, stomp_got_send, stomp_got_zxctl, zxbus_subscribe */
void stomp_send_receipt(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* req)
{
  int len;
  char* rcpt;
  char sigbuf[1024];
  if ((rcpt = req->ad.stomp.receipt)) {
    len = (char*)memchr(rcpt, '\n', req->ap - rcpt) - rcpt;
  } else {
    len = 1;
    rcpt = "-";
  }
  DD("rcpt(%.*s) len=%d", len, rcpt, len);

  zxbus_mint_receipt(zxbus_cf, sizeof(sigbuf), sigbuf,
		     len, rcpt,
		     -2, req->ad.stomp.dest,
		     -1, io->ent->eid,   /* entity to which we issue receipt */
		     req->ad.stomp.len, req->ad.stomp.body);
  hi_sendf(hit, io, 0, req, "RECEIPT\nreceipt-id:%.*s\nzx-rcpt-sig:%s\n\n%c", len, rcpt, sigbuf,0);
}

/* STOMP Received Command Handling */

/* Called by:  stomp_decode */
static int stomp_got_login(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* req)
{
  if (!req->ad.stomp.login)
    return stomp_err(hit, io, req, "login fail", "No login header supplied (client error). zxbusd(8) requires login header whose value is the EntityID of the connecting client.");
  
  if (zxbus_login_ent(hit, io, req)) {
    hi_sendf(hit, io, 0, req, "CONNECTED\nversion:1.1\nserver:zxbusd-1.x\n\n%c", 0);
    return 0;
  } else
    return stomp_err(hit, io, req, "login fail", "login failed either due to nonexistent entity id or bad credential");
}

/* Called by:  stomp_decode */
static int stomp_got_disc(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* req)
{
  /* *** figure out the real receipt id */
  stomp_send_receipt(hit, io, req);
  return HI_CONN_CLOSE;
}

/*() Main function for receiving audit bus summary log lines from SPs.
 * This function will first store the line in a persistent way (RAID1
 * arrangement needs to be implemented at the OS level), and then,
 * perhaps, attempt to deliver the message to all subscribers. Indeed,
 * delivery should be attempted first and if successful, the persistence
 * is not necessary. If delivery is unsuccessful, the delivery needs
 * to be retried, i.e. this is a store-and-forward system. However,
 * the delivery first approach needs extensive IO engine
 * operations and it thus may be easier to just store the message
 * first and then have a separate process attempt the sending. This
 * latter is the approach adopted here. */

/* Called by:  stomp_decode */
static void stomp_got_send(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* req)
{
  if (zxbus_persist(hit, io, req)) {
    stomp_send_receipt(hit, io, req);
  } else {
    ERR("Persist Problem. Disk full? %d", 0);
    //hi_sendf(hit, io, 0, req, "ERROR\nmessage:persist failure\nreceipt-id:%.*s\n\nUnable to persist message. Can not guarantee reliable delivery, therefore rejecting.%c", len, rcpt, 0);
  }
}

/*() Find a request that matches response. Looks in
 * the io->pending list for message ID match. When found,
 * the req is dequeued from pending. */

/* Called by:  stomp_got_ack, stomp_got_nack */
static struct hi_pdu* stomp_find_pending_req_for_resp(struct hi_io* io, struct hi_pdu* resp)
{
  struct hi_pdu* prev;
  struct hi_pdu* req;
  int midlen=resp->ad.stomp.msg_id?(strchr(resp->ad.stomp.msg_id,'\n')- resp->ad.stomp.msg_id):0;
  
  LOCK(io->qel.mut, "ack");
  for (prev = 0, req = io->pending; req; prev = req, req = req->n) {
    if (!memcmp(resp->ad.stomp.msg_id, req->ad.stomp.msg_id, midlen+1)) {
      if (prev)
	prev->n = req->n;
      else
	io->pending = req->n;
      resp->req = req;
      resp->parent = req->parent;
      break;
    }
  }
  UNLOCK(io->qel.mut, "ack");
  return req;
}

/*() Process NACK response from client to MESSAGE request sent by server.
 * This is essentially nice way for the client to communicate to us it has
 * difficulty in persisting the message. It could also just hang up and the
 * net effect would be the same. However, receiving the NACK allows us to
 * close the delivery bitch sooner so we can free the memory in the
 * hopeless cases quicker. (*** there should also be a handler for
 * close-connection lost that would do similar cleanup) */

/* Called by:  stomp_decode */
static void stomp_got_nack(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* resp)
{
  int sublen, midlen, siglen;
  struct hi_pdu* parent;

  sublen = resp->ad.stomp.subsc ? (strchr(resp->ad.stomp.subsc, '\n') - resp->ad.stomp.subsc) : 0;
  midlen = resp->ad.stomp.msg_id ?(strchr(resp->ad.stomp.msg_id, '\n')- resp->ad.stomp.msg_id) : 0;
  siglen = resp->ad.stomp.zx_rcpt_sig ? (strchr(resp->ad.stomp.zx_rcpt_sig, '\n') - resp->ad.stomp.zx_rcpt_sig) : 0;

  D("NACK subsc(%.*s) msg_id(%.*s) zx_rcpt_sig(%.*s)", sublen, sublen?resp->ad.stomp.subsc:"", midlen, midlen?resp->ad.stomp.msg_id:"", siglen, siglen?resp->ad.stomp.zx_rcpt_sig:"");
  
  ASSERTOPP(resp->req, ==, 0);
  if (!stomp_find_pending_req_for_resp(io, resp)) {
    ERR("Unsolicited NACK subsc(%.*s) msg_id(%.*s)", sublen, sublen?resp->ad.stomp.subsc:"", midlen, midlen?resp->ad.stomp.msg_id:"");
    return;
  }
  parent = resp->parent;
  ASSERT(parent);
  
  /* *** add validation of zx_rcpt_sig. Lookup the cert using metadata for the EID. */
  /* Remember NACK somewhere? */
  hi_free_resp(hit, resp, "nack ");
  
  ++(parent->ad.delivb.nacks);
  if (--(parent->ad.delivb.acks) <= 0) {
    ASSERTOPI(parent->ad.delivb.acks, ==, 0);
    close_file(parent->ad.delivb.ack_fd, "got_nack");
    D("nack: freeing parent(%p)", parent);
    hi_free_req(hit, parent, "nack ");
  }
}

/*() Process ACK response from client to MESSAGE request sent by server. */

/* Called by:  stomp_decode */
static void stomp_got_ack(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* resp)
{
  int sublen, midlen, siglen, ver;
  struct hi_pdu* parent;
  char* eid;
  char buf[1024];
  
  /* First, it was wrong for hi_add_to_reqs() to be called for an ACK as acks are
   * really responses to MESSAGEs. Thus undo that action here. */
  
  hi_del_from_reqs(io, resp);
  
  sublen = resp->ad.stomp.subsc ? (strchr(resp->ad.stomp.subsc, '\n') - resp->ad.stomp.subsc) : 0;
  midlen = resp->ad.stomp.msg_id ?(strchr(resp->ad.stomp.msg_id, '\n')- resp->ad.stomp.msg_id) : 0;
  siglen = resp->ad.stomp.zx_rcpt_sig ? (strchr(resp->ad.stomp.zx_rcpt_sig, '\n') - resp->ad.stomp.zx_rcpt_sig) : 0;

  DD("ACK subsc(%.*s) msg_id(%.*s) zx_rcpt_sig(%.*s)", sublen, sublen?resp->ad.stomp.subsc:"", midlen, midlen?resp->ad.stomp.msg_id:"", siglen, siglen?resp->ad.stomp.zx_rcpt_sig:"");

  if (!stomp_find_pending_req_for_resp(io, resp)) {
    ERR("Unsolicited ACK subsc(%.*s) msg_id(%.*s)", sublen, sublen?resp->ad.stomp.subsc:"", midlen, midlen?resp->ad.stomp.msg_id:"");
    return;
  }
  parent = resp->parent;
  ASSERT(parent);
  
  if (errmac_debug>1)
    D("ACK par_%p->len=%d rq_%p->len=%d\nparent->body(%.*s)\n   req->body(%.*s)", parent, parent->ad.delivb.len, resp->req, resp->req->ad.stomp.len, parent->ad.delivb.len, parent->ad.delivb.body, resp->req->ad.stomp.len, resp->req->ad.stomp.body);
  else
    D("ACK par_%p->len=%d rq_%p->len=%d", parent, parent->ad.delivb.len, resp->req, resp->req->ad.stomp.len);

  eid = zxid_my_ent_id_cstr(zxbus_cf);
  ver = zxbus_verify_receipt(zxbus_cf, io->ent->eid,
			     siglen, siglen?resp->ad.stomp.zx_rcpt_sig:"",
			     -2, resp->req->ad.stomp.msg_id,
			     -2, resp->req->ad.stomp.dest,
			     -1, eid,  /* our eid, the receipt was issued to us */
			     resp->req->ad.stomp.len, resp->req->ad.stomp.body);
  ZX_FREE(zxbus_cf->ctx, eid);
  if (ver != ZXSIG_OK) {
    ERR("ACK signature validation failed: %d", ver);
    hi_free_resp(hit, resp, "ack ");
    return;
  }
  
  /* Record the receipt in /var/zxid/bus/ch/DEST/.ack/SHA1.ack for our audit trail, and to
   * indicate that we need not attempt delivery again to this entity. */
  write_all_fd_fmt(parent->ad.delivb.ack_fd, "ACK", sizeof(buf), buf, "AB1 %s ACK %.*s\n",
		   io->ent->eid, siglen, siglen?resp->ad.stomp.zx_rcpt_sig:"");
  
  hi_free_resp(hit, resp, "ack ");
  
  if (--(parent->ad.delivb.acks) <= 0) {
    ASSERTOPI(parent->ad.delivb.acks, ==, 0);
    close_file(parent->ad.delivb.ack_fd, "got_ack");
    if (!parent->ad.delivb.nacks) {
      D("Delivered to all: mv msg to .del par_%p", parent);
      zxbus_retire(hit, parent);
    }
    hi_free_req(hit, parent, "parent ");
  }
}

/* Called by:  stomp_decode */
static void stomp_got_subsc(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* req)
{
  HI_SANITY(hit->shf, hit);
  if (zxbus_subscribe(hit, io, req)) {
    /* N.B. The receipt was already sent. It needs to be sent before
     * scheduling pending deliveries, lest the simple listener clients
     * get confused by seeing a MESSAGE when expecting RECEIPT. */
  } else {
    ERR("Subscribe Problem. Disk full? %d", 0);
  }
}

/* Called by:  stomp_decode */
static void stomp_got_unsubsc(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* req)
{
  stomp_cmd_ni(hit,io,req,"UNSUBSCRIBE\n");
}

/*() Nonstandard STOMP command for ZXBUS testing.
 * Based on different body content, diffrent magic can be invoked:
 * dump - dump data structures to stdout with hi_dump() */

/* Called by:  stomp_decode */
static void stomp_got_zxctl(struct hi_thr* hit, struct hi_io* io, struct hi_pdu* req)
{
  D("ZXCTL(%.*s)", req->ad.stomp.len, req->ad.stomp.body);
  if (!memcmp(req->ad.stomp.body, "dump", sizeof("dump")-1)) hi_dump(hit->shf);
  stomp_send_receipt(hit, io, req);
}

/*() Parse STOMP 1.1 header to a struct. */

/* Called by:  stomp_decode, stomp_parse_pdu */
void stomp_parse_header(struct hi_pdu* req, char* hdr, char* val)
{
#define HDR(header, field, valu) } else if (!memcmp(hdr, header, sizeof(header)-1)) { if (!req->ad.stomp.field) req->ad.stomp.field = (valu)

  if (!memcmp(hdr, "content-length:", sizeof("content-length:")-1)) {
    if (!req->ad.stomp.len) {
      req->ad.stomp.len = atoi(val);
      req->need = req->ad.stomp.len + val - req->m + 3;  /* not accurate if more headers follow, but fix below */
    }
    DD("len=%d need=%d (%.*s)", req->ad.stomp.len, req->need, val-hdr-1, hdr);
  } else if (!memcmp(hdr, "content-type:", sizeof("content-type:")-1)) { /* ignore */
  } else if (!memcmp(hdr, "message:", sizeof("message:")-1)) { /* ignore */
  HDR("receipt:",        receipt,   val);
  HDR("destination:",    dest,      val);
  HDR("zx-rcpt-sig:",    zx_rcpt_sig, val);
  HDR("host:",           host,      val);
  HDR("version:",        vers,      val);
  HDR("accept-version:", acpt_vers, val);
  HDR("server:",         server,    val);
  HDR("heart-beat:",     heart_bt,  val);
  HDR("login:",          login,     val);
  HDR("passcode:",       pw,        val);
  HDR("session:",        session,   val);
  HDR("transaction:",    tx_id,     val);
  HDR("id:",             subs_id,   val);
  HDR("subscription:",   subsc,     val);
  HDR("ack:",            ack,       val);
  HDR("message-id:",     msg_id,    val);
  HDR("receipt-id:",     rcpt_id,   val);  DD("receipt-id(%.*s)", 4, req->ad.stomp.rcpt_id);
  } else {
    D("Unknown header(%s) ignored.", hdr);
  }
}

/*() STOMP decoder and dispatch.
 * Return:: 0 for no error (including need more and PDU complete and processed),
 * 1 to force closing connection. */

/* Called by:  hi_read x2 */
int stomp_decode(struct hi_thr* hit, struct hi_io* io)
{
  struct hi_pdu* req = io->cur_pdu;
  char* command;
  char* hdr;
  char* val;
  char* p = req->m;

  D("decode req(%p)->need=%d (%.*s)", req, req->need, (int)MIN(req->ap - req->m, 3), req->m);
  
  HI_SANITY(hit->shf, hit);
  
  /* Skip newlines and check size */

  for (; p < req->ap && ONE_OF_2(*p, '\n', '\r'); ++p) ;
  
  if (req->ap - p < STOMP_MIN_PDU_SIZE) {   /* too little, need more */
    req->need = STOMP_MIN_PDU_SIZE;
    D("need=%d have=%d", req->need, (int)(req->ap - req->m));
    return  HI_NEED_MORE;
  }

  /* Extract command */

  command = p;
  hdr = memchr(p, '\n', req->ap - p);
  if (!hdr || ++hdr == req->ap) {
    req->need = MAX(STOMP_MIN_PDU_SIZE, req->ap - req->m + 2);
    D("need=%d have=%d", req->need, (int)(req->ap - req->m));
    return  HI_NEED_MORE;
  }
  memset(&req->ad.stomp, 0, sizeof(req->ad.stomp));
  p = hdr;

  /* Decode headers
   * 012345678901234567890
   * STOMP\n\n\0
   *         ^-p
   * STOMP\r\n\r\n\0
   *           ^-p
   * STOMP\nhost:foo\n\n\0
   *        ^-p        ^-pp
   * STOMP\r\nhost:foo\r\n\r\n\0
   *          ^-p          ^-pp
   * STOMP\nhost:foo\naccept-version:1.1\n\n\0
   *        ^-p       ^-pp                 ^-ppp
   * STOMP\r\nhost:foo\r\naccept-version:1.1\r\n\r\n\0
   *          ^-p         ^-pp                   ^-ppp
   */

  while (!ONE_OF_2(*p,'\n','\r')) {
    hdr = p;
    p = memchr(p, '\n', req->ap - p);
    if (!p || ++p == req->ap) {
      req->need = MAX(STOMP_MIN_PDU_SIZE, req->ap - req->m + 2);
      D("need=%d have=%d", req->need, (int)(req->ap - req->m));
      return HI_NEED_MORE;
    }
    val = memchr(hdr, ':', p-hdr);
    if (!val)
      return stomp_frame_err(hit, io, req, "Header missing colon.");
    ++val; /* skip : */
    stomp_parse_header(req, hdr, val);
  }
  
  /* Now body */

  if (*p == '\r') ++p;
  req->ad.stomp.body = ++p;

  /* p now points to first byte of body (after \n\n; at nul if no body) */

  if (req->ad.stomp.len) {
    req->need = p - req->m + req->ad.stomp.len + 1 /* nul */;  /* req->need has to be set correctly for hi_checkmore() to work right. */
    if (req->ad.stomp.len < req->ap - p) {
      /* Got complete with content-length */
      p += req->ad.stomp.len;
      if (*p++)
	return stomp_frame_err(hit, io, req, "No nul to terminate body.");
    } else {
      D("need=%d have=%d", req->need, (int)(req->ap - req->m));
      return HI_NEED_MORE;
    }
  } else {
    /* Scan until nul */
    while (1) {
      if (req->ap - p < 1) {   /* too little, need more */
	req->need = req->ap - req->m + 1;
	D("need=%d have=%d", req->need, (int)(req->ap - req->m));
	return HI_NEED_MORE;
      }
      if (!*p++) {  /* nul termination found */
	req->ad.stomp.len = p - req->ad.stomp.body - 1;
	req->need = p - req->m;
	break;
      }
    }
  }
  
  HI_SANITY(hit->shf, hit);
  hi_add_to_reqs(hit, io, req, STOMP_MIN_PDU_SIZE);
  HI_SANITY(hit->shf, hit);

  /* Command dispatch */

#define CMD(vrb, action) } else if (!memcmp(command, vrb, sizeof(vrb)-1)) { action
 
  if (!memcmp(command, "STOMP", sizeof("STOMP")-1)
      || (!memcmp(command, "CONNECT", sizeof("CONNECT")-1)
	  &&ONE_OF_2(command[sizeof("CONNECT")],'\n','\r')))
  { return stomp_got_login(hit,io,req);
  CMD("SEND",        stomp_got_send(hit,io,req) );
  CMD("ACK",         stomp_got_ack(hit,io,req) );
  CMD("DISCONNECT",  return stomp_got_disc(hit,io,req) );
  CMD("SUBSCRIBE",   stomp_got_subsc(hit,io,req) );
  CMD("UNSUBSCRIBE", stomp_got_unsubsc(hit,io,req) );
  CMD("BEGIN",       stomp_cmd_ni(hit,io,req,p) );
  CMD("COMMIT",      stomp_cmd_ni(hit,io,req,p) );
  CMD("ABORT",       stomp_cmd_ni(hit,io,req,p) );
  CMD("NACK",        stomp_got_nack(hit,io,req) );
  /* Commands client would see (sent by server) */
  CMD("CONNECTED",   stomp_cmd_ni(hit,io,req,p) );
  CMD("MESSAGE",     stomp_cmd_ni(hit,io,req,p) );
  CMD("RECEIPT",     stomp_cmd_ni(hit,io,req,p) );
  CMD("ERROR",       return stomp_got_err(hit,io,req) );
  CMD("ZXCTL",       stomp_got_zxctl(hit,io,req) );  /* Custom command */
  } else {
    D("Unknown command(%.*s) ignored.", 4, command);
    stomp_cmd_ni(hit,io,req,p);
  }
  return 0;
}

/*() Parse PDU to extract headers. Typically this is called
 * to recover a persisted PDU, i.e. we can assume to have
 * all the data at hand already. This simplifies error reporting.
 * return:: 0 on success, 1 on error
 * see also:: stomp_decode() is usually used for decoring network traffic */

/* Called by:  zxbus_sched_pending_delivery */
int stomp_parse_pdu(struct hi_pdu* pdu)
{
  char* hdr;
  char* val;
  char* p;

  /* Parse STOMP message */
  
  memset(&pdu->ad.stomp, 0, sizeof(pdu->ad.stomp));
  p = pdu->m;
  hdr = memchr(p, '\n', pdu->ap - p);
  if (!hdr || ++hdr == pdu->ap) {
    pdu->need = MAX(STOMP_MIN_PDU_SIZE, pdu->ap - pdu->m + 2);
    ERR("PDU from file is too small. need=%d have=%d", pdu->need, (int)(pdu->ap - pdu->m));
    return 1;
  }
  p = hdr;
  
  while (!ONE_OF_2(*p,'\n','\r')) {
    hdr = p;
    p = memchr(p, '\n', pdu->ap - p);
    if (!p || ++p == pdu->ap) {
      pdu->need = MAX(STOMP_MIN_PDU_SIZE, pdu->ap - pdu->m + 2);
      ERR("need=%d have=%d", pdu->need, (int)(pdu->ap - pdu->m));
      return 1;
    }
    val = memchr(hdr, ':', p-hdr);
    if (!val) {
      ERR("Malformed PDU from file. Header missing a colon. %p", pdu);
      return 1;
    }
    ++val; /* skip : */
    stomp_parse_header(pdu, hdr, val);
  }

  if (*p == '\r') ++p;
  pdu->ad.stomp.body = ++p;
  
  if (pdu->ad.stomp.len) {
    pdu->need = p - pdu->m + pdu->ad.stomp.len + 1 /* nul */;
    if (pdu->ad.stomp.len < pdu->ap - p) {
      /* Got complete with content-length */
      p += pdu->ad.stomp.len;
      if (*p++) {
	ERR("Malformed PDU from file: No nul to terminate body. %x", p[-1]);
      }
    } else {
      ERR("PDU from file has specified length(%d), but not enough data. need=%d have=%d", pdu->ad.stomp.len, pdu->need, (int)(pdu->ap - pdu->m));
      return 1;
    }
    return 0;
  } else {
    /* Scan until nul */
    while (1) {
      if (pdu->ap - p < 1) {   /* too little, need more */
	pdu->need = pdu->ap - pdu->m + 1;
	ERR("PDU from file without length but too short to have even nul termination. need=%d have=%d", pdu->need, (int)(pdu->ap - pdu->m));
	return 1;
      }
      if (!*p++) {  /* nul termination found */
	pdu->ad.stomp.len = p - pdu->ad.stomp.body - 1;
	pdu->need = p - pdu->m;
	return 0;
      }
    }
  }
  return 0;
}

/* EOF  --  stomp.c */
