#include "Stream.h"
#include "ssl/SslFilter.h"

namespace panda { namespace unievent {

using ssl::SslFilter;

#define HOLD_ON(what) StreamSP __hold = what; (void)__hold;

#define INVOKE(h, f, fm, hm, ...) do { \
    if (f) f->fm(__VA_ARGS__);      \
    else   h->hm(__VA_ARGS__);      \
} while(0)

#define REQUEST_REQUIRE_WRITE_STATE do {                        \
    if (!handle->out_connected())                               \
        return delay([this]{                                    \
            cancel(make_error_code(std::errc::not_connected));  \
        });                                                     \
} while(0)

Stream::~Stream () {
    panda_log_dtor();
}

string Stream::buf_alloc (size_t cap) noexcept {
    try {
        return buf_alloc_callback ? buf_alloc_callback(cap) : string(cap);
    } catch (...) {
        return {};
    }
}

// ===================== CONNECTION ===============================
excepted<void, ErrorCode> Stream::listen (connection_fn callback, int backlog) {
    panda_log_info("Stream::listen, backlog " << backlog);
    invoke_sync(&StreamFilter::listen);
    if (callback) connection_event.add(callback);
    auto code = impl()->listen(backlog);
    if (code) {
        panda_log_info("Stream::listen error:" << code);
        return make_unexpected(ErrorCode(errc::listen_error, code));
    } else {
        set_listening();
        return {};
    }
}

void Stream::handle_connection (const std::error_code& err) {
    panda_log_info("handle_connection err: " << err << " this: " << this);
    HOLD_ON(this);
    if (err) INVOKE(this, _filters.back(), handle_connection, finalize_handle_connection, nullptr, err, nullptr);
    else     accept();
}

void Stream::accept () {
    StreamSP self = this;
    StreamSP client;
    if (connection_factory) client = connection_factory(self);
    else {
        if (_listener) client = _listener->create_connection(self);
        if (!client)   client = create_connection();
    }
    accept(client);
}

void Stream::accept (const StreamSP& client) {
    panda_log_debug("accept client " << client << ", this: " << this);
    auto err = impl()->accept(client->impl());
    if (!err) {
        client->set_connecting();
        client->set_established();
    }

    if (_listener) _listener->on_establish(this, client, err);

    // filters may delay handle_connection() and make subrequests
    // creating dummy AcceptRequest follows 2 purposes: holding the only client reference and delaying users requests until handle_connection() is done
    AcceptRequestSP areq;
    if (_filters.size()) {
        areq = new AcceptRequest(client);
        client->queue.push(areq);
    }
    INVOKE(this, _filters.back(), handle_connection, finalize_handle_connection, client, err, areq);
}

void Stream::finalize_handle_connection (const StreamSP& client, const ErrorCode& connection_err, const AcceptRequestSP& req) {
    ErrorCode err;
    if (!connection_err) {
        auto read_start_err = client->set_connect_result(true);
        if (read_start_err) err = ErrorCode(errc::read_start_error, read_start_err);
    } else {
        if (client) client->set_connect_result(false);
        err = connection_err;
    }
    panda_log_debug("finalize_handle_connection err: " << err << "client: " << client << ", this: " << this);

    if (req && client) client->queue.done(req, []{});
    StreamSP self = this;

    // call on client stream as well (may be useful)
    if (client) {
        client->connection_event(self, client, err);
        if (client->_listener) client->_listener->on_connection(self, client, err);
    }

    connection_event(self, client, err);
    if (_listener) _listener->on_connection(self, client, err);
}

// ===================== CONNECT ===============================
void ConnectRequest::exec () {
    panda_log_debug("ConnectRequest::exec " << this);
    handle->set_connecting();

    if (timeout) {
        _timer = new Timer(handle->loop());
        _timer->event.add([this](const TimerSP&){ cancel(make_error_code(std::errc::timed_out)); });
        _timer->once(timeout);
    }
}

void ConnectRequest::handle_event (const ErrorCode& err) {
    panda_log_debug("ConnectRequest::handle_event " << this);
    if (!err) handle->set_established();
    StreamSP stream = handle;
    ConnectRequestSP self = this;
    if (handle->_listener) handle->_listener->on_establish(stream, err, self);
    INVOKE(stream, last_filter, handle_connect, finalize_handle_connect, err, self);
}

void ConnectRequest::notify (const ErrorCode& err) { handle->notify_on_connect(err, this); }

void Stream::finalize_handle_connect (const ErrorCode& connect_err, const ConnectRequestSP& req) {
    ErrorCode err;
    if (!connect_err) {
        auto read_start_err = set_connect_result(true);
        if (read_start_err) err = ErrorCode(errc::read_start_error, read_start_err);
    } else {
        set_connect_result(false);
        err = connect_err;
    }
    panda_log_debug("finalize_handle_connect err: " << err << "req: " << req << ", this: " << this);

    if (req->_timer) {
        req->_timer->pause();
        req->_timer->event.remove_all();
    }

    // if we are already canceling queue now, do not start recursive cancel
    if (!err || queue.canceling()) {
        queue.done(req, [=]{ notify_on_connect(err, req); });
    }
    else { // cancel everything till the end of queue, but call connect callback with actual status(err), not with ECANCELED
        queue.cancel([&]{
            // temporary variable for lambda fixes some kind of bug in clang 8 compiler on FreeBSD: somewhy dtor of "req" variable is called twice
            auto l = [=]{ notify_on_connect(err, req); };
            queue.done(req, l);
        }, [&]{
            _reset();
        });
    }
}

