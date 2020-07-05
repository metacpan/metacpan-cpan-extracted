#include <xs/basic.h>
#include <thread>
#include <vector>
#include <xs/Sub.h>
#include <xs/Simple.h>
#include <panda/string.h>

namespace xs {

using panda::string;

#ifdef PERL_IMPLICIT_CONTEXT
PerlInterpreter* my_perl_auto_t::main_interp = PERL_GET_THX;
#endif

my_perl_auto_t my_perl;

static std::vector<panda::function<void()>> end_cbs;
static const auto mt_id = std::this_thread::get_id();

void at_perl_destroy (const panda::function<void()>& f) {
    end_cbs.push_back(f);
}

void __call_at_perl_destroy () {
    for (auto& f : end_cbs) f();
    Sv::__at_perl_destroy();
    Scalar::__at_perl_destroy();
    Simple::__at_perl_destroy();
}

void __call_at_thread_create () {
#ifdef PERL_IMPLICIT_CONTEXT
    my_perl_auto_t::main_interp = nullptr;
#endif
}

void __boot_module (const char* rawmod, void (*bootfunc)(pTHX_ CV*), const char* version, const char* file) {
    string bs("::bootstrap");
    string module(strlen(rawmod) + bs.length() + 1);
    module.assign(rawmod);

    auto len = module.length();
    auto ptr = module.buf();
    for (size_t i = 0; i < len; ++i) {
        if (ptr[i] != '_' || i >= len - 1 || ptr[i+1] != '_') continue;
        ptr[i] = ':';
        ptr[i+1] = ':';
        ++i;
    }

    auto xsname = module + bs;

    Sub sub = newXS(xsname.c_str(), bootfunc, file);
    sub.call<void>(Simple(module), Simple(version));
}

bool is_perl_thread () {
    if (std::this_thread::get_id() == mt_id) return true;
  #ifndef PERL_IMPLICIT_CONTEXT
    return false;
  #else
    return (PerlInterpreter*)my_perl;
  #endif
}

}
