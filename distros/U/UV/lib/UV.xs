#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <assert.h>
#include <stdlib.h>

#include <uv.h>

#if defined(DEBUG) && DEBUG > 0
 #define DEBUG_PRINT(fmt, args...) fprintf(stderr, "C -- %s:%d:%s(): " fmt, \
    __FILE__, __LINE__, __func__, ##args)
#else
 #define DEBUG_PRINT(fmt, args...) /* Don't do anything in release builds */
#endif

#include "perl-backcompat.h"
#include "uv-backcompat.h"

#ifdef MULTIPLICITY
#  define storeTHX(var)  (var) = aTHX
#  define dTHXfield(var) tTHX var;
#else
#  define storeTHX(var)  dNOOP
#  define dTHXfield(var)
#endif

#if defined(__MINGW32__) || defined(WIN32)
#  define HAVE_MSWIN32
#  include <io.h> /* we need _get_osfhandle() on windows */
#  define _MAKE_SOCK(f) (_get_osfhandle(f))
#else
#  define _MAKE_SOCK(f) (f)
#endif

#ifdef AI_V4MAPPED
#  define DEFAULT_AI_FLAGS  (AI_V4MAPPED|AI_ADDRCONFIG)
#else
#  define DEFAULT_AI_FLAGS  (AI_ADDRCONFIG)
#endif

#define do_callback_accessor(var, cb) MY_do_callback_accessor(aTHX_ var, cb)
static SV *MY_do_callback_accessor(pTHX_ SV **var, SV *cb)
{
    if(cb && SvOK(cb)) {
        SvREFCNT_dec(*var);

        *var = newSVsv(cb);
    }

    if(*var && SvOK(*var))
        return SvREFCNT_inc(*var);
    else
        return &PL_sv_undef;
}

#define newSV_error(err)  MY_newSV_error(aTHX_ err)
static SV *MY_newSV_error(pTHX_ int err)
{
    SV *sv = newSVpv(err ? uv_strerror(err) : "", 0);
    sv_upgrade(sv, SVt_PVIV);
    SvIV_set(sv, err);
    SvIOK_on(sv);

    return sv;
}

static HV *make_errstash(pTHX_ int err)
{
    /* Technically a memory leak within libuv if err is unknown; we should
     * consider using uv_err_name_r()
     */
    SV *name = newSVpvf("UV::Exception::%s::", uv_err_name(err));
    sv_2mortal(name);

    HV *stash = get_hv(SvPVX(name), 0);
    if(stash) return stash;

    stash = get_hv(SvPVX(name), GV_ADD);

    /* push @ISA, "UV::Exception" */
    sv_catpvs(name, "ISA");
    av_push(get_av(SvPVX(name), GV_ADD), newSVpvs_share("UV::Exception"));

    return stash;
}

#define THROWERRSV(sv, err)                                               \
    do {                                                                  \
        SV *msgsv = mess_sv(sv, TRUE);                                    \
        sv_upgrade(msgsv, SVt_PVIV);                                      \
        SvIV_set(msgsv, err); SvIOK_on(msgsv);                            \
        croak_sv(sv_bless(newRV_noinc(msgsv), make_errstash(aTHX_ err))); \
    } while(0)

#define THROWERR(message, err)                                            \
    THROWERRSV(newSVpvf(message " (%d): %s", err, uv_strerror(err)), err)

#ifdef HEKf
#  define CHECKCALL(call)                                \
  do {                                                   \
    int err = call;                                      \
    if(err != 0)                                         \
      THROWERRSV(newSVpvf("Couldn't %" HEKf " (%d): %s", \
        HEKfARG(GvNAME_HEK(CvGV(cv))),                   \
        err, uv_strerror(err)), err);                    \
  } while(0)
#else
#  define CHECKCALL(call)                                \
  do {                                                   \
    int err = call;                                      \
    if(err != 0)                                         \
      THROWERRSV(newSVpvf("Couldn't %s (%d): %s",        \
        GvNAME(CvGV(cv)),                                \
        err, uv_strerror(err)), err);                    \
  } while(0)
#endif

/**************
 * UV::Handle *
 **************/

#define FIELDS_UV__Handle     \
    SV *selfrv;               \
    dTHXfield(perl)           \
    SV *data;                 \
    SV *on_close;             \
    bool destroy_after_close;

typedef struct UV__Handle {
    uv_handle_t *h;
    FIELDS_UV__Handle
} *UV__Handle;

#define NEW_UV__Handle(var, type) \
    Newxc(var, sizeof(*var) + sizeof(type), char, void); \
    var->h = (type *)((char *)var + sizeof(*var));

#define INIT_UV__Handle(handle)  {      \
  handle->h->data = handle;             \
  storeTHX(handle->perl);               \
  handle->data     = NULL;              \
  handle->on_close = NULL;              \
  handle->destroy_after_close = FALSE;  \
}

static void destroy_handle(UV__Handle self);
static void destroy_handle_base(pTHX_ UV__Handle self)
{
    SvREFCNT_dec(self->data);
    SvREFCNT_dec(self->on_close);

    /* No need to destroy self->selfrv because Perl is already destroying
     * it, being the reason we are invoked in the first place
     */

    Safefree(self);
}

static void on_alloc_cb(uv_handle_t *handle, size_t suggested, uv_buf_t *buf)
{
    Newx(buf->base, suggested, char);
    buf->len = suggested;
}

static void on_close_cb(uv_handle_t *handle)
{
    UV__Handle  self;
    SV         *cb;

    if(!handle || !handle->data) return;

    self = handle->data;

    if((cb = self->on_close) && SvOK(cb)) {
        dTHXa(self->perl);
        dSP;
        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        EXTEND(SP, 1);
        mPUSHs(newRV_inc(self->selfrv));
        PUTBACK;

        call_sv(cb, G_DISCARD|G_VOID);

        FREETMPS;
        LEAVE;
    }

    if(self->destroy_after_close)
        destroy_handle(handle->data);
}

/**************
 * UV::Stream *
 **************/

#define FIELDS_UV__Stream \
    SV *on_read;          \
    SV *on_connection;

#define INIT_UV__Stream(stream)  { \
    stream->on_read = NULL;        \
    stream->on_connection = NULL;  \
}

typedef struct UV__Stream {
    uv_stream_t *h;
    FIELDS_UV__Handle
    FIELDS_UV__Stream
} *UV__Stream;

static void destroy_stream(pTHX_ UV__Stream self)
{
    SvREFCNT_dec(self->on_read);
    SvREFCNT_dec(self->on_connection);
}

static void on_read_cb(uv_stream_t *stream, ssize_t nread, const uv_buf_t *buf)
{
    UV__Stream self;
    SV         *cb;

    if(!stream || !stream->data) return;

    self = stream->data;
    if((cb = self->on_read) && SvOK(cb)) {
        dTHXa(self->perl);
        dSP;
        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        EXTEND(SP, 3);
        mPUSHs(newRV_inc(self->selfrv));
        mPUSHs(nread < 0 ? newSV_error(nread) : &PL_sv_undef);
        if(nread >= 0)
            mPUSHp(buf->base, nread);
        PUTBACK;

        call_sv(cb, G_DISCARD|G_VOID);

        FREETMPS;
        LEAVE;
    }

    if(buf && buf->base)
        Safefree(buf->base);
}

static void on_connection_cb(uv_stream_t *stream, int status)
{
    UV__Stream self;
    SV         *cb;

    if(!stream || !stream->data) return;

    self = stream->data;
    if(!(cb = self->on_connection) || !SvOK(cb)) return;

    dTHXa(self->perl);
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 2);
    mPUSHs(newRV_inc(self->selfrv));
    mPUSHi(status);
    PUTBACK;

    call_sv(cb, G_DISCARD|G_VOID);

    FREETMPS;
    LEAVE;
}

/*************
 * UV::Async *
 *************/

typedef struct UV__Async {
    uv_async_t *h;
    FIELDS_UV__Handle
    SV         *on_async;
} *UV__Async;

static void destroy_async(pTHX_ UV__Async self)
{
    SvREFCNT_dec(self->on_async);
}

static void on_async_cb(uv_async_t *async)
{
    UV__Async self;
    SV        *cb;

    if(!async || !async->data) return;

    self = async->data;
    if(!(cb = self->on_async) || !SvOK(cb)) return;

    dTHXa(self->perl);
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    mPUSHs(newRV_inc(self->selfrv));
    PUTBACK;

    call_sv(cb, G_DISCARD|G_VOID);

    FREETMPS;
    LEAVE;
}

/*************
 * UV::Check *
 *************/

/* See also http://docs.libuv.org/en/v1.x/check.html */

typedef struct UV__Check {
    uv_check_t *h;
    FIELDS_UV__Handle
    SV         *on_check;
} *UV__Check;

