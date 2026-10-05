#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "uniform_http_fastpath.h"
#include "lib/Unblock/HTTP3/NativeABI/unblock_http3_consumer.h"

#include <nghttp3/nghttp3.h>

#include <inttypes.h>
#include <string.h>

#define UNBLOCK_HTTP3_MAX_VARINT UINT64_C(0x3fffffffffffffff)

typedef struct {
    uhttp_native_api uniform_api;
} my_cxt_t;

START_MY_CXT

typedef struct unblock_http3_body_chunk {
    SV *storage;
    uint8_t *data;
    size_t len;
    size_t acked;
    int supplied;
    struct unblock_http3_body_chunk *next;
} unblock_http3_body_chunk;

typedef struct unblock_http3_body {
    int64_t stream_id;
    int streaming;
    int eof;
    uint64_t discarded_unacked;
    unblock_http3_body_chunk *head;
    unblock_http3_body_chunk *tail;
    struct unblock_http3_body *next;
} unblock_http3_body;

typedef struct {
    uint8_t *name;
    size_t namelen;
    uint8_t *value;
    size_t valuelen;
} unblock_http3_captured_field;

typedef struct unblock_http3_header_block {
    int64_t stream_id;
    unblock_http3_captured_field *fields;
    size_t count;
    size_t capacity;
    size_t field_section_size;
    struct unblock_http3_header_block *next;
} unblock_http3_header_block;

typedef struct {
    nghttp3_conn *conn;
    AV *events;
    uint8_t *origin_list_data;
    nghttp3_vec origin_list;
    unblock_http3_body *bodies;
    unblock_http3_header_block *header_blocks;
    size_t streaming_retained_bytes;
    int is_server;
    int fatal;
} unblock_http3_native_conn;


static void
unblock_http3_header_block_free(unblock_http3_header_block *block)
{
    size_t i;

    if (block == NULL) {
        return;
    }

    if (block->fields != NULL) {
        for (i = 0; i < block->count; ++i) {
            if (block->fields[i].name != NULL) {
                Safefree(block->fields[i].name);
            }
            if (block->fields[i].value != NULL) {
                Safefree(block->fields[i].value);
            }
        }

        Safefree(block->fields);
    }

    Safefree(block);
}

static unblock_http3_header_block *
unblock_http3_header_block_find(
    unblock_http3_native_conn *native,
    int64_t stream_id
)
{
    unblock_http3_header_block *block;

    for (
        block = native->header_blocks;
        block != NULL;
        block = block->next
    ) {
        if (block->stream_id == stream_id) {
            return block;
        }
    }

    return NULL;
}

static unblock_http3_header_block *
unblock_http3_header_block_create(
    unblock_http3_native_conn *native,
    int64_t stream_id
)
{
    unblock_http3_header_block *block;

    if (unblock_http3_header_block_find(native, stream_id) != NULL) {
        croak("HTTP/3 stream already has an active header block");
    }

    Newxz(block, 1, unblock_http3_header_block);
    block->stream_id = stream_id;
    block->next = native->header_blocks;
    native->header_blocks = block;

    return block;
}

static void
unblock_http3_header_block_append(
    unblock_http3_header_block *block,
    const uint8_t *name,
    size_t namelen,
    const uint8_t *value,
    size_t valuelen
)
{
    unblock_http3_captured_field *field;
    size_t next_size;

    if (block == NULL) {
        croak("HTTP/3 header arrived without an active header block");
    }

    if (block->count == block->capacity) {
        size_t capacity = block->capacity == 0
            ? 8
            : block->capacity * 2;

        if (capacity < block->capacity) {
            croak("HTTP/3 header block capacity overflow");
        }

        if (block->fields == NULL) {
            Newxz(
                block->fields,
                capacity,
                unblock_http3_captured_field
            );
        } else {
            size_t old_capacity = block->capacity;

            Renew(
                block->fields,
                capacity,
                unblock_http3_captured_field
            );
            Zero(
                block->fields + old_capacity,
                capacity - old_capacity,
                unblock_http3_captured_field
            );
        }

        block->capacity = capacity;
    }

    field = &block->fields[block->count];

    Newx(field->name, namelen ? namelen : 1, uint8_t);
    Newx(field->value, valuelen ? valuelen : 1, uint8_t);

    if (namelen) {
        Copy(name, field->name, namelen, uint8_t);
    }

    if (valuelen) {
        Copy(value, field->value, valuelen, uint8_t);
    }

    field->namelen = namelen;
    field->valuelen = valuelen;
    ++block->count;

    if (
        block->field_section_size > (size_t)-1 - namelen
        || block->field_section_size + namelen > (size_t)-1 - valuelen
        || block->field_section_size + namelen + valuelen > (size_t)-1 - 32
    ) {
        croak("HTTP/3 field section size overflow");
    }

    next_size =
        block->field_section_size
        + namelen
        + valuelen
        + 32;
    block->field_section_size = next_size;
}

static unblock_http3_header_block *
unblock_http3_header_block_remove(
    unblock_http3_native_conn *native,
    int64_t stream_id
)
{
    unblock_http3_header_block **link = &native->header_blocks;

    while (*link != NULL) {
        unblock_http3_header_block *block = *link;

        if (block->stream_id != stream_id) {
            link = &block->next;
            continue;
        }

        *link = block->next;
        block->next = NULL;
        return block;
    }

    return NULL;
}

static void
unblock_http3_header_block_free_all(
    unblock_http3_native_conn *native
)
{
    unblock_http3_header_block *block = native->header_blocks;

    while (block != NULL) {
        unblock_http3_header_block *next = block->next;
        unblock_http3_header_block_free(block);
        block = next;
    }

    native->header_blocks = NULL;
}

static int
unblock_http3_captured_name_equal(
    const unblock_http3_captured_field *field,
    const char *name,
    size_t namelen
)
{
    return field->namelen == namelen
        && memcmp(field->name, name, namelen) == 0;
}

static int
unblock_http3_captured_name_equal_ci(
    const unblock_http3_captured_field *field,
    const char *name,
    size_t namelen
)
{
    size_t i;

    if (field->namelen != namelen) {
        return 0;
    }

    for (i = 0; i < namelen; ++i) {
        uint8_t left = field->name[i];
        uint8_t right = (uint8_t)name[i];

        if (left >= 'A' && left <= 'Z') {
            left = (uint8_t)(left + ('a' - 'A'));
        }

        if (right >= 'A' && right <= 'Z') {
            right = (uint8_t)(right + ('a' - 'A'));
        }

        if (left != right) {
            return 0;
        }
    }

    return 1;
}

static const unblock_http3_captured_field *
unblock_http3_header_block_pseudo(
    const unblock_http3_header_block *block,
    const char *name,
    size_t namelen
)
{
    const unblock_http3_captured_field *found = NULL;
    size_t i;

    for (i = 0; i < block->count; ++i) {
        if (
            unblock_http3_captured_name_equal(
                &block->fields[i],
                name,
                namelen
            )
        ) {
            found = &block->fields[i];
        }
    }

    return found;
}

static size_t
unblock_http3_header_block_regular_count(
    const unblock_http3_header_block *block
)
{
    size_t i;
    size_t count = 0;

    for (i = 0; i < block->count; ++i) {
        if (
            block->fields[i].namelen == 0
            || block->fields[i].name[0] != ':'
        ) {
            ++count;
        }
    }

    return count;
}

static void
unblock_http3_header_block_uniform_fields(
    pTHX_ const unblock_http3_header_block *block,
    uhttp_native_field **pfields,
    Size_t *pcount,
    uint8_t **pcookie
)
{
    size_t regular_count =
        unblock_http3_header_block_regular_count(block);
    size_t cookie_count = 0;
    size_t cookie_length = 0;
    size_t first_cookie = (size_t)-1;
    size_t i;
    size_t out_index = 0;
    uhttp_native_field *fields = NULL;
    uint8_t *cookie = NULL;

    for (i = 0; i < block->count; ++i) {
        const unblock_http3_captured_field *field =
            &block->fields[i];

        if (
            field->namelen != 0
            && field->name[0] == ':'
        ) {
            continue;
        }

        if (
            unblock_http3_captured_name_equal_ci(
                field,
                "cookie",
                6
            )
        ) {
            if (first_cookie == (size_t)-1) {
                first_cookie = i;
            }

            if (
                cookie_length > (size_t)-1 - field->valuelen
                || (
                    cookie_count != 0
                    && cookie_length + field->valuelen
                        > (size_t)-1 - 2
                )
            ) {
                croak("HTTP/3 Cookie field coalescing overflow");
            }

            cookie_length += field->valuelen;
            if (cookie_count != 0) {
                cookie_length += 2;
            }
            ++cookie_count;
        }
    }

    if (cookie_count > 1) {
        regular_count -= cookie_count - 1;
        Newx(cookie, cookie_length ? cookie_length : 1, uint8_t);
    }

    if (regular_count != 0) {
        Newxz(fields, regular_count, uhttp_native_field);
    }

    if (cookie_count > 1) {
        size_t cookie_offset = 0;

        for (i = 0; i < block->count; ++i) {
            const unblock_http3_captured_field *field =
                &block->fields[i];

            if (
                !unblock_http3_captured_name_equal_ci(
                    field,
                    "cookie",
                    6
                )
            ) {
                continue;
            }

            if (cookie_offset != 0) {
                cookie[cookie_offset++] = ';';
                cookie[cookie_offset++] = ' ';
            }

            if (field->valuelen) {
                Copy(
                    field->value,
                    cookie + cookie_offset,
                    field->valuelen,
                    uint8_t
                );
                cookie_offset += field->valuelen;
            }
        }
    }

    for (i = 0; i < block->count; ++i) {
        const unblock_http3_captured_field *field =
            &block->fields[i];

        if (
            field->namelen != 0
            && field->name[0] == ':'
        ) {
            continue;
        }

        if (
            cookie_count > 1
            && unblock_http3_captured_name_equal_ci(
                field,
                "cookie",
                6
            )
        ) {
            if (i != first_cookie) {
                continue;
            }

            fields[out_index].name.data = "cookie";
            fields[out_index].name.len = 6;
            fields[out_index].value.data =
                (const char *)cookie;
            fields[out_index].value.len =
                (STRLEN)cookie_length;
            ++out_index;
            continue;
        }

        fields[out_index].name.data =
            (const char *)field->name;
        fields[out_index].name.len =
            (STRLEN)field->namelen;
        fields[out_index].value.data =
            (const char *)field->value;
        fields[out_index].value.len =
            (STRLEN)field->valuelen;
        ++out_index;
    }

    *pfields = fields;
    *pcount = (Size_t)regular_count;
    *pcookie = cookie;
}

static uhttp_native_bytes
unblock_http3_uniform_bytes_from_sv(SV *value)
{
    uhttp_native_bytes bytes;
    STRLEN len;
    const char *data;

    if (value == NULL || !SvOK(value)) {
        bytes.data = NULL;
        bytes.len = 0;
        return bytes;
    }

    data = SvPVbyte(value, len);
    bytes.data = data;
    bytes.len = len;
    return bytes;
}

static U32
unblock_http3_received_uniform_flags(
    U32 kind,
    int fin
)
{
    U32 flags =
        UHTTP_HEADERS_LOSSLESS
        | UHTTP_TRAILERS_LOSSLESS;

    if (kind == UHTTP_KIND_REQUEST) {
        flags |= UHTTP_TARGET_EXACT;
    }

    if (fin) {
        flags |= UHTTP_COMPLETE;
    } else {
        flags |=
            UHTTP_MUTABLE
            | UHTTP_BODY_MUTABLE
            | UHTTP_TRAILERS_MUTABLE;
    }

    return flags;
}


static SV *
unblock_http3_header_block_uniform_request(
    pTHX_ unblock_http3_header_block *block,
    SV *method,
    SV *target,
    SV *scheme,
    SV *authority,
    SV *protocol,
    int fin
)
{
    dMY_CXT;
    uhttp_native_input input;
    uhttp_native_field *fields = NULL;
    Size_t field_count = 0;
    uint8_t *cookie = NULL;
    SV *object;

    unblock_http3_header_block_uniform_fields(
        aTHX_ block,
        &fields,
        &field_count,
        &cookie
    );

    uhttp_native_input_init(
        &input,
        UHTTP_KIND_REQUEST
    );
    input.flags = unblock_http3_received_uniform_flags(
        UHTTP_KIND_REQUEST,
        fin
    );
    input.version.data = "3";
    input.version.len = 1;
    input.method =
        unblock_http3_uniform_bytes_from_sv(method);
    input.target =
        unblock_http3_uniform_bytes_from_sv(target);
    input.scheme =
        unblock_http3_uniform_bytes_from_sv(scheme);
    input.authority =
        unblock_http3_uniform_bytes_from_sv(authority);
    input.protocol =
        unblock_http3_uniform_bytes_from_sv(protocol);
    input.headers = fields;
    input.header_count = field_count;

    object = uhttp_native_from_validated(
        aTHX_ &MY_CXT.uniform_api,
        &input,
        UHTTP_NATIVE_TRUSTED
    );

    if (cookie != NULL) {
        Safefree(cookie);
    }
    if (fields != NULL) {
        Safefree(fields);
    }

    return object;
}

