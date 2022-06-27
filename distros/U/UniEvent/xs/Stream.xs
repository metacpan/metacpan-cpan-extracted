#include <xs/unievent/Timer.h>
#include <xs/unievent/Stream.h>
#include <xs/typemap/expected.h>
#include <xs/unievent/Listener.h>
#include <xs/CallbackDispatcher.h>

using namespace xs;
using namespace xs::unievent;
using namespace panda::unievent;
using panda::string;

static PERL_ITHREADS_LOCAL struct {
    Simple create_connection = Simple::shared("create_connection");
    Simple on_establish      = Simple::shared("on_establish");
    Simple on_connection     = Simple::shared("on_connection");
    Simple on_connect        = Simple::shared("on_connect");
    Simple on_read           = Simple::shared("on_read");
    Simple on_write          = Simple::shared("on_write");
    Simple on_shutdown       = Simple::shared("on_shutdown");
    Simple on_eof            = Simple::shared("on_eof");
} cbn;

struct XSStreamListener : IStreamListener, XSListener {
    StreamSP create_connection (const StreamSP& h) override {
        auto ret = call<Scalar>(cbn.create_connection, xs::out(h));
        return ret ? xs::in<StreamSP>(ret) : StreamSP();
    }

    void on_establish (const StreamSP& h, const StreamSP& client, const ErrorCode& err) override {
        call(cbn.on_establish, xs::out(h), xs::out(client), xs::out(err));
    }

    void on_connection (const StreamSP& h, const StreamSP& client, const ErrorCode& err) override {
        call(cbn.on_connection, xs::out(h), xs::out(client), xs::out(err));
    }

    void on_establish (const StreamSP& h, const ErrorCode& err, const ConnectRequestSP& req) override {
        call(cbn.on_establish, xs::out(h), xs::out(err), xs::out(req));
    }

    void on_connect (const StreamSP& h, const ErrorCode& err, const ConnectRequestSP& req) override {
        call(cbn.on_connect, xs::out(h), xs::out(err), xs::out(req));
    }

    void on_read (const StreamSP& h, string& buf, const ErrorCode& err) override {
        call(cbn.on_read, xs::out(h), err ? Sv::undef : xs::out(buf), xs::out(err));
    }

    void on_write (const StreamSP& h, const ErrorCode& err, const WriteRequestSP& req) override {
        call(cbn.on_write, xs::out(h), xs::out(err), xs::out(req));
    }

    void on_shutdown (const StreamSP& h, const ErrorCode& err, const ShutdownRequestSP& req) override {
        call(cbn.on_shutdown, xs::out(h), xs::out(err), xs::out(req));
    }

    void on_eof (const StreamSP& h) override {
        call(cbn.on_eof, xs::out(h));
    }
};

MODULE = UniEvent::Stream                PACKAGE = UniEvent::Stream
PROTOTYPES: DISABLE

BOOT {
    Stash s(__PACKAGE__);
    s.inherit("UniEvent::Handle");

    xs::at_perl_destroy([]() {
        cbn.create_connection = nullptr;
        cbn.on_establish      = nullptr;
        cbn.on_connection     = nullptr;
        cbn.on_connect        = nullptr;
        cbn.on_read           = nullptr;
        cbn.on_write          = nullptr;
        cbn.on_shutdown       = nullptr;
        cbn.on_eof            = nullptr;
    });
}

bool Stream::readable ()

bool Stream::writable ()

bool Stream::listening ()

bool Stream::connecting ()

bool Stream::established ()

bool Stream::connected ()

bool Stream::wantread ()

bool Stream::shutting_down ()

bool Stream::is_shut_down ()

size_t Stream::write_queue_size ()

bool Stream::is_secure ()

void Stream::connection_factory (Sub callback) {
    THIS->connection_factory = [callback](const StreamSP& h) -> StreamSP {
        return xs::in<StreamSP>( callback.call(xs::out(h)) );
    };
}

XSCallbackDispatcher* Stream::connection_event () {
    RETVAL = XSCallbackDispatcher::create(THIS->connection_event);
}

void Stream::connection_callback (Stream::connection_fn cb) {
    THIS->connection_event.remove_all();
    if (cb) THIS->connection_event.add(cb);
}

XSCallbackDispatcher* Stream::connect_event () {
    RETVAL = XSCallbackDispatcher::create(THIS->connect_event);
}

void Stream::connect_callback (Stream::connect_fn cb) {
    THIS->connect_event.remove_all();
    if (cb) THIS->connect_event.add(cb);
}

XSCallbackDispatcher* Stream::read_event () {
    RETVAL = XSCallbackDispatcher::create(THIS->read_event);
}

void Stream::read_callback (Stream::read_fn cb) {
    THIS->read_event.remove_all();
    if (cb) THIS->read_event.add(cb);
}

