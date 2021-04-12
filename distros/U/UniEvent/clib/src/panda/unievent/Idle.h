#pragma once
#include "BackendHandle.h"
#include "backend/IdleImpl.h"

namespace panda { namespace unievent {

struct IIdleListener {
    virtual void on_idle (const IdleSP&) = 0;
};

struct IIdleSelfListener : IIdleListener {
    virtual void on_idle () = 0;
    void on_idle (const IdleSP&) override { on_idle(); }
};

struct Idle : virtual BackendHandle, private backend::IIdleImplListener {
    using idle_fptr = void(const IdleSP&);
    using idle_fn   = function<idle_fptr>;
    
    static const HandleType TYPE;

    CallbackDispatcher<idle_fptr> event;

    static IdleSP create (const idle_fn&, const LoopSP& = Loop::default_loop());

    Idle (const LoopSP& loop = Loop::default_loop()) : _listener() {
        _init(loop, loop->impl()->new_idle(this));
    }

    const HandleType& type () const override;

    IIdleListener* event_listener () const           { return _listener; }
    void           event_listener (IIdleListener* l) { _listener = l; }

    virtual void start (const idle_fn& = {});
    virtual void stop  ();

    void reset () override;
    void clear () override;

    void call_now () { handle_idle(); }

private:
    IIdleListener* _listener;

    void handle_idle () override;

    backend::IdleImpl* impl () const { return static_cast<backend::IdleImpl*>(_impl); }
};

}}
