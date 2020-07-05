#pragma once
#include "../forward.h"
#include <openssl/ssl.h>
#include <openssl/bio.h>
#include <panda/string.h>
#include <panda/memory.h>

namespace panda { namespace unievent { namespace ssl {

extern log::Module panda_log_module;

#ifdef LIBRESSL_VERSION_NUMBER
#  define _PATCH_BIO 1
#else
#  define _PATCH_BIO 0
#endif

#if OPENSSL_VERSION_NUMBER < 0x10100000L || _PATCH_BIO

#define BIO_get_data(bio) bio->ptr
#define BIO_set_data(bio, b) bio->ptr = b
#define BIO_get_shutdown(bio) bio->shutdown
#define BIO_set_shutdown(bio, s) bio->shutdown = 1
#define BIO_get_init(bio) bio->init
#define BIO_set_init(bio, i) bio->init = i

#define BIO_meth_set_write(bio, bio_write) bio->bwrite = bio_write
#define BIO_meth_set_read(bio, bio_read) bio->bread = bio_read
#define BIO_meth_set_puts(bio, bio_puts) bio->bputs = bio_puts
#define BIO_meth_set_gets(bio, bio_gets) bio->bgets = bio_gets
#define BIO_meth_set_ctrl(bio, bio_ctrl) bio->ctrl = bio_ctrl
#define BIO_meth_set_create(bio, bio_new) bio->create = bio_new
#define BIO_meth_set_destroy(bio, bio_free) bio->destroy = bio_free
#define BIO_meth_set_callback_ctrl(bio, bio_callback) bio->callback_ctrl = bio_callback

#define BIO_meth_new(TYPE, NAME) ({ \
    BIO_METHOD* bio = new BIO_METHOD; \
    bio->name = NAME; \
    bio->type = TYPE; \
    bio; \
})

#endif

struct SslBio {
    struct membuf_t : AllocatedObject<membuf_t> {
        Stream* handle;
        string  buf;    // current read buf
    };

    static const int TYPE = 63 | BIO_TYPE_SOURCE_SINK;

    static BIO_METHOD* method () {
        #if OPENSSL_VERSION_NUMBER < 0x10100000L
        return &_method;
        #else
        return _method();
        #endif
    }

    static void set_handle (BIO* bio, Stream* handle) {
        membuf_t* b = (membuf_t*) BIO_get_data(bio);
        b->handle = handle;
    }

    static void set_buf (BIO* bio, const string& buf) {
        membuf_t* b = (membuf_t*) BIO_get_data(bio);
        panda_log_debug(bio << " len=" << buf.length() << ", was=" << b->buf.length());
        b->buf += buf;
    }

    static string steal_buf (BIO* bio) {
        membuf_t* b = (membuf_t*) BIO_get_data(bio);
        panda_log_debug(bio << " len=" << b->buf.length());
        string ret;
        ret.swap(b->buf);
        return ret;
    }

private:
    #if OPENSSL_VERSION_NUMBER < 0x10100000L
    static BIO_METHOD _method;
    #else
    static BIO_METHOD* _method();
    #endif
};

}}}
