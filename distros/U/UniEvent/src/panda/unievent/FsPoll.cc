#include "FsPoll.h"
using namespace panda::unievent;

const HandleType FsPoll::TYPE("fs_poll");

FsPoll::FsPoll (const LoopSP& loop) : prev(), fetched(), _listener() {
    _init(loop);
    fsr   = new Fs::Request(loop);
    timer = new Timer(loop);
    timer->event.add([this](auto) {
        if (fsr->busy()) return; // filesystem has not yet completed the request -> skip one cycle
        this->do_stat();
    });
}

const HandleType& FsPoll::type () const {
    return TYPE;
}

void FsPoll::start (string_view path, unsigned int interval, const fs_poll_fn& callback) {
    if (timer->active()) throw Error("cannot start FsPoll: it is already active");
    if (callback) poll_event.add(callback);
    _path = string(path);
    timer->start(interval);
    if (fsr->busy()) fsr = new Fs::Request(loop()); // previous fspoll task has not yet been completed -> forget FSR and create new one
    do_stat();
}

void FsPoll::stop () {
    if (!timer->active()) return;
    timer->stop();
    prev = Fs::FStat();
    // if cancellation possible it will call callback (which we will ignore)
    // otherwise nothing will happen and fsr will remain busy (and if it is not complete by the next start(), we will change fsr
    fsr->cancel();
    fetched = false;
}

void FsPoll::do_stat () {
    if (!wself) wself = FsPollSP(this);
    auto wp = wself;
    fsr->stat(_path, [this, wp](auto& stat, auto& err, const Fs::RequestSP& req) {
        auto p = wp.lock();
        if (!p) return; // check if <this> is dead by the moment, after this line we can safely use 'this'
        if (!timer->active() || fsr != req) return; // ongoing previous result -> ignore

        opt<Fs::FStat> prev_opt, stat_opt;
        if (!prev_err) prev_opt = prev;
        if (!err) stat_opt = stat;

        if (err) {
            if (err != prev_err) {
                prev_err = err;
                // accessing <stat> is UB
                if (!fetched) this->initial_notify(stat_opt, err);
                this->notify(prev_opt, stat_opt, err);
            }
        }
        else if (!fetched || prev != stat) {
            if (fetched) this->notify(prev_opt, stat_opt, err);
            else         this->initial_notify(stat_opt, err);
            prev = stat;
        }

        fetched = true;
    });
}

void FsPoll::reset () {
    stop();
}

void FsPoll::clear () {
    stop();
    weak(false);
    _listener = nullptr;
    poll_event.remove_all();
    start_event.remove_all();
}

void FsPoll::notify (const opt<Fs::FStat>& prev, const opt<Fs::FStat>& cur, const std::error_code& err) {
    FsPollSP self = this;
    poll_event(self, prev, cur, err);
    if (_listener) _listener->on_fs_poll(self, prev, cur, err);
}

void FsPoll::initial_notify (const opt<Fs::FStat>& cur, const std::error_code& err) {
    FsPollSP self = this;
    start_event(self, cur, err);
    if (_listener) _listener->on_fs_start(self, cur, err);
}

