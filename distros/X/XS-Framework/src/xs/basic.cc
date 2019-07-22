#include <xs/basic.h>
#include <vector>
#include <xs/Sub.h>
#include <xs/Simple.h>
#include <panda/string.h>

namespace xs {

using panda::string;

xs::my_perl_auto_t my_perl;

static std::vector<panda::function<void()>> end_cbs;

void at_perl_destroy (const panda::function<void()>& f) {
    end_cbs.push_back(f);
}

void __call_at_perl_destroy () {
    for (auto& f : end_cbs) f();
    Sv::__at_perl_destroy();
    Scalar::__at_perl_destroy();
    Simple::__at_perl_destroy();
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

}