static SV *
unblock_http3_header_block_uniform_response(
    pTHX_ unblock_http3_header_block *block,
    IV status,
    int fin
)
{
    dMY_CXT;
    uhttp_native_input input;
    uhttp_native_field *fields = NULL;
    Size_t field_count = 0;
    uint8_t *cookie = NULL;
    SV *object;

    unblock_http3_header_block_uniform_fields(
        aTHX_ block,
        &fields,
        &field_count,
        &cookie
    );

    uhttp_native_input_init(
        &input,
        UHTTP_KIND_RESPONSE
    );
    input.flags = unblock_http3_received_uniform_flags(
        UHTTP_KIND_RESPONSE,
        fin
    );
    input.version.data = "3";
    input.version.len = 1;
    input.status = status;
    input.headers = fields;
    input.header_count = field_count;

    object = uhttp_native_from_validated(
        aTHX_ &MY_CXT.uniform_api,
        &input,
        UHTTP_NATIVE_TRUSTED
    );

    if (cookie != NULL) {
        Safefree(cookie);
    }
    if (fields != NULL) {
        Safefree(fields);
    }

    return object;
}

static void
unblock_http3_fail(const char *operation, int rv)
{
    croak("%s: %s (%d)", operation, nghttp3_strerror(rv), rv);
}

static unblock_http3_body *
unblock_http3_body_find(
    unblock_http3_native_conn *native,
    int64_t stream_id
)
{
    unblock_http3_body *body;

    for (body = native->bodies; body != NULL; body = body->next) {
        if (body->stream_id == stream_id) {
            return body;
        }
    }

    return NULL;
}

static unblock_http3_body *
unblock_http3_body_create(
    unblock_http3_native_conn *native,
    int64_t stream_id,
    int streaming
)
{
    unblock_http3_body *body;

    if (unblock_http3_body_find(native, stream_id) != NULL) {
        croak("HTTP/3 stream already has an outgoing body");
    }

    Newxz(body, 1, unblock_http3_body);

    body->stream_id = stream_id;
    body->streaming = streaming ? 1 : 0;
    body->next = native->bodies;
    native->bodies = body;

    return body;
}

static void
unblock_http3_body_chunk_free(unblock_http3_body_chunk *chunk)
{
    if (chunk == NULL) {
        return;
    }

    if (chunk->storage != NULL) {
        SvREFCNT_dec(chunk->storage);
        chunk->storage = NULL;
    }

    chunk->data = NULL;
    Safefree(chunk);
}

static size_t
unblock_http3_body_append(
    unblock_http3_native_conn *native,
    unblock_http3_body *body,
    SV *body_sv
)
{
    unblock_http3_body_chunk *chunk;
    SV *storage;
    STRLEN len;
    const char *bytes;

    storage = newSVsv(body_sv);
    bytes = SvPVbyte(storage, len);

    if (len == 0) {
        SvREFCNT_dec(storage);
        return 0;
    }

    Newxz(chunk, 1, unblock_http3_body_chunk);

    chunk->storage = storage;
    chunk->data = (uint8_t *)bytes;
    chunk->len = (size_t)len;

    if (body->tail != NULL) {
        body->tail->next = chunk;
    } else {
        body->head = chunk;
    }

    body->tail = chunk;

    if (body->streaming) {
        native->streaming_retained_bytes += (size_t)len;
    }

    return (size_t)len;
}

static void
unblock_http3_body_discard(
    unblock_http3_native_conn *native,
    unblock_http3_body *body
)
{
    unblock_http3_body_chunk *chunk;

    if (body == NULL) {
        return;
    }

    chunk = body->head;

    while (chunk != NULL) {
        unblock_http3_body_chunk *next_chunk = chunk->next;

        {
            size_t retained = chunk->len - chunk->acked;

            body->discarded_unacked += (uint64_t)retained;

            if (body->streaming) {
                if (native->streaming_retained_bytes < retained) {
                    croak("HTTP/3 streaming retained-byte accounting underflow");
                }

                native->streaming_retained_bytes -= retained;
            }
        }

        unblock_http3_body_chunk_free(chunk);
        chunk = next_chunk;
    }

    body->head = NULL;
    body->tail = NULL;
    body->eof = 1;
}

static void
unblock_http3_body_remove(
    unblock_http3_native_conn *native,
    int64_t stream_id
)
{
    unblock_http3_body **link = &native->bodies;

    while (*link != NULL) {
        unblock_http3_body *body = *link;

        if (body->stream_id != stream_id) {
            link = &body->next;
            continue;
        }

        *link = body->next;

        {
            unblock_http3_body_chunk *chunk = body->head;

            while (chunk != NULL) {
                unblock_http3_body_chunk *next_chunk = chunk->next;
                size_t retained = chunk->len - chunk->acked;

                if (body->streaming) {
                    if (native->streaming_retained_bytes < retained) {
                        croak("HTTP/3 streaming retained-byte accounting underflow");
                    }

                    native->streaming_retained_bytes -= retained;
                }

                unblock_http3_body_chunk_free(chunk);
                chunk = next_chunk;
            }
        }

        Safefree(body);
        return;
    }
}

static void
unblock_http3_body_free_all(unblock_http3_native_conn *native)
{
    unblock_http3_body *body = native->bodies;

    while (body != NULL) {
        unblock_http3_body *next_body = body->next;
        unblock_http3_body_chunk *chunk = body->head;

        while (chunk != NULL) {
            unblock_http3_body_chunk *next_chunk = chunk->next;

            unblock_http3_body_chunk_free(chunk);
            chunk = next_chunk;
        }

        Safefree(body);
        body = next_body;
    }

    native->bodies = NULL;
    native->streaming_retained_bytes = 0;
}

static nghttp3_ssize
unblock_http3_read_body_cb(
    nghttp3_conn *conn,
    int64_t stream_id,
    nghttp3_vec *vec,
    size_t veccnt,
    uint32_t *pflags,
    void *conn_user_data,
    void *stream_user_data
)
{
    unblock_http3_body *body = (unblock_http3_body *)stream_user_data;
    unblock_http3_body_chunk *chunk;
    size_t count = 0;
    int more_unsupplied = 0;

    (void)conn;
    (void)stream_id;
    (void)conn_user_data;

    if (body == NULL) {
        return NGHTTP3_ERR_CALLBACK_FAILURE;
    }

    *pflags = NGHTTP3_DATA_FLAG_NONE;

    for (chunk = body->head; chunk != NULL; chunk = chunk->next) {
        if (chunk->supplied) {
            continue;
        }

        if (count == veccnt) {
            more_unsupplied = 1;
            break;
        }

        vec[count].base = chunk->data;
        vec[count].len = chunk->len;
        chunk->supplied = 1;
        ++count;
    }

    if (count != 0) {
        if (body->eof && !more_unsupplied) {
            for (chunk = body->head; chunk != NULL; chunk = chunk->next) {
                if (!chunk->supplied) {
                    more_unsupplied = 1;
                    break;
                }
            }

            if (!more_unsupplied) {
                *pflags |= NGHTTP3_DATA_FLAG_EOF;
            }
        }

        return (nghttp3_ssize)count;
    }

    if (body->eof) {
        *pflags |= NGHTTP3_DATA_FLAG_EOF;
        return 0;
    }

    return NGHTTP3_ERR_WOULDBLOCK;
}

static const nghttp3_data_reader unblock_http3_body_reader = {
    unblock_http3_read_body_cb
};

static int
unblock_http3_acked_stream_data_cb(
    nghttp3_conn *conn,
    int64_t stream_id,
    uint64_t datalen,
    void *conn_user_data,
    void *stream_user_data
)
{
    unblock_http3_native_conn *native =
        (unblock_http3_native_conn *)conn_user_data;
    unblock_http3_body *body = (unblock_http3_body *)stream_user_data;
    uint64_t remaining = datalen;

    (void)conn;
    (void)stream_id;

    if (body == NULL) {
        return 0;
    }

    if (remaining != 0 && body->discarded_unacked != 0) {
        uint64_t ignored = remaining < body->discarded_unacked
            ? remaining
            : body->discarded_unacked;

        body->discarded_unacked -= ignored;
        remaining -= ignored;
    }

    while (remaining != 0 && body->head != NULL) {
        unblock_http3_body_chunk *chunk = body->head;
        size_t available;
        size_t take;

        if (!chunk->supplied) {
            return NGHTTP3_ERR_CALLBACK_FAILURE;
        }

        available = chunk->len - chunk->acked;
        take = remaining < (uint64_t)available
            ? (size_t)remaining
            : available;

        chunk->acked += take;
        remaining -= take;

        if (body->streaming) {
            if (native->streaming_retained_bytes < take) {
                return NGHTTP3_ERR_CALLBACK_FAILURE;
            }
            native->streaming_retained_bytes -= take;
        }

        if (chunk->acked == chunk->len) {
            body->head = chunk->next;
            if (body->head == NULL) {
                body->tail = NULL;
            }

            unblock_http3_body_chunk_free(chunk);
        }
    }

    if (remaining != 0) {
        return NGHTTP3_ERR_CALLBACK_FAILURE;
    }

    return 0;
}

static AV *
unblock_http3_event_new(const char *type, int64_t stream_id)
{
    AV *event = newAV();

    av_push(event, newSVpv(type, 0));
    av_push(event, newSViv((IV)stream_id));

    return event;
}

static void
unblock_http3_push_event(unblock_http3_native_conn *native, AV *event)
{
    av_push(native->events, newRV_noinc((SV *)event));
}

static int
unblock_http3_recv_settings2_cb(
    nghttp3_conn *conn,
    const nghttp3_proto_settings *settings,
    void *conn_user_data
)
{
    unblock_http3_native_conn *native =
        (unblock_http3_native_conn *)conn_user_data;
    AV *event = unblock_http3_event_new("settings", -1);
    char max_field_section_size[32];

    (void)conn;

    snprintf(
        max_field_section_size,
        sizeof(max_field_section_size),
        "%" PRIu64,
        settings->max_field_section_size
    );

    av_push(event, newSVpv(max_field_section_size, 0));
    av_push(event, newSViv(settings->enable_connect_protocol ? 1 : 0));
    av_push(event, newSViv(settings->h3_datagram ? 1 : 0));
    unblock_http3_push_event(native, event);

    return 0;
}

static int
unblock_http3_recv_origin_cb(
    nghttp3_conn *conn,
    const uint8_t *origin,
    size_t originlen,
    void *conn_user_data
)
{
    unblock_http3_native_conn *native =
        (unblock_http3_native_conn *)conn_user_data;
    AV *event = unblock_http3_event_new("origin", -1);

    (void)conn;

    av_push(event, newSVpvn((const char *)origin, originlen));
    unblock_http3_push_event(native, event);

    return 0;
}

static int
unblock_http3_end_origin_cb(
    nghttp3_conn *conn,
    void *conn_user_data
)
{
    unblock_http3_native_conn *native =
        (unblock_http3_native_conn *)conn_user_data;

    (void)conn;

    unblock_http3_push_event(
        native,
        unblock_http3_event_new("end_origin", -1)
    );

    return 0;
}

static int
unblock_http3_recv_data_cb(
    nghttp3_conn *conn,
    int64_t stream_id,
    const uint8_t *data,
    size_t datalen,
    void *conn_user_data,
    void *stream_user_data
)
{
    unblock_http3_native_conn *native =
        (unblock_http3_native_conn *)conn_user_data;
    AV *event = unblock_http3_event_new("data", stream_id);

    (void)conn;
    (void)stream_user_data;

    av_push(event, newSVpvn((const char *)data, datalen));
    unblock_http3_push_event(native, event);

    return 0;
}

static int
unblock_http3_deferred_consume_cb(
    nghttp3_conn *conn,
    int64_t stream_id,
    size_t consumed,
    void *conn_user_data,
    void *stream_user_data
)
{
    unblock_http3_native_conn *native =
        (unblock_http3_native_conn *)conn_user_data;
    AV *event = unblock_http3_event_new("deferred_consume", stream_id);

    (void)conn;
    (void)stream_user_data;

    av_push(event, newSVuv((UV)consumed));
    unblock_http3_push_event(native, event);

    return 0;
}

static int
unblock_http3_begin_headers_cb(
    nghttp3_conn *conn,
    int64_t stream_id,
    void *conn_user_data,
    void *stream_user_data
)
{
    unblock_http3_native_conn *native =
        (unblock_http3_native_conn *)conn_user_data;

    (void)conn;
    (void)stream_user_data;

    (void)unblock_http3_header_block_create(
        native,
        stream_id
    );

    return 0;
}

static int
unblock_http3_recv_header_cb(
    nghttp3_conn *conn,
    int64_t stream_id,
    int32_t token,
    nghttp3_rcbuf *name,
    nghttp3_rcbuf *value,
    uint8_t flags,
    void *conn_user_data,
    void *stream_user_data
)
{
    unblock_http3_native_conn *native =
        (unblock_http3_native_conn *)conn_user_data;
    unblock_http3_header_block *block =
        unblock_http3_header_block_find(native, stream_id);
    nghttp3_vec nbuf = nghttp3_rcbuf_get_buf(name);
    nghttp3_vec vbuf = nghttp3_rcbuf_get_buf(value);

    (void)conn;
    (void)token;
    (void)flags;
    (void)stream_user_data;

    unblock_http3_header_block_append(
        block,
        nbuf.base,
        nbuf.len,
        vbuf.base,
        vbuf.len
    );

    return 0;
}

