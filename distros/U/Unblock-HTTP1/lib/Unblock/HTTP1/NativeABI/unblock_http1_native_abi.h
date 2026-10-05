#ifndef UNBLOCK_HTTP1_NATIVE_ABI_H
#define UNBLOCK_HTTP1_NATIVE_ABI_H

#include "EXTERN.h"
#include "perl.h"
#include <stddef.h>
#include <stdint.h>

#define UB_HTTP1_INPUT_ABI_VERSION 1U

#define UB_HTTP1_INPUT_OK     0
#define UB_HTTP1_INPUT_MORE   1
#define UB_HTTP1_INPUT_CLOSED 3
#define UB_HTTP1_INPUT_SWITCH 4

typedef struct ub_http1_input_ops_v1_s {
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
} ub_http1_input_ops_v1;

#endif
