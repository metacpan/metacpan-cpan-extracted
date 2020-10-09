#include "Stream.h"

namespace panda { namespace unievent { namespace streamer {

ErrorCode StreamInput::start (const LoopSP&) {
    prev_lst = stream->event_listener();
    prev_wantread = stream->wantread();

    auto res = stream->read_start();
    if (!res) return res.error();

    stream->event_listener(this);
    return {};
}

void StreamInput::on_read (string& data, const ErrorCode& err) {
    handle_read(data, err);
}

void StreamInput::on_eof () {
    handle_eof();
}

void StreamInput::stop () {
    if (prev_wantread) stream->read_start().nevermind();
    else               stream->read_stop();
    stream->event_listener(prev_lst);
}

ErrorCode StreamInput::start_reading () {
    auto res = stream->read_start();
    return res ? ErrorCode() : res.error();
}

void StreamInput::stop_reading () {
    stream->read_stop();
}



ErrorCode StreamOutput::start (const LoopSP&) {
    prev_lst = stream->event_listener();
    stream->event_listener(this);
    return {};
}

ErrorCode StreamOutput::write (const string& data) {
    stream->write(data);
    return {};
}

void StreamOutput::on_write (const ErrorCode& err, const WriteRequestSP&) {
    handle_write(err);
}

void StreamOutput::stop () {
    stream->event_listener(prev_lst);
}

}}}
