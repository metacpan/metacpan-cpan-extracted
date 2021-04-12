#include "File.h"

namespace panda { namespace unievent { namespace streamer {

ErrorCode FileInput::start (const LoopSP& loop) {
    this->loop = loop;
    fsreq = Fs::open(path, Fs::OpenFlags::RDONLY, Fs::DEFAULT_FILE_MODE, [this](fd_t fd, const std::error_code& err, const Fs::RequestSP&) {
        if (err) return handle_read({}, err);
        this->fd = fd;
        opened = true;
        do_read();
    }, loop);
    return {};
}

void FileInput::do_read () {
    fsreq = Fs::read(fd, chunk_size, -1, [this](const string& data, const std::error_code& err, const Fs::RequestSP&) {
        if (err) return handle_read({}, err);
        if (data.length()) handle_read(data, err);
        if (data.length() < chunk_size) return handle_eof();
        if (!pause) do_read();
    }, loop);
}

void FileInput::stop () {
    if (fsreq) fsreq->cancel();
    fsreq = nullptr;
    if (opened) Fs::close(fd, [](auto...){}, loop);
    opened = false;
}

ErrorCode FileInput::start_reading () {
    pause = false;
    if (!fsreq->active()) do_read();
    return {};
}

void FileInput::stop_reading () {
    pause = true;
}



ErrorCode FileOutput::start (const LoopSP& loop) {
    this->loop = loop;
    fsreq = Fs::open(path, Fs::OpenFlags::WRONLY | Fs::OpenFlags::TRUNC | Fs::OpenFlags::CREAT, mode, [this](fd_t fd, const std::error_code& err, const Fs::RequestSP&) {
        if (err) return handle_write(err);
        this->fd = fd;
        opened = true;
        if (bufs.size()) do_write();
    }, loop);
    return {};
}

ErrorCode FileOutput::write (const string& data) {
    bufsz += data.length();
    bufs.push_back(data);
    if (bufs.size() == 1 && opened) do_write();
    return {};
}

void FileOutput::do_write () {
    fsreq = Fs::write(fd, bufs.front(), -1, [this](const auto& err, const auto&) {
        bufsz -= bufs.front().length();
        bufs.pop_front();
        this->handle_write(err);
        if (bufs.size()) this->do_write();
    }, loop);
}

void FileOutput::stop () {
    if (fsreq) fsreq->cancel();
    fsreq = nullptr;
    if (opened) Fs::close(fd, [](auto...){}, loop);
    opened = false;
}

}}}