XSCallbackDispatcher* Stream::write_event () {
    RETVAL = XSCallbackDispatcher::create(THIS->write_event);
}

void Stream::write_callback (Stream::write_fn cb) {
    THIS->write_event.remove_all();
    if (cb) THIS->write_event.add(cb);
}

XSCallbackDispatcher* Stream::shutdown_event () {
    RETVAL = XSCallbackDispatcher::create(THIS->shutdown_event);
}

void Stream::shutdown_callback (Stream::shutdown_fn cb) {
    THIS->shutdown_event.remove_all();
    if (cb) THIS->shutdown_event.add(cb);
}

XSCallbackDispatcher* Stream::eof_event () {
    RETVAL = XSCallbackDispatcher::create(THIS->eof_event);
}

void Stream::eof_callback (Stream::eof_fn cb) {
    THIS->eof_event.remove_all();
    if (cb) THIS->eof_event.add(cb);
}

Ref Stream::event_listener (Sv lst = Sv(), bool weak = false) {
    RETVAL = event_listener<XSStreamListener>(THIS, ST(0), lst, weak);
}

#// listen([$callback], [$backlog])
#// listen($backlog)
void Stream::listen (Sv cb_bl = Sv(), int backlog = Stream::DEFAULT_BACKLOG) {
    if (items == 2 && cb_bl.is_simple()) {
        backlog = SvIV(cb_bl);
        cb_bl.reset();
    }
    if (cb_bl) {
        auto fn = xs::in<Stream::connection_fn>(cb_bl);
        if (fn) THIS->connection_event.add(fn);
    }
    XSRETURN_EXPECTED(THIS->listen(backlog));
}

void Stream::read_start () {
    XSRETURN_EXPECTED(THIS->read_start());
}

void Stream::read_stop ()

WriteRequestSP Stream::write (Sv sv, Stream::write_fn cb = nullptr) {
    auto buf = sv2buf(sv);
    if (!buf) XSRETURN(0);

    WriteRequestSP req = make_backref<WriteRequest>(buf);
    if (cb) req->event.add(cb);
    THIS->write(req);
    RETVAL = req;
}

#// shutdown([$timeout], [$cb]) or shutdown($cb)
ShutdownRequestSP Stream::shutdown (Sv arg1 = {}, Sv arg2 = {}) {
    double timeout = 0;
    Stream::shutdown_fn cb;

    if (arg2) {
        timeout = SvNV(arg1);
        cb = xs::in<Stream::shutdown_fn>(arg2);
    }
    else if (arg1) {
        if (arg1.is_sub_ref()) cb = xs::in<Stream::shutdown_fn>(arg1);
        else                   timeout = SvNV(arg1);
    }

    ShutdownRequestSP req = make_backref<ShutdownRequest>(cb, timeout * 1000);
    THIS->shutdown(req);
    RETVAL = req;
}

void Stream::disconnect ()

void Stream::sockaddr () : ALIAS(peeraddr=1) {
    auto res = ix == 0 ? THIS->sockaddr() : THIS->peeraddr();
    XSRETURN_EXPECTED(res);
}

void Stream::use_ssl (SslContext ctx = NULL) {
    if (ctx) THIS->use_ssl(ctx);
    else THIS->use_ssl();
}

void Stream::no_ssl ()

void Stream::recv_buffer_size (SV* newval = {}) {
    if (newval) XSRETURN_EXPECTED(THIS->recv_buffer_size(xs::in<int>(newval)));
    else        XSRETURN_EXPECTED(THIS->recv_buffer_size());
}

void Stream::send_buffer_size (SV* newval = {}) {
    if (newval) XSRETURN_EXPECTED(THIS->send_buffer_size(xs::in<int>(newval)));
    else        XSRETURN_EXPECTED(THIS->send_buffer_size());
}

void Stream::run_in_order (Stream::run_fn cb)


MODULE = UniEvent::Stream                PACKAGE = UniEvent::Request::Connect
PROTOTYPES: DISABLE

BOOT {
    Stash stash(__PACKAGE__, GV_ADD);
    stash.inherit("UniEvent::Request");
}

TimerSP ConnectRequest::timeout_timer () {
    RETVAL = THIS->timeout_timer();
}


MODULE = UniEvent::Stream                PACKAGE = UniEvent::Request::Write
PROTOTYPES: DISABLE

BOOT {
    Stash stash(__PACKAGE__, GV_ADD);
    stash.inherit("UniEvent::Request");
}


MODULE = UniEvent::Stream                PACKAGE = UniEvent::Request::Shutdown
PROTOTYPES: DISABLE

BOOT {
    Stash stash(__PACKAGE__, GV_ADD);
    stash.inherit("UniEvent::Request");
}