static void destroy_check(pTHX_ UV__Check self)
{
    SvREFCNT_dec(self->on_check);
}

static void on_check_cb(uv_check_t *check)
{
    UV__Check  self;
    SV        *cb;

    if(!check || !check->data) return;

    self = check->data;
    if(!(cb = self->on_check) || !SvOK(cb)) return;

    dTHXa(self->perl);
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    mPUSHs(newRV_inc(self->selfrv));
    PUTBACK;

    call_sv(cb, G_DISCARD|G_VOID);

    FREETMPS;
    LEAVE;
}

/************
 * UV::Idle *
 ************/

/* See also http://docs.libuv.org/en/v1.x/idle.html */

typedef struct UV__Idle {
    uv_idle_t *h;
    FIELDS_UV__Handle
    SV        *on_idle;
} *UV__Idle;

static void destroy_idle(pTHX_ UV__Idle self)
{
    SvREFCNT_dec(self->on_idle);
}

static void on_idle_cb(uv_idle_t *idle)
{
    UV__Idle self;
    SV       *cb;

    if(!idle || !idle->data) return;

    self = idle->data;
    if(!(cb = self->on_idle) || !SvOK(cb)) return;

    dTHXa(self->perl);
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    mPUSHs(newRV_inc(self->selfrv));
    PUTBACK;

    call_sv(cb, G_DISCARD|G_VOID);

    FREETMPS;
    LEAVE;
}

/************
 * UV::Pipe *
 ************/

/* See also http://docs.libuv.org/en/v1.x/pipe.html */

typedef struct UV__Pipe {
    uv_pipe_t *h;
    FIELDS_UV__Handle
    FIELDS_UV__Stream
} *UV__Pipe;

static void destroy_pipe(pTHX_ UV__Pipe self)
{
    destroy_stream(aTHX_ (UV__Stream)self);
}

/************
 * UV::Poll *
 ************/

/* See also http://docs.libuv.org/en/v1.x/poll.html */

typedef struct UV__Poll {
    uv_poll_t *h;
    FIELDS_UV__Handle
    SV        *on_poll;
} *UV__Poll;

static void destroy_poll(pTHX_ UV__Poll self)
{
    SvREFCNT_dec(self->on_poll);
}

static void on_poll_cb(uv_poll_t *poll, int status, int events)
{
    UV__Poll self;
    SV       *cb;

    if(!poll || !poll->data) return;

    self = poll->data;
    if(!(cb = self->on_poll) || !SvOK(cb)) return;

    dTHXa(self->perl);
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 3);
    mPUSHs(newRV_inc(self->selfrv));
    mPUSHi(status);
    mPUSHi(events);
    PUTBACK;

    call_sv(cb, G_DISCARD|G_VOID);

    FREETMPS;
    LEAVE;
}

/***************
 * UV::Prepare *
 ***************/

/* See also http://docs.libuv.org/en/v1.x/prepare.html */

typedef struct UV__Prepare {
    uv_prepare_t *h;
    FIELDS_UV__Handle
    SV           *on_prepare;
} *UV__Prepare;

static void destroy_prepare(pTHX_ UV__Prepare self)
{
    SvREFCNT_dec(self->on_prepare);
}

static void on_prepare_cb(uv_prepare_t *prepare)
{
    UV__Prepare  self;
    SV          *cb;

    if(!prepare || !prepare->data) return;

    self = prepare->data;
    if(!(cb = self->on_prepare) || !SvOK(cb)) return;

    dTHXa(self->perl);
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    mPUSHs(newRV_inc(self->selfrv));
    PUTBACK;

    call_sv(cb, G_DISCARD|G_VOID);

    FREETMPS;
    LEAVE;
}

/* See also http://docs.libuv.org/en/v1.x/process.html */

typedef struct UV__Process {
    uv_process_t *h;
    FIELDS_UV__Handle
    SV           *on_exit;

    /* fields for spawn */
    uv_loop_t *loop;
    uv_process_options_t options;
} *UV__Process;

static void on_exit_cb(uv_process_t *process, int64_t exit_status, int term_signal)
{
    UV__Process self;
    SV          *cb;

    if(!process || !process->data) return;

    self = process->data;
    if(!(cb = self->on_exit) || !SvOK(cb)) return;

    dTHXa(self->perl);
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 3);
    mPUSHs(newRV_inc(self->selfrv));
    mPUSHi(exit_status);
    mPUSHi(term_signal);
    PUTBACK;

    call_sv(cb, G_DISCARD|G_VOID);

    FREETMPS;
    LEAVE;
}

/**************
 * UV::Signal *
 **************/

/* See also http://docs.libuv.org/en/v1.x/signal.html */

typedef struct UV__Signal {
    uv_signal_t *h;
    FIELDS_UV__Handle
    int          signum;
    SV          *on_signal;
} *UV__Signal;

static void destroy_signal(pTHX_ UV__Signal self)
{
    SvREFCNT_dec(self->on_signal);
}

static void on_signal_cb(uv_signal_t *signal, int signum)
{
    UV__Signal self;
    SV         *cb;

    if(!signal || !signal->data) return;

    self = signal->data;
    if(!(cb = self->on_signal) || !SvOK(cb)) return;

    dTHXa(self->perl);
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 2);
    mPUSHs(newRV_inc(self->selfrv));
    mPUSHi(signum);
    PUTBACK;

    call_sv(cb, G_DISCARD|G_VOID);

    FREETMPS;
    LEAVE;
}

/*************
 * UV::Timer *
 *************/

/* See also http://docs.libuv.org/en/v1.x/timer.html */

typedef struct UV__Timer {
    uv_timer_t *h;
    FIELDS_UV__Handle
    SV         *on_timer;
} *UV__Timer;

static void destroy_timer(pTHX_ UV__Timer self)
{
    SvREFCNT_dec(self->on_timer);
}

static void on_timer_cb(uv_timer_t *timer)
{
    UV__Timer  self;
    SV        *cb;

    if(!timer || !timer->data) return;

    self = timer->data;
    if(!(cb = self->on_timer) || !SvOK(cb)) return;

    dTHXa(self->perl);
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    mPUSHs(newRV_inc(self->selfrv));
    PUTBACK;

    call_sv(cb, G_DISCARD|G_VOID);

    FREETMPS;
    LEAVE;
}

/***********
 * UV::TCP *
 ***********/

/* See also http://docs.libuv.org/en/v1.x/tcp.html */

typedef struct UV__TCP {
    uv_tcp_t *h;
    FIELDS_UV__Handle;
    FIELDS_UV__Stream;
} *UV__TCP;

static void destroy_tcp(pTHX_ UV__TCP self)
{
    destroy_stream(aTHX_ (UV__Stream)self);
}

/***********
 * UV::TTY *
 ***********/

/* See also http://docs.libuv.org/en/v1.x/tty.html */

typedef struct UV__TTY {
    uv_tty_t *h;
    FIELDS_UV__Handle
    FIELDS_UV__Stream
} *UV__TTY;

static void destroy_tty(pTHX_ UV__TTY self)
{
    destroy_stream(aTHX_ (UV__Stream)self);
}

/***********
 * UV::UDP *
 ***********/

/* See also http://docs.libuv.org/en/v1.x/udp.html */

typedef struct UV__UDP {
    uv_udp_t *h;
    FIELDS_UV__Handle
    SV       *on_recv;
} *UV__UDP;

static void destroy_udp(pTHX_ UV__UDP self)
{
    SvREFCNT_dec(self->on_recv);
}

static void on_recv_cb(uv_udp_t *udp, ssize_t nread, const uv_buf_t *buf, const struct sockaddr *addr, unsigned flags)
{
    UV__UDP self;
    SV      *cb;

    if(!udp || !udp->data) return;

    self = udp->data;
    if((cb = self->on_recv) && SvOK(cb)) {
        size_t addrlen = 0;
        dTHXa(self->perl);
        dSP;

        /* libuv doesn't give us the length of addr; we'll have to guess */
        switch(((struct sockaddr_storage *)addr)->ss_family) {
            case AF_INET:  addrlen = sizeof(struct sockaddr_in);  break;
            case AF_INET6: addrlen = sizeof(struct sockaddr_in6); break;
        }

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        EXTEND(SP, 5);
        mPUSHs(newRV_inc(self->selfrv));
        mPUSHs(nread < 0 ? newSV_error(nread) : &PL_sv_undef);
        if(nread >= 0)
            mPUSHp(buf->base, nread);
        else
            PUSHs(&PL_sv_undef);
        mPUSHp((char *)addr, addrlen);
        mPUSHi(flags);
        PUTBACK;

        call_sv(cb, G_DISCARD|G_VOID);

        FREETMPS;
        LEAVE;
    }

    if(buf && buf->base)
        Safefree(buf->base);
}