void Stream::notify_on_connect (const ErrorCode& err, const ConnectRequestSP& req) {
    StreamSP self = this;
    req->event(self, err, req);
    connect_event(self, err, req);
    if (_listener) _listener->on_connect(self, err, req);
}

// ===================== READ ===============================
std::error_code Stream::_read_start () {
    if (reading() || !established()) return {};
    auto err = impl()->read_start();
    if (!err) set_reading(true);
    return err;
}

void Stream::read_stop () {
    set_wantread(false);
    if (!reading()) return;
    impl()->read_stop();
    set_reading(false);
}

void Stream::handle_read (string& buf, const std::error_code& err) {
    if (err == std::errc::connection_reset) return handle_eof(); // sometimes (when we were WRITING) read with error occurs instead of EOF
    if (flags & IGNORE_READ) return;
    HOLD_ON(this);
    INVOKE(this, _filters.back(), handle_read, finalize_handle_read, buf, err);
}

void Stream::finalize_handle_read (string& buf, const ErrorCode& err) {
    StreamSP self = this;
    read_event(self, buf, err);
    if (_listener) _listener->on_read(self, buf, err);
}

// ===================== WRITE ===============================
void Stream::write (const WriteRequestSP& req) {
    panda_log_debug("WriteRequest::exec req: " << req << ", this: " << this);
    for (const auto& buf : req->bufs) _wq_size += buf.length();
    req->set(this);
    queue.push(req);
}

void WriteRequest::exec () {
    panda_log_debug([&]{
        size_t sum = 0;
        for (const auto b : bufs) {
            sum += b.size();
        }
        log << "WriteRequest::exec " << this << " " << sum << " bytes";
    });
    REQUEST_REQUIRE_WRITE_STATE;
    last_filter = handle->_filters.front();
    for (const auto& buf : bufs) handle->_wq_size -= buf.length();
    INVOKE(handle, last_filter, write, finalize_write, this);
}

void Stream::finalize_write (const WriteRequestSP& req) {
    panda_log_debug("WriteRequest::finalize_write " << this);
    auto err = impl()->write(req->bufs, req->impl());
    if (err) req->delay([=]{ req->cancel(err); });
}

void WriteRequest::handle_event (const ErrorCode& err) {
    panda_log_debug("WriteRequest::handle_event " << this << ", err" << err);
    if (err & std::errc::broken_pipe) handle->clear_out_connected();
    HOLD_ON(handle);
    INVOKE(handle, last_filter, handle_write, finalize_handle_write, err, this);
}

void WriteRequest::notify (const ErrorCode& err) { handle->notify_on_write(err, this); }

void Stream::finalize_handle_write (const ErrorCode& err, const WriteRequestSP& req) {
    panda_log_debug("finalize_handle_write err: " << err << ", request" << req << ", this" << this);
    queue.done(req, [=]{ notify_on_write(err, req); });
}

void Stream::notify_on_write (const ErrorCode& err, const WriteRequestSP& req) {
    StreamSP self = this;
    req->event(self, err, req);
    write_event(self, err, req);
    if (_listener) _listener->on_write(self, err, req);
}

// ===================== EOF ===============================
void Stream::handle_eof () {
    if (!established()) return;
    clear_in_connected();
    HOLD_ON(this);
    INVOKE(this, _filters.back(), handle_eof, finalize_handle_eof);
}

void Stream::finalize_handle_eof () {
    StreamSP self = this;
    eof_event(self);
    if (_listener) _listener->on_eof(self);
}

// ===================== SHUTDOWN ===============================
void Stream::shutdown (const ShutdownRequestSP& req) {
    panda_log_debug("shutdown req: " << req << ", this:" << this);
    req->set(this);
    req->timed_out = false;

    if (req->timeout) {
        req->timer = new Timer(loop());
        auto reqp = req.get();
        req->timer->event.add([this, reqp](const TimerSP&){
            // if we have any requests not completed before shutdown - cancel it with status "cancelled" and then cancel shutdown request with status "timed out"
            // otherwise, just cancel shutdown request with status "timed out"
            // notice that we don't cancel all the queue, but only everything before shutdown request. next request after shutdown request will start running right now
            auto prev_req = intrusive_chain_prev(RequestSP(reqp));
            if (prev_req) {
                reqp->timed_out = true; // needed for calling with correct err if somebody calls reset() in previous requests handlers
                queue.cancel([]{}, [reqp] {
                    reqp->cancel(make_error_code(std::errc::timed_out));
                }, prev_req);
            } else {
                reqp->cancel(make_error_code(std::errc::timed_out));
            }
        });
        req->timer->once(req->timeout);
    }

    queue.push(req);
}

