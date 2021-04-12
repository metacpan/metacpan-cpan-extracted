#include <xs/export.h>
#include <xs/unievent/Pipe.h>
#include <xs/typemap/expected.h>
#include <panda/unievent/util.h>

using namespace xs;
using namespace panda::unievent;
using namespace xs::unievent;
using panda::string;
using panda::ErrorCode;

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
    
    xs::exp::create_constants(s, {
        {"MODE_NOT_CONNECTED", Pipe::Mode::not_connected},
        {"MODE_READABLE",      Pipe::Mode::readable},
        {"MODE_WRITABLE",      Pipe::Mode::writable}
    });
    xs::exp::autoexport(s);
}

PipeSP Pipe::new (LoopSP loop = {}, bool ipc = false) {
    if (!loop) loop = Loop::default_loop();
    RETVAL = create_pipe(loop, ipc);
}

void Pipe::open (Sv fd, int mode) {
    XSRETURN_EXPECTED(THIS->open(sv2fd(fd), mode, Ownership::SHARE));
}

void Pipe::bind (panda::string_view name) {
    XSRETURN_EXPECTED(THIS->bind(name));
}

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

void Pipe::sockname () : ALIAS(peername=1) {
    auto ret = ix == 0 ? THIS->sockname() : THIS->peername();
    XSRETURN_EXPECTED(ret);
}

void Pipe::pending_instances (int count)

void Pipe::chmod (int mode) {
    XSRETURN_EXPECTED(THIS->chmod(mode));
}

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
    
    auto ret = Pipe::pair(reader, writer);
    if (!ret) throw Error(ret.error());

    mXPUSHs(xs::out(reader).detach());
    mXPUSHs(xs::out(writer).detach());
    XSRETURN(2);
}
