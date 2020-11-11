#pragma once
#include "Queue.h"
#include "Timer.h"
#include "forward.h"
#include "Request.h"
#include "StreamFilter.h"
#include "BackendHandle.h"
#include "SslContext.h"
#include "backend/StreamImpl.h"
#include <panda/excepted.h>

struct ssl_st;        typedef ssl_st SSL;
struct ssl_method_st; typedef ssl_method_st SSL_METHOD;

namespace panda { namespace unievent {

struct IStreamListener {
    virtual StreamSP create_connection (const StreamSP&)                                             { return {}; }
    virtual void     on_connection     (const StreamSP&, const StreamSP&, const ErrorCode&)          {}
    virtual void     on_connect        (const StreamSP&, const ErrorCode&, const ConnectRequestSP&)  {}
    virtual void     on_read           (const StreamSP&, string&, const ErrorCode&)                  {}
    virtual void     on_write          (const StreamSP&, const ErrorCode&, const WriteRequestSP&)    {}
    virtual void     on_shutdown       (const StreamSP&, const ErrorCode&, const ShutdownRequestSP&) {}
    virtual void     on_eof            (const StreamSP&)                                             {}
};

struct IStreamSelfListener : IStreamListener {
    virtual StreamSP create_connection ()                                           { return {}; }
    virtual void     on_connection     (const StreamSP&, const ErrorCode&)          {}
    virtual void     on_connect        (const ErrorCode&, const ConnectRequestSP&)  {}
    virtual void     on_read           (string&, const ErrorCode&)                  {}
    virtual void     on_write          (const ErrorCode&, const WriteRequestSP&)    {}
    virtual void     on_shutdown       (const ErrorCode&, const ShutdownRequestSP&) {}
    virtual void     on_eof            ()                                           {}

    StreamSP create_connection (const StreamSP&)                                                     override { return create_connection(); }
    void     on_connection     (const StreamSP&, const StreamSP& cli, const ErrorCode& err)          override { on_connection(cli, err); }
    void     on_connect        (const StreamSP&, const ErrorCode& err, const ConnectRequestSP& req)  override { on_connect(err, req); }
    void     on_read           (const StreamSP&, string& buf, const ErrorCode& err)                  override { on_read(buf, err); }
    void     on_write          (const StreamSP&, const ErrorCode& err, const WriteRequestSP& req)    override { on_write(err, req); }
    void     on_shutdown       (const StreamSP&, const ErrorCode& err, const ShutdownRequestSP& req) override { on_shutdown(err, req); }
    void     on_eof            (const StreamSP&)                                                     override { on_eof(); }
};

struct Stream : virtual BackendHandle, protected backend::IStreamImplListener {
    using Filters         = IntrusiveChain<StreamFilterSP>;
    using conn_factory_fn = function<StreamSP(const StreamSP&)>;
    using connection_fptr = void(const StreamSP& handle, const StreamSP& client, const ErrorCode& err);
    using connection_fn   = function<connection_fptr>;
    using connect_fptr    = void(const StreamSP& handle, const ErrorCode& err, const ConnectRequestSP& req);
    using connect_fn      = function<connect_fptr>;
    using read_fptr       = void(const StreamSP& handle, string& buf, const ErrorCode& err);
    using read_fn         = function<read_fptr>;
    using write_fptr      = void(const StreamSP& handle, const ErrorCode& err, const WriteRequestSP& req);
    using write_fn        = function<write_fptr>;
    using shutdown_fptr   = void(const StreamSP& handle, const ErrorCode& err, const ShutdownRequestSP& req);
    using shutdown_fn     = function<shutdown_fptr>;
    using eof_fptr        = void(const StreamSP& handle);
    using eof_fn          = function<eof_fptr>;
    using run_fptr        = void(const StreamSP& handle);
    using run_fn          = function<run_fptr>;

    static const int DEFAULT_BACKLOG = 128;

    buf_alloc_fn                        buf_alloc_callback;
    conn_factory_fn                     connection_factory;
    CallbackDispatcher<connection_fptr> connection_event;
    CallbackDispatcher<connect_fptr>    connect_event;
    CallbackDispatcher<read_fptr>       read_event;
    CallbackDispatcher<write_fptr>      write_event;
    CallbackDispatcher<shutdown_fptr>   shutdown_event;
    CallbackDispatcher<eof_fptr>        eof_event;

