#pragma once
#include <xs/unievent/http.h>
#include <panda/unievent/http/manager.h>

namespace xs { namespace unievent { namespace http {

void fill (Manager::Config&, const Hash&);

}}}

namespace xs {
    template <class T> struct Typemap<panda::unievent::http::Manager::Config, T> : TypemapBase<panda::unievent::http::Manager::Config, T> {
        static panda::unievent::http::Manager::Config in (const Hash& h) {
            T cfg;
            xs::unievent::http::fill(cfg, h);
            return cfg;
        }
    };

    template <class T> struct Typemap<panda::unievent::http::Manager*, T> : TypemapObject<panda::unievent::http::Manager*, T, ObjectTypeRefcntPtr, ObjectStorageMGBackref> {
        static panda::string package () { return "UniEvent::HTTP::Manager"; }
    };
}
