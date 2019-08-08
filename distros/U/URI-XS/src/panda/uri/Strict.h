#pragma once
#include <panda/uri/URI.h>

namespace panda { namespace uri {

class URI::Strict : public URI {
public:
    Strict ()                                    : URI()              {}
    Strict (const string& source, int flags = 0) : URI(source, flags) {}
    Strict (const URI& source)                   : URI(source)        {}

    using URI::assign;
    virtual void assign (const URI& source) {
        URI::assign(source);
        strict_scheme();
    }

    using URI::scheme;
    virtual void scheme (const string& scheme) {
        URI::scheme(scheme);
        strict_scheme();
    }

protected:
    virtual void parse (const string& uristr) {
        URI::parse(uristr);
        strict_scheme();
    }

    void strict_scheme (const std::type_info* alternate = NULL) {
        if (!_scheme.length()) {
            if (_host.length()) URI::scheme(my_scheme());
        }
        else if (!scheme_info || (scheme_info->type_info != &typeid(*this) && scheme_info->type_info != alternate)) {
            string sup_scheme = my_scheme();
            if (alternate) sup_scheme += "' or '" + my_scheme(alternate);
            throw WrongScheme("URI: wrong scheme '" + _scheme + "', this object only supports '" + sup_scheme + "'");
        }
    }

    string my_scheme (const std::type_info* ti = NULL) {
        if (!ti) ti = &typeid(*this);
        auto info = get_scheme_info(ti);
        if (!info) throw URIError(string("URI: tried to use class ") + ti->name() + " which has not been registered");
        return info->scheme;
    }
};

class URI::UserPass : public virtual Strict {
public:
    const string user () const {
        size_t delim = _user_info.find(':');
        if (delim == string::npos) return _user_info;
        return _user_info.substr(0, delim);
    }

    void user (const string& user) {
        size_t delim = _user_info.find(':');
        if (delim == string::npos) _user_info = user;
        else _user_info.replace(0, delim, user);
    }

    const string password () const {
        size_t delim = _user_info.find(':');
        if (delim == string::npos) return string();
        return _user_info.substr(delim+1);
    }

    void password (const string& password) {
        size_t delim = _user_info.find(':');
        if (delim == string::npos) {
            _user_info += ':';
            _user_info += password;
        }
        else _user_info.replace(delim+1, string::npos, password);
    }
};

}}
