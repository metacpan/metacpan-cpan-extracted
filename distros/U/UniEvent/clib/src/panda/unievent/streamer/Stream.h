#pragma once
#include "../Stream.h"
#include "../Streamer.h"

namespace panda { namespace unievent { namespace streamer {

struct StreamInput : Streamer::IInput, private IStreamSelfListener {
    StreamInput (const StreamSP& s) : stream(s) {}

    ErrorCode start (const LoopSP&) override;
    void      stop  ()              override;

    ErrorCode start_reading () override;
    void      stop_reading  () override;

private:
    StreamSP         stream;
    IStreamListener* prev_lst = nullptr;
    bool             prev_wantread = false;

    void on_read (string&, const ErrorCode&) override;
    void on_eof  ()                          override;
};

struct StreamOutput : Streamer::IOutput, private IStreamSelfListener {
    StreamOutput (const StreamSP& s) : stream(s) {}

    ErrorCode start (const LoopSP&)      override;
    void      stop  ()                   override;
    ErrorCode write (const string& data) override;

    size_t write_queue_size () const override { return stream->write_queue_size(); }

private:
    StreamSP         stream;
    IStreamListener* prev_lst = nullptr;
    WriteRequestSP   first_wreq;
    bool             handle_write_started = false;

    void on_write (const ErrorCode&, const WriteRequestSP&) override;
};

}}}