    IStreamListener* event_listener () const             { return _listener; }
    void             event_listener (IStreamListener* l) { _listener = l; }

    string buf_alloc (size_t cap) noexcept override;

    bool   readable         () const { return impl()->readable(); }
    bool   writable         () const { return impl()->writable(); }
    bool   listening        () const { return flags & LISTENING; }
    bool   connecting       () const { return flags & CONNECTING; }
    bool   established      () const { return flags & ESTABLISHED; }
    bool   connected        () const { return flags & (IN_CONNECTED | OUT_CONNECTED); }
    bool   in_connected     () const { return flags & IN_CONNECTED; }
    bool   out_connected    () const { return flags & OUT_CONNECTED; }
    bool   wantread         () const { return !(flags & DONTREAD); }
    bool   shutting_down    () const { return flags & SHUTTING; }
    bool   is_shut_down     () const { return flags & SHUT; }
    size_t write_queue_size () const { return _wq_size + impl()->write_queue_size(); }

    excepted<void, ErrorCode>         listen (int backlog) { return listen(nullptr, backlog); }
    virtual excepted<void, ErrorCode> listen (connection_fn callback = nullptr, int backlog = DEFAULT_BACKLOG);

    virtual void   write (const WriteRequestSP&);
    WriteRequestSP write (const string& buf, write_fn callback = nullptr); /*INLINE*/
    template <class It>
    WriteRequestSP write (const It& begin, const It& end, write_fn callback = nullptr); /*INLINE*/
    template <class Range, typename = typename std::enable_if<std::is_convertible<decltype(*std::declval<Range>().begin()), string>::value>::type>
    WriteRequestSP write (const Range& range, write_fn callback = nullptr); /*INLINE*/

    virtual void shutdown (const ShutdownRequestSP&);
    /*INL*/ void shutdown (shutdown_fn callback = {});
    /*INL*/ void shutdown (uint64_t timeout, shutdown_fn callback = {});

    template <class T> void run_in_order (T&& code);

    excepted<void, ErrorCode> read_start () {
        set_wantread(true);
        flags &= ~IGNORE_READ;
        auto err = _read_start();
        if (err) return make_unexpected(ErrorCode(err));
        return {};
    }

    void read_stop ();

    void read_ignore () { flags |= IGNORE_READ; }

    virtual void disconnect ();

    void reset () override;
    void clear () override;

    void use_ssl (const SslContext& context);
    void use_ssl (const SSL_METHOD* method = nullptr);
    void no_ssl  ();

    SSL* get_ssl   () const;
    bool is_secure () const;

    void add_filter    (const StreamFilterSP&, bool force = false);
    void remove_filter (const StreamFilterSP&, bool force = false);

    template <typename F>
    iptr<F>        get_filter ()                 const { return static_pointer_cast<F>(get_filter(F::TYPE)); }
    StreamFilterSP get_filter (const void* type) const;

    void push_ahead_filter  (const StreamFilterSP& filter, bool force = false) {
        if (!force) _check_change_filters();
        _filters.insert(_filters.begin(), filter);
    }

    void push_behind_filter (const StreamFilterSP& filter, bool force = false) {
        if (!force) _check_change_filters();
        _filters.insert(_filters.end(), filter);
    }

    Filters& filters () { return _filters; }

    optional<fh_t> fileno () const { return _impl ? impl()->fileno() : optional<fh_t>(); }

    int  recv_buffer_size () const    { return impl()->recv_buffer_size(); }
    void recv_buffer_size (int value) { impl()->recv_buffer_size(value); }
    int  send_buffer_size () const    { return impl()->send_buffer_size(); }
    void send_buffer_size (int value) { impl()->send_buffer_size(value); }

protected:
    Queue queue;

    Stream () : flags(), _wq_size(), _listener() {
        panda_log_ctor();
    }

    virtual void accept ();
    virtual void accept (const StreamSP& client);

    virtual StreamSP create_connection () = 0;

    void set_listening   () { flags |= LISTENING; }
    void set_connecting  () { flags |= CONNECTING; }
    void set_established () { flags |= ESTABLISHED; }

