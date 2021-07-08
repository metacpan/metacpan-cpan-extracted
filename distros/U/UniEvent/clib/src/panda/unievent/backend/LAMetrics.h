#pragma once
#include <memory>
#include <panda/unievent/backend/LoopImpl.h>
#include <panda/unievent/backend/TimerImpl.h>

namespace panda { namespace unievent { namespace backend {

static const int LA_INTERVALS = 10;

struct IMetricsProvider {
    virtual uint64_t get_metrics_idle_time () const = 0;
};

struct LAMetrics : private ITimerImplListener {
    LAMetrics (LoopImpl* loop, IMetricsProvider* provider, uint32_t nsec) : provider(provider) {
        timer = loop->new_timer(this);
        timer->set_weak();
        auto repeat = nsec * 1000 / LA_INTERVALS;
        timer->start(repeat, repeat);

        times[0].idle = provider->get_metrics_idle_time();
        times[0].time = now();
        for (auto& row : times) {
            row.idle = times[0].idle;
            row.time = times[0].time;
        }
    }

    double get () const {
        auto first = next_idx();
        auto idle  = provider->get_metrics_idle_time() - times[first].idle;
        auto total = now() - times[first].time;
        return total ? (double)(total - idle) / total : 0.0f;
    }

    virtual ~LAMetrics () {
        timer->destroy();
    }

private:
    struct TimeRow {
        uint64_t idle = 0;
        uint64_t time = 0;
    } times[LA_INTERVALS];

    IMetricsProvider* provider;
    size_t            ti = 0;   // current slot
    TimerImpl*        timer;

    // rotate stat times
    void handle_timer () override {
        ti = next_idx();
        times[ti].idle = provider->get_metrics_idle_time();
        times[ti].time = now();
    }

    size_t next_idx () const {
        return ti == LA_INTERVALS - 1 ? 0 : ti + 1;
    }

    static inline uint64_t now () {
        return panda::unievent::hrtime();
    }
};

using LAMetricsPtr = std::unique_ptr<LAMetrics>;

}}}
