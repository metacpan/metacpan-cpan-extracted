#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <errno.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "include/unblock_websocket_native.h"

#if defined(_WIN32)
#  define WIN32_LEAN_AND_MEAN
#  define NOMINMAX
#  include <windows.h>
#  include <bcrypt.h>
#elif defined(__APPLE__) || defined(__FreeBSD__) || defined(__OpenBSD__) \
   || defined(__NetBSD__) || defined(__DragonFly__)
#  include <stdlib.h>
#elif defined(__linux__)
#  include <sys/random.h>
#else
#  include <fcntl.h>
#  include <unistd.h>
#endif

static int
unblock_ws_secure_random(void *buffer, size_t length)
{
#if defined(_WIN32)
    unsigned char *out = (unsigned char *)buffer;
    while (length > 0) {
        ULONG chunk = length > 0xffffffffUL ? 0xffffffffUL : (ULONG)length;
        NTSTATUS status = BCryptGenRandom(
            NULL, (PUCHAR)out, chunk, BCRYPT_USE_SYSTEM_PREFERRED_RNG
        );
        if (status != 0)
            return 0;
        out += chunk;
        length -= chunk;
    }
    return 1;
#elif defined(__APPLE__) || defined(__FreeBSD__) || defined(__OpenBSD__) \
   || defined(__NetBSD__) || defined(__DragonFly__)
    arc4random_buf(buffer, length);
    return 1;
#elif defined(__linux__)
    unsigned char *out = (unsigned char *)buffer;
    while (length > 0) {
        ssize_t n = getrandom(out, length, 0);
        if (n < 0) {
            if (errno == EINTR)
                continue;
            return 0;
        }
        if (n == 0)
            return 0;
        out += (size_t)n;
        length -= (size_t)n;
    }
    return 1;
#else
    int fd;
    unsigned char *out = (unsigned char *)buffer;

    do {
        fd = open("/dev/urandom", O_RDONLY);
    } while (fd < 0 && errno == EINTR);
    if (fd < 0)
        return 0;

    while (length > 0) {
        ssize_t n = read(fd, out, length);
        if (n < 0) {
            if (errno == EINTR)
                continue;
            close(fd);
            return 0;
        }
        if (n == 0) {
            close(fd);
            return 0;
        }
        out += (size_t)n;
        length -= (size_t)n;
    }
    close(fd);
    return 1;
#endif
}

#define BQWS_SINGLE_THREAD 1
#define BQWS_DEBUG 0
#define bqws_mutex int
#define bqws_mutex_init(m) ((void)(m))
#define bqws_mutex_free(m) ((void)(m))
#define bqws_mutex_lock(m) ((void)(m))
#define bqws_mutex_unlock(m) ((void)(m))
#define bqws_assert_locked(m) ((void)(m))
#include "vendor/bq_websocket/bq_websocket.c"

typedef struct {
    bqws_socket *ws;
} unblock_ws_native;

static unblock_ws_native *
unblock_ws_native_create(uint32_t role, size_t max_message_size)
{
    unblock_ws_native *state;
    bqws_opts opts;

    if (role != UNBLOCK_WEBSOCKET_ROLE_CLIENT
        && role != UNBLOCK_WEBSOCKET_ROLE_SERVER)
        return NULL;
    if (max_message_size == 0)
        return NULL;

    state = (unblock_ws_native *)calloc(1, sizeof(*state));
    if (state == NULL)
        return NULL;

    memset(&opts, 0, sizeof(opts));
    opts.skip_handshake = true;
    opts.recv_control_messages = true;
    opts.ping_interval = SIZE_MAX;
    opts.connect_timeout = SIZE_MAX;
    opts.close_timeout = SIZE_MAX;
    opts.ping_response_timeout = SIZE_MAX;
    opts.limits.max_memory_used = SIZE_MAX;
    opts.limits.max_recv_msg_size = max_message_size;
    opts.limits.max_recv_queue_messages = SIZE_MAX;
    opts.limits.max_recv_queue_size = SIZE_MAX;
    opts.limits.max_partial_message_parts = SIZE_MAX;

    if (role == UNBLOCK_WEBSOCKET_ROLE_CLIENT)
        state->ws = bqws_new_client(&opts, NULL);
    else
        state->ws = bqws_new_server(&opts, NULL);

    if (state->ws == NULL) {
        free(state);
        return NULL;
    }

    return state;
}

