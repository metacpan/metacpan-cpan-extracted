#include <xs/uri.h>
#include <xs/export.h>
#include <unordered_map>
#include <panda/uri/all.h>
#include <panda/string_view.h>

using namespace xs;
using namespace xs::uri;
using namespace panda::uri;
using panda::string;
using panda::string_view;

static std::unordered_map<string, Stash> uri_class_map;
static Sv::payload_marker_t data_marker;

struct XsUriData {
    XsUriData () : query_cache_rev(0) {}

    void sync_query_hash (const URI* uri) {
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

    Ref query_hash (const URI* uri) {
        if (!query_cache || query_cache_rev != uri->query().rev) sync_query_hash(uri);
        return query_cache;
    }

private:
    Ref      query_cache;
    uint32_t query_cache_rev;
};

static void register_perl_scheme (const string& scheme, const string_view& perl_class) {
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

static void add_param (URI* uri, const string& key, const Scalar& val, bool replace = false) {
    if (val.is_array_ref()) {
        Array arr = val;
        if (replace) uri->query().erase(key);
        auto end = arr.end();
        for (auto it = arr.begin(); it != end; ++it) {
            if (!*it) continue;
            uri->query().emplace(key, xs::in<string>(*it));
        }
    }
    else if (replace) uri->param(key, xs::in<string>(val));
    else uri->query().emplace(key, xs::in<string>(val));
}

static void hash2query (Hash& hash, Query* query) {
    auto end = hash.end();
    for (auto it = hash.begin(); it != end; ++it) {
        string key(it->key());
        auto val = it->value();
        if (val.is_array_ref()) {
            Array arr = val;
            auto end = arr.end();
            for (auto it = arr.begin(); it != end; ++it) {
                if (!*it) continue;
                query->emplace(key, xs::in<string>(*it));
            }
        }
        else query->emplace(key, xs::in<string>(val));
    }
}

static void add_query_hash (URI* uri, Hash& hash, bool replace = false) {
    if (replace) {
        Query query;
        hash2query(hash, &query);
        uri->query(query);
    }
    else {
        auto end = hash.end();
        for (auto it = hash.begin(); it != end; ++it) add_param(uri, string(it->key()), it->value());
    }
}

static void add_query_args (URI* uri, SV** sp, I32 items, bool replace = false) {
    if (items == 1) {
        if (SvROK(*sp)) {
            Hash hash = *sp;
            if (hash) add_query_hash(uri, hash, replace);
        }
        else if (replace) uri->query(xs::in<string>(*sp));
        else              uri->add_query(xs::in<string>(*sp));
    }
    else {
        SV** spe = sp + items;
        for (; sp < spe; sp += 2) add_param(uri, xs::in<string>(*sp), *(sp+1), replace);
    }
}

MODULE = URI::XS                PACKAGE = URI::XS
PROTOTYPES: DISABLE

BOOT {
    data_marker.svt_free = data_free;
    
    xs::at_perl_destroy([]{
        uri_class_map.clear();
    });
}

URIx uri (string url = string(), int flags = 0) {
    RETVAL = URI::create(url, flags);
}

void register_scheme (string scheme, string_view perl_class) {
    register_perl_scheme(scheme, perl_class);
}

uint64_t bench_parse (string str, int flags = 0) {
    RETVAL = 0;
    for (int i = 0; i < 1000; ++i) {
        URI u(str, flags);
        RETVAL += u.path().length();
    }
}

void test_parse (string str) {
    auto uri = URI(str);
    printf("scheme=%s\n", uri.scheme().c_str());
    printf("userinfo=%s\n", uri.user_info().c_str());
    printf("host=%s\n", uri.host().c_str());
    printf("port=%d\n", uri.port());
    printf("path=%s\n", uri.path().c_str());
    printf("query=%s\n", uri.raw_query().c_str());
    printf("fragment=%s\n", uri.fragment().c_str());
}

void bench_parse_query (string str) {
    URI u;
    for (int i = 0; i < 1000; ++i) {
        u.query_string(str);
        u.query();
    }
}

uint64_t bench_encode_uri_component (string_view str) {
    RETVAL = 0;
    auto dest = (char*)alloca(str.length() * 3);
    for (int i = 0; i < 1000; ++i) {
        encode_uri_component(str, dest);
    }
}

uint64_t bench_decode_uri_component (string_view str) {
    RETVAL = 0;
    auto dest = (char*)alloca(str.length());
    for (int i = 0; i < 1000; ++i) {
        decode_uri_component(str, dest);
    }
}

INCLUDE: encode.xsi
INCLUDE: URI.xsi
INCLUDE: schemas.xsi
INCLUDE: cloning.xsi
