#pragma once
#include <panda/unievent/backend/CheckImpl.h>
#include <panda/unievent/backend/TimerImpl.h>
#include <panda/unievent/backend/PrepareImpl.h>

// SHOULD BE REFACTORED IF NEED, MOVED HERE FROM UV

void mark_load_average () {
    if (_la_tracker) _la_tracker->mark();
}

static inline void mark_load_average (LoopImpl* loop) {
    static_cast<UVLoop*>(loop)->mark_load_average();
}

// + on every action from loop
mark_load_average(h->loop);

namespace panda { namespace unievent { namespace backend { namespace uv {

static const int LA_INTERVALS = 10;

struct UVLATracker : private IPrepareImplListener, private ICheckImplListener, private ITimerImplListener {
    UVLATracker (LoopImpl* loop, uint32_t nsec) {
        prepare = loop->new_prepare(this);
        prepare->set_weak();
        prepare->start();

        check = loop->new_check(this);
        check->set_weak();
        check->start();

        timer = loop->new_timer(this);
        timer->set_weak();
        auto repeat = nsec * 1000 / LA_INTERVALS;
        timer->start(repeat, repeat);
    }

    double get () const {
        double io = 0, user = 0;
        for (auto& row : times) {
            io   += row.io;
            user += row.user;
        }

        if (io_end_time) user += now() - io_end_time;

        return user ? (double)user / (user+io) : 0.0f;
    }

    void mark () {
        if (io_end_time >= prepare_time) return;
        io_end_time = now();
        if (prepare_time) times[ti].io += io_end_time - prepare_time;
    }

    ~UVLATracker () {
        prepare->destroy();
        check->destroy();
        timer->destroy();
    }

private:
    struct TimeRow {
        double io   = 0;
        double user = 0;
    } times[LA_INTERVALS];

    size_t       ti           = 0; // current slot
    double       prepare_time = 0; // last time we felt into system IO polling
    double       io_end_time  = 0; // last time we returned from system IO polling
    PrepareImpl* prepare;
    CheckImpl*   check;
    TimerImpl*   timer;

    void handle_prepare () override {
        prepare_time = now();
        if (io_end_time) {
            times[ti].user += prepare_time - io_end_time;
            io_end_time = 0;
        }
    }

    void handle_check () override {
        mark();
    }

    // rotate stat times
    void handle_timer () override {
        if (++ti == LA_INTERVALS) ti = 0;
        times[ti].io   = 0;
        times[ti].user = 0;
    }

    static double now () {
        return (double)panda::unievent::hrtime() / 1000000000;
    }
};

}}}}
