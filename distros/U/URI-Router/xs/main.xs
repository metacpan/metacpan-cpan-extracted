#include <xs/export.h>
#include <xs/typemap.h>
#include <xs/uri/router.h>
#include <regex>

using namespace xs;
using namespace xs::uri;
using namespace panda;
using namespace panda::uri;
using namespace panda::uri::router;

static void router_add (SvRouter* r, const Scalar& sv_path, const Scalar& value) {
    auto copy = Scalar::create();
    SvSetSV_nosteal(copy, value);
    auto path = xs::in<string>(sv_path);
    if (SvRXOK(sv_path)) {
        if (path.find("(?^") == 0) {
            static std::regex rere("^\\(\\?\\^[a-z]*:");
            auto re = regex_replace(std::string(path.data(), path.length()), rere, "");
            path = string(re.data(), re.length()-1);
        }
        r->add({Regex(path), copy});
    } else {
        r->add({path, copy});
    }
}

MODULE = URI::Router                PACKAGE = URI::Router
PROTOTYPES: DISABLE

BOOT {
    using M = Method;
    Stash s(__PACKAGE__);
    xs::exp::create_constants(s, {
        {"METHOD_UNSPECIFIED", int(M::Unspecified)},
        {"METHOD_OPTIONS",     int(M::Options)    },
        {"METHOD_GET",         int(M::Get)        },
        {"METHOD_HEAD",        int(M::Head)       },
        {"METHOD_POST",        int(M::Post)       },
        {"METHOD_PUT",         int(M::Put)        },
        {"METHOD_DELETE",      int(M::Delete)     },
        {"METHOD_TRACE",       int(M::Trace)      },
        {"METHOD_CONNECT",     int(M::Connect)    },
    });
    xs::exp::autoexport(s);
}

SvRouter* SvRouter::new (...) {
    RETVAL = new SvRouter();
    for (I32 i = 1; i < items - 1; i += 2) {
        router_add(RETVAL, ST(i), ST(i+1));
    }
}

void SvRouter::add (Scalar path, Scalar value) {
    router_add(THIS, path, value);
}

void SvRouter::route (string_view path, Sv sv_method = Sv()) {
    Method method = sv_method ? Method(SvIV(sv_method)) : Method::Get;
    auto opt = THIS->route(path, method);
    if (!opt) XSRETURN_UNDEF;
    auto& res = *opt;
    
    if (GIMME_V != G_ARRAY) {
        XPUSHs(res.value);
        XSRETURN(1);
    }
    else {
        I32 nret = res.captures.size() + 1;
        EXTEND(SP, nret);
        XPUSHs(res.value);
        for (auto& s : res.captures) mXPUSHs(xs::out(s).detach());
        XSRETURN(nret);
    }
}

uint64_t SvRouter::bench (string_view path) {
    RETVAL = 0;
    for (int i = 0; i < 1000; ++i) {
        auto opt = THIS->route(path);
        if (opt) ++RETVAL;
    }
}
