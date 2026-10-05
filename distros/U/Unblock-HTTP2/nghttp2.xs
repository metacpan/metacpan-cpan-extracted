#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "uniform_http_fastpath.h"
#include "unblock_http2_native_abi.h"

#include <nghttp2/nghttp2.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef struct unblock_h2_provider unblock_h2_provider;
typedef struct unblock_h2_header_block unblock_h2_header_block;

typedef struct {
    char *name;
    size_t namelen;
    char *value;
    size_t valuelen;
} unblock_h2_header_field;

struct unblock_h2_header_block {
    unblock_h2_header_block *next;
    int32_t stream_id;
    int category;
    uint8_t flags;
    size_t list_size;
    size_t count;
    size_t capacity;
    unblock_h2_header_field *fields;
    const char *error;
    uint32_t error_code;
};

struct unblock_h2_provider {
    unblock_h2_provider *next;
    unblock_h2_provider *pending_next;
    SV *callback;
    int32_t stream_id;
    int deferred;
    int released;
};

typedef struct {
    nghttp2_session *session;
    uhttp_native_api uniform_api;
    SV *cb_begin_headers;
    SV *cb_frame_recv;
    SV *cb_data_chunk_recv;
    SV *cb_stream_close;
    SV *cb_invalid_frame;
    SV *cb_error;
    SV *callback_error;
    unblock_h2_provider *providers;
    unblock_h2_provider *pending_free;
    unblock_h2_header_block *header_blocks;
    size_t max_header_list_size;
    int server;
    int in_session_call;
} unblock_h2_session;


typedef struct {
    SV *engine;
    SV *session_object;
    unblock_h2_session *session;
    CV *after_session_cv;
    CV *finish_close_cv;
} ub_http2_native_context;

static unblock_h2_session *
session_from_sv(pTHX_ SV *self)
{
    unblock_h2_session *ps;

    if (!SvROK(self)) {
        croak("Unblock::HTTP2::_nghttp2::Session: invalid session object");
    }

    ps = INT2PTR(unblock_h2_session *, SvIV(SvRV(self)));
    if (!ps || !ps->session) {
        croak("Unblock::HTTP2::_nghttp2::Session: session has been destroyed");
    }

    return ps;
}

static void
set_callback_error(pTHX_ unblock_h2_session *ps, const char *prefix)
{
    SV *error;

    if (ps->callback_error) {
        return;
    }

    error = ERRSV;
    if (error && SvTRUE(error)) {
        ps->callback_error = newSVpvf("%s: %s", prefix, SvPV_nolen(error));
    }
    else {
        ps->callback_error = newSVpv(prefix, 0);
    }
}

static void
clear_callback_error(pTHX_ unblock_h2_session *ps)
{
    if (ps->callback_error) {
        SvREFCNT_dec(ps->callback_error);
        ps->callback_error = NULL;
    }
}

static void
croak_callback_error(pTHX_ unblock_h2_session *ps)
{
    SV *error;

    if (!ps->callback_error) {
        return;
    }

    error = ps->callback_error;
    ps->callback_error = NULL;
    sv_2mortal(error);
    croak("%s", SvPV_nolen(error));
}

static SV *
callback_from_hash(pTHX_ HV *callbacks, const char *name, I32 name_len)
{
    SV **svp;

    if (!callbacks) {
        return NULL;
    }

    svp = hv_fetch(callbacks, name, name_len, 0);
    if (!svp || !SvOK(*svp)) {
        return NULL;
    }

    if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVCV) {
        croak("callback %s must be a coderef", name);
    }

    return newSVsv(*svp);
}

static void
load_callbacks(pTHX_ unblock_h2_session *ps, HV *callbacks)
{
    ps->cb_begin_headers = callback_from_hash(aTHX_ callbacks, "on_begin_headers", 16);
    ps->cb_frame_recv = callback_from_hash(aTHX_ callbacks, "on_frame_recv", 13);
    ps->cb_data_chunk_recv = callback_from_hash(aTHX_ callbacks, "on_data_chunk_recv", 18);
    ps->cb_stream_close = callback_from_hash(aTHX_ callbacks, "on_stream_close", 15);
    ps->cb_invalid_frame = callback_from_hash(aTHX_ callbacks, "on_invalid_frame", 16);
    ps->cb_error = callback_from_hash(aTHX_ callbacks, "on_error", 8);
}

static void
release_callbacks(pTHX_ unblock_h2_session *ps)
{
    if (ps->cb_begin_headers) SvREFCNT_dec(ps->cb_begin_headers);
    if (ps->cb_frame_recv) SvREFCNT_dec(ps->cb_frame_recv);
    if (ps->cb_data_chunk_recv) SvREFCNT_dec(ps->cb_data_chunk_recv);
    if (ps->cb_stream_close) SvREFCNT_dec(ps->cb_stream_close);
    if (ps->cb_invalid_frame) SvREFCNT_dec(ps->cb_invalid_frame);
    if (ps->cb_error) SvREFCNT_dec(ps->cb_error);
    if (ps->callback_error) SvREFCNT_dec(ps->callback_error);

    ps->cb_begin_headers = NULL;
    ps->cb_frame_recv = NULL;
    ps->cb_data_chunk_recv = NULL;
    ps->cb_stream_close = NULL;
    ps->cb_invalid_frame = NULL;
    ps->cb_error = NULL;
    ps->callback_error = NULL;
}

static unblock_h2_provider *
find_provider(unblock_h2_session *ps, int32_t stream_id)
{
    unblock_h2_provider *provider = ps->providers;

    while (provider) {
        if (provider->stream_id == stream_id) {
            return provider;
        }
        provider = provider->next;
    }

    return NULL;
}

static void
free_provider(pTHX_ unblock_h2_provider *provider)
{
    if (provider->callback) {
        SvREFCNT_dec(provider->callback);
    }
    free(provider);
}

static void
drain_pending_free(pTHX_ unblock_h2_session *ps)
{
    unblock_h2_provider *provider = ps->pending_free;

    ps->pending_free = NULL;
    while (provider) {
        unblock_h2_provider *next = provider->pending_next;
        free_provider(aTHX_ provider);
        provider = next;
    }
}

static void
remove_provider(pTHX_ unblock_h2_session *ps, int32_t stream_id)
{
    unblock_h2_provider **link = &ps->providers;

    while (*link) {
        unblock_h2_provider *provider = *link;
        if (provider->stream_id == stream_id) {
            *link = provider->next;
            provider->released = 1;

            if (ps->in_session_call) {
                provider->pending_next = ps->pending_free;
                ps->pending_free = provider;
            }
            else {
                free_provider(aTHX_ provider);
            }
            return;
        }
        link = &provider->next;
    }
}

static void
add_provider(pTHX_ unblock_h2_session *ps, unblock_h2_provider *provider)
{
    if (find_provider(ps, provider->stream_id)) {
        croak("stream %d already has a data provider", (int)provider->stream_id);
    }

    provider->next = ps->providers;
    ps->providers = provider;
}

static void
free_header_block(pTHX_ unblock_h2_header_block *block)
{
    size_t i;

    if (!block) {
        return;
    }

    for (i = 0; i < block->count; i++) {
        free(block->fields[i].name);
        free(block->fields[i].value);
    }
    free(block->fields);
    free(block);
}

static unblock_h2_header_block *
find_header_block(unblock_h2_session *ps, int32_t stream_id)
{
    unblock_h2_header_block *block = ps->header_blocks;

    while (block) {
        if (block->stream_id == stream_id) {
            return block;
        }
        block = block->next;
    }
    return NULL;
}

static unblock_h2_header_block *
take_header_block(unblock_h2_session *ps, int32_t stream_id)
{
    unblock_h2_header_block **link = &ps->header_blocks;

    while (*link) {
        unblock_h2_header_block *block = *link;
        if (block->stream_id == stream_id) {
            *link = block->next;
            block->next = NULL;
            return block;
        }
        link = &block->next;
    }
    return NULL;
}

static void
remove_header_block(pTHX_ unblock_h2_session *ps, int32_t stream_id)
{
    free_header_block(aTHX_ take_header_block(ps, stream_id));
}

static void
free_header_blocks(pTHX_ unblock_h2_session *ps)
{
    unblock_h2_header_block *block = ps->header_blocks;

    ps->header_blocks = NULL;
    while (block) {
        unblock_h2_header_block *next = block->next;
        free_header_block(aTHX_ block);
        block = next;
    }
}

static int
start_header_block(pTHX_ unblock_h2_session *ps, const nghttp2_frame *frame)
{
    unblock_h2_header_block *block;

    remove_header_block(aTHX_ ps, frame->hd.stream_id);

    block = (unblock_h2_header_block *)calloc(1, sizeof(*block));
    if (!block) {
        return 0;
    }

    block->stream_id = frame->hd.stream_id;
    block->category = frame->headers.cat;
    block->flags = frame->hd.flags;
    block->next = ps->header_blocks;
    ps->header_blocks = block;
    return 1;
}

static int
append_header_field(pTHX_ unblock_h2_session *ps,
                    unblock_h2_header_block *block,
                    const uint8_t *name, size_t namelen,
                    const uint8_t *value, size_t valuelen)
{
    unblock_h2_header_field *fields;
    unblock_h2_header_field *field;
    size_t new_size;
    size_t capacity;

    if (!block || block->error) {
        return 1;
    }

    if (namelen > (size_t)-1 - valuelen - 32
        || block->list_size > (size_t)-1 - namelen - valuelen - 32) {
        block->error = "HTTP/2 header list size overflow";
        block->error_code = NGHTTP2_ENHANCE_YOUR_CALM;
        return 1;
    }

    new_size = block->list_size + namelen + valuelen + 32;
    if (new_size > ps->max_header_list_size) {
        block->error = ps->server
            ? "HTTP/2 request header list exceeds configured limit"
            : "HTTP/2 response header list exceeds configured limit";
        block->error_code = NGHTTP2_ENHANCE_YOUR_CALM;
        return 1;
    }

    if (block->count == block->capacity) {
        capacity = block->capacity ? block->capacity * 2 : 8;
        if (capacity < block->capacity
            || capacity > (size_t)-1 / sizeof(*fields)) {
            return 0;
        }
        fields = (unblock_h2_header_field *)realloc(
            block->fields, capacity * sizeof(*fields));
        if (!fields) {
            return 0;
        }
        memset(fields + block->capacity, 0,
            (capacity - block->capacity) * sizeof(*fields));
        block->fields = fields;
        block->capacity = capacity;
    }

    field = &block->fields[block->count];
    field->name = (char *)malloc(namelen ? namelen : 1);
    field->value = (char *)malloc(valuelen ? valuelen : 1);
    if (!field->name || !field->value) {
        free(field->name);
        free(field->value);
        field->name = NULL;
        field->value = NULL;
        return 0;
    }

    if (namelen) {
        memcpy(field->name, name, namelen);
    }
    if (valuelen) {
        memcpy(field->value, value, valuelen);
    }
    field->namelen = namelen;
    field->valuelen = valuelen;
    block->count++;
    block->list_size = new_size;
    return 1;
}

static nghttp2_nv *
headers_to_nva(pTHX_ AV *headers, size_t *count_out)
{
    I32 last = av_len(headers);
    size_t count = last < 0 ? 0 : (size_t)last + 1;
    nghttp2_nv *nva;
    I32 i;

    *count_out = count;
    if (count == 0) {
        return NULL;
    }

    for (i = 0; i <= last; i++) {
        SV **pair_sv = av_fetch(headers, i, 0);
        AV *pair;
        SV **name_sv;
        SV **value_sv;

        if (!pair_sv || !SvROK(*pair_sv) || SvTYPE(SvRV(*pair_sv)) != SVt_PVAV) {
            croak("header %ld must be a two-element array reference", (long)i);
        }

        pair = (AV *)SvRV(*pair_sv);
        if (av_len(pair) != 1) {
            croak("header %ld must be a two-element array reference", (long)i);
        }

        name_sv = av_fetch(pair, 0, 0);
        value_sv = av_fetch(pair, 1, 0);
        if (!name_sv || !value_sv || !SvOK(*name_sv) || !SvOK(*value_sv)
            || SvROK(*name_sv) || SvROK(*value_sv)) {
            croak("header %ld name and value must be defined scalars", (long)i);
        }
    }

    nva = (nghttp2_nv *)calloc(count, sizeof(*nva));
    if (!nva) {
        croak("unable to allocate HTTP/2 header block");
    }

    for (i = 0; i <= last; i++) {
        SV **pair_sv = av_fetch(headers, i, 0);
        AV *pair = (AV *)SvRV(*pair_sv);
        SV **name_sv = av_fetch(pair, 0, 0);
        SV **value_sv = av_fetch(pair, 1, 0);
        STRLEN name_len;
        STRLEN value_len;

        nva[i].name = (uint8_t *)SvPVbyte(*name_sv, name_len);
        nva[i].namelen = (size_t)name_len;
        nva[i].value = (uint8_t *)SvPVbyte(*value_sv, value_len);
        nva[i].valuelen = (size_t)value_len;
        nva[i].flags = NGHTTP2_NV_FLAG_NONE;
    }

    return nva;
}


