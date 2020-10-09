#pragma once
#include "BackendHandle.h"
#include <signal.h>
#include "backend/SignalImpl.h"

namespace panda { namespace unievent {

struct ISignalListener {
    virtual void on_signal (const SignalSP&, int signum) = 0;
};

struct ISignalSelfListener : ISignalListener {
    virtual void on_signal (int signum) = 0;
    void on_signal (const SignalSP&, int signum) override { on_signal(signum); }
};

struct Signal : virtual BackendHandle, private backend::ISignalImplListener {
    using signal_fptr = void(const SignalSP& handle, int signum);
    using signal_fn = function<signal_fptr>;

    static const HandleType TYPE;

    CallbackDispatcher<signal_fptr> event;

    Signal (const LoopSP& loop = Loop::default_loop()) : _listener() {
        _init(loop, loop->impl()->new_signal(this));
    }

    const HandleType& type () const override;

    ISignalListener* event_listener () const             { return _listener; }
    void             event_listener (ISignalListener* l) { _listener = l; }

    int           signum  () const { return impl()->signum(); }
    const string& signame () const { return signame(signum()); }

    virtual void start (int signum, signal_fn callback = {});
    virtual void once  (int signum, signal_fn callback = {});
    virtual void stop  ();

    void reset () override;
    void clear () override;

    void call_now (int signum) { handle_signal(signum); }

    static SignalSP watch (int signum, signal_fn cb, const LoopSP& loop = Loop::default_loop());

    static const string& signame (int signum);

private:
    ISignalListener* _listener;

    void handle_signal (int signum) override;

    backend::SignalImpl* impl () const { return static_cast<backend::SignalImpl*>(_impl); }
};

}}
