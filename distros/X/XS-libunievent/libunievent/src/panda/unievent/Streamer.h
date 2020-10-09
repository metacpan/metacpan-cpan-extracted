#pragma once
#include "Loop.h"
#include <panda/CallbackDispatcher.h>

namespace panda { namespace unievent {

struct Streamer : Refcnt {
    struct IInput : Refcnt {
        virtual ErrorCode start_reading ()              = 0;
        virtual void      stop_reading  ()              = 0;
        virtual ErrorCode start         (const LoopSP&) = 0;
        virtual void      stop          ()              = 0;

    protected:
        void handle_read (const string& data, const ErrorCode& err) { streamer->handle_read(data, err); }
        void handle_eof  ()                                         { streamer->handle_eof(); }

    private:
        friend Streamer;
        Streamer* streamer = nullptr;
    };
    using IInputSP = iptr<IInput>;

    struct IOutput : Refcnt {
        virtual ErrorCode start            (const LoopSP&)      = 0;
        virtual void      stop             ()                   = 0;
        virtual ErrorCode write            (const string& data) = 0;
        virtual size_t    write_queue_size () const             = 0;

    protected:
        void handle_write (const ErrorCode& err) { streamer->handle_write(err); }

    private:
        friend Streamer;
        Streamer* streamer = nullptr;
    };
    using IOutputSP = iptr<IOutput>;

    using finish_fptr = void(const ErrorCode& err);
    using finish_fn   = function<finish_fptr>;

    CallbackDispatcher<finish_fptr> finish_event;

    Streamer (const IInputSP& input, const IOutputSP& output, size_t max_buf = 10000000, const LoopSP& loop = Loop::default_loop());

    void start ();
    void stop  ();

    virtual ~Streamer () {}

private:
    friend IInput; friend IOutput;

    LoopSP    loop;
    IInputSP  input;
    IOutputSP output;
    size_t    max_buf;
    size_t    thr_buf;
    size_t    nread = 0;
    size_t    nwrite = 0;
    bool      started = false;
    bool      inread = true;
    bool      eof = false;

    void handle_read  (const string&, const ErrorCode&);
    void handle_write (const ErrorCode&);
    void handle_eof   ();

    void finish (const ErrorCode& = {});
};
using StreamerSP = iptr<Streamer>;

}}