static int
unblock_http3_end_headers_cb(
    nghttp3_conn *conn,
    int64_t stream_id,
    int fin,
    void *conn_user_data,
    void *stream_user_data
)
{
    unblock_http3_native_conn *native =
        (unblock_http3_native_conn *)conn_user_data;
    unblock_http3_header_block *block =
        unblock_http3_header_block_find(native, stream_id);
    AV *event;

    (void)conn;
    (void)stream_user_data;

    if (block == NULL) {
        croak("HTTP/3 header section ended without beginning");
    }

    event = unblock_http3_event_new("headers", stream_id);
    av_push(event, newSVuv((UV)block->field_section_size));
    av_push(event, newSViv(fin ? 1 : 0));
    unblock_http3_push_event(native, event);

    return 0;
}

static int
unblock_http3_begin_trailers_cb(
    nghttp3_conn *conn,
    int64_t stream_id,
    void *conn_user_data,
    void *stream_user_data
)
{
    unblock_http3_native_conn *native =
        (unblock_http3_native_conn *)conn_user_data;

    (void)conn;
    (void)stream_user_data;

    unblock_http3_push_event(
        native,
        unblock_http3_event_new("begin_trailers", stream_id)
    );

    return 0;
}

static int
unblock_http3_recv_trailer_cb(
    nghttp3_conn *conn,
    int64_t stream_id,
    int32_t token,
    nghttp3_rcbuf *name,
    nghttp3_rcbuf *value,
    uint8_t flags,
    void *conn_user_data,
    void *stream_user_data
)
{
    unblock_http3_native_conn *native =
        (unblock_http3_native_conn *)conn_user_data;
    nghttp3_vec nbuf = nghttp3_rcbuf_get_buf(name);
    nghttp3_vec vbuf = nghttp3_rcbuf_get_buf(value);
    AV *event = unblock_http3_event_new("trailer", stream_id);

    (void)conn;
    (void)token;
    (void)flags;
    (void)stream_user_data;

    av_push(event, newSVpvn((const char *)nbuf.base, nbuf.len));
    av_push(event, newSVpvn((const char *)vbuf.base, vbuf.len));
    unblock_http3_push_event(native, event);

    return 0;
}

static int
unblock_http3_end_trailers_cb(
    nghttp3_conn *conn,
    int64_t stream_id,
    int fin,
    void *conn_user_data,
    void *stream_user_data
)
{
    unblock_http3_native_conn *native =
        (unblock_http3_native_conn *)conn_user_data;
    AV *event = unblock_http3_event_new("end_trailers", stream_id);

    (void)conn;
    (void)stream_user_data;

    av_push(event, newSViv(fin ? 1 : 0));
    unblock_http3_push_event(native, event);

    return 0;
}

static int
unblock_http3_end_stream_cb(
    nghttp3_conn *conn,
    int64_t stream_id,
    void *conn_user_data,
    void *stream_user_data
)
{
    unblock_http3_native_conn *native =
        (unblock_http3_native_conn *)conn_user_data;

    (void)conn;
    (void)stream_user_data;

    unblock_http3_push_event(
        native,
        unblock_http3_event_new("end_stream", stream_id)
    );

    return 0;
}

static int
unblock_http3_stop_sending_cb(
    nghttp3_conn *conn,
    int64_t stream_id,
    uint64_t app_error_code,
    void *conn_user_data,
    void *stream_user_data
)
{
    unblock_http3_native_conn *native =
        (unblock_http3_native_conn *)conn_user_data;
    AV *event = unblock_http3_event_new("stop_sending", stream_id);

    (void)conn;
    (void)stream_user_data;

    av_push(event, newSVuv((UV)app_error_code));
    unblock_http3_push_event(native, event);

    return 0;
}

static int
unblock_http3_reset_stream_cb(
    nghttp3_conn *conn,
    int64_t stream_id,
    uint64_t app_error_code,
    void *conn_user_data,
    void *stream_user_data
)
{
    unblock_http3_native_conn *native =
        (unblock_http3_native_conn *)conn_user_data;
    AV *event = unblock_http3_event_new("reset_stream", stream_id);

    (void)conn;
    (void)stream_user_data;

    av_push(event, newSVuv((UV)app_error_code));
    unblock_http3_push_event(native, event);

    return 0;
}

static int
unblock_http3_shutdown_cb(
    nghttp3_conn *conn,
    int64_t id,
    void *conn_user_data
)
{
    unblock_http3_native_conn *native =
        (unblock_http3_native_conn *)conn_user_data;
    AV *event = unblock_http3_event_new("shutdown", id);

    (void)conn;

    unblock_http3_push_event(native, event);

    return 0;
}

static int
unblock_http3_stream_close2_cb(
    nghttp3_conn *conn,
    uint32_t flags,
    int64_t stream_id,
    uint64_t rx_app_error_code,
    uint64_t tx_app_error_code,
    void *conn_user_data,
    void *stream_user_data
)
{
    unblock_http3_native_conn *native =
        (unblock_http3_native_conn *)conn_user_data;
    AV *event = unblock_http3_event_new("stream_close", stream_id);

    (void)conn;
    (void)stream_user_data;

    av_push(event, newSVuv((UV)flags));
    av_push(event, newSVuv((UV)rx_app_error_code));
    av_push(event, newSVuv((UV)tx_app_error_code));
    unblock_http3_push_event(native, event);

    return 0;
}

static SV *
unblock_http3_bless_conn(unblock_http3_native_conn *native)
{
    SV *inner = newSViv(PTR2IV(native));
    SV *rv = newRV_noinc(inner);

    sv_bless(
        rv,
        gv_stashpv("Unblock::HTTP3::_Native::Connection", GV_ADD)
    );

    return rv;
}

static unblock_http3_native_conn *
unblock_http3_conn_from_sv(SV *self)
{
    unblock_http3_native_conn *native;

    if (!SvROK(self)) {
        croak("native HTTP/3 connection is not a reference");
    }

    native = INT2PTR(
        unblock_http3_native_conn *,
        SvIV(SvRV(self))
    );

    if (native == NULL || native->conn == NULL) {
        croak("native HTTP/3 connection has been destroyed");
    }

    if (native->fatal) {
        croak("native HTTP/3 connection is no longer usable");
    }

    return native;
}

static SV *
unblock_http3_new_conn(
    int is_server,
    uint64_t max_field_section_size,
    uint64_t qpack_max_table_capacity,
    uint64_t qpack_blocked_streams,
    int enable_connect_protocol,
    int h3_datagram,
    SV *origin_list_sv
)
{
    unblock_http3_native_conn *native;
    nghttp3_callbacks callbacks;
    nghttp3_settings settings;
    int rv;

    Newxz(native, 1, unblock_http3_native_conn);
    Zero(&callbacks, 1, nghttp3_callbacks);

    native->events = newAV();

    callbacks.acked_stream_data = unblock_http3_acked_stream_data_cb;
    callbacks.recv_settings2 = unblock_http3_recv_settings2_cb;
    callbacks.recv_origin = unblock_http3_recv_origin_cb;
    callbacks.end_origin = unblock_http3_end_origin_cb;
    callbacks.recv_data = unblock_http3_recv_data_cb;
    callbacks.deferred_consume = unblock_http3_deferred_consume_cb;
    callbacks.begin_headers = unblock_http3_begin_headers_cb;
    callbacks.recv_header = unblock_http3_recv_header_cb;
    callbacks.end_headers = unblock_http3_end_headers_cb;
    callbacks.begin_trailers = unblock_http3_begin_trailers_cb;
    callbacks.recv_trailer = unblock_http3_recv_trailer_cb;
    callbacks.end_trailers = unblock_http3_end_trailers_cb;
    callbacks.end_stream = unblock_http3_end_stream_cb;
    callbacks.stop_sending = unblock_http3_stop_sending_cb;
    callbacks.reset_stream = unblock_http3_reset_stream_cb;
    callbacks.shutdown = unblock_http3_shutdown_cb;
    callbacks.stream_close2 = unblock_http3_stream_close2_cb;

    nghttp3_settings_default(&settings);
    settings.max_field_section_size = max_field_section_size;
    settings.qpack_max_dtable_capacity = qpack_max_table_capacity;
    settings.qpack_blocked_streams = qpack_blocked_streams;
    settings.enable_connect_protocol = enable_connect_protocol ? 1 : 0;
    settings.h3_datagram = h3_datagram ? 1 : 0;

    if (is_server && origin_list_sv != NULL && SvOK(origin_list_sv)) {
        STRLEN origin_list_len;
        const char *origin_list_bytes =
            SvPVbyte(origin_list_sv, origin_list_len);

        if (origin_list_len != 0) {
            Newx(native->origin_list_data, origin_list_len, uint8_t);
            Copy(
                origin_list_bytes,
                native->origin_list_data,
                origin_list_len,
                uint8_t
            );
        }

        native->origin_list.base = native->origin_list_data;
        native->origin_list.len = (size_t)origin_list_len;
        settings.origin_list = &native->origin_list;
    }

    if (is_server) {
        rv = nghttp3_conn_server_new(
            &native->conn,
            &callbacks,
            &settings,
            NULL,
            native
        );
    } else {
        rv = nghttp3_conn_client_new(
            &native->conn,
            &callbacks,
            &settings,
            NULL,
            native
        );
    }

    if (rv != 0) {
        SvREFCNT_dec((SV *)native->events);
        if (native->origin_list_data != NULL) {
            Safefree(native->origin_list_data);
        }
        Safefree(native);
        unblock_http3_fail("could not create libnghttp3 connection", rv);
    }

    native->is_server = is_server ? 1 : 0;

    return unblock_http3_bless_conn(native);
}


typedef struct {
    nghttp3_nv *nva;
    uint8_t **owned_names;
    size_t nvlen;
} unblock_http3_uniform_fields;

static int
unblock_http3_bytes_equal(
    const uint8_t *left,
    size_t left_len,
    const char *right
)
{
    size_t right_len = strlen(right);

    return left_len == right_len
        && memcmp(left, right, right_len) == 0;
}

static int
unblock_http3_ascii_equal_ci(
    const uint8_t *left,
    size_t left_len,
    const char *right
)
{
    size_t i;
    size_t right_len = strlen(right);

    if (left_len != right_len) {
        return 0;
    }

    for (i = 0; i < left_len; ++i) {
        uint8_t ch = left[i];
        uint8_t expected = (uint8_t)right[i];

        if (ch >= 'A' && ch <= 'Z') {
            ch = (uint8_t)(ch + ('a' - 'A'));
        }

        if (expected >= 'A' && expected <= 'Z') {
            expected = (uint8_t)(expected + ('a' - 'A'));
        }

        if (ch != expected) {
            return 0;
        }
    }

    return 1;
}

static void
unblock_http3_uniform_fields_free(unblock_http3_uniform_fields *fields)
{
    size_t i;

    if (fields == NULL) {
        return;
    }

    if (fields->owned_names != NULL) {
        for (i = 0; i < fields->nvlen; ++i) {
            if (fields->owned_names[i] != NULL) {
                Safefree(fields->owned_names[i]);
            }
        }

        Safefree(fields->owned_names);
    }

    if (fields->nva != NULL) {
        Safefree(fields->nva);
    }

    fields->nva = NULL;
    fields->owned_names = NULL;
    fields->nvlen = 0;
}

static void
unblock_http3_uniform_nv_static(
    nghttp3_nv *nv,
    const char *name,
    const char *value,
    size_t value_len
)
{
    nv->name = (const uint8_t *)name;
    nv->namelen = strlen(name);
    nv->value = (const uint8_t *)value;
    nv->valuelen = value_len;
    nv->flags = NGHTTP3_NV_FLAG_NONE;
}

static void
unblock_http3_uniform_nv_sv(
    nghttp3_nv *nv,
    const char *name,
    SV *value
)
{
    STRLEN len;
    const char *bytes = SvPVbyte(value, len);

    unblock_http3_uniform_nv_static(
        nv,
        name,
        bytes,
        (size_t)len
    );
}

static void
unblock_http3_validate_uniform_field(
    int context,
    const uint8_t *name,
    size_t namelen,
    const uint8_t *value,
    size_t valuelen
)
{
    size_t start;
    size_t end;

    if (
        unblock_http3_ascii_equal_ci(name, namelen, "connection")
        || unblock_http3_ascii_equal_ci(name, namelen, "keep-alive")
        || unblock_http3_ascii_equal_ci(name, namelen, "proxy-connection")
        || unblock_http3_ascii_equal_ci(name, namelen, "transfer-encoding")
        || unblock_http3_ascii_equal_ci(name, namelen, "upgrade")
    ) {
        croak("HTTP/3 does not allow connection-specific field '%.*s'",
            (int)namelen, (const char *)name);
    }

    if (unblock_http3_ascii_equal_ci(name, namelen, "te")) {
        if (context != 0) {
            croak("HTTP/3 TE is only allowed in request headers");
        }

        start = 0;
        end = valuelen;

        while (
            start < end
            && (value[start] == ' ' || value[start] == '\t')
        ) {
            ++start;
        }

        while (
            end > start
            && (value[end - 1] == ' ' || value[end - 1] == '\t')
        ) {
            --end;
        }

        if (
            !unblock_http3_ascii_equal_ci(
                value + start,
                end - start,
                "trailers"
            )
        ) {
            croak("HTTP/3 TE field may contain only 'trailers'");
        }
    }

    if (context == 2) {
        if (unblock_http3_ascii_equal_ci(name, namelen, "content-length")) {
            croak("HTTP/3 Content-Length is not allowed in trailers");
        }

        if (unblock_http3_ascii_equal_ci(name, namelen, "host")) {
            croak("HTTP/3 Host is not allowed in trailers");
        }
    }
}


