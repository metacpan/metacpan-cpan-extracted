#pragma once
#include <xs.h>
#include <panda/uri/URI.h>
#include <panda/uri/ftp.h>
#include <panda/uri/http.h>

namespace xs {
    namespace uri {
        void data_attach (Sv& sv);
        Stash get_perl_class (const panda::uri::URI* uri);

        struct URIx {
            using URI = panda::uri::URI;
            URI* uri;
            URIx () : uri(nullptr) {}
            URIx (URI* uri) : uri(uri) {}
            URI* operator-> () const { return uri; }
            URI& operator*  () const { return *uri; }
            operator URI*   () const { return uri; }
            URIx& operator= (URI* uri) { this->uri = uri; return *this; }
        };
    }

    template <class TYPE> struct Typemap<panda::uri::URI*, TYPE> : TypemapObject<panda::uri::URI*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref, DynamicCast> {
        static panda::string_view package () { return "URI::XS"; }

        static Sv create (const TYPE& var, const Sv& proto = Sv()) {
            auto ret = TypemapObject<panda::uri::URI*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref, DynamicCast>::create(var, proto);
            xs::uri::data_attach(ret);
            return ret;
        }
    };

    template <> struct Typemap<xs::uri::URIx> : Typemap<panda::uri::URI*> {
        static Sv out (xs::uri::URIx var, const Sv& = Sv()) {
            return Typemap<panda::uri::URI*>::out(var, xs::uri::get_perl_class(var));
        }
    };

    template <class TYPE> struct Typemap<panda::uri::URI::http*, TYPE> : Typemap<panda::uri::URI*, TYPE> {
        static panda::string_view package () { return "URI::XS::http"; }
    };

    template <class TYPE> struct Typemap<panda::uri::URI::https*, TYPE> : Typemap<panda::uri::URI*, TYPE> {
        static panda::string_view package () { return "URI::XS::https"; }
    };

    template <class TYPE> struct Typemap<panda::uri::URI::UserPass*, TYPE> : Typemap<panda::uri::URI*, TYPE> {};

    template <class TYPE> struct Typemap<panda::uri::URI::ftp*, TYPE> : Typemap<panda::uri::URI::UserPass*, TYPE> {
        static panda::string_view package () { return "URI::XS::ftp"; }
    };

    template <class TYPE> struct Typemap<panda::uri::URI::socks*, TYPE> : Typemap<panda::uri::URI::UserPass*, TYPE> {
        static panda::string_view package () { return "URI::XS::socks"; }
    };
}
