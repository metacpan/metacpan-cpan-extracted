#pragma once
#include "Stream.h"
#include "backend/PipeImpl.h"

namespace panda { namespace unievent {

struct IPipeListener     : IStreamListener     {};
struct IPipeSelfListener : IStreamSelfListener {};

struct Pipe : virtual Stream {
    static const HandleType TYPE;

    Pipe (Loop* loop = Loop::default_loop(), bool ipc = false) : _ipc(ipc) {
        panda_log_ctor();
        _init(loop, loop->impl()->new_pipe(this, ipc));
    }

    Pipe (bool ipc) : Pipe(Loop::default_loop(), ipc) {}

    ~Pipe () { panda_log_dtor(); }

    const HandleType& type () const override;

    bool ipc () const { return _ipc; }

    virtual void open    (fd_t file, Ownership ownership = Ownership::TRANSFER, bool connected = false);
    virtual void bind    (string_view name);
    virtual void connect (const PipeConnectRequestSP& req);
    /*INL*/ void connect (const string& name, connect_fn callback = nullptr);

    virtual void pending_instances (int count);

    optional<string> sockname () const { return impl()->sockname(); }
    optional<string> peername () const { return impl()->peername(); }

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


inline void Pipe::connect (const string& name, connect_fn callback) {
    connect(new PipeConnectRequest(name, callback));
}


}}
