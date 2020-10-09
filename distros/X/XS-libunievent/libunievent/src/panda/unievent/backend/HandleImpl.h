#pragma once
#include "../error.h"
#include "LoopImpl.h"
#include <panda/string.h>
#include <panda/optional.h>

namespace panda { namespace unievent { namespace backend {

struct HandleImpl {
    static constexpr const size_t MIN_ALLOC_SIZE = 1024;

    uint64_t  id;
    LoopImpl* loop;

    HandleImpl (LoopImpl* loop) : id(++last_id), loop(loop) {}

    virtual bool active () const = 0;

    virtual void set_weak   () = 0;
    virtual void unset_weak () = 0;

    template <class Func>
    void ltry (Func&& f) { loop->ltry(f); }

    virtual void destroy () noexcept = 0;

    virtual ~HandleImpl () {}

    template <class T>
    static string buf_alloc (size_t size, T allocator) noexcept {
        if (size < MIN_ALLOC_SIZE) size = MIN_ALLOC_SIZE;
        return allocator->buf_alloc(size);
    }

private:
    static uint64_t last_id;

};

struct IRequestListener {
    virtual void handle_event (const ErrorCode&) = 0;
};

struct RequestImpl {
    HandleImpl*       handle;
    IRequestListener* listener;

    RequestImpl (HandleImpl* h, IRequestListener* l) : handle(h), listener(l) { panda_log_ctor(); }

    void handle_event (const std::error_code& err) noexcept {
        handle->loop->ltry([&]{ listener->handle_event(err); });
    }

    virtual void destroy () noexcept = 0;
    virtual ~RequestImpl () { panda_log_dtor(); }
};

}}}
