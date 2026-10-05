#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "uniform_http_fastpath.h"
#include "unblock_http1_native_abi.h"

#include "vendor/picohttpparser/picohttpparser.c"

#define UB_HTTP1_MAX_HEADERS 256
#define UB_BODY_NONE 0
#define UB_BODY_CONTENT_LENGTH 1
#define UB_BODY_CHUNKED 2

static int
ascii_equal_ci(const char *left, size_t left_len, const char *right, size_t right_len)
{
    size_t i;
    if (left_len != right_len)
        return 0;
    for (i = 0; i < left_len; ++i) {
        unsigned char a = (unsigned char)left[i];
        unsigned char b = (unsigned char)right[i];
        if (a >= 'A' && a <= 'Z') a = (unsigned char)(a + ('a' - 'A'));
        if (b >= 'A' && b <= 'Z') b = (unsigned char)(b + ('a' - 'A'));
        if (a != b) return 0;
    }
    return 1;
}

static int
is_ows(unsigned char c)
{
    return c == ' ' || c == '\t';
}

static int
is_tchar(unsigned char c)
{
    if ((c >= '0' && c <= '9') ||
        (c >= 'A' && c <= 'Z') ||
        (c >= 'a' && c <= 'z'))
        return 1;
    switch (c) {
        case '!': case '#': case '$': case '%': case '&': case '\'':
        case '*': case '+': case '-': case '.': case '^': case '_':
        case 0x60: case '|': case '~':
            return 1;
        default:
            return 0;
    }
}

static int
valid_field_name(const char *name, size_t len)
{
    size_t i;
    if (len == 0) return 0;
    for (i = 0; i < len; ++i)
        if (!is_tchar((unsigned char)name[i])) return 0;
    return 1;
}

static int
valid_field_value(const char *value, size_t len)
{
    size_t i;
    for (i = 0; i < len; ++i) {
        unsigned char c = (unsigned char)value[i];
        if (c == '\t') continue;
        if (c < 0x20 || c == 0x7f) return 0;
    }
    return 1;
}

static int
valid_host_value(const char *value, size_t len)
{
    size_t i;
    size_t close_bracket = (size_t)-1;
    size_t colon_count = 0;
    if (len == 0) return 1;
    for (i = 0; i < len; ++i) {
        unsigned char c = (unsigned char)value[i];
        if (c <= 0x20 || c >= 0x7f) return 0;
        if (c == '/' || c == '?' || c == '#' || c == '@') return 0;
    }
    if (value[0] == '[') {
        for (i = 1; i < len; ++i) {
            if (value[i] == ']') { close_bracket = i; break; }
        }
        if (close_bracket == (size_t)-1 || close_bracket == 1) return 0;
        if (close_bracket + 1 == len) return 1;
        if (value[close_bracket + 1] != ':') return 0;
        if (close_bracket + 2 == len) return 1;
        for (i = close_bracket + 2; i < len; ++i)
            if (value[i] < '0' || value[i] > '9') return 0;
        return 1;
    }
    for (i = 0; i < len; ++i) {
        if (value[i] == ':') {
            size_t j;
            ++colon_count;
            if (colon_count > 1) return 0;
            for (j = i + 1; j < len; ++j)
                if (value[j] < '0' || value[j] > '9') return 0;
            break;
        }
    }
    return 1;
}

static int
ascii_equal_cs(const char *left, size_t left_len, const char *right, size_t right_len)
{
    return left_len == right_len && memEQ(left, right, right_len);
}

static int
valid_port_number(const char *value, size_t len)
{
    size_t i;
    unsigned int port = 0;
    if (len == 0) return 0;
    for (i = 0; i < len; ++i) {
        unsigned int digit;
        if (value[i] < '0' || value[i] > '9') return 0;
        digit = (unsigned int)(value[i] - '0');
        if (port > 6553 || (port == 6553 && digit > 5)) return 0;
        port = port * 10 + digit;
    }
    return port != 0;
}

static int
valid_connect_authority(const char *target, size_t len)
{
    size_t i;
    if (len < 3) return 0;

    if (target[0] == '[') {
        size_t close_bracket = (size_t)-1;
        for (i = 1; i < len; ++i) {
            if (target[i] == ']') {
                close_bracket = i;
                break;
            }
        }
        if (close_bracket == (size_t)-1 || close_bracket == 1) return 0;
        if (close_bracket + 2 >= len || target[close_bracket + 1] != ':')
            return 0;
        for (i = 1; i < close_bracket; ++i) {
            unsigned char ch = (unsigned char)target[i];
            if (ch <= 0x20 || ch == 0x7f ||
                ch == '/' || ch == '?' || ch == '#' || ch == '@')
                return 0;
        }
        return valid_port_number(
            target + close_bracket + 2,
            len - close_bracket - 2
        );
    }

    {
        size_t colon = (size_t)-1;
        for (i = 0; i < len; ++i) {
            unsigned char ch = (unsigned char)target[i];
            if (ch <= 0x20 || ch == 0x7f ||
                ch == '/' || ch == '?' || ch == '#' || ch == '@')
                return 0;
            if (target[i] == ':') {
                if (colon != (size_t)-1) return 0;
                colon = i;
            }
        }
        if (colon == (size_t)-1 || colon == 0 || colon + 1 == len) return 0;
        return valid_port_number(target + colon + 1, len - colon - 1);
    }
}

static int
connect_host_matches_target(const char *host, size_t host_len,
                            const char *target, size_t target_len)
{
    size_t target_host_len = 0;
    size_t compare_host_len = host_len;
    size_t i;

    if (ascii_equal_ci(host, host_len, target, target_len))
        return 1;

    if (host_len && host[host_len - 1] == ':')
        --compare_host_len;

    if (target_len == 0)
        return 0;

    if (target[0] == '[') {
        for (i = 1; i < target_len; ++i) {
            if (target[i] == ']') {
                target_host_len = i + 1;
                break;
            }
        }
    } else {
        for (i = 0; i < target_len; ++i) {
            if (target[i] == ':') {
                target_host_len = i;
                break;
            }
        }
    }

    return target_host_len != 0
        && ascii_equal_ci(host, compare_host_len, target, target_host_len);
}

static int
valid_request_target(const char *method, size_t method_len,
                     const char *target, size_t target_len)
{
    size_t i;
    if (target_len == 0) return 0;

    for (i = 0; i < target_len; ++i)
        if (target[i] == '#') return 0;

    if (target_len == 1 && target[0] == '*')
        return ascii_equal_cs(method, method_len, "OPTIONS", 7);

    if (ascii_equal_cs(method, method_len, "CONNECT", 7))
        return valid_connect_authority(target, target_len);

    if (target[0] == '/') return 1;

    if (!((target[0] >= 'A' && target[0] <= 'Z') ||
          (target[0] >= 'a' && target[0] <= 'z')))
        return 0;

    for (i = 1; i < target_len; ++i) {
        unsigned char ch = (unsigned char)target[i];
        if (ch == ':') {
            if (ascii_equal_ci(target, i, "http", 4) ||
                ascii_equal_ci(target, i, "https", 5)) {
                size_t pos = i + 1;
                size_t authority_start;

                if (pos + 1 >= target_len ||
                    target[pos] != '/' || target[pos + 1] != '/')
                    return 0;

                pos += 2;
                authority_start = pos;
                while (pos < target_len &&
                       target[pos] != '/' && target[pos] != '?') {
                    if (target[pos] == '@')
                        return 0;
                    ++pos;
                }
                if (pos == authority_start || target[authority_start] == ':')
                    return 0;
            }
            return 1;
        }
        if (!((ch >= 'A' && ch <= 'Z') ||
              (ch >= 'a' && ch <= 'z') ||
              (ch >= '0' && ch <= '9') ||
              ch == '+' || ch == '-' || ch == '.'))
            return 0;
    }
    return 0;
}

