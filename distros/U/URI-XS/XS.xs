#include <xs/uri.h>
#include <unordered_map>
#include <panda/uri/all.h>
#include <panda/string_view.h>

using namespace xs;
using namespace xs::uri;
using namespace panda::uri;
using panda::string;
using panda::string_view;

static char unsafe_query_component_plus[256];
static std::unordered_map<string, Stash> uri_class_map;
static Sv::payload_marker_t data_marker;

// We use make_backref for URI, URI::http, URI::https,
// but we can't use it for URI::ftp/socks because of virtual inheritance of UserPass from Strict with non-empty constructor

class XSURIftp : public URI::ftp, public Backref {
public:
    XSURIftp () : URI::ftp() {}
    XSURIftp (const string& source, int flags = 0) : URI::Strict(source, flags), URI::ftp(source, flags) {}
    XSURIftp (const URI& source)                   : URI::Strict(source),        URI::ftp(source)        {}
    ~XSURIftp() { Backref::dtor(); }
};

class XSURIsocks : public URI::socks, public Backref {
public:
    XSURIsocks () : URI::socks() {}
    XSURIsocks (const string& source, int flags = 0) : URI::Strict(source, flags), URI::socks(source, flags) {}
    XSURIsocks (const URI& source)                   : URI::Strict(source),        URI::socks(source)        {}
    ~XSURIsocks() { Backref::dtor(); }
};

struct XsUriData {
    XsUriData () : query_cache_rev(0) {}

    void sync_query_hash (pTHX_ const URI* uri) {
        Hash hash;
        if (query_cache) {
            hash = query_cache.value<Hash>();
            hash.clear();
        } else {
            hash = Hash::create();
            query_cache = Ref::create(hash);
        }

        auto end = uri->query().cend();
        for (auto it = uri->query().cbegin(); it != end; ++it) hash.store(it->first, Simple(it->second));

        query_cache_rev = uri->query().rev;
    }

    Ref query_hash (pTHX_ const URI* uri) {
        if (!query_cache || query_cache_rev != uri->query().rev) sync_query_hash(aTHX_ uri);
        return query_cache;
    }

private:
    Ref      query_cache;
    uint32_t query_cache_rev;
};

static void register_perl_scheme (pTHX_ const string& scheme, const string_view& perl_class) {
    uri_class_map[scheme] = Stash(perl_class);
}

Stash xs::uri::get_perl_class (const URI* uri) {
    auto it = uri_class_map.find(uri->scheme());
    if (it == uri_class_map.end()) return Stash();
    else return it->second;
}

void xs::uri::data_attach (Sv& sv) {
    void* data = new XsUriData();
    Object(sv).payload_attach(data, &data_marker);
}

static int data_free (pTHX_ SV*, MAGIC* mg) {
    auto data = (XsUriData*)mg->mg_ptr;
    delete data;
    return 0;
}

static XsUriData* data_get (SV* sv) {
    return (XsUriData*)Object(sv).payload(&data_marker).ptr;
}

static void add_param (pTHX_ URI* uri, const string& key, const Scalar& val, bool replace = false) {
    if (val.is_array_ref()) {
        Array arr = val;
        if (replace) uri->query().erase(key);
        auto end = arr.end();
        for (auto it = arr.begin(); it != end; ++it) {
            if (!*it) continue;
            uri->query().emplace(key, xs::in<string>(aTHX_ *it));
        }
    }
    else if (replace) uri->param(key, xs::in<string>(aTHX_ val));
    else uri->query().emplace(key, xs::in<string>(aTHX_ val));
}

static void hash2query (pTHX_ Hash& hash, Query* query) {
    auto end = hash.end();
    for (auto it = hash.begin(); it != end; ++it) {
        string key(it->key());
        auto val = it->value();
        if (val.is_array_ref()) {
            Array arr = val;
            auto end = arr.end();
            for (auto it = arr.begin(); it != end; ++it) {
                if (!*it) continue;
                query->emplace(key, xs::in<string>(aTHX_ *it));
            }
        }
        else query->emplace(key, xs::in<string>(aTHX_ val));
    }
}

static void add_query_hash (pTHX_ URI* uri, Hash& hash, bool replace = false) {
    if (replace) {
        Query query;
        hash2query(aTHX_ hash, &query);
        uri->query(query);
    }
    else {
        auto end = hash.end();
        for (auto it = hash.begin(); it != end; ++it) add_param(aTHX_ uri, string(it->key()), it->value());
    }
}

static void add_query_args (pTHX_ URI* uri, SV** sp, I32 items, bool replace = false) {
    if (items == 1) {
        if (SvROK(*sp)) {
            Hash hash = *sp;
            if (hash) add_query_hash(aTHX_ uri, hash, replace);
        }
        else if (replace) uri->query(xs::in<string>(aTHX_ *sp));
        else              uri->add_query(xs::in<string>(aTHX_ *sp));
    }
    else {
        SV** spe = sp + items;
        for (; sp < spe; sp += 2) add_param(aTHX_ uri, xs::in<string>(aTHX_ *sp), *(sp+1), replace);
    }
}

MODULE = URI::XS                PACKAGE = URI::XS
PROTOTYPES: DISABLE

BOOT {
    unsafe_generate(unsafe_query_component_plus, UNSAFE_UNRESERVED);
    unsafe_query_component_plus[(unsigned char)' '] = '+';
    data_marker.svt_free = data_free;
}

URIx uri (string url = string(), int flags = 0) {
    RETVAL = URI::create(url, flags);
}

void register_scheme (string scheme, string_view perl_class) {
    register_perl_scheme(aTHX_ scheme, perl_class);
}

INCLUDE: encode.xsi
INCLUDE: URI.xsi
INCLUDE: schemas.xsi
INCLUDE: cloning.xsi
