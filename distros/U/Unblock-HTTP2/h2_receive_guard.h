/* Private receive checks for facts libnghttp2 discards in RFC 9218 mode.
 * libnghttp2 still owns frame decoding, HPACK, flow control and active streams.
 * Only frame envelopes and small PRIORITY/WINDOW_UPDATE fields are inspected.
 */
#define UB_H2_HISTORY_LIMIT 1024
#define UB_H2_CLOSED 1
#define UB_H2_LOCAL_RESET 2
#define UB_H2_SKIPPED 3

typedef struct {
    int32_t first;
    int32_t last;
    unsigned char kind;
} ub_h2_history;

typedef struct {
    ub_h2_history *history;
    size_t count;
    size_t capacity;
    int32_t last_peer_id;
    int32_t current_rst;
    int32_t continuation;
    size_t payload_left;
    size_t prefix_used;
    size_t preface_left;
    unsigned char prefix[14];
    int ready;
    int failed;
} ub_h2_guard;

static int
ub_h2_reject(ub_h2_guard *g, nghttp2_session *session,
             uint32_t code, const char *reason)
{
    int rv;
    if (g->failed) return 0;
    (void)reason; /* Diagnostic label at the call site; public nghttp2 API. */
    rv = nghttp2_session_terminate_session(session, code);
    if (rv == 0) g->failed = 1;
    return rv;
}

/* Sorted, coalesced ranges of odd request stream IDs. Normal sequential
 * traffic uses one range, regardless of the number of completed requests.
 * Bound pathological fragmentation instead of forgetting reset-race facts.
 */
static int
ub_h2_remember(ub_h2_guard *g, nghttp2_session *session,
               int32_t first, int32_t last, unsigned char kind)
{
    size_t lo = 0, hi = g->count, i;
    ub_h2_history *h;
    if (g->failed || first > last || !(first & 1)) return 0;
    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        if (g->history[mid].last < first) lo = mid + 1;
        else hi = mid;
    }
    i = lo;
    /* Stream-close notifications are unique. Keep existing facts if a
     * duplicate notification nevertheless arrives during teardown. */
    if (i < g->count && g->history[i].first <= last) return 0;
    if (i && g->history[i - 1].kind == kind
        && (int64_t)g->history[i - 1].last + 2 == first) {
        h = &g->history[--i];
        h->last = last;
    } else if (i < g->count && g->history[i].kind == kind
               && (int64_t)last + 2 == g->history[i].first) {
        g->history[i].first = first;
        return 0;
    } else {
        if (g->count == UB_H2_HISTORY_LIMIT) {
            return ub_h2_reject(g, session, NGHTTP2_ENHANCE_YOUR_CALM,
                                "stream history fragmentation limit");
        }
        if (g->count == g->capacity) {
            dTHX; /* Windows Perl can route realloc through its interpreter. */
            size_t capacity = g->capacity ? g->capacity * 2 : 8;
            h = (ub_h2_history *)realloc(g->history, capacity * sizeof(*h));
            if (!h) return NGHTTP2_ERR_NOMEM;
            g->history = h;
            g->capacity = capacity;
        }
        memmove(g->history + i + 1, g->history + i,
                (g->count - i) * sizeof(*g->history));
        ++g->count;
        h = &g->history[i];
        h->first = first;
        h->last = last;
        h->kind = kind;
    }
    if (i + 1 < g->count && g->history[i + 1].kind == kind
        && (int64_t)h->last + 2 == g->history[i + 1].first) {
        h->last = g->history[i + 1].last;
        --g->count;
        memmove(g->history + i + 1, g->history + i + 2,
                (g->count - i - 1) * sizeof(*g->history));
    }
    return 0;
}

static unsigned char
ub_h2_history_kind(const ub_h2_guard *g, int32_t id)
{
    size_t lo = 0, hi = g->count;
    if (!(id & 1)) return 0;
    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        const ub_h2_history *h = &g->history[mid];
        if (id < h->first) hi = mid;
        else if (id > h->last) lo = mid + 1;
        else return h->kind;
    }
    return 0;
}

static uint32_t
ub_h2_u31(const uint8_t *p)
{
    return ((uint32_t)(p[0] & 0x7f) << 24)
        | ((uint32_t)p[1] << 16) | ((uint32_t)p[2] << 8) | p[3];
}

/* A peer RST_STREAM can arrive after our own reset was serialized. It ends
 * the in-flight-frame exception even though nghttp2 has already freed the
 * stream. Split a coalesced local-reset range without losing its neighbors.
 */
static int
ub_h2_peer_reset(ub_h2_guard *g, nghttp2_session *session, int32_t id)
{
    size_t i;
    int rv;
    if (!(id & 1) || ub_h2_history_kind(g, id) != UB_H2_LOCAL_RESET) return 0;
    for (i = 0; i < g->count; ++i) {
        ub_h2_history old = g->history[i];
        if (id < old.first || id > old.last) continue;
        --g->count;
        memmove(g->history + i, g->history + i + 1,
                (g->count - i) * sizeof(*g->history));
        if (id > old.first) {
            rv = ub_h2_remember(g, session, old.first, id - 2, old.kind);
            if (rv != 0) return rv;
        }
        rv = ub_h2_remember(g, session, id, id, UB_H2_CLOSED);
        if (rv != 0) return rv;
        if (id < old.last)
            return ub_h2_remember(g, session, id + 2, old.last, old.kind);
        return 0;
    }
    return 0;
}