static void
unblock_http3_uniform_validate_section(
    pTHX_ const uhttp_native_section *section,
    int context
)
{
    Size_t i;
    Size_t count = uhttp_native_field_count(aTHX_ section);

    for (i = 0; i < count; ++i) {
        SV *name_sv;
        SV *value_sv;
        STRLEN namelen;
        STRLEN valuelen;
        const char *name;
        const char *value;

        if (
            !uhttp_native_field_at(
                aTHX_ section,
                i,
                &name_sv,
                &value_sv
            )
        ) {
            croak("Uniform field inspection failed");
        }

        name = SvPVbyte(name_sv, namelen);
        value = SvPVbyte(value_sv, valuelen);

        unblock_http3_validate_uniform_field(
            context,
            (const uint8_t *)name,
            (size_t)namelen,
            (const uint8_t *)value,
            (size_t)valuelen
        );
    }
}

static size_t
unblock_http3_uniform_section_size(
    pTHX_ const uhttp_native_section *section
)
{
    Size_t i;
    Size_t count = uhttp_native_field_count(aTHX_ section);
    size_t total = 0;

    for (i = 0; i < count; ++i) {
        SV *name_sv;
        SV *value_sv;
        STRLEN namelen;
        STRLEN valuelen;

        if (
            !uhttp_native_field_at(
                aTHX_ section,
                i,
                &name_sv,
                &value_sv
            )
        ) {
            croak("Uniform header inspection failed");
        }

        (void)SvPVbyte(name_sv, namelen);
        (void)SvPVbyte(value_sv, valuelen);

        if (
            total > SIZE_MAX - (size_t)namelen
            || total + (size_t)namelen > SIZE_MAX - (size_t)valuelen
            || total + (size_t)namelen + (size_t)valuelen > SIZE_MAX - 32
        ) {
            croak("HTTP/3 field section size overflow");
        }

        total += (size_t)namelen + (size_t)valuelen + 32;
    }

    return total;
}

static size_t
unblock_http3_uniform_pseudo_size(
    const char *name,
    SV *value
)
{
    STRLEN valuelen;

    (void)SvPVbyte(value, valuelen);
    return strlen(name) + (size_t)valuelen + 32;
}

static void
unblock_http3_uniform_add_section(
    pTHX_ unblock_http3_uniform_fields *out,
    size_t *index,
    const uhttp_native_section *section,
    int context
)
{
    Size_t i;
    Size_t count = uhttp_native_field_count(aTHX_ section);

    for (i = 0; i < count; ++i) {
        SV *name_sv;
        SV *value_sv;
        STRLEN namelen;
        STRLEN valuelen;
        const char *name;
        const char *value;
        uint8_t *lower = NULL;
        size_t j;
        int needs_lower = 0;

        if (
            !uhttp_native_field_at(
                aTHX_ section,
                i,
                &name_sv,
                &value_sv
            )
        ) {
            croak("Uniform field inspection failed");
        }

        name = SvPVbyte(name_sv, namelen);
        value = SvPVbyte(value_sv, valuelen);

        for (j = 0; j < (size_t)namelen; ++j) {
            uint8_t ch = (uint8_t)name[j];

            if (ch >= 'A' && ch <= 'Z') {
                needs_lower = 1;
                break;
            }
        }

        if (needs_lower) {
            Newx(lower, namelen ? namelen : 1, uint8_t);

            for (j = 0; j < (size_t)namelen; ++j) {
                uint8_t ch = (uint8_t)name[j];

                if (ch >= 'A' && ch <= 'Z') {
                    ch = (uint8_t)(ch + ('a' - 'A'));
                }

                lower[j] = ch;
            }

            out->nva[*index].name = lower;
        } else {
            out->nva[*index].name = (const uint8_t *)name;
        }
        out->nva[*index].namelen = (size_t)namelen;
        out->nva[*index].value = (const uint8_t *)value;
        out->nva[*index].valuelen = (size_t)valuelen;
        out->nva[*index].flags = NGHTTP3_NV_FLAG_NONE;
        out->owned_names[*index] = lower;
        ++*index;
    }
}

static int
unblock_http3_uniform_request_shape(
    pTHX_ const uhttp_native_view *view,
    int *is_connect,
    int *is_extended
)
{
    STRLEN method_len;
    const char *method;

    if (!SvOK(view->method) || !SvOK(view->target)) {
        croak("canonical Uniform request is missing method or target");
    }

    method = SvPVbyte(view->method, method_len);
    *is_connect =
        method_len == 7 && memcmp(method, "CONNECT", 7) == 0
            ? 1 : 0;
    *is_extended = *is_connect && SvOK(view->protocol) ? 1 : 0;

    if (*is_connect) {
        if (!SvOK(view->authority)) {
            croak("HTTP/3 CONNECT request requires authority");
        }

        if (*is_extended && !SvOK(view->scheme)) {
            croak("HTTP/3 Extended CONNECT request requires scheme");
        }
    } else {
        if (!SvOK(view->scheme)) {
            croak("HTTP/3 request requires scheme");
        }

        if (!SvOK(view->authority)) {
            croak("HTTP/3 request requires authority");
        }
    }

    return 1;
}

static size_t
unblock_http3_uniform_request_size(
    pTHX_ const uhttp_native_view *view
)
{
    int is_connect;
    int is_extended;
    size_t total;

    unblock_http3_uniform_request_shape(
        aTHX_ view,
        &is_connect,
        &is_extended
    );

    total = unblock_http3_uniform_section_size(
        aTHX_ &view->headers
    );

    total += unblock_http3_uniform_pseudo_size(
        ":method",
        view->method
    );

    if (is_extended) {
        total += unblock_http3_uniform_pseudo_size(
            ":protocol",
            view->protocol
        );
        total += unblock_http3_uniform_pseudo_size(
            ":scheme",
            view->scheme
        );
        total += unblock_http3_uniform_pseudo_size(
            ":authority",
            view->authority
        );
        total += unblock_http3_uniform_pseudo_size(
            ":path",
            view->target
        );
    } else if (is_connect) {
        total += unblock_http3_uniform_pseudo_size(
            ":authority",
            view->authority
        );
    } else {
        total += unblock_http3_uniform_pseudo_size(
            ":scheme",
            view->scheme
        );
        total += unblock_http3_uniform_pseudo_size(
            ":authority",
            view->authority
        );
        total += unblock_http3_uniform_pseudo_size(
            ":path",
            view->target
        );
    }

    return total;
}

static size_t
unblock_http3_uniform_response_size(
    pTHX_ const uhttp_native_view *view
)
{
    IV status;
    char status_buffer[4];

    if (!SvOK(view->status)) {
        croak("canonical Uniform response is missing status");
    }

    status = SvIV(view->status);

    if (status < 100 || status > 599) {
        croak("canonical Uniform response status is invalid");
    }

    snprintf(status_buffer, sizeof(status_buffer), "%ld", (long)status);

    return strlen(":status") + strlen(status_buffer) + 32
        + unblock_http3_uniform_section_size(
            aTHX_ &view->headers
        );
}

static void
unblock_http3_uniform_request_fields(
    pTHX_ const uhttp_native_view *view,
    unblock_http3_uniform_fields *out
)
{
    Size_t header_count = uhttp_native_field_count(
        aTHX_ &view->headers
    );
    int is_connect;
    int is_extended;
    size_t pseudo_count;
    size_t index = 0;

    unblock_http3_uniform_request_shape(
        aTHX_ view,
        &is_connect,
        &is_extended
    );
    unblock_http3_uniform_validate_section(
        aTHX_ &view->headers,
        0
    );

    pseudo_count = is_extended ? 5 : (is_connect ? 2 : 4);

    Zero(out, 1, unblock_http3_uniform_fields);
    out->nvlen = pseudo_count + (size_t)header_count;

    if (out->nvlen == 0) {
        return;
    }

    Newxz(out->nva, out->nvlen, nghttp3_nv);
    Newxz(out->owned_names, out->nvlen, uint8_t *);

    unblock_http3_uniform_nv_sv(
        &out->nva[index++],
        ":method",
        view->method
    );

    if (is_extended) {
        unblock_http3_uniform_nv_sv(
            &out->nva[index++],
            ":protocol",
            view->protocol
        );
        unblock_http3_uniform_nv_sv(
            &out->nva[index++],
            ":scheme",
            view->scheme
        );
        unblock_http3_uniform_nv_sv(
            &out->nva[index++],
            ":authority",
            view->authority
        );
        unblock_http3_uniform_nv_sv(
            &out->nva[index++],
            ":path",
            view->target
        );
    } else if (is_connect) {
        unblock_http3_uniform_nv_sv(
            &out->nva[index++],
            ":authority",
            view->authority
        );
    } else {
        unblock_http3_uniform_nv_sv(
            &out->nva[index++],
            ":scheme",
            view->scheme
        );
        unblock_http3_uniform_nv_sv(
            &out->nva[index++],
            ":authority",
            view->authority
        );
        unblock_http3_uniform_nv_sv(
            &out->nva[index++],
            ":path",
            view->target
        );
    }

    unblock_http3_uniform_add_section(
        aTHX_ out,
        &index,
        &view->headers,
        0
    );
}

static void
unblock_http3_uniform_response_fields(
    pTHX_ const uhttp_native_view *view,
    unblock_http3_uniform_fields *out,
    char status_buffer[4]
)
{
    Size_t header_count = uhttp_native_field_count(
        aTHX_ &view->headers
    );
    IV status;
    size_t index = 0;

    if (!SvOK(view->status)) {
        croak("canonical Uniform response is missing status");
    }

    status = SvIV(view->status);

    if (status < 100 || status > 599) {
        croak("canonical Uniform response status is invalid");
    }

    snprintf(status_buffer, 4, "%ld", (long)status);
    unblock_http3_uniform_validate_section(
        aTHX_ &view->headers,
        1
    );

    Zero(out, 1, unblock_http3_uniform_fields);
    out->nvlen = 1 + (size_t)header_count;

    Newxz(out->nva, out->nvlen, nghttp3_nv);
    Newxz(out->owned_names, out->nvlen, uint8_t *);

    unblock_http3_uniform_nv_static(
        &out->nva[index++],
        ":status",
        status_buffer,
        strlen(status_buffer)
    );

    unblock_http3_uniform_add_section(
        aTHX_ out,
        &index,
        &view->headers,
        1
    );
}

static void
unblock_http3_uniform_trailer_fields(
    pTHX_ const uhttp_native_view *view,
    unblock_http3_uniform_fields *out
)
{
    Size_t count = uhttp_native_field_count(
        aTHX_ &view->trailers
    );
    size_t index = 0;

    unblock_http3_uniform_validate_section(
        aTHX_ &view->trailers,
        2
    );
    Zero(out, 1, unblock_http3_uniform_fields);
    out->nvlen = (size_t)count;

    if (out->nvlen == 0) {
        return;
    }

    Newxz(out->nva, out->nvlen, nghttp3_nv);
    Newxz(out->owned_names, out->nvlen, uint8_t *);

    unblock_http3_uniform_add_section(
        aTHX_ out,
        &index,
        &view->trailers,
        2
    );
}

static void
unblock_http3_uniform_any_view(
    pTHX_ SV *message,
    uhttp_native_view *view
)
{
    dMY_CXT;

    if (
        !uhttp_native_inspect(
            aTHX_ &MY_CXT.uniform_api,
            message,
            view
        )
    ) {
        croak("native Uniform fast path requires an exact canonical message");
    }
}

static void
unblock_http3_uniform_view(
    pTHX_ SV *message,
    U32 expected_kind,
    uhttp_native_view *view
)
{
    unblock_http3_uniform_any_view(
        aTHX_ message,
        view
    );

    if (view->kind != expected_kind) {
        croak("canonical Uniform message has the wrong kind");
    }
}


typedef struct {
    SV *connection;
    HV *connection_hv;
    CV *service_cv;
    CV *request_cv;
    CV *send_response_cv;
    CV *send_informational_cv;
    void *interpreter;
} unblock_http3_consumer_context;

static void *
unblock_http3_consumer_interpreter(pTHX)
{
#ifdef MULTIPLICITY
    return (void *)aTHX;
#else
    return NULL;
#endif
}

static SV *
unblock_http3_consumer_fetch(
    pTHX_ HV *hv,
    const char *key,
    I32 key_len,
    int required
)
{
    SV **slot = hv_fetch(hv, key, key_len, 0);

    if (slot == NULL) {
        if (required) {
            croak("Unblock::HTTP3 native ABI object is missing '%.*s'",
                (int)key_len, key);
        }

        return NULL;
    }

    return *slot;
}

