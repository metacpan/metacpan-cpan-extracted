#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <errno.h>
#include "ppport.h"
#include <xs_object_magic.h>
#include <zmq.h>
#include "zmqxs.h"

MODULE = ZeroMQ::Raw	PACKAGE = ZeroMQ::Raw   PREFIX = zmq_
PROTOTYPES: DISABLE

void
zmq_version()
    PREINIT:
        int major, minor, patch = 0;
    PPCODE:
        zmq_version(&major, &minor, &patch);
        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSViv(major)));
        PUSHs(sv_2mortal(newSViv(minor)));
        PUSHs(sv_2mortal(newSViv(patch)));

MODULE = ZeroMQ::Raw	PACKAGE = ZeroMQ::Raw::Context	PREFIX = zmq_

void
zmq_init(SV *self, int threads)
    PREINIT:
        zmq_ctx_t *ctx;

    CODE:
        zmqxs_ensure_unallocated(self);
        ctx = zmq_init(threads);
        if(ctx == NULL){
            SET_BANG;
            if(_ERRNO == EINVAL)
                croak("Invalid number of threads (%d) passed to zmq_init", threads);

            croak("Unknown error allocating ZMQ context");
        }
        xs_object_magic_attach_struct(aTHX_ SvRV(self), ctx);

void
zmq_term(zmq_ctx_t *ctx);
    PREINIT:
        int status = 0;
    CODE:
        status = zmq_term(ctx);
        if(status < 0){
            SET_BANG;
            if(_ERRNO == EFAULT)
                croak("Invalid context (%p) passed to zmq_term", ctx);

            croak("Unknown error terminating ZMQ context");
        }

bool
zmq_has_valid_context(SV *self)
    CODE:
        RETVAL = zmqxs_has_object(self);
    OUTPUT:
        RETVAL

MODULE = ZeroMQ::Raw	PACKAGE = ZeroMQ::Raw::Message	PREFIX = zmq_msg_

void
zmq_msg_init(SV *self)
    PREINIT:
        zmq_msg_t *msg;
    CODE:
        ZMQ_MSG_ALLOCATE(zmq_msg_init(msg));

void
zmq_msg_init_size(SV *self, size_t size)
    PREINIT:
        zmq_msg_t *msg;
    CODE:
        ZMQ_MSG_ALLOCATE(zmq_msg_init_size(msg, size));

void
zmq_msg_init_data(SV *self, SV *data)
    PREINIT:
        zmq_msg_t *msg;
        STRLEN len;
        char *buf;
        char *copy;
    CODE:
        if(!SvPOK(data))
            croak("You must pass init_data an SvPV and 0x%p is not one", data);
        if(SvUTF8(data))
            croak("Wide character in init_data, you must encode characters");

        buf = SvPV(data, len);
        copy = savepvn(buf, len);
        ZMQ_MSG_ALLOCATE(zmq_msg_init_data(msg, copy, len, &zmqxs_free_data, NULL));

int
zmq_msg_size(zmq_msg_t *msg)

SV *
zmq_msg_data(zmq_msg_t *msg)
    PREINIT:
        char *buf;
        size_t len;
    CODE:
        len = zmq_msg_size(msg);
        if(len < 1)
            XSRETURN_UNDEF;

        buf = zmq_msg_data(msg);
        RETVAL = newSVpv(buf, len);
    OUTPUT:
        RETVAL

void
zmq_msg_close(zmq_msg_t *msg)
    PREINIT:
        int status = 0;
    CODE:
        status = zmq_msg_close(msg);
        Safefree(msg);
        if(status < 0){
            SET_BANG;
            croak("Error closing message %p", msg);
        }

bool
zmq_msg_is_allocated(SV *self)
    CODE:
        RETVAL = zmqxs_has_object(self);
    OUTPUT:
        RETVAL

MODULE = ZeroMQ::Raw	PACKAGE = ZeroMQ::Raw::Socket	PREFIX = zmq_

