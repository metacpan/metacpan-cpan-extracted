#pragma once
#include "HandleImpl.h"
#include <panda/expected.h>
#include <panda/net/sockaddr.h>

#undef fileno

namespace panda { namespace unievent { namespace backend {

struct IStreamImplListener {
    virtual string buf_alloc         (size_t cap) = 0;
    virtual void   handle_connection (const std::error_code&) = 0;
    virtual void   handle_read       (string&, const std::error_code&) = 0;
    virtual void   handle_eof        () = 0;
};

struct ConnectRequestImpl  : RequestImpl { using RequestImpl::RequestImpl; };
struct WriteRequestImpl    : RequestImpl { using RequestImpl::RequestImpl; };
struct ShutdownRequestImpl : RequestImpl { using RequestImpl::RequestImpl; };

struct StreamImpl : HandleImpl {
    IStreamImplListener* listener;

    StreamImpl (LoopImpl* loop, IStreamImplListener* lst) : HandleImpl(loop), listener(lst) {}

    virtual ConnectRequestImpl*  new_connect_request  (IRequestListener*) = 0;
    virtual WriteRequestImpl*    new_write_request    (IRequestListener*) = 0;
    virtual ShutdownRequestImpl* new_shutdown_request (IRequestListener*) = 0;

    string buf_alloc (size_t size) noexcept { return HandleImpl::buf_alloc(size, listener); }

    virtual std::error_code listen     (int backlog) = 0;
    virtual std::error_code accept     (StreamImpl* client) = 0;
    virtual std::error_code read_start () = 0;
    virtual void            read_stop  () = 0;
    virtual std::error_code write      (const std::vector<string>& bufs, WriteRequestImpl*) = 0;
    virtual void            shutdown   (ShutdownRequestImpl*) = 0;

    virtual optional<fh_t> fileno () const = 0;

    virtual int  recv_buffer_size () const    = 0;
    virtual void recv_buffer_size (int value) = 0;
    virtual int  send_buffer_size () const    = 0;
    virtual void send_buffer_size (int value) = 0;

    virtual bool   readable         () const noexcept = 0;
    virtual bool   writable         () const noexcept = 0;
    virtual size_t write_queue_size () const noexcept = 0;

    void handle_connection (const std::error_code& err) noexcept {
        ltry([&]{ listener->handle_connection(err); });
    }

    void handle_read (string& buf, const std::error_code& err) noexcept {
        ltry([&]{ listener->handle_read(buf, err); });
    }

    void handle_eof () noexcept {
        ltry([&]{ listener->handle_eof(); });
    }
};

}}}
