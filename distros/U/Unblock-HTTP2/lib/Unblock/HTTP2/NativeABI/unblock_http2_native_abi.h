#ifndef UNBLOCK_HTTP2_NATIVE_ABI_H
#define UNBLOCK_HTTP2_NATIVE_ABI_H

#include "EXTERN.h"
#include "perl.h"
#include <stddef.h>
#include <stdint.h>

#define UB_HTTP2_NATIVE_ABI_VERSION 1U

#define UB_HTTP2_INPUT_OK      0
#define UB_HTTP2_INPUT_MORE    1
#define UB_HTTP2_INPUT_CLOSED  3

#define UB_HTTP2_OUTPUT_OK      0
#define UB_HTTP2_OUTPUT_CLOSED  3

#define UB_HTTP2_OUTPUT_CONTINUE 0
#define UB_HTTP2_OUTPUT_PAUSE    1
#define UB_HTTP2_OUTPUT_ERROR   -1

typedef int (*ub_http2_output_sink_v1)(
    pTHX_
    void *sink_context,
    const char *data,
    size_t length
);

typedef struct ub_http2_native_ops_v1_s {
    uint32_t abi_version;
    size_t struct_size;
    const char *name;

    void *(*create)(pTHX_ SV *engine);

    int (*input)(
        pTHX_
        void *context,
        const char *data,
        size_t length,
        size_t *consumed
    );

    int (*eof)(pTHX_ void *context);

    void (*destroy)(pTHX_ void *context);

    int (*output)(
        pTHX_
        void *context,
        ub_http2_output_sink_v1 sink,
        void *sink_context,
        size_t *produced
    );

    int (*want_read)(pTHX_ void *context);
    int (*want_write)(pTHX_ void *context);
} ub_http2_native_ops_v1;

#endif
