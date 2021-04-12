#pragma once
#include "../Fs.h"
#include "../Streamer.h"
#include <deque>

namespace panda { namespace unievent { namespace streamer {

struct FileInput : Streamer::IInput {
    FileInput (string_view path, size_t chunk_size = 1000000) : path(string(path)), chunk_size(chunk_size) {}

    ErrorCode start (const LoopSP&) override;
    void      stop  () override;

    ErrorCode start_reading () override;
    void      stop_reading  () override;

private:
    string        path;
    size_t        chunk_size;
    LoopSP        loop;
    fd_t          fd;
    Fs::RequestSP fsreq;
    bool          opened = false;
    bool          pause = false;

    void do_read ();
};

struct FileOutput : Streamer::IOutput {
    FileOutput (string_view path, int mode = Fs::DEFAULT_FILE_MODE) : path(string(path)), mode(mode) {}

    ErrorCode start (const LoopSP&)      override;
    void      stop  ()                   override;
    ErrorCode write (const string& data) override;

    size_t write_queue_size () const override { return bufsz; }

private:
    string             path;
    int                mode;
    LoopSP             loop;
    fd_t               fd;
    Fs::RequestSP      fsreq;
    bool               opened = false;
    std::deque<string> bufs;
    size_t             bufsz = 0;

    void do_write ();
};

}}}