static void
validate_uniform_native_view(pTHX_ unblock_h2_session *ps, SV *message,
                             U32 expected_kind, uhttp_native_view *view)
{
    STRLEN version_len;
    const char *version;

    if (!uhttp_native_inspect(aTHX_ &ps->uniform_api, message, view)) {
        croak("Uniform::HTTP native path requires an exact canonical message");
    }
    if (view->kind != expected_kind) {
        croak("Uniform::HTTP native path has the wrong message kind");
    }

    if (SvOK(view->version)) {
        version = SvPVbyte(view->version, version_len);
        if (version_len != 1 || version[0] != '2') {
            croak("explicit HTTP version must be 2");
        }
    }
}

static int
ascii_equal_ci(const char *value, size_t value_len, const char *literal)
{
    size_t literal_len = strlen(literal);
    size_t i;

    if (value_len != literal_len) {
        return 0;
    }

    for (i = 0; i < value_len; i++) {
        unsigned char a = (unsigned char)value[i];
        unsigned char b = (unsigned char)literal[i];

        if (a >= 'A' && a <= 'Z') {
            a = (unsigned char)(a + ('a' - 'A'));
        }
        if (b >= 'A' && b <= 'Z') {
            b = (unsigned char)(b + ('a' - 'A'));
        }
        if (a != b) {
            return 0;
        }
    }

    return 1;
}

static int
http_token_char(unsigned char ch)
{
    if ((ch >= '0' && ch <= '9')
        || (ch >= 'A' && ch <= 'Z')
        || (ch >= 'a' && ch <= 'z')) {
        return 1;
    }

    switch (ch) {
        case '!': case '#': case '$': case '%': case '&': case '\'':
        case '*': case '+': case '-': case '.': case '^': case '_':
        case 0x60: case '|': case '~':
            return 1;
        default:
            return 0;
    }
}

static void
validate_h2_normal_field(pTHX_ SV *name_sv, SV *value_sv, Size_t index)
{
    STRLEN name_len;
    STRLEN value_len;
    const char *name;
    const char *value;
    size_t i;

    if (!name_sv || !value_sv || !SvOK(name_sv) || !SvOK(value_sv)
        || SvROK(name_sv) || SvROK(value_sv)) {
        croak("header %lu name and value must be defined scalars",
            (unsigned long)index);
    }

    name = SvPVbyte(name_sv, name_len);
    value = SvPVbyte(value_sv, value_len);

    if (name_len == 0) {
        croak("header %lu name must not be empty", (unsigned long)index);
    }

    for (i = 0; i < (size_t)name_len; i++) {
        if (!http_token_char((unsigned char)name[i])) {
            croak("header %lu name must be an HTTP token",
                (unsigned long)index);
        }
    }

    for (i = 0; i < (size_t)value_len; i++) {
        unsigned char ch = (unsigned char)value[i];
        if (ch <= 0x08 || (ch >= 0x0a && ch <= 0x1f) || ch == 0x7f) {
            croak("header %lu value contains a prohibited control byte",
                (unsigned long)index);
        }
    }

    if (ascii_equal_ci(name, (size_t)name_len, "connection")
        || ascii_equal_ci(name, (size_t)name_len, "keep-alive")
        || ascii_equal_ci(name, (size_t)name_len, "proxy-connection")
        || ascii_equal_ci(name, (size_t)name_len, "transfer-encoding")
        || ascii_equal_ci(name, (size_t)name_len, "upgrade")) {
        croak("HTTP/2 forbids connection-specific header '%.*s'",
            (int)name_len, name);
    }

    if (ascii_equal_ci(name, (size_t)name_len, "te")
        && !ascii_equal_ci(value, (size_t)value_len, "trailers")) {
        croak("HTTP/2 TE is limited to trailers");
    }
}

static size_t
measure_native_headers(pTHX_ const uhttp_native_section *headers,
                       size_t *name_bytes_out)
{
    Size_t count = uhttp_native_field_count(aTHX_ headers);
    Size_t i;
    size_t name_bytes = 0;

    for (i = 0; i < count; i++) {
        SV *name_sv;
        SV *value_sv;
        STRLEN name_len;

        if (!uhttp_native_field_at(aTHX_ headers, i, &name_sv, &value_sv)) {
            croak("Uniform::HTTP native header index is out of range");
        }
        validate_h2_normal_field(aTHX_ name_sv, value_sv, i);
        (void)SvPVbyte(name_sv, name_len);
        name_bytes += (size_t)name_len;
    }

    *name_bytes_out = name_bytes;
    return (size_t)count;
}

static void
set_nv_from_sv(pTHX_ nghttp2_nv *nv, const char *name, size_t name_len,
               SV *value_sv)
{
    STRLEN value_len;
    const char *value = SvPVbyte(value_sv, value_len);

    nv->name = (uint8_t *)name;
    nv->namelen = name_len;
    nv->value = (uint8_t *)value;
    nv->valuelen = (size_t)value_len;
    nv->flags = NGHTTP2_NV_FLAG_NONE;
}

static void
append_native_headers(pTHX_ nghttp2_nv *nva, size_t start,
                      const uhttp_native_section *headers, char *name_buffer)
{
    Size_t count = uhttp_native_field_count(aTHX_ headers);
    Size_t i;
    size_t out = start;
    char *cursor = name_buffer;

    for (i = 0; i < count; i++, out++) {
        SV *name_sv;
        SV *value_sv;
        STRLEN name_len;
        STRLEN value_len;
        const char *name;
        const char *value;
        size_t j;

        if (!uhttp_native_field_at(aTHX_ headers, i, &name_sv, &value_sv)) {
            croak("Uniform::HTTP native header index is out of range");
        }

        name = SvPVbyte(name_sv, name_len);
        value = SvPVbyte(value_sv, value_len);

        for (j = 0; j < (size_t)name_len; j++) {
            unsigned char ch = (unsigned char)name[j];
            cursor[j] = (char)((ch >= 'A' && ch <= 'Z')
                ? ch + ('a' - 'A') : ch);
        }

        nva[out].name = (uint8_t *)cursor;
        nva[out].namelen = (size_t)name_len;
        nva[out].value = (uint8_t *)value;
        nva[out].valuelen = (size_t)value_len;
        nva[out].flags = NGHTTP2_NV_FLAG_NONE;
        cursor += name_len;
    }
}

static nghttp2_nv *
uniform_request_to_nva(pTHX_ unblock_h2_session *ps, SV *message,
                       size_t *count_out)
{
    uhttp_native_view view;
    SV *method_sv;
    SV *target_sv;
    SV *scheme_sv;
    SV *authority_sv;
    SV *protocol_sv;
    STRLEN method_len;
    STRLEN target_len;
    STRLEN scheme_len = 0;
    STRLEN authority_len = 0;
    STRLEN protocol_len = 0;
    const char *method;
    const char *target;
    const char *scheme = NULL;
    const char *authority = NULL;
    const char *protocol = NULL;
    size_t normal_count;
    size_t normal_name_bytes;
    size_t pseudo_count;
    size_t count;
    nghttp2_nv *nva;
    char *name_buffer;
    size_t out = 0;

    validate_uniform_native_view(
        aTHX_ ps, message, UHTTP_KIND_REQUEST, &view);

    method_sv = view.method;
    target_sv = view.target;
    scheme_sv = view.scheme;
    authority_sv = view.authority;
    protocol_sv = view.protocol;

    method = SvPVbyte(method_sv, method_len);
    target = SvPVbyte(target_sv, target_len);
    if (SvOK(authority_sv)) {
        authority = SvPVbyte(authority_sv, authority_len);
    }
    if (SvOK(scheme_sv)) {
        scheme = SvPVbyte(scheme_sv, scheme_len);
    }
    if (SvOK(protocol_sv)) {
        protocol = SvPVbyte(protocol_sv, protocol_len);
    }

    if (ascii_equal_ci(method, (size_t)method_len, "CONNECT")) {
        if (!authority || authority_len == 0) {
            croak("request_headers(): CONNECT requires authority");
        }
        if (protocol) {
            if (protocol_len == 0) {
                croak("request_headers(): extended CONNECT requires nonempty protocol");
            }
            if (!scheme || scheme_len == 0) {
                croak("request_headers(): extended CONNECT requires scheme");
            }
            if (target_len == 0) {
                croak("request_headers(): extended CONNECT requires a path target");
            }
            pseudo_count = 5;
        }
        else {
            if (scheme) {
                croak("request_headers(): ordinary CONNECT must not have scheme");
            }
            if (target_len != authority_len
                || memcmp(target, authority, (size_t)target_len) != 0) {
                croak("request_headers(): ordinary CONNECT target must equal authority");
            }
            pseudo_count = 2;
        }
    }
    else {
        if (protocol) {
            croak("request_headers(): protocol metadata requires CONNECT");
        }
        if (target_len == 0) {
            croak("request_headers(): HTTP/2 Request requires nonempty path target");
        }
        if (!scheme || scheme_len == 0) {
            croak("request_headers(): HTTP/2 Request requires scheme");
        }
        if (!authority || authority_len == 0) {
            croak("request_headers(): HTTP/2 Request requires authority");
        }
        pseudo_count = 4;
    }

    normal_count = measure_native_headers(
        aTHX_ &view.headers, &normal_name_bytes);
    count = pseudo_count + normal_count;
    nva = (nghttp2_nv *)calloc(1, count * sizeof(*nva) + normal_name_bytes);
    if (!nva) {
        croak("unable to allocate HTTP/2 Uniform native header block");
    }
    name_buffer = (char *)(nva + count);

    set_nv_from_sv(aTHX_ &nva[out++], ":method", 7, method_sv);
    if (ascii_equal_ci(method, (size_t)method_len, "CONNECT")) {
        if (protocol) {
            set_nv_from_sv(aTHX_ &nva[out++], ":protocol", 9, protocol_sv);
            set_nv_from_sv(aTHX_ &nva[out++], ":scheme", 7, scheme_sv);
            set_nv_from_sv(aTHX_ &nva[out++], ":authority", 10, authority_sv);
            set_nv_from_sv(aTHX_ &nva[out++], ":path", 5, target_sv);
        }
        else {
            set_nv_from_sv(aTHX_ &nva[out++], ":authority", 10, authority_sv);
        }
    }
    else {
        set_nv_from_sv(aTHX_ &nva[out++], ":scheme", 7, scheme_sv);
        set_nv_from_sv(aTHX_ &nva[out++], ":authority", 10, authority_sv);
        set_nv_from_sv(aTHX_ &nva[out++], ":path", 5, target_sv);
    }

    append_native_headers(aTHX_ nva, out, &view.headers, name_buffer);
    *count_out = count;
    return nva;
}

static nghttp2_nv *
uniform_response_to_nva(pTHX_ unblock_h2_session *ps, SV *message,
                        size_t *count_out)
{
    uhttp_native_view view;
    IV status_value;
    size_t normal_count;
    size_t normal_name_bytes;
    size_t count;
    nghttp2_nv *nva;
    char *status_buffer;
    char *name_buffer;

    validate_uniform_native_view(
        aTHX_ ps, message, UHTTP_KIND_RESPONSE, &view);

    status_value = SvIV(view.status);
    if (status_value < 100 || status_value > 599) {
        croak("response_headers(): status must be an integer from 100 through 599");
    }

    normal_count = measure_native_headers(
        aTHX_ &view.headers, &normal_name_bytes);
    count = 1 + normal_count;
    nva = (nghttp2_nv *)calloc(
        1, count * sizeof(*nva) + 3 + normal_name_bytes);
    if (!nva) {
        croak("unable to allocate HTTP/2 Uniform native header block");
    }

    status_buffer = (char *)(nva + count);
    status_buffer[0] = (char)('0' + (status_value / 100) % 10);
    status_buffer[1] = (char)('0' + (status_value / 10) % 10);
    status_buffer[2] = (char)('0' + status_value % 10);
    name_buffer = status_buffer + 3;

    nva[0].name = (uint8_t *)":status";
    nva[0].namelen = 7;
    nva[0].value = (uint8_t *)status_buffer;
    nva[0].valuelen = 3;
    nva[0].flags = NGHTTP2_NV_FLAG_NONE;

    append_native_headers(aTHX_ nva, 1, &view.headers, name_buffer);
    *count_out = count;
    return nva;
}

static int
bytes_equal(const char *value, size_t value_len, const char *literal)
{
    size_t literal_len = strlen(literal);
    return value_len == literal_len
        && memcmp(value, literal, literal_len) == 0;
}

