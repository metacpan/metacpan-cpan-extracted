#pragma once
#include "LoopImpl.h"
#include <panda/refcnt.h>

namespace panda { namespace unievent { namespace backend {

struct Delayer {
    using delayed_fn = LoopImpl::delayed_fn;

    Delayer (LoopImpl* l) : loop(l), lastid(0) {}

    uint64_t add (const delayed_fn& f, const iptr<Refcnt>& guard = {}) {
        callbacks.push_back({++lastid, f, guard});
        return lastid;
    }

    bool cancel (uint64_t id) noexcept {
        return _delayer_cancel(callbacks, id) || _delayer_cancel(reserve, id);
    }

protected:
    struct Callback {
        size_t            id;
        delayed_fn        cb;
        weak_iptr<Refcnt> guard;
    };
    using Callbacks = std::vector<Callback>;

    LoopImpl* loop;
    Callbacks callbacks;
    Callbacks reserve;
    size_t    lastid;

    void call () {
        assert(!reserve.size());
        std::swap(callbacks, reserve);

        auto sz = reserve.size();
        size_t i = 0;

        scope_guard([&]{
            while (i < sz) {
                auto& row = reserve[i++]; // if exception is thrown, "i" must be the next unprocessed item
                if (!row.cb || (row.guard.weak_count() && !row.guard)) continue; // skip callbacks with guard destroyed
                auto cb = row.cb;
                panda_mlog_debug(uebacklog, "on delay");
                cb();
            }
        }, [&] { // return remaining callbacks to pool (if exception is thrown)
            if (i < sz) callbacks.insert(callbacks.begin(), reserve.begin() + (sz-i), reserve.end());
            reserve.clear();
        });
    }

private:
    static bool _delayer_cancel (Callbacks& list, uint64_t id) noexcept {
        if (!list.size()) return false;
        if (id < list.front().id) return false;
        size_t idx = id - list.front().id;
        if (idx >= list.size()) return false;
        list[idx].cb = nullptr;
        return true;
    }
};

}}}
