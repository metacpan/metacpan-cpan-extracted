#pragma once
#include <panda/uri/URI.h>

namespace panda { namespace uri {

struct URIStrict : URI {
    using URI::URI;
    URIStrict (const URI& source) : URI(source) {}
};

template <class TYPE1, class TYPE2>
struct URI::Strict : URIStrict {
    Strict ()                                    : URIStrict()              {}
    Strict (const string& source, int flags = 0) : URIStrict(source, flags) { strict_scheme(); }
    Strict (const URI& source)                   : URIStrict(source)        { strict_scheme(); }

    using URI::assign;
    void assign (const URI& source) override {
        URI::assign(source);
        strict_scheme();
    }

    using URI::scheme;
    void scheme (const string& scheme) override {
        URI::scheme(scheme);
        strict_scheme();
    }

protected:
    void parse (const string& uristr) override {
        URI::parse(uristr);
        strict_scheme();
    }

    void strict_scheme () {
        if (!_scheme.length()) {
            if (_host.length()) URI::scheme(TYPE1::default_scheme());
        }
        else if (!scheme_info || (*(scheme_info->type_info) != typeid(TYPE1) && *(scheme_info->type_info) != typeid(TYPE2))) {
            throw WrongScheme("URI: wrong scheme '" + _scheme + "' for " + typeid(TYPE1).name());
        }
    }
};

}}