static void
unblock_ws_native_destroy(void *opaque)
{
    unblock_ws_native *state = (unblock_ws_native *)opaque;
    if (state == NULL)
        return;
    if (state->ws != NULL) {
        bqws_free_socket(state->ws);
        state->ws = NULL;
    }
    free(state);
}

static uint32_t
unblock_ws_event_code(bqws_msg_type type)
{
    switch (type) {
    case BQWS_MSG_TEXT:          return UNBLOCK_WEBSOCKET_EVENT_TEXT;
    case BQWS_MSG_BINARY:        return UNBLOCK_WEBSOCKET_EVENT_BINARY;
    case BQWS_MSG_CONTROL_CLOSE: return UNBLOCK_WEBSOCKET_EVENT_CLOSE;
    case BQWS_MSG_CONTROL_PING:  return UNBLOCK_WEBSOCKET_EVENT_PING;
    case BQWS_MSG_CONTROL_PONG:  return UNBLOCK_WEBSOCKET_EVENT_PONG;
    default:                     return 0;
    }
}

typedef struct {
    unblock_websocket_event_fn fn;
    void *user;
} unblock_ws_legacy_event;

static int
unblock_ws_legacy_event_adapter(
    void *user,
    uint32_t event,
    uint32_t flags,
    const char *data,
    size_t length
)
{
    unblock_ws_legacy_event *legacy = (unblock_ws_legacy_event *)user;

    if (flags != 0)
        return UNBLOCK_WEBSOCKET_ERROR;

    if (legacy->fn == NULL)
        return UNBLOCK_WEBSOCKET_OK;

    return legacy->fn(legacy->user, event, data, length);
}

static int
unblock_ws_native_input_ex(
    void *opaque,
    const char *data,
    size_t length,
    size_t *consumed,
    unblock_websocket_event_ex_fn event_fn,
    void *event_user
)
{
    unblock_ws_native *state = (unblock_ws_native *)opaque;
    size_t used = 0;
    bqws_msg *msg;

    if (consumed == NULL)
        return UNBLOCK_WEBSOCKET_ERROR;
    *consumed = 0;

    if (state == NULL || state->ws == NULL || (length > 0 && data == NULL))
        return UNBLOCK_WEBSOCKET_ERROR;

    while (used < length) {
        size_t n = bqws_read_from(state->ws, data + used, length - used);
        if (n == 0)
            break;
        used += n;
        if (bqws_get_error(state->ws) != BQWS_OK
            || bqws_get_state(state->ws) >= BQWS_STATE_CLOSING)
            break;
    }
    *consumed = used;

    while ((msg = bqws_recv(state->ws)) != NULL) {
        uint32_t event = unblock_ws_event_code(msg->type);
        uint32_t flags = (msg_imp(msg))->compressed
            ? UNBLOCK_WEBSOCKET_MESSAGE_COMPRESSED : 0U;
        int callback_result = UNBLOCK_WEBSOCKET_OK;

        if (event == UNBLOCK_WEBSOCKET_EVENT_TEXT
            && !(flags & UNBLOCK_WEBSOCKET_MESSAGE_COMPRESSED)
            && !unblock_bqws_valid_utf8(
                (const uint8_t *)msg->data, msg->size)) {
            bqws_free_msg(msg);
            bqws_direct_fail(state->ws, BQWS_ERR_BAD_UTF8);
            break;
        }

        if (event == 0) {
            bqws_free_msg(msg);
            bqws_direct_fail(state->ws, BQWS_ERR_BAD_OPCODE);
            break;
        }

        if (event_fn != NULL)
            callback_result = event_fn(
                event_user, event, flags, msg->data, msg->size);

        bqws_free_msg(msg);

        if (callback_result != UNBLOCK_WEBSOCKET_OK)
            return callback_result;
    }

    if (bqws_get_error(state->ws) != BQWS_OK)
        return UNBLOCK_WEBSOCKET_ERROR;

    if (used != length && bqws_get_state(state->ws) < BQWS_STATE_CLOSING)
        return UNBLOCK_WEBSOCKET_ERROR;

    return UNBLOCK_WEBSOCKET_OK;
}