    std::error_code set_connect_result (bool ok) {
        flags &= ~CONNECTING;
        if (ok) {
            flags |= IN_CONNECTED|OUT_CONNECTED|ESTABLISHED;
            if (wantread()) return _read_start();
        }
        return {};
    }

    void set_wantread (bool on) { on ? (flags &= ~DONTREAD) : (flags |= DONTREAD); }
    void set_reading  (bool on) { on ? (flags |= READING) : (flags &= ~READING); }
    void set_shutting ()        { flags |= SHUTTING; }

    void clear_out_connected () {
        flags &= ~OUT_CONNECTED;
        if (!(flags & IN_CONNECTED)) flags &= ~ESTABLISHED;
    }

    void clear_in_connected () {
        flags &= ~IN_CONNECTED;
        if (!(flags & OUT_CONNECTED)) flags &= ~ESTABLISHED;
    }

    void set_shutdown (bool ok) {
        flags &= ~SHUTTING;
        if (ok) clear_out_connected();
    }

    virtual void on_reset () {}

    ~Stream ();

private:
    friend StreamFilter; friend ConnectRequest; friend WriteRequest; friend ShutdownRequest;
    friend struct DisconnectRequest; friend AcceptRequest; friend RunInOrderRequest;

    static const uint32_t LISTENING     = 1;
    static const uint32_t CONNECTING    = 2;
    static const uint32_t ESTABLISHED   = 4;  // physically connected
    static const uint32_t IN_CONNECTED  = 8;  // logically connected for reading (connected and eof not received)
    static const uint32_t OUT_CONNECTED = 16; // logically connected for writing (connected and shutdown not done)
    static const uint32_t DONTREAD      = 32; // turn off incoming events completely (eof as well)
    static const uint32_t READING       = 64;
    static const uint32_t SHUTTING      = 128;
    static const uint32_t SHUT          = 256;
    static const uint32_t IGNORE_READ   = 512; // turn off only reading (eof is enabled)

    uint32_t         flags;
    Filters          _filters;
    size_t           _wq_size;
    IStreamListener* _listener;

    backend::StreamImpl* impl () const { return static_cast<backend::StreamImpl*>(BackendHandle::impl()); }

    bool reading () const { return flags & READING; }

    template <class T, class...Args>
    void invoke_sync (T filter_method, Args&&...args) {
        if (_filters.size()) (_filters.front()->*filter_method)(std::forward<Args>(args)...);
    }

    void handle_connection          (const std::error_code&) override;
    void finalize_handle_connection (const StreamSP& client, const ErrorCode&, const AcceptRequestSP&);
    void finalize_handle_connect    (const ErrorCode&, const ConnectRequestSP&);
    void notify_on_connect          (const ErrorCode&, const ConnectRequestSP&);
    void handle_read                (string&, const std::error_code&) override;
    void finalize_handle_read       (string& buf, const ErrorCode&);
    void finalize_write             (const WriteRequestSP&);
    void finalize_handle_write      (const ErrorCode&, const WriteRequestSP&);
    void notify_on_write            (const ErrorCode&, const WriteRequestSP&);
    void handle_eof                 () override;
    void finalize_handle_eof        ();
    void finalize_shutdown          (const ShutdownRequestSP&);
    void finalize_handle_shutdown   (const ErrorCode&, const ShutdownRequestSP&);
    void notify_on_shutdown         (const ErrorCode&, const ShutdownRequestSP&);

    void _reset ();
    void _clear ();

    std::error_code _read_start ();

    void _check_change_filters () {
        if (connecting() || established()) throw Error("can't change stream filters when active");
    }
};

struct StreamRequest : Request {
protected:
    friend Stream; friend StreamFilter;
    Stream* handle;

    StreamRequest () : handle() {}

    void set (Stream* h) {
        handle = h;
        Request::set(h);
    }
};
using StreamRequestSP = iptr<StreamRequest>;


struct AcceptRequest : StreamRequest, AllocatedObject<AcceptRequest> {
    AcceptRequest (Stream* h) { set(h); }