static int
span_is_token(const char *value, size_t len)
{
    size_t i;

    if (!len) {
        return 0;
    }
    for (i = 0; i < len; i++) {
        if (!http_token_char((unsigned char)value[i])) {
            return 0;
        }
    }
    return 1;
}

static const char *
validate_received_normal_field(const unblock_h2_header_field *field)
{
    size_t i;

    if (!field->namelen) {
        return "HTTP/2 field name must not be empty";
    }

    for (i = 0; i < field->namelen; i++) {
        unsigned char ch = (unsigned char)field->name[i];
        if (ch >= 'A' && ch <= 'Z') {
            return "HTTP/2 field names must be lowercase";
        }
        if (!http_token_char(ch)) {
            return "HTTP/2 field name must be an HTTP token";
        }
    }

    for (i = 0; i < field->valuelen; i++) {
        unsigned char ch = (unsigned char)field->value[i];
        if (ch <= 0x08 || (ch >= 0x0a && ch <= 0x1f) || ch == 0x7f) {
            return "HTTP/2 field value contains a prohibited control byte";
        }
    }

    if (bytes_equal(field->name, field->namelen, "connection")
        || bytes_equal(field->name, field->namelen, "keep-alive")
        || bytes_equal(field->name, field->namelen, "proxy-connection")
        || bytes_equal(field->name, field->namelen, "transfer-encoding")
        || bytes_equal(field->name, field->namelen, "upgrade")) {
        return "HTTP/2 forbids connection-specific field";
    }

    if (bytes_equal(field->name, field->namelen, "te")
        && !ascii_equal_ci(field->value, field->valuelen, "trailers")) {
        return "HTTP/2 TE is limited to trailers";
    }

    return NULL;
}

static const char *
validate_request_target(const char *value, size_t len)
{
    size_t i;

    if (!len) {
        return "request_from_headers(): target must not be empty";
    }
    for (i = 0; i < len; i++) {
        unsigned char ch = (unsigned char)value[i];
        if (ch <= 0x20 || ch == 0x7f) {
            return "request_from_headers(): target contains spaces or control bytes";
        }
    }
    return NULL;
}

static const char *
validate_request_scheme(const char *value, size_t len)
{
    size_t i;

    if (!len
        || !((value[0] >= 'A' && value[0] <= 'Z')
            || (value[0] >= 'a' && value[0] <= 'z'))) {
        return "request_from_headers(): scheme must be a valid URI scheme";
    }

    for (i = 1; i < len; i++) {
        unsigned char ch = (unsigned char)value[i];
        if (!((ch >= 'A' && ch <= 'Z')
            || (ch >= 'a' && ch <= 'z')
            || (ch >= '0' && ch <= '9')
            || ch == '+' || ch == '-' || ch == '.')) {
            return "request_from_headers(): scheme must be a valid URI scheme";
        }
    }
    return NULL;
}

static const char *
validate_request_authority(const char *value, size_t len)
{
    size_t i;

    if (!len) {
        return "request_from_headers(): authority must not be empty";
    }

    for (i = 0; i < len; i++) {
        unsigned char ch = (unsigned char)value[i];
        if (ch <= 0x20 || ch == 0x7f
            || ch == '/' || ch == '?' || ch == '#') {
            return "request_from_headers(): authority contains a prohibited delimiter or control byte";
        }
    }
    return NULL;
}

static void
set_native_span(uhttp_native_bytes *span, const char *data, size_t len)
{
    span->data = data;
    span->len = (STRLEN)len;
}

static U32
received_native_flags(U32 kind, int complete)
{
    U32 flags = UHTTP_HEADERS_LOSSLESS | UHTTP_TRAILERS_LOSSLESS;

    if (kind == UHTTP_KIND_REQUEST) {
        flags |= UHTTP_TARGET_EXACT;
    }

    if (complete) {
        flags |= UHTTP_COMPLETE;
    }
    else {
        flags |= UHTTP_MUTABLE | UHTTP_BODY_MUTABLE
            | UHTTP_TRAILERS_MUTABLE;
    }

    return flags;
}

static SV *
request_from_native_headers(pTHX_ unblock_h2_session *ps,
                            const unblock_h2_header_block *block,
                            const char **error_out)
{
    const unblock_h2_header_field *method = NULL;
    const unblock_h2_header_field *scheme = NULL;
    const unblock_h2_header_field *authority = NULL;
    const unblock_h2_header_field *path = NULL;
    const unblock_h2_header_field *protocol = NULL;
    uhttp_native_field *normal = NULL;
    size_t normal_count = 0;
    size_t i;
    int saw_normal = 0;
    const char *error = NULL;
    uhttp_native_input input;
    SV *object;

    if (block->count) {
        normal = (uhttp_native_field *)calloc(block->count, sizeof(*normal));
        if (!normal) {
            croak("unable to allocate HTTP/2 native request fields");
        }
    }

    for (i = 0; i < block->count; i++) {
        const unblock_h2_header_field *field = &block->fields[i];

        if (field->namelen && field->name[0] == ':') {
            if (saw_normal) {
                error = "request_from_headers(): pseudo-header follows a regular field";
                break;
            }

#define UHTTP_H2_PSEUDO(literal, slot) \
            if (bytes_equal(field->name, field->namelen, literal)) { \
                if (slot) { \
                    error = "request_from_headers(): duplicate pseudo-header"; \
                    break; \
                } \
                slot = field; \
                continue; \
            }
            UHTTP_H2_PSEUDO(":method", method)
            UHTTP_H2_PSEUDO(":scheme", scheme)
            UHTTP_H2_PSEUDO(":authority", authority)
            UHTTP_H2_PSEUDO(":path", path)
            UHTTP_H2_PSEUDO(":protocol", protocol)
#undef UHTTP_H2_PSEUDO
            error = "request_from_headers(): unsupported pseudo-header";
            break;
        }

        saw_normal = 1;
        error = validate_received_normal_field(field);
        if (error) {
            break;
        }

        set_native_span(&normal[normal_count].name,
            field->name, field->namelen);
        set_native_span(&normal[normal_count].value,
            field->value, field->valuelen);
        normal_count++;
    }

    if (!error && (!method || !method->valuelen)) {
        error = "request_from_headers(): missing :method";
    }
    if (!error && !span_is_token(method->value, method->valuelen)) {
        error = "request_from_headers(): method must be an HTTP token";
    }

    if (!error && ascii_equal_ci(method->value, method->valuelen, "CONNECT")) {
        if (!authority || !authority->valuelen) {
            error = "request_from_headers(): CONNECT requires :authority";
        }
        else if (protocol) {
            if (!protocol->valuelen) {
                error = "request_from_headers(): extended CONNECT requires nonempty :protocol";
            }
            else if (!scheme || !scheme->valuelen) {
                error = "request_from_headers(): extended CONNECT requires :scheme";
            }
            else if (!path || !path->valuelen) {
                error = "request_from_headers(): extended CONNECT requires :path";
            }
        }
        else if (scheme || path) {
            error = "request_from_headers(): ordinary CONNECT must omit :scheme and :path";
        }
    }
    else if (!error) {
        if (protocol) {
            error = "request_from_headers(): :protocol requires CONNECT";
        }
        else if (!scheme || !scheme->valuelen) {
            error = "request_from_headers(): missing :scheme";
        }
        else if (!path || !path->valuelen) {
            error = "request_from_headers(): missing :path";
        }
        else if (!authority || !authority->valuelen) {
            error = "request_from_headers(): missing :authority";
        }
    }

    if (!error && protocol
        && !span_is_token(protocol->value, protocol->valuelen)) {
        error = "request_from_headers(): protocol must be an HTTP token";
    }
    if (!error && scheme) {
        error = validate_request_scheme(scheme->value, scheme->valuelen);
    }
    if (!error && authority) {
        error = validate_request_authority(
            authority->value, authority->valuelen);
    }

    if (!error) {
        const char *target;
        size_t target_len;

        if (path) {
            target = path->value;
            target_len = path->valuelen;
        }
        else {
            target = authority->value;
            target_len = authority->valuelen;
        }

        error = validate_request_target(target, target_len);
        if (!error) {
            uhttp_native_input_init(&input, UHTTP_KIND_REQUEST);
            input.flags = received_native_flags(
                UHTTP_KIND_REQUEST,
                (block->flags & NGHTTP2_FLAG_END_STREAM) ? 1 : 0);
            set_native_span(&input.version, "2", 1);
            set_native_span(&input.method, method->value, method->valuelen);
            set_native_span(&input.target, target, target_len);
            if (scheme) {
                set_native_span(
                    &input.scheme, scheme->value, scheme->valuelen);
            }
            if (authority) {
                set_native_span(
                    &input.authority, authority->value, authority->valuelen);
            }
            if (protocol) {
                set_native_span(
                    &input.protocol, protocol->value, protocol->valuelen);
            }
            input.headers = normal;
            input.header_count = normal_count;
            object = uhttp_native_from_validated(
                aTHX_ &ps->uniform_api, &input, UHTTP_NATIVE_TRUSTED);
            free(normal);
            *error_out = NULL;
            return object;
        }
    }

    free(normal);
    *error_out = error;
    return NULL;
}

static SV *
response_from_native_headers(pTHX_ unblock_h2_session *ps,
                             const unblock_h2_header_block *block,
                             const char **error_out)
{
    const unblock_h2_header_field *status = NULL;
    uhttp_native_field *normal = NULL;
    size_t normal_count = 0;
    size_t i;
    int saw_normal = 0;
    IV status_value = 0;
    const char *error = NULL;
    uhttp_native_input input;
    SV *object;

    if (block->count) {
        normal = (uhttp_native_field *)calloc(block->count, sizeof(*normal));
        if (!normal) {
            croak("unable to allocate HTTP/2 native response fields");
        }
    }

    for (i = 0; i < block->count; i++) {
        const unblock_h2_header_field *field = &block->fields[i];

        if (field->namelen && field->name[0] == ':') {
            size_t j;

            if (saw_normal) {
                error = "response_from_headers(): pseudo-header follows a regular field";
                break;
            }
            if (!bytes_equal(field->name, field->namelen, ":status")) {
                error = "response_from_headers(): unsupported pseudo-header";
                break;
            }
            if (status) {
                error = "response_from_headers(): duplicate pseudo-header";
                break;
            }

            status = field;
            for (j = 0; j < field->valuelen; j++) {
                unsigned char ch = (unsigned char)field->value[j];
                if (ch < '0' || ch > '9') {
                    error = "response_from_headers(): status must be an integer from 100 through 599";
                    break;
                }
                if (status_value > 599) {
                    error = "response_from_headers(): status must be an integer from 100 through 599";
                    break;
                }
                status_value = status_value * 10 + (ch - '0');
            }
            if (error) {
                break;
            }
            continue;
        }

        saw_normal = 1;
        error = validate_received_normal_field(field);
        if (error) {
            break;
        }

        set_native_span(&normal[normal_count].name,
            field->name, field->namelen);
        set_native_span(&normal[normal_count].value,
            field->value, field->valuelen);
        normal_count++;
    }

    if (!error && (!status || !status->valuelen
        || status_value < 100 || status_value > 599)) {
        error = "response_from_headers(): status must be an integer from 100 through 599";
    }

    if (!error) {
        int complete = (status_value >= 100 && status_value < 200)
            ? 1
            : ((block->flags & NGHTTP2_FLAG_END_STREAM) ? 1 : 0);

        uhttp_native_input_init(&input, UHTTP_KIND_RESPONSE);
        input.flags = received_native_flags(UHTTP_KIND_RESPONSE, complete);
        set_native_span(&input.version, "2", 1);
        input.status = status_value;
        input.headers = normal;
        input.header_count = normal_count;
        object = uhttp_native_from_validated(
            aTHX_ &ps->uniform_api, &input, UHTTP_NATIVE_TRUSTED);
        free(normal);
        *error_out = NULL;
        return object;
    }

    free(normal);
    *error_out = error;
    return NULL;
}

static AV *
trailers_from_native_headers(pTHX_ const unblock_h2_header_block *block,
                             const char **error_out)
{
    AV *headers = newAV();
    size_t i;

    for (i = 0; i < block->count; i++) {
        const unblock_h2_header_field *field = &block->fields[i];
        const char *error;
        AV *pair;

        if (field->namelen && field->name[0] == ':') {
            SvREFCNT_dec((SV *)headers);
            *error_out = "apply_trailers(): unsupported pseudo-header";
            return NULL;
        }

        error = validate_received_normal_field(field);
        if (error) {
            SvREFCNT_dec((SV *)headers);
            *error_out = error;
            return NULL;
        }

        pair = newAV();
        av_push(pair, newSVpvn(field->name, field->namelen));
        av_push(pair, newSVpvn(field->value, field->valuelen));
        av_push(headers, newRV_noinc((SV *)pair));
    }

    *error_out = NULL;
    return headers;
}