zmq_sock_err
zmq_init_socket(SV *self, zmq_ctx_t *context, int type)
    PREINIT:
        zmq_sock_t *sock;
    CODE:
        sock = zmq_socket(context, type);
        if(sock == NULL){
            RETVAL = 1;
        }
        else {
            xs_object_magic_attach_struct(aTHX_ SvRV(self), sock);
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

zmq_sock_err
zmq_close(zmq_sock_t *sock)

zmq_sock_err
zmq_bind(zmq_sock_t *sock, const char *endpoint)

zmq_sock_err
zmq_connect(zmq_sock_t *sock, const char *endpoint)

zmq_sock_err
zmq_send(zmq_sock_t *sock, zmq_msg_t *msg, int flags)

zmq_sock_err
zmq_recv(zmq_sock_t *sock, zmq_msg_t *msg, int flags)

zmq_sock_err
zmq_setsockopt(zmq_sock_t *sock, int option, SV *value)
    PREINIT:
        STRLEN len;
        const char *ptr;
        uint64_t u64;
        int64_t  i64;
        int        i;
    CODE:
        switch(option){
            case ZMQ_LINGER:
            case ZMQ_RECONNECT_IVL:
            case ZMQ_BACKLOG:
                i = SvIV(value);
                RETVAL = zmq_setsockopt(sock, option, &i, sizeof(int));
                break;

            case ZMQ_IDENTITY:
            case ZMQ_SUBSCRIBE:
            case ZMQ_UNSUBSCRIBE:
                ptr = SvPV(value, len);
                RETVAL = zmq_setsockopt(sock, option, ptr, len);
                break;

            case ZMQ_SWAP:
            case ZMQ_RATE:
            case ZMQ_RECOVERY_IVL:
            case ZMQ_RECOVERY_IVL_MSEC:
            case ZMQ_MCAST_LOOP:
                i64 = SvIV(value);
                RETVAL = zmq_setsockopt(sock, option, &i64, sizeof(int64_t));
                break;

            case ZMQ_HWM:
            case ZMQ_AFFINITY:
            case ZMQ_SNDBUF:
            case ZMQ_RCVBUF:
                u64 = SvUV(value);
                RETVAL = zmq_setsockopt(sock, option, &u64, sizeof(uint64_t));
                break;

            default:
                warn("Unknown sockopt type %d, assuming string.  Send patch", option);
                ptr = SvPV(value, len);
                RETVAL = zmq_setsockopt(sock, option, ptr, len);
        }
    OUTPUT:
        RETVAL

SV *
zmq_getsockopt(zmq_sock_t *sock, int option)
    PREINIT:
        char     buf[256];
        int      i;
        uint64_t u64;
        int64_t  i64;
        uint32_t i32;
        size_t   len;
        int      status = -1;
    CODE:
        switch(option){
            case ZMQ_TYPE:
            case ZMQ_LINGER:
            case ZMQ_RECONNECT_IVL:
            case ZMQ_BACKLOG:
            case ZMQ_FD:
                len = sizeof(i);
                status = zmq_getsockopt(sock, option, &i, &len);
                if(status == 0)
                    RETVAL = newSViv(i);
                break;

            case ZMQ_RCVMORE:
            case ZMQ_SWAP:
            case ZMQ_RATE:
            case ZMQ_RECOVERY_IVL:
            case ZMQ_MCAST_LOOP:
                len = sizeof(i64);
                status = zmq_getsockopt(sock, option, &i64, &len);
                if(status == 0)
                    RETVAL = newSViv(i64);
                break;

            case ZMQ_HWM:
            case ZMQ_AFFINITY:
            case ZMQ_SNDBUF:
            case ZMQ_RCVBUF:
                len = sizeof(u64);
                status = zmq_getsockopt(sock, option, &u64, &len);
                if(status == 0)
                    RETVAL = newSVuv(u64);
                break;

            case ZMQ_EVENTS:
                len = sizeof(i32);
                status = zmq_getsockopt(sock, option, &i32, &len);
                if(status == 0)
                    RETVAL = newSViv(i32);
                break;

            case ZMQ_IDENTITY:
                len = sizeof(buf);
                status = zmq_getsockopt(sock, option, &buf, &len);
                if(status == 0)
                    RETVAL = newSVpvn(buf, len);
                break;
        }
        if(status != 0){
	    SET_BANG;
	    switch(_ERRNO) {
	        case EINTR:
                    croak("The operation was interrupted by delivery of a signal");
	        case ETERM:
	            croak("The 0MQ context accociated with the specified socket was terminated");
	        case EFAULT:
	            croak("The provided socket was not valid");
                case EINVAL:
                    croak("Invalid argument");
	        default:
	            croak("Unknown error reading socket option");
	    }
	}
    OUTPUT:
        RETVAL

bool
zmq_is_allocated(SV *self)
    CODE:
        RETVAL = zmqxs_has_object(self);
    OUTPUT:
        RETVAL