static int
unblock_ws_native_input(
    void *opaque,
    const char *data,
    size_t length,
    size_t *consumed,
    unblock_websocket_event_fn event_fn,
    void *event_user
)
{
    unblock_ws_legacy_event legacy;
    legacy.fn = event_fn;
    legacy.user = event_user;

    return unblock_ws_native_input_ex(
        opaque,
        data,
        length,
        consumed,
        unblock_ws_legacy_event_adapter,
        &legacy
    );
}

static int
unblock_ws_native_send_ex(
    void *opaque,
    uint32_t opcode,
    uint32_t flags,
    const char *data,
    size_t length
)
{
    unblock_ws_native *state = (unblock_ws_native *)opaque;
    bool compressed =
        (flags & UNBLOCK_WEBSOCKET_MESSAGE_COMPRESSED) != 0;

    if (state == NULL || state->ws == NULL || (length > 0 && data == NULL))
        return UNBLOCK_WEBSOCKET_ERROR;
    if (flags & ~UNBLOCK_WEBSOCKET_MESSAGE_COMPRESSED)
        return UNBLOCK_WEBSOCKET_ERROR;

    if (opcode == UNBLOCK_WEBSOCKET_EVENT_TEXT) {
        if (!compressed
            && !unblock_bqws_valid_utf8((const uint8_t *)data, length))
            return UNBLOCK_WEBSOCKET_ERROR;
        unblock_bqws_send_data(
            state->ws, BQWS_MSG_TEXT, data, length, compressed);
    }
    else if (opcode == UNBLOCK_WEBSOCKET_EVENT_BINARY) {
        unblock_bqws_send_data(
            state->ws, BQWS_MSG_BINARY, data, length, compressed);
    }
    else if (opcode == UNBLOCK_WEBSOCKET_EVENT_PING) {
        if (compressed || length > 125)
            return UNBLOCK_WEBSOCKET_ERROR;
        bqws_send_ping(state->ws, data, length);
    }
    else if (opcode == UNBLOCK_WEBSOCKET_EVENT_PONG) {
        if (compressed || length > 125)
            return UNBLOCK_WEBSOCKET_ERROR;
        bqws_send_pong(state->ws, data, length);
    }
    else {
        return UNBLOCK_WEBSOCKET_ERROR;
    }

    return bqws_get_error(state->ws) == BQWS_OK
        ? UNBLOCK_WEBSOCKET_OK : UNBLOCK_WEBSOCKET_ERROR;
}

static int
unblock_ws_native_send(
    void *opaque,
    uint32_t opcode,
    const char *data,
    size_t length
)
{
    return unblock_ws_native_send_ex(
        opaque, opcode, 0U, data, length);
}