static int
header_block_has_name(const unblock_h2_header_block *block,
                      const char *name)
{
    size_t i;

    for (i = 0; i < block->count; i++) {
        if (bytes_equal(
                block->fields[i].name,
                block->fields[i].namelen,
                name)) {
            return 1;
        }
    }
    return 0;
}

static void
attach_native_header_result(pTHX_ unblock_h2_session *ps,
                            const nghttp2_frame *frame, HV *hv,
                            unblock_h2_header_block *block)
{
    const char *error = NULL;
    SV *message = NULL;
    AV *headers = NULL;

    if (!block) {
        hv_store(hv, "header_error", 12,
            newSVpv("HTTP/2 header block state is missing", 0), 0);
        hv_store(hv, "header_error_code", 17,
            newSVuv(NGHTTP2_PROTOCOL_ERROR), 0);
        return;
    }

    if (block->error) {
        hv_store(hv, "header_error", 12,
            newSVpv(block->error, 0), 0);
        hv_store(hv, "header_error_code", 17,
            newSVuv(block->error_code), 0);
        return;
    }

    switch (block->category) {
        case NGHTTP2_HCAT_REQUEST:
            if (!ps->server) {
                error = "unexpected HTTP/2 request header category";
                break;
            }
            message = request_from_native_headers(
                aTHX_ ps, block, &error);
            break;

        case NGHTTP2_HCAT_RESPONSE:
            if (ps->server) {
                error = "unexpected HTTP/2 response header category";
                break;
            }
            message = response_from_native_headers(
                aTHX_ ps, block, &error);
            break;

        case NGHTTP2_HCAT_HEADERS:
            if (!ps->server && header_block_has_name(block, ":status")) {
                message = response_from_native_headers(
                    aTHX_ ps, block, &error);
            }
            else {
                headers = trailers_from_native_headers(
                    aTHX_ block, &error);
            }
            break;

        default:
            error = "unsupported HTTP/2 header category";
            break;
    }

    if (error) {
        hv_store(hv, "header_error", 12, newSVpv(error, 0), 0);
        hv_store(hv, "header_error_code", 17,
            newSVuv(NGHTTP2_PROTOCOL_ERROR), 0);
        return;
    }

    if (message) {
        hv_store(hv, "uniform_message", 15, message, 0);
    }
    else if (headers) {
        hv_store(hv, "native_headers", 14,
            newRV_noinc((SV *)headers), 0);
    }
}

static int
call_scalar_callback(pTHX_ unblock_h2_session *ps, SV *callback, AV *args)
{
    dSP;
    int count;
    int result = 0;
    I32 i;
    I32 len;

    if (!callback || !SvOK(callback)) {
        return 0;
    }

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    len = args ? av_len(args) + 1 : 0;
    for (i = 0; i < len; i++) {
        SV **arg = av_fetch(args, i, 0);
        if (arg) {
            XPUSHs(*arg);
        }
    }

    PUTBACK;
    count = call_sv(callback, G_SCALAR | G_EVAL);
    SPAGAIN;

    if (SvTRUE(ERRSV)) {
        set_callback_error(aTHX_ ps, "HTTP/2 callback failed");
        result = NGHTTP2_ERR_CALLBACK_FAILURE;
    }
    else if (count > 0) {
        SV *return_value = POPs;
        if (SvOK(return_value)) {
            result = (int)SvIV(return_value);
        }
    }

    PUTBACK;
    FREETMPS;
    LEAVE;
    return result;
}

static HV *
frame_to_hv(pTHX_ const nghttp2_frame *frame)
{
    HV *hv = newHV();
    AV *settings_av;
    AV *entry_av;
    size_t i;

    hv_store(hv, "stream_id", 9, newSViv(frame->hd.stream_id), 0);
    hv_store(hv, "type", 4, newSViv(frame->hd.type), 0);
    hv_store(hv, "flags", 5, newSViv(frame->hd.flags), 0);
    hv_store(hv, "length", 6, newSVuv((UV)frame->hd.length), 0);

    if (frame->hd.type == NGHTTP2_HEADERS) {
        hv_store(hv, "headers_category", 16,
            newSViv(frame->headers.cat), 0);
    }
    else if (frame->hd.type == NGHTTP2_SETTINGS
             && !(frame->hd.flags & NGHTTP2_FLAG_ACK)) {
        settings_av = newAV();
        for (i = 0; i < frame->settings.niv; i++) {
            entry_av = newAV();
            av_push(entry_av,
                newSViv((IV)frame->settings.iv[i].settings_id));
            av_push(entry_av,
                newSVuv((UV)frame->settings.iv[i].value));
            av_push(settings_av, newRV_noinc((SV *)entry_av));
        }
        hv_store(hv, "settings", 8,
            newRV_noinc((SV *)settings_av), 0);
    }
    else if (frame->hd.type == NGHTTP2_PING) {
        hv_store(hv, "opaque_data", 11,
            newSVpvn((const char *)frame->ping.opaque_data, 8), 0);
    }
    else if (frame->hd.type == NGHTTP2_PRIORITY_UPDATE
             && frame->ext.payload) {
        nghttp2_ext_priority_update *priority_update
            = (nghttp2_ext_priority_update *)frame->ext.payload;
        hv_store(hv, "prioritized_stream_id", 21,
            newSViv(priority_update->stream_id), 0);
        hv_store(hv, "priority_field_value", 20,
            newSVpvn(
                priority_update->field_value
                    ? (const char *)priority_update->field_value
                    : "",
                priority_update->field_value_len
            ), 0);
    }
    else if (frame->hd.type == NGHTTP2_GOAWAY) {
        hv_store(hv, "last_stream_id", 14,
            newSViv(frame->goaway.last_stream_id), 0);
        hv_store(hv, "error_code", 10,
            newSVuv((UV)frame->goaway.error_code), 0);
        hv_store(hv, "debug_data", 10,
            newSVpvn(
                frame->goaway.opaque_data
                    ? (const char *)frame->goaway.opaque_data
                    : "",
                frame->goaway.opaque_data_len
            ), 0);
    }

    return hv;
}

static ssize_t
provider_read_callback(
    nghttp2_session *session,
    int32_t stream_id,
    uint8_t *buf,
    size_t length,
    uint32_t *data_flags,
    nghttp2_data_source *source,
    void *user_data)
{
    dTHX;
    unblock_h2_session *ps = (unblock_h2_session *)user_data;
    unblock_h2_provider *provider = (unblock_h2_provider *)source->ptr;
    dSP;
    int count;
    ssize_t result = 0;

    if (!provider || provider->released) {
        *data_flags |= NGHTTP2_DATA_FLAG_EOF;
        return 0;
    }

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(stream_id)));
    XPUSHs(sv_2mortal(newSVuv((UV)length)));
    PUTBACK;

    count = call_sv(provider->callback, G_ARRAY | G_EVAL);
    SPAGAIN;

    if (provider->released) {
        *data_flags |= NGHTTP2_DATA_FLAG_EOF;
        result = 0;
    }
    else if (SvTRUE(ERRSV)) {
        set_callback_error(aTHX_ ps, "HTTP/2 data provider failed");
        result = NGHTTP2_ERR_CALLBACK_FAILURE;
    }
    else if (count == 0) {
        provider->deferred = 1;
        result = NGHTTP2_ERR_DEFERRED;
    }
    else {
        SV **values = SP - count + 1;
        SV *data_sv = values[0];
        SV *eof_sv = count >= 2 ? values[1] : NULL;
        SV *no_end_stream_sv = count >= 3 ? values[2] : NULL;

        if (!SvOK(data_sv)) {
            provider->deferred = 1;
            result = NGHTTP2_ERR_DEFERRED;
        }
        else {
            STRLEN data_len;
            const char *data = SvPVbyte(data_sv, data_len);

            if ((size_t)data_len > length) {
                if (!ps->callback_error) {
                    ps->callback_error = newSVpvf(
                        "HTTP/2 data provider returned %lu bytes with a %lu byte limit",
                        (unsigned long)data_len,
                        (unsigned long)length
                    );
                }
                result = NGHTTP2_ERR_CALLBACK_FAILURE;
            }
            else {
                if (data_len) {
                    memcpy(buf, data, data_len);
                }
                result = (ssize_t)data_len;
                provider->deferred = 0;

                if (eof_sv && SvTRUE(eof_sv)) {
                    *data_flags |= NGHTTP2_DATA_FLAG_EOF;
                    if (no_end_stream_sv && SvTRUE(no_end_stream_sv)) {
                        *data_flags |= NGHTTP2_DATA_FLAG_NO_END_STREAM;
                    }
                }
                else if (data_len == 0) {
                    provider->deferred = 1;
                    result = NGHTTP2_ERR_DEFERRED;
                }
            }
        }
    }

    if (count > 0) {
        SP -= count;
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return result;
}

static int
on_begin_headers_callback(nghttp2_session *session,
                          const nghttp2_frame *frame,
                          void *user_data)
{
    dTHX;
    unblock_h2_session *ps = (unblock_h2_session *)user_data;
    AV *args;
    int result = 0;

    if (ps->cb_begin_headers) {
        args = newAV();
        av_push(args, newSViv(frame->hd.stream_id));
        av_push(args, newSViv(frame->hd.type));
        av_push(args, newSViv(frame->hd.flags));
        result = call_scalar_callback(
            aTHX_ ps, ps->cb_begin_headers, args);
        SvREFCNT_dec((SV *)args);
        if (result != 0) {
            return result;
        }
    }

    if (frame->hd.type == NGHTTP2_HEADERS
        && !start_header_block(aTHX_ ps, frame)) {
        if (!ps->callback_error) {
            ps->callback_error = newSVpv(
                "unable to allocate HTTP/2 receive header block", 0);
        }
        return NGHTTP2_ERR_CALLBACK_FAILURE;
    }

    return 0;
}

static int
on_header_callback(nghttp2_session *session,
                   const nghttp2_frame *frame,
                   const uint8_t *name,
                   size_t namelen,
                   const uint8_t *value,
                   size_t valuelen,
                   uint8_t flags,
                   void *user_data)
{
    dTHX;
    unblock_h2_session *ps = (unblock_h2_session *)user_data;
    unblock_h2_header_block *block;

    block = find_header_block(ps, frame->hd.stream_id);
    if (!block) {
        if (!ps->callback_error) {
            ps->callback_error = newSVpv(
                "HTTP/2 receive header block state is missing", 0);
        }
        return NGHTTP2_ERR_CALLBACK_FAILURE;
    }

    if (!append_header_field(
            aTHX_ ps, block, name, namelen, value, valuelen)) {
        if (!ps->callback_error) {
            ps->callback_error = newSVpv(
                "unable to allocate HTTP/2 receive header field", 0);
        }
        return NGHTTP2_ERR_CALLBACK_FAILURE;
    }

    return 0;
}

static int
on_frame_recv_callback(nghttp2_session *session,
                       const nghttp2_frame *frame,
                       void *user_data)
{
    dTHX;
    unblock_h2_session *ps = (unblock_h2_session *)user_data;
    unblock_h2_header_block *block = NULL;
    HV *frame_hv;
    AV *args;
    int result;

    if (frame->hd.type == NGHTTP2_HEADERS) {
        block = take_header_block(ps, frame->hd.stream_id);
    }

    if (!ps->cb_frame_recv) {
        free_header_block(aTHX_ block);
        return 0;
    }

    frame_hv = frame_to_hv(aTHX_ frame);
    if (frame->hd.type == NGHTTP2_HEADERS) {
        attach_native_header_result(
            aTHX_ ps, frame, frame_hv, block);
    }
    free_header_block(aTHX_ block);

    args = newAV();
    av_push(args, newRV_noinc((SV *)frame_hv));
    result = call_scalar_callback(aTHX_ ps, ps->cb_frame_recv, args);
    SvREFCNT_dec((SV *)args);
    return result;
}

static int
on_data_chunk_recv_callback(nghttp2_session *session,
                            uint8_t flags,
                            int32_t stream_id,
                            const uint8_t *data,
                            size_t len,
                            void *user_data)
{
    dTHX;
    unblock_h2_session *ps = (unblock_h2_session *)user_data;
    AV *args;
    int consume_rv;
    int result;

    consume_rv = nghttp2_session_consume_connection(session, len);
    if (consume_rv != 0) {
        if (!ps->callback_error) {
            ps->callback_error = newSVpvf(
                "nghttp2_session_consume_connection failed (%d): %s",
                consume_rv, nghttp2_strerror(consume_rv)
            );
        }
        return NGHTTP2_ERR_CALLBACK_FAILURE;
    }

    if (!ps->cb_data_chunk_recv) {
        return 0;
    }

    args = newAV();
    av_push(args, newSViv(stream_id));
    av_push(args, newSVpvn((const char *)data, len));
    av_push(args, newSViv(flags));
    result = call_scalar_callback(aTHX_ ps, ps->cb_data_chunk_recv, args);
    SvREFCNT_dec((SV *)args);
    return result;
}

