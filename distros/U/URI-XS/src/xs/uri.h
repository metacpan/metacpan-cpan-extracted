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
            if (ret.defined()) xs::uri::data_attach(ret);
            return ret;
        }
    };

    template <class TYPE>
    struct Typemap<panda::uri::URISP, panda::iptr<TYPE>> : Typemap<TYPE*> {
        using Super = Typemap<TYPE*>;
        static panda::iptr<TYPE> in (const Sv& arg) {
            if (!arg.defined()) return {};
            if (!arg.is_object_ref()) return new TYPE(xs::in<panda::string>(arg));
            return Super::in(arg);
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

    template <class TYPE> struct Typemap<panda::uri::URI::ws*, TYPE> : Typemap<panda::uri::URI*, TYPE> {
        static panda::string_view package () { return "URI::XS::ws"; }
    };

    template <class TYPE> struct Typemap<panda::uri::URI::wss*, TYPE> : Typemap<panda::uri::URI*, TYPE> {
        static panda::string_view package () { return "URI::XS::wss"; }
    };

    template <class TYPE> struct Typemap<panda::uri::URI::ftp*, TYPE> : Typemap<panda::uri::URI*, TYPE> {
        static panda::string_view package () { return "URI::XS::ftp"; }
    };

    template <class TYPE> struct Typemap<panda::uri::URI::socks*, TYPE> : Typemap<panda::uri::URI*, TYPE> {
        static panda::string_view package () { return "URI::XS::socks"; }
    };

    template <class TYPE> struct Typemap<panda::uri::URI::ssh*, TYPE> : Typemap<panda::uri::URI*, TYPE> {
        static panda::string_view package () { return "URI::XS::ssh"; }
    };

    template <class TYPE> struct Typemap<panda::uri::URI::telnet*, TYPE> : Typemap<panda::uri::URI*, TYPE> {
        static panda::string_view package () { return "URI::XS::telnet"; }
    };

    template <class TYPE> struct Typemap<panda::uri::URI::sftp*, TYPE> : Typemap<panda::uri::URI*, TYPE> {
        static panda::string_view package () { return "URI::XS::sftp"; }
    };
}
