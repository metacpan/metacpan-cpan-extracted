#pragma once
#include "Loop.h"
#include "backend/WorkImpl.h"
#include <panda/memory.h>

namespace panda { namespace unievent {

struct IWorkListener {
    virtual void on_work       (Work*)                                 = 0;
    virtual void on_after_work (const WorkSP&, const std::error_code&) = 0;
};

struct IWorkSelfListener : IWorkListener {
    virtual void on_work       ()                       = 0;
    virtual void on_after_work (const std::error_code&) = 0;

    void on_work       (Work*)                                     override { on_work(); }
    void on_after_work (const WorkSP&, const std::error_code& err) override { on_after_work(err); }
};

struct Work : Refcnt, IntrusiveChainNode<WorkSP>, AllocatedObject<Work>, private backend::IWorkImplListener {
    using WorkImpl      = backend::WorkImpl;
    using work_fn       = function<void(Work*)>;
    using after_work_fn = function<void(const WorkSP&, const std::error_code&)>;

    work_fn       work_cb;
    after_work_fn after_work_cb;

    static WorkSP queue (const work_fn&, const after_work_fn&, const LoopSP& = Loop::default_loop());

    Work (const LoopSP& loop = Loop::default_loop()) : _loop(loop), _impl(), _listener(), _active() {}

    const LoopSP& loop () const { return _loop; }

    IWorkListener* event_listener () const           { return _listener; }
    void           event_listener (IWorkListener* l) { _listener = l; }

    virtual void queue  ();
    virtual bool cancel ();

    ~Work () {
        if (_impl) assert(_impl->destroy());
    }

private:
    LoopSP         _loop;
    WorkImpl*      _impl;
    IWorkListener* _listener;
    bool           _active;

    void handle_work       () override;
    void handle_after_work (const std::error_code& err) override;

    WorkImpl* impl () {
        if (!_impl) _impl = _loop->impl()->new_work(this);
        return _impl;
    }
};

}}