static int
parse_content_length(const char *value, size_t len, UV *out, int *seen)
{
    size_t pos = 0;
    int members = 0;
    const UV uv_max = ~(UV)0;
    while (1) {
        UV parsed = 0;
        int digits = 0;
        while (pos < len && is_ows((unsigned char)value[pos])) ++pos;
        if (pos == len) return 0;
        while (pos < len && value[pos] >= '0' && value[pos] <= '9') {
            UV digit = (UV)(value[pos] - '0');
            if (parsed > uv_max / 10 ||
                (parsed == uv_max / 10 && digit > uv_max % 10))
                return 0;
            parsed = parsed * 10 + digit;
            ++pos;
            ++digits;
        }
        if (!digits) return 0;
        while (pos < len && is_ows((unsigned char)value[pos])) ++pos;
        if (*seen) {
            if (*out != parsed) return 0;
        } else {
            *out = parsed;
            *seen = 1;
        }
        ++members;
        if (pos == len) break;
        if (value[pos] != ',') return 0;
        ++pos;
    }
    return members != 0;
}

static int
parse_connection(const char *value, size_t len, int *close_seen, int *keep_seen)
{
    size_t pos = 0;
    while (pos < len) {
        size_t start, end, i;
        while (pos < len && is_ows((unsigned char)value[pos])) ++pos;
        start = pos;
        while (pos < len && value[pos] != ',') ++pos;
        end = pos;
        while (end > start && is_ows((unsigned char)value[end - 1])) --end;
        if (end > start) {
            for (i = start; i < end; ++i)
                if (!is_tchar((unsigned char)value[i]))
                    return 0;
            if (ascii_equal_ci(value + start, end - start, "close", 5))
                *close_seen = 1;
            else if (ascii_equal_ci(value + start, end - start, "keep-alive", 10))
                *keep_seen = 1;
        }
        if (pos < len) ++pos;
    }
    return 1;
}

static int
parse_transfer_encoding(const char *value, size_t len,
                        int *count, int *chunked_count,
                        int *final_chunked, int *unsupported)
{
    size_t pos = 0;
    while (1) {
        size_t start, token_end, member_end, tail;
        int chunked;
        while (pos < len && is_ows((unsigned char)value[pos])) ++pos;
        if (pos == len) return 0;
        start = pos;
        while (pos < len && is_tchar((unsigned char)value[pos])) ++pos;
        token_end = pos;
        if (token_end == start) return 0;
        while (pos < len && value[pos] != ',') ++pos;
        member_end = pos;
        while (member_end > token_end && is_ows((unsigned char)value[member_end - 1])) --member_end;
        chunked = ascii_equal_ci(value + start, token_end - start, "chunked", 7);
        if (chunked) {
            tail = token_end;
            while (tail < member_end && is_ows((unsigned char)value[tail])) ++tail;
            if (tail != member_end) return 0;
            ++*chunked_count;
        } else {
            *unsupported = 1;
        }
        ++*count;
        *final_chunked = chunked;
        if (pos == len) break;
        ++pos;
    }
    return *count != 0;
}

static int
parse_expect(const char *value, size_t len)
{
    size_t pos = 0;
    int members = 0;
    while (1) {
        size_t start, end;
        while (pos < len && is_ows((unsigned char)value[pos])) ++pos;
        start = pos;
        while (pos < len && value[pos] != ',') ++pos;
        end = pos;
        while (end > start && is_ows((unsigned char)value[end - 1])) --end;
        if (end == start || !ascii_equal_ci(value + start, end - start, "100-continue", 12))
            return -1;
        ++members;
        if (pos == len) break;
        ++pos;
    }
    return members ? 1 : -1;
}

static SV *
new_error_result(pTHX_ int status, const char *message)
{
    HV *hv = newHV();
    hv_store(hv, "ok", 2, newSViv(0), 0);
    if (status) hv_store(hv, "status", 6, newSViv(status), 0);
    hv_store(hv, "error", 5, newSVpv(message, 0), 0);
    return newRV_noinc((SV *)hv);
}

static AV *
headers_to_av(pTHX_ const struct phr_header *headers, size_t count)
{
    AV *out = newAV();
    size_t i;
    for (i = 0; i < count; ++i) {
        const char *value = headers[i].value;
        size_t value_len = headers[i].value_len;
        AV *pair;
        while (value_len && is_ows((unsigned char)*value)) { ++value; --value_len; }
        while (value_len && is_ows((unsigned char)value[value_len - 1])) --value_len;
        pair = newAV();
        av_push(pair, newSVpvn(headers[i].name, (STRLEN)headers[i].name_len));
        av_push(pair, newSVpvn(value, (STRLEN)value_len));
        av_push(out, newRV_noinc((SV *)pair));
    }
    return out;
}

static int
strict_headers(const struct phr_header *headers, size_t count)
{
    size_t i;
    for (i = 0; i < count; ++i) {
        if (headers[i].name == NULL ||
            !valid_field_name(headers[i].name, headers[i].name_len) ||
            !valid_field_value(headers[i].value, headers[i].value_len))
            return 0;
    }
    return 1;
}