    void exec         ()                 override {}
    void cancel       (const ErrorCode&) override { handle->queue.done(this, []{}); }
    void notify       (const ErrorCode&) override {}
    void handle_event (const ErrorCode&) override {}
};


struct ConnectRequest : StreamRequest {
    CallbackDispatcher<Stream::connect_fptr> event;

protected:
    friend Stream;
    uint64_t timeout;
    TimerSP  timer;

    ConnectRequest (Stream::connect_fn callback = {}, uint64_t timeout = 0) : timeout(timeout) {
        panda_log_ctor();
        if (callback) event.add(callback);
    }

    backend::ConnectRequestImpl* impl () {
        if (!_impl) _impl = handle->impl()->new_connect_request(this);
        return static_cast<backend::ConnectRequestImpl*>(_impl);
    }

    void exec         () override = 0;
    void handle_event (const ErrorCode&) override;
    void notify       (const ErrorCode&) override;
};


struct WriteRequest : StreamRequest, AllocatedObject<WriteRequest> {
    CallbackDispatcher<Stream::write_fptr> event;
    std::vector<string> bufs;

    WriteRequest () {}

    WriteRequest (const string& data) {
        bufs.push_back(data);
    }

    template <class It>
    WriteRequest (const It& begin, const It& end) {
        bufs.reserve(std::distance(begin, end));
        for (auto it = begin; it != end; ++it) bufs.push_back(*it);
    }

    template <class Range, typename = decltype(*std::declval<Range>().begin())>
    WriteRequest (const Range& range) {
        bufs.reserve(range.size());
        for (auto iter = range.begin(); iter != range.end(); ++iter) bufs.push_back(*iter);
    }

private:
    friend Stream;

    backend::WriteRequestImpl* impl () {
        if (!_impl) _impl = handle->impl()->new_write_request(this);
        return static_cast<backend::WriteRequestImpl*>(_impl);
    }

    void exec         () override;
    void handle_event (const ErrorCode&) override;
    void notify       (const ErrorCode&) override;
};


struct ShutdownRequest : StreamRequest {
    CallbackDispatcher<Stream::shutdown_fptr> event;

    ShutdownRequest (Stream::shutdown_fn callback = {}, uint64_t timeout = 0) : timeout(timeout) {
        panda_log_ctor();
        if (callback) event.add(callback);
    }

private:
    friend Stream;

    uint64_t timeout;
    TimerSP  timer;
    bool     timed_out = false;

    backend::ShutdownRequestImpl* impl () {
        if (!_impl) _impl = handle->impl()->new_shutdown_request(this);
        return static_cast<backend::ShutdownRequestImpl*>(_impl);
    }

    void exec         () override;
    void handle_event (const ErrorCode&) override;
    void notify       (const ErrorCode&) override;
    void cancel       (const ErrorCode& err = make_error_code(std::errc::operation_canceled)) override;
};

struct RunInOrderRequest : StreamRequest {
    Stream::run_fn code;

    template <class T>
    RunInOrderRequest (T&& _code) {
        code = std::forward<T>(_code);
    }

    void exec         () override;
    void handle_event (const ErrorCode&) override;
    void notify       (const ErrorCode&) override;
};

inline WriteRequestSP Stream::write (const string& data, write_fn callback) {
    WriteRequestSP req = new WriteRequest(data);
    if (callback) req->event.add(callback);
    write(req);
    return req;
}

template <class It>
inline WriteRequestSP Stream::write (const It& begin, const It& end, write_fn callback) {
    WriteRequestSP req = new WriteRequest(begin, end);
    if (callback) req->event.add(callback);
    write(req);
    return req;
}

template <class Range, typename>
inline WriteRequestSP Stream::write (const Range& range, write_fn callback) {
    WriteRequestSP req = new WriteRequest(range);
    if (callback) req->event.add(callback);
    write(req);
    return req;
}

inline void Stream::shutdown (shutdown_fn callback)                   { shutdown(new ShutdownRequest(callback)); }
inline void Stream::shutdown (uint64_t timeout, shutdown_fn callback) { shutdown(new ShutdownRequest(callback, timeout)); }

template <class T>
inline void Stream::run_in_order (T&& code) {
    if (!queue.size()) {
        auto param = StreamSP(this);
        code(param);
        return;
    }
    RunInOrderRequestSP req = new RunInOrderRequest(std::forward<T>(code));
    req->set(this);
    queue.push(req);
}

}}
