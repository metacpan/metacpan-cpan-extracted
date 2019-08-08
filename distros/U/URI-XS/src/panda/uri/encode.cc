#include <panda/uri/encode.h>
#include <climits>

namespace panda { namespace uri {

#define FROM_HEX(ch) (std::isdigit(ch) ? ch - '0' : std::tolower(ch) - 'a' + 10)
typedef unsigned char uchar;

char unsafe_scheme[256];
char unsafe_uinfo[256];
char unsafe_host[256];
char unsafe_path[256];
char unsafe_path_segment[256];
char unsafe_query[256];
char unsafe_query_component[256];
char unsafe_fragment[256];

static char _restore[256];
static char _forward[256][2];
static char _backward[256][2];

static int init () {
    unsafe_generate(unsafe_scheme, UNSAFE_ALPHA|UNSAFE_DIGIT, "+-.");
    unsafe_generate(unsafe_uinfo, UNSAFE_UNRESERVED | UNSAFE_SUBDELIMS, ":");
    unsafe_generate(unsafe_host, UNSAFE_UNRESERVED | UNSAFE_SUBDELIMS);
    unsafe_generate(unsafe_path, UNSAFE_PCHAR, "/");
    unsafe_generate(unsafe_path_segment, UNSAFE_PCHAR);
    unsafe_generate(unsafe_query, UNSAFE_PCHAR, "/?");
    unsafe_generate(unsafe_query_component, UNSAFE_UNRESERVED);
    unsafe_generate(unsafe_fragment, UNSAFE_PCHAR, "/?");

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

void unsafe_generate (char* unsafe, int flags, const char* chars) {
    if (flags & UNSAFE_DIGIT)      unsafe_generate(unsafe, 0, "0123456789");
    if (flags & UNSAFE_ALPHA)      unsafe_generate(unsafe, 0, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ");
    if (flags & UNSAFE_SUBDELIMS)  unsafe_generate(unsafe, 0, "!$&'()*+,;=");
    if (flags & UNSAFE_GENDELIMS)  unsafe_generate(unsafe, 0, ":/?#[]@");
    if (flags & UNSAFE_RESERVED)   unsafe_generate(unsafe, UNSAFE_SUBDELIMS | UNSAFE_GENDELIMS);
    if (flags & UNSAFE_UNRESERVED) unsafe_generate(unsafe, UNSAFE_ALPHA | UNSAFE_DIGIT, "-._~");
    if (flags & UNSAFE_PCHAR)      unsafe_generate(unsafe, UNSAFE_UNRESERVED | UNSAFE_SUBDELIMS, ":@");
    if (chars) while (char c = *chars++) unsafe[(unsigned char) c] = c;
}

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