static SV *
ub_http1_parse_request_head_result(
    pTHX_
    const char *buf,
    size_t buffer_len,
    size_t last_len,
    size_t max_headers,
    const uhttp_native_api *uniform_api,
    SV **request_out
)
{
    const char *method;
    size_t method_len;
    const char *target;
    size_t target_len;
    int minor;
    struct phr_header headers[UB_HTTP1_MAX_HEADERS];
    size_t count;
    int consumed;
    size_t i;
    int host_count = 0;
    int has_cl = 0;
    UV content_length = 0;
    int te_present = 0;
    int te_count = 0;
    int chunked_count = 0;
    int final_chunked = 0;
    int unsupported = 0;
    int close_seen = 0;
    int keep_seen = 0;
    int expect_mode = 0;
    int body_mode = UB_BODY_NONE;
    int is_connect = 0;
    const char *host_value = NULL;
    size_t host_value_len = 0;
    uhttp_native_field native_headers[UB_HTTP1_MAX_HEADERS];
    char version_bytes[3];
    SV *native_request = NULL;
    HV *hv;
    AV *list;

    if (request_out != NULL)
        *request_out = NULL;

    if (last_len > buffer_len)
        croak("last_len exceeds input window length");
    if (max_headers == 0 || max_headers > UB_HTTP1_MAX_HEADERS)
        croak("max_headers must be between 1 and %d", UB_HTTP1_MAX_HEADERS);

    count = max_headers;
    consumed = phr_parse_request(
        buf, buffer_len,
        &method, &method_len, &target, &target_len, &minor,
        headers, &count, last_len
    );

    if (consumed == -2)
        return NULL;

    if (consumed == -1) {
        if (count == max_headers)
            return new_error_result(
                aTHX_ 431, "too many HTTP/1 request header fields"
            );
        return new_error_result(aTHX_ 400, "malformed HTTP/1 request");
    }

    if (minor < 0 || minor > 9)
        return new_error_result(aTHX_ 505, "unsupported HTTP/1 version");

    if (!strict_headers(headers, count))
        return new_error_result(
            aTHX_ 400, "invalid or folded HTTP/1 header field"
        );

    {
        const char *error = NULL;
        int error_status = 0;

        is_connect = ascii_equal_cs(method, method_len, "CONNECT", 7);
        if (!valid_request_target(method, method_len, target, target_len)) {
            error = "invalid HTTP/1 request target";
            error_status = 400;
        }
        if (!error && is_connect && minor == 0) {
            error = "CONNECT requires HTTP/1.1 semantics";
            error_status = 400;
        }

        for (i = 0; i < count && !error; ++i) {
            const char *name = headers[i].name;
            size_t name_len = headers[i].name_len;
            const char *value = headers[i].value;
            size_t value_len = headers[i].value_len;

            if (ascii_equal_ci(name, name_len, "Host", 4)) {
                ++host_count;
                if (host_count == 1) {
                    host_value = value;
                    host_value_len = value_len;
                }
                if (!valid_host_value(value, value_len)) {
                    error = "invalid Host field";
                    error_status = 400;
                }
            } else if (ascii_equal_ci(
                    name, name_len, "Content-Length", 14)) {
                if (!parse_content_length(
                        value, value_len,
                        &content_length, &has_cl)) {
                    error = "invalid or conflicting Content-Length";
                    error_status = 400;
                }
            } else if (ascii_equal_ci(
                    name, name_len, "Transfer-Encoding", 17)) {
                te_present = 1;
                if (!parse_transfer_encoding(
                        value, value_len,
                        &te_count, &chunked_count,
                        &final_chunked, &unsupported)) {
                    error = "invalid Transfer-Encoding";
                    error_status = 400;
                }
            } else if (ascii_equal_ci(
                    name, name_len, "Connection", 10)) {
                if (!parse_connection(
                        value, value_len, &close_seen, &keep_seen)) {
                    error = "invalid Connection field";
                    error_status = 400;
                }
            } else if (ascii_equal_ci(name, name_len, "Expect", 6)) {
                int e = parse_expect(value, value_len);
                if (minor == 0) {
                    expect_mode = 0;
                } else if (e < 0) {
                    expect_mode = -1;
                } else if (expect_mode >= 0) {
                    expect_mode = 1;
                }
            }
        }

        if (!error && host_count > 1) {
            error = "multiple Host fields";
            error_status = 400;
        }
        if (!error && minor >= 1 && host_count != 1) {
            error = "HTTP/1.1 semantics require exactly one Host field";
            error_status = 400;
        }
        if (!error && te_present && has_cl) {
            error = "Transfer-Encoding and Content-Length cannot be combined";
            error_status = 400;
        }
        if (!error && minor == 0 && te_present) {
            error = "HTTP/1.0 request must not contain Transfer-Encoding";
            error_status = 400;
        }
        if (!error && is_connect
            && (te_present || (has_cl && content_length != 0))) {
            error = "CONNECT request must not contain content framing";
            error_status = 400;
        }
        if (!error && is_connect && host_count == 1
            && !connect_host_matches_target(
                host_value, host_value_len, target, target_len)) {
            error = "CONNECT Host must identify request target";
            error_status = 400;
        }

        if (!error && te_present) {
            if (chunked_count != 1 || !final_chunked) {
                error =
                    "chunked must be the final and only chunked transfer coding";
                error_status = 400;
            } else if (unsupported) {
                error = "unsupported transfer coding";
                error_status = 501;
            } else {
                body_mode = UB_BODY_CHUNKED;
            }
        } else if (!error && has_cl) {
            body_mode = (is_connect && content_length == 0)
                ? UB_BODY_NONE : UB_BODY_CONTENT_LENGTH;
        }

        if (error)
            return new_error_result(aTHX_ error_status, error);
    }

    if (uniform_api != NULL && request_out != NULL
        && !is_connect && target_len > 0
        && (target[0] == '/'
            || (target_len == 1 && target[0] == '*'))) {
        uhttp_native_input input;

        uhttp_native_input_init(&input, UHTTP_KIND_REQUEST);
        input.flags =
            UHTTP_HEADERS_LOSSLESS
            | UHTTP_TRAILERS_LOSSLESS
            | UHTTP_TARGET_EXACT;

        if (body_mode == UB_BODY_NONE) {
            input.flags |= UHTTP_COMPLETE;
        } else {
            input.flags |=
                UHTTP_MUTABLE
                | UHTTP_BODY_MUTABLE
                | UHTTP_TRAILERS_MUTABLE;
        }

        version_bytes[0] = '1';
        version_bytes[1] = '.';
        version_bytes[2] = (char)('0' + minor);
        input.version.data = version_bytes;
        input.version.len = 3;
        input.method.data = method;
        input.method.len = (STRLEN)method_len;
        input.target.data = target;
        input.target.len = (STRLEN)target_len;

        for (i = 0; i < count; ++i) {
            const char *value = headers[i].value;
            size_t value_len = headers[i].value_len;

            while (value_len && is_ows((unsigned char)*value)) {
                ++value;
                --value_len;
            }
            while (value_len
                && is_ows((unsigned char)value[value_len - 1]))
                --value_len;

            native_headers[i].name.data = headers[i].name;
            native_headers[i].name.len = (STRLEN)headers[i].name_len;
            native_headers[i].value.data = value;
            native_headers[i].value.len = (STRLEN)value_len;
        }

        input.headers = native_headers;
        input.header_count = (Size_t)count;
        native_request = uhttp_native_from_validated(
            aTHX_ uniform_api, &input, UHTTP_NATIVE_TRUSTED
        );
        *request_out = native_request;
    }

    hv = newHV();
    hv_store(hv, "ok", 2, newSViv(1), 0);
    hv_store(hv, "consumed", 8, newSViv(consumed), 0);
    if (native_request == NULL) {
        hv_store(hv, "version", 7, newSVpvf("1.%d", minor), 0);
        hv_store(hv, "method", 6, newSVpvn(method, (STRLEN)method_len), 0);
        hv_store(hv, "target", 6, newSVpvn(target, (STRLEN)target_len), 0);
        list = headers_to_av(aTHX_ headers, count);
        hv_store(hv, "headers", 7, newRV_noinc((SV *)list), 0);
    }

    if (body_mode == UB_BODY_CHUNKED)
        hv_store(hv, "body_mode", 9, newSVpvs("chunked"), 0);
    else if (body_mode == UB_BODY_CONTENT_LENGTH)
        hv_store(hv, "body_mode", 9, newSVpvs("content-length"), 0);
    else
        hv_store(hv, "body_mode", 9, newSVpvs("none"), 0);

    if (has_cl)
        hv_store(hv, "content_length", 14, newSVuv(content_length), 0);

    hv_store(
        hv, "keep_alive", 10,
        newSViv(close_seen ? 0 : (minor >= 1 ? 1 : (keep_seen ? 1 : 0))),
        0
    );
    hv_store(hv, "expect_continue", 15, newSViv(expect_mode), 0);

    return newRV_noinc((SV *)hv);
}

