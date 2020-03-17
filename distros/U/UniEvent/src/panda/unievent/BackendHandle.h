#pragma once
#include "Handle.h"
#include "backend/HandleImpl.h"

namespace panda { namespace unievent {

struct BackendHandle : Handle {
    using HandleImpl = backend::HandleImpl;

    bool active () const override { return _impl ? _impl->active() : false; }

    void reset () override = 0;
    void clear () override = 0;

protected:
    mutable HandleImpl* _impl;

    BackendHandle () : _impl() { _ECTOR(); }

    ~BackendHandle () {
        if (_impl) _impl->destroy();
    }

    void _init (const LoopSP& loop, HandleImpl* impl = nullptr) {
        _impl = impl;
        Handle::_init(loop);
    }

    void set_weak   () override { impl()->set_weak(); }
    void unset_weak () override { impl()->unset_weak(); }

    virtual HandleImpl* new_impl () { abort(); }

    HandleImpl* impl () const {
        if (!_impl) {
            _impl = const_cast<BackendHandle*>(this)->new_impl();
            if (weak()) _impl->set_weak(); // preserve weak
        }
        return _impl;
    }
};
using BackendHandleSP = iptr<BackendHandle>;

inline void BackendHandle::reset () {
    if (!_impl) return;
    _impl->destroy();
    _impl = nullptr;
}

inline void BackendHandle::clear () {
    if (!_impl) return;
    _impl->destroy();
    _impl = nullptr;
    clear_weak();
}

}}
