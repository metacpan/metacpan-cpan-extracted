#pragma once
#include <map>
#include <vector>
#include <cctype>
#include <iosfwd>
#include <typeinfo>
#include <stdexcept>
#include <initializer_list>
#include <panda/refcnt.h>
#include <panda/string.h>
#include <panda/uri/Query.h>
#include <panda/uri/encode.h>
#include <panda/string_view.h>
#include <panda/from_chars.h>

namespace panda { namespace uri {

struct URIError : std::logic_error {
  explicit URIError (const std::string& what_arg) : logic_error(what_arg) {}
};

struct WrongScheme : URIError {
  explicit WrongScheme (const std::string& what_arg) : URIError(what_arg) {}
};

struct URI;
using URISP = iptr<URI>;

struct URI : Refcnt {
    struct Flags {
        static constexpr const int allow_suffix_reference = 1; // https://tools.ietf.org/html/rfc3986#section-4.5 uri may omit leading "SCHEME://"
        static constexpr const int query_param_semicolon  = 2; // query params are delimited by ';' instead of '&'
        static constexpr const int allow_extended_chars   = 4; // non-RFC input: allow some unencoded chars in query string
    };

    template <class TYPE1, class TYPE2 = void> struct Strict;
    struct http; struct https; struct ftp; struct socks; struct ws; struct wss; struct ssh; struct telnet; struct sftp;

    using uricreator = URI*(*)(const URI& uri);

    struct SchemeInfo {
        int        index;
        string     scheme;
        uricreator creator;
        uint16_t   default_port;
        bool       secure;
        const std::type_info* type_info;
    };

    static void register_scheme (const string& scheme, uint16_t default_port, bool secure = false);
    static void register_scheme (const string& scheme, const std::type_info*, uricreator, uint16_t default_port, bool secure = false);

    static URISP create (const string& source, int flags = 0) {
        URI temp(source, flags);
        if (temp.scheme_info) return temp.scheme_info->creator(temp);
        else                  return new URI(temp);
    }

    static URISP create (const URI& source) {
        if (source.scheme_info) return source.scheme_info->creator(source);
        else                    return new URI(source);
    }

    URI ()                                               : scheme_info(NULL), _port(0), _qrev(1), _flags(0)     {}
    URI (const string& s, int flags = 0)                 : scheme_info(NULL), _port(0), _qrev(1), _flags(flags) { parse(s); }
    URI (const string& s, const Query& q, int flags = 0) : URI(s, flags)                                        { add_query(q); }
    URI (const URI& s)                                                                                          { assign(s); }

    URI& operator= (const URI& source)    { if (this != &source) assign(source); return *this; }
    URI& operator= (const string& source) { assign(source); return *this; }

    const string& scheme        () const { return _scheme; }
    const string& user_info     () const { return _user_info; }
    const string& host          () const { return _host; }
    const string& path          () const { return _path; }
    string        path_info     () const { return _path ? decode_uri_component(_path) : string(); }
    const string& fragment      () const { return _fragment; }
    uint16_t      explicit_port () const { return _port; }
    uint16_t      default_port  () const { return scheme_info ? scheme_info->default_port : 0; }
    uint16_t      port          () const { return _port ? _port : default_port(); }
    bool          secure        () const { return scheme_info ? scheme_info->secure : false; }

    virtual void assign (const URI& source) {
        _scheme     = source._scheme;
        scheme_info = source.scheme_info;
        _user_info  = source._user_info;
        _host       = source._host;
        _path       = source._path;
        _qstr       = source._qstr;
        _query      = source._query;
        _query.rev  = source._query.rev;
        _qrev       = source._qrev;
        _fragment   = source._fragment;
        _port       = source._port;
        _flags      = source._flags;
    }

    void assign (const string& s, int flags = 0) {
        clear();
        _flags = flags;
        parse(s);
    }

    const string& query_string () const {
        sync_query_string();
        return _qstr;
    }

    const string raw_query () const {
        sync_query_string();
        return decode_uri_component(_qstr);
    }

    Query& query () {
        sync_query();
        return _query;
    }

    const Query& query () const {
        sync_query();
        return _query;
    }

    virtual void scheme (const string& scheme) {
        _scheme = scheme;
        sync_scheme_info();
    }

    void user_info (const string& user_info) { _user_info = user_info; }
    void host      (const string& host)      { _host      = host; }
    void fragment  (const string& fragment)  { _fragment  = fragment; }
    void port      (uint16_t port)           { _port      = port; }

    void path (const string& path) {
        if (path && path.front() != '/') {
            _path = '/';
            _path += path;
        }
        else _path = path;
    }

    void query_string (const string& qstr) {
        _qstr = qstr;
        ok_qstr();
    }

    void raw_query (const string& rq) {
        _qstr.clear();
        encode_uri_component(rq, _qstr, URIComponent::query);
        ok_qstr();
    }

    void query (const string& qstr) { query_string(qstr); }
    void query (const Query& query) {
        _query = query;
        ok_query();
    }

