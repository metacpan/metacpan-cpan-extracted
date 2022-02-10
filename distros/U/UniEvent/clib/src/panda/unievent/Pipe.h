#pragma once
#include "Stream.h"
#include "backend/PipeImpl.h"

namespace panda { namespace unievent {

struct IPipeListener     : IStreamListener     {};
struct IPipeSelfListener : IStreamSelfListener {};

struct Pipe : virtual Stream {
    using Mode = backend::PipeImpl::Mode;

    static const HandleType TYPE;

    Pipe (Loop* loop = Loop::default_loop(), bool ipc = false) : _ipc(ipc) {
        panda_log_ctor();
        _init(loop, loop->impl()->new_pipe(this, ipc));
    }

    Pipe (bool ipc) : Pipe(Loop::default_loop(), ipc) {}

    ~Pipe () { panda_log_dtor(); }

    const HandleType& type () const override;

    bool ipc () const { return _ipc; }

    virtual excepted<void, ErrorCode> open (fd_t, int mode, Ownership = Ownership::TRANSFER);
    virtual excepted<void, ErrorCode> bind (string_view name);

    virtual PipeConnectRequestSP connect (const PipeConnectRequestSP& req);
    /*INL*/ PipeConnectRequestSP connect (const string& name, connect_fn callback = nullptr);

    virtual void pending_instances (int count);
    virtual int  pending_count     () const;

    excepted<string, ErrorCode> sockname () const { return handle_fd_excepted(impl()->sockname()); }
    excepted<string, ErrorCode> peername () const { return handle_fd_excepted(impl()->peername()); }
    
    excepted<net::SockAddr, ErrorCode> sockaddr () const override;
    excepted<net::SockAddr, ErrorCode> peeraddr () const override;

    virtual excepted<void, ErrorCode> chmod (int mode);

    static excepted<std::pair<PipeSP,PipeSP>, ErrorCode> pair (const LoopSP& = Loop::default_loop());
    static excepted<std::pair<PipeSP,PipeSP>, ErrorCode> pair (const PipeSP&, const PipeSP&);

protected:
    StreamSP create_connection () override;

private:
    friend PipeConnectRequest;

    bool _ipc;

    backend::PipeImpl* impl () const { return static_cast<backend::PipeImpl*>(BackendHandle::impl()); }

    HandleImpl* new_impl () override;
};


struct PipeConnectRequest : ConnectRequest, AllocatedObject<PipeConnectRequest> {
    string name;

    PipeConnectRequest (const string& name, Stream::connect_fn callback = nullptr)
        : ConnectRequest(callback), name(name) {}

private:
    friend Pipe; friend StreamFilter;
    Pipe* handle;

    void set (Pipe* h) {
        handle = h;
        ConnectRequest::set(h);
    }

    void exec             () override;
    void finalize_connect ();
};


inline PipeConnectRequestSP Pipe::connect (const string& name, connect_fn callback) {
    PipeConnectRequestSP connect_request = new PipeConnectRequest(name, callback);
    return connect(connect_request);
}


}}
