#pragma once
#include "inc.h"
#include "BackendHandle.h"
#include <vector>
#include <panda/string.h>
#include <panda/refcnt.h>
#include <panda/intrusive_chain.h>

namespace panda { namespace unievent {

struct Request;
using RequestSP = iptr<Request>;

struct Request : IntrusiveChainNode<RequestSP>, Refcnt, protected backend::IRequestListener {
    template <class Func>
    void delay (Func&& f) {
        delay_cancel();
        _delay_id = _handle->loop()->delay(f);
    }

    void delay_cancel () {
        if (_delay_id) {
            _handle->loop()->cancel_delay(_delay_id);
            _delay_id = 0;
        }
    }

protected:
    friend struct Queue; friend Stream; friend StreamFilter;
    using RequestImpl = backend::RequestImpl;

    RequestImpl*  _impl;
    Request*      parent;
    RequestSP     subreq;
    StreamFilter* last_filter;

    Request () : _impl(), parent(), last_filter(), _delay_id(0), async() {}

    void set (BackendHandle* h) {
        _handle = h;
        async = false;
    }

    virtual void exec () = 0;

    /* this is private API, as there is no way of stopping request inside backend in general case. usually called during reset()
       If called separately by user, will only do "visible" cancellation (user callback being called with canceled status),
       but backend will continue to run the request and the next request will only be started afterwards */
    virtual void cancel (const ErrorCode& err) {
        if (subreq) return subreq->cancel(err);
        handle_event(err);
    }

    // just calls user callbacks with some status
    virtual void notify (const ErrorCode&) = 0;

    // detach from backend. Backend won't call the callback when request is completed (if it wasn't completed already)
    void finish_exec () {
        delay_cancel();
        if (_impl) {
            _impl->destroy();
            _impl = nullptr;
        }
    }

    ~Request () {
        if (subreq) subreq->finish_exec(); // stop sub-request (quiet) if filter forgets parent request
        assert(!_impl);
    }

private:
    BackendHandleSP _handle;
    uint64_t        _delay_id;
    bool            async;
};

}}
