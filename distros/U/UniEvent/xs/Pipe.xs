#include <xs/unievent/Pipe.h>
#include <panda/unievent/util.h>

using namespace xs;
using namespace xs::unievent;
using panda::string;
using panda::ErrorCode;
using panda::unievent::Pipe;
using panda::unievent::Loop;
using panda::unievent::Error;
using panda::unievent::Stream;
using panda::unievent::LoopSP;
using panda::unievent::PipeSP;
using panda::unievent::StreamSP;
using panda::unievent::Ownership;
using panda::unievent::last_sys_error;
using panda::unievent::ConnectRequest;
using panda::unievent::ConnectRequestSP;
using panda::unievent::PipeConnectRequest;

static inline PipeSP create_pipe (const LoopSP& loop, bool ipc) {
    PipeSP ret = make_backref<Pipe>(loop, ipc);
    ret->connection_factory = [](const StreamSP& h) {
        auto srv = panda::dyn_cast<Pipe*>(h.get());
        PipeSP client = make_backref<Pipe>(srv->loop(), srv->ipc());
        xs::out(client); // fill backref
        return client;
    };
    return ret;
}


MODULE = UniEvent::Pipe                PACKAGE = UniEvent::Pipe
PROTOTYPES: DISABLE

BOOT {
    Stash s(__PACKAGE__);
    s.inherit("UniEvent::Stream");
    s.add_const_sub("TYPE", Simple(Pipe::TYPE.name));
    unievent::register_perl_class(Pipe::TYPE, s);
}

PipeSP Pipe::new (LoopSP loop = {}, bool ipc = false) {
    if (!loop) loop = Loop::default_loop();
    RETVAL = create_pipe(loop, ipc);
}

void Pipe::open (Sv fd, bool connected = false) {
    THIS->open(sv2fd(fd), Ownership::SHARE, connected);
}

void Pipe::bind (panda::string_view name)

ConnectRequestSP Pipe::connect (string name, Sub callback = Sub()) {
    Stream::connect_fn fn;
    auto req = make_backref<PipeConnectRequest>(name, fn);
    if (callback) {
        fn = [=](const StreamSP& h, const ErrorCode& err, const ConnectRequestSP& req){
            callback.call<void>(xs::out(h), xs::out(err), xs::out(req));
        };
    }
    THIS->connect(name, fn);
    RETVAL = req;
}

string Pipe::sockname () : ALIAS(peername=1) {
    auto ret = ix == 0 ? THIS->sockname() : THIS->peername();
    if (!ret) XSRETURN_UNDEF;
    RETVAL = *ret;
}

void Pipe::pending_instances (int count)

#// pair([$loop])
#// pair($reader, $writer)
#// returns ($reader, $writer)
void pair (Sv arg1 = Sv(), Sv arg2 = Sv()) {
    PipeSP reader, writer;
    LoopSP loop;

    if (arg2) {
        reader = xs::in<Pipe*>(arg1);
        writer = xs::in<Pipe*>(arg2);
    }
    else if (arg1) {
        loop = xs::in<Loop*>(arg1);
    }

    if (!loop) loop = Loop::default_loop();
    // although, these don't accept connections, they can be reset(), and used as servers, so we need connection_factory
    if (!reader) reader = create_pipe(loop, false);
    if (!writer) writer = create_pipe(loop, false);
    if (reader->ipc() || writer->ipc()) throw "both reader and writer must be created with ipc = false";

    int fds[2];
    if (PerlProc_pipe(fds) < 0) throw Error(last_sys_error());

    try {
        reader->read_start();
        reader->open(fds[0], Ownership::TRANSFER, true);
        writer->read_stop();
        writer->open(fds[1], Ownership::TRANSFER, true);
    } catch (...) {
        reader->reset();
        writer->reset();
        PerlLIO_close(fds[0]);
        PerlLIO_close(fds[1]);
        throw;
    }

    mXPUSHs(xs::out(reader).detach());
    mXPUSHs(xs::out(writer).detach());
    XSRETURN(2);
}
