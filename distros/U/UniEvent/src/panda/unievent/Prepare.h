#pragma once
#include "BackendHandle.h"
#include "backend/PrepareImpl.h"

namespace panda { namespace unievent {

struct IPrepareListener {
    virtual void on_prepare (const PrepareSP&) = 0;
};

struct IPrepareSelfListener : IPrepareListener {
    virtual void on_prepare () = 0;
    void on_prepare (const PrepareSP&) override { on_prepare(); }
};

struct Prepare : virtual BackendHandle, private backend::IPrepareImplListener {
    using prepare_fptr = void(const PrepareSP&);
    using prepare_fn   = function<prepare_fptr>;

    static const HandleType TYPE;

    CallbackDispatcher<prepare_fptr> event;

    Prepare (const LoopSP& loop = Loop::default_loop()) : _listener() {
        _init(loop, loop->impl()->new_prepare(this));
    }

    const HandleType& type () const override;

    IPrepareListener* event_listener () const              { return _listener; }
    void              event_listener (IPrepareListener* l) { _listener = l; }

    virtual void start (prepare_fn callback = nullptr);
    virtual void stop  ();

    void reset () override;
    void clear () override;

    void call_now () { handle_prepare(); }

private:
    IPrepareListener* _listener;

    void handle_prepare () override;

    backend::PrepareImpl* impl () const { return static_cast<backend::PrepareImpl*>(_impl); }
};

}}
