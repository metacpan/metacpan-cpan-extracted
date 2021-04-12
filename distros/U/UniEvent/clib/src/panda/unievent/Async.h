#pragma once
#include "BackendHandle.h"
#include "backend/AsyncImpl.h"

namespace panda { namespace unievent {

struct IAsyncListener {
    virtual void on_async (const AsyncSP&) = 0;
};

struct IAsyncSelfListener : IAsyncListener {
    virtual void on_async () = 0;
    void on_async (const AsyncSP&) override { on_async(); }
};

struct Async : virtual BackendHandle, private backend::IAsyncImplListener {
    using async_fptr = void(const AsyncSP&);
    using async_fn   = function<async_fptr>;
    
    static const HandleType TYPE;

    CallbackDispatcher<async_fptr> event;

    Async (const LoopSP& loop = Loop::default_loop()) : _listener() {
        _init(loop, loop->impl()->new_async(this));
    }

    Async (async_fn cb, const LoopSP& loop = Loop::default_loop()) : Async(loop) {
        if (cb) event.add(cb);
    }

    const HandleType& type () const override;

    IAsyncListener* event_listener () const            { return _listener; }
    void            event_listener (IAsyncListener* l) { _listener = l; }

    virtual void send ();

    void reset () override {}
    void clear () override;

    void call_now () { handle_async(); }

private:
    IAsyncListener* _listener;

    void handle_async () override;

    backend::AsyncImpl* impl () const { return static_cast<backend::AsyncImpl*>(_impl); }
};

}}
