#include <panda/uri/encode.h>
#include <climits>

namespace panda { namespace uri {

#define FROM_HEX(ch) (std::isdigit(ch) ? ch - '0' : std::tolower(ch) - 'a' + 10)
typedef unsigned char uchar;

char URIComponent::scheme[256];
char URIComponent::user_info[256];
char URIComponent::host[256];
char URIComponent::path[256];
char URIComponent::path_segment[256];
char URIComponent::query[256];
char URIComponent::query_param[256];
char URIComponent::query_param_plus[256];
char URIComponent::fragment[256];

static char _restore[256];
static char _forward[256][2];
static char _backward[256][2];

static const int UNSAFE_DIGIT      =  1;
static const int UNSAFE_ALPHA      =  2;
static const int UNSAFE_SUBDELIMS  =  4;
static const int UNSAFE_GENDELIMS  =  8;
static const int UNSAFE_RESERVED   = 16;
static const int UNSAFE_UNRESERVED = 32;
static const int UNSAFE_PCHAR      = 64;

static void unsafe_generate (char* unsafe, int flags, const char* chars = nullptr) {
    if (flags & UNSAFE_DIGIT)      unsafe_generate(unsafe, 0, "0123456789");
    if (flags & UNSAFE_ALPHA)      unsafe_generate(unsafe, 0, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ");
    if (flags & UNSAFE_SUBDELIMS)  unsafe_generate(unsafe, 0, "!$&'()*+,;=");
    if (flags & UNSAFE_GENDELIMS)  unsafe_generate(unsafe, 0, ":/?#[]@");
    if (flags & UNSAFE_RESERVED)   unsafe_generate(unsafe, UNSAFE_SUBDELIMS | UNSAFE_GENDELIMS);
    if (flags & UNSAFE_UNRESERVED) unsafe_generate(unsafe, UNSAFE_ALPHA | UNSAFE_DIGIT, "-._~");
    if (flags & UNSAFE_PCHAR)      unsafe_generate(unsafe, UNSAFE_UNRESERVED | UNSAFE_SUBDELIMS, ":@");
    if (chars) while (char c = *chars++) unsafe[(unsigned char) c] = c;
}

static int init () {
    unsafe_generate(URIComponent::scheme, UNSAFE_ALPHA|UNSAFE_DIGIT, "+-.");
    unsafe_generate(URIComponent::user_info, UNSAFE_UNRESERVED | UNSAFE_SUBDELIMS, ":");
    unsafe_generate(URIComponent::host, UNSAFE_UNRESERVED | UNSAFE_SUBDELIMS);
    unsafe_generate(URIComponent::path, UNSAFE_PCHAR, "/");
    unsafe_generate(URIComponent::path_segment, UNSAFE_PCHAR);
    unsafe_generate(URIComponent::query, UNSAFE_PCHAR, "/?");
    unsafe_generate(URIComponent::query_param, UNSAFE_UNRESERVED);
    unsafe_generate(URIComponent::fragment, UNSAFE_PCHAR, "/?");

    unsafe_generate(URIComponent::query_param_plus, UNSAFE_UNRESERVED);
    URIComponent::query_param_plus[(unsigned char)' '] = '+';

    static char hex[] = "0123456789ABCDEF";
    char c = CHAR_MIN;
    do {
        uchar uc = (uchar)c;
        _restore[uc] = c;
        _forward[uc][0] = hex[(c >> 4) & 15];
        _forward[uc][1] = hex[(c & 15) & 15];
        _backward[uc][0] = FROM_HEX(c) << 4;
        _backward[uc][1] = FROM_HEX(c);
    } while (c++ != CHAR_MAX);

    _restore[(uchar)'%'] = 0;
    _restore[(uchar)'+'] = ' ';

    return 0;
}
static int __init = init();

size_t encode_uri_component (const string_view src, char* dest, const char* unsafe) {
    const char* str = src.data();
    const char*const end = str + src.length();
    char* buf = dest;

    while (str != end) {
        uchar uc = *str++;
        if (unsafe[uc] != 0) *buf++ = unsafe[uc];
        else {
            *buf++ = '%';
            *buf++ = _forward[uc][0];
            *buf++ = _forward[uc][1];
        }
    }

    return buf - dest;
}

size_t decode_uri_component (const string_view src, char* dest) {
    const char* str = src.data();
    const char*const end = str + src.length();
    char* buf = dest;

    while (str != end) {
        char res = _restore[(uchar)*str++];
        if (res != 0) *buf++ = res;
        else if (str < end-1) {
            *buf++ = _backward[(uchar)str[0]][0] | _backward[(uchar)str[1]][1];
            str += 2;
        }
    }

    return buf - dest;
}

}}