static int
on_stream_close_callback(nghttp2_session *session,
                         int32_t stream_id,
                         uint32_t error_code,
                         void *user_data)
{
    dTHX;
    unblock_h2_session *ps = (unblock_h2_session *)user_data;
    AV *args;
    int result = 0;

    remove_provider(aTHX_ ps, stream_id);
    remove_header_block(aTHX_ ps, stream_id);

    if (!ps->cb_stream_close) {
        return 0;
    }

    args = newAV();
    av_push(args, newSViv(stream_id));
    av_push(args, newSVuv((UV)error_code));
    result = call_scalar_callback(aTHX_ ps, ps->cb_stream_close, args);
    SvREFCNT_dec((SV *)args);
    return result;
}

static int
on_frame_not_send_callback(nghttp2_session *session,
                           const nghttp2_frame *frame,
                           int lib_error_code,
                           void *user_data)
{
    dTHX;
    unblock_h2_session *ps = (unblock_h2_session *)user_data;

    if (frame->hd.type == NGHTTP2_HEADERS
        && nghttp2_session_get_stream_remote_close(session, frame->hd.stream_id) < 0) {
        remove_provider(aTHX_ ps, frame->hd.stream_id);
    }

    return 0;
}

static int
on_invalid_frame_recv_callback(nghttp2_session *session,
                               const nghttp2_frame *frame,
                               int lib_error_code,
                               void *user_data)
{
    dTHX;
    unblock_h2_session *ps = (unblock_h2_session *)user_data;
    AV *args;
    int result;

    if (!ps->cb_invalid_frame) {
        return 0;
    }

    args = newAV();
    av_push(args, newRV_noinc((SV *)frame_to_hv(aTHX_ frame)));
    av_push(args, newSViv(lib_error_code));
    result = call_scalar_callback(aTHX_ ps, ps->cb_invalid_frame, args);
    SvREFCNT_dec((SV *)args);
    return result;
}

static int
error_callback(nghttp2_session *session,
               int lib_error_code,
               const char *msg,
               size_t len,
               void *user_data)
{
    dTHX;
    unblock_h2_session *ps = (unblock_h2_session *)user_data;
    AV *args;
    int result;

    if (!ps->cb_error) {
        return 0;
    }

    args = newAV();
    av_push(args, newSViv(lib_error_code));
    av_push(args, newSVpvn(msg ? msg : "", msg ? len : 0));
    result = call_scalar_callback(aTHX_ ps, ps->cb_error, args);
    SvREFCNT_dec((SV *)args);
    return result;
}

static int
configure_callbacks(pTHX_ nghttp2_session_callbacks **callbacks_out)
{
    nghttp2_session_callbacks *callbacks;
    int rv = nghttp2_session_callbacks_new(&callbacks);

    if (rv != 0) {
        return rv;
    }

    nghttp2_session_callbacks_set_on_begin_headers_callback(
        callbacks, on_begin_headers_callback);
    nghttp2_session_callbacks_set_on_header_callback(
        callbacks, on_header_callback);
    nghttp2_session_callbacks_set_on_frame_recv_callback(
        callbacks, on_frame_recv_callback);
    nghttp2_session_callbacks_set_on_data_chunk_recv_callback(
        callbacks, on_data_chunk_recv_callback);
    nghttp2_session_callbacks_set_on_stream_close_callback(
        callbacks, on_stream_close_callback);
    nghttp2_session_callbacks_set_on_frame_not_send_callback(
        callbacks, on_frame_not_send_callback);
    nghttp2_session_callbacks_set_on_invalid_frame_recv_callback(
        callbacks, on_invalid_frame_recv_callback);
    nghttp2_session_callbacks_set_error_callback2(callbacks, error_callback);

    *callbacks_out = callbacks;
    return 0;
}

static unblock_h2_session *
new_session(pTHX_ HV *callbacks_hv, int server, size_t max_header_list_size)
{
    unblock_h2_session *ps;
    uhttp_native_api uniform_api;
    nghttp2_session_callbacks *callbacks = NULL;
    nghttp2_option *option = NULL;
    int rv;

    if (!uhttp_native_init(aTHX_ &uniform_api, UHTTP_NATIVE_ABI_VERSION)) {
        croak("Uniform::HTTP 0.06 native ABI is unavailable or incompatible");
    }

    ps = (unblock_h2_session *)calloc(1, sizeof(*ps));
    if (!ps) {
        croak("unable to allocate HTTP/2 session");
    }
    ps->uniform_api = uniform_api;
    ps->server = server ? 1 : 0;
    ps->max_header_list_size = max_header_list_size;

    load_callbacks(aTHX_ ps, callbacks_hv);
    rv = configure_callbacks(aTHX_ &callbacks);
    if (rv != 0) {
        free_header_blocks(aTHX_ ps);
        release_callbacks(aTHX_ ps);
        free(ps);
        croak("nghttp2_session_callbacks_new failed (%d): %s",
            rv, nghttp2_strerror(rv));
    }

    rv = nghttp2_option_new(&option);
    if (rv != 0) {
        nghttp2_session_callbacks_del(callbacks);
        release_callbacks(aTHX_ ps);
        free(ps);
        croak("nghttp2_option_new failed (%d): %s",
            rv, nghttp2_strerror(rv));
    }

    nghttp2_option_set_no_auto_window_update(option, 1);

    if (server) {
        nghttp2_option_set_builtin_recv_extension_type(
            option, NGHTTP2_PRIORITY_UPDATE);
        rv = nghttp2_session_server_new2(
            &ps->session, callbacks, ps, option);
    }
    else {
        rv = nghttp2_session_client_new2(
            &ps->session, callbacks, ps, option);
    }

    nghttp2_option_del(option);
    nghttp2_session_callbacks_del(callbacks);

    if (rv != 0) {
        release_callbacks(aTHX_ ps);
        free(ps);
        croak("nghttp2 session creation failed (%d): %s",
            rv, nghttp2_strerror(rv));
    }

    return ps;
}

static HV *
ub_http2_native_engine_hv(pTHX_ ub_http2_native_context *context)
{
    if (!context || !context->engine || !SvROK(context->engine)
        || SvTYPE(SvRV(context->engine)) != SVt_PVHV) {
        croak("invalid Unblock::HTTP2 native transport context");
    }

    return (HV *)SvRV(context->engine);
}

static int
ub_http2_native_engine_closed(pTHX_ ub_http2_native_context *context)
{
    HV *hv = ub_http2_native_engine_hv(aTHX_ context);
    SV **value = hv_fetch(hv, "closed", 6, 0);

    return value && SvOK(*value) && SvTRUE(*value) ? 1 : 0;
}

static int
ub_http2_native_engine_in_call(pTHX_ ub_http2_native_context *context)
{
    HV *hv = ub_http2_native_engine_hv(aTHX_ context);
    SV **value = hv_fetch(hv, "in_session_call", 15, 0);

    return value && SvOK(*value) && SvTRUE(*value) ? 1 : 0;
}

static void
ub_http2_native_set_engine_in_call(
    pTHX_ ub_http2_native_context *context, int value)
{
    HV *hv = ub_http2_native_engine_hv(aTHX_ context);
    SV **slot = hv_fetch(hv, "in_session_call", 15, 0);

    if (slot) {
        sv_setiv(*slot, value ? 1 : 0);
    }
    else {
        hv_store(hv, "in_session_call", 15, newSViv(value ? 1 : 0), 0);
    }
}

static CV *
ub_http2_native_engine_method(
    pTHX_
    ub_http2_native_context *context,
    CV **slot,
    const char *name)
{
    GV *gv;
    CV *cv;

    if (*slot) {
        return *slot;
    }

    if (!context || !context->engine || !SvROK(context->engine)) {
        croak("invalid Unblock::HTTP2 native transport engine");
    }

    gv = gv_fetchmethod_autoload(
        SvSTASH(SvRV(context->engine)), name, 0);
    if (!gv || !(cv = GvCV(gv))) {
        croak("Unblock::HTTP2 native transport method %s is unavailable",
            name);
    }

    *slot = (CV *)SvREFCNT_inc((SV *)cv);
    return *slot;
}

static void
ub_http2_native_call_engine(
    pTHX_
    ub_http2_native_context *context,
    CV **slot,
    const char *name,
    SV *arg)
{
    CV *cv = ub_http2_native_engine_method(
        aTHX_ context, slot, name);
    SV *error = NULL;
    dSP;

    ENTER;
    SAVETMPS;
    sv_setsv(ERRSV, &PL_sv_undef);
    PUSHMARK(SP);
    XPUSHs(context->engine);
    if (arg) {
        XPUSHs(arg);
    }
    PUTBACK;
    call_sv((SV *)cv, G_DISCARD | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        error = newSVsv(ERRSV);
    }
    PUTBACK;
    FREETMPS;
    LEAVE;

    if (error) {
        sv_2mortal(error);
        croak("%s", SvPV_nolen(error));
    }
}

static void
ub_http2_native_finish_close(
    pTHX_ ub_http2_native_context *context, SV *error)
{
    if (!ub_http2_native_engine_closed(aTHX_ context)) {
        ub_http2_native_call_engine(
            aTHX_
            context,
            &context->finish_close_cv,
            "_finish_close",
            error
        );
    }
}

static int
ub_http2_native_after_session(
    pTHX_ ub_http2_native_context *context)
{
    HV *hv = ub_http2_native_engine_hv(aTHX_ context);
    SV **pending = hv_fetch(hv, "close_pending", 13, 0);

    if (pending && SvOK(*pending)) {
        SV *error = newSVsv(*pending);
        hv_delete(hv, "close_pending", 13, G_DISCARD);
        ub_http2_native_finish_close(aTHX_ context, error);
        SvREFCNT_dec(error);
    }
    else {
        ub_http2_native_call_engine(
            aTHX_
            context,
            &context->after_session_cv,
            "_after_session_call",
            NULL
        );
    }

    return ub_http2_native_engine_closed(aTHX_ context) ? 1 : 0;
}

static SV *
ub_http2_native_take_callback_error(
    pTHX_ unblock_h2_session *ps)
{
    SV *error;

    if (!ps->callback_error) {
        return NULL;
    }

    error = newSVsv(ps->callback_error);
    clear_callback_error(aTHX_ ps);
    return error;
}

static void
ub_http2_native_croak_error(
    pTHX_ ub_http2_native_context *context, SV *error)
{
    const char *message;

    if (!error) {
        error = newSVpv("Unblock::HTTP2 native transport failure", 0);
    }

    ub_http2_native_finish_close(aTHX_ context, error);
    message = SvPV_nolen(error);
    sv_2mortal(error);
    croak("%s", message);
}

static void *
ub_http2_native_create(pTHX_ SV *engine)
{
    ub_http2_native_context *context;
    HV *engine_hv;
    SV **session_value;

    if (!engine || !SvROK(engine)
        || !sv_derived_from(engine, "Unblock::HTTP2::_Connection")
        || SvTYPE(SvRV(engine)) != SVt_PVHV) {
        return NULL;
    }

    engine_hv = (HV *)SvRV(engine);
    session_value = hv_fetch(engine_hv, "session", 7, 0);
    if (!session_value || !SvOK(*session_value) || !SvROK(*session_value)
        || !sv_derived_from(
            *session_value, "Unblock::HTTP2::_nghttp2::Session")) {
        return NULL;
    }

    Newxz(context, 1, ub_http2_native_context);
    if (!context) {
        return NULL;
    }

    context->engine = SvREFCNT_inc(engine);
    context->session_object = SvREFCNT_inc(*session_value);
    context->session = session_from_sv(aTHX_ context->session_object);
    return context;
}