void ShutdownRequest::exec () {
    panda_log_debug("ShutdownRequest::exec " << this);
    REQUEST_REQUIRE_WRITE_STATE;
    last_filter = handle->_filters.front();
    INVOKE(handle, last_filter, shutdown, finalize_shutdown, this);
}

void Stream::finalize_shutdown (const ShutdownRequestSP& req) {
    panda_log_debug("finalize_shutdown " << this);
    set_shutting();
    impl()->shutdown(req->impl());
}

void ShutdownRequest::handle_event (const ErrorCode& err) {
    panda_log_debug("ShutdownRequest::handle_event " << this);
    HOLD_ON(handle);
    INVOKE(handle, last_filter, handle_shutdown, finalize_handle_shutdown, err, this);
}

void ShutdownRequest::notify (const ErrorCode& err) { handle->notify_on_shutdown(err, this); }

void ShutdownRequest::cancel (const ErrorCode& err) {
    if (timed_out && err & std::errc::operation_canceled) {
        timed_out = false;
        StreamRequest::cancel(make_error_code(std::errc::timed_out));
    }
    else StreamRequest::cancel(err);
}

void Stream::finalize_handle_shutdown (const ErrorCode& err, const ShutdownRequestSP& req) {
    panda_log_debug("finalize_handle_shutdown req: " << err << "req: " << req << ", this: " << this);
    set_shutdown(!err);
    req->timer = nullptr;
    queue.done(req, [=]{ notify_on_shutdown(err, req); });
}

void Stream::notify_on_shutdown (const ErrorCode& err, const ShutdownRequestSP& req) {
    StreamSP self = this;
    req->event(self, err, req);
    shutdown_event(self, err, req);
    if (_listener) _listener->on_shutdown(self, err, req);
}

// ===================== DISCONNECT/RESET/CLEAR ===============================
struct DisconnectRequest : StreamRequest {
    DisconnectRequest (Stream* h) { set(h); }

    void exec         ()                 override { handle->queue.done(this, [&]{ HOLD_ON(handle); handle->_reset(); }); }
    void cancel       (const ErrorCode&) override { handle->queue.done(this, []{}); }
    void handle_event (const ErrorCode&) override {}
    void notify       (const ErrorCode&) override {}
};

void Stream::disconnect () {
    if (!queue.size()) {
        HOLD_ON(this);
        _reset();
    }
    else if (queue.size() == 1 && connecting()) reset();
    else queue.push(new DisconnectRequest(this));
}

void Stream::reset () {
    HOLD_ON(this);
    queue.cancel([&]{ _reset(); });
}

void Stream::_reset () {
    BackendHandle::reset();
    invoke_sync(&StreamFilter::reset);
    flags &= DONTREAD; // clear flags except DONTREAD
    _wq_size = 0;
    on_reset();
}

void Stream::clear () {
    HOLD_ON(this);
    queue.cancel([&]{ _clear(); });
}

void Stream::_clear () {
    BackendHandle::clear();
    invoke_sync(&StreamFilter::reset);
    _filters.clear();
    flags              = 0;
    _wq_size           = 0;
    _listener          = nullptr;
    buf_alloc_callback = nullptr;
    connection_factory = nullptr;
    connection_event.remove_all();
    connect_event.remove_all();
    read_event.remove_all();
    write_event.remove_all();
    shutdown_event.remove_all();
    eof_event.remove_all();
    on_reset();
}

// ===================== FILTERS ADD/REMOVE ===============================
void Stream::add_filter (const StreamFilterSP& filter, bool force) {
    assert(filter);
    if (!force) _check_change_filters();
    auto it = _filters.begin();
    auto pos = it;
    bool found = false;
    while (it != _filters.end()) {
        if ((*it)->type() == filter->type()) {
            *it = filter;
            return;
        }
        if ((*it)->priority() > filter->priority() && !found) {
            pos = it;
            found = true;
        }
        it++;
    }
    if (found) _filters.insert(pos, filter);
    else _filters.push_back(filter);
}

void Stream::remove_filter (const StreamFilterSP& filter, bool force) {
    if (!force) _check_change_filters();
    _filters.erase(filter);
}

StreamFilterSP Stream::get_filter (const void* type) const {
    for (const auto& f : _filters) if (f->type() == type) return f;
    return {};
}

void Stream::use_ssl (const SslContext &context)  { add_filter(new SslFilter(this, context)); }
void Stream::use_ssl (const SSL_METHOD* method)   { add_filter(new SslFilter(this, method)); }

bool Stream::is_secure () const { return get_filter(SslFilter::TYPE); }

SSL* Stream::get_ssl() const {
    auto filter = get_filter<SslFilter>();
    return filter ? filter->get_ssl() : nullptr;
}

void Stream::no_ssl () {
    auto filter = get_filter<SslFilter>();
    if (!filter) return;
    remove_filter(filter);
}

// ===================== RUN IN ORDER REQUEST ===============================
void RunInOrderRequest::exec         ()                     { handle->queue.done(this, [this]{ code(handle); }); }
void RunInOrderRequest::handle_event (const ErrorCode& err) { assert(err); }
void RunInOrderRequest::notify       (const ErrorCode& err) { assert(err); }

}}
