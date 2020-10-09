#include "StreamFilter.h"
#include "Tcp.h"
#include "Pipe.h"

using namespace panda::unievent;

#define INVOKE(f, fm, hm, ...) do { \
    if (f) f->fm(__VA_ARGS__);      \
    else   handle->hm(__VA_ARGS__); \
} while(0)

StreamFilter::StreamFilter (Stream* h, const void* type, double priority) : handle(h), _type(type), _priority(priority) {}

std::error_code StreamFilter::read_start () {
    return handle->_read_start();
}

void StreamFilter::read_stop () {
    if (!handle->wantread()) handle->read_stop();
}

void StreamFilter::subreq_tcp_connect (const StreamRequestSP& parent, const TcpConnectRequestSP& req) {
    parent->subreq   = req;
    req->parent      = parent;
    req->last_filter = this;
    req->set(panda::dyn_cast<Tcp*>(handle)); // TODO: find a better way
    NextFilter::tcp_connect(req);
}

void StreamFilter::subreq_pipe_connect (const StreamRequestSP& parent, const PipeConnectRequestSP& req) {
    parent->subreq   = req;
    req->parent      = parent;
    req->last_filter = this;
    req->set(panda::dyn_cast<Pipe*>(handle)); // TODO: find a better way
    NextFilter::pipe_connect(req);
}

void StreamFilter::subreq_write (const StreamRequestSP& parent, const WriteRequestSP& req) {
    parent->subreq   = req;
    req->parent      = parent;
    req->last_filter = this;
    req->set(handle);
    NextFilter::write(req);
}

void StreamFilter::subreq_done (const StreamRequestSP& req) {
    assert(!req->subreq);
    req->finish_exec();
    req->parent->subreq = nullptr;
    req->parent         = nullptr;
    req->last_filter    = nullptr;
}

void StreamFilter::handle_connection (const StreamSP& client, const ErrorCode& err, const AcceptRequestSP& req) {
    INVOKE(prev, handle_connection, finalize_handle_connection, client, err, req);
}

void StreamFilter::tcp_connect (const TcpConnectRequestSP& req) {
    if (next) {
        req->last_filter = next;
        next->tcp_connect(req);
    }
    else req->finalize_connect();
}

void StreamFilter::pipe_connect (const PipeConnectRequestSP& req) {
    if (next) {
        req->last_filter = next;
        next->pipe_connect(req);
    }
    else req->finalize_connect();
}

void StreamFilter::handle_connect (const ErrorCode& err, const ConnectRequestSP& req) {
    INVOKE(prev, handle_connect, finalize_handle_connect, err, req);
}

void StreamFilter::handle_read (string& buf, const ErrorCode& err) {
    INVOKE(prev, handle_read, finalize_handle_read, buf, err);
}

void StreamFilter::write (const WriteRequestSP& req) {
    if (next) req->last_filter = next;
    INVOKE(next, write, finalize_write, req);
}

void StreamFilter::handle_write (const ErrorCode& err, const WriteRequestSP& req) {
    INVOKE(prev, handle_write, finalize_handle_write, err, req);
}

void StreamFilter::handle_eof () {
    INVOKE(prev, handle_eof, finalize_handle_eof);
}

void StreamFilter::shutdown (const ShutdownRequestSP& req) {
    if (next) req->last_filter = next;
    INVOKE(next, shutdown, finalize_shutdown, req);
}

void StreamFilter::handle_shutdown (const ErrorCode& err, const ShutdownRequestSP& req) {
    INVOKE(prev, handle_shutdown, finalize_handle_shutdown, err, req);
}
