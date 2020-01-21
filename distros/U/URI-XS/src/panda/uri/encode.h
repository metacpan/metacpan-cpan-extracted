#pragma once
#include <panda/string.h>

namespace panda { namespace uri {

struct URIComponent {
    static char scheme[256];
    static char user_info[256];
    static char host[256];
    static char path[256];
    static char path_segment[256];
    static char query[256];
    static char query_param[256];
    static char query_param_plus[256];
    static char fragment[256];
};

size_t encode_uri_component (const string_view src, char* dest, const char* component = URIComponent::query_param);
size_t decode_uri_component (const string_view src, char* dest);

inline void encode_uri_component (const string_view src, panda::string& dest, const char* component = URIComponent::query_param) {
    size_t final_size = encode_uri_component(src, dest.reserve(src.length()*3), component);
    dest.length(final_size);
}

inline void decode_uri_component (const string_view src, panda::string& dest) {
    size_t final_size = decode_uri_component(src, dest.reserve(src.length()));
    dest.length(final_size);
}

inline panda::string encode_uri_component (const string_view src, const char* component = URIComponent::query_param) {
    panda::string ret;
    encode_uri_component(src, ret, component);
    return ret;
}

inline panda::string decode_uri_component (const string_view src) {
    panda::string ret;
    decode_uri_component(src, ret);
    return ret;
}

}}