/* Both public input paths call this routine. Forward borrowed payload windows
 * directly, stopping at frame boundaries so callbacks update history before
 * the next frame is checked. Buffer at most 14 bytes across fragmented reads.
 */
static ssize_t
ub_h2_receive(ub_h2_guard *g, nghttp2_session *session,
              const uint8_t *data, size_t length)
{
    size_t offset = 0;
    ssize_t rv;
    while (offset < length) {
        size_t n, frame_length, need;
        const uint8_t *p;
        int buffered;
        uint8_t type, flags;
        int32_t id;
        unsigned char kind;
        int inspect_priority, inspect_window;

        if (g->failed || !nghttp2_session_want_read(session))
            return (ssize_t)length;

        if (g->preface_left || g->payload_left) {
            size_t *left = g->preface_left ? &g->preface_left : &g->payload_left;
            n = length - offset;
            if (n > *left) n = *left;
            rv = nghttp2_session_mem_recv(session, data + offset, n);
            if (rv < 0) return rv;
            if ((size_t)rv != n) return NGHTTP2_ERR_CALLBACK_FAILURE;
            *left -= n;
            offset += n;
            continue;
        }

        buffered = g->prefix_used || length - offset < 9;
        if (buffered) {
            n = 9 - (g->prefix_used < 9 ? g->prefix_used : 9);
            if (n > length - offset) n = length - offset;
            memcpy(g->prefix + g->prefix_used, data + offset, n);
            g->prefix_used += n;
            offset += n;
            if (g->prefix_used < 9) break;
            p = g->prefix;
        } else {
            p = data + offset;
        }
        frame_length = ((size_t)p[0] << 16) | ((size_t)p[1] << 8) | p[2];
        type = p[3];
        flags = p[4];
        id = (int32_t)ub_h2_u31(p + 5);

        /* Invalid sizes, the initial SETTINGS requirement, and interleaved
         * header blocks are libnghttp2's responsibility and take precedence. */
        inspect_priority = g->ready && !g->continuation
            && type == NGHTTP2_PRIORITY && frame_length == 5
            && nghttp2_session_get_remote_settings(
                session, NGHTTP2_SETTINGS_NO_RFC7540_PRIORITIES) != 1;
        inspect_window = g->ready && !g->continuation
            && type == NGHTTP2_WINDOW_UPDATE && frame_length == 4 && id > 0;
        need = inspect_priority ? 14 : inspect_window ? 13 : 9;
        if (buffered || length - offset < need) {
            if (!buffered) {
                memcpy(g->prefix, p, 9);
                g->prefix_used = 9;
                offset += 9;
                buffered = 1;
            }
            n = need - g->prefix_used;
            if (n > length - offset) n = length - offset;
            memcpy(g->prefix + g->prefix_used, data + offset, n);
            g->prefix_used += n;
            offset += n;
            if (g->prefix_used < need) break;
            p = g->prefix;
        }

        if (g->ready && !g->continuation
            && frame_length <= nghttp2_session_get_local_settings(
                session, NGHTTP2_SETTINGS_MAX_FRAME_SIZE)) {
            /* Recent nghttp2 versions escalate stream-window overflow to a
             * connection error. Preserve the required stream-local reset,
             * using nghttp2's authoritative send window, without updating it.
             * The parser is at a frame boundary: consume just this frame.
             */
            if (inspect_window
                && (int64_t)nghttp2_session_get_stream_remote_window_size(session, id)
                    + ub_h2_u31(p + 9) > INT32_MAX) {
                rv = nghttp2_submit_rst_stream(session, NGHTTP2_FLAG_NONE, id,
                                               NGHTTP2_FLOW_CONTROL_ERROR);
                if (rv != 0) return rv;
                if (!buffered) offset += 13;
                g->prefix_used = 0;
                continue;
            }
            if (inspect_priority && (!id || ub_h2_u31(p + 9) == (uint32_t)id)) {
                rv = ub_h2_reject(g, session, NGHTTP2_PROTOCOL_ERROR,
                                  "invalid legacy PRIORITY stream dependency");
                return rv < 0 ? rv : (ssize_t)length;
            }
            if (type == NGHTTP2_HEADERS || type == NGHTTP2_DATA) {
                kind = ub_h2_history_kind(g, id);
                if (kind == UB_H2_CLOSED || kind == UB_H2_SKIPPED) {
                    uint32_t code = kind == UB_H2_SKIPPED && type == NGHTTP2_HEADERS
                        ? NGHTTP2_PROTOCOL_ERROR : NGHTTP2_STREAM_CLOSED;
                    rv = ub_h2_reject(g, session, code,
                                      "frame on closed or skipped stream");
                    return rv < 0 ? rv : (ssize_t)length;
                }
            }
        }

        g->current_rst = type == NGHTTP2_RST_STREAM && frame_length == 4 ? id : 0;
        if (type == NGHTTP2_HEADERS && !(flags & NGHTTP2_FLAG_END_HEADERS))
            g->continuation = id;
        else if (type == NGHTTP2_CONTINUATION && (flags & NGHTTP2_FLAG_END_HEADERS))
            g->continuation = 0;

        n = buffered ? need : length - offset;
        if (n > frame_length + 9) n = frame_length + 9;
        g->payload_left = frame_length - (n - 9);
        rv = nghttp2_session_mem_recv(session, p, n);
        if (rv < 0) return rv;
        if ((size_t)rv != n) return NGHTTP2_ERR_CALLBACK_FAILURE;
        if (!buffered) offset += n;
        g->prefix_used = 0;
    }
    return (ssize_t)length;
}
