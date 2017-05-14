/* aktab.h  -  Application Black (K) Box Reason Table
 *
 * Copyright (c) 2006,2012 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is unpublished proprietary source code. All dissemination
 * prohibited. Contains trade secrets. NO WARRANTY. See file COPYING.
 * Special grant: aktab.h may be used with zxid open source project under
 * same licensing terms as zxid itself.
 *
 * This file has been designed to be included multiple times: once in
 * akbox.h to generate enums and another time to generate cases for
 * switch in akbox.c. At both times some macros need to be defined
 * appropriately.
 *
 * Try to keep this file sorted by reason code to avoid accidental
 * duplication of codes. You can also use
 *    perl -e 'for(<STDIN>){ @a=split /,\s{0,}/; die "DUP $_" if $h{$a[1]}; $h{$a[1]}=$_;}print join "", map $h{$_}, sort keys %h' <extract
 *
 * EDIT THIS FILE TO ADD NEW REASONS.
 */


/* You should define the following macros prior to including this file. */

#if 0
#define AK_RAZ_TS(sym,code,desc)   /* uses TS format */
#define AK_RAZ_TS2(sym,code,desc)  /* uses TS format, but logkey is just a value */
#define AK_RAZ_RUN(sym,code,desc)  /* uses regular RUN format */
#define AK_RAZ_PDU(sym,code,desc)  /* uses regular PDU format */
#define AK_RAZ_PDU2(sym,code,desc) /* uses regular PDU format, but logkey is just a value */
#define AK_RAZ_LITE(sym,code,desc) /* uses light PDU format */
#define AK_RAZ_IO(sym,code,desc)   /* uses IO format */
#define AK_RAZ_MEM(sym,code,desc)  /* uses MEM format */
#define AK_RAZ_REPORT(sym,code,desc)  /* uses REPORT format for memory leak reporting */
#define AK_RAZ_SPEC(sym,code,desc) /* special case, no automatic code generation */
#endif

/* Reason (razon) codes. These should be unique 16 bit numbers. Generally funny sp311 is used
 * to make them more mnemonic (at least to some, for the rest the symbolic name is provided).
 * Some obvious ones
 *
 *   0x10XX  General I/O, I/O shuffler
 *   0xfcXX  Polling and flow control related
 *   0xfeXX  frontend related
 *   0xbeXX  backend related
 *   0xbdXX  PDU (bD0, actually) related
 *   0xc5XX  cond_script related
 *   0xdbXX  debugger related
 *   0x9cXX  garbage collect related
 *   0xa5XX  ASSERT related
 *  (0xc0XX  generic compiler/parser related)
 *  (0x1eXX  lexer related)
 *  (0xccXX  code generation errors)
 *  (0x00XX  generic errors)
 *  (0xdeXX  decoder errors)
 *  (0xecXX  encoder errors)
 *  (0xb3XX  backend marshal errors)
 *  (0x0cXX  hoOK manager errors)
 *  (0xcfXX  configuration errors)
 *  (0xc1XX  command line interface related errors)
 *  (0x7eXX  regular expression related errors)
 *   0x1bXX  API LiBrary and run time related errors
 *   0x33XX  memory alloc errors
 *   0x35XX  Thread pool related
 *   0xd1XX  Disassembly and trace messages
 *   0xf0XX  Fail Over and Load Balancing related
 *
 * There is no need to keep this table in numberic order and its OK to leave gaps.
 * N.B. When these macros are expanded to enums, they are prefixed with AK_ and
 * suffixed with _RAZ, so that no name space problems should arise.  */

