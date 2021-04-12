#include "Pipe.h"
#include "util.h"

namespace panda { namespace unievent {

const HandleType Pipe::TYPE("pipe");

const HandleType& Pipe::type () const {
    return TYPE;
}

backend::HandleImpl* Pipe::new_impl () {
    return loop()->impl()->new_pipe(this, _ipc);
}

excepted<void, ErrorCode> Pipe::open (fd_t file, int mode, Ownership ownership) {
    if (ownership == Ownership::SHARE) file = file_dup(file);

    auto error = impl()->open(file);
    if (error) make_excepted(error);

    if (mode != Mode::not_connected) {
        if (!(mode & Mode::readable)) read_stop(); // do not run read_start() if pipe is not a reader
        error = set_connect_result(true);
        if (!(mode & Mode::writable)) clear_out_connected(); // do not allow to call write() if pipe is not a writer
    }

    return make_excepted(error);
}

excepted<void, ErrorCode> Pipe::bind (string_view name) {
    return make_excepted(impl()->bind(name));
}

StreamSP Pipe::create_connection () {
    return new Pipe(loop(), _ipc);
}

PipeConnectRequestSP Pipe::connect (const PipeConnectRequestSP& req) {
    req->set(this);
    queue.push(req);
    return req;
}

void PipeConnectRequest::exec () {
    ConnectRequest::exec();
    if (handle->filters().size()) {
        last_filter = handle->filters().front();
        last_filter->pipe_connect(this);
    }
    else finalize_connect();
}

void PipeConnectRequest::finalize_connect () {
    panda_log_debug("PipeConnectRequest::finalize_connect " << this);
    auto err = handle->impl()->connect(name, impl());
    if (err) return delay([=]{ cancel(err); });
}

void Pipe::pending_instances (int count) {
    impl()->pending_instances(count);
}

int Pipe::pending_count () const {
    return impl()->pending_count();
}

excepted<void, ErrorCode> Pipe::chmod (int mode) {
    return make_excepted(impl()->chmod(mode));
}

excepted<std::pair<PipeSP, PipeSP>, ErrorCode> Pipe::pair (const LoopSP& loop) {
    return pair(new Pipe(loop), new Pipe(loop));
}

excepted<std::pair<PipeSP, PipeSP>, ErrorCode> Pipe::pair (const PipeSP& h1, const PipeSP& h2) {
    std::pair<PipeSP, PipeSP> p = {h1, h2};

    auto spres = panda::unievent::pipe();
    if (!spres) return make_unexpected<ErrorCode>(spres.error());
    auto fds = spres.value();

    auto res = p.first->open(fds.first, Mode::readable);
    if (res) res = p.second->open(fds.second, Mode::writable);
    if (res) return p;

    p.first->reset();
    p.second->reset();
    return make_unexpected(res.error());
}

}}