static HV *
unblock_http3_consumer_exact_object(
    pTHX_
    SV *object,
    const char *class_name
)
{
    HV *stash;

    if (
        object == NULL
        || !SvROK(object)
        || SvTYPE(SvRV(object)) != SVt_PVHV
        || !SvOBJECT(SvRV(object))
        || SvMAGICAL(SvRV(object))
    ) {
        croak("Unblock::HTTP3 native ABI requires a plain blessed hash object");
    }

    stash = gv_stashpv(class_name, 0);

    if (stash == NULL || SvSTASH(SvRV(object)) != stash) {
        croak("Unblock::HTTP3 native ABI requires exact class %s", class_name);
    }

    return (HV *)SvRV(object);
}

static unblock_http3_consumer_context *
unblock_http3_consumer_require_context(
    pTHX_ void *opaque
)
{
    unblock_http3_consumer_context *context =
        (unblock_http3_consumer_context *)opaque;

    if (
        context == NULL
        || context->connection == NULL
        || context->connection_hv == NULL
        || context->interpreter != unblock_http3_consumer_interpreter(aTHX)
    ) {
        croak("Unblock::HTTP3 native consumer context is invalid");
    }

    return context;
}

static SV *
unblock_http3_consumer_call_scalar_2(
    pTHX_
    CV *cv,
    SV *first,
    SV *second
)
{
    dSP;
    int count;
    SV *value;
    SV *owned = NULL;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(first);
    XPUSHs(second);
    PUTBACK;

    count = call_sv((SV *)cv, G_SCALAR);

    SPAGAIN;

    if (count != 1) {
        PUTBACK;
        FREETMPS;
        LEAVE;
        croak("Unblock::HTTP3 native ABI callback returned an invalid result");
    }

    value = POPs;

    if (SvOK(value)) {
        owned = newSVsv(value);
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return owned;
}

static void
unblock_http3_consumer_call_void_1(
    pTHX_
    CV *cv,
    SV *first
)
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(first);
    PUTBACK;

    (void)call_sv((SV *)cv, G_VOID);

    FREETMPS;
    LEAVE;
}

static void
unblock_http3_consumer_call_void_2(
    pTHX_
    CV *cv,
    SV *first,
    SV *second
)
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(first);
    XPUSHs(second);
    PUTBACK;

    (void)call_sv((SV *)cv, G_VOID);

    FREETMPS;
    LEAVE;
}

static SV *
unblock_http3_consumer_shift_queue(
    pTHX_
    HV *connection_hv,
    const char *key,
    I32 key_len
)
{
    SV *queue_sv;
    AV *queue;

    queue_sv = unblock_http3_consumer_fetch(
        aTHX_ connection_hv,
        key,
        key_len,
        1
    );

    if (
        !SvROK(queue_sv)
        || SvTYPE(SvRV(queue_sv)) != SVt_PVAV
        || SvMAGICAL(SvRV(queue_sv))
        || SvOBJECT(SvRV(queue_sv))
    ) {
        croak("Unblock::HTTP3 native ABI queue storage is invalid");
    }

    queue = (AV *)SvRV(queue_sv);

    if (av_len(queue) < 0) {
        return NULL;
    }

    return av_shift(queue);
}

static void *
unblock_http3_consumer_create(
    pTHX_ SV *connection
)
{
    unblock_http3_consumer_context *context;

    (void)unblock_http3_consumer_exact_object(
        aTHX_ connection,
        "Unblock::HTTP3::Connection"
    );

    Newxz(context, 1, unblock_http3_consumer_context);

    context->connection = newSVsv(connection);
    context->connection_hv = (HV *)SvRV(context->connection);
    context->service_cv =
        get_cv("Unblock::HTTP3::Connection::_service", 0);
    context->request_cv =
        get_cv("Unblock::HTTP3::Connection::request", 0);
    context->send_response_cv =
        get_cv("Unblock::HTTP3::Transaction::send_response", 0);
    context->send_informational_cv =
        get_cv("Unblock::HTTP3::Transaction::send_informational", 0);
    context->interpreter =
        unblock_http3_consumer_interpreter(aTHX);

    if (
        context->service_cv == NULL
        || context->request_cv == NULL
        || context->send_response_cv == NULL
        || context->send_informational_cv == NULL
    ) {
        SvREFCNT_dec(context->connection);
        Safefree(context);
        croak("Unblock::HTTP3 native ABI could not resolve provider callbacks");
    }

    return context;
}

static void
unblock_http3_consumer_service(
    pTHX_ void *opaque
)
{
    unblock_http3_consumer_context *context =
        unblock_http3_consumer_require_context(aTHX_ opaque);

    unblock_http3_consumer_call_void_1(
        aTHX_ context->service_cv,
        context->connection
    );
}

static int
unblock_http3_consumer_should_service(
    pTHX_ unblock_http3_consumer_context *context
)
{
    SV *started = unblock_http3_consumer_fetch(
        aTHX_ context->connection_hv,
        "started",
        7,
        1
    );
    SV *failed = unblock_http3_consumer_fetch(
        aTHX_ context->connection_hv,
        "failed",
        6,
        1
    );

    return SvTRUE(started) && !SvTRUE(failed);
}

static SV *
unblock_http3_consumer_request(
    pTHX_
    void *opaque,
    SV *request
)
{
    unblock_http3_consumer_context *context =
        unblock_http3_consumer_require_context(aTHX_ opaque);

    return unblock_http3_consumer_call_scalar_2(
        aTHX_
        context->request_cv,
        context->connection,
        request
    );
}

static SV *
unblock_http3_consumer_next_transaction(
    pTHX_ void *opaque
)
{
    unblock_http3_consumer_context *context =
        unblock_http3_consumer_require_context(aTHX_ opaque);

    if (unblock_http3_consumer_should_service(aTHX_ context)) {
        unblock_http3_consumer_service(aTHX_ context);
    }

    return unblock_http3_consumer_shift_queue(
        aTHX_
        context->connection_hv,
        "ready_transactions",
        18
    );
}

static SV *
unblock_http3_consumer_next_informational(
    pTHX_ void *opaque
)
{
    unblock_http3_consumer_context *context =
        unblock_http3_consumer_require_context(aTHX_ opaque);

    if (unblock_http3_consumer_should_service(aTHX_ context)) {
        unblock_http3_consumer_service(aTHX_ context);
    }

    return unblock_http3_consumer_shift_queue(
        aTHX_
        context->connection_hv,
        "ready_informational",
        19
    );
}

static HV *
unblock_http3_consumer_transaction_hv(
    pTHX_ SV *transaction
)
{
    return unblock_http3_consumer_exact_object(
        aTHX_
        transaction,
        "Unblock::HTTP3::Transaction"
    );
}

static SV *
unblock_http3_consumer_transaction_next_informational(
    pTHX_ SV *transaction
)
{
    HV *hv = unblock_http3_consumer_transaction_hv(
        aTHX_ transaction
    );

    return unblock_http3_consumer_shift_queue(
        aTHX_
        hv,
        "informational",
        13
    );
}

static SV *
unblock_http3_consumer_transaction_request(
    pTHX_ SV *transaction
)
{
    HV *hv = unblock_http3_consumer_transaction_hv(
        aTHX_ transaction
    );

    return unblock_http3_consumer_fetch(
        aTHX_ hv,
        "request",
        7,
        1
    );
}

static SV *
unblock_http3_consumer_transaction_response(
    pTHX_ SV *transaction
)
{
    HV *hv = unblock_http3_consumer_transaction_hv(
        aTHX_ transaction
    );
    SV *response = unblock_http3_consumer_fetch(
        aTHX_ hv,
        "response",
        8,
        1
    );

    return SvOK(response) ? response : NULL;
}

static int64_t
unblock_http3_consumer_transaction_stream_id(
    pTHX_ SV *transaction
)
{
    HV *hv = unblock_http3_consumer_transaction_hv(
        aTHX_ transaction
    );
    SV *stream_id = unblock_http3_consumer_fetch(
        aTHX_ hv,
        "stream_id",
        9,
        1
    );

    return (int64_t)SvIV(stream_id);
}

static uint32_t
unblock_http3_consumer_transaction_state(
    pTHX_ SV *transaction
)
{
    HV *hv = unblock_http3_consumer_transaction_hv(
        aTHX_ transaction
    );
    SV *state_sv = unblock_http3_consumer_fetch(
        aTHX_ hv,
        "state",
        5,
        1
    );
    STRLEN len;
    const char *state = SvPV(state_sv, len);

    if (len == 6 && memcmp(state, "active", 6) == 0) {
        return UB_HTTP3_TX_ACTIVE;
    }

    if (len == 8 && memcmp(state, "complete", 8) == 0) {
        return UB_HTTP3_TX_COMPLETE;
    }

    if (len == 9 && memcmp(state, "cancelled", 9) == 0) {
        return UB_HTTP3_TX_CANCELLED;
    }

    if (len == 5 && memcmp(state, "error", 5) == 0) {
        return UB_HTTP3_TX_ERROR;
    }

    croak("Unblock::HTTP3 native ABI encountered an unknown Transaction state");
    return UB_HTTP3_TX_ERROR;
}

static void
unblock_http3_consumer_require_transaction_owner(
    pTHX_
    unblock_http3_consumer_context *context,
    SV *transaction
)
{
    HV *hv = unblock_http3_consumer_transaction_hv(
        aTHX_ transaction
    );
    SV *owner = unblock_http3_consumer_fetch(
        aTHX_ hv,
        "connection",
        10,
        1
    );

    if (
        !SvOK(owner)
        || !SvROK(owner)
        || SvRV(owner) != SvRV(context->connection)
    ) {
        croak("Transaction does not belong to this Unblock::HTTP3 Connection");
    }
}

static void
unblock_http3_consumer_send_response(
    pTHX_
    void *opaque,
    SV *transaction
)
{
    unblock_http3_consumer_context *context =
        unblock_http3_consumer_require_context(aTHX_ opaque);

    unblock_http3_consumer_require_transaction_owner(
        aTHX_ context,
        transaction
    );

    unblock_http3_consumer_call_void_1(
        aTHX_
        context->send_response_cv,
        transaction
    );
}

static void
unblock_http3_consumer_send_informational(
    pTHX_
    void *opaque,
    SV *transaction,
    SV *response
)
{
    unblock_http3_consumer_context *context =
        unblock_http3_consumer_require_context(aTHX_ opaque);

    unblock_http3_consumer_require_transaction_owner(
        aTHX_ context,
        transaction
    );

    unblock_http3_consumer_call_void_2(
        aTHX_
        context->send_informational_cv,
        transaction,
        response
    );
}

static int
unblock_http3_consumer_failed(
    pTHX_ void *opaque
)
{
    unblock_http3_consumer_context *context =
        unblock_http3_consumer_require_context(aTHX_ opaque);
    SV *failed = unblock_http3_consumer_fetch(
        aTHX_ context->connection_hv,
        "failed",
        6,
        1
    );

    return SvTRUE(failed) ? 1 : 0;
}

static int
unblock_http3_consumer_error_code(
    pTHX_
    void *opaque,
    uint64_t *code
)
{
    unblock_http3_consumer_context *context =
        unblock_http3_consumer_require_context(aTHX_ opaque);
    SV *value = unblock_http3_consumer_fetch(
        aTHX_ context->connection_hv,
        "error_code",
        10,
        1
    );

    if (!SvOK(value)) {
        return 0;
    }

    if (code == NULL) {
        croak("Unblock::HTTP3 native ABI error-code output is NULL");
    }

    *code = (uint64_t)SvUV(value);
    return 1;
}

static SV *
unblock_http3_consumer_error(
    pTHX_ void *opaque
)
{
    unblock_http3_consumer_context *context =
        unblock_http3_consumer_require_context(aTHX_ opaque);
    SV *value = unblock_http3_consumer_fetch(
        aTHX_ context->connection_hv,
        "error",
        5,
        1
    );

    return SvOK(value) ? value : NULL;
}

static void
unblock_http3_consumer_destroy(
    pTHX_ void *opaque
)
{
    unblock_http3_consumer_context *context =
        (unblock_http3_consumer_context *)opaque;

    if (context == NULL) {
        return;
    }

    if (
        context->interpreter != unblock_http3_consumer_interpreter(aTHX)
    ) {
        croak("Unblock::HTTP3 native consumer context belongs to another interpreter");
    }

    if (context->connection != NULL) {
        SvREFCNT_dec(context->connection);
        context->connection = NULL;
    }

    context->connection_hv = NULL;
    context->service_cv = NULL;
    context->request_cv = NULL;
    context->send_response_cv = NULL;
    context->send_informational_cv = NULL;
    context->interpreter = NULL;

    Safefree(context);
}