AK_RAZ_TS(  TS,          0x0a0a, "plain message just to let you know we're here")
AK_RAZ_INI(  FDINC,      0x0ab0, "Included File")
AK_RAZ_SPEC(ERR,         0x0aef, "err_report()")
AK_RAZ_PDU( ENQ_SUB,     0x0c05, "PDU FULL enqueue sub response, various")
AK_RAZ_PDU( HOPELESS,    0x0c07, "PDU FULL processed by hopeless")
AK_RAZ_PDU( HK_SUBRESP,  0x0c57, "PDU FULL hk_subresp, various")
AK_RAZ_PDU( ABORTED_RESP, 0x0cab, "PDU FULL aborted resp")
AK_RAZ_IO(  INTR,        0x1017, "read was interrupted, in read_decode_call_hooks()")
AK_RAZ_IO(  IO_LOCK,     0x101c, "io_free(), various")
AK_RAZ_IO(  IO_UNLK,     0x101d, "io_free(), various")
AK_RAZ_IO(  BE_LOCK,     0x101e, "cur_BE locked")
AK_RAZ_IO(  BE_UNLK,     0x101f, "cur_BE iunlocked")
AK_RAZ_IO(  BE_CTL,      0x1020, "backend_ctl() was called")
AK_RAZ_IO(  QIO_LOCK,  0x1021, "io_queue_lock")
AK_RAZ_IO(  QIO_UNLK,  0x1022, "io_queue_lock")
AK_RAZ_IO(  ENQ_IO,      0x1030, "IO ENQUEUED in pool")
AK_RAZ_IO(  DEQ_IO,      0x1031, "IO DEQUEUED in pool")
AK_RAZ_IO(  THE_IO,      0x105f, "dump of io ptr, usually related to the previous log entry")
AK_RAZ_IO(  READ,        0x107d, "readreturned something in read_decode_call_hooks() got=%d wanted=%d miss=%d n_more=%d ssl=0x%x")
AK_RAZ_IO(  AGAIN,       0x10a9, "read would have blocked, in read_decode_call_hooks()")
AK_RAZ_IO(  CLEAN_IN_WRITE, 0x10c1, "clean_in_write()")
AK_RAZ_IO(  HALF_DESPERATE, 0x10de, "half close EOF desperate read_decode_call_hooks()")
AK_RAZ_IO(  UDP_EOF,     0x10e0, "UDP EOF in read_decode_call_hooks()")
AK_RAZ_IO(  ZERO_WRITEV, 0x10e1, "writev returned zero in write_from_buffer()")
AK_RAZ_IO(  SSL_EOF,     0x10e5, "SSL EOF in read_decode_call_hooks()")
AK_RAZ_ARG( POLL_EV_EOF, 0x10eb, "handle_poll_event_error()")
AK_RAZ_IO(  TCP_EOF,     0x10ef, "TCP EOF in read_decode_call_hooks()")
AK_RAZ_IO(  IO_FREE,     0x10f7, "io_free(), various")
AK_RAZ_IO(  WR_FRM_BUF,  0x10fb, "write_from_buffer(), various")
AK_RAZ_PDU( DQ_TO_WR,    0x10fc, "dequeue_to_write(), various")
AK_RAZ_IO(  CLOSE_CONN,  0x10ff, "close_connection(), various")
AK_RAZ_TS(  SHUFF_LOCK,  0x151c, "io_free(), various")
AK_RAZ_TS(  SHUFF_UNLOCK,0x151d, "io_free(), various")
AK_RAZ_TS(  RECONN_LOCK,   0x151e, "reconn queue, various")
AK_RAZ_TS(  RECONN_UNLOCK, 0x151f, "reconn queue, various")
AK_RAZ_TS(  RELEASE_LOCK,   0x1520, "release, various")
AK_RAZ_TS(  RELEASE_UNLOCK, 0x1521, "release, various")
AK_RAZ_TS(  EPOLL_LOCK,   0x1522, "win epoll, various")
AK_RAZ_TS(  EPOLL_UNLOCK, 0x1523, "win epoll, various")
AK_RAZ_RUN( RUN_LOCK,    0x1b1c, "run lock")
AK_RAZ_RUN( RUN_UNLOCK,  0x1b1d, "run unlock")
AK_RAZ_RUN( GROW_STACK,  0x1b95, "grow stack")
AK_RAZ_TS(  LEAK,        0x1eac, "TS, memory leaks enabled")
AK_RAZ_ARG( LEAF,        0x1eaf, "PDU LEAF Call from cseval to VM")
AK_RAZ_MEM( MALLOC_FAIL, 0x3301, "nonfatal eager malloc failure, will try again")
AK_RAZ_MEM( MEM_NOHEAD,  0x3303, "Head pointer missing, resorting to malloc")
AK_RAZ_MEM( MEM_NOPOOL,  0x3305, "No pool associated with mem, resorting to malloc")
AK_RAZ_MEM( MEM_FRM_MALLOC,0x330a, "Desperately seeking memory from malloc")
AK_RAZ_MEM( MEM_FRM_POOL,0x330b, "Memory from pool")
AK_RAZ_MEM( NULL_FREE,   0x330f, "freeing of NULL pointer")
AK_RAZ_MEM( MEM_LOCK,    0x331c, "mem pool lock")
AK_RAZ_MEM( MEM_UNLK,    0x331d, "mem pool unlock")
AK_RAZ_REPORT(MEM_REPORT,0x3337, "memory leak report, from shuffler main loop")
AK_RAZ_MEM( MALLOC,      0x333a, "eager malloc succeed")
AK_RAZ_MEM( MEM_REL,     0x3377, "release memory to pool")
AK_RAZ_MEM( MEM_FREE,    0x33f7, "freeing of malloc'd pointer")
AK_RAZ_TSA( THR_POOL_LOCK,    0x351c, "thread pool lock")
AK_RAZ_TSA( THR_POOL_UNLOCK,  0x351d, "thread pool unlock")
AK_RAZ_TSA( FD_POOL_LOCK,    0x351e, "fd pool lock")
AK_RAZ_TSA( FD_POOL_UNLOCK,  0x351f, "fd pool unlock")
AK_RAZ_TSA( SUPER_POOL_LOCK,    0x3520, "super pool lock")
AK_RAZ_TSA( SUPER_POOL_UNLOCK,  0x3521, "super pool unlock")
AK_RAZ_TS(  THR_REPORT,  0x3537, "thread pool report, from shuffler main loop")
AK_RAZ_PDU( THR_POOL_CANCEL,  0x35ca, "thread pool cancellation clean up")
AK_RAZ_PDU( SCHED_LK,    0x5ced, "PDU full, sched_pdu_to_write_lock")
AK_RAZ_PDU( SCHED_NOLK,  0x5cee, "PDU full, sched_pdu_to_write_nolock")
AK_RAZ_TS(  GC_START,    0x9c57, "TS garbage collection start")
AK_RAZ_TS(  GC_END,      0x9ced, "TS garbage collection end")
AK_RAZ_TS(  GC_UNSAFE,   0x9cff, "TS garbage collection unsafe VAL_VAL_REF")
AK_RAZ_SPEC(ASSERTOP,    0xa507, "ASSERTOP macro, logkey is value a, msg is condition")
AK_RAZ_TS(  SANITY,      0xa55a, "Sanity check failed. Not quite an assert, but something is weird.")
AK_RAZ_SPEC(ASSERT,      0xa5e7, "ASSERT or CHK macro, logkey is condition")
AK_RAZ_SPEC(FAIL,        0xa5fa, "FAIL macro logkey: val (e.g. failed magic), msg: why")
AK_RAZ_SPEC(FAILS,       0xa5fb, "FAILS macro logkey: val (e.g. function name), msg: why")
AK_RAZ_TS(  ASSERT_NONFATAL,0xa5ff, "TS, assert nonfatal enabled")
AK_RAZ_PDU( INLINE_ABORT,0xab01, "HOOK_INLINE_ABORT happened")
AK_RAZ_PDU( ABORT_RESP,  0xab03, "PDU FULL aborted resp (resp returned PDU_DONE)")
AK_RAZ_IO(  ACCEPT,      0xacce, "accept a new connection from socket")
AK_RAZ_PDU( ORPHAN_RESPS,0xb307, "PDU FULL abandon request and orphan all responses to it")
AK_RAZ_ARG( ORPHAN_IGN,  0xb319, "PDU lite orphan abandon ignored, arg is message ID")
AK_RAZ_LITE(RES_BIND,    0xb337, "PDU lite bind response seen, ldap_marshal_map_resp_to_req()")
AK_RAZ_LITE(REAUTH_BIND, 0xb339, "PDU lite reauth bind sent")
AK_RAZ_LITE(RESCHED,     0xb375, "PDU lite resched traffic to be")
AK_RAZ_IO(  RESCHED_BE,  0xb376, "IO resched traffic to be")
AK_RAZ_IO(  REALLOC_OUTSTANDING,  0xb37e, "IO reallocated outstanding table")
AK_RAZ_LITE(REENC_OK,    0xb3ec, "PDU lite re-encode successful")
AK_RAZ_LITE(PDU_LITE,    0xbd00, "PDU Lite dump")
AK_RAZ_PDU( PDU,         0xbd01, "PDU dump")
AK_RAZ_PDU( REQ,         0xbd03, "dump of pdu->req neighbour")
AK_RAZ_PDU( PARENT,      0xbd05, "dump of pdu->parent neighbour")
AK_RAZ_PDU( NEXT,        0xbd07, "g.pdunext exists and is not a guard")
AK_RAZ_SPEC(NEXT_GUARD,  0xbd08, "g.pdunext exists but is a guard")
AK_RAZ_PDU( PREV,        0xbd09, "g.pduprev exists and is not a guard")
AK_RAZ_SPEC(PREV_GUARD,  0xbd0a, "g.pduprev exists but is a guard")
AK_RAZ_PDU( WRITENEXT,   0xbd0b, "g.writenext")
AK_RAZ_PDU( REQ_HEAD,    0xbd0c, "req_head of a frontend exists")
AK_RAZ_PDU( REQ_TAIL,    0xbd0d, "req_tail of a frontend exists")
AK_RAZ_PDU( PDU_FULL,    0xbd0f, "PDU dump followed by dumps of immediate neighbours")
AK_RAZ_PDU( ONE_MORE,    0xbd13, "PDU one more")
AK_RAZ_PDU( PDU_INVOKE,  0xbd1b, "PDU FULL invoked cs, sending PDU to thread")
AK_RAZ_PDU( PDU_LOCK,    0xbd1c, "Grab PDU lock")
AK_RAZ_PDU( PDU_UNLK,    0xbd1d, "Let go of PDU lock")
AK_RAZ_PDU( IOV_FULL,    0xbd1f, "PDU iov_full")
AK_RAZ_LITE(PDU_CTL,     0xbd20, "pdu_ctl() was called")
AK_RAZ_LITE(DECODE_OK,   0xbd33, "PDU decode successful")
AK_RAZ_PDU( SUSPEND,     0xbd53, "PDU FULL Parent entering suspended state")
AK_RAZ_PDU( SUBREQ,      0xbd57, "PDU FULL send_any_subrequest()")
AK_RAZ_PDU( DROP,        0xbd5d, "PDU FULL Script requested dropping connection")
AK_RAZ_PDU( PDU_THROTTLED,0xbd70,"PDU was throttled")
AK_RAZ_PDU( SYNTH_RESP,  0xbd77, "PDU FULL send_any_resp()")
AK_RAZ_PDU( RAISE_XCPT_PDU, 0xbd7f, "raise_xcpt_walk_pdu()")
AK_RAZ_LITE(NEW_BUF,     0xbd80, "new_buf_nolock")
AK_RAZ_LITE(NEW_BUF_LK,  0xbd81, "new_buf_lock")
AK_RAZ_PDU( FREE_BUF,    0xbd82, "free_buf_nolock")
AK_RAZ_PDU( FREE_BUF_LK, 0xbd83, "free_buf_lock")
AK_RAZ_PDU( UNLINK,      0xbd84, "unlink_pdu_may_lock_req(), various")
AK_RAZ_PDU( FREE_WALK,   0xbd85, "PDU free_walk(), various")
AK_RAZ_PDU( TRY_REL,     0xbd86, "PDU try_release_pdu(), various")
AK_RAZ_PDU( TRY_REL_NOT_RDY,  0xbd87, "PDU try_release_pdu() dependent PDU not ready, various")
AK_RAZ_PDU( TRY_REL_DISSOCIATE,  0xbd89, "PDU try_release_pdu() dissociate dependent response from request, various")
AK_RAZ_PDU( MV_TO_FREEABLE, 0xbd8a, "PDU mv_to_freeable()")
AK_RAZ_PDU( NEW_OWNER,   0xbd8b, "PDU mv_to_freeable() new_owner")
AK_RAZ_PDU( TRY_REL_REQ_ET_PEND_DONE, 0xbd8c, "PDU try_release_req_and_pending_done()")
AK_RAZ_PDU( CLEAN_PDU,   0xbd8d, "PDU FULL clean_pdu, various")
AK_RAZ_PDU( RM_FRM_Q,    0xbd8e, "PDU FULL clean_pdu, various")
AK_RAZ_PDU( YANK,        0xbd8f, "PDU FULL clean_pdu, various")
AK_RAZ_PDU( TRY_REM,     0xbd90, "PDU try_remove_pdu(), various")
AK_RAZ_PDU( PEND_DONE,   0xbdbd, "pending done")
AK_RAZ_LITE(CONTENT_LEN, 0xbdc1, "Content length manipulations, various")
AK_RAZ_PDU( DONE,        0xbdd0, "PDU FULL pdu done")
AK_RAZ_PDU( WAKEUP,      0xbdd1, "PDU wake up suspended parent")
AK_RAZ_PDU( WOKEUP,      0xbdd2, "PDU FULL wokeup suspended parent")
AK_RAZ_PDU( WAIT_ON,     0xbdd3, "PDU FULL nn_wait() on this PDU")
AK_RAZ_PDU( WAIT_RET,    0xbdd5, "PDU FULL nn_wait() will return this PDU")
AK_RAZ_LITE(WAIT_ERR,    0xbdde, "PDU lite, nn_wait() error decoding retry")
AK_RAZ_LITE(WAIT_LAST,   0xbddf, "PDU lite, nn_wait() returns undef")
AK_RAZ_TS(  NEXT_HK_SUBRESP,0xbde5, "TS, hk_process() next hook and bubbled up processing")
AK_RAZ_LITE(PDU_ENQ,     0xbde9, "PDU was enqueued to thread queue")
AK_RAZ_PDU( HK_PROCESS,  0xbdec, "PDU, hk_process() starting")
AK_RAZ_PDU( NEXT_HK,     0xbded, "PDU, hk_process() next hook and bubbled up processing")
AK_RAZ_PDU2(ERR_PDU,     0xbdee, "PDU, error involving PDU")
AK_RAZ_IO(  OPEN_BE,     0xbe0b, "open_be() succeeded port=%d proto=%d ssl_ctx=0x%x udp=%d")
AK_RAZ_IO(  BE_HALF_CLOSE, 0xbe12, "BE HALF CLOSE")
AK_RAZ_IO(  BE,          0xbe51, "dump of a pdu->be pointer (or otherwise assumed backend)")
AK_RAZ_PDU( BE_SETUP,    0xbe5e, "PDU be_setup_call_hooks")
AK_RAZ_PDU( THROTTLE_BE, 0xbe70, "PDU throttle backend")
AK_RAZ_IO(  BE_CLEAN,    0xbe7d, "try_clean, various phases")
AK_RAZ_IO(  RECONN,      0xbe7e, "try_reconnect, various phases")
AK_RAZ_IO(  BE_ELIM,     0xbe7f, "try_eliminate, various phases")
AK_RAZ_PDU( BE_POP,      0xbeb0, "PDU FULL be_populate_in_write()")
AK_RAZ_PDU( INWRITE_POSTPONE, 0xbebb, "PDU be_populate_in_write() postponed towrite to inwrite move due to reauth_outstanding")
AK_RAZ_PDU( CHOOSE_BE,   0xbec0, "various backend choosing activities")
AK_RAZ_PDU( ADD_TO_WR,   0xbec1, "add_pdu_to_write() - Major gateway in PDU processing")
AK_RAZ_IO(  HTTP_NO_CONTENT_LENGTH,0xbecc , "Triggered special case where HTTP response didn't have Content-Length header and we need to detect the length from connection close. Completing pdu.")
AK_RAZ_LITE(CS_SKIP_CLI_IP,  0xc551, "PDU LITE skipped by cs due to client IP")
AK_RAZ_LITE(CS_SKIP_SUFFIX,  0xc555, "PDU LITE skipped by cs due to suffix")
AK_RAZ_LITE(SET_SG,          0xc559, "PDU LITE set server group")
AK_RAZ_LITE(SET_ATTR,        0xc55a, "PDU LITE set attr")
AK_RAZ_LITE(CS_SKIP_BIND_DN, 0xc55b, "PDU LITE skipped by cs due to bind dn")
AK_RAZ_LITE(CS_ACCEPT,       0xc5ac, "PDU LITE accepted by cs")
AK_RAZ_PDU( AVOID_DEAD,      0xc5de, "PDU FULL avoided script execution on dead session")
AK_RAZ_LITE(CS_REJECT,       0xc5ff, "PDU LITE rejected by cs")
AK_RAZ_SPEC(TRACE_VMENTRY,   0xd110, "Trace condition processing and VM entry and exit")
AK_RAZ_SPEC(TRACE_CALL,      0xd121, "Function call trace")
AK_RAZ_SPEC(TRACE_RET,       0xd123, "Function return trace")
AK_RAZ_SPEC(TRACE_NATCALL,   0xd131, "Natcall trace")
AK_RAZ_SPEC(TRACE_NATRET,    0xd133, "Natcall return trace")
AK_RAZ_SPEC(TRACE,           0xd104, "Instruction execution trace (i.e. disassembly)")
AK_RAZ_TS(  DEBUG_INTR,  0xdb13, "TS C-c interrupt from debugging connection")
AK_RAZ_TS(  DEBUG_LISTEN,0xdb57, "TS, -bug debug listen")
AK_RAZ_TS(  DEBUG_ACCEPT,0xdbac, "TS")
AK_RAZ_TS(  DEBUG_CLOSE, 0xdbc7, "TS debugging connection closed, EOF seen")
AK_RAZ_PDU( HTTP_DECODE_PDU, 0xdc06, "HTTP decode pdu successful")
AK_RAZ_LITE(HTTP_RESP,   0xdc07, "HTTP response")
AK_RAZ_IO(  HTTP_DECODE, 0xdc08, "HTTP decode, various")
AK_RAZ_LITE(HTTP_REQ,    0xdc09, "HTTP request")
AK_RAZ_IO(  HALFCLOSE_LINGER, 0xdc12, "Half close linger, trimmed content length")
AK_RAZ_LITE(LDAP_DECODE, 0xdc1d, "LDAP decoder, various")
AK_RAZ_LITE(LDAP_TRAILING, 0xdc1e, "LDAP decoder, trailing noise moved to one_more_pdu")
AK_RAZ_LITE(LDAP_TOO_SMALL_BUF, 0xdc1f, "LDAP decoder, too small buf, realloc: noise_free=%d, missing=%d len_pdu=%d prelen=%d")
AK_RAZ_PDU (MM1_DECODE_PDU, 0xdc20, "MM1 decode pdu successful")
AK_RAZ_PDU (MM1_ENCODE_PDU, 0xdc21, "MM1 encode pdu successful")
AK_RAZ_TS(  SG_LOCK,      0xf01c, "various")
AK_RAZ_TS(  SG_UNLOCK,    0xf01d, "various")
AK_RAZ_TS(  SERV_LOCK,    0xf01e, "various")
AK_RAZ_TS(  SERV_UNLOCK,  0xf01f, "various")
AK_RAZ_LITE(LDAP_ENCODE,  0xec1d, "LDAP encoder, various")
AK_RAZ_ARG( FULL,         0xf011, "PDU FULL Call from cseval to ?")

AK_RAZ_IO(  SSL_POLL_OK,  0xfc5b, "SSL poll OK in process_poll_events()")
AK_RAZ_IO(  POP_POLL_NO,  0xfcb0, "Polled infavorably in populate_poll()")
AK_RAZ_IO(  POP_POLL_YES, 0xfcb1, "Polled favorably in populate_poll()")
AK_RAZ_IO(  TOO_BIG_N_POLL,0xfcb2, "Too big n_poll value in shuffler main loop")
AK_RAZ_IO(  EAGAIN_POLL,  0xfcb3, "fd added to poll due to EAGAIN in write")
AK_RAZ_TS(  POLL_FAIL,    0xfcb4, "epoll ioctl failed")
AK_RAZ_TS(  POLL_OK,      0xfcb5, "epoll ioctl ok")

AK_RAZ_PDU( DEAD_FE_JUNK, 0xfe10, "PDU FULL dead frontend junking PDU")
AK_RAZ_IO(  FE,           0xfe51, "dump of a pdu->fe pointer (or otherwise assumed frontend)")
AK_RAZ_PDU( THROTTLE_FE,  0xfe70, "PDU throttle frontend")
AK_RAZ_IO(  TRY_TERM,     0xfe77, "try_term(), various")
AK_RAZ_IO(  RAISE_XCPT_IO,0xfe7f, "raise_xcpt_walk()")
AK_RAZ_PDU( FE_POP,       0xfeb0, "PDU FULL fe_populate_in_write()")
AK_RAZ_LITE(FE_POP2,      0xfeb2, "PDU lite fe_populate_in_write(), various")
AK_RAZ_IO(  MARK_FOR_TERM,0xfec1, "mark_for_term(), various")

/* aktab.h */
