#include "Signal.h"

namespace panda { namespace unievent {

static panda::string signames[NSIG];

static bool init () {
    signames[SIGINT]    = "SIGINT";
    signames[SIGILL]    = "SIGILL";
    signames[SIGABRT]   = "SIGABRT";
    signames[SIGFPE]    = "SIGFPE";
    signames[SIGSEGV]   = "SIGSEGV";
    signames[SIGTERM]   = "SIGTERM";
    
    #ifdef SIGHUP
    signames[SIGHUP]    = "SIGHUP";
    #endif
    #ifdef SIGQUIT
    signames[SIGQUIT]   = "SIGQUIT";
    #endif
    #ifdef SIGTRAP
    signames[SIGTRAP]   = "SIGTRAP";
    #endif
    #ifdef SIGBUS
    signames[SIGBUS]    = "SIGBUS";
    #endif
    #ifdef SIGKILL
    signames[SIGKILL]   = "SIGKILL";
    #endif
    #ifdef SIGUSR1
    signames[SIGUSR1]   = "SIGUSR1";
    #endif
    #ifdef SIGUSR2
    signames[SIGUSR2]   = "SIGUSR2";
    #endif
    #ifdef SIGPIPE
    signames[SIGPIPE]   = "SIGPIPE";
    #endif
    #ifdef SIGALRM
    signames[SIGALRM]   = "SIGALRM";
    #endif
    #ifdef SIGSTKFLT
    signames[SIGSTKFLT] = "SIGSTKFLT";
    #endif
    #ifdef SIGCHLD
    signames[SIGCHLD]   = "SIGCHLD";
    #endif
    #ifdef SIGCONT
    signames[SIGCONT]   = "SIGCONT";
    #endif
    #ifdef SIGSTOP
    signames[SIGSTOP]   = "SIGSTOP";
    #endif
    #ifdef SIGTSTP
    signames[SIGTSTP]   = "SIGTSTP";
    #endif
    #ifdef SIGTTIN
    signames[SIGTTIN]   = "SIGTTIN";
    #endif
    #ifdef SIGTTOU
    signames[SIGTTOU]   = "SIGTTOU";
    #endif
    #ifdef SIGURG
    signames[SIGURG]    = "SIGURG";
    #endif
    #ifdef SIGXCPU
    signames[SIGXCPU]   = "SIGXCPU";
    #endif
    #ifdef SIGXFSZ
    signames[SIGXFSZ]   = "SIGXFSZ";
    #endif
    #ifdef SIGVTALRM
    signames[SIGVTALRM] = "SIGVTALRM";
    #endif
    #ifdef SIGPROF
    signames[SIGPROF]   = "SIGPROF";
    #endif
    #ifdef SIGWINCH
    signames[SIGWINCH]  = "SIGWINCH";
    #endif
    #ifdef SIGIO
    signames[SIGIO]     = "SIGIO";
    #endif
    #ifdef SIGPOLL
    signames[SIGPOLL]   = "SIGPOLL";
    #endif
    #ifdef SIGPWR
    signames[SIGPWR]    = "SIGPWR";
    #endif
    #ifdef SIGSYS
    signames[SIGSYS]    = "SIGSYS";
    #endif
    return true;
}
static bool _init = init();

const HandleType Signal::TYPE("signal");

SignalSP Signal::create (int signum, const signal_fn& cb, const LoopSP& loop) {
    SignalSP h = new Signal(loop);
    h->start(signum, cb);
    return h;
}

SignalSP Signal::create_once (int signum, const signal_fn& cb, const LoopSP& loop) {
    SignalSP h = new Signal(loop);
    h->once(signum, cb);
    return h;
}

const HandleType& Signal::type () const {
    return TYPE;
}

excepted<void, ErrorCode> Signal::start (int signum, const signal_fn& callback) {
    if (callback) event.add(callback);
    return make_excepted(impl()->start(signum));
}

excepted<void, ErrorCode> Signal::once (int signum, const signal_fn& callback) {
    if (callback) event.add(callback);
    return make_excepted(impl()->once(signum));
}

excepted<void, ErrorCode> Signal::stop () {
    return make_excepted(impl()->stop());
}

void Signal::reset () {
    stop();
}

void Signal::clear () {
    stop();
    weak(false);
    _listener = nullptr;
    event.remove_all();
}

void Signal::handle_signal (int signum) {
    SignalSP self = this;
    event(self, signum);
    if (_listener) _listener->on_signal(self, signum);
}

const panda::string& Signal::signame (int signum) {
    if (signum < 0 || signum >= NSIG) throw std::invalid_argument("signum must be >= 0 and < NSIG");
    return signames[signum];
}

}}