static const ub_http3_consumer_ops_v1
unblock_http3_consumer_operations = {
    UB_HTTP3_CONSUMER_ABI_VERSION,
    sizeof(ub_http3_consumer_ops_v1),
    "Unblock::HTTP3 consumer ABI v1",
    &unblock_http3_consumer_create,
    &unblock_http3_consumer_service,
    &unblock_http3_consumer_request,
    &unblock_http3_consumer_next_transaction,
    &unblock_http3_consumer_next_informational,
    &unblock_http3_consumer_transaction_next_informational,
    &unblock_http3_consumer_transaction_request,
    &unblock_http3_consumer_transaction_response,
    &unblock_http3_consumer_transaction_stream_id,
    &unblock_http3_consumer_transaction_state,
    &unblock_http3_consumer_send_response,
    &unblock_http3_consumer_send_informational,
    &unblock_http3_consumer_failed,
    &unblock_http3_consumer_error_code,
    &unblock_http3_consumer_error,
    &unblock_http3_consumer_destroy
};

static nghttp3_nv *
unblock_http3_fields_from_sv(SV *fields_sv, size_t *pnvlen)
{
    AV *fields;
    SSize_t last;
    size_t nvlen;
    nghttp3_nv *nva;
    size_t i;

    if (!SvROK(fields_sv) || SvTYPE(SvRV(fields_sv)) != SVt_PVAV) {
        croak("HTTP fields must be an array reference");
    }

    fields = (AV *)SvRV(fields_sv);
    last = av_len(fields);
    nvlen = last < 0 ? 0 : (size_t)last + 1;

    if (nvlen == 0) {
        *pnvlen = 0;
        return NULL;
    }

    Newxz(nva, nvlen, nghttp3_nv);

    for (i = 0; i < nvlen; ++i) {
        SV **fieldp = av_fetch(fields, (SSize_t)i, 0);
        AV *field;
        SV **namep;
        SV **valuep;
        STRLEN namelen;
        STRLEN valuelen;
        const char *name;
        const char *value;

        if (
            fieldp == NULL ||
            !SvROK(*fieldp) ||
            SvTYPE(SvRV(*fieldp)) != SVt_PVAV
        ) {
            Safefree(nva);
            croak("each HTTP field must be a two-element array reference");
        }

        field = (AV *)SvRV(*fieldp);

        if (av_len(field) != 1) {
            Safefree(nva);
            croak("each HTTP field must contain exactly a name and value");
        }

        namep = av_fetch(field, 0, 0);
        valuep = av_fetch(field, 1, 0);

        if (namep == NULL || valuep == NULL) {
            Safefree(nva);
            croak("HTTP field name and value are required");
        }

        name = SvPVbyte(*namep, namelen);
        value = SvPVbyte(*valuep, valuelen);

        nva[i].name = (const uint8_t *)name;
        nva[i].value = (const uint8_t *)value;
        nva[i].namelen = (size_t)namelen;
        nva[i].valuelen = (size_t)valuelen;
        nva[i].flags = NGHTTP3_NV_FLAG_NONE;
    }

    *pnvlen = nvlen;
    return nva;
}

MODULE = Unblock::HTTP3    PACKAGE = Unblock::HTTP3::_Native

PROTOTYPES: DISABLE

BOOT:
    MY_CXT_INIT;
    if (!uhttp_native_init(
        aTHX_ &MY_CXT.uniform_api,
        UHTTP_NATIVE_ABI_VERSION
    ))
        croak("Uniform::HTTP native FastPath ABI mismatch");

void
CLONE(...)
    CODE:
        MY_CXT_CLONE;
        if (!uhttp_native_init(
            aTHX_ &MY_CXT.uniform_api,
            UHTTP_NATIVE_ABI_VERSION
        ))
            croak("Uniform::HTTP native FastPath clone ABI mismatch");


UV
_consumer_operations_address()
    CODE:
        RETVAL = PTR2UV(&unblock_http3_consumer_operations);
    OUTPUT:
        RETVAL

UV
_consumer_operations_size()
    CODE:
        RETVAL = (UV)sizeof(ub_http3_consumer_ops_v1);
    OUTPUT:
        RETVAL

int
_consumer_context_probe(connection)
    SV *connection
    PREINIT:
        void *context;
    CODE:
        context = unblock_http3_consumer_operations.create(
            aTHX_ connection
        );
        unblock_http3_consumer_operations.destroy(
            aTHX_ context
        );
        RETVAL = 1;
    OUTPUT:
        RETVAL


SV *
_consumer_transaction_probe(transaction)
    SV *transaction
    PREINIT:
        AV *out;
        SV *request;
        SV *response;
        SV *informational;
    CODE:
        request =
            unblock_http3_consumer_operations.transaction_request(
                aTHX_ transaction
            );
        response =
            unblock_http3_consumer_operations.transaction_response(
                aTHX_ transaction
            );
        informational =
            unblock_http3_consumer_operations.transaction_next_informational(
                aTHX_ transaction
            );

        out = newAV();
        av_push(
            out,
            newSViv(
                (IV)unblock_http3_consumer_operations.transaction_stream_id(
                    aTHX_ transaction
                )
            )
        );
        av_push(
            out,
            newSVuv(
                (UV)unblock_http3_consumer_operations.transaction_state(
                    aTHX_ transaction
                )
            )
        );
        av_push(out, newSVsv(request));
        av_push(
            out,
            response == NULL
                ? newSV(0)
                : newSVsv(response)
        );
        av_push(
            out,
            informational == NULL
                ? newSV(0)
                : informational
        );

        RETVAL = newRV_noinc((SV *)out);
    OUTPUT:
        RETVAL


SV *
_consumer_queue_probe(connection)
    SV *connection
    PREINIT:
        void *context;
        SV *transaction;
        SV *informational;
        SV *error;
        uint64_t code;
        int has_code;
        AV *out;
    CODE:
        context = unblock_http3_consumer_operations.create(
            aTHX_ connection
        );

        transaction =
            unblock_http3_consumer_operations.next_transaction(
                aTHX_ context
            );
        informational =
            unblock_http3_consumer_operations.next_informational(
                aTHX_ context
            );
        has_code =
            unblock_http3_consumer_operations.error_code(
                aTHX_ context,
                &code
            );
        error =
            unblock_http3_consumer_operations.error(
                aTHX_ context
            );

        out = newAV();
        av_push(
            out,
            transaction == NULL
                ? newSV(0)
                : transaction
        );
        av_push(
            out,
            informational == NULL
                ? newSV(0)
                : informational
        );
        av_push(
            out,
            newSViv(
                unblock_http3_consumer_operations.failed(
                    aTHX_ context
                )
            )
        );
        av_push(out, newSViv(has_code ? 1 : 0));
        av_push(
            out,
            has_code
                ? newSVuv((UV)code)
                : newSV(0)
        );
        av_push(
            out,
            error == NULL
                ? newSV(0)
                : newSVsv(error)
        );

        unblock_http3_consumer_operations.destroy(
            aTHX_ context
        );

        RETVAL = newRV_noinc((SV *)out);
    OUTPUT:
        RETVAL


SV *
_parse_priority(value)
    SV *value
    PREINIT:
        STRLEN len;
        const uint8_t *bytes;
        nghttp3_pri pri;
        AV *out;
        int rv;
    CODE:
        bytes = (const uint8_t *)SvPVbyte(value, len);

        pri.urgency = NGHTTP3_DEFAULT_URGENCY;
        pri.inc = 0;

        rv = nghttp3_pri_parse_priority(
            &pri,
            bytes,
            (size_t)len
        );

        if (rv != 0) {
            croak("invalid RFC 9218 Priority field");
        }

        out = newAV();
        av_push(out, newSVuv((UV)pri.urgency));
        av_push(out, newSViv(pri.inc ? 1 : 0));

        RETVAL = newRV_noinc((SV *)out);
    OUTPUT:
        RETVAL

const char *
_nghttp3_version()
    PREINIT:
        const nghttp3_info *info;
    CODE:
        info = nghttp3_version(0);
        if (info == NULL || info->version_str == NULL) {
            croak("could not read libnghttp3 version");
        }
        RETVAL = info->version_str;
    OUTPUT:
        RETVAL

SV *
_new_client(max_field_section_size, qpack_max_table_capacity, qpack_blocked_streams, enable_connect_protocol, h3_datagram)
    UV max_field_section_size
    UV qpack_max_table_capacity
    UV qpack_blocked_streams
    IV enable_connect_protocol
    IV h3_datagram
    CODE:
        if (
            (uint64_t)max_field_section_size > UNBLOCK_HTTP3_MAX_VARINT ||
            (uint64_t)qpack_max_table_capacity > UNBLOCK_HTTP3_MAX_VARINT ||
            (uint64_t)qpack_blocked_streams > UNBLOCK_HTTP3_MAX_VARINT
        ) {
            croak("HTTP/3 setting exceeds varint maximum");
        }

        RETVAL = unblock_http3_new_conn(
            0,
            (uint64_t)max_field_section_size,
            (uint64_t)qpack_max_table_capacity,
            (uint64_t)qpack_blocked_streams,
            enable_connect_protocol ? 1 : 0,
            h3_datagram ? 1 : 0,
            &PL_sv_undef
        );
    OUTPUT:
        RETVAL

SV *
_new_server(max_field_section_size, qpack_max_table_capacity, qpack_blocked_streams, enable_connect_protocol, h3_datagram, origin_list)
    UV max_field_section_size
    UV qpack_max_table_capacity
    UV qpack_blocked_streams
    IV enable_connect_protocol
    IV h3_datagram
    SV *origin_list
    CODE:
        if (
            (uint64_t)max_field_section_size > UNBLOCK_HTTP3_MAX_VARINT ||
            (uint64_t)qpack_max_table_capacity > UNBLOCK_HTTP3_MAX_VARINT ||
            (uint64_t)qpack_blocked_streams > UNBLOCK_HTTP3_MAX_VARINT
        ) {
            croak("HTTP/3 setting exceeds varint maximum");
        }

        RETVAL = unblock_http3_new_conn(
            1,
            (uint64_t)max_field_section_size,
            (uint64_t)qpack_max_table_capacity,
            (uint64_t)qpack_blocked_streams,
            enable_connect_protocol ? 1 : 0,
            h3_datagram ? 1 : 0,
            origin_list
        );
    OUTPUT:
        RETVAL

MODULE = Unblock::HTTP3    PACKAGE = Unblock::HTTP3::_Native::Connection

SV *
header_pseudo(self, stream_id, name)
    SV *self
    IV stream_id
    SV *name
    PREINIT:
        unblock_http3_native_conn *native;
        unblock_http3_header_block *block;
        STRLEN namelen;
        const char *name_bytes;
        const unblock_http3_captured_field *field;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        block = unblock_http3_header_block_find(
            native,
            (int64_t)stream_id
        );

        if (block == NULL) {
            croak("HTTP/3 stream has no pending header block");
        }

        name_bytes = SvPVbyte(name, namelen);
        field = unblock_http3_header_block_pseudo(
            block,
            name_bytes,
            (size_t)namelen
        );

        if (field == NULL) {
            XSRETURN_UNDEF;
        }

        RETVAL = newSVpvn(
            (const char *)field->value,
            (STRLEN)field->valuelen
        );
    OUTPUT:
        RETVAL

SV *
header_values(self, stream_id, name)
    SV *self
    IV stream_id
    SV *name
    PREINIT:
        unblock_http3_native_conn *native;
        unblock_http3_header_block *block;
        STRLEN namelen;
        const char *name_bytes;
        AV *values;
        size_t i;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        block = unblock_http3_header_block_find(
            native,
            (int64_t)stream_id
        );

        if (block == NULL) {
            croak("HTTP/3 stream has no pending header block");
        }

        name_bytes = SvPVbyte(name, namelen);
        values = newAV();

        for (i = 0; i < block->count; ++i) {
            const unblock_http3_captured_field *field =
                &block->fields[i];

            if (
                field->namelen != 0
                && field->name[0] == ':'
            ) {
                continue;
            }

            if (
                unblock_http3_captured_name_equal_ci(
                    field,
                    name_bytes,
                    (size_t)namelen
                )
            ) {
                av_push(
                    values,
                    newSVpvn(
                        (const char *)field->value,
                        (STRLEN)field->valuelen
                    )
                );
            }
        }

        RETVAL = newRV_noinc((SV *)values);
    OUTPUT:
        RETVAL

int
has_header(self, stream_id, name)
    SV *self
    IV stream_id
    SV *name
    PREINIT:
        unblock_http3_native_conn *native;
        unblock_http3_header_block *block;
        STRLEN namelen;
        const char *name_bytes;
        size_t i;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        block = unblock_http3_header_block_find(
            native,
            (int64_t)stream_id
        );

        if (block == NULL) {
            croak("HTTP/3 stream has no pending header block");
        }

        name_bytes = SvPVbyte(name, namelen);
        RETVAL = 0;

        for (i = 0; i < block->count; ++i) {
            const unblock_http3_captured_field *field =
                &block->fields[i];

            if (
                field->namelen != 0
                && field->name[0] == ':'
            ) {
                continue;
            }

            if (
                unblock_http3_captured_name_equal_ci(
                    field,
                    name_bytes,
                    (size_t)namelen
                )
            ) {
                RETVAL = 1;
                break;
            }
        }
    OUTPUT:
        RETVAL