static int
unblock_ws_native_configure(
    void *opaque,
    uint32_t features,
    size_t max_wire_message_size
)
{
    unblock_ws_native *state = (unblock_ws_native *)opaque;
    bqws_limits limits;

    if (state == NULL || state->ws == NULL || max_wire_message_size == 0)
        return UNBLOCK_WEBSOCKET_ERROR;
    if (features & ~UNBLOCK_WEBSOCKET_FEATURE_PERMESSAGE_DEFLATE)
        return UNBLOCK_WEBSOCKET_ERROR;

    limits = bqws_get_limits(state->ws);
    limits.max_recv_msg_size = max_wire_message_size;
    bqws_set_limits(state->ws, &limits);

    unblock_bqws_set_allow_rsv1(
        state->ws,
        (features & UNBLOCK_WEBSOCKET_FEATURE_PERMESSAGE_DEFLATE) != 0
    );

    return UNBLOCK_WEBSOCKET_OK;
}

static int
unblock_ws_native_close(
    void *opaque,
    uint32_t status_code,
    const char *reason,
    size_t reason_length
)
{
    unblock_ws_native *state = (unblock_ws_native *)opaque;

    if (state == NULL || state->ws == NULL
        || (reason_length > 0 && reason == NULL))
        return UNBLOCK_WEBSOCKET_ERROR;
    if (!unblock_bqws_valid_close_code((uint16_t)status_code)
        || status_code > 0xffffU)
        return UNBLOCK_WEBSOCKET_ERROR;
    if (reason_length > 123)
        return UNBLOCK_WEBSOCKET_ERROR;
    if (!unblock_bqws_valid_utf8((const uint8_t *)reason, reason_length))
        return UNBLOCK_WEBSOCKET_ERROR;

    bqws_close(
        state->ws,
        (bqws_close_reason)status_code,
        reason,
        reason_length
    );

    return bqws_get_error(state->ws) == BQWS_OK
        ? UNBLOCK_WEBSOCKET_OK : UNBLOCK_WEBSOCKET_ERROR;
}

static size_t
unblock_ws_native_output(void *opaque, char *buffer, size_t capacity)
{
    unblock_ws_native *state = (unblock_ws_native *)opaque;
    if (state == NULL || state->ws == NULL || (capacity > 0 && buffer == NULL))
        return 0;
    return bqws_write_to(state->ws, buffer, capacity);
}

static uint32_t
unblock_ws_native_error_code(void *opaque)
{
    unblock_ws_native *state = (unblock_ws_native *)opaque;
    if (state == NULL || state->ws == NULL)
        return (uint32_t)BQWS_ERR_UNKNOWN;
    return (uint32_t)bqws_get_error(state->ws);
}

static const char *
unblock_ws_native_error_string(void *opaque)
{
    return bqws_error_str((bqws_error)unblock_ws_native_error_code(opaque));
}

static size_t
unblock_ws_native_memory_used(void *opaque)
{
    unblock_ws_native *state = (unblock_ws_native *)opaque;
    if (state == NULL || state->ws == NULL)
        return 0;
    return bqws_get_memory_used(state->ws);
}

static void *
unblock_ws_native_abi_create(uint32_t role, size_t max_message_size)
{
    return (void *)unblock_ws_native_create(role, max_message_size);
}

static const unblock_websocket_native_ops_v1_t unblock_ws_native_ops = {
    UNBLOCK_WEBSOCKET_NATIVE_ABI_VERSION,
    sizeof(unblock_websocket_native_ops_v1_t),
    "Unblock::WebSocket native protocol engine",
    unblock_ws_native_abi_create,
    unblock_ws_native_destroy,
    unblock_ws_native_input,
    unblock_ws_native_send,
    unblock_ws_native_close,
    unblock_ws_native_output,
    unblock_ws_native_error_code,
    unblock_ws_native_error_string,
    unblock_ws_native_memory_used,
    unblock_ws_native_configure,
    unblock_ws_native_input_ex,
    unblock_ws_native_send_ex
};

static unblock_ws_native *
unblock_ws_from_sv(SV *self)
{
    unblock_ws_native *state;

    if (!SvROK(self))
        croak("invalid Unblock::WebSocket::_Native object");

    state = INT2PTR(unblock_ws_native *, SvIV((SV *)SvRV(self)));
    if (state == NULL || state->ws == NULL)
        croak("invalid Unblock::WebSocket::_Native state");

    return state;
}