/* Handle destructor has to be able to see the type-specific destroy_
 * functions above, so must be last
 */

static void destroy_handle(UV__Handle self)
{
    dTHXa(self->perl);

    uv_handle_t *handle = self->h;
    switch(handle->type) {
        case UV_ASYNC:   destroy_async  (aTHX_ (UV__Async)  self); break;
        case UV_CHECK:   destroy_check  (aTHX_ (UV__Check)  self); break;
        case UV_IDLE:    destroy_idle   (aTHX_ (UV__Idle)   self); break;
        case UV_NAMED_PIPE:
                         destroy_pipe   (aTHX_ (UV__Pipe)   self); break;
        case UV_POLL:    destroy_poll   (aTHX_ (UV__Poll)   self); break;
        case UV_PREPARE: destroy_prepare(aTHX_ (UV__Prepare)self); break;
        case UV_SIGNAL:  destroy_signal (aTHX_ (UV__Signal) self); break;
        case UV_TCP:     destroy_tcp    (aTHX_ (UV__TCP)    self); break;
        case UV_TIMER:   destroy_timer  (aTHX_ (UV__Timer)  self); break;
        case UV_TTY:     destroy_tty    (aTHX_ (UV__TTY)    self); break;
        case UV_UDP:     destroy_udp    (aTHX_ (UV__UDP)    self); break;
    }

    destroy_handle_base(aTHX_ self);
}

/***********
 * UV::Req *
 ***********/

#define FIELDS_UV__Req \
    SV *selfrv;        \
    dTHXfield(perl)    \
    SV *cb;

typedef struct UV__Req {
    uv_req_t *r;
    FIELDS_UV__Req
} *UV__Req;

#define NEW_UV__Req(var, type) \
    Newxc(var, sizeof(*var) + sizeof(type), char, void); \
    var->r = (type *)((char *)var + sizeof(*var));

#define INIT_UV__Req(req)  { \
    req->r->data = req;      \
    storeTHX(req->perl);     \
}

static void on_req_cb(uv_req_t *_req, int status)
{
    UV__Req req = _req->data;
    dTHXa(req->perl);

    if(req->cb) {
        dSP;
        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        EXTEND(SP, 1);
        mPUSHs(newSV_error(status));
        PUTBACK;

        call_sv(req->cb, G_DISCARD|G_VOID);

        FREETMPS;
        LEAVE;
    }

    SvREFCNT_dec(req->selfrv);
}

/* Simple UV::Req subtypes that just invoke a callback with status */

typedef struct UV__Req_connect {
    uv_connect_t *r;
    FIELDS_UV__Req
} *UV__Req_connect;

typedef struct UV__Req_shutdown {
    uv_shutdown_t *r;
    FIELDS_UV__Req
} *UV__Req_shutdown;

typedef struct UV__Req_udp_send {
    uv_udp_send_t *r;
    FIELDS_UV__Req
    char       *s;
} *UV__Req_udp_send;

typedef struct UV__Req_write {
    uv_write_t *r;
    FIELDS_UV__Req
    char       *s;
} *UV__Req_write;

/* See also http://docs.libuv.org/en/v1.x/dns.html#c.uv_getaddrinfo */

typedef struct UV__Req_getaddrinfo {
    uv_getaddrinfo_t *r;
    FIELDS_UV__Req
} *UV__Req_getaddrinfo;

typedef struct UV__getaddrinfo_result {
    int              family;
    int              socktype;
    int              protocol;
    socklen_t        addrlen;
    struct sockaddr *addr;
    char            *canonname;
} *UV__getaddrinfo_result;

static void on_getaddrinfo_cb(uv_getaddrinfo_t *_req, int status, struct addrinfo *res)
{
    UV__Req_getaddrinfo req = _req->data;
    dTHXa(req->perl);

    struct addrinfo *addrp;

    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    mPUSHs(newSV_error(status));
    for(addrp = res; addrp; addrp = addrp->ai_next) {
        UV__getaddrinfo_result result;
        STRLEN canonnamelen = addrp->ai_canonname ? strlen(addrp->ai_canonname) + 1 : 0;
        Newxc(result, sizeof(*result) + addrp->ai_addrlen + canonnamelen, char, struct UV__getaddrinfo_result);

        result->family   = addrp->ai_family;
        result->socktype = addrp->ai_socktype;
        result->protocol = addrp->ai_protocol;
        result->addrlen  = addrp->ai_addrlen;
        result->addr     = (struct sockaddr *)((char *)result + sizeof(*result));
        Copy(addrp->ai_addr, result->addr, addrp->ai_addrlen, char);
        if(canonnamelen) {
            result->canonname = (char *)result->addr + addrp->ai_addrlen;
            Copy(addrp->ai_canonname, result->canonname, canonnamelen, char);
        }
        else {
            result->canonname = NULL;
        }

        EXTEND(SP, 1);
        PUSHmortal;
        sv_setref_pv(TOPs, "UV::getaddrinfo_result", result);
    }
    PUTBACK;

    call_sv(req->cb, G_DISCARD|G_VOID);

    FREETMPS;
    LEAVE;

    uv_freeaddrinfo(res);
    SvREFCNT_dec(req->selfrv);
}

typedef struct UV__Req_getnameinfo {
    uv_getnameinfo_t *r;
    FIELDS_UV__Req
} *UV__Req_getnameinfo;

static void on_getnameinfo_cb(uv_getnameinfo_t *_req, int status, const char *hostname, const char *service)
{
    UV__Req_getnameinfo req = _req->data;
    dTHXa(req->perl);

    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 3);
    mPUSHs(newSV_error(status));
    mPUSHp(hostname, strlen(hostname));
    mPUSHp(service, strlen(service));
    PUTBACK;

    call_sv(req->cb, G_DISCARD|G_VOID);

    FREETMPS;
    LEAVE;

    SvREFCNT_dec(req->selfrv);
}

/************
 * UV::Loop *
 ************/

typedef struct UV__Loop {
    uv_loop_t *loop; /* may point to uv_default_loop() or past this struct */
} *UV__Loop;

MODULE = UV             PACKAGE = UV            PREFIX = uv_

