#include "Streamer.h"

namespace panda { namespace unievent {

Streamer::Streamer (const IInputSP& input, const IOutputSP& output, size_t max_buf, const LoopSP& loop)
    : loop(loop), input(input), output(output), max_buf(max_buf)
{
    assert(input); assert(output);
    input->streamer = output->streamer = this;
    thr_buf = max_buf * 2 / 3;
}

void Streamer::start () {
    auto err = input->start(loop);
    if (err) return finish_event(nest_error(streamer_errc::read_error, err));

    err = output->start(loop);
    if (err) {
        input->stop();
        return finish_event(nest_error(streamer_errc::write_error, err));
    }

    started = true;
}

void Streamer::stop () {
    finish(make_error_code(std::errc::operation_canceled));
}

void Streamer::handle_read (const string& data, const ErrorCode& err) {
    if (err) return finish(nest_error(streamer_errc::read_error, err));

    nread++;
    auto werr = output->write(data);
    if (werr) return finish(nest_error(streamer_errc::write_error, werr));

    if (max_buf && output->write_queue_size() >= max_buf) {
        input->stop_reading();
        inread = false;
    }
}

void Streamer::handle_write (const ErrorCode& err) {
    if (err) return finish(nest_error(streamer_errc::write_error, err));
    nwrite++;

    if (eof && nwrite == nread) return finish();

    if (!inread && output->write_queue_size() <= thr_buf) {
        auto rerr = input->start_reading();
        if (rerr) return finish(nest_error(streamer_errc::read_error, rerr));
        inread = true;
    }
}

void Streamer::handle_eof () {
    if (nwrite == nread) return finish();
    eof = true;
}

void Streamer::finish (const ErrorCode& err) {
    if (!started) return;
    input->stop();
    output->stop();

    started = false;
    inread = true;
    eof = false;
    nread = nwrite = 0;

    finish_event(err);
}

}}
