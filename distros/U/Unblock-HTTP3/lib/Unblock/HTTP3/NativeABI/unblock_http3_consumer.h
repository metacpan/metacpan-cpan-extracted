#ifndef UNBLOCK_HTTP3_CONSUMER_ABI_H
#define UNBLOCK_HTTP3_CONSUMER_ABI_H

#include "EXTERN.h"
#include "perl.h"

#include <stddef.h>
#include <stdint.h>

#define UB_HTTP3_CONSUMER_ABI_VERSION 1U

#define UB_HTTP3_TX_ACTIVE    0U
#define UB_HTTP3_TX_COMPLETE  1U
#define UB_HTTP3_TX_CANCELLED 2U
#define UB_HTTP3_TX_ERROR     3U

/* ABI v1 is append-only. Consumers must check abi_version and
 * struct_size before dereferencing entries. Incompatible layouts use a new
 * ABI version.
 */
typedef struct ub_http3_consumer_ops_v1_s {
    uint32_t abi_version;
    size_t struct_size;
    const char *name;

    void *(*create)(pTHX_ SV *connection);
    void (*service)(pTHX_ void *context);

    SV *(*request)(pTHX_ void *context, SV *request);
    SV *(*next_transaction)(pTHX_ void *context);
    SV *(*next_informational)(pTHX_ void *context);

    SV *(*transaction_next_informational)(pTHX_ SV *transaction);
    SV *(*transaction_request)(pTHX_ SV *transaction);
    SV *(*transaction_response)(pTHX_ SV *transaction);
    int64_t (*transaction_stream_id)(pTHX_ SV *transaction);
    uint32_t (*transaction_state)(pTHX_ SV *transaction);

    void (*send_response)(pTHX_ void *context, SV *transaction);
    void (*send_informational)(
        pTHX_
        void *context,
        SV *transaction,
        SV *response
    );

    int (*failed)(pTHX_ void *context);
    int (*error_code)(pTHX_ void *context, uint64_t *code);
    SV *(*error)(pTHX_ void *context);

    void (*destroy)(pTHX_ void *context);
} ub_http3_consumer_ops_v1;

#endif