    void add_query (const string& qstr);
    void add_query (const Query& query);

    bool has_param (const string_view& key) const {
        sync_query();
        return _query.find(key) != _query.end();
    }

    const string& param (const string_view& key) const {
        sync_query();
        const auto& cq = _query;
        auto it = cq.find(key);
        return it == cq.cend() ? _empty : it->second;
    }

    void param (const string& key, const string& val);

    void remove_param (const string_view& key) {
        sync_query();
        _query.erase(key);
    }

    auto multiparam (const string_view& key) const -> decltype(Query().equal_range(string_view())) {
        sync_query();
        return _query.equal_range(key);
    }

    void multiparam (const string& key, const std::initializer_list<string>& values);

    string explicit_location () const {
        if (!_port) return _host;
        return location();
    }

    string location () const {
        string ret(_host.length() + 6); // port is 5 chars max
        if (_host) ret += _host;
        ret += ':';
        char* buf = ret.buf(); // has exactly 5 bytes left
        auto len = ret.length();
        auto ptr_start = buf + len;
        auto res = to_chars(ptr_start, buf + ret.capacity(), port());
        assert(!res.ec); // because buf is always enough
        ret.length(len + (res.ptr - ptr_start));
        return ret;
    }

    void location (const string& newloc) {
        if (!newloc) {
            _host.clear();
            _port = 0;
            return;
        }

        size_t delim = newloc.rfind(':');
        if (delim == string::npos) _host.assign(newloc);
        else {
            size_t ipv6end = newloc.rfind(']');
            if (ipv6end != string::npos && ipv6end > delim) _host.assign(newloc);
            else {
                _host.assign(newloc, 0, delim);
                _port = 0;
                from_chars(newloc.data() + delim + 1, newloc.data() + newloc.length(), _port);
            }
        }
    }

    std::vector<string> path_segments () const;

    template <class It>
    void path_segments (It begin, It end) {
        _path.clear();
        for (auto it = begin; it != end; ++it) {
            if (!it->length()) continue;
            _path += '/';
            _encode_uri_component_append(*it, _path, URIComponent::path_segment);
        }
    }

    void path_segments (std::initializer_list<string_view> l) { path_segments(l.begin(), l.end()); }

    string to_string (bool relative = false) const;
    string relative  () const { return to_string(true); }

    bool equals (const URI& uri) const {
        if (_path != uri._path || _host != uri._host || _user_info != uri._user_info || _fragment != uri._fragment || _scheme != uri._scheme) return false;
        if (_port != uri._port && port() != uri.port()) return false;
        sync_query_string();
        uri.sync_query_string();
        return _qstr == uri._qstr;
    }

    void swap (URI& uri);

    string user () const;
    void   user (const string& user);

    string password () const;
    void   password (const string& password);

    virtual ~URI () {}

protected:
    SchemeInfo* scheme_info;

    virtual void parse (const string&);

    static SchemeInfo* get_scheme_info (const std::type_info*);

private:
    string           _scheme;
    string           _user_info;
    string           _host;
    string           _path;
    string           _fragment;
    uint16_t         _port;
    mutable string   _qstr;
    mutable Query    _query;
    mutable uint32_t _qrev; // last query rev we've synced query string with (0 if query itself isn't synced with string)
    int              _flags;

    static const string _empty;

    void ok_qstr      () const { _qrev = 0; }
    void ok_query     () const { _qrev = _query.rev - 1; }
    void ok_qboth     () const { _qrev = _query.rev; }
    bool has_ok_qstr  () const { return !_qrev || _qrev == _query.rev; }
    bool has_ok_query () const { return _qrev != 0; }

    void clear () {
        _port = 0;
        _scheme.clear();
        scheme_info = NULL;
        _user_info.clear();
        _host.clear();
        _path.clear();
        _qstr.clear();
        _query.clear();
        _fragment.clear();
        ok_qboth();
        _flags = 0;
    }

    void guess_suffix_reference ();

    void compile_query () const;
    void parse_query   () const;

    void sync_query_string () const { if (!has_ok_qstr()) compile_query(); }
    void sync_query        () const { if (!has_ok_query()) parse_query(); }

    void sync_scheme_info ();

    static inline void _encode_uri_component_append (const string_view& src, string& dest, const char* unsafe) {
        char* buf = dest.reserve(dest.length() + src.length()*3) + dest.length();
        size_t final_size = encode_uri_component(src, buf, unsafe);
        dest.length(dest.length() + final_size);
    }

    bool _parse     (const string&, bool&);
    bool _parse_ext (const string&, bool&);
};

std::ostream& operator<< (std::ostream& os, const URI& uri);

inline bool operator== (const URI& lhs, const URI& rhs) { return lhs.equals(rhs); }
inline bool operator!= (const URI& lhs, const URI& rhs) { return !lhs.equals(rhs); }
inline void swap (URI& l, URI& r) { l.swap(r); }

}}
