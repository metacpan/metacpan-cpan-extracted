#include <ostream>
#include <stdexcept>
#include <unordered_map>
#include <panda/uri/all.h>

namespace panda { namespace uri {

static std::unordered_map<const string, URI::SchemeInfo> scheme_map;
static std::map<const std::type_info*, URI::SchemeInfo*> scheme_ti_map;
static std::vector<URI::SchemeInfo*> schemas;

static URI::SchemeInfo* http_si;
static URI::SchemeInfo* https_si;

const string URI::_empty;

void URI::register_scheme (const string& scheme, uint16_t default_port, bool secure) {
    register_scheme(scheme, &typeid(URI), [](const URI& u)->URI*{ return new URI(u);  }, default_port, secure);
}

void URI::register_scheme (const string& scheme, const std::type_info* ti, uricreator creator, uint16_t default_port, bool secure) {
    if (scheme_map.find(scheme) != scheme_map.end())
        throw std::invalid_argument("URI::register_scheme: scheme '" + scheme + "' has been already registered");
    auto& inf = scheme_map[scheme];
    inf.index         = schemas.size();
    inf.scheme        = scheme;
    inf.creator       = creator;
    inf.default_port  = default_port;
    inf.secure        = secure;
    inf.type_info     = ti;
    scheme_ti_map[ti] = &inf;
    schemas.push_back(&inf);
}


static int init () {
    URI::register_scheme("http",   &typeid(URI::http),   [](const URI& u)->URI*{ return new URI::http(u);   },   80      );
    URI::register_scheme("https",  &typeid(URI::https),  [](const URI& u)->URI*{ return new URI::https(u);  },  443, true);
    URI::register_scheme("ws",     &typeid(URI::ws),     [](const URI& u)->URI*{ return new URI::ws(u);     },   80      );
    URI::register_scheme("wss",    &typeid(URI::wss),    [](const URI& u)->URI*{ return new URI::wss(u);    },  443, true);
    URI::register_scheme("ftp",    &typeid(URI::ftp),    [](const URI& u)->URI*{ return new URI::ftp(u);    },   21      );
    URI::register_scheme("socks5", &typeid(URI::socks),  [](const URI& u)->URI*{ return new URI::socks(u);  }, 1080      );
    URI::register_scheme("ssh",    &typeid(URI::ssh),    [](const URI& u)->URI*{ return new URI::ssh(u);    },   22, true);
    URI::register_scheme("telnet", &typeid(URI::telnet), [](const URI& u)->URI*{ return new URI::telnet(u); },   23      );
    URI::register_scheme("sftp",   &typeid(URI::sftp),   [](const URI& u)->URI*{ return new URI::sftp(u);   },   22, true);

    http_si  = &scheme_map.find("http")->second;
    https_si = &scheme_map.find("https")->second;

    return 0;
}
static const int __init = init();

void URI::parse (const string& str) {
    bool authority_has_pct = false;
    bool ok = !(_flags & Flags::allow_extended_chars) ? _parse(str, authority_has_pct) : _parse_ext(str, authority_has_pct);

    if (!ok) {
        clear();
        return;
    }

    if (authority_has_pct) {
        decode_uri_component(_user_info, _user_info);
        decode_uri_component(_host, _host);
    }

    if (_qstr) ok_qstr();
    if (_flags & Flags::allow_suffix_reference && !_host.length()) guess_suffix_reference();
    sync_scheme_info();
}

void URI::guess_suffix_reference () {
    // try to find out if it was an url with leading authority ('ya.ru', 'ya.ru:80/a/b/c', 'user@mysite.com/a/b/c')
    // in either case host is always empty and there are 2 cases
    // 1) if no scheme -> host is first path part, port is absent
    // 2) if scheme is present and first path part is a valid port -> scheme is host, first path part is port.
    // otherwise leave parsed url unchanged as it has no leading authority
    if (!_scheme.length()) {
        size_t delim = _path.find('/');
        if (delim == string::npos) {
            _host = _path;
            _path.clear();
        } else {
            _host.assign(_path, 0, delim);
            _path.erase(0, delim);
        }
        return;
    }

    bool ok = false;
    size_t plen = _path.length();
    const char* p = _path.data();
    size_t i = 0;
    for (; i < plen; ++i) {
        char c = p[i];
        if (c >= '0' && c <= '9') {
            _port = _port * 10 + c - '0';
            ok = true;
            continue;
        }
        if (c != '/') { _port = 0; return; }
        break;
    }

    if (!ok) return;
    _host = _scheme;
    _scheme.clear();
    _path.erase(0, i);
}

string URI::to_string (bool relative) const {
    sync_query_string();
    size_t approx_len = _path.length() + _fragment.length() + _qstr.length() + 3;
    if (!relative) approx_len += (_scheme.length()+3) + (_user_info.length()*3 + 1) + (_host.length()*3 + 6);
    string str(approx_len);

    if (!relative) {
        if (_scheme.length()) {
            str += _scheme;
            if (_host.length()) str += "://";
            else str += ':';
        }
        else if (_host.length()) str += "//";

        if (_host.length()) {
            if (_user_info.length()) {
                _encode_uri_component_append(_user_info, str, URIComponent::user_info);
                str += '@';
            }

            const auto& chost = _host;
            if (chost.front() == '[' && chost.back() == ']') str += _host;
            else _encode_uri_component_append(_host, str, URIComponent::host);

            if (_port) {
                str += ':';
                str += string::from_number(_port);
            }
        }
    }

    if (_path.length()) str += _path;
    else if (relative) str += '/'; // relative path MUST NOT be empty

    if (_qstr.length()) {
        str += '?';
        str += _qstr; // as is, because already encoded either by raw_query setter or by compile_query
    }

    if (_fragment.length()) {
        str += '#';
        str += _fragment;
    }

    return str;
}

void URI::parse_query () const {
    enum { PARSE_MODE_KEY, PARSE_MODE_VAL, PARSE_MODE_WRITE } mode = PARSE_MODE_KEY;
    int key_start = 0;
    int key_end   = 0;
    int val_start = 0;
    bool has_pct = false;
    const char delim = _flags & Flags::query_param_semicolon ? ';' : '&';
    const char* str = _qstr.data();
    int len = _qstr.length();
    _query.clear();

    if (len) for (int i = 0; i <= len; ++i) {
        char c = (i == len) ? delim : str[i];
        if (c == '=' && mode == PARSE_MODE_KEY) {
            key_end = i;
            mode = PARSE_MODE_VAL;
            val_start = i+1;
        }
        else if (c == '%') {
            has_pct = true;
        }
        else if (c == delim) {
            if (mode == PARSE_MODE_KEY) {
                key_end = i;
                val_start = i;
            }

            if (has_pct) {
                string key, value;
                size_t klen = key_end - key_start;
                if (klen > 0) decode_uri_component(string_view(str+key_start, klen), key);

                size_t vlen = i - val_start;
                if (vlen > 0) decode_uri_component(string_view(str+val_start, vlen), value);

                has_pct = false;
                _query.emplace(key, value);
            } else {
                _query.emplace(_qstr.substr(key_start, key_end - key_start), _qstr.substr(val_start, i - val_start));
            }

            mode = PARSE_MODE_KEY;
            key_start = i+1;
        }
    }

    ok_qboth();
}

void URI::compile_query () const {
    _qstr.clear();
    const char delim = _flags & Flags::query_param_semicolon ? ';' : '&';
    auto begin = _query.cbegin();
    auto end   = _query.cend();

    size_t bufsize = 0;
    for (auto it = begin; it != end; ++it) bufsize += (it->first.length() + it->second.length())*3 + 2;
    if (bufsize) --bufsize;

    _qstr.reserve(bufsize);

    char* bufp = _qstr.buf();
    char* ptr = bufp;
    for (auto it = begin; it != end; ++it) {
        if (it != begin) *ptr++ = delim;
        ptr += encode_uri_component(it->first, ptr);
        *ptr++ = '=';
        ptr += encode_uri_component(it->second, ptr);
    }
    _qstr.length(ptr-bufp);

    ok_qboth();
}

void URI::add_query (const string& addstr) {
    if (!addstr) return;
    sync_query_string();
    ok_qstr();
    if (_qstr) {
        _qstr.reserve(_qstr.length() + addstr.length() + 1);
        _qstr += '&';
        _qstr += addstr;
    }
    else _qstr = addstr;
}

void URI::add_query (const Query& addquery) {
    sync_query();
    auto end = addquery.cend();
    for (auto it = addquery.cbegin(); it != end; ++it) _query.emplace(it->first, it->second);
    ok_query();
}

void URI::param (const string& key, const string& val) {
    sync_query();
    auto range = _query.equal_range(key);

    if (range.first == range.second) {
        _query.emplace(key, val);
        return;
    }

    range.first->second.assign(val);

    _query.erase(++range.first, range.second);
}

void URI::multiparam (const string& key, const std::initializer_list<string>& values) {
    sync_query();
    auto range = _query.equal_range(key);
    for (auto& val : values) {
        if (range.first == range.second) {
            _query.emplace(key, val);
        } else {
            range.first->second.assign(val);
            ++range.first;
        }
    }

    _query.erase(range.first, range.second);
}

std::vector<string> URI::path_segments () const {
    size_t plen = _path.length();
    if (!plen) return std::vector<string>();
    std::vector<string> ret;
    ret.reserve(7);
    const char* p = _path.data();
    size_t start = 0;
    for (size_t i = 0; i < plen; ++i) {
        if (p[i] != '/') continue;
        if (i == start) { start++; continue; }
        ret.push_back(decode_uri_component(string_view(p+start, i-start)));
        start = i+1;
    }
    if (p[plen-1] != '/') ret.push_back(string(p+start, plen-start));
    return ret;
}

void URI::swap (URI& uri) {
    std::swap(_scheme,     uri._scheme);
    std::swap(scheme_info, uri.scheme_info);
    std::swap(_user_info,  uri._user_info);
    std::swap(_host,       uri._host);
    std::swap(_port,       uri._port);
    std::swap(_path,       uri._path);
    std::swap(_qstr,       uri._qstr);
    std::swap(_query,      uri._query);
    std::swap(_qrev,       uri._qrev);
    std::swap(_fragment,   uri._fragment);
    std::swap(_flags,      uri._flags);
}

void URI::sync_scheme_info () {
    if (!_scheme) {
        scheme_info = NULL;
        return;
    }

    auto len = _scheme.length();
    if (len >= 4 && (_scheme[0]|0x20) == 'h' && (_scheme[1]|0x20) == 't' && (_scheme[2]|0x20) == 't' && (_scheme[3]|0x20) == 'p') {
        if (len == 4) {
            scheme_info = http_si;
            _scheme = "http";
        }
        else if (len == 5 && (_scheme[4]|0x20) == 's') {
            scheme_info = https_si;
            _scheme = "https";
            return;
        }
        return;
    }

    // lowercase the scheme
    char* p   = _scheme.buf();
    char* end = p + _scheme.length();
    for (;p != end; ++p) *p = tolower(*p);

    auto it = scheme_map.find(_scheme);
    if (it == scheme_map.cend()) scheme_info = NULL;
    else                         scheme_info = &it->second;
}

URI::SchemeInfo* URI::get_scheme_info (const std::type_info* ti) {
    auto it = scheme_ti_map.find(ti);
    return it == scheme_ti_map.end() ? nullptr : it->second;
}

string URI::user () const {
    size_t delim = _user_info.find(':');
    if (delim == string::npos) return _user_info;
    return _user_info.substr(0, delim);
}

void URI::user (const string& user) {
    size_t delim = _user_info.find(':');
    if (delim == string::npos) _user_info = user;
    else _user_info.replace(0, delim, user);
}

string URI::password () const {
    size_t delim = _user_info.find(':');
    if (delim == string::npos) return string();
    return _user_info.substr(delim+1);
}

void URI::password (const string& password) {
    size_t delim = _user_info.find(':');
    if (delim == string::npos) {
        _user_info += ':';
        _user_info += password;
    }
    else _user_info.replace(delim+1, string::npos, password);
}

std::ostream& operator<< (std::ostream& os, const URI& uri) {
    string tmp = uri.to_string();
    return os.write(tmp.data(), tmp.length());
}

}}