static SV *
unblock_ws_new_object(const char *class, const char *role, UV max_message_size)
{
    uint32_t native_role;
    unblock_ws_native *state;
    SV *object;

    if (strEQ(role, "client"))
        native_role = UNBLOCK_WEBSOCKET_ROLE_CLIENT;
    else if (strEQ(role, "server"))
        native_role = UNBLOCK_WEBSOCKET_ROLE_SERVER;
    else
        return NULL;

    state = unblock_ws_native_create(native_role, (size_t)max_message_size);
    if (state == NULL)
        return NULL;

    object = newSV(0);
    sv_setref_pv(object, class, (void *)state);
    return object;
}

static SV *
unblock_ws_flush_sv(unblock_ws_native *state)
{
    SV *out = newSVpvn("", 0);
    char buffer[65536];

    for (;;) {
        size_t n = unblock_ws_native_output(state, buffer, sizeof(buffer));
        if (n > 0)
            sv_catpvn(out, buffer, n);
        if (n < sizeof(buffer))
            break;
    }
    return out;
}

typedef struct {
    AV *events;
} unblock_ws_perl_events;

static int
unblock_ws_collect_event(
    void *user,
    uint32_t event,
    uint32_t flags,
    const char *data,
    size_t length
)
{
    unblock_ws_perl_events *collector = (unblock_ws_perl_events *)user;
    AV *pair = newAV();
    SV *payload = newSVpvn(data == NULL ? "" : data, (STRLEN)length);

    av_push(pair, newSVuv((UV)event));
    av_push(pair, payload);
    av_push(pair, newSVuv((UV)flags));
    av_push(collector->events, newRV_noinc((SV *)pair));
    return UNBLOCK_WEBSOCKET_OK;
}

MODULE = Unblock::WebSocket    PACKAGE = Unblock::WebSocket::_Native

PROTOTYPES: DISABLE

SV *
new(class, role, max_message_size, allow_permessage_deflate = 0)
    const char *class
    const char *role
    UV max_message_size
    IV allow_permessage_deflate
PREINIT:
    unblock_ws_native *state;
CODE:
    RETVAL = unblock_ws_new_object(class, role, max_message_size);
    if (RETVAL == NULL)
        croak("native WebSocket context initialization failed");

    if (allow_permessage_deflate) {
        state = unblock_ws_from_sv(RETVAL);
        if (unblock_ws_native_configure(
                state,
                UNBLOCK_WEBSOCKET_FEATURE_PERMESSAGE_DEFLATE,
                (size_t)max_message_size)
            != UNBLOCK_WEBSOCKET_OK) {
            SvREFCNT_dec(RETVAL);
            croak("native WebSocket compression configuration failed");
        }
    }
OUTPUT:
    RETVAL

SV *
feed(self, bytes)
    SV *self
    SV *bytes
PREINIT:
    unblock_ws_native *state;
    STRLEN length;
    const char *data;
    size_t consumed;
    int result;
    AV *events;
    unblock_ws_perl_events collector;
CODE:
    state = unblock_ws_from_sv(self);
    data = SvPVbyte(bytes, length);
    events = newAV();
    collector.events = events;
    result = unblock_ws_native_input_ex(
        state,
        data,
        (size_t)length,
        &consumed,
        unblock_ws_collect_event,
        &collector
    );
    if (result != UNBLOCK_WEBSOCKET_OK
        && unblock_ws_native_error_code(state) == (uint32_t)BQWS_OK) {
        SvREFCNT_dec((SV *)events);
        croak("native WebSocket input failed without protocol error");
    }
    if (consumed != (size_t)length
        && unblock_ws_native_error_code(state) == (uint32_t)BQWS_OK
        && bqws_get_state(state->ws) < BQWS_STATE_CLOSING) {
        SvREFCNT_dec((SV *)events);
        croak("native WebSocket consumed only %lu of %lu input bytes",
            (unsigned long)consumed, (unsigned long)length);
    }
    RETVAL = newRV_noinc((SV *)events);