static SV *
ub_http1_parse_response_head_result(
    pTHX_
    const char *buf,
    size_t buffer_len,
    size_t last_len,
    size_t max_headers,
    const uhttp_native_api *uniform_api,
    SV **response_out
)
{
    int minor;
    int status;
    const char *reason;
    size_t reason_len;
    struct phr_header headers[UB_HTTP1_MAX_HEADERS];
    uhttp_native_field native_headers[UB_HTTP1_MAX_HEADERS];
    size_t count;
    int consumed;
    size_t i;
    char version_bytes[3];
    SV *native_response = NULL;
    HV *hv;
    AV *list;

    if (response_out != NULL)
        *response_out = NULL;
    if (last_len > buffer_len)
        croak("last_len exceeds input window length");
    if (max_headers == 0 || max_headers > UB_HTTP1_MAX_HEADERS)
        croak("max_headers must be between 1 and %d", UB_HTTP1_MAX_HEADERS);

    count = max_headers;
    consumed = phr_parse_response(
        buf, buffer_len, &minor, &status,
        &reason, &reason_len, headers, &count, last_len
    );

    if (consumed == -2)
        return NULL;

    if (consumed == -1 || minor < 0 || minor > 9
        || status < 100 || status > 599
        || buffer_len < 13 || !memEQ(buf, "HTTP/1.", 7)
        || buf[7] < '0' || buf[7] > '9' || buf[8] != ' '
        || buf[9] < '0' || buf[9] > '9'
        || buf[10] < '0' || buf[10] > '9'
        || buf[11] < '0' || buf[11] > '9' || buf[12] != ' '
        || reason != buf + 13
        || !valid_field_value(reason, reason_len)
        || !strict_headers(headers, count)) {
        return new_error_result(aTHX_ 0, "malformed HTTP/1 response");
    }

    if (uniform_api != NULL && response_out != NULL) {
        uhttp_native_input input;
        int informational =
            status >= 100 && status < 200 && status != 101 ? 1 : 0;

        uhttp_native_input_init(&input, UHTTP_KIND_RESPONSE);
        input.flags =
            UHTTP_HEADERS_LOSSLESS
            | UHTTP_TRAILERS_LOSSLESS;

        if (informational) {
            input.flags |= UHTTP_COMPLETE;
        } else {
            input.flags |=
                UHTTP_MUTABLE
                | UHTTP_BODY_MUTABLE
                | UHTTP_TRAILERS_MUTABLE;
        }

        version_bytes[0] = '1';
        version_bytes[1] = '.';
        version_bytes[2] = (char)('0' + minor);
        input.version.data = version_bytes;
        input.version.len = 3;
        input.status = (IV)status;
        input.reason.data = reason;
        input.reason.len = (STRLEN)reason_len;

        for (i = 0; i < count; ++i) {
            const char *value = headers[i].value;
            size_t value_len = headers[i].value_len;

            while (value_len && is_ows((unsigned char)*value)) {
                ++value;
                --value_len;
            }
            while (value_len
                && is_ows((unsigned char)value[value_len - 1]))
                --value_len;

            native_headers[i].name.data = headers[i].name;
            native_headers[i].name.len = (STRLEN)headers[i].name_len;
            native_headers[i].value.data = value;
            native_headers[i].value.len = (STRLEN)value_len;
        }

        input.headers = native_headers;
        input.header_count = (Size_t)count;
        native_response = uhttp_native_from_validated(
            aTHX_ uniform_api, &input, UHTTP_NATIVE_TRUSTED
        );
        *response_out = native_response;
    }

    hv = newHV();
    hv_store(hv, "ok", 2, newSViv(1), 0);
    hv_store(hv, "consumed", 8, newSViv(consumed), 0);
    hv_store(hv, "status", 6, newSViv(status), 0);
    if (native_response == NULL) {
        hv_store(hv, "version", 7, newSVpvf("1.%d", minor), 0);
        hv_store(
            hv, "reason", 6,
            newSVpvn(reason, (STRLEN)reason_len), 0
        );
        list = headers_to_av(aTHX_ headers, count);
        hv_store(hv, "headers", 7, newRV_noinc((SV *)list), 0);
    }

    return newRV_noinc((SV *)hv);
}

typedef struct {
    const char *data;
    size_t length;
    size_t offset;
    int valid;
} ub_http1_borrowed_window;

typedef struct {
    SV *engine;
    CV *input_cv;
    CV *head_cv;
    CV *eof_cv;
    uhttp_native_api uniform_api;
    int uniform_native;
    int role;
    int direct_head;
    size_t max_headers;
    size_t max_head_size;
} ub_http1_input_context;

static ub_http1_borrowed_window *
ub_http1_window_from_sv(pTHX_ SV *sv)
{
    SV *inner;
    ub_http1_borrowed_window *window;

    if (!SvROK(sv)
        || !sv_derived_from(sv, "Unblock::HTTP1::_Native::BorrowedWindow"))
        croak("not an Unblock::HTTP1 borrowed input window");

    inner = SvRV(sv);
    window = INT2PTR(ub_http1_borrowed_window *, SvIV(inner));
    if (window == NULL || !window->valid)
        croak("borrowed input window is no longer valid");
    if (window->offset > window->length)
        croak("corrupt borrowed input window");
    return window;
}

static const char *
ub_http1_buffer_view(pTHX_ SV *buffer, STRLEN *length)
{
    if (SvROK(buffer)
        && sv_derived_from(buffer, "Unblock::HTTP1::_Native::BorrowedWindow")) {
        ub_http1_borrowed_window *window =
            ub_http1_window_from_sv(aTHX_ buffer);
        size_t remaining = window->length - window->offset;
        if (remaining > (size_t)~(STRLEN)0)
            croak("borrowed input window exceeds Perl string length range");
        *length = (STRLEN)remaining;
        return window->data + window->offset;
    }

    return SvPVbyte(buffer, *length);
}

static CV *
ub_http1_engine_method_cv(
    pTHX_
    ub_http1_input_context *context,
    CV **slot,
    const char *name
)
{
    GV *gv;
    CV *cv;

    if (*slot != NULL)
        return *slot;

    if (!SvROK(context->engine))
        croak("Unblock::HTTP1 native input engine is not an object");

    gv = gv_fetchmethod_autoload(SvSTASH(SvRV(context->engine)), name, 0);
    if (gv == NULL || (cv = GvCV(gv)) == NULL)
        croak("Unblock::HTTP1 native input method %s is unavailable", name);

    *slot = (CV *)SvREFCNT_inc((SV *)cv);
    return *slot;
}

