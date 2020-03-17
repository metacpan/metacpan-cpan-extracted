#pragma once
#include "../inc.h"
#include "forward.h"
#include <vector>
#include <exception>
#include <panda/function.h>
#include <panda/log.h>

namespace panda { namespace unievent { namespace backend {

struct LoopImpl {
    using delayed_fn = function<void()>;
    enum class Type    { LOCAL, GLOBAL, DEFAULT };
    enum class RunMode { DEFAULT, ONCE, NOWAIT };

    std::exception_ptr _exception;

    LoopImpl () {}

    virtual uint64_t now         () const = 0;
    virtual void     update_time () = 0;
    virtual bool     alive       () const = 0;

    bool run (RunMode mode) {
        bool ret = _run(mode);
        if (_exception) throw_exception();
        return ret;
    }

    virtual bool _run        (RunMode) = 0; // returns false if there are no more active handles
    virtual void stop        () = 0;
    virtual bool stopped     () const = 0;
    virtual void handle_fork () = 0;

    virtual TimerImpl*   new_timer     (ITimerImplListener*)              = 0;
    virtual PrepareImpl* new_prepare   (IPrepareImplListener*)            = 0;
    virtual CheckImpl*   new_check     (ICheckImplListener*)              = 0;
    virtual IdleImpl*    new_idle      (IIdleImplListener*)               = 0;
    virtual AsyncImpl*   new_async     (IAsyncImplListener*)              = 0;
    virtual SignalImpl*  new_signal    (ISignalImplListener*)             = 0;
    virtual PollImpl*    new_poll_sock (IPollImplListener*, sock_t sock)  = 0;
    virtual PollImpl*    new_poll_fd   (IPollImplListener*, int fd)       = 0;
    virtual UdpImpl*     new_udp       (IUdpImplListener*, int domain)    = 0;
    virtual PipeImpl*    new_pipe      (IStreamImplListener*, bool ipc)   = 0;
    virtual TcpImpl*     new_tcp       (IStreamImplListener*, int domain) = 0;
    virtual TtyImpl*     new_tty       (IStreamImplListener*, fd_t)       = 0;
    virtual WorkImpl*    new_work      (IWorkImplListener*)               = 0;
    virtual FsEventImpl* new_fs_event  (IFsEventImplListener*)            = 0;

    virtual uint64_t delay        (const delayed_fn& f, const iptr<Refcnt>& guard = {}) = 0;
    virtual void     cancel_delay (uint64_t id) noexcept = 0;

    template <class Func>
    void ltry (Func&& f) {
        try { f(); }
        catch (...) { capture_exception(); }
    }

    void capture_exception ();
    void throw_exception   ();

    virtual ~LoopImpl () {}
};

extern log::Module uebacklog;

}}}