static int
ub_http2_native_input(
    pTHX_
    void *opaque,
    const char *data,
    size_t length,
    size_t *consumed)
{
    ub_http2_native_context *context =
        (ub_http2_native_context *)opaque;
    unblock_h2_session *ps;
    ssize_t rv = 0;
    SV *error = NULL;
    int jump_status;
    int old_session_call;
    dJMPENV;

    if (!context || !context->session || !consumed) {
        croak("invalid Unblock::HTTP2 native input context");
    }
    if (!data && length) {
        croak("native input data is NULL with a nonzero length");
    }

    *consumed = 0;
    if (ub_http2_native_engine_closed(aTHX_ context)) {
        return UB_HTTP2_INPUT_CLOSED;
    }
    if (ub_http2_native_engine_in_call(aTHX_ context)) {
        croak("native input cannot be called from an HTTP/2 callback");
    }
    if (!length) {
        return UB_HTTP2_INPUT_OK;
    }

    ps = context->session;
    clear_callback_error(aTHX_ ps);
    old_session_call = ps->in_session_call;
    ub_http2_native_set_engine_in_call(aTHX_ context, 1);
    ps->in_session_call = 1;

    JMPENV_PUSH(jump_status);
    if (jump_status == 0) {
        rv = nghttp2_session_mem_recv(
            ps->session, (const uint8_t *)data, length);
        JMPENV_POP;
    }
    else {
        JMPENV_POP;
        ps->in_session_call = old_session_call;
        ub_http2_native_set_engine_in_call(aTHX_ context, 0);
        drain_pending_free(aTHX_ ps);
        JMPENV_JUMP(jump_status);
    }

    ps->in_session_call = old_session_call;
    ub_http2_native_set_engine_in_call(aTHX_ context, 0);
    drain_pending_free(aTHX_ ps);

    error = ub_http2_native_take_callback_error(aTHX_ ps);
    if (!error && rv < 0) {
        error = newSVpvf(
            "nghttp2_session_mem_recv failed (%ld): %s",
            (long)rv, nghttp2_strerror((int)rv));
    }
    if (!error && (size_t)rv != length) {
        error = newSVpv(
            "native input: nghttp2 did not consume complete input", 0);
    }
    if (error) {
        ub_http2_native_croak_error(aTHX_ context, error);
    }

    *consumed = (size_t)rv;
    return ub_http2_native_after_session(aTHX_ context)
        ? UB_HTTP2_INPUT_CLOSED
        : UB_HTTP2_INPUT_OK;
}

static int
ub_http2_native_output(
    pTHX_
    void *opaque,
    ub_http2_output_sink_v1 sink,
    void *sink_context,
    size_t *produced)
{
    ub_http2_native_context *context =
        (ub_http2_native_context *)opaque;
    unblock_h2_session *ps;
    const uint8_t *data = NULL;
    ssize_t rv = 0;
    size_t total = 0;
    SV *error = NULL;
    int sink_result = UB_HTTP2_OUTPUT_CONTINUE;
    int jump_status;
    int old_session_call;
    dJMPENV;

    if (!context || !context->session || !produced) {
        croak("invalid Unblock::HTTP2 native output context");
    }

    *produced = 0;
    if (ub_http2_native_engine_closed(aTHX_ context)) {
        return UB_HTTP2_OUTPUT_CLOSED;
    }
    if (ub_http2_native_engine_in_call(aTHX_ context)) {
        croak("native output cannot be called from an HTTP/2 callback");
    }

    ps = context->session;
    if (!nghttp2_session_want_write(ps->session)) {
        return UB_HTTP2_OUTPUT_OK;
    }
    if (!sink) {
        croak("native output requires a sink while output is pending");
    }

    clear_callback_error(aTHX_ ps);
    old_session_call = ps->in_session_call;
    ub_http2_native_set_engine_in_call(aTHX_ context, 1);
    ps->in_session_call = 1;

    JMPENV_PUSH(jump_status);
    if (jump_status == 0) {
        for (;;) {
            rv = nghttp2_session_mem_send(ps->session, &data);
            if (rv <= 0) {
                break;
            }

            sink_result = sink(
                aTHX_
                sink_context,
                (const char *)data,
                (size_t)rv
            );
            total += (size_t)rv;

            if (sink_result == UB_HTTP2_OUTPUT_PAUSE) {
                rv = 0;
                break;
            }
            if (sink_result != UB_HTTP2_OUTPUT_CONTINUE) {
                error = newSVpv(
                    "native output sink reported a fatal failure", 0);
                rv = 0;
                break;
            }
        }
        JMPENV_POP;
    }
    else {
        JMPENV_POP;
        ps->in_session_call = old_session_call;
        ub_http2_native_set_engine_in_call(aTHX_ context, 0);
        drain_pending_free(aTHX_ ps);
        JMPENV_JUMP(jump_status);
    }

    ps->in_session_call = old_session_call;
    ub_http2_native_set_engine_in_call(aTHX_ context, 0);
    drain_pending_free(aTHX_ ps);

    if (!error) {
        error = ub_http2_native_take_callback_error(aTHX_ ps);
    }
    else {
        clear_callback_error(aTHX_ ps);
    }

    if (!error && rv < 0) {
        error = newSVpvf(
            "nghttp2_session_mem_send failed (%ld): %s",
            (long)rv, nghttp2_strerror((int)rv));
    }

    *produced = total;
    if (error) {
        ub_http2_native_croak_error(aTHX_ context, error);
    }

    return ub_http2_native_after_session(aTHX_ context)
        ? UB_HTTP2_OUTPUT_CLOSED
        : UB_HTTP2_OUTPUT_OK;
}

static int
ub_http2_native_want_read(pTHX_ void *opaque)
{
    ub_http2_native_context *context =
        (ub_http2_native_context *)opaque;

    if (!context || !context->session) {
        croak("invalid Unblock::HTTP2 native transport context");
    }
    if (ub_http2_native_engine_closed(aTHX_ context)) {
        return 0;
    }

    return nghttp2_session_want_read(context->session->session) ? 1 : 0;
}

static int
ub_http2_native_want_write(pTHX_ void *opaque)
{
    ub_http2_native_context *context =
        (ub_http2_native_context *)opaque;

    if (!context || !context->session) {
        croak("invalid Unblock::HTTP2 native transport context");
    }
    if (ub_http2_native_engine_closed(aTHX_ context)) {
        return 0;
    }

    return nghttp2_session_want_write(context->session->session) ? 1 : 0;
}

static int
ub_http2_native_eof(pTHX_ void *opaque)
{
    ub_http2_native_context *context =
        (ub_http2_native_context *)opaque;
    SV *error;

    if (!context || !context->session) {
        croak("invalid Unblock::HTTP2 native transport context");
    }
    if (ub_http2_native_engine_closed(aTHX_ context)) {
        return UB_HTTP2_INPUT_CLOSED;
    }
    if (ub_http2_native_engine_in_call(aTHX_ context)) {
        croak("native EOF cannot be called from an HTTP/2 callback");
    }

    error = newSVpv("HTTP/2 transport reached EOF", 0);
    ub_http2_native_finish_close(aTHX_ context, error);
    SvREFCNT_dec(error);
    return UB_HTTP2_INPUT_CLOSED;
}

static void
ub_http2_native_destroy(pTHX_ void *opaque)
{
    ub_http2_native_context *context =
        (ub_http2_native_context *)opaque;

    PERL_UNUSED_CONTEXT;
    if (!context) {
        return;
    }

    if (context->after_session_cv) {
        SvREFCNT_dec((SV *)context->after_session_cv);
    }
    if (context->finish_close_cv) {
        SvREFCNT_dec((SV *)context->finish_close_cv);
    }
    if (context->session_object) {
        SvREFCNT_dec(context->session_object);
    }
    if (context->engine) {
        SvREFCNT_dec(context->engine);
    }
    Safefree(context);
}

static const ub_http2_native_ops_v1 ub_http2_native_ops = {
    UB_HTTP2_NATIVE_ABI_VERSION,
    sizeof(ub_http2_native_ops_v1),
    "Unblock::HTTP2 native transport",
    ub_http2_native_create,
    ub_http2_native_input,
    ub_http2_native_eof,
    ub_http2_native_destroy,
    ub_http2_native_output,
    ub_http2_native_want_read,
    ub_http2_native_want_write
};

typedef struct {
    SV *buffer;
    int pause_after_first;
    size_t chunks;
} ub_http2_test_sink_context;

static int
ub_http2_test_output_sink(
    pTHX_
    void *opaque,
    const char *data,
    size_t length)
{
    ub_http2_test_sink_context *sink =
        (ub_http2_test_sink_context *)opaque;

    if (!sink || !sink->buffer) {
        return UB_HTTP2_OUTPUT_ERROR;
    }

    sv_catpvn(sink->buffer, data, (STRLEN)length);
    sink->chunks++;
    return sink->pause_after_first && sink->chunks >= 1
        ? UB_HTTP2_OUTPUT_PAUSE
        : UB_HTTP2_OUTPUT_CONTINUE;
}

typedef struct {
    ub_http2_native_context *destination;
    size_t moved;
    int input_status;
} ub_http2_test_bridge_context;

static int
ub_http2_test_bridge_sink(
    pTHX_
    void *opaque,
    const char *data,
    size_t length)
{
    ub_http2_test_bridge_context *bridge =
        (ub_http2_test_bridge_context *)opaque;
    size_t consumed = 0;

    if (!bridge || !bridge->destination) {
        return UB_HTTP2_OUTPUT_ERROR;
    }

    bridge->input_status = ub_http2_native_input(
        aTHX_
        bridge->destination,
        data,
        length,
        &consumed
    );
    if (consumed != length) {
        return UB_HTTP2_OUTPUT_ERROR;
    }

    bridge->moved += consumed;
    return UB_HTTP2_OUTPUT_CONTINUE;
}


MODULE = Unblock::HTTP2    PACKAGE = Unblock::HTTP2::_nghttp2

PROTOTYPES: DISABLE

int
_available()
    CODE:
        RETVAL = nghttp2_version(0) ? 1 : 0;
    OUTPUT:
        RETVAL

UV
_native_transport_operations_address()
    CODE:
        RETVAL = PTR2UV(&ub_http2_native_ops);
    OUTPUT:
        RETVAL

UV
_native_transport_operations_size()
    CODE:
        RETVAL = (UV)sizeof(ub_http2_native_ops_v1);
    OUTPUT:
        RETVAL

const char *
version_string()
    CODE:
        nghttp2_info *info = nghttp2_version(0);
        RETVAL = info ? info->version_str : "unknown";
    OUTPUT:
        RETVAL

MODULE = Unblock::HTTP2    PACKAGE = Unblock::HTTP2::_nghttp2::Session

SV *
_new_client_xs(class, callbacks_hv, max_header_list_size)
        char *class
        HV *callbacks_hv
        UV max_header_list_size
    PREINIT:
        unblock_h2_session *ps;
    CODE:
        if (max_header_list_size == 0) {
            croak("max_header_list_size must be positive");
        }
        ps = new_session(
            aTHX_ callbacks_hv, 0, (size_t)max_header_list_size);
        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, class, (void *)ps);
    OUTPUT:
        RETVAL

SV *
_new_server_xs(class, callbacks_hv, max_header_list_size)
        char *class
        HV *callbacks_hv
        UV max_header_list_size
    PREINIT:
        unblock_h2_session *ps;
    CODE:
        if (max_header_list_size == 0) {
            croak("max_header_list_size must be positive");
        }
        ps = new_session(
            aTHX_ callbacks_hv, 1, (size_t)max_header_list_size);
        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, class, (void *)ps);
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self
    PREINIT:
        unblock_h2_session *ps;
        unblock_h2_provider *provider;
    CODE:
        if (!SvROK(self)) {
            XSRETURN_EMPTY;
        }
        ps = INT2PTR(unblock_h2_session *, SvIV(SvRV(self)));
        if (!ps) {
            XSRETURN_EMPTY;
        }

        if (ps->session) {
            nghttp2_session_del(ps->session);
            ps->session = NULL;
        }

        drain_pending_free(aTHX_ ps);
        provider = ps->providers;
        ps->providers = NULL;
        while (provider) {
            unblock_h2_provider *next = provider->next;
            free_provider(aTHX_ provider);
            provider = next;
        }
        free_header_blocks(aTHX_ ps);
        release_callbacks(aTHX_ ps);
        free(ps);
        sv_setiv(SvRV(self), 0);

IV
mem_recv(self, data)
        SV *self
        SV *data
    PREINIT:
        unblock_h2_session *ps;
        STRLEN len;
        const char *bytes;
        ssize_t rv;
    CODE:
        ps = session_from_sv(aTHX_ self);
        if (ps->in_session_call) {
            croak("mem_recv called from inside an HTTP/2 callback");
        }
        bytes = SvPVbyte(data, len);
        clear_callback_error(aTHX_ ps);

        ENTER;
        SAVEINT(ps->in_session_call);
        ps->in_session_call = 1;
        rv = nghttp2_session_mem_recv(
            ps->session, (const uint8_t *)bytes, (size_t)len);
        LEAVE;
        drain_pending_free(aTHX_ ps);
        croak_callback_error(aTHX_ ps);

        if (rv < 0) {
            croak("nghttp2_session_mem_recv failed (%ld): %s",
                (long)rv, nghttp2_strerror((int)rv));
        }
        RETVAL = (IV)rv;
    OUTPUT:
        RETVAL