static int
ub_http1_call_engine_scalar(
    pTHX_
    ub_http1_input_context *context,
    CV **slot,
    const char *name,
    SV *arg
)
{
    CV *cv = ub_http1_engine_method_cv(aTHX_ context, slot, name);
    int result = 0;
    int count;
    SV *error = NULL;
    dSP;

    ENTER;
    SAVETMPS;
    sv_setsv(ERRSV, &PL_sv_undef);
    PUSHMARK(SP);
    XPUSHs(context->engine);
    if (arg != NULL)
        XPUSHs(arg);
    PUTBACK;
    count = call_sv((SV *)cv, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV))
        error = newSVsv(ERRSV);
    else if (count > 0)
        result = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;

    if (error != NULL) {
        const char *message = SvPV_nolen(error);
        croak("%s", message);
    }

    return result;
}

static int
ub_http1_call_engine_input(
    pTHX_
    ub_http1_input_context *context,
    SV *window,
    size_t length,
    SV *head,
    SV *message,
    size_t *consumed,
    int *head_ready
)
{
    CV *cv = ub_http1_engine_method_cv(
        aTHX_ context, &context->input_cv, "_input_borrowed"
    );
    int result = 0;
    int count;
    SV *error = NULL;
    SV *ready_sv;
    SV *consumed_sv;
    SV *status_sv;
    UV consumed_uv;
    dSP;

    ENTER;
    SAVETMPS;
    sv_setsv(ERRSV, &PL_sv_undef);
    PUSHMARK(SP);
    XPUSHs(context->engine);
    XPUSHs(window);
    mPUSHu((UV)length);
    XPUSHs(head != NULL ? head : &PL_sv_undef);
    XPUSHs(message != NULL ? message : &PL_sv_undef);
    PUTBACK;
    count = call_sv((SV *)cv, G_ARRAY | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        error = newSVsv(ERRSV);
    } else {
        if (count != 3)
            croak("Unblock::HTTP1 native input returned the wrong number of values");
        ready_sv = POPs;
        consumed_sv = POPs;
        status_sv = POPs;
        consumed_uv = SvUV(consumed_sv);
        if (consumed_uv > (UV)length)
            croak("Unblock::HTTP1 native input consumed beyond its window");
        *consumed = (size_t)consumed_uv;
        *head_ready = SvTRUE(ready_sv) ? 1 : 0;
        result = SvIV(status_sv);
    }
    PUTBACK;
    FREETMPS;
    LEAVE;

    if (error != NULL) {
        const char *message = SvPV_nolen(error);
        croak("%s", message);
    }

    return result;
}

static int
ub_http1_call_engine_head(
    pTHX_
    ub_http1_input_context *context,
    SV *head,
    SV *message,
    int *head_ready
)
{
    CV *cv = ub_http1_engine_method_cv(
        aTHX_ context, &context->head_cv, "_input_native_head"
    );
    int result = 0;
    int count;
    SV *error = NULL;
    SV *ready_sv;
    SV *status_sv;
    dSP;

    ENTER;
    SAVETMPS;
    sv_setsv(ERRSV, &PL_sv_undef);
    PUSHMARK(SP);
    XPUSHs(context->engine);
    XPUSHs(head);
    XPUSHs(message != NULL ? message : &PL_sv_undef);
    PUTBACK;
    count = call_sv((SV *)cv, G_ARRAY | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        error = newSVsv(ERRSV);
    } else {
        if (count != 2)
            croak("Unblock::HTTP1 native head dispatch returned the wrong number of values");
        ready_sv = POPs;
        status_sv = POPs;
        *head_ready = SvTRUE(ready_sv) ? 1 : 0;
        result = SvIV(status_sv);
    }
    PUTBACK;
    FREETMPS;
    LEAVE;

    if (error != NULL) {
        const char *message = SvPV_nolen(error);
        croak("%s", message);
    }

    return result;
}

static int
ub_http1_input_can_direct_head(pTHX_ ub_http1_input_context *context)
{
    HV *engine_hv;
    SV **value;
    int active = 0;

    if (context == NULL || context->role == 0
        || context->engine == NULL || !SvROK(context->engine)
        || SvTYPE(SvRV(context->engine)) != SVt_PVHV)
        return 0;

    engine_hv = (HV *)SvRV(context->engine);

    value = hv_fetch(engine_hv, "closed", 6, 0);
    if (value != NULL && SvOK(*value) && SvTRUE(*value))
        return 0;

    value = hv_fetch(engine_hv, "switched", 8, 0);
    if (value != NULL && SvOK(*value) && SvTRUE(*value))
        return 0;

    value = hv_fetch(engine_hv, "input", 5, 0);
    if (value != NULL && SvOK(*value) && SvCUR(*value) != 0)
        return 0;

    value = hv_fetch(engine_hv, "rx", 2, 0);
    if (value != NULL && SvOK(*value) && SvTRUE(*value))
        return 0;

    value = hv_fetch(engine_hv, "active", 6, 0);
    if (value != NULL && SvOK(*value) && SvTRUE(*value))
        active = 1;

    return context->role == 1 ? !active : active;
}

static void *
ub_http1_input_create(pTHX_ SV *engine)
{
    ub_http1_input_context *context;

    if (!SvROK(engine)
        || !sv_derived_from(engine, "Unblock::HTTP1::_Engine"))
        return NULL;

    Newxz(context, 1, ub_http1_input_context);
    if (context == NULL)
        return NULL;

    context->engine = SvREFCNT_inc(engine);
    context->uniform_native = uhttp_native_init(
        aTHX_ &context->uniform_api, UHTTP_NATIVE_ABI_VERSION
    );
    context->role = sv_derived_from(engine, "Unblock::HTTP1::Server") ? 1
        : sv_derived_from(engine, "Unblock::HTTP1::Client") ? 2 : 0;
    context->direct_head = 0;
    context->max_headers = 100;
    context->max_head_size = 65536;

    if (SvTYPE(SvRV(engine)) == SVt_PVHV) {
        HV *engine_hv = (HV *)SvRV(engine);
        SV **value;

        value = hv_fetch(engine_hv, "max_headers", 11, 0);
        if (value != NULL && SvOK(*value))
            context->max_headers = (size_t)SvUV(*value);

        value = hv_fetch(engine_hv, "max_head_size", 13, 0);
        if (value != NULL && SvOK(*value))
            context->max_head_size = (size_t)SvUV(*value);

    }

    context->direct_head = ub_http1_input_can_direct_head(aTHX_ context);
    return context;
}

