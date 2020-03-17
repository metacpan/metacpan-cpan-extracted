#pragma once
#include "Fs.h"
#include "Timer.h"

namespace panda { namespace unievent {

struct IFsPollListener {
    virtual void on_fs_poll  (const FsPollSP&, const Fs::FStat& prev, const Fs::FStat& cur, const std::error_code&) = 0;
    virtual void on_fs_start (const FsPollSP&, const Fs::FStat& stat, const std::error_code&) = 0;
};

struct IFsPollSelfListener : IFsPollListener {
    virtual void on_fs_poll  (const Fs::FStat& prev, const Fs::FStat& cur, const std::error_code&) = 0;
    virtual void on_fs_start (const Fs::FStat& stat, const std::error_code&) = 0;
    void on_fs_poll  (const FsPollSP&, const Fs::FStat& prev, const Fs::FStat& cur, const std::error_code& err) override { on_fs_poll(prev, cur, err); }
    void on_fs_start (const FsPollSP&, const Fs::FStat& stat, const std::error_code& err)                       override { on_fs_start(stat, err); }
};

struct FsPoll : virtual Handle {
    using fs_poll_fptr  = void(const FsPollSP&, const Fs::FStat& prev, const Fs::FStat& cur, const std::error_code&);
    using fs_poll_fn    = function<fs_poll_fptr>;
    using fs_start_fptr = void(const FsPollSP&, const Fs::FStat& stat, const std::error_code&);
    using fs_start_fn   = function<fs_start_fptr>;

    static const HandleType TYPE;

    CallbackDispatcher<fs_poll_fptr>  poll_event;
    CallbackDispatcher<fs_start_fptr> start_event;

    FsPoll (const LoopSP& loop = Loop::default_loop());

    const HandleType& type () const override;

    IFsPollListener* event_listener () const             { return _listener; }
    void             event_listener (IFsPollListener* l) { _listener = l; }

    const string& path () const { return _path; }

    bool active () const override { return timer->active(); }

    void set_weak   () override { timer->weak(true); }
    void unset_weak () override { timer->weak(false); }

    virtual void start (string_view path, unsigned int interval = 1000, const fs_poll_fn& callback = {});
    virtual void stop  ();

    void reset () override;
    void clear () override;

private:
    TimerSP           timer;
    Fs::RequestSP     fsr;
    string            _path;
    weak_iptr<FsPoll> wself;
    Fs::FStat         prev;
    std::error_code   prev_err;
    bool              fetched;
    IFsPollListener*  _listener;

    void do_stat        ();
    void notify         (const Fs::FStat&, const Fs::FStat&, const std::error_code&);
    void initial_notify (const Fs::FStat&, const std::error_code&);
};

}}