BOOT:
{
    HV *stash;
    AV *export;
#define DO_CONST_IV(c) \
    newCONSTSUB_flags(stash, #c, strlen(#c), 0, newSViv(c)); \
    av_push(export, newSVpvs(#c));
#define DO_CONST_PV(c) \
    newCONSTSUB_flags(stash, #c, strlen(#c), 0, newSVpvn(c, strlen(c))); \
    av_push(export, newSVpvs(#c));

    /* constants under UV */
    {
        stash = gv_stashpv("UV", GV_ADD);
        export = get_av("UV::EXPORT_XS", TRUE);

        DO_CONST_IV(UV_VERSION_MAJOR);
        DO_CONST_IV(UV_VERSION_MINOR);
        DO_CONST_IV(UV_VERSION_PATCH);
        DO_CONST_IV(UV_VERSION_IS_RELEASE);
        DO_CONST_IV(UV_VERSION_HEX);
        DO_CONST_PV(UV_VERSION_SUFFIX);

        DO_CONST_IV(UV_E2BIG);
        DO_CONST_IV(UV_EACCES);
        DO_CONST_IV(UV_EADDRINUSE);
        DO_CONST_IV(UV_EADDRNOTAVAIL);
        DO_CONST_IV(UV_EAFNOSUPPORT);
        DO_CONST_IV(UV_EAGAIN);
        DO_CONST_IV(UV_EAI_ADDRFAMILY);
        DO_CONST_IV(UV_EAI_AGAIN);
        DO_CONST_IV(UV_EAI_BADFLAGS);
        DO_CONST_IV(UV_EAI_BADHINTS);
        DO_CONST_IV(UV_EAI_CANCELED);
        DO_CONST_IV(UV_EAI_FAIL);
        DO_CONST_IV(UV_EAI_FAMILY);
        DO_CONST_IV(UV_EAI_MEMORY);
        DO_CONST_IV(UV_EAI_NODATA);
        DO_CONST_IV(UV_EAI_NONAME);
        DO_CONST_IV(UV_EAI_OVERFLOW);
        DO_CONST_IV(UV_EAI_PROTOCOL);
        DO_CONST_IV(UV_EAI_SERVICE);
        DO_CONST_IV(UV_EAI_SOCKTYPE);
        DO_CONST_IV(UV_EALREADY);
        DO_CONST_IV(UV_EBADF);
        DO_CONST_IV(UV_EBUSY);
        DO_CONST_IV(UV_ECANCELED);
        DO_CONST_IV(UV_ECHARSET);
        DO_CONST_IV(UV_ECONNABORTED);
        DO_CONST_IV(UV_ECONNREFUSED);
        DO_CONST_IV(UV_ECONNRESET);
        DO_CONST_IV(UV_EDESTADDRREQ);
        DO_CONST_IV(UV_EEXIST);
        DO_CONST_IV(UV_EFAULT);
        DO_CONST_IV(UV_EFBIG);
        DO_CONST_IV(UV_EHOSTUNREACH);
        DO_CONST_IV(UV_EINTR);
        DO_CONST_IV(UV_EINVAL);
        DO_CONST_IV(UV_EIO);
        DO_CONST_IV(UV_EISCONN);
        DO_CONST_IV(UV_EISDIR);
        DO_CONST_IV(UV_ELOOP);
        DO_CONST_IV(UV_EMFILE);
        DO_CONST_IV(UV_EMSGSIZE);
        DO_CONST_IV(UV_ENAMETOOLONG);
        DO_CONST_IV(UV_ENETDOWN);
        DO_CONST_IV(UV_ENETUNREACH);
        DO_CONST_IV(UV_ENFILE);
        DO_CONST_IV(UV_ENOBUFS);
        DO_CONST_IV(UV_ENODEV);
        DO_CONST_IV(UV_ENOENT);
        DO_CONST_IV(UV_ENOMEM);
        DO_CONST_IV(UV_ENONET);
        DO_CONST_IV(UV_ENOPROTOOPT);
        DO_CONST_IV(UV_ENOSPC);
        DO_CONST_IV(UV_ENOSYS);
        DO_CONST_IV(UV_ENOTCONN);
        DO_CONST_IV(UV_ENOTDIR);
        DO_CONST_IV(UV_ENOTEMPTY);
        DO_CONST_IV(UV_ENOTSOCK);
        DO_CONST_IV(UV_ENOTSUP);
        DO_CONST_IV(UV_EPERM);
        DO_CONST_IV(UV_EPIPE);
        DO_CONST_IV(UV_EPROTO);
        DO_CONST_IV(UV_EPROTONOSUPPORT);
        DO_CONST_IV(UV_EPROTOTYPE);
        DO_CONST_IV(UV_ERANGE);
        DO_CONST_IV(UV_EROFS);
        DO_CONST_IV(UV_ESHUTDOWN);
        DO_CONST_IV(UV_ESPIPE);
        DO_CONST_IV(UV_ESRCH);
        DO_CONST_IV(UV_ETIMEDOUT);
        DO_CONST_IV(UV_ETXTBSY);
        DO_CONST_IV(UV_EXDEV);
        DO_CONST_IV(UV_UNKNOWN);
        DO_CONST_IV(UV_EOF);
        DO_CONST_IV(UV_ENXIO);
        DO_CONST_IV(UV_EMLINK);
    }

    /* constants under UV::Handle */
    {
        stash = gv_stashpv("UV::Handle", GV_ADD);
        export = get_av("UV::Handle::EXPORT_XS", TRUE);

        DO_CONST_IV(UV_ASYNC);
        DO_CONST_IV(UV_CHECK);
        DO_CONST_IV(UV_FS_EVENT);
        DO_CONST_IV(UV_FS_POLL);
        DO_CONST_IV(UV_IDLE);
        DO_CONST_IV(UV_NAMED_PIPE);
        DO_CONST_IV(UV_POLL);
        DO_CONST_IV(UV_PREPARE);
        DO_CONST_IV(UV_PROCESS);
        DO_CONST_IV(UV_STREAM);
        DO_CONST_IV(UV_TCP);
        DO_CONST_IV(UV_TIMER);
        DO_CONST_IV(UV_TTY);
        DO_CONST_IV(UV_UDP);
        DO_CONST_IV(UV_SIGNAL);
        DO_CONST_IV(UV_FILE);
    }

    /* constants under UV::Loop */
    {
        stash = gv_stashpv("UV::Loop", GV_ADD);
        export = get_av("UV::Loop::EXPORT_XS", TRUE);

        /* Loop run constants */
        DO_CONST_IV(UV_RUN_DEFAULT);
        DO_CONST_IV(UV_RUN_ONCE);
        DO_CONST_IV(UV_RUN_NOWAIT);

        /* expose the Loop configure constants */
        DO_CONST_IV(UV_LOOP_BLOCK_SIGNAL);
        DO_CONST_IV(SIGPROF);
    }

    /* constants under UV::Poll */
    {
        stash = gv_stashpv("UV::Poll", GV_ADD);
        export = get_av("UV::Poll::EXPORT_XS", TRUE);

        /* Poll Event Types */
        DO_CONST_IV(UV_READABLE);
        DO_CONST_IV(UV_WRITABLE);
        DO_CONST_IV(UV_DISCONNECT);
        DO_CONST_IV(UV_PRIORITIZED);
    }

    /* constants under UV::Signal */
    {
        stash = gv_stashpv("UV::Signal", GV_ADD);
        export = get_av("UV::Signal::EXPORT_XS", TRUE);

        /* Signal numbers - exported again because at least on MSWin32 several
         * of these are emulated, and the values are not known to the rest of
         * the system, including POSIX.xs
         */
        DO_CONST_IV(SIGINT);
        DO_CONST_IV(SIGILL);
        DO_CONST_IV(SIGABRT);
        DO_CONST_IV(SIGFPE);
        DO_CONST_IV(SIGSEGV);
        DO_CONST_IV(SIGTERM);
#ifdef SIGBREAK
        DO_CONST_IV(SIGBREAK);
#endif
        DO_CONST_IV(SIGHUP);
        DO_CONST_IV(SIGKILL);
#ifdef SIGWINCH
        DO_CONST_IV(SIGWINCH);
#endif
}

    /* constants under UV::TTY */
    {
        stash = gv_stashpv("UV::TTY", GV_ADD);
        export = get_av("UV::TTY::EXPORT_XS", TRUE);

        /* TTY mode types */
        DO_CONST_IV(UV_TTY_MODE_NORMAL);
        DO_CONST_IV(UV_TTY_MODE_RAW);
        DO_CONST_IV(UV_TTY_MODE_IO);
    }

    /* constants under UV::UDP */
    {
        stash = gv_stashpv("UV::UDP", GV_ADD);
        export = get_av("UV::UDP::EXPORT_XS", TRUE);

        /* TTY mode types */
        DO_CONST_IV(UV_JOIN_GROUP);
        DO_CONST_IV(UV_LEAVE_GROUP);
    }
}

const char* uv_err_name(int err)

#if UVSIZE >= 8

UV uv_hrtime()
    CODE:
        RETVAL = uv_hrtime();
    OUTPUT:
        RETVAL

#else

NV uv_hrtime()
    CODE:
        RETVAL = (NV)uv_hrtime();
    OUTPUT:
        RETVAL

#endif

const char* uv_strerror(int err)

unsigned int uv_version()

const char* uv_version_string()

MODULE = UV             PACKAGE = UV::Exception

SV *
message(SV *self)
    CODE:
        RETVAL = newSV(0);
        sv_copypv(RETVAL, SvRV(self));
    OUTPUT:
        RETVAL

int
code(SV *self)
    CODE:
        RETVAL = SvIV(SvRV(self));
    OUTPUT:
        RETVAL

MODULE = UV             PACKAGE = UV::Handle

void
DESTROY(UV::Handle self)
    CODE:
        /* TODO:
            $self->stop() if ($self->can('stop') && !$self->closing() && !$self->closed());
         */
        if(!uv_is_closing(self->h))
            uv_close(self->h, on_close_cb);
        self->destroy_after_close = TRUE;

bool
closed(UV::Handle self)
    CODE:
        RETVAL = 0;
    OUTPUT:
        RETVAL

bool
closing(UV::Handle self)
    CODE:
        RETVAL = uv_is_closing(self->h);
    OUTPUT:
        RETVAL

bool
active(UV::Handle self)
    CODE:
        RETVAL = uv_is_active(self->h);
    OUTPUT:
        RETVAL

SV *
loop(UV::Handle self)
    INIT:
        UV__Loop loop;
    CODE:
        Newx(loop, 1, struct UV__Loop);
        loop->loop = self->h->loop;

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::Loop", loop);
    OUTPUT:
        RETVAL

SV *
data(UV::Handle self, SV *data = NULL)
    CODE:
        if(items > 1) {
            SvREFCNT_dec(self->data);
            self->data = newSVsv(data);
        }
        RETVAL = self->data ? newSVsv(self->data) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
_close(UV::Handle self)
    CODE:
        uv_close(self->h, on_close_cb);

SV *
_on_close(UV::Handle self, SV *cb = NULL)
    CODE:
        RETVAL = do_callback_accessor(&self->on_close, cb);
    OUTPUT:
        RETVAL

MODULE = UV             PACKAGE = UV::Async

SV *
_new(char *class, UV::Loop loop)
    INIT:
        UV__Async self;
        int err;
    CODE:
        NEW_UV__Handle(self, uv_async_t);

        err = uv_async_init(loop->loop, self->h, &on_async_cb);
        if (err != 0) {
            Safefree(self);
            THROWERR("Couldn't initialise async handle", err);
        }

        INIT_UV__Handle(self);
        self->on_async = NULL;

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::Async", self);
        self->selfrv = SvRV(RETVAL); /* no inc */
    OUTPUT:
        RETVAL

SV *
_on_async(UV::Async self, SV *cb = NULL)
    CODE:
        RETVAL = do_callback_accessor(&self->on_async, cb);
    OUTPUT:
        RETVAL

void
send(UV::Async self)
    CODE:
        CHECKCALL(uv_async_send(self->h));

MODULE = UV             PACKAGE = UV::Check

SV *
_new(char *class, UV::Loop loop)
    INIT:
        UV__Check self;
        int err;
    CODE:
        NEW_UV__Handle(self, uv_check_t);

        err = uv_check_init(loop->loop, self->h);
        if (err != 0) {
            Safefree(self);
            THROWERR("Couldn't initialise check handle", err);
        }

        INIT_UV__Handle(self);
        self->on_check = NULL;

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::Check", self);
        self->selfrv = SvRV(RETVAL); /* no inc */
    OUTPUT:
        RETVAL

SV *
_on_check(UV::Check self, SV *cb = NULL)
    CODE:
        RETVAL = do_callback_accessor(&self->on_check, cb);
    OUTPUT:
        RETVAL

SV *
_start(UV::Check self)
    CODE:
        CHECKCALL(uv_check_start(self->h, on_check_cb));
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

void
stop(UV::Check self)
    CODE:
        CHECKCALL(uv_check_stop(self->h));

MODULE = UV             PACKAGE = UV::Idle

SV *
_new(char *class, UV::Loop loop)
    INIT:
        UV__Idle self;
        int err;
    CODE:
        NEW_UV__Handle(self, uv_idle_t);

        err = uv_idle_init(loop->loop, self->h);
        if (err != 0) {
            Safefree(self);
            THROWERR("Couldn't initialise idle handle", err);
        }

        INIT_UV__Handle(self);
        self->on_idle = NULL;

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::Idle", self);
        self->selfrv = SvRV(RETVAL); /* no inc */
    OUTPUT:
        RETVAL

SV *
_on_idle(UV::Idle self, SV *cb = NULL)
    CODE:
        RETVAL = do_callback_accessor(&self->on_idle, cb);
    OUTPUT:
        RETVAL

SV *
_start(UV::Idle self)
    CODE:
        CHECKCALL(uv_idle_start(self->h, on_idle_cb));
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

void
stop(UV::Idle self)
    CODE:
        CHECKCALL(uv_idle_stop(self->h));

MODULE = UV             PACKAGE = UV::Pipe

SV *
_new(char *class, UV::Loop loop)
    INIT:
        UV__Pipe self;
        int err;
    CODE:
        NEW_UV__Handle(self, uv_pipe_t);

        err = uv_pipe_init(loop->loop, self->h, 0);
        if (err != 0) {
            Safefree(self);
            THROWERR("Couldn't initialse pipe handle", err);
        }

        INIT_UV__Handle(self);
        INIT_UV__Stream(self);

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::Pipe", self);
        self->selfrv = SvRV(RETVAL); /* no inc */
    OUTPUT:
        RETVAL

void
_open(UV::Pipe self, int fd)
    CODE:
        CHECKCALL(uv_pipe_open(self->h, fd));

void
bind(UV::Pipe self, char *name)
    CODE:
        CHECKCALL(uv_pipe_bind(self->h, name));

SV *
connect(UV::Pipe self, char *path, SV *cb)
    INIT:
        UV__Req_connect req;
    CODE:
        NEW_UV__Req(req, uv_connect_t);
        INIT_UV__Req(req);

        uv_pipe_connect(req->r, self->h, path, (uv_connect_cb)on_req_cb);

        req->cb = newSVsv(cb);

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::Req", req);
        req->selfrv = SvREFCNT_inc(SvRV(RETVAL));
    OUTPUT:
        RETVAL

SV *
getpeername(UV::Pipe self)
    ALIAS:
        getpeername = 0
        getsockname = 1
    INIT:
        size_t len;
        int err;
    CODE:
        RETVAL = newSV(256);
        len = SvLEN(RETVAL);

        err = (ix == 0) ?
            uv_pipe_getpeername(self->h, SvPVX(RETVAL), &len) :
            uv_pipe_getsockname(self->h, SvPVX(RETVAL), &len);
        if(err != 0) {
            SvREFCNT_dec(RETVAL);
            croak("Couldn't %s from pipe handle (%d): %s", (ix == 0) ? "getpeername" : "getsockname",
                err, uv_strerror(err));
        }

        SvCUR_set(RETVAL, len);
        SvPOK_on(RETVAL);
    OUTPUT:
        RETVAL

void
chmod(UV::Pipe self, int flags)
    CODE:
        CHECKCALL(uv_pipe_chmod(self->h, flags));

MODULE = UV             PACKAGE = UV::Poll

SV *
_new(char *class, UV::Loop loop, int fd, bool is_socket)
    INIT:
        UV__Poll self;
        int err;
    CODE:
        NEW_UV__Handle(self, uv_poll_t);

        if(is_socket) {
            err = uv_poll_init_socket(loop->loop, self->h, _MAKE_SOCK(fd));
            if (err != 0) {
                Safefree(self);
                THROWERR("Couldn't initialise poll handle for socket", err);
            }
        }
        else {
            err = uv_poll_init(loop->loop, self->h, fd);
            if (err != 0) {
                Safefree(self);
                THROWERR("Couldn't initialise poll handle for non-socket", err);
            }
        }

        INIT_UV__Handle(self);
        self->on_poll = NULL;

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::Poll", self);
        self->selfrv = SvRV(RETVAL); /* no inc */
    OUTPUT:
        RETVAL

SV *
_on_poll(UV::Poll self, SV *cb = NULL)
    CODE:
        RETVAL = do_callback_accessor(&self->on_poll, cb);
    OUTPUT:
        RETVAL

SV *
_start(UV::Poll self, int events = UV_READABLE)
    CODE:
        CHECKCALL(uv_poll_start(self->h, events, on_poll_cb));
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

void
stop(UV::Poll self)
    CODE:
        CHECKCALL(uv_poll_stop(self->h));

MODULE = UV             PACKAGE = UV::Prepare

SV *
_new(char *class, UV::Loop loop)
    INIT:
        UV__Prepare self;
        int err;
    CODE:
        NEW_UV__Handle(self, uv_prepare_t);

        err = uv_prepare_init(loop->loop, self->h);
        if (err != 0) {
            Safefree(self);
            THROWERR("Couldn't initialise prepare handle", err);
        }

        INIT_UV__Handle(self);
        self->on_prepare = NULL;

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::Prepare", self);
        self->selfrv = SvRV(RETVAL); /* no inc */
    OUTPUT:
        RETVAL

SV *
_on_prepare(UV::Prepare self, SV *cb = NULL)
    CODE:
        RETVAL = do_callback_accessor(&self->on_prepare, cb);
    OUTPUT:
        RETVAL

SV *
_start(UV::Prepare self)
    CODE:
        CHECKCALL(uv_prepare_start(self->h, on_prepare_cb));
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

void
stop(UV::Prepare self)
    CODE:
        CHECKCALL(uv_prepare_stop(self->h));

MODULE = UV             PACKAGE = UV::Process

SV *
_new(char *class, UV::Loop loop)
    INIT:
        UV__Process self;
        int err;
    CODE:
        NEW_UV__Handle(self, uv_process_t);
        self->loop = loop->loop;

        INIT_UV__Handle(self);
        self->on_exit = NULL;

        Zero(&self->options, 1, uv_process_options_t);

        self->options.exit_cb = &on_exit_cb;

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::Process", self);
        self->selfrv = SvRV(RETVAL); /* no inc */
    OUTPUT:
        RETVAL

SV *
_on_exit(UV::Process self, SV *cb = NULL)
    CODE:
        RETVAL = do_callback_accessor(&self->on_exit, cb);
    OUTPUT:
        RETVAL

void
_set_file(UV::Process self, char *file)
    CODE:
        self->options.file = savepv(file);

void
_set_args(UV::Process self, SV *args)
    INIT:
        AV *argsav;
        U32 i;
    CODE:
        if(!SvROK(args) || SvTYPE(SvRV(args)) != SVt_PVAV)
            croak("Expected args as ARRAY reference");

        argsav = (AV *)SvRV(args);

        Newx(self->options.args, AvFILL(argsav) + 3, char *);
        self->options.args[0] = NULL;
        for(i = 0; i <= AvFILL(argsav); i++)
            self->options.args[i+1] = savepv(SvPVbyte_nolen(AvARRAY(argsav)[i]));
        self->options.args[i+1] = NULL;

void
_set_env(UV::Process self, SV *env)
    INIT:
        HV *envhv;
        I32 nkeys, i, dummy;
        HE *iter;
        SV *tmp;
    CODE:
        if(!SvROK(env) || SvTYPE(SvRV(env)) != SVt_PVHV)
            croak("Expected env as HASH reference");

        envhv = (HV *)SvRV(env);
        nkeys = hv_iterinit(envhv);

        Newx(self->options.env, nkeys + 1, char *);
        tmp = sv_newmortal();

        i = 0;
        while((iter = hv_iternext(envhv))) {
            sv_setpvf(tmp, "%s=%s",
                hv_iterkey(iter, &dummy), SvPVbyte_nolen(HeVAL(iter)));

            self->options.env[i++] = SvPVX(tmp);
            SvPVX(tmp) = NULL;
            SvLEN(tmp) = 0;
        }
        self->options.env[i] = NULL;

void
_set_stdio_h(UV::Process self, int fd, SV *arg)
    INIT:
        uv_stdio_container_t *cont;
        int flags = 0;
        SV *fdarg = arg;
    CODE:
        if(self->options.stdio_count < (fd+1)) {
            int n = self->options.stdio_count;
            if(n < (fd+1)) n = (fd+1);
            if(n < 3)      n = 3;

            Renew(self->options.stdio, n, uv_stdio_container_t);
            int i;
            for(i = self->options.stdio_count; i < n; i++)
                self->options.stdio[i].flags = UV_IGNORE;

            self->options.stdio_count = n;
        }

        cont = self->options.stdio + fd;

        if(SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVHV) {
            fprintf(stderr, "TODO: grab extra values from hash\n");
        }

        if(!SvROK(fdarg)) {
            /* FD by stream number */
            cont->data.fd = SvIV(arg);
            flags |= UV_INHERIT_FD;
        }
        else if(SvTYPE(SvRV(fdarg)) == SVt_PVGV) {
            /* FD by globref */
            cont->data.fd = PerlIO_fileno(IoOFP(GvIO(SvRV(fdarg))));
            flags |= UV_INHERIT_FD;
        }
        else {
            croak("Unsure what to do with _set_stdio_h fd argument %" SVf, SVfARG(arg));
        }

        cont->flags = flags;

void
_set_setuid(UV::Process self, int uid)
    CODE:
        self->options.flags |= UV_PROCESS_SETUID;
        self->options.uid = uid;

void
_set_setgid(UV::Process self, int gid)
    CODE:
        self->options.flags |= UV_PROCESS_SETGID;
        self->options.uid = gid;


void
_spawn(UV::Process self)
    INIT:
        int err;
    CODE:
        if(!self->options.file)
            croak("Require 'file' to spawn a UV::Process");
        if(!self->options.args)
            croak("Require 'args' to spawn a UV::Process");

        if(!self->options.args[0])
            self->options.args[0] = savepv(self->options.file);

        err = uv_spawn(self->loop, self->h, &self->options);
        if (err != 0) {
            THROWERR("Couldn't spawn process", err);
        }

void
kill(UV::Process self, int signum)
    CODE:
        CHECKCALL(uv_process_kill(self->h, signum));

int
pid(UV::Process self)
    CODE:
        RETVAL = self->h->pid;
    OUTPUT:
        RETVAL

MODULE = UV             PACKAGE = UV::Signal

SV *
_new(char *class, UV::Loop loop, int signum)
    INIT:
        UV__Signal self;
        int err;
    CODE:
        NEW_UV__Handle(self, uv_signal_t);

        err = uv_signal_init(loop->loop, self->h);
        if (err != 0) {
            Safefree(self);
            THROWERR("Couldn't initialise signal handle", err);
        }

        INIT_UV__Handle(self);
        self->signum = signum; /* need to remember this until start() time */
        self->on_signal = NULL;

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::Signal", self);
        self->selfrv = SvRV(RETVAL); /* no inc */
    OUTPUT:
        RETVAL

SV *
_on_signal(UV::Signal self, SV *cb = NULL)
    CODE:
        RETVAL = do_callback_accessor(&self->on_signal, cb);
    OUTPUT:
        RETVAL

SV *
_start(UV::Signal self)
    CODE:
        CHECKCALL(uv_signal_start(self->h, on_signal_cb, self->signum));
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

void
stop(UV::Signal self)
    CODE:
        CHECKCALL(uv_signal_stop(self->h));

MODULE = UV             PACKAGE = UV::Stream

SV *
_on_read(UV::Stream self, SV *cb = NULL)
    CODE:
        RETVAL = do_callback_accessor(&self->on_read, cb);
    OUTPUT:
        RETVAL

SV *
_on_connection(UV::Stream self, SV *cb = NULL)
    CODE:
        RETVAL = do_callback_accessor(&self->on_connection, cb);
    OUTPUT:
        RETVAL

void
_listen(UV::Stream self, int backlog)
    CODE:
        CHECKCALL(uv_listen(self->h, backlog, on_connection_cb));

void
_accept(UV::Stream self, UV::Stream client)
    CODE:
        CHECKCALL(uv_accept(self->h, client->h));

SV *
shutdown(UV::Stream self, SV *cb)
    INIT:
        UV__Req_shutdown req;
        int err;
    CODE:
        NEW_UV__Req(req, uv_shutdown_t);
        INIT_UV__Req(req);

        err = uv_shutdown(req->r, self->h, (uv_shutdown_cb)on_req_cb);

        if(err != 0) {
            Safefree(req);
            THROWERR("Couldn't shutdown", err);
        }

        req->cb = newSVsv(cb);

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::Req", req);
        req->selfrv = SvREFCNT_inc(SvRV(RETVAL));
    OUTPUT:
        RETVAL

SV *
read_start(UV::Stream self)
    CODE:
        CHECKCALL(uv_read_start(self->h, on_alloc_cb, on_read_cb));
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

void
read_stop(UV::Stream self)
    CODE:
        CHECKCALL(uv_read_stop(self->h));

SV *
write(UV::Stream self, SV *s, SV *cb)
    INIT:
        UV__Req_write req;
        uv_buf_t buf[1];
        int err;
    CODE:
        NEW_UV__Req(req, uv_write_t);
        INIT_UV__Req(req);

        buf[0].len  = SvCUR(s);
        buf[0].base = savepvn(SvPVX(s), buf[0].len);

        req->s = buf[0].base;

        err = uv_write(req->r, self->h, buf, 1, (uv_write_cb)on_req_cb);

        if(err != 0) {
            Safefree(req->s);
            Safefree(req);
            THROWERR("Couldn't write", err);
        }

        req->cb = newSVsv(cb);

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::Req", req);
        req->selfrv = SvREFCNT_inc(SvRV(RETVAL));
    OUTPUT:
        RETVAL

MODULE = UV             PACKAGE = UV::Timer

SV *
_new(char *class, UV::Loop loop)
    INIT:
        UV__Timer self;
        int err;
    CODE:
        NEW_UV__Handle(self, uv_timer_t);

        err = uv_timer_init(loop->loop, self->h);
        if (err != 0) {
            Safefree(self);
            THROWERR("Couldn't initialise timer handle", err);
        }

        INIT_UV__Handle(self);
        self->on_timer = NULL;

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::Timer", self);
        self->selfrv = SvRV(RETVAL); /* no inc */
    OUTPUT:
        RETVAL

SV *
_on_timer(UV::Timer self, SV *cb = NULL)
    CODE:
        RETVAL = do_callback_accessor(&self->on_timer, cb);
    OUTPUT:
        RETVAL

SV *
_start(UV::Timer self, UV timeout, UV repeat)
    CODE:
        CHECKCALL(uv_timer_start(self->h, on_timer_cb, timeout, repeat));
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

UV
_get_repeat(UV::Timer self)
    CODE:
        RETVAL = uv_timer_get_repeat(self->h);
    OUTPUT:
        RETVAL

void
_set_repeat(UV::Timer self, UV repeat)
    CODE:
        uv_timer_set_repeat(self->h, repeat);

void
again(UV::Timer self)
    CODE:
        CHECKCALL(uv_timer_again(self->h));

void
stop(UV::Timer self)
    CODE:
        CHECKCALL(uv_timer_stop(self->h));

MODULE = UV             PACKAGE = UV::TCP

SV *
_new(char *class, UV::Loop loop)
    INIT:
        UV__TCP self;
        int err;
    CODE:
        NEW_UV__Handle(self, uv_tcp_t);

        err = uv_tcp_init(loop->loop, self->h);
        if (err != 0) {
            Safefree(self);
            THROWERR("Couldn't initialise tcp handle", err);
        }

        INIT_UV__Handle(self);
        INIT_UV__Stream(self);

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::TCP", self);
        self->selfrv = SvRV(RETVAL); /* no inc */
    OUTPUT:
        RETVAL

void
_open(UV::TCP self, int fd)
    CODE:
#ifdef HAVE_MSWIN32
        /* Not supported currently, because libuv would want overlapped IO on
         * sockets and perl does not create those. See also
         *   https://github.com/p5-UV/p5-UV/issues/38
         */
        croak("UV::TCP->open is not currently supported on Windows");
#endif
        CHECKCALL(uv_tcp_open(self->h, _MAKE_SOCK(fd)));

void
nodelay(UV::TCP self, bool enable)
    CODE:
        CHECKCALL(uv_tcp_nodelay(self->h, enable));

void
keepalive(UV::TCP self, bool enable, unsigned int delay = 0)
    CODE:
        if(enable && items < 3)
            croak_xs_usage(cv, "self, enable=true, delay");

        CHECKCALL(uv_tcp_keepalive(self->h, enable, delay));

void
simultaneous_accepts(UV::TCP self, bool enable)
    CODE:
        CHECKCALL(uv_tcp_simultaneous_accepts(self->h, enable));

void
bind(UV::TCP self, SV *addr, int flags = 0)
    CODE:
        if(!SvPOK(addr) || SvCUR(addr) < sizeof(struct sockaddr))
            croak("Expected a packed socket address for addr");

        CHECKCALL(uv_tcp_bind(self->h, (struct sockaddr *)SvPVX(addr), flags));

SV *
connect(UV::TCP self, SV *addr, SV *cb)
    INIT:
        UV__Req_connect req;
    CODE:
        NEW_UV__Req(req, uv_connect_t);
        INIT_UV__Req(req);

        if(!SvPOK(addr) || SvCUR(addr) < sizeof(struct sockaddr))
            croak("Expected a packed socket address for addr");

        uv_tcp_connect(req->r, self->h, (struct sockaddr *)SvPVX(addr), (uv_connect_cb)on_req_cb);

        req->cb = newSVsv(cb);

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::Req", req);
        req->selfrv = SvREFCNT_inc(SvRV(RETVAL));
    OUTPUT:
        RETVAL

SV *
getpeername(UV::TCP self)
    ALIAS:
        getpeername = 0
        getsockname = 1
    INIT:
        int len;
        int err;
    CODE:
        len = sizeof(struct sockaddr_storage);
        RETVAL = newSV(len);

        err = (ix == 0) ?
            uv_tcp_getpeername(self->h, (struct sockaddr *)SvPVX(RETVAL), &len) :
            uv_tcp_getsockname(self->h, (struct sockaddr *)SvPVX(RETVAL), &len);
        if(err != 0) {
            SvREFCNT_dec(RETVAL);
            croak("Couldn't %s from tcp handle (%d): %s", (ix == 0) ? "getpeername" : "getsockname",
                err, uv_strerror(err));
        }

        SvCUR_set(RETVAL, len);
        SvPOK_on(RETVAL);
    OUTPUT:
        RETVAL

void
_close_reset(UV::TCP self)
    CODE:
        CHECKCALL(uv_tcp_close_reset(self->h, on_close_cb));

MODULE = UV             PACKAGE = UV::TTY

SV *
_new(char *class, UV::Loop loop, int fd)
    INIT:
        UV__TTY self;
        int err;
    CODE:
        NEW_UV__Handle(self, uv_tty_t);

        err = uv_tty_init(loop->loop, self->h, fd, 0);
        if (err != 0) {
            Safefree(self);
            THROWERR("Couldn't initialise tty handle", err);
        }

        INIT_UV__Handle(self);
        INIT_UV__Stream(self);

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::TTY", self);
        self->selfrv = SvRV(RETVAL); /* no inc */
    OUTPUT:
        RETVAL

void
set_mode(UV::TTY self, int mode)
    CODE:
        CHECKCALL(uv_tty_set_mode(self->h, mode));

void
get_winsize(UV::TTY self)
    INIT:
        int width, height;
    PPCODE:
        CHECKCALL(uv_tty_get_winsize(self->h, &width, &height));
        EXTEND(SP, 2);
        mPUSHi(width);
        mPUSHi(height);
        XSRETURN(2);

MODULE = UV             PACKAGE = UV::UDP

SV *
_new(char *class, UV::Loop loop)
    INIT:
        UV__UDP self;
        int err;
    CODE:
        NEW_UV__Handle(self, uv_udp_t);

        err = uv_udp_init(loop->loop, self->h);
        if (err != 0) {
            Safefree(self);
            THROWERR("Couldn't initialse udp handle", err);
        }

        INIT_UV__Handle(self);
        self->on_recv = NULL;

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::UDP", self);
        self->selfrv = SvRV(RETVAL); /* no inc */
    OUTPUT:
        RETVAL

SV *
_on_recv(UV::UDP self, SV *cb = NULL)
    CODE:
        RETVAL = do_callback_accessor(&self->on_recv, cb);
    OUTPUT:
        RETVAL

void
_open(UV::UDP self, int fd)
    CODE:
#ifdef HAVE_MSWIN32
        /* Not supported currently, because libuv would want overlapped IO on
         * sockets and perl does not create those. See also
         *   https://github.com/p5-UV/p5-UV/issues/38
         */
        croak("UV::UDP->open is not currently supported on Windows");
#endif
        CHECKCALL(uv_udp_open(self->h, _MAKE_SOCK(fd)));

void
bind(UV::UDP self, SV *addr, int flags = 0)
    CODE:
        if(!SvPOK(addr) || SvCUR(addr) < sizeof(struct sockaddr))
            croak("Expected a packed socket address for addr");

        CHECKCALL(uv_udp_bind(self->h, (struct sockaddr *)SvPVX(addr), flags));

SV *
connect(UV::UDP self, SV *addr)
    CODE:
        if(!SvPOK(addr) || SvCUR(addr) < sizeof(struct sockaddr))
            croak("Expected a packed socket address for addr");

        CHECKCALL(uv_udp_connect(self->h, (struct sockaddr *)SvPVX(addr)));

SV *
getpeername(UV::UDP self)
    ALIAS:
        getpeername = 0
        getsockname = 1
    INIT:
        int len;
        int err;
    CODE:
        len = sizeof(struct sockaddr_storage);
        RETVAL = newSV(len);

        err = (ix == 0) ?
            uv_udp_getpeername(self->h, (struct sockaddr *)SvPVX(RETVAL), &len) :
            uv_udp_getsockname(self->h, (struct sockaddr *)SvPVX(RETVAL), &len);
        if(err != 0) {
            SvREFCNT_dec(RETVAL);
            croak("Couldn't %s from udp handle (%d): %s", (ix == 0) ? "getpeername" : "getsockname",
                err, uv_strerror(err));
        }

        SvCUR_set(RETVAL, len);
        SvPOK_on(RETVAL);
    OUTPUT:
        RETVAL

SV *
recv_start(UV::UDP self)
    CODE:
        CHECKCALL(uv_udp_recv_start(self->h, on_alloc_cb, on_recv_cb));
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

void
recv_stop(UV::UDP self)
    CODE:
        CHECKCALL(uv_udp_recv_stop(self->h));

SV *
send(UV::UDP self, SV *s, ...)
    INIT:
        UV__Req_udp_send req;
        uv_buf_t buf[1];
        int err;
        SV *addr;
        struct sockaddr *sockaddr = NULL;
        SV *cb;
    CODE:
        if(items > 4)
            croak_xs_usage(cv, "self, s, [from], cb");
        else if(items == 4) {
            addr = ST(2);
            cb   = ST(3);
        }
        else if(SvTYPE(SvRV(ST(2))) == SVt_PVCV) {
            addr = NULL;
            cb   = ST(2);
        }
        else {
            addr = ST(2);
            cb   = NULL;
        }

        if(addr) {
            if(!SvPOK(addr) || SvCUR(addr) < sizeof(struct sockaddr))
                croak("Expected a packed socket address for addr");
            sockaddr = (struct sockaddr *)SvPVX(addr);
        }

        NEW_UV__Req(req, uv_udp_send_t);
        INIT_UV__Req(req);

        buf[0].len  = SvCUR(s);
        buf[0].base = savepvn(SvPVX(s), buf[0].len);

        req->s = buf[0].base;

        err = uv_udp_send(req->r, self->h, buf, 1, sockaddr,
            (uv_udp_send_cb)on_req_cb);

        if(err != 0) {
            Safefree(req->s);
            Safefree(req);
            THROWERR("Couldn't send", err);
        }

        if(cb)
            req->cb = newSVsv(cb);
        else
            req->cb = NULL;

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::Req", req);
        req->selfrv = SvREFCNT_inc(SvRV(RETVAL));
    OUTPUT:
        RETVAL

void
set_broadcast(UV::UDP self, bool on)
    CODE:
        CHECKCALL(uv_udp_set_broadcast(self->h, on));

void
set_ttl(UV::UDP self, int ttl)
    CODE:
        CHECKCALL(uv_udp_set_ttl(self->h, ttl));

void
set_multicast_loop(UV::UDP self, bool on)
    CODE:
        CHECKCALL(uv_udp_set_multicast_loop(self->h, on));

void
set_multicast_ttl(UV::UDP self, int ttl)
    CODE:
        CHECKCALL(uv_udp_set_multicast_ttl(self->h, ttl));

void
set_multicast_interface(UV::UDP self, SV *ifaddr)
    CODE:
        CHECKCALL(uv_udp_set_multicast_interface(self->h, SvPVbyte_nolen(ifaddr)));

void
set_membership(UV::UDP self, SV *mcaddr, SV *ifaddr, int membership)
    CODE:
        CHECKCALL(uv_udp_set_membership(
            self->h, SvPVbyte_nolen(mcaddr), SvPVbyte_nolen(ifaddr), membership));

void
set_source_membership(UV::UDP self, SV *mcaddr, SV *ifaddr, SV *srcaddr, int membership)
    CODE:
        CHECKCALL(uv_udp_set_source_membership(
            self->h, SvPVbyte_nolen(mcaddr), SvPVbyte_nolen(ifaddr), SvPVbyte_nolen(srcaddr), membership));

void
try_send(UV::UDP self, SV *s, ...)
    INIT:
        uv_buf_t buf[1];
        int err;
        SV *addr;
        struct sockaddr *sockaddr = NULL;
    CODE:
        if(items > 3)
            croak_xs_usage(cv, "self, s, [from]");
        else if(items == 3) {
            addr = ST(2);
        }
        else {
            addr = NULL;
        }

        if(addr) {
            if(!SvPOK(addr) || SvCUR(addr) < sizeof(struct sockaddr))
                croak("Expected a packed socket address for addr");
            sockaddr = (struct sockaddr *)SvPVX(addr);
        }

        buf[0].len  = SvCUR(s);
        buf[0].base = savepvn(SvPVX(s), buf[0].len);

        err = uv_udp_try_send(self->h, buf, 1, sockaddr);

        if(err < 0) {
            THROWERR("Couldn't send", err);
        }

UV
get_send_queue_size(UV::UDP self)
    ALIAS:
        get_send_queue_size  = 0
        get_send_queue_count = 1
    CODE:
        switch(ix) {
            case 0: RETVAL = uv_udp_get_send_queue_size(self->h);  break;
            case 1: RETVAL = uv_udp_get_send_queue_count(self->h); break;
        }
    OUTPUT:
        RETVAL

MODULE = UV             PACKAGE = UV::Loop

SV *
_new(char *class, int want_default)
    INIT:
        UV__Loop self;
        int err;
    CODE:
        Newxc(self, sizeof(struct UV__Loop) + (!want_default * sizeof(uv_loop_t)),
            char, struct UV__Loop);

        if(want_default) {
            self->loop = uv_default_loop();
        }
        else {
            self->loop = (uv_loop_t *)((char *)self + sizeof(struct UV__Loop));
            err = uv_loop_init(self->loop);
            if(err != 0) {
                Safefree(self);
                THROWERR("Couldn't initialise loop", err);
            }
        }

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::Loop", self);
    OUTPUT:
        RETVAL

bool
alive(UV::Loop self)
    CODE:
        RETVAL = uv_loop_alive(self->loop);
    OUTPUT:
        RETVAL

int
backend_fd(UV::Loop self)
    CODE:
        RETVAL = uv_backend_fd(self->loop);
    OUTPUT:
        RETVAL

int
backend_timeout(UV::Loop self)
    CODE:
        RETVAL = uv_backend_timeout(self->loop);
    OUTPUT:
        RETVAL

void
DESTROY(UV::Loop self)
    CODE:
        /* Don't allow closing the default loop */
        if(self->loop != uv_default_loop())
            uv_loop_close(self->loop);

void
configure(UV::Loop self, int option, int value)
    CODE:
        CHECKCALL(uv_loop_configure(self->loop, option, value));

bool
is_default(UV::Loop self)
    CODE:
        RETVAL = (self->loop == uv_default_loop());
    OUTPUT:
        RETVAL

UV
now(UV::Loop self)
    CODE:
        RETVAL = uv_now(self->loop);
    OUTPUT:
        RETVAL

int
run(UV::Loop self, int mode = UV_RUN_DEFAULT)
    CODE:
        RETVAL = uv_run(self->loop, mode);
    OUTPUT:
        RETVAL

void
stop(UV::Loop self)
    CODE:
        uv_stop(self->loop);

void
update_time(UV::Loop self)
    CODE:
        uv_update_time(self->loop);

SV *
_getaddrinfo(UV::Loop self, char *node, char *service, SV *flags, SV *family, SV *socktype, SV *protocol, SV *cb)
    INIT:
        UV__Req_getaddrinfo req;
        struct addrinfo hints = { 0 };
        int err;
    CODE:
        NEW_UV__Req(req, uv_getaddrinfo_t);
        INIT_UV__Req(req);

        hints.ai_flags    = SvOK(flags)    ? SvIV(flags)    : DEFAULT_AI_FLAGS;
        hints.ai_family   = SvOK(family)   ? SvIV(family)   : AF_UNSPEC;
        hints.ai_socktype = SvOK(socktype) ? SvIV(socktype) : 0;
        hints.ai_protocol = SvOK(protocol) ? SvIV(protocol) : 0;

        err = uv_getaddrinfo(self->loop, req->r, on_getaddrinfo_cb,
            node, service, &hints);
        if (err != 0) {
            Safefree(req);
            THROWERR("Couldn't getaddrinfo", err);
        }

        req->cb = newSVsv(cb);

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::Req", req);
        req->selfrv = SvREFCNT_inc(SvRV(RETVAL));
    OUTPUT:
        RETVAL

SV *
getnameinfo(UV::Loop self, SV *addr, int flags, SV *cb)
    INIT:
        UV__Req_getnameinfo req;
        int err;
    CODE:
        NEW_UV__Req(req, uv_getnameinfo_t);
        INIT_UV__Req(req);

        err = uv_getnameinfo(self->loop, req->r, on_getnameinfo_cb,
            (struct sockaddr *)SvPV_nolen(addr), flags);
        if (err != 0) {
            Safefree(req);
            THROWERR("Couldn't getnameinfo", err);
        }

        req->cb = newSVsv(cb);

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "UV::Req", req);
        req->selfrv = SvREFCNT_inc(SvRV(RETVAL));
    OUTPUT:
        RETVAL

MODULE = UV             PACKAGE = UV::Req

void
DESTROY(UV::Req req)
    CODE:
        switch(req->r->type) {
            case UV_CONNECT:
                SvREFCNT_dec(((UV__Req_connect)req)->cb);
                break;

            case UV_GETADDRINFO:
                SvREFCNT_dec(((UV__Req_getaddrinfo)req)->cb);
                break;

            case UV_GETNAMEINFO:
                SvREFCNT_dec(((UV__Req_getnameinfo)req)->cb);
                break;

            case UV_SHUTDOWN:
                SvREFCNT_dec(((UV__Req_shutdown)req)->cb);
                break;

            case UV_WRITE:
                Safefree(((UV__Req_write)req)->s);
                SvREFCNT_dec(((UV__Req_write)req)->cb);
                break;
        }

        Safefree(req);

void
cancel(UV::Req req)
    INIT:
        int err;
    CODE:
        err = uv_cancel(req->r);
        /* Cancellation is best-effort; don't consider it an error if we get
         * EBUSY */
        if((err != 0) && (err != UV_EBUSY))
            THROWERR("Couldn't cancel", err);

MODULE = UV             PACKAGE = UV::getaddrinfo_result

void
DESTROY(UV::getaddrinfo_result self)
    CODE:
        Safefree(self);

int
family(UV::getaddrinfo_result self)
    ALIAS:
        family   = 0
        socktype = 1
        protocol = 2
    CODE:
        switch(ix) {
            case 0: RETVAL = self->family;   break;
            case 1: RETVAL = self->socktype; break;
            case 2: RETVAL = self->protocol; break;
        }
    OUTPUT:
        RETVAL

SV *
addr(UV::getaddrinfo_result self)
    ALIAS:
        addr      = 0
        canonname = 1
    CODE:
        switch(ix) {
            case 0: RETVAL = newSVpvn((char *)self->addr, self->addrlen); break;
            case 1: RETVAL = self->canonname ? newSVpv(self->canonname, 0) : &PL_sv_undef; break;
        }
    OUTPUT:
        RETVAL