SV *
receive_uniform_request(self, stream_id, method, target, scheme, authority, protocol, fin)
    SV *self
    IV stream_id
    SV *method
    SV *target
    SV *scheme
    SV *authority
    SV *protocol
    IV fin
    PREINIT:
        unblock_http3_native_conn *native;
        unblock_http3_header_block *block;
        unblock_http3_header_block *removed;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        block = unblock_http3_header_block_find(
            native,
            (int64_t)stream_id
        );

        if (block == NULL) {
            croak("HTTP/3 stream has no pending header block");
        }

        RETVAL = unblock_http3_header_block_uniform_request(
            aTHX_ block,
            method,
            target,
            scheme,
            authority,
            protocol,
            fin ? 1 : 0
        );

        removed = unblock_http3_header_block_remove(
            native,
            (int64_t)stream_id
        );
        unblock_http3_header_block_free(removed);
    OUTPUT:
        RETVAL

SV *
receive_uniform_response(self, stream_id, status, fin)
    SV *self
    IV stream_id
    IV status
    IV fin
    PREINIT:
        unblock_http3_native_conn *native;
        unblock_http3_header_block *block;
        unblock_http3_header_block *removed;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        block = unblock_http3_header_block_find(
            native,
            (int64_t)stream_id
        );

        if (block == NULL) {
            croak("HTTP/3 stream has no pending header block");
        }

        RETVAL = unblock_http3_header_block_uniform_response(
            aTHX_ block,
            status,
            fin ? 1 : 0
        );

        removed = unblock_http3_header_block_remove(
            native,
            (int64_t)stream_id
        );
        unblock_http3_header_block_free(removed);
    OUTPUT:
        RETVAL

void
discard_header_block(self, stream_id)
    SV *self
    IV stream_id
    PREINIT:
        unblock_http3_native_conn *native;
        unblock_http3_header_block *block;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        block = unblock_http3_header_block_remove(
            native,
            (int64_t)stream_id
        );
        unblock_http3_header_block_free(block);

const char *
role(self)
    SV *self
    PREINIT:
        unblock_http3_native_conn *native;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        RETVAL = native->is_server ? "server" : "client";
    OUTPUT:
        RETVAL

void
set_max_client_streams_bidi(self, max_streams)
    SV *self
    UV max_streams
    PREINIT:
        unblock_http3_native_conn *native;
    CODE:
        native = unblock_http3_conn_from_sv(self);

        if (!native->is_server) {
            croak("client stream limit synchronization requires a server connection");
        }

        nghttp3_conn_set_max_client_streams_bidi(
            native->conn,
            (uint64_t)max_streams
        );

void
set_client_stream_priority(self, stream_id, value)
    SV *self
    IV stream_id
    SV *value
    PREINIT:
        unblock_http3_native_conn *native;
        STRLEN len;
        const uint8_t *bytes;
        int rv;
    CODE:
        native = unblock_http3_conn_from_sv(self);

        if (native->is_server) {
            croak("client stream priority update requires a client connection");
        }

        bytes = (const uint8_t *)SvPVbyte(value, len);

        rv = nghttp3_conn_set_client_stream_priority(
            native->conn,
            (int64_t)stream_id,
            bytes,
            (size_t)len
        );

        if (rv != 0) {
            unblock_http3_fail("could not update client HTTP priority", rv);
        }

SV *
get_server_stream_priority(self, stream_id)
    SV *self
    IV stream_id
    PREINIT:
        unblock_http3_native_conn *native;
        nghttp3_pri pri;
        AV *out;
        int rv;
    CODE:
        native = unblock_http3_conn_from_sv(self);

        if (!native->is_server) {
            croak("stream priority inspection requires a server connection");
        }

        rv = nghttp3_conn_get_stream_priority2(
            native->conn,
            &pri,
            (int64_t)stream_id
        );

        if (rv != 0) {
            unblock_http3_fail("could not inspect HTTP stream priority", rv);
        }

        out = newAV();
        av_push(out, newSVuv((UV)pri.urgency));
        av_push(out, newSViv(pri.inc ? 1 : 0));

        RETVAL = newRV_noinc((SV *)out);
    OUTPUT:
        RETVAL

void
set_server_stream_priority(self, stream_id, urgency, incremental)
    SV *self
    IV stream_id
    UV urgency
    IV incremental
    PREINIT:
        unblock_http3_native_conn *native;
        nghttp3_pri pri;
        int rv;
    CODE:
        native = unblock_http3_conn_from_sv(self);

        if (!native->is_server) {
            croak("server stream priority override requires a server connection");
        }

        if (urgency > NGHTTP3_URGENCY_LOW) {
            croak("HTTP urgency must be from 0 through 7");
        }

        if (incremental != 0 && incremental != 1) {
            croak("HTTP incremental priority must be 0 or 1");
        }

        pri.urgency = (uint32_t)urgency;
        pri.inc = incremental ? 1 : 0;

        rv = nghttp3_conn_set_server_stream_priority(
            native->conn,
            (int64_t)stream_id,
            &pri
        );

        if (rv != 0) {
            unblock_http3_fail("could not override server HTTP priority", rv);
        }

void
bind_streams(self, control_stream_id, qenc_stream_id, qdec_stream_id)
    SV *self
    IV control_stream_id
    IV qenc_stream_id
    IV qdec_stream_id
    PREINIT:
        unblock_http3_native_conn *native;
        int rv;
    CODE:
        native = unblock_http3_conn_from_sv(self);

        rv = nghttp3_conn_bind_control_stream(
            native->conn,
            (int64_t)control_stream_id
        );
        if (rv != 0) {
            unblock_http3_fail("could not bind HTTP/3 control stream", rv);
        }

        rv = nghttp3_conn_bind_qpack_streams(
            native->conn,
            (int64_t)qenc_stream_id,
            (int64_t)qdec_stream_id
        );
        if (rv != 0) {
            unblock_http3_fail("could not bind HTTP/3 QPACK streams", rv);
        }

SV *
read_stream(self, stream_id, bytes, fin, timestamp)
    SV *self
    IV stream_id
    SV *bytes
    IV fin
    UV timestamp
    PREINIT:
        unblock_http3_native_conn *native;
        STRLEN len;
        const char *data;
        nghttp3_ssize rv;
        AV *out;
        uint64_t app_error_code;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        data = SvPVbyte(bytes, len);

        rv = nghttp3_conn_read_stream2(
            native->conn,
            (int64_t)stream_id,
            (const uint8_t *)data,
            (size_t)len,
            fin ? 1 : 0,
            (nghttp3_tstamp)timestamp
        );

        out = newAV();

        if (rv < 0) {
            native->fatal = 1;
            app_error_code =
                nghttp3_err_infer_quic_app_error_code((int)rv);

            av_push(out, newSV(0));
            av_push(out, newSViv((IV)rv));
            av_push(out, newSVuv((UV)app_error_code));
            av_push(out, newSVpv(nghttp3_strerror((int)rv), 0));
        } else {
            av_push(out, newSViv((IV)rv));
        }

        RETVAL = newRV_noinc((SV *)out);
    OUTPUT:
        RETVAL

SV *
next_write(self)
    SV *self
    PREINIT:
        unblock_http3_native_conn *native;
        nghttp3_vec vec[16];
        nghttp3_ssize nvec;
        int64_t stream_id;
        int fin;
        SV *payload;
        AV *out;
        nghttp3_ssize i;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        stream_id = -1;
        fin = 0;

        nvec = nghttp3_conn_writev_stream(
            native->conn,
            &stream_id,
            &fin,
            vec,
            16
        );

        if (nvec < 0) {
            unblock_http3_fail("could not obtain HTTP/3 output", (int)nvec);
        }

        if (nvec == 0 && stream_id == -1) {
            XSRETURN_UNDEF;
        }

        payload = newSVpvn("", 0);

        for (i = 0; i < nvec; ++i) {
            sv_catpvn(
                payload,
                (const char *)vec[i].base,
                (STRLEN)vec[i].len
            );
        }

        out = newAV();
        av_push(out, newSViv((IV)stream_id));
        av_push(out, payload);
        av_push(out, newSViv(fin ? 1 : 0));

        RETVAL = newRV_noinc((SV *)out);
    OUTPUT:
        RETVAL

void
add_write_offset(self, stream_id, amount)
    SV *self
    IV stream_id
    UV amount
    PREINIT:
        unblock_http3_native_conn *native;
        int rv;
    CODE:
        native = unblock_http3_conn_from_sv(self);

        rv = nghttp3_conn_add_write_offset(
            native->conn,
            (int64_t)stream_id,
            (size_t)amount
        );

        if (rv != 0) {
            unblock_http3_fail("could not advance HTTP/3 write offset", rv);
        }

void
update_ack_offset(self, stream_id, offset)
    SV *self
    IV stream_id
    UV offset
    PREINIT:
        unblock_http3_native_conn *native;
        int rv;
    CODE:
        native = unblock_http3_conn_from_sv(self);

        rv = nghttp3_conn_update_ack_offset(
            native->conn,
            (int64_t)stream_id,
            (uint64_t)offset
        );

        if (rv != 0) {
            unblock_http3_fail("could not update HTTP/3 acknowledgement offset", rv);
        }

void
submit_shutdown_notice(self)
    SV *self
    PREINIT:
        unblock_http3_native_conn *native;
        int rv;
    CODE:
        native = unblock_http3_conn_from_sv(self);

        rv = nghttp3_conn_submit_shutdown_notice(native->conn);

        if (rv != 0) {
            unblock_http3_fail("could not submit HTTP/3 shutdown notice", rv);
        }

void
begin_shutdown(self)
    SV *self
    PREINIT:
        unblock_http3_native_conn *native;
        int rv;
    CODE:
        native = unblock_http3_conn_from_sv(self);

        rv = nghttp3_conn_shutdown(native->conn);

        if (rv != 0) {
            unblock_http3_fail("could not begin HTTP/3 shutdown", rv);
        }

int
is_drained(self)
    SV *self
    PREINIT:
        unblock_http3_native_conn *native;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        RETVAL = nghttp3_conn_is_drained2(native->conn) ? 1 : 0;
    OUTPUT:
        RETVAL

void
shutdown_stream_read(self, stream_id)
    SV *self
    IV stream_id
    PREINIT:
        unblock_http3_native_conn *native;
        int rv;
    CODE:
        native = unblock_http3_conn_from_sv(self);

        rv = nghttp3_conn_shutdown_stream_read(
            native->conn,
            (int64_t)stream_id
        );

        if (rv != 0) {
            unblock_http3_fail("could not shut down HTTP/3 stream read side", rv);
        }

void
shutdown_stream_write(self, stream_id)
    SV *self
    IV stream_id
    PREINIT:
        unblock_http3_native_conn *native;
    CODE:
        native = unblock_http3_conn_from_sv(self);

        nghttp3_conn_shutdown_stream_write(
            native->conn,
            (int64_t)stream_id
        );

void
close_stream(self, stream_id, rx_error = &PL_sv_undef, tx_error = &PL_sv_undef)
    SV *self
    IV stream_id
    SV *rx_error
    SV *tx_error
    PREINIT:
        unblock_http3_native_conn *native;
        uint32_t flags;
        uint64_t rx_code;
        uint64_t tx_code;
        int rv;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        flags = 0;
        rx_code = 0;
        tx_code = 0;

        if (SvOK(rx_error)) {
            flags |= NGHTTP3_STREAM_CLOSE_FLAG_RX_APP_ERROR_CODE_SET;
            rx_code = (uint64_t)SvUV(rx_error);
        }

        if (SvOK(tx_error)) {
            flags |= NGHTTP3_STREAM_CLOSE_FLAG_TX_APP_ERROR_CODE_SET;
            tx_code = (uint64_t)SvUV(tx_error);
        }

        rv = nghttp3_conn_close_stream2(
            native->conn,
            flags,
            (int64_t)stream_id,
            rx_code,
            tx_code
        );

        if (rv != 0 && rv != NGHTTP3_ERR_STREAM_NOT_FOUND) {
            unblock_http3_fail("could not close HTTP/3 stream", rv);
        }

        unblock_http3_body_remove(
            native,
            (int64_t)stream_id
        );


UV
uniform_request_field_section_size(self, message)
    SV *self
    SV *message
    PREINIT:
        unblock_http3_native_conn *native;
        uhttp_native_view view;
        size_t size;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        (void)native;
        unblock_http3_uniform_view(
            aTHX_ message,
            UHTTP_KIND_REQUEST,
            &view
        );
        unblock_http3_uniform_validate_section(
            aTHX_ &view.headers,
            0
        );
        size = unblock_http3_uniform_request_size(
            aTHX_ &view
        );
        RETVAL = (UV)size;
    OUTPUT:
        RETVAL

UV
uniform_response_field_section_size(self, message)
    SV *self
    SV *message
    PREINIT:
        unblock_http3_native_conn *native;
        uhttp_native_view view;
        size_t size;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        (void)native;
        unblock_http3_uniform_view(
            aTHX_ message,
            UHTTP_KIND_RESPONSE,
            &view
        );
        unblock_http3_uniform_validate_section(
            aTHX_ &view.headers,
            1
        );
        size = unblock_http3_uniform_response_size(
            aTHX_ &view
        );
        RETVAL = (UV)size;
    OUTPUT:
        RETVAL