OUTPUT:
    RETVAL

void
queue_message(self, opcode, bytes, compressed = 0)
    SV *self
    UV opcode
    SV *bytes
    IV compressed
PREINIT:
    unblock_ws_native *state;
    STRLEN length;
    const char *data;
    uint32_t flags;
CODE:
    state = unblock_ws_from_sv(self);
    if (opcode == UNBLOCK_WEBSOCKET_EVENT_TEXT
        && !compressed
        && SvUTF8(bytes))
        data = SvPVutf8(bytes, length);
    else
        data = SvPVbyte(bytes, length);

    flags = compressed ? UNBLOCK_WEBSOCKET_MESSAGE_COMPRESSED : 0U;
    if (unblock_ws_native_send_ex(
            state,
            (uint32_t)opcode,
            flags,
            data,
            (size_t)length)
        != UNBLOCK_WEBSOCKET_OK)
        croak("native WebSocket send failed");

void
queue_close(self, status_code, reason)
    SV *self
    UV status_code
    SV *reason
PREINIT:
    unblock_ws_native *state;
    STRLEN length;
    const char *data;
CODE:
    state = unblock_ws_from_sv(self);
    if (SvUTF8(reason))
        data = SvPVutf8(reason, length);
    else
        data = SvPVbyte(reason, length);
    if (unblock_ws_native_close(
            state, (uint32_t)status_code, data, (size_t)length)
        != UNBLOCK_WEBSOCKET_OK)
        croak("native WebSocket close failed");

SV *
flush(self)
    SV *self
PREINIT:
    unblock_ws_native *state;
CODE:
    state = unblock_ws_from_sv(self);
    RETVAL = unblock_ws_flush_sv(state);
OUTPUT:
    RETVAL

UV
_memory_used(self)
    SV *self
PREINIT:
    unblock_ws_native *state;
CODE:
    state = unblock_ws_from_sv(self);
    RETVAL = (UV)unblock_ws_native_memory_used(state);
OUTPUT:
    RETVAL

UV
_error_code(self)
    SV *self
PREINIT:
    unblock_ws_native *state;
CODE:
    state = unblock_ws_from_sv(self);
    RETVAL = (UV)unblock_ws_native_error_code(state);
OUTPUT:
    RETVAL

SV *
_error_string(self)
    SV *self
PREINIT:
    unblock_ws_native *state;
CODE:
    state = unblock_ws_from_sv(self);
    RETVAL = newSVpv(unblock_ws_native_error_string(state), 0);
OUTPUT:
    RETVAL

UV
_operations_address(class)
    const char *class
CODE:
    PERL_UNUSED_ARG(class);
    RETVAL = PTR2UV(&unblock_ws_native_ops);
OUTPUT:
    RETVAL

SV *
_random_bytes(class, length)
    const char *class
    UV length
PREINIT:
    SV *out;
    char *buffer;
CODE:
    PERL_UNUSED_ARG(class);
    if (length == 0)
        croak("random byte length must be positive");
    out = newSV((STRLEN)length + 1);
    SvPOK_on(out);
    SvCUR_set(out, (STRLEN)length);
    buffer = SvPVX(out);
    if (!unblock_ws_secure_random(buffer, (size_t)length)) {
        SvREFCNT_dec(out);
        croak("secure random byte generation failed");
    }
    buffer[length] = '\0';
    RETVAL = out;
OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
PREINIT:
    unblock_ws_native *state;
CODE:
    if (SvROK(self)) {
        state = INT2PTR(unblock_ws_native *, SvIV((SV *)SvRV(self)));
        if (state != NULL) {
            unblock_ws_native_destroy(state);
            sv_setiv((SV *)SvRV(self), 0);
        }
    }
