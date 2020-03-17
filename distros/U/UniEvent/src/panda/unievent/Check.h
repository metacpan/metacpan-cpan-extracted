#pragma once
#include "BackendHandle.h"
#include "backend/CheckImpl.h"

namespace panda { namespace unievent {

struct ICheckListener {
    virtual void on_check (const CheckSP&) = 0;
};

struct ICheckSelfListener : ICheckListener {
    virtual void on_check () = 0;
    void on_check (const CheckSP&) override { on_check(); }
};

struct Check : virtual BackendHandle, private backend::ICheckImplListener {
    using check_fptr = void(const CheckSP&);
    using check_fn   = function<check_fptr>;

    static const HandleType TYPE;

    CallbackDispatcher<check_fptr> event;

    Check (const LoopSP& loop = Loop::default_loop()) : _listener() {
        _init(loop, loop->impl()->new_check(this));
    }

    const HandleType& type () const override;

    ICheckListener* event_listener () const            { return _listener; }
    void            event_listener (ICheckListener* l) { _listener = l; }

    virtual void start (check_fn callback = nullptr);
    virtual void stop  ();

    void reset () override;
    void clear () override;

    void call_now () { handle_check(); }

private:
    ICheckListener* _listener;

    void handle_check () override;

    backend::CheckImpl* impl () const { return static_cast<backend::CheckImpl*>(_impl); }
};

}}
