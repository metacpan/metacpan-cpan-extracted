#pragma once
#include <uv.h>
#include <panda/unievent/util.h>
#include <panda/unievent/error.h>
#include <panda/unievent/backend/HandleImpl.h>

namespace panda { namespace unievent { namespace backend { namespace uv {

static inline void            uvx_strict (int err) { if (err) throw Error(uvx_error(err)); }
static inline std::error_code uvx_ce     (int err) { return err ? uvx_error(err) : std::error_code(); }

template <class T = HandleImpl*, class X>
static inline T get_handle (X* uvhp) {
    return static_cast<T>(reinterpret_cast<HandleImpl*>(uvhp->data));
}

template <class T = RequestImpl*, class X>
static inline T get_request (X* uvrp) {
    return static_cast<T>(reinterpret_cast<RequestImpl*>(uvrp->data));
}

static inline void uvx_buf_alloc (string& buf, uv_buf_t* uvbuf) {
    char* ptr = buf.shared_buf();
    auto  cap = buf.shared_capacity();

    size_t align = (size_t(ptr) + cap) % sizeof(void*);
    cap -= align;

    auto availcap = cap - sizeof(string);

    //TODO: optimize me. writing in the end is bad. size is usually 64k, which is 16 pages.
    //data size is usually less than 4k and can be stored in one page, but writing in the and always needs 2 pagees: first and last
    //buf.data() is not aligned because of string internal data, so align it before writeing
    //also align ptr data + sizeof(string) in case of odd size of string itself
    new ((string*)(ptr + availcap)) string(buf); // save string object at the end of the buffer, keeping it's internal ptr alive

    uvbuf->base = ptr;
    uvbuf->len  = availcap;
}

static inline string uvx_detach_buf (const uv_buf_t* uvbuf) {
    if (!uvbuf->base) return {}; // in some cases of eof there may be no buffer
    auto buf_ptr = (string*)(uvbuf->base + uvbuf->len);
    string ret = *buf_ptr;
    buf_ptr->~string();
    return ret;
}

#define UVX_FILL_BUFS(bufs, uvbufs)     \
    uv_buf_t uvbufs[bufs.size()];       \
    uv_buf_t* ptr = uvbufs;             \
    for (const auto& str : bufs) {      \
        ptr->base = (char*)str.data();  \
        ptr->len  = str.length();       \
        ++ptr;                          \
    }

template <class Handle, class Func>
static inline net::SockAddr uvx_sockaddr (Handle uvhp, Func&& f) {
    net::SockAddr ret;
    int err;
    ret.assign_foreign([&](auto ptr, auto size_ptr){
        err = f(uvhp, ptr, (int*)size_ptr);
        return !err;
    });
    if (err) {
        if (err == UV_ENOTCONN || err == UV_EBADF || err == UV_EINVAL) return {};
        throw Error(uvx_error(err));
    }
    return ret;
}

static inline optional<fh_t> uvx_fileno (const uv_handle_t* p) {
    uv_os_fd_t fd; //should be compatible type
    int err = uv_fileno(p, &fd);
    if (!err) return {fd};
    if (err == UV_EBADF) return {};
    throw Error(uvx_error(err));
}

static inline int uvx_recv_buffer_size (const uv_handle_t* p) {
    int ret = 0;
    uvx_strict(uv_recv_buffer_size((uv_handle_t*)p, &ret));
    return ret;
}

static inline void uvx_recv_buffer_size (uv_handle_t* p, int value) {
    uvx_strict(uv_recv_buffer_size(p, &value));
}

static inline int uvx_send_buffer_size (const uv_handle_t* p) {
    int ret = 0;
    uvx_strict(uv_send_buffer_size((uv_handle_t*)p, &ret));
    return ret;
}

static inline void uvx_send_buffer_size (uv_handle_t* p, int value) {
    uvx_strict(uv_send_buffer_size(p, &value));
}

}}}}
