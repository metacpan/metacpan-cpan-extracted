#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <nghttp3/nghttp3.h>

#include <inttypes.h>

#define UNBLOCK_HTTP3_MAX_VARINT UINT64_C(0x3fffffffffffffff)

typedef struct unblock_http3_body_chunk {
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
    nghttp3_conn *conn;
    AV *events;
    unblock_http3_body *bodies;
    size_t streaming_retained_bytes;
    int is_server;
    int fatal;
} unblock_http3_native_conn;

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

static size_t
unblock_http3_body_append(
    unblock_http3_native_conn *native,
    unblock_http3_body *body,
    SV *body_sv
)
{
    unblock_http3_body_chunk *chunk;
    STRLEN len;
    const char *bytes = SvPVbyte(body_sv, len);

    if (len == 0) {
        return 0;
    }

    Newxz(chunk, 1, unblock_http3_body_chunk);
    Newx(chunk->data, len, uint8_t);
    Copy(bytes, chunk->data, len, uint8_t);

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

        if (chunk->data != NULL) {
            Safefree(chunk->data);
        }

        Safefree(chunk);
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

                if (chunk->data != NULL) {
                    Safefree(chunk->data);
                }

                Safefree(chunk);
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

            if (chunk->data != NULL) {
                Safefree(chunk->data);
            }

            Safefree(chunk);
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

            Safefree(chunk->data);
            Safefree(chunk);
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

    unblock_http3_push_event(
        native,
        unblock_http3_event_new("begin_headers", stream_id)
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
    nghttp3_vec nbuf = nghttp3_rcbuf_get_buf(name);
    nghttp3_vec vbuf = nghttp3_rcbuf_get_buf(value);
    AV *event = unblock_http3_event_new("header", stream_id);

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
    AV *event = unblock_http3_event_new("end_headers", stream_id);

    (void)conn;
    (void)stream_user_data;

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
    int h3_datagram
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
        Safefree(native);
        unblock_http3_fail("could not create libnghttp3 connection", rv);
    }

    native->is_server = is_server ? 1 : 0;

    return unblock_http3_bless_conn(native);
}

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
            h3_datagram ? 1 : 0
        );
    OUTPUT:
        RETVAL

SV *
_new_server(max_field_section_size, qpack_max_table_capacity, qpack_blocked_streams, enable_connect_protocol, h3_datagram)
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
            1,
            (uint64_t)max_field_section_size,
            (uint64_t)qpack_max_table_capacity,
            (uint64_t)qpack_blocked_streams,
            enable_connect_protocol ? 1 : 0,
            h3_datagram ? 1 : 0
        );
    OUTPUT:
        RETVAL

MODULE = Unblock::HTTP3    PACKAGE = Unblock::HTTP3::_Native::Connection

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

            unblock_http3_body_free_all(native);
            Safefree(native);
            sv_setiv(SvRV(self), 0);
        }