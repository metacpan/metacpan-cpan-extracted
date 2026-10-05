#ifndef UNIFORM_HTTP_FASTPATH_H
#define UNIFORM_HTTP_FASTPATH_H

/* MIT License. Include after EXTERN.h and perl.h. See docs/NATIVE-FASTPATH.md.
 * Public: UHTTP_* constants, uhttp_native_* types and helpers.
 * Members/helpers prefixed with _ or uhttp_private_ are implementation details.
 * No global interpreter-owned state. Compile this header in the consumer XS.
 */
#define UHTTP_NATIVE_ABI_VERSION 1
#define UHTTP_PRIVATE_LAYOUT_VERSION 1
#define UHTTP_KIND_MESSAGE 0
#define UHTTP_KIND_REQUEST 1
#define UHTTP_KIND_RESPONSE 2
#define UHTTP_HAS_BUFFERED_BODY 0x001
#define UHTTP_COMPLETE          0x002
#define UHTTP_MUTABLE           0x004
#define UHTTP_INITIAL_MUTABLE   0x008
#define UHTTP_BODY_MUTABLE      0x010
#define UHTTP_TRAILERS_MUTABLE  0x020
#define UHTTP_HEADERS_LOSSLESS  0x040
#define UHTTP_TRAILERS_LOSSLESS 0x080
#define UHTTP_TARGET_EXACT      0x100
/* Explicit opt-in; zero-initialized input is never implicitly trusted. */
#define UHTTP_NATIVE_TRUSTED 0x55485431UL

#ifndef PERL_STATIC_INLINE
# define PERL_STATIC_INLINE static
#endif

typedef struct {
    const char *data;             /* NULL + 0 is absent; "" + 0 is present */
    STRLEN len;
} uhttp_native_bytes;

typedef struct {
    uhttp_native_bytes name, value;
} uhttp_native_field;

typedef struct {
    U32 _abi;
    void *_interpreter;
    HV *_classes[3];
} uhttp_native_api;

typedef struct {
    U32 kind, flags;
    uhttp_native_bytes version, method, target, scheme, authority, protocol;
    IV status;                   /* required for response, zero otherwise */
    uhttp_native_bytes reason, body;
    const uhttp_native_field *headers, *trailers;
    Size_t header_count, trailer_count;
} uhttp_native_input;

typedef struct { AV *_array; } uhttp_native_section;

typedef struct {
    U32 kind, flags;
    SV *version, *method, *target, *scheme, *authority, *protocol;
    SV *status, *reason, *body;    /* borrowed SVs, &PL_sv_undef if absent */
    uhttp_native_section headers, trailers;
} uhttp_native_view;

PERL_STATIC_INLINE void *
uhttp_private_interpreter(pTHX)
{
#ifdef MULTIPLICITY
    return (void *)aTHX;
#else
    return NULL;
#endif
}

/* Call once per interpreter/consumer state; also after an ithread clone.
 * Return false on version/layout mismatch. A failed handle cannot be used.
 */
PERL_STATIC_INLINE int
uhttp_native_init(pTHX_ uhttp_native_api *api, U32 requested_abi)
{
    dSP;
    int compatible = 0;
    CV *check;
    SV *answer;
    if (!api) croak("Uniform native API handle is NULL");
    Zero(api, 1, uhttp_native_api);
    if (requested_abi != UHTTP_NATIVE_ABI_VERSION) return 0;
    require_pv("Uniform/HTTP/FastPath.pm");
    check = get_cv("Uniform::HTTP::FastPath::native_compatible", 0);
    if (!check) return 0;  /* Uniform 0.05: portable FastPath still available */
    SPAGAIN;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVuv(UHTTP_NATIVE_ABI_VERSION)));
    XPUSHs(sv_2mortal(newSVuv(UHTTP_PRIVATE_LAYOUT_VERSION)));
    PUTBACK;
    if (call_sv((SV *)check, G_SCALAR) == 1) {
        SPAGAIN;
        answer = POPs;
        compatible = SvTRUE(answer) ? 1 : 0;
        PUTBACK;
    }
    FREETMPS;
    LEAVE;
    if (!compatible) return 0;
    api->_classes[0] = gv_stashpv("Uniform::HTTP::Message", 0);
    api->_classes[1] = gv_stashpv("Uniform::HTTP::Request", 0);
    api->_classes[2] = gv_stashpv("Uniform::HTTP::Response", 0);
    if (!api->_classes[0] || !api->_classes[1] || !api->_classes[2]) return 0;
    api->_interpreter = uhttp_private_interpreter(aTHX);
    api->_abi = UHTTP_NATIVE_ABI_VERSION;
    return 1;
}

PERL_STATIC_INLINE void
uhttp_private_require_api(pTHX_ const uhttp_native_api *api)
{
    if (!api || api->_abi != UHTTP_NATIVE_ABI_VERSION ||
        api->_interpreter != uhttp_private_interpreter(aTHX))
        croak("Uniform native ABI handle is incompatible or uninitialized");
}

/* Initialize metadata and the normal complete, fully mutable default state. */
PERL_STATIC_INLINE void
uhttp_native_input_init(uhttp_native_input *input, U32 kind)
{
    Zero(input, 1, uhttp_native_input);
    input->kind = kind;
    input->flags = UHTTP_COMPLETE | UHTTP_MUTABLE | UHTTP_INITIAL_MUTABLE |
        UHTTP_BODY_MUTABLE | UHTTP_TRAILERS_MUTABLE |
        UHTTP_HEADERS_LOSSLESS | UHTTP_TRAILERS_LOSSLESS;
    if (kind == UHTTP_KIND_REQUEST) input->flags |= UHTTP_TARGET_EXACT;
}

PERL_STATIC_INLINE void
uhttp_private_check_bytes(pTHX_ uhttp_native_bytes value, int required)
{
    if ((!value.data && (value.len || required)) || value.len > (STRLEN)IV_MAX - 1)
        croak("Uniform native byte span is absent, inconsistent, or too large");
}

PERL_STATIC_INLINE void
uhttp_private_check_fields(pTHX_ const uhttp_native_field *fields, Size_t count)
{
    Size_t i;
    if ((!fields && count) || count > (Size_t)I32_MAX)
        croak("Uniform native field array is absent or too large");
    for (i = 0; i < count; ++i) {
        uhttp_private_check_bytes(aTHX_ fields[i].name, 1);
        uhttp_private_check_bytes(aTHX_ fields[i].value, 1);
        if (!fields[i].name.len) croak("Uniform native field name is empty");
    }
}

PERL_STATIC_INLINE void
uhttp_private_check_input(pTHX_ const uhttp_native_input *in, U32 trust)
{
    U32 f;
    if (trust != UHTTP_NATIVE_TRUSTED)
        croak("Uniform native construction requires explicit trusted input");
    if (!in || in->kind > UHTTP_KIND_RESPONSE)
        croak("Uniform native message kind is invalid");
    f = in->flags;
    if ((f & ~0x1ffU) || !(f & UHTTP_HEADERS_LOSSLESS) ||
        !(f & UHTTP_TRAILERS_LOSSLESS) ||
        (!!(f & UHTTP_MUTABLE) != !!(f & UHTTP_BODY_MUTABLE)) ||
        (!(f & UHTTP_MUTABLE) && (f & (UHTTP_INITIAL_MUTABLE | UHTTP_TRAILERS_MUTABLE))) ||
        (!!(f & UHTTP_TARGET_EXACT) != (in->kind == UHTTP_KIND_REQUEST)) ||
        (!!(f & UHTTP_HAS_BUFFERED_BODY) != !!in->body.data))
        croak("Uniform native flags are not canonical");
    uhttp_private_check_bytes(aTHX_ in->version, 0);
    uhttp_private_check_bytes(aTHX_ in->method, in->kind == UHTTP_KIND_REQUEST);
    uhttp_private_check_bytes(aTHX_ in->target, in->kind == UHTTP_KIND_REQUEST);
    uhttp_private_check_bytes(aTHX_ in->scheme, 0);
    uhttp_private_check_bytes(aTHX_ in->authority, 0);
    uhttp_private_check_bytes(aTHX_ in->protocol, 0);
    uhttp_private_check_bytes(aTHX_ in->reason, 0);
    uhttp_private_check_bytes(aTHX_ in->body, 0);
    if (in->kind == UHTTP_KIND_REQUEST && (!in->method.len || !in->target.len))
        croak("Uniform native request method and target must not be empty");
    if (in->kind != UHTTP_KIND_REQUEST && (in->method.data || in->target.data ||
        in->scheme.data || in->authority.data || in->protocol.data))
        croak("Uniform native non-request contains request metadata");
    if (in->kind == UHTTP_KIND_RESPONSE) {
        if (in->status < 100 || in->status > 599)
            croak("Uniform native response status must be 100 through 599");
    }
    else if (in->status || in->reason.data)
        croak("Uniform native non-response contains response metadata");
    uhttp_private_check_fields(aTHX_ in->headers, in->header_count);
    uhttp_private_check_fields(aTHX_ in->trailers, in->trailer_count);
}

PERL_STATIC_INLINE SV *
uhttp_private_copy_bytes(pTHX_ uhttp_native_bytes value)
{
    return value.data ? newSVpvn(value.data, value.len) : newSV(0);
}

PERL_STATIC_INLINE void
uhttp_private_store(pTHX_ HV *hv, const char *key, I32 len, SV *value)
{
    if (!hv_store(hv, key, len, value, 0)) {
        SvREFCNT_dec(value);
        croak("Uniform native object allocation failed");
    }
}

PERL_STATIC_INLINE void
uhttp_private_copy_fields(pTHX_ HV *hv, const char *key, I32 len,
    const uhttp_native_field *fields, Size_t count)
{
    Size_t i;
    AV *array = newAV();
    uhttp_private_store(aTHX_ hv, key, len, newRV_noinc((SV *)array));
    if (count) av_extend(array, (I32)count - 1);
    for (i = 0; i < count; ++i) {
        AV *pair = newAV();
        av_push(array, newRV_noinc((SV *)pair));
        av_extend(pair, 1);
        av_push(pair, uhttp_private_copy_bytes(aTHX_ fields[i].name));
        av_push(pair, uhttp_private_copy_bytes(aTHX_ fields[i].value));
    }
}

/* Returns an owned, non-mortal SV (refcount 1). Caller must return, mortalize,
 * or decrement it. All input spans are copied; no input ownership transfers.
 * Deliberately skips HTTP syntax validation. Never use for unvalidated data.
 */
PERL_STATIC_INLINE SV *
uhttp_native_from_validated(pTHX_ const uhttp_native_api *api,
    const uhttp_native_input *in, U32 trust)
{
    HV *hv;
    SV *object;
    U32 f;
    uhttp_private_require_api(aTHX_ api);
    uhttp_private_check_input(aTHX_ in, trust);
    f = in->flags;
    ENTER;
    SAVETMPS;
    hv = newHV();
    object = sv_2mortal(newRV_noinc((SV *)hv));
    hv_ksplit(hv, 16);
#define UHTTP_PRIVATE_BYTES(key) \
    uhttp_private_store(aTHX_ hv, #key, sizeof(#key)-1, uhttp_private_copy_bytes(aTHX_ in->key))
#define UHTTP_PRIVATE_BOOL(key, expr) \
    uhttp_private_store(aTHX_ hv, key, sizeof(key)-1, newSViv((expr) ? 1 : 0))
    UHTTP_PRIVATE_BYTES(version);
    UHTTP_PRIVATE_BYTES(body);
    UHTTP_PRIVATE_BOOL("initial_frozen", !(f & UHTTP_INITIAL_MUTABLE));
    UHTTP_PRIVATE_BOOL("trailers_frozen", !(f & UHTTP_TRAILERS_MUTABLE));
    UHTTP_PRIVATE_BOOL("has_buffered_body", f & UHTTP_HAS_BUFFERED_BODY);
    UHTTP_PRIVATE_BOOL("complete", f & UHTTP_COMPLETE);
    UHTTP_PRIVATE_BOOL("mutable", f & UHTTP_MUTABLE);
    uhttp_private_copy_fields(aTHX_ hv, "headers", 7, in->headers, in->header_count);
    uhttp_private_copy_fields(aTHX_ hv, "trailers", 8, in->trailers, in->trailer_count);
    if (in->kind == UHTTP_KIND_REQUEST) {
        UHTTP_PRIVATE_BYTES(method);
        UHTTP_PRIVATE_BYTES(target);
        UHTTP_PRIVATE_BYTES(scheme);
        UHTTP_PRIVATE_BYTES(authority);
        UHTTP_PRIVATE_BYTES(protocol);
    }
    else if (in->kind == UHTTP_KIND_RESPONSE) {
        uhttp_private_store(aTHX_ hv, "status", 6, newSViv(in->status));
        UHTTP_PRIVATE_BYTES(reason);
    }
#undef UHTTP_PRIVATE_BYTES
#undef UHTTP_PRIVATE_BOOL
    sv_bless(object, api->_classes[in->kind]);
    SvREFCNT_inc(object);
    FREETMPS;
    LEAVE;
    return object;
}

/* Missing optional keys behave like Perl getters. No magical scalar is read. */
PERL_STATIC_INLINE SV *
uhttp_private_fetch(pTHX_ HV *hv, const char *key, I32 len)
{
    SV **slot = hv_fetch(hv, key, len, 0);
    return slot ? *slot : &PL_sv_undef;
}

PERL_STATIC_INLINE int
uhttp_private_plain(SV *sv)
{
    return sv && !SvMAGICAL(sv) && !SvROK(sv) && SvTYPE(sv) <= SVt_PVMG;
}

PERL_STATIC_INLINE int
uhttp_private_section(SV *sv, uhttp_native_section *out)
{
    if (!sv || SvMAGICAL(sv) || !SvROK(sv) ||
        SvTYPE(SvRV(sv)) != SVt_PVAV || SvMAGICAL(SvRV(sv)) || SvOBJECT(SvRV(sv)))
        return 0;
    out->_array = (AV *)SvRV(sv);
    return 1;
}

/* Returns 0 for adapters, subclasses, magical or malformed top-level storage.
 * On failure the output is unspecified and must not be used. No Perl callbacks.
 */
PERL_STATIC_INLINE int
uhttp_native_inspect(pTHX_ const uhttp_native_api *api, SV *object,
    uhttp_native_view *out)
{
    HV *hv;
    U32 kind, flags;
    SV *mutable, *initial, *trailers, *complete, *body;
    uhttp_private_require_api(aTHX_ api);
    if (!out) croak("Uniform native view is NULL");
    Zero(out, 1, uhttp_native_view);
    if (!object || SvMAGICAL(object) || !SvROK(object) ||
        SvTYPE(SvRV(object)) != SVt_PVHV || !SvOBJECT(SvRV(object)) ||
        SvMAGICAL(SvRV(object))) return 0;
    hv = (HV *)SvRV(object);
    for (kind = 0; kind < 3; ++kind) if (SvSTASH((SV *)hv) == api->_classes[kind]) break;
    if (kind == 3) return 0;
#define UHTTP_PRIVATE_FETCH(key) uhttp_private_fetch(aTHX_ hv, key, sizeof(key)-1)
#define UHTTP_PRIVATE_VIEW(key) \
    out->key = UHTTP_PRIVATE_FETCH(#key); \
    if (!uhttp_private_plain(out->key)) return 0
    UHTTP_PRIVATE_VIEW(version);
    UHTTP_PRIVATE_VIEW(body);
    out->method = out->target = out->scheme = out->authority = out->protocol = &PL_sv_undef;
    out->status = out->reason = &PL_sv_undef;
    if (kind == UHTTP_KIND_REQUEST) {
        UHTTP_PRIVATE_VIEW(method);
        UHTTP_PRIVATE_VIEW(target);
        UHTTP_PRIVATE_VIEW(scheme);
        UHTTP_PRIVATE_VIEW(authority);
        UHTTP_PRIVATE_VIEW(protocol);
        if (!SvOK(out->method) || !SvOK(out->target)) return 0;
    }
    else if (kind == UHTTP_KIND_RESPONSE) {
        UHTTP_PRIVATE_VIEW(status);
        UHTTP_PRIVATE_VIEW(reason);
        if (!SvOK(out->status)) return 0;
    }
    if (!uhttp_private_section(UHTTP_PRIVATE_FETCH("headers"), &out->headers) ||
        !uhttp_private_section(UHTTP_PRIVATE_FETCH("trailers"), &out->trailers)) return 0;
    mutable = UHTTP_PRIVATE_FETCH("mutable");
    initial = UHTTP_PRIVATE_FETCH("initial_frozen");
    trailers = UHTTP_PRIVATE_FETCH("trailers_frozen");
    complete = UHTTP_PRIVATE_FETCH("complete");
    body = UHTTP_PRIVATE_FETCH("has_buffered_body");
    if (!uhttp_private_plain(mutable) || !SvOK(mutable) ||
        !uhttp_private_plain(initial) || !SvOK(initial) ||
        !uhttp_private_plain(trailers) || !SvOK(trailers) ||
        !uhttp_private_plain(complete) || !SvOK(complete) ||
        !uhttp_private_plain(body) || !SvOK(body)) return 0;
    flags = UHTTP_HEADERS_LOSSLESS | UHTTP_TRAILERS_LOSSLESS;
    if (kind == UHTTP_KIND_REQUEST) flags |= UHTTP_TARGET_EXACT;
    if (SvTRUE(mutable)) {
        flags |= UHTTP_MUTABLE | UHTTP_BODY_MUTABLE;
        if (!SvTRUE(initial)) flags |= UHTTP_INITIAL_MUTABLE;
        if (!SvTRUE(trailers)) flags |= UHTTP_TRAILERS_MUTABLE;
    }
    if (SvTRUE(complete)) flags |= UHTTP_COMPLETE;
    if (SvTRUE(body)) {
        if (!SvOK(out->body)) return 0;
        flags |= UHTTP_HAS_BUFFERED_BODY;
    }
    else out->body = &PL_sv_undef;
    out->kind = kind;
    out->flags = flags;
#undef UHTTP_PRIVATE_FETCH
#undef UHTTP_PRIVATE_VIEW
    return 1;
}

PERL_STATIC_INLINE Size_t
uhttp_native_field_count(pTHX_ const uhttp_native_section *section)
{
    return (Size_t)(av_len(section->_array) + 1);
}

/* Returns 0 for out of range. Croaks on malformed/magical pair storage.
 * Returned scalars are borrowed and read-only to the consumer.
 */
PERL_STATIC_INLINE int
uhttp_native_field_at(pTHX_ const uhttp_native_section *section, Size_t index,
    SV **name, SV **value)
{
    SV **pair, **n, **v;
    AV *av;
    *name = *value = &PL_sv_undef;
    if (index >= uhttp_native_field_count(aTHX_ section)) return 0;
    pair = av_fetch(section->_array, (I32)index, 0);
    if (!pair || SvMAGICAL(*pair) || !SvROK(*pair) ||
        SvTYPE(SvRV(*pair)) != SVt_PVAV || SvMAGICAL(SvRV(*pair)) ||
        SvOBJECT(SvRV(*pair))) croak("Uniform native field pair is not canonical");
    av = (AV *)SvRV(*pair);
    if (av_len(av) != 1) croak("Uniform native field pair is not canonical");
    n = av_fetch(av, 0, 0);
    v = av_fetch(av, 1, 0);
    if (!n || !v || !uhttp_private_plain(*n) || !uhttp_private_plain(*v) ||
        !SvOK(*n) || !SvOK(*v)) croak("Uniform native field values are not canonical");
    *name = *n;
    *value = *v;
    return 1;
}

#endif