SV *
mem_send(self)
        SV *self
    PREINIT:
        unblock_h2_session *ps;
        const uint8_t *data = NULL;
        ssize_t rv = 0;
        SV *output;
    CODE:
        ps = session_from_sv(aTHX_ self);
        if (ps->in_session_call) {
            croak("mem_send called from inside an HTTP/2 callback");
        }
        clear_callback_error(aTHX_ ps);
        output = newSVpvn("", 0);

        ENTER;
        SAVEINT(ps->in_session_call);
        ps->in_session_call = 1;
        for (;;) {
            rv = nghttp2_session_mem_send(ps->session, &data);
            if (rv <= 0) {
                break;
            }
            sv_catpvn(output, (const char *)data, (STRLEN)rv);
        }
        LEAVE;
        drain_pending_free(aTHX_ ps);

        if (ps->callback_error) {
            SvREFCNT_dec(output);
            croak_callback_error(aTHX_ ps);
        }

        if (rv < 0) {
            SvREFCNT_dec(output);
            croak("nghttp2_session_mem_send failed (%ld): %s",
                (long)rv, nghttp2_strerror((int)rv));
        }
        RETVAL = output;
    OUTPUT:
        RETVAL

int
want_read(self)
        SV *self
    PREINIT:
        unblock_h2_session *ps;
    CODE:
        ps = session_from_sv(aTHX_ self);
        RETVAL = nghttp2_session_want_read(ps->session);
    OUTPUT:
        RETVAL

int
want_write(self)
        SV *self
    PREINIT:
        unblock_h2_session *ps;
    CODE:
        ps = session_from_sv(aTHX_ self);
        RETVAL = nghttp2_session_want_write(ps->session);
    OUTPUT:
        RETVAL