static int
ub_http1_input_borrowed(
    pTHX_
    void *opaque,
    const char *data,
    size_t length,
    size_t *consumed
)
{
    ub_http1_input_context *context = (ub_http1_input_context *)opaque;
    ub_http1_borrowed_window *window = NULL;
    SV *object = NULL;
    SV *head = NULL;
    SV *message = NULL;
    SV *window_arg = &PL_sv_undef;
    int head_ready = 0;
    int head_only = 0;
    int need_window = 1;
    int result;

    if (context == NULL || consumed == NULL)
        croak("invalid Unblock::HTTP1 native input context");

    *consumed = 0;
    if (data == NULL)
        data = "";

    context->direct_head = ub_http1_input_can_direct_head(aTHX_ context);

    if (context->direct_head && context->role == 1) {
        head = ub_http1_parse_request_head_result(
            aTHX_
            data,
            length,
            0,
            context->max_headers,
            context->uniform_native ? &context->uniform_api : NULL,
            &message
        );

        if (head == NULL) {
            if (length <= context->max_head_size)
                return UB_HTTP1_INPUT_MORE;
            head = new_error_result(
                aTHX_ 431, "request head exceeds configured limit"
            );
            need_window = 0;
        } else if (SvROK(head) && SvTYPE(SvRV(head)) == SVt_PVHV) {
            HV *head_hv = (HV *)SvRV(head);
            SV **ok_sv = hv_fetch(head_hv, "ok", 2, 0);

            if (ok_sv != NULL && SvTRUE(*ok_sv)) {
                SV **consumed_sv = hv_fetch(head_hv, "consumed", 8, 0);
                if (consumed_sv != NULL && SvOK(*consumed_sv)) {
                    UV head_consumed = SvUV(*consumed_sv);
                    if (head_consumed <= (UV)length
                        && head_consumed == (UV)length) {
                        need_window = 0;
                        head_only = 1;
                    }
                }
            } else {
                need_window = 0;
            }
        }
    } else if (context->direct_head && context->role == 2) {
        head = ub_http1_parse_response_head_result(
            aTHX_
            data,
            length,
            0,
            context->max_headers,
            context->uniform_native ? &context->uniform_api : NULL,
            &message
        );

        if (head == NULL) {
            if (length <= context->max_head_size)
                return UB_HTTP1_INPUT_MORE;
            head = new_error_result(
                aTHX_ 0, "HTTP/1 response head exceeds configured limit"
            );
            need_window = 0;
        } else if (SvROK(head) && SvTYPE(SvRV(head)) == SVt_PVHV) {
            HV *head_hv = (HV *)SvRV(head);
            SV **ok_sv = hv_fetch(head_hv, "ok", 2, 0);

            if (ok_sv != NULL && SvTRUE(*ok_sv)) {
                SV **consumed_sv = hv_fetch(head_hv, "consumed", 8, 0);
                if (consumed_sv != NULL && SvOK(*consumed_sv)) {
                    UV head_consumed = SvUV(*consumed_sv);
                    if (head_consumed <= (UV)length
                        && head_consumed == (UV)length) {
                        need_window = 0;
                        head_only = 1;
                    }
                }
            } else {
                need_window = 0;
            }
        }
    }

    if (head_only) {
        int jump_status;
        dJMPENV;

        *consumed = length;
        JMPENV_PUSH(jump_status);
        if (jump_status == 0) {
            result = ub_http1_call_engine_head(
                aTHX_ context, head, message, &head_ready
            );
            JMPENV_POP;
        } else {
            JMPENV_POP;
            if (message != NULL)
                SvREFCNT_dec(message);
            SvREFCNT_dec(head);
            JMPENV_JUMP(jump_status);
        }

        if (message != NULL)
            SvREFCNT_dec(message);
        SvREFCNT_dec(head);

        if (result < UB_HTTP1_INPUT_OK || result > UB_HTTP1_INPUT_SWITCH
            || result == 2)
            croak("Unblock::HTTP1 engine returned invalid native input status");

        context->direct_head = head_ready;
        return result;
    }

    if (need_window) {
        SV *inner;

        Newxz(window, 1, ub_http1_borrowed_window);
        if (window == NULL) {
            if (head != NULL)
                SvREFCNT_dec(head);
            croak("unable to allocate borrowed input window");
        }

        window->data = data;
        window->length = length;
        window->offset = 0;
        window->valid = 1;

        inner = newSViv(PTR2IV(window));
        object = newRV_noinc(inner);
        sv_bless(object,
            gv_stashpv("Unblock::HTTP1::_Native::BorrowedWindow", GV_ADD));
        window_arg = object;
    }

    {
        int jump_status;
        dJMPENV;

        JMPENV_PUSH(jump_status);
        if (jump_status == 0) {
            result = ub_http1_call_engine_input(
                aTHX_
                context,
                window_arg,
                length,
                head,
                message,
                consumed,
                &head_ready
            );
            JMPENV_POP;
        } else {
            JMPENV_POP;
            if (window != NULL)
                window->valid = 0;
            if (object != NULL)
                SvREFCNT_dec(object);
            if (message != NULL)
                SvREFCNT_dec(message);
            if (head != NULL)
                SvREFCNT_dec(head);
            JMPENV_JUMP(jump_status);
        }
    }

    if (window != NULL)
        window->valid = 0;
    if (object != NULL)
        SvREFCNT_dec(object);
    if (message != NULL)
        SvREFCNT_dec(message);
    if (head != NULL)
        SvREFCNT_dec(head);

    if (result < UB_HTTP1_INPUT_OK || result > UB_HTTP1_INPUT_SWITCH
        || result == 2)
        croak("Unblock::HTTP1 engine returned invalid native input status");

    if (context->role)
        context->direct_head = head_ready;

    return result;
}

static int
ub_http1_input_eof(pTHX_ void *opaque)
{
    ub_http1_input_context *context = (ub_http1_input_context *)opaque;
    int result;

    if (context == NULL)
        croak("invalid Unblock::HTTP1 native input context");

    result = ub_http1_call_engine_scalar(
        aTHX_
        context,
        &context->eof_cv,
        "_borrowed_input_eof",
        NULL
    );

    if (result != UB_HTTP1_INPUT_OK
        && result != UB_HTTP1_INPUT_CLOSED
        && result != UB_HTTP1_INPUT_SWITCH)
        croak("Unblock::HTTP1 engine returned invalid native EOF status");

    return result;
}

static void
ub_http1_input_destroy(pTHX_ void *opaque)
{
    ub_http1_input_context *context = (ub_http1_input_context *)opaque;

    PERL_UNUSED_CONTEXT;
    if (context == NULL)
        return;

    if (context->input_cv != NULL)
        SvREFCNT_dec((SV *)context->input_cv);
    if (context->head_cv != NULL)
        SvREFCNT_dec((SV *)context->head_cv);
    if (context->eof_cv != NULL)
        SvREFCNT_dec((SV *)context->eof_cv);
    if (context->engine != NULL)
        SvREFCNT_dec(context->engine);
    Safefree(context);
}

static const ub_http1_input_ops_v1 ub_http1_input_ops = {
    UB_HTTP1_INPUT_ABI_VERSION,
    sizeof(ub_http1_input_ops_v1),
    "Unblock::HTTP1 borrowed input",
    ub_http1_input_create,
    ub_http1_input_borrowed,
    ub_http1_input_eof,
    ub_http1_input_destroy
};

MODULE = Unblock::HTTP1    PACKAGE = Unblock::HTTP1::_Native
PROTOTYPES: DISABLE

UV
_borrowed_input_operations_address()
  CODE:
    RETVAL = PTR2UV(&ub_http1_input_ops);
  OUTPUT:
    RETVAL

UV
_borrowed_input_operations_size()
  CODE:
    RETVAL = (UV)sizeof(ub_http1_input_ops_v1);
  OUTPUT:
    RETVAL

