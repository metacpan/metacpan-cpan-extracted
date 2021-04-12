#include "../lib/test.h"
#include <panda/unievent/Streamer.h>
#include <deque>

namespace {

struct TestInput : Streamer::IInput {
    TimerSP timer;
    size_t size;
    size_t speed;
    int    start_reading_cnt = 0;
    int    stop_reading_cnt  = 0;

    TestInput (size_t size, size_t speed) : size(size), speed(speed) {}

    ErrorCode start (const LoopSP& loop) override {
        //printf("start\n");
        timer = new Timer(loop);
        timer->start(1);
        timer->event.add([this](auto...){
            //printf("on read\n");
            if (!size) {
                this->handle_eof();
                timer->stop();
                return;
            }
            if (speed > size) speed = size;
            this->handle_read(string(speed, 'x'), {});
            size -= speed;
        });
        return {};
    }

    ErrorCode start_reading () override {
        //printf("start reading\n");
        timer->start(1);
        start_reading_cnt++;
        return {};
    }

    void stop_reading () override {
        //printf("stop reading %d\n", stop_reading_cnt);
        timer->stop();
        stop_reading_cnt++;
    }

    void stop () override {
        //printf("stop\n");
        timer->stop();
    }
};

struct TestOutput : Streamer::IOutput {
    size_t speed;
    TimerSP timer;
    std::deque<size_t> bufs;

    TestOutput (size_t speed) : speed(speed) {}

    ErrorCode start (const LoopSP& loop) override {
        //printf("writer start\n");
        timer = new Timer(loop);
        timer->event.add([this](auto...){
            bufs.pop_front();
            //printf("on write que left %d\n", write_queue_size());
            this->handle_write({});
            this->_write();
        });
        return {};
    }

    void stop () override {
        //printf("writer stop\n");
        timer->stop();
    }

    ErrorCode write (const string& data) override {
        auto len = data.length();
        //printf("writer write %d, que=%d\n", len, write_queue_size());

        bufs.push_back(len);
        if (bufs.size() == 1) _write();
        return {};
    }

    void _write () {
        if (!bufs.size()) return;
        auto len = bufs.front();
        size_t tmt = len / speed;
        //printf("writer _write\n");
        timer->once(tmt);
    }

    size_t write_queue_size () const override {
        size_t que = 0;
        for (auto n : bufs) { que += n; }
        return que;
    }
};

}
