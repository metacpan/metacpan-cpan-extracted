#include <xs/unievent/Loop.h>
#include <xs/unievent/Handle.h>
#include <xs/unievent/Prepare.h>
#include <xs/unievent/Resolver.h>
#include <xs/CallbackDispatcher.h>

using namespace xs;
using namespace panda::unievent;
using panda::unievent::backend::Backend;

static Object    global_loop;
static Loop*     global_loop_for;
static PrepareSP global_loop_freetmps;

static PERL_ITHREADS_LOCAL struct {
    Object    default_loop;
    Loop*     default_loop_for;
    PrepareSP default_loop_freetmps;
} tls;

static Sv::payload_marker_t delay_marker;

static void freetmps_on_loop_iter (const PrepareSP&) {
    FREETMPS;
}

static Sv _get_default_loop_sv () {
    auto cur = Loop::default_loop();
    if (tls.default_loop_for != cur) {
        tls.default_loop_for = cur;
        tls.default_loop     = xs::out(cur);
        tls.default_loop_freetmps = new Prepare(cur);
        tls.default_loop_freetmps->event.add(freetmps_on_loop_iter);
        tls.default_loop_freetmps->weak(true);
        tls.default_loop_freetmps->start();
    }
    return tls.default_loop.ref();
}

static Sv _get_global_loop_sv () {
    auto cur = Loop::global_loop();
    if (global_loop_for != cur) {
        global_loop_for = cur;
        if (cur == Loop::default_loop()) global_loop = _get_default_loop_sv();
        else {
            global_loop = xs::out(cur);
            global_loop_freetmps = new Prepare(cur);
            global_loop_freetmps->event.add(freetmps_on_loop_iter);
            global_loop_freetmps->weak(true);
            global_loop_freetmps->start();
        }
    }
    return global_loop.ref();
}

struct SvWrapper : panda::Refcnt {
    SvWrapper(Sv sv) : sv(sv) {}
    Sv sv;
};

MODULE = UniEvent::Loop                PACKAGE = UniEvent::Loop
PROTOTYPES: DISABLE

BOOT {
    delay_marker.svt_free = [](pTHX_ SV* sv, MAGIC* mg) -> int {
        auto id = SvUVX(sv);
        auto w = (panda::weak<LoopSP>*)mg->mg_ptr;
        
        if (id) {
            SvUVX(sv) = 0;
            auto loop = w->lock();
            if (loop) loop->cancel_delay(id);
        }
        
        delete w;
        return 0;
    };
    
    xs::at_perl_destroy([]() {
        global_loop_freetmps = nullptr;
        global_loop          = nullptr;
        global_loop_for      = nullptr;
        tls.default_loop_freetmps = nullptr;
        tls.default_loop          = nullptr;
        tls.default_loop_for      = nullptr;
    });
}

void global_loop (...) : ALIAS(global=1) {
    PERL_UNUSED_VAR(ix);
    XPUSHs(_get_global_loop_sv());
    XSRETURN(1);
}

void default_loop (...) : ALIAS(default=1) {
    PERL_UNUSED_VAR(ix);
    XPUSHs(_get_default_loop_sv());
    XSRETURN(1);
}

Loop* Loop::new (Backend* be = nullptr) {
    RETVAL = make_backref<Loop>(be);
}
    
bool Loop::is_default ()

bool Loop::is_global ()

bool Loop::alive ()
    
uint64_t Loop::now ()

void Loop::update_time ()

bool Loop::run ()

bool Loop::run_once ()
    
bool Loop::run_nowait ()

void Loop::stop ()

Array Loop::handles () {
    RETVAL = Array::create();
    auto& hl = THIS->handles();
    if (hl.size()) {
        RETVAL.reserve(hl.size());
        for (const auto& h : hl) RETVAL.push(xs::out(h));
    }
}

Ref Loop::delay (Sub callback) {
    if (!callback) throw "callback is required";
    
    if (GIMME_V == G_VOID) {
        THIS->delay([=]() { callback.call<void>(); });
        XSRETURN_EMPTY;
    }
    
    auto ret = Simple((uint64_t)0);
    auto svp = ret.get();
    
    auto id = THIS->delay([=]() {
        SvUVX(svp) = 0;
        Sv(svp).payload_detach(&delay_marker);
        callback.call<void>();
    });
    SvUVX(svp) = id;
    
    auto w = new panda::weak<LoopSP>(LoopSP(THIS));
    ret.payload_attach(w, &delay_marker);
    
    RETVAL = Ref::create(ret);
}

void Loop::cancel_delay (Ref ref) {
    (void)THIS;
    auto val = ref.value<Simple>();
    if (val) val.payload_detach(&delay_marker);
}

XSCallbackDispatcher* Loop::fork_event () {
    RETVAL = XSCallbackDispatcher::create(THIS->fork_event);
}

ResolverSP Loop::resolver ()

void Loop::track_load_average (uint32_t for_last_n_seconds)

double Loop::get_load_average ()

void Loop::start_debug_tracer (Sub s) {
    THIS->new_handle_event.add([s](const LoopSP&, Handle* h){
        Sv stack = s.call();
        h->user_data = new SvWrapper(stack);
    });
}

void Loop::watch_active_trace (Sub s) {
    for (auto h : THIS->handles()) {
        auto sv = panda::dynamic_pointer_cast<SvWrapper>(h->user_data);
        if (!h->user_data || !h->active() || h->weak()) {
            continue;
        }
        if (!sv) {
            throw std::logic_error("Trace is broken or somebody else used Handle::user_data");
        }
        s.call(xs::out(h), sv->sv);
    }
}

SV* CLONE_SKIP (...) {
    XSRETURN_YES;
    PERL_UNUSED_VAR(items);
}