UV
uniform_trailer_field_section_size(self, message)
    SV *self
    SV *message
    PREINIT:
        unblock_http3_native_conn *native;
        uhttp_native_view view;
        size_t size;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        (void)native;

        unblock_http3_uniform_any_view(
            aTHX_ message,
            &view
        );

        unblock_http3_uniform_validate_section(
            aTHX_ &view.trailers,
            2
        );
        size = unblock_http3_uniform_section_size(
            aTHX_ &view.trailers
        );
        RETVAL = (UV)size;
    OUTPUT:
        RETVAL

void
submit_uniform_request(self, stream_id, message, streaming = 0)
    SV *self
    IV stream_id
    SV *message
    IV streaming
    PREINIT:
        unblock_http3_native_conn *native;
        uhttp_native_view view;
        unblock_http3_uniform_fields headers;
        unblock_http3_uniform_fields trailers;
        unblock_http3_body *body_ctx;
        const nghttp3_data_reader *reader;
        Size_t trailer_count;
        int rv;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        unblock_http3_uniform_view(
            aTHX_ message,
            UHTTP_KIND_REQUEST,
            &view
        );
        unblock_http3_uniform_request_fields(
            aTHX_ &view,
            &headers
        );
        unblock_http3_uniform_trailer_fields(
            aTHX_ &view,
            &trailers
        );
        trailer_count = uhttp_native_field_count(
            aTHX_ &view.trailers
        );
        body_ctx = NULL;
        reader = NULL;

        if (
            (view.flags & UHTTP_HAS_BUFFERED_BODY)
            || streaming
            || trailer_count != 0
        ) {
            body_ctx = unblock_http3_body_create(
                native,
                (int64_t)stream_id,
                streaming ? 1 : 0
            );

            if (view.flags & UHTTP_HAS_BUFFERED_BODY) {
                unblock_http3_body_append(
                    native,
                    body_ctx,
                    view.body
                );
            }

            if (!streaming) {
                body_ctx->eof = 1;
            }

            reader = &unblock_http3_body_reader;
        }

        rv = nghttp3_conn_submit_request(
            native->conn,
            (int64_t)stream_id,
            headers.nva,
            headers.nvlen,
            reader,
            body_ctx
        );

        unblock_http3_uniform_fields_free(&headers);

        if (rv != 0) {
            unblock_http3_uniform_fields_free(&trailers);
            if (body_ctx != NULL) {
                unblock_http3_body_remove(
                    native,
                    (int64_t)stream_id
                );
            }
            unblock_http3_fail("could not submit HTTP/3 request", rv);
        }

        if (trailers.nvlen != 0) {
            rv = nghttp3_conn_submit_trailers(
                native->conn,
                (int64_t)stream_id,
                trailers.nva,
                trailers.nvlen
            );

            unblock_http3_uniform_fields_free(&trailers);

            if (rv != 0) {
                unblock_http3_fail(
                    "could not submit HTTP/3 request trailers",
                    rv
                );
            }
        } else {
            unblock_http3_uniform_fields_free(&trailers);
        }

void
submit_uniform_info(self, stream_id, message)
    SV *self
    IV stream_id
    SV *message
    PREINIT:
        unblock_http3_native_conn *native;
        uhttp_native_view view;
        unblock_http3_uniform_fields fields;
        char status_buffer[4];
        int rv;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        unblock_http3_uniform_view(
            aTHX_ message,
            UHTTP_KIND_RESPONSE,
            &view
        );
        unblock_http3_uniform_response_fields(
            aTHX_ &view,
            &fields,
            status_buffer
        );

        rv = nghttp3_conn_submit_info(
            native->conn,
            (int64_t)stream_id,
            fields.nva,
            fields.nvlen
        );

        unblock_http3_uniform_fields_free(&fields);

        if (rv != 0) {
            unblock_http3_fail(
                "could not submit HTTP/3 informational response",
                rv
            );
        }

void
submit_uniform_response(self, stream_id, message, streaming = 0)
    SV *self
    IV stream_id
    SV *message
    IV streaming
    PREINIT:
        unblock_http3_native_conn *native;
        uhttp_native_view view;
        unblock_http3_uniform_fields headers;
        unblock_http3_uniform_fields trailers;
        unblock_http3_body *body_ctx;
        const nghttp3_data_reader *reader;
        Size_t trailer_count;
        char status_buffer[4];
        int rv;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        unblock_http3_uniform_view(
            aTHX_ message,
            UHTTP_KIND_RESPONSE,
            &view
        );
        unblock_http3_uniform_response_fields(
            aTHX_ &view,
            &headers,
            status_buffer
        );
        unblock_http3_uniform_trailer_fields(
            aTHX_ &view,
            &trailers
        );
        trailer_count = uhttp_native_field_count(
            aTHX_ &view.trailers
        );
        body_ctx = NULL;
        reader = NULL;

        if (
            (view.flags & UHTTP_HAS_BUFFERED_BODY)
            || streaming
            || trailer_count != 0
        ) {
            body_ctx = unblock_http3_body_create(
                native,
                (int64_t)stream_id,
                streaming ? 1 : 0
            );

            if (view.flags & UHTTP_HAS_BUFFERED_BODY) {
                unblock_http3_body_append(
                    native,
                    body_ctx,
                    view.body
                );
            }

            if (!streaming) {
                body_ctx->eof = 1;
            }

            reader = &unblock_http3_body_reader;

            rv = nghttp3_conn_set_stream_user_data(
                native->conn,
                (int64_t)stream_id,
                body_ctx
            );

            if (rv != 0) {
                unblock_http3_uniform_fields_free(&headers);
                unblock_http3_uniform_fields_free(&trailers);
                unblock_http3_body_remove(
                    native,
                    (int64_t)stream_id
                );
                unblock_http3_fail(
                    "could not attach HTTP/3 response body",
                    rv
                );
            }
        }

        rv = nghttp3_conn_submit_response(
            native->conn,
            (int64_t)stream_id,
            headers.nva,
            headers.nvlen,
            reader
        );

        unblock_http3_uniform_fields_free(&headers);

        if (rv != 0) {
            unblock_http3_uniform_fields_free(&trailers);
            if (body_ctx != NULL) {
                unblock_http3_body_remove(
                    native,
                    (int64_t)stream_id
                );
            }
            unblock_http3_fail("could not submit HTTP/3 response", rv);
        }

        if (trailers.nvlen != 0) {
            rv = nghttp3_conn_submit_trailers(
                native->conn,
                (int64_t)stream_id,
                trailers.nva,
                trailers.nvlen
            );

            unblock_http3_uniform_fields_free(&trailers);

            if (rv != 0) {
                unblock_http3_fail(
                    "could not submit HTTP/3 response trailers",
                    rv
                );
            }
        } else {
            unblock_http3_uniform_fields_free(&trailers);
        }

void
submit_request(self, stream_id, fields, body = &PL_sv_undef, streaming = 0)
    SV *self
    IV stream_id
    SV *fields
    SV *body
    IV streaming
    PREINIT:
        unblock_http3_native_conn *native;
        unblock_http3_body *body_ctx;
        const nghttp3_data_reader *reader;
        nghttp3_nv *nva;
        size_t nvlen;
        int rv;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        nva = unblock_http3_fields_from_sv(fields, &nvlen);
        body_ctx = NULL;
        reader = NULL;

        if (SvOK(body) || streaming) {
            body_ctx = unblock_http3_body_create(
                native,
                (int64_t)stream_id,
                streaming ? 1 : 0
            );

            if (SvOK(body)) {
                unblock_http3_body_append(native, body_ctx, body);
                body_ctx->eof = 1;
            }

            reader = &unblock_http3_body_reader;
        }

        rv = nghttp3_conn_submit_request(
            native->conn,
            (int64_t)stream_id,
            nva,
            nvlen,
            reader,
            body_ctx
        );

        if (nva != NULL) {
            Safefree(nva);
        }

        if (rv != 0) {
            unblock_http3_fail("could not submit HTTP/3 request", rv);
        }

void
submit_info(self, stream_id, fields)
    SV *self
    IV stream_id
    SV *fields
    PREINIT:
        unblock_http3_native_conn *native;
        nghttp3_nv *nva;
        size_t nvlen;
        int rv;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        nva = unblock_http3_fields_from_sv(fields, &nvlen);

        rv = nghttp3_conn_submit_info(
            native->conn,
            (int64_t)stream_id,
            nva,
            nvlen
        );

        if (nva != NULL) {
            Safefree(nva);
        }

        if (rv != 0) {
            unblock_http3_fail(
                "could not submit HTTP/3 informational response",
                rv
            );
        }

void
submit_response(self, stream_id, fields, body = &PL_sv_undef, streaming = 0)
    SV *self
    IV stream_id
    SV *fields
    SV *body
    IV streaming
    PREINIT:
        unblock_http3_native_conn *native;
        unblock_http3_body *body_ctx;
        const nghttp3_data_reader *reader;
        nghttp3_nv *nva;
        size_t nvlen;
        int rv;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        nva = unblock_http3_fields_from_sv(fields, &nvlen);
        body_ctx = NULL;
        reader = NULL;

        if (SvOK(body) || streaming) {
            body_ctx = unblock_http3_body_create(
                native,
                (int64_t)stream_id,
                streaming ? 1 : 0
            );

            if (SvOK(body)) {
                unblock_http3_body_append(native, body_ctx, body);
                body_ctx->eof = 1;
            }

            reader = &unblock_http3_body_reader;

            rv = nghttp3_conn_set_stream_user_data(
                native->conn,
                (int64_t)stream_id,
                body_ctx
            );

            if (rv != 0) {
                if (nva != NULL) {
                    Safefree(nva);
                }
                unblock_http3_fail(
                    "could not attach HTTP/3 response body",
                    rv
                );
            }
        }

        rv = nghttp3_conn_submit_response(
            native->conn,
            (int64_t)stream_id,
            nva,
            nvlen,
            reader
        );

        if (nva != NULL) {
            Safefree(nva);
        }

        if (rv != 0) {
            unblock_http3_fail("could not submit HTTP/3 response", rv);
        }

UV
append_body(self, stream_id, bytes, final)
    SV *self
    IV stream_id
    SV *bytes
    IV final
    PREINIT:
        unblock_http3_native_conn *native;
        unblock_http3_body *body;
        size_t appended;
        int rv;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        body = unblock_http3_body_find(native, (int64_t)stream_id);

        if (body == NULL || !body->streaming) {
            croak("HTTP/3 stream does not have an incremental body");
        }

        if (body->eof) {
            croak("HTTP/3 incremental body is already complete");
        }

        appended = unblock_http3_body_append(native, body, bytes);

        if (final) {
            body->eof = 1;
        }

        rv = nghttp3_conn_resume_stream(
            native->conn,
            (int64_t)stream_id
        );

        if (rv != 0) {
            unblock_http3_fail("could not resume HTTP/3 body stream", rv);
        }

        RETVAL = (UV)appended;
    OUTPUT:
        RETVAL

void
discard_body(self, stream_id)
    SV *self
    IV stream_id
    PREINIT:
        unblock_http3_native_conn *native;
        unblock_http3_body *body;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        body = unblock_http3_body_find(native, (int64_t)stream_id);
        unblock_http3_body_discard(native, body);

UV
streaming_retained_bytes(self)
    SV *self
    PREINIT:
        unblock_http3_native_conn *native;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        RETVAL = (UV)native->streaming_retained_bytes;
    OUTPUT:
        RETVAL

void
submit_trailers(self, stream_id, fields)
    SV *self
    IV stream_id
    SV *fields
    PREINIT:
        unblock_http3_native_conn *native;
        nghttp3_nv *nva;
        size_t nvlen;
        int rv;
    CODE:
        native = unblock_http3_conn_from_sv(self);
        nva = unblock_http3_fields_from_sv(fields, &nvlen);

        rv = nghttp3_conn_submit_trailers(
            native->conn,
            (int64_t)stream_id,
            nva,
            nvlen
        );

        if (nva != NULL) {
            Safefree(nva);
        }

        if (rv != 0) {
            unblock_http3_fail("could not submit HTTP/3 trailers", rv);
        }

SV *
next_event(self)
    SV *self
    PREINIT:
        unblock_http3_native_conn *native;
        SV *event;
    CODE:
        native = unblock_http3_conn_from_sv(self);

        if (av_len(native->events) < 0) {
            XSRETURN_UNDEF;
        }

        event = av_shift(native->events);

        if (event == NULL) {
            XSRETURN_UNDEF;
        }

        RETVAL = event;
    OUTPUT:
        RETVAL

void
DESTROY(self)
    SV *self
    PREINIT:
        unblock_http3_native_conn *native;
    CODE:
        if (!SvROK(self)) {
            XSRETURN_EMPTY;
        }

        native = INT2PTR(
            unblock_http3_native_conn *,
            SvIV(SvRV(self))
        );

        if (native != NULL) {
            if (native->conn != NULL) {
                nghttp3_conn_del(native->conn);
                native->conn = NULL;
            }

            if (native->events != NULL) {
                SvREFCNT_dec((SV *)native->events);
                native->events = NULL;
            }

            if (native->origin_list_data != NULL) {
                Safefree(native->origin_list_data);
                native->origin_list_data = NULL;
            }

            unblock_http3_body_free_all(native);
            unblock_http3_header_block_free_all(native);
            Safefree(native);
            sv_setiv(SvRV(self), 0);
        }