#ifndef ZMQXS_H
#define ZMQXS_H
#include <errno.h>
#include <xs_object_magic.h>
#include <zmq.h>

/* this can be zmq_errno() if errno does not work */
#define _ERRNO errno

#define ZMQ_MSG_ALLOCATE(f)                        \
    msg = Zmqxs_msg_start_allocate(aTHX_ self);    \
    Zmqxs_msg_finish_allocate(aTHX_ self, f, msg); \

typedef void zmq_ctx_t;
typedef void zmq_sock_t;
typedef int zmq_sock_err; /* for the typemap */

void zmqxs_free_data(void *, void *);

/* convenient macro for updating $! */
#define SET_BANG Zmqxs_set_bang(aTHX_ _ERRNO)
inline void Zmqxs_set_bang(pTHX_ int);

/* utils to check that a struct is attached to our magic */
int zmqxs_has_object(pTHX_ SV *);
inline void Zmqxs_ensure_unallocated(pTHX_ SV *);

/* allocation utils for messages */
inline zmq_msg_t *Zmqxs_msg_start_allocate(pTHX_ SV *);
inline void Zmqxs_msg_finish_allocate(pTHX_ SV *, int, zmq_msg_t *);

#define zmqxs_new_sv(a) Zmqxs_new_sv(aTHX_ a)
#define zmqxs_has_object(a) Zmqxs_has_object(aTHX_ a)
#define zmqxs_ensure_unallocated(a) Zmqxs_ensure_unallocated(aTHX_ a)

#endif