void
_borrowed_input_once(engine, buffer)
    SV *engine
    SV *buffer
  PREINIT:
    STRLEN buffer_len;
    const char *data;
    void *context;
    size_t consumed = 0;
    int status;
  PPCODE:
    data = SvPVbyte(buffer, buffer_len);
    context = ub_http1_input_create(aTHX_ engine);
    if (context == NULL)
        croak("engine does not support Unblock::HTTP1 native input");
    status = ub_http1_input_borrowed(
        aTHX_ context, data, (size_t)buffer_len, &consumed
    );
    ub_http1_input_destroy(aTHX_ context);
    XPUSHs(sv_2mortal(newSViv(status)));
    XPUSHs(sv_2mortal(newSVuv((UV)consumed)));

const char *
pico_version(CLASS)
    const char *CLASS
  CODE:
    (void)CLASS;
    RETVAL = PICOHTTPPARSER_VERSION;
  OUTPUT:
    RETVAL

SV *
parse_request_head(CLASS, buffer, last_len = 0, max_headers = 100, offset = 0)
    const char *CLASS
    SV *buffer
    UV last_len
    UV max_headers
    UV offset
  PREINIT:
    STRLEN buffer_len;
    const char *buf;
  CODE:
    (void)CLASS;
    buf = ub_http1_buffer_view(aTHX_ buffer, &buffer_len);
    if (offset > (UV)buffer_len)
        croak("offset exceeds buffer length");
    buf += (size_t)offset;
    buffer_len -= (STRLEN)offset;
    RETVAL = ub_http1_parse_request_head_result(
        aTHX_
        buf,
        (size_t)buffer_len,
        (size_t)last_len,
        (size_t)max_headers,
        NULL,
        NULL
    );
    if (RETVAL == NULL)
        XSRETURN_UNDEF;
  OUTPUT:
    RETVAL

SV *
parse_response_head(CLASS, buffer, last_len = 0, max_headers = 100, offset = 0)
    const char *CLASS
    SV *buffer
    UV last_len
    UV max_headers
    UV offset
  PREINIT:
    STRLEN buffer_len;
    const char *buf;
  CODE:
    (void)CLASS;
    buf = ub_http1_buffer_view(aTHX_ buffer, &buffer_len);
    if (offset > (UV)buffer_len)
        croak("offset exceeds buffer length");
    buf += (size_t)offset;
    buffer_len -= (STRLEN)offset;
    RETVAL = ub_http1_parse_response_head_result(
        aTHX_
        buf,
        (size_t)buffer_len,
        (size_t)last_len,
        (size_t)max_headers,
        NULL,
        NULL
    );
    if (RETVAL == NULL)
        XSRETURN_UNDEF;
  OUTPUT:
    RETVAL

SV *
parse_trailers(CLASS, buffer, last_len = 0, max_headers = 100, offset = 0)
    const char *CLASS
    SV *buffer
    UV last_len
    UV max_headers
    UV offset
  PREINIT:
    STRLEN buffer_len;
    const char *buf;
    struct phr_header headers[UB_HTTP1_MAX_HEADERS];
    size_t count;
    int consumed;
    HV *hv;
    AV *list;
  CODE:
    (void)CLASS;
    buf = ub_http1_buffer_view(aTHX_ buffer, &buffer_len);
    if (offset > (UV)buffer_len)
        croak("offset exceeds buffer length");
    buf += (size_t)offset;
    buffer_len -= (STRLEN)offset;
    if (last_len > (UV)buffer_len)
        croak("last_len exceeds input window length");
    if (max_headers == 0 || max_headers > UB_HTTP1_MAX_HEADERS)
        croak("max_headers must be between 1 and %d", UB_HTTP1_MAX_HEADERS);
    count = (size_t)max_headers;
    consumed = phr_parse_headers(buf, (size_t)buffer_len, headers, &count, (size_t)last_len);
    if (consumed == -2) XSRETURN_UNDEF;
    if (consumed == -1 || !strict_headers(headers, count)) {
        RETVAL = new_error_result(aTHX_ 0, "malformed HTTP/1 trailer section");
    } else {
        hv = newHV();
        hv_store(hv, "ok", 2, newSViv(1), 0);
        hv_store(hv, "consumed", 8, newSViv(consumed), 0);
        list = headers_to_av(aTHX_ headers, count);
        hv_store(hv, "headers", 7, newRV_noinc((SV *)list), 0);
        RETVAL = newRV_noinc((SV *)hv);
    }
  OUTPUT:
    RETVAL

MODULE = Unblock::HTTP1    PACKAGE = Unblock::HTTP1::_Native::BorrowedDriver

SV *
new(CLASS, engine)
    const char *CLASS
    SV *engine
  PREINIT:
    ub_http1_input_context *context;
    SV *inner;
    SV *object;
  CODE:
    context = (ub_http1_input_context *)ub_http1_input_create(aTHX_ engine);
    if (context == NULL)
        croak("engine does not support Unblock::HTTP1 native input");
    inner = newSViv(PTR2IV(context));
    object = newRV_noinc(inner);
    sv_bless(object, gv_stashpv(CLASS, GV_ADD));
    RETVAL = object;
  OUTPUT:
    RETVAL

void
feed(self, buffer)
    SV *self
    SV *buffer
  PREINIT:
    SV *inner;
    ub_http1_input_context *context;
    STRLEN buffer_len;
    const char *data;
    size_t consumed = 0;
    int status;
  PPCODE:
    if (!SvROK(self)
        || !sv_derived_from(self, "Unblock::HTTP1::_Native::BorrowedDriver"))
        croak("not an Unblock::HTTP1 borrowed input driver");
    inner = SvRV(self);
    context = INT2PTR(ub_http1_input_context *, SvIV(inner));
    if (context == NULL)
        croak("borrowed input driver has already been released");
    data = SvPVbyte(buffer, buffer_len);
    status = ub_http1_input_borrowed(
        aTHX_ context, data, (size_t)buffer_len, &consumed
    );
    XPUSHs(sv_2mortal(newSViv(status)));
    XPUSHs(sv_2mortal(newSVuv((UV)consumed)));

UV
feed_repeat(self, buffer, count)
    SV *self
    SV *buffer
    UV count
  PREINIT:
    SV *inner;
    ub_http1_input_context *context;
    STRLEN buffer_len;
    const char *data;
    UV i;
  CODE:
    if (!SvROK(self)
        || !sv_derived_from(self, "Unblock::HTTP1::_Native::BorrowedDriver"))
        croak("not an Unblock::HTTP1 borrowed input driver");
    inner = SvRV(self);
    context = INT2PTR(ub_http1_input_context *, SvIV(inner));
    if (context == NULL)
        croak("borrowed input driver has already been released");
    data = SvPVbyte(buffer, buffer_len);
    for (i = 0; i < count; ++i) {
        size_t consumed = 0;
        int status = ub_http1_input_borrowed(
            aTHX_ context, data, (size_t)buffer_len, &consumed
        );
        if (status != UB_HTTP1_INPUT_OK
            || consumed != (size_t)buffer_len)
            croak("borrowed repeat input did not consume complete window");
    }
    RETVAL = count;
  OUTPUT:
    RETVAL