int
submit_settings(self, settings_hv)
        SV *self
        HV *settings_hv
    PREINIT:
        unblock_h2_session *ps;
        nghttp2_settings_entry entries[9];
        size_t count = 0;
        SV **value;
        int rv;
    CODE:
        ps = session_from_sv(aTHX_ self);

        if ((value = hv_fetch(settings_hv, "header_table_size", 17, 0))) {
            entries[count].settings_id = NGHTTP2_SETTINGS_HEADER_TABLE_SIZE;
            entries[count++].value = (uint32_t)SvUV(*value);
        }
        if ((value = hv_fetch(settings_hv, "enable_push", 11, 0))) {
            entries[count].settings_id = NGHTTP2_SETTINGS_ENABLE_PUSH;
            entries[count++].value = SvTRUE(*value) ? 1 : 0;
        }
        if ((value = hv_fetch(settings_hv, "max_concurrent_streams", 22, 0))) {
            entries[count].settings_id = NGHTTP2_SETTINGS_MAX_CONCURRENT_STREAMS;
            entries[count++].value = (uint32_t)SvUV(*value);
        }
        if ((value = hv_fetch(settings_hv, "initial_window_size", 19, 0))) {
            entries[count].settings_id = NGHTTP2_SETTINGS_INITIAL_WINDOW_SIZE;
            entries[count++].value = (uint32_t)SvUV(*value);
        }
        if ((value = hv_fetch(settings_hv, "max_frame_size", 14, 0))) {
            entries[count].settings_id = NGHTTP2_SETTINGS_MAX_FRAME_SIZE;
            entries[count++].value = (uint32_t)SvUV(*value);
        }
        if ((value = hv_fetch(settings_hv, "max_header_list_size", 20, 0))) {
            entries[count].settings_id = NGHTTP2_SETTINGS_MAX_HEADER_LIST_SIZE;
            entries[count++].value = (uint32_t)SvUV(*value);
        }
        if ((value = hv_fetch(settings_hv, "enable_connect_protocol", 23, 0))) {
            entries[count].settings_id = NGHTTP2_SETTINGS_ENABLE_CONNECT_PROTOCOL;
            entries[count++].value = SvTRUE(*value) ? 1 : 0;
        }
        if ((value = hv_fetch(settings_hv, "no_rfc7540_priorities", 21, 0))) {
            entries[count].settings_id = NGHTTP2_SETTINGS_NO_RFC7540_PRIORITIES;
            entries[count++].value = SvTRUE(*value) ? 1 : 0;
        }

        rv = nghttp2_submit_settings(
            ps->session, NGHTTP2_FLAG_NONE, entries, count);
        if (rv != 0) {
            croak("nghttp2_submit_settings failed (%d): %s",
                rv, nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL

UV
remote_setting(self, setting_id)
        SV *self
        int setting_id
    PREINIT:
        unblock_h2_session *ps;
    CODE:
        ps = session_from_sv(aTHX_ self);
        RETVAL = (UV)nghttp2_session_get_remote_settings(
            ps->session, (nghttp2_settings_id)setting_id);
    OUTPUT:
        RETVAL

int
consume_stream(self, stream_id, size)
        SV *self
        int stream_id
        UV size
    PREINIT:
        unblock_h2_session *ps;
        int rv;
    CODE:
        ps = session_from_sv(aTHX_ self);
        rv = nghttp2_session_consume_stream(
            ps->session, stream_id, (size_t)size);
        if (rv != 0) {
            croak("nghttp2_session_consume_stream failed (%d): %s",
                rv, nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL

int
get_stream_remote_close(self, stream_id)
        SV *self
        int stream_id
    PREINIT:
        unblock_h2_session *ps;
        int rv;
    CODE:
        ps = session_from_sv(aTHX_ self);
        rv = nghttp2_session_get_stream_remote_close(ps->session, stream_id);
        RETVAL = rv;
    OUTPUT:
        RETVAL

int
get_stream_local_close(self, stream_id)
        SV *self
        int stream_id
    PREINIT:
        unblock_h2_session *ps;
        int rv;
    CODE:
        ps = session_from_sv(aTHX_ self);
        rv = nghttp2_session_get_stream_local_close(ps->session, stream_id);
        RETVAL = rv;
    OUTPUT:
        RETVAL

int
_submit_request_uniform_native(self, message, provider_sv)
        SV *self
        SV *message
        SV *provider_sv
    PREINIT:
        unblock_h2_session *ps;
        nghttp2_nv *nva;
        size_t nvlen;
        nghttp2_data_provider data_provider;
        nghttp2_data_provider *data_provider_ptr = NULL;
        unblock_h2_provider *provider = NULL;
        int32_t stream_id;
    CODE:
        ps = session_from_sv(aTHX_ self);
        nva = uniform_request_to_nva(aTHX_ ps, message, &nvlen);

        if (SvOK(provider_sv)) {
            if (!SvROK(provider_sv) || SvTYPE(SvRV(provider_sv)) != SVt_PVCV) {
                if (nva) free(nva);
                croak("request data provider must be a coderef");
            }
            provider = (unblock_h2_provider *)calloc(1, sizeof(*provider));
            if (!provider) {
                if (nva) free(nva);
                croak("unable to allocate HTTP/2 data provider");
            }
            provider->callback = newSVsv(provider_sv);
            data_provider.source.ptr = provider;
            data_provider.read_callback = provider_read_callback;
            data_provider_ptr = &data_provider;
        }

        stream_id = nghttp2_submit_request(
            ps->session, NULL, nva, nvlen, data_provider_ptr, NULL);
        if (nva) free(nva);

        if (stream_id < 0) {
            if (provider) free_provider(aTHX_ provider);
            croak("nghttp2_submit_request failed (%d): %s",
                (int)stream_id, nghttp2_strerror((int)stream_id));
        }

        if (provider) {
            provider->stream_id = stream_id;
            add_provider(aTHX_ ps, provider);
        }
        RETVAL = stream_id;
    OUTPUT:
        RETVAL

int
_submit_request_native(self, headers_av, provider_sv)
        SV *self
        AV *headers_av
        SV *provider_sv
    PREINIT:
        unblock_h2_session *ps;
        nghttp2_nv *nva;
        size_t nvlen;
        nghttp2_data_provider data_provider;
        nghttp2_data_provider *data_provider_ptr = NULL;
        unblock_h2_provider *provider = NULL;
        int32_t stream_id;
    CODE:
        ps = session_from_sv(aTHX_ self);
        nva = headers_to_nva(aTHX_ headers_av, &nvlen);

        if (SvOK(provider_sv)) {
            if (!SvROK(provider_sv) || SvTYPE(SvRV(provider_sv)) != SVt_PVCV) {
                if (nva) free(nva);
                croak("request data provider must be a coderef");
            }
            provider = (unblock_h2_provider *)calloc(1, sizeof(*provider));
            if (!provider) {
                if (nva) free(nva);
                croak("unable to allocate HTTP/2 data provider");
            }
            provider->callback = newSVsv(provider_sv);
            data_provider.source.ptr = provider;
            data_provider.read_callback = provider_read_callback;
            data_provider_ptr = &data_provider;
        }

        stream_id = nghttp2_submit_request(
            ps->session, NULL, nva, nvlen, data_provider_ptr, NULL);
        if (nva) free(nva);

        if (stream_id < 0) {
            if (provider) free_provider(aTHX_ provider);
            croak("nghttp2_submit_request failed (%d): %s",
                (int)stream_id, nghttp2_strerror((int)stream_id));
        }

        if (provider) {
            provider->stream_id = stream_id;
            add_provider(aTHX_ ps, provider);
        }
        RETVAL = stream_id;
    OUTPUT:
        RETVAL

int
_submit_response_uniform_no_body_native(self, stream_id, message)
        SV *self
        int stream_id
        SV *message
    PREINIT:
        unblock_h2_session *ps;
        nghttp2_nv *nva;
        size_t nvlen;
        int rv;
    CODE:
        ps = session_from_sv(aTHX_ self);
        nva = uniform_response_to_nva(aTHX_ ps, message, &nvlen);
        rv = nghttp2_submit_response(ps->session, stream_id, nva, nvlen, NULL);
        if (nva) free(nva);
        if (rv != 0) {
            croak("nghttp2_submit_response failed (%d): %s",
                rv, nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL

int
_submit_response_uniform_streaming_native(self, stream_id, message, provider_sv)
        SV *self
        int stream_id
        SV *message
        SV *provider_sv
    PREINIT:
        unblock_h2_session *ps;
        nghttp2_nv *nva;
        size_t nvlen;
        nghttp2_data_provider data_provider;
        unblock_h2_provider *provider;
        int rv;
    CODE:
        ps = session_from_sv(aTHX_ self);
        if (find_provider(ps, stream_id)) {
            croak("stream %d already has a data provider", stream_id);
        }
        if (!SvROK(provider_sv) || SvTYPE(SvRV(provider_sv)) != SVt_PVCV) {
            croak("response data provider must be a coderef");
        }

        nva = uniform_response_to_nva(aTHX_ ps, message, &nvlen);
        provider = (unblock_h2_provider *)calloc(1, sizeof(*provider));
        if (!provider) {
            if (nva) free(nva);
            croak("unable to allocate HTTP/2 data provider");
        }
        provider->stream_id = stream_id;
        provider->callback = newSVsv(provider_sv);
        data_provider.source.ptr = provider;
        data_provider.read_callback = provider_read_callback;

        rv = nghttp2_submit_response(
            ps->session, stream_id, nva, nvlen, &data_provider);
        if (nva) free(nva);
        if (rv != 0) {
            free_provider(aTHX_ provider);
            croak("nghttp2_submit_response failed (%d): %s",
                rv, nghttp2_strerror(rv));
        }

        add_provider(aTHX_ ps, provider);
        RETVAL = rv;
    OUTPUT:
        RETVAL

int
_submit_response_no_body_native(self, stream_id, headers_av)
        SV *self
        int stream_id
        AV *headers_av
    PREINIT:
        unblock_h2_session *ps;
        nghttp2_nv *nva;
        size_t nvlen;
        int rv;
    CODE:
        ps = session_from_sv(aTHX_ self);
        nva = headers_to_nva(aTHX_ headers_av, &nvlen);
        rv = nghttp2_submit_response(ps->session, stream_id, nva, nvlen, NULL);
        if (nva) free(nva);
        if (rv != 0) {
            croak("nghttp2_submit_response failed (%d): %s",
                rv, nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL

int
_submit_response_streaming_native(self, stream_id, headers_av, provider_sv)
        SV *self
        int stream_id
        AV *headers_av
        SV *provider_sv
    PREINIT:
        unblock_h2_session *ps;
        nghttp2_nv *nva;
        size_t nvlen;
        nghttp2_data_provider data_provider;
        unblock_h2_provider *provider;
        int rv;
    CODE:
        ps = session_from_sv(aTHX_ self);
        if (find_provider(ps, stream_id)) {
            croak("stream %d already has a data provider", stream_id);
        }
        if (!SvROK(provider_sv) || SvTYPE(SvRV(provider_sv)) != SVt_PVCV) {
            croak("response data provider must be a coderef");
        }

        nva = headers_to_nva(aTHX_ headers_av, &nvlen);
        provider = (unblock_h2_provider *)calloc(1, sizeof(*provider));
        if (!provider) {
            if (nva) free(nva);
            croak("unable to allocate HTTP/2 data provider");
        }
        provider->stream_id = stream_id;
        provider->callback = newSVsv(provider_sv);
        data_provider.source.ptr = provider;
        data_provider.read_callback = provider_read_callback;

        rv = nghttp2_submit_response(
            ps->session, stream_id, nva, nvlen, &data_provider);
        if (nva) free(nva);
        if (rv != 0) {
            free_provider(aTHX_ provider);
            croak("nghttp2_submit_response failed (%d): %s",
                rv, nghttp2_strerror(rv));
        }

        add_provider(aTHX_ ps, provider);
        RETVAL = rv;
    OUTPUT:
        RETVAL

int
_submit_response_headers_uniform_native(self, stream_id, message, end_stream)
        SV *self
        int stream_id
        SV *message
        int end_stream
    PREINIT:
        unblock_h2_session *ps;
        nghttp2_nv *nva;
        size_t nvlen;
        int32_t rv;
        uint8_t flags;
    CODE:
        ps = session_from_sv(aTHX_ self);
        nva = uniform_response_to_nva(aTHX_ ps, message, &nvlen);
        flags = end_stream ? NGHTTP2_FLAG_END_STREAM : NGHTTP2_FLAG_NONE;
        rv = nghttp2_submit_headers(
            ps->session, flags, stream_id, NULL, nva, nvlen, NULL);
        if (nva) free(nva);
        if (rv < 0) {
            croak("nghttp2_submit_headers failed (%d): %s",
                (int)rv, nghttp2_strerror((int)rv));
        }
        RETVAL = (int)rv;
    OUTPUT:
        RETVAL

int
_submit_headers_native(self, stream_id, headers_av, end_stream)
        SV *self
        int stream_id
        AV *headers_av
        int end_stream
    PREINIT:
        unblock_h2_session *ps;
        nghttp2_nv *nva;
        size_t nvlen;
        int32_t rv;
        uint8_t flags;
    CODE:
        ps = session_from_sv(aTHX_ self);
        nva = headers_to_nva(aTHX_ headers_av, &nvlen);
        flags = end_stream ? NGHTTP2_FLAG_END_STREAM : NGHTTP2_FLAG_NONE;
        rv = nghttp2_submit_headers(
            ps->session, flags, stream_id, NULL, nva, nvlen, NULL);
        if (nva) free(nva);
        if (rv < 0) {
            croak("nghttp2_submit_headers failed (%d): %s",
                (int)rv, nghttp2_strerror((int)rv));
        }
        RETVAL = (int)rv;
    OUTPUT:
        RETVAL

int
_submit_trailer_native(self, stream_id, headers_av)
        SV *self
        int stream_id
        AV *headers_av
    PREINIT:
        unblock_h2_session *ps;
        nghttp2_nv *nva;
        size_t nvlen;
        int rv;
    CODE:
        ps = session_from_sv(aTHX_ self);
        nva = headers_to_nva(aTHX_ headers_av, &nvlen);
        rv = nghttp2_submit_trailer(ps->session, stream_id, nva, nvlen);
        if (nva) free(nva);
        if (rv != 0) {
            croak("nghttp2_submit_trailer failed (%d): %s",
                rv, nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL

int
submit_rst_stream(self, stream_id, error_code)
        SV *self
        int stream_id
        unsigned int error_code
    PREINIT:
        unblock_h2_session *ps;
        int rv;
    CODE:
        ps = session_from_sv(aTHX_ self);
        rv = nghttp2_submit_rst_stream(
            ps->session, NGHTTP2_FLAG_NONE, stream_id, error_code);
        if (rv != 0) {
            croak("nghttp2_submit_rst_stream failed (%d): %s",
                rv, nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL

int
_submit_priority_update_native(self, stream_id, field_value)
        SV *self
        int stream_id
        SV *field_value
    PREINIT:
        unblock_h2_session *ps;
        STRLEN len = 0;
        const uint8_t *value;
        int rv;
    CODE:
        ps = session_from_sv(aTHX_ self);
        value = (const uint8_t *)SvPVbyte(field_value, len);
        if (len > 16380) {
            croak("PRIORITY_UPDATE field value exceeds 16380 bytes");
        }
        rv = nghttp2_submit_priority_update(
            ps->session, NGHTTP2_FLAG_NONE, stream_id, value, (size_t)len);
        if (rv != 0) {
            croak("nghttp2_submit_priority_update failed (%d): %s",
                rv, nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL

int
_submit_ping_native(self, opaque_data)
        SV *self
        SV *opaque_data
    PREINIT:
        unblock_h2_session *ps;
        STRLEN len = 0;
        const uint8_t *data;
        int rv;
    CODE:
        ps = session_from_sv(aTHX_ self);
        data = (const uint8_t *)SvPVbyte(opaque_data, len);
        if (len != 8) {
            croak("PING opaque data must be exactly 8 bytes");
        }
        rv = nghttp2_submit_ping(
            ps->session, NGHTTP2_FLAG_NONE, data);
        if (rv != 0) {
            croak("nghttp2_submit_ping failed (%d): %s",
                rv, nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL

int
_submit_goaway_native(self, last_stream_id, error_code, debug_data)
        SV *self
        int last_stream_id
        unsigned int error_code
        SV *debug_data
    PREINIT:
        unblock_h2_session *ps;
        STRLEN len = 0;
        const uint8_t *data = NULL;
        int rv;
    CODE:
        ps = session_from_sv(aTHX_ self);
        if (SvOK(debug_data)) {
            data = (const uint8_t *)SvPVbyte(debug_data, len);
        }
        rv = nghttp2_submit_goaway(
            ps->session, NGHTTP2_FLAG_NONE, last_stream_id,
            error_code, data, (size_t)len);
        if (rv != 0) {
            croak("nghttp2_submit_goaway failed (%d): %s",
                rv, nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL

int
resume_data(self, stream_id)
        SV *self
        int stream_id
    PREINIT:
        unblock_h2_session *ps;
        int rv;
    CODE:
        ps = session_from_sv(aTHX_ self);
        rv = nghttp2_session_resume_data(ps->session, stream_id);
        if (rv != 0 && rv != NGHTTP2_ERR_INVALID_ARGUMENT) {
            croak("nghttp2_session_resume_data failed (%d): %s",
                rv, nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL

int
is_stream_deferred(self, stream_id)
        SV *self
        int stream_id
    PREINIT:
        unblock_h2_session *ps;
        unblock_h2_provider *provider;
    CODE:
        ps = session_from_sv(aTHX_ self);
        provider = find_provider(ps, stream_id);
        RETVAL = provider ? provider->deferred : 0;
    OUTPUT:
        RETVAL

void
_clear_deferred(self, stream_id)
        SV *self
        int stream_id
    PREINIT:
        unblock_h2_session *ps;
        unblock_h2_provider *provider;
    CODE:
        ps = session_from_sv(aTHX_ self);
        provider = find_provider(ps, stream_id);
        if (provider) {
            provider->deferred = 0;
        }


MODULE = Unblock::HTTP2    PACKAGE = Unblock::HTTP2::_nghttp2::NativeDriver

SV *
new(CLASS, engine)
        const char *CLASS
        SV *engine
    PREINIT:
        ub_http2_native_context *context;
        SV *inner;
        SV *object;
    CODE:
        context = (ub_http2_native_context *)
            ub_http2_native_create(aTHX_ engine);
        if (!context) {
            croak("engine does not support Unblock::HTTP2 native transport");
        }
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
        ub_http2_native_context *context;
        STRLEN buffer_len;
        const char *data;
        size_t consumed = 0;
        int status;
    PPCODE:
        if (!SvROK(self)
            || !sv_derived_from(
                self, "Unblock::HTTP2::_nghttp2::NativeDriver")) {
            croak("not an Unblock::HTTP2 native transport driver");
        }
        inner = SvRV(self);
        context = INT2PTR(
            ub_http2_native_context *, SvIV(inner));
        if (!context) {
            croak("native transport driver has already been released");
        }

        data = SvPVbyte(buffer, buffer_len);
        status = ub_http2_native_input(
            aTHX_
            context,
            data,
            (size_t)buffer_len,
            &consumed
        );

        XPUSHs(sv_2mortal(newSViv(status)));
        XPUSHs(sv_2mortal(newSVuv((UV)consumed)));

void
drain(self, pause_after_first = 0)
        SV *self
        int pause_after_first
    PREINIT:
        SV *inner;
        ub_http2_native_context *context;
        SV *output;
        ub_http2_test_sink_context sink;
        size_t produced = 0;
        int status;
    PPCODE:
        if (!SvROK(self)
            || !sv_derived_from(
                self, "Unblock::HTTP2::_nghttp2::NativeDriver")) {
            croak("not an Unblock::HTTP2 native transport driver");
        }
        inner = SvRV(self);
        context = INT2PTR(
            ub_http2_native_context *, SvIV(inner));
        if (!context) {
            croak("native transport driver has already been released");
        }

        output = newSVpvn("", 0);
        sink.buffer = output;
        sink.pause_after_first = pause_after_first ? 1 : 0;
        sink.chunks = 0;

        status = ub_http2_native_output(
            aTHX_
            context,
            ub_http2_test_output_sink,
            &sink,
            &produced
        );

        XPUSHs(sv_2mortal(newSViv(status)));
        XPUSHs(sv_2mortal(output));
        XPUSHs(sv_2mortal(newSVuv((UV)produced)));

void
transfer_to(self, destination)
        SV *self
        SV *destination
    PREINIT:
        SV *inner;
        SV *destination_inner;
        ub_http2_native_context *context;
        ub_http2_native_context *destination_context;
        ub_http2_test_bridge_context bridge;
        size_t produced = 0;
        int output_status;
    PPCODE:
        if (!SvROK(self)
            || !sv_derived_from(
                self, "Unblock::HTTP2::_nghttp2::NativeDriver")
            || !SvROK(destination)
            || !sv_derived_from(
                destination, "Unblock::HTTP2::_nghttp2::NativeDriver")) {
            croak("transfer_to requires two HTTP/2 native transport drivers");
        }

        inner = SvRV(self);
        destination_inner = SvRV(destination);
        context = INT2PTR(
            ub_http2_native_context *, SvIV(inner));
        destination_context = INT2PTR(
            ub_http2_native_context *, SvIV(destination_inner));
        if (!context || !destination_context) {
            croak("native transport driver has already been released");
        }

        bridge.destination = destination_context;
        bridge.moved = 0;
        bridge.input_status = UB_HTTP2_INPUT_OK;

        output_status = ub_http2_native_output(
            aTHX_
            context,
            ub_http2_test_bridge_sink,
            &bridge,
            &produced
        );
        if (produced != bridge.moved) {
            croak("native transport bridge byte count mismatch");
        }

        XPUSHs(sv_2mortal(newSViv(output_status)));
        XPUSHs(sv_2mortal(newSViv(bridge.input_status)));
        XPUSHs(sv_2mortal(newSVuv((UV)bridge.moved)));

int
want_read(self)
        SV *self
    PREINIT:
        SV *inner;
        ub_http2_native_context *context;
    CODE:
        if (!SvROK(self)
            || !sv_derived_from(
                self, "Unblock::HTTP2::_nghttp2::NativeDriver")) {
            croak("not an Unblock::HTTP2 native transport driver");
        }
        inner = SvRV(self);
        context = INT2PTR(
            ub_http2_native_context *, SvIV(inner));
        if (!context) {
            croak("native transport driver has already been released");
        }
        RETVAL = ub_http2_native_want_read(aTHX_ context);
    OUTPUT:
        RETVAL

int
want_write(self)
        SV *self
    PREINIT:
        SV *inner;
        ub_http2_native_context *context;
    CODE:
        if (!SvROK(self)
            || !sv_derived_from(
                self, "Unblock::HTTP2::_nghttp2::NativeDriver")) {
            croak("not an Unblock::HTTP2 native transport driver");
        }
        inner = SvRV(self);
        context = INT2PTR(
            ub_http2_native_context *, SvIV(inner));
        if (!context) {
            croak("native transport driver has already been released");
        }
        RETVAL = ub_http2_native_want_write(aTHX_ context);
    OUTPUT:
        RETVAL

int
eof(self)
        SV *self
    PREINIT:
        SV *inner;
        ub_http2_native_context *context;
    CODE:
        if (!SvROK(self)
            || !sv_derived_from(
                self, "Unblock::HTTP2::_nghttp2::NativeDriver")) {
            croak("not an Unblock::HTTP2 native transport driver");
        }
        inner = SvRV(self);
        context = INT2PTR(
            ub_http2_native_context *, SvIV(inner));
        if (!context) {
            croak("native transport driver has already been released");
        }
        RETVAL = ub_http2_native_eof(aTHX_ context);
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self
    PREINIT:
        SV *inner;
        ub_http2_native_context *context;
    CODE:
        if (!SvROK(self)) {
            XSRETURN_EMPTY;
        }
        inner = SvRV(self);
        context = INT2PTR(
            ub_http2_native_context *, SvIV(inner));
        if (!context) {
            XSRETURN_EMPTY;
        }
        ub_http2_native_destroy(aTHX_ context);
        sv_setiv(inner, 0);
