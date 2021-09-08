#pragma once
#include "inc.h"
#include "UVDelayer.h"
#include <panda/unievent/backend/LoopImpl.h>
#include <panda/unievent/backend/LAMetrics.h>

namespace panda { namespace unievent { namespace backend { namespace uv {

struct UVLoop : LoopImpl, IMetricsProvider {
    uv_loop_t* uvloop;

    UVLoop (Type type) : _delayer(this), _running(false) {
        switch (type) {
            case Type::GLOBAL:
                uvloop = uv_default_loop();
                if (!uvloop) throw Error("[UVLoop] uv_default_loop() couldn't create a loop");
                break;
            case Type::LOCAL:
            case Type::DEFAULT:
                uvloop = &_uvloop_body;
                int err = uv_loop_init(uvloop);
                if (err) throw Error(uvx_error(err));
        }
        uvloop->data = this;
    }

    ~UVLoop () {
        _delayer.destroy();
        _la_metrics.reset();
        run(RunMode::NOWAIT); // finish all closing handles
        run(RunMode::NOWAIT); // finish all closing handles
        int err = uv_loop_close(uvloop);
        assert(!err); // unievent should have closed all handles
    }

    uint64_t now         () const override { return uv_now(uvloop); }
    void     update_time ()       override { uv_update_time(uvloop); }
    bool     alive       () const override { return uv_loop_alive(uvloop) != 0; }

    bool _run (RunMode mode) override {
        struct AutoResetFlag {
            bool& flag;
            AutoResetFlag(bool& flag) : flag(flag) {flag = true;}
            ~AutoResetFlag() {flag = false;}
        };

        if (_running) {
            throw panda::exception("Loop::run recursion");
        }

        AutoResetFlag autoflag(_running);
        uvloop->stop_flag = 0; // fix bug when UV immediately exits run() if stop() was called before run()
        switch (mode) {
            case RunMode::DEFAULT      : return uv_run(uvloop, UV_RUN_DEFAULT);
            case RunMode::ONCE         : return uv_run(uvloop, UV_RUN_ONCE);
            case RunMode::NOWAIT       : return uv_run(uvloop, UV_RUN_NOWAIT);
            case RunMode::NOWAIT_FORCE : {
                uvloop->active_handles++;
                auto ret = uv_run(uvloop, UV_RUN_NOWAIT);
                uvloop->active_handles--;
                return ret;
            }
        }
        assert(0);
    }

    void stop () override {
        uv_stop(uvloop);
    }

    bool stopped () const override {
        return uvloop->stop_flag;
    }

    excepted<void, std::error_code> handle_fork () override {
        int err = uv_loop_fork(uvloop);
        if (err) return make_unexpected(uvx_error(err));
        return {};
    }

    TimerImpl*   new_timer     (ITimerImplListener*)                      override;
    PrepareImpl* new_prepare   (IPrepareImplListener*)                    override;
    CheckImpl*   new_check     (ICheckImplListener*)                      override;
    IdleImpl*    new_idle      (IIdleImplListener*)                       override;
    AsyncImpl*   new_async     (IAsyncImplListener*)                      override;
    SignalImpl*  new_signal    (ISignalImplListener*)                     override;
    PollImpl*    new_poll_sock (IPollImplListener*, sock_t sock)          override;
    PollImpl*    new_poll_fd   (IPollImplListener*, int fd)               override;
    UdpImpl*     new_udp       (IUdpImplListener*, int domain, int flags) override;
    PipeImpl*    new_pipe      (IStreamImplListener*, bool ipc)           override;
    TcpImpl*     new_tcp       (IStreamImplListener*, int domain)         override;
    TtyImpl*     new_tty       (IStreamImplListener*, fd_t)               override;
    WorkImpl*    new_work      (IWorkImplListener*)                       override;
    FsEventImpl* new_fs_event  (IFsEventImplListener*)                    override;

    uint64_t delay        (const delayed_fn& f, const iptr<Refcnt>& guard = {}) override { return _delayer.add(f, guard); }
    void     cancel_delay (uint64_t id)                                noexcept override { _delayer.cancel(id); }

    void track_load_average (uint32_t nsec) override {
        _la_metrics.reset();
        if (nsec) {
            uvx_strict(uv_loop_configure(uvloop, UV_METRICS_IDLE_TIME));
            _la_metrics = std::make_unique<LAMetrics>(this, this, nsec);
        }
    }

    double get_load_average () const override {
        return _la_metrics ? _la_metrics->get() : 0.0f;
    }

    uint64_t get_metrics_idle_time () const override {
        return uv_metrics_idle_time(uvloop);
    }

    void* get() override {return uvloop;}

private:
    uv_loop_t    _uvloop_body;
    UVDelayer    _delayer;
    LAMetricsPtr _la_metrics;
    bool         _running;
};


}}}}