int
eof(self)
    SV *self
  PREINIT:
    SV *inner;
    ub_http1_input_context *context;
  CODE:
    if (!SvROK(self)
        || !sv_derived_from(self, "Unblock::HTTP1::_Native::BorrowedDriver"))
        croak("not an Unblock::HTTP1 borrowed input driver");
    inner = SvRV(self);
    context = INT2PTR(ub_http1_input_context *, SvIV(inner));
    if (context == NULL)
        croak("borrowed input driver has already been released");
    RETVAL = ub_http1_input_eof(aTHX_ context);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  PREINIT:
    SV *inner;
    ub_http1_input_context *context;
  CODE:
    if (!SvROK(self))
        XSRETURN_EMPTY;
    inner = SvRV(self);
    context = INT2PTR(ub_http1_input_context *, SvIV(inner));
    if (context == NULL)
        XSRETURN_EMPTY;
    ub_http1_input_destroy(aTHX_ context);
    sv_setiv(inner, 0);

MODULE = Unblock::HTTP1    PACKAGE = Unblock::HTTP1::_Native::BorrowedWindow

SV *
slice(self, offset, length)
    SV *self
    UV offset
    UV length
  PREINIT:
    ub_http1_borrowed_window *window;
  CODE:
    window = ub_http1_window_from_sv(aTHX_ self);
    if (offset > (UV)window->length
        || length > (UV)(window->length - (size_t)offset))
        croak("borrowed input slice exceeds window");
    RETVAL = newSVpvn(
        window->data + (size_t)offset,
        (STRLEN)length
    );
  OUTPUT:
    RETVAL

UV
remaining(self)
    SV *self
  PREINIT:
    ub_http1_borrowed_window *window;
  CODE:
    window = ub_http1_window_from_sv(aTHX_ self);
    RETVAL = (UV)(window->length - window->offset);
  OUTPUT:
    RETVAL

UV
consumed(self)
    SV *self
  PREINIT:
    ub_http1_borrowed_window *window;
  CODE:
    window = ub_http1_window_from_sv(aTHX_ self);
    RETVAL = (UV)window->offset;
  OUTPUT:
    RETVAL

SV *
take(self, length)
    SV *self
    UV length
  PREINIT:
    ub_http1_borrowed_window *window;
    size_t remaining;
  CODE:
    window = ub_http1_window_from_sv(aTHX_ self);
    remaining = window->length - window->offset;
    if (length > (UV)remaining)
        croak("borrowed input take exceeds remaining window");
    RETVAL = newSVpvn(window->data + window->offset, (STRLEN)length);
    window->offset += (size_t)length;
  OUTPUT:
    RETVAL

void
discard(self, length)
    SV *self
    UV length
  PREINIT:
    ub_http1_borrowed_window *window;
    size_t remaining;
  CODE:
    window = ub_http1_window_from_sv(aTHX_ self);
    remaining = window->length - window->offset;
    if (length > (UV)remaining)
        croak("borrowed input discard exceeds remaining window");
    window->offset += (size_t)length;

void
clear(self)
    SV *self
  PREINIT:
    ub_http1_borrowed_window *window;
  CODE:
    window = ub_http1_window_from_sv(aTHX_ self);
    window->offset = window->length;

SV *
remaining_bytes(self)
    SV *self
  PREINIT:
    ub_http1_borrowed_window *window;
    size_t remaining;
  CODE:
    window = ub_http1_window_from_sv(aTHX_ self);
    remaining = window->length - window->offset;
    RETVAL = newSVpvn(window->data + window->offset, (STRLEN)remaining);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  PREINIT:
    SV *inner;
    ub_http1_borrowed_window *window;
  CODE:
    if (!SvROK(self))
        XSRETURN_EMPTY;
    inner = SvRV(self);
    window = INT2PTR(ub_http1_borrowed_window *, SvIV(inner));
    if (window == NULL)
        XSRETURN_EMPTY;
    Safefree(window);
    sv_setiv(inner, 0);

MODULE = Unblock::HTTP1    PACKAGE = Unblock::HTTP1::_Native::Chunked

SV *
new(CLASS, max_chunk_extension_size = 16384)
    const char *CLASS
    UV max_chunk_extension_size
  PREINIT:
    struct phr_chunked_decoder *decoder;
    SV *inner;
    SV *obj;
  CODE:
    if (max_chunk_extension_size > (UV)SIZE_MAX)
        croak("max_chunk_extension_size exceeds native size range");
    Newxz(decoder, 1, struct phr_chunked_decoder);
    decoder->consume_trailer = 0;
    decoder->_max_chunk_ext_size = (size_t)max_chunk_extension_size;
    inner = newSViv(PTR2IV(decoder));
    obj = newRV_noinc(inner);
    sv_bless(obj, gv_stashpv(CLASS, GV_ADD));
    RETVAL = obj;
  OUTPUT:
    RETVAL

void
feed(self, input, emit = 1, offset = 0)
    SV *self
    SV *input
    int emit
    UV offset
  PREINIT:
    struct phr_chunked_decoder *decoder;
    SV *inner;
    STRLEN input_len;
    const char *input_bytes;
    char *scratch;
    size_t decoded_len;
    ssize_t result;
    size_t leftover;
  PPCODE:
    if (!SvROK(self) || !sv_derived_from(self, "Unblock::HTTP1::_Native::Chunked"))
        croak("not an Unblock::HTTP1 chunked decoder object");
    inner = SvRV(self);
    decoder = INT2PTR(struct phr_chunked_decoder *, SvIV(inner));
    if (!decoder) croak("chunked decoder has already been released");
    input_bytes = ub_http1_buffer_view(aTHX_ input, &input_len);
    if (offset > (UV)input_len)
        croak("offset exceeds input length");
    input_bytes += (size_t)offset;
    input_len -= (STRLEN)offset;
    Newx(scratch, input_len ? input_len : 1, char);
    if (input_len) Copy(input_bytes, scratch, input_len, char);
    decoded_len = (size_t)input_len;
    result = phr_decode_chunked(decoder, scratch, &decoded_len);
    if (result == -1) {
        Safefree(scratch);
        croak("malformed HTTP/1 chunked body");
    }
    leftover = result >= 0 ? (size_t)result : 0;
    XPUSHs(sv_2mortal(newSViv(result >= 0 ? 1 : 0)));
    if (emit)
        XPUSHs(sv_2mortal(newSVpvn(scratch, (STRLEN)decoded_len)));
    else
        XPUSHs(&PL_sv_undef);
    if (leftover)
        XPUSHs(sv_2mortal(newSVpvn(scratch + decoded_len, (STRLEN)leftover)));
    else
        XPUSHs(sv_2mortal(newSVpvn("", 0)));
    Safefree(scratch);

void
DESTROY(self)
    SV *self
  PREINIT:
    SV *inner;
    struct phr_chunked_decoder *decoder;
  CODE:
    if (!SvROK(self)) XSRETURN_EMPTY;
    inner = SvRV(self);
    decoder = INT2PTR(struct phr_chunked_decoder *, SvIV(inner));
    if (!decoder) XSRETURN_EMPTY;
    Safefree(decoder);
    sv_setiv(inner, 0);
