//
//  m3_api_uvwasi.c
//
//  Created by Colin J. Ihrig on 4/20/20.
//  Copyright © 2020 Colin J. Ihrig, Volodymyr Shymanskyy. All rights reserved.
//

#define _POSIX_C_SOURCE 200809L

#include "m3_api_wasi.h"

#include "m3_env.h"
#include "m3_exception.h"

#if defined(d_m3HasUVWASI)

#include <stdio.h>
#include <string.h>

#ifndef d_m3EnableWasiTracing
#  define d_m3EnableWasiTracing     0
#endif

#ifdef __APPLE__
# include <crt_externs.h>
# define environ (*_NSGetEnviron())
#elif !defined(_MSC_VER)
extern char** environ;
#endif

static m3_wasi_context_t* wasi_context = NULL;

typedef struct wasi_iovec_t
{
    uvwasi_size_t buf;
    uvwasi_size_t buf_len;
} wasi_iovec_t;

#if d_m3EnableWasiTracing

const char* wasi_errno2str(uvwasi_errno_t err)
{
    switch (err) {
    case  0: return "ESUCCESS";
    case  1: return "E2BIG";
    case  2: return "EACCES";
    case  3: return "EADDRINUSE";
    case  4: return "EADDRNOTAVAIL";
    case  5: return "EAFNOSUPPORT";
    case  6: return "EAGAIN";
    case  7: return "EALREADY";
    case  8: return "EBADF";
    case  9: return "EBADMSG";
    case 10: return "EBUSY";
    case 11: return "ECANCELED";
    case 12: return "ECHILD";
    case 13: return "ECONNABORTED";
    case 14: return "ECONNREFUSED";
    case 15: return "ECONNRESET";
    case 16: return "EDEADLK";
    case 17: return "EDESTADDRREQ";
    case 18: return "EDOM";
    case 19: return "EDQUOT";
    case 20: return "EEXIST";
    case 21: return "EFAULT";
    case 22: return "EFBIG";
    case 23: return "EHOSTUNREACH";
    case 24: return "EIDRM";
    case 25: return "EILSEQ";
    case 26: return "EINPROGRESS";
    case 27: return "EINTR";
    case 28: return "EINVAL";
    case 29: return "EIO";
    case 30: return "EISCONN";
    case 31: return "EISDIR";
    case 32: return "ELOOP";
    case 33: return "EMFILE";
    case 34: return "EMLINK";
    case 35: return "EMSGSIZE";
    case 36: return "EMULTIHOP";
    case 37: return "ENAMETOOLONG";
    case 38: return "ENETDOWN";
    case 39: return "ENETRESET";
    case 40: return "ENETUNREACH";
    case 41: return "ENFILE";
    case 42: return "ENOBUFS";
    case 43: return "ENODEV";
    case 44: return "ENOENT";
    case 45: return "ENOEXEC";
    case 46: return "ENOLCK";
    case 47: return "ENOLINK";
    case 48: return "ENOMEM";
    case 49: return "ENOMSG";
    case 50: return "ENOPROTOOPT";
    case 51: return "ENOSPC";
    case 52: return "ENOSYS";
    case 53: return "ENOTCONN";
    case 54: return "ENOTDIR";
    case 55: return "ENOTEMPTY";
    case 56: return "ENOTRECOVERABLE";
    case 57: return "ENOTSOCK";
    case 58: return "ENOTSUP";
    case 59: return "ENOTTY";
    case 60: return "ENXIO";
    case 61: return "EOVERFLOW";
    case 62: return "EOWNERDEAD";
    case 63: return "EPERM";
    case 64: return "EPIPE";
    case 65: return "EPROTO";
    case 66: return "EPROTONOSUPPORT";
    case 67: return "EPROTOTYPE";
    case 68: return "ERANGE";
    case 69: return "EROFS";
    case 70: return "ESPIPE";
    case 71: return "ESRCH";
    case 72: return "ESTALE";
    case 73: return "ETIMEDOUT";
    case 74: return "ETXTBSY";
    case 75: return "EXDEV";
    case 76: return "ENOTCAPABLE";
    default: return "<unknown>";
    }
}

#  define WASI_TRACE(fmt, ...)    { fprintf(stderr, "%s " fmt, __FUNCTION__+16, ##__VA_ARGS__); fprintf(stderr, " => %s\n", wasi_errno2str(ret)); }
#else
#  define WASI_TRACE(fmt, ...)
#endif

static inline
uvwasi_t* _get_uvwasi_p(IM3ImportContext _ctx) {
    m3_wasi_context_t* context = (m3_wasi_context_t*)(_ctx->userdata);
    assert(context != NULL);
    return &context->uvwasi;
}

/*
 * WASI API implementation
 */

m3ApiRawFunction(m3_wasi_generic_args_get)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArgMem   (uint32_t *           , argv)
    m3ApiGetArgMem   (char *               , argv_buf)

    m3_wasi_context_t* context = (m3_wasi_context_t*)(_ctx->userdata);

    if (context == NULL) { m3ApiReturn(UVWASI_EINVAL); }

    m3ApiCheckMem(argv, context->argc * sizeof(uint32_t));

    for (u32 i = 0; i < context->argc; ++i)
    {
        m3ApiWriteMem32(&argv[i], m3ApiPtrToOffset(argv_buf));

        size_t len = strlen (context->argv[i]);

        m3ApiCheckMem(argv_buf, len);
        memcpy (argv_buf, context->argv[i], len);
        argv_buf += len;
        * argv_buf++ = 0;
    }

    m3ApiReturn(UVWASI_ESUCCESS);
}

m3ApiRawFunction(m3_wasi_generic_args_sizes_get)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArgMem   (uvwasi_size_t *      , argc)
    m3ApiGetArgMem   (uvwasi_size_t *      , argv_buf_size)

    m3ApiCheckMem(argc,             sizeof(uvwasi_size_t));
    m3ApiCheckMem(argv_buf_size,    sizeof(uvwasi_size_t));

    m3_wasi_context_t* context = (m3_wasi_context_t*)(_ctx->userdata);

    if (context == NULL) { m3ApiReturn(UVWASI_EINVAL); }

    uvwasi_size_t buf_len = 0;
    for (u32 i = 0; i < context->argc; ++i)
    {
        buf_len += strlen (context->argv[i]) + 1;
    }

    m3ApiWriteMem32(argc, context->argc);
    m3ApiWriteMem32(argv_buf_size, buf_len);

    m3ApiReturn(UVWASI_ESUCCESS);
}

m3ApiRawFunction(m3_wasi_generic_environ_get)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArgMem   (uint32_t *           , env)
    m3ApiGetArgMem   (char *               , env_buf)

    char **environment;
    uvwasi_errno_t ret;
    uvwasi_size_t env_count, env_buf_size;

    ret = uvwasi_environ_sizes_get(_get_uvwasi_p(_ctx), &env_count, &env_buf_size);
    if (ret != UVWASI_ESUCCESS) {
        m3ApiReturn(ret);
    }

    m3ApiCheckMem(env,      env_count * sizeof(uint32_t));
    m3ApiCheckMem(env_buf,  env_buf_size);

    environment = calloc(env_count, sizeof(char *));
    if (environment == NULL) {
        m3ApiReturn(UVWASI_ENOMEM);
    }

    ret = uvwasi_environ_get(_get_uvwasi_p(_ctx), environment, env_buf);
    if (ret != UVWASI_ESUCCESS) {
        free(environment);
        m3ApiReturn(ret);
    }

    uint32_t environ_buf_offset = m3ApiPtrToOffset(env_buf);

    for (u32 i = 0; i < env_count; ++i)
    {
        uint32_t offset = environ_buf_offset +
                          (environment[i] - environment[0]);
        m3ApiWriteMem32(&env[i], offset);
    }

    free(environment);
    m3ApiReturn(UVWASI_ESUCCESS);
}

m3ApiRawFunction(m3_wasi_generic_environ_sizes_get)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArgMem   (uvwasi_size_t *      , env_count)
    m3ApiGetArgMem   (uvwasi_size_t *      , env_buf_size)

    m3ApiCheckMem(env_count,    sizeof(uvwasi_size_t));
    m3ApiCheckMem(env_buf_size, sizeof(uvwasi_size_t));

    uvwasi_size_t count;
    uvwasi_size_t buf_size;

    uvwasi_errno_t ret = uvwasi_environ_sizes_get(_get_uvwasi_p(_ctx), &count, &buf_size);

    m3ApiWriteMem32(env_count,    count);
    m3ApiWriteMem32(env_buf_size, buf_size);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_fd_prestat_dir_name)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArgMem   (char *               , path)
    m3ApiGetArg      (uvwasi_size_t        , path_len)

    m3ApiCheckMem(path, path_len);

    uvwasi_errno_t ret = uvwasi_fd_prestat_dir_name(_get_uvwasi_p(_ctx), fd, path, path_len);

    WASI_TRACE("fd:%d, len:%d | path:%s", fd, path_len, path);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_fd_prestat_get)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArgMem   (uint8_t *            , buf)

    m3ApiCheckMem(buf, 8);

    uvwasi_prestat_t prestat;

    uvwasi_errno_t ret = uvwasi_fd_prestat_get(_get_uvwasi_p(_ctx), fd, &prestat);

    WASI_TRACE("fd:%d | type:%d, name_len:%d", fd, prestat.pr_type, prestat.u.dir.pr_name_len);

    if (ret != UVWASI_ESUCCESS) {
        m3ApiReturn(ret);
    }

    m3ApiWriteMem32(buf+0, prestat.pr_type);
    m3ApiWriteMem32(buf+4, prestat.u.dir.pr_name_len);
    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_fd_fdstat_get)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArgMem   (uint8_t *            , buf)

    m3ApiCheckMem(buf, 24);

    uvwasi_fdstat_t stat;
    uvwasi_errno_t ret = uvwasi_fd_fdstat_get(_get_uvwasi_p(_ctx), fd, &stat);

    WASI_TRACE("fd:%d", fd);

    if (ret != UVWASI_ESUCCESS) {
        m3ApiReturn(ret);
    }

    memset(buf, 0, 24);
    m3ApiWriteMem8 (buf+0, stat.fs_filetype);
    m3ApiWriteMem16(buf+2, stat.fs_flags);
    m3ApiWriteMem64(buf+8, stat.fs_rights_base);
    m3ApiWriteMem64(buf+16, stat.fs_rights_inheriting);
    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_fd_fdstat_set_flags)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArg      (uvwasi_fdflags_t     , flags)

    uvwasi_errno_t ret = uvwasi_fd_fdstat_set_flags(_get_uvwasi_p(_ctx), fd, flags);

    WASI_TRACE("fd:%d, flags:0x%x", fd, flags);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_unstable_fd_filestat_get)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArgMem   (uint8_t *            , buf)

    m3ApiCheckMem(buf, 56); // wasi_filestat_t

    uvwasi_filestat_t stat;

    uvwasi_errno_t ret = uvwasi_fd_filestat_get(_get_uvwasi_p(_ctx), fd, &stat);

    WASI_TRACE("fd:%d | fs.size:%ld", fd, stat.st_size);

    if (ret != UVWASI_ESUCCESS) {
        m3ApiReturn(ret);
    }

    memset(buf, 0, 56);
    m3ApiWriteMem64(buf+0,  stat.st_dev);
    m3ApiWriteMem64(buf+8,  stat.st_ino);
    m3ApiWriteMem8 (buf+16, stat.st_filetype);
    m3ApiWriteMem32(buf+20, stat.st_nlink);
    m3ApiWriteMem64(buf+24, stat.st_size);
    m3ApiWriteMem64(buf+32, stat.st_atim);
    m3ApiWriteMem64(buf+40, stat.st_mtim);
    m3ApiWriteMem64(buf+48, stat.st_ctim);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_snapshot_preview1_fd_filestat_get)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArgMem   (uint8_t *            , buf)

    m3ApiCheckMem(buf, 64); // wasi_filestat_t

    uvwasi_filestat_t stat;

    uvwasi_errno_t ret = uvwasi_fd_filestat_get(_get_uvwasi_p(_ctx), fd, &stat);

    WASI_TRACE("fd:%d | fs.size:%ld", fd, stat.st_size);

    if (ret != UVWASI_ESUCCESS) {
        m3ApiReturn(ret);
    }

    memset(buf, 0, 64);
    m3ApiWriteMem64(buf+0,  stat.st_dev);
    m3ApiWriteMem64(buf+8,  stat.st_ino);
    m3ApiWriteMem8 (buf+16, stat.st_filetype);
    m3ApiWriteMem64(buf+24, stat.st_nlink);
    m3ApiWriteMem64(buf+32, stat.st_size);
    m3ApiWriteMem64(buf+40, stat.st_atim);
    m3ApiWriteMem64(buf+48, stat.st_mtim);
    m3ApiWriteMem64(buf+56, stat.st_ctim);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_unstable_fd_seek)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArg      (uvwasi_filedelta_t   , offset)
    m3ApiGetArg      (uint32_t             , wasi_whence)
    m3ApiGetArgMem   (uvwasi_filesize_t *  , result)

    m3ApiCheckMem(result, sizeof(uvwasi_filesize_t));

    uvwasi_whence_t whence = -1;
    const char* whstr = "???";

    switch (wasi_whence) {
    case 0: whence = UVWASI_WHENCE_CUR; whstr = "CUR"; break;
    case 1: whence = UVWASI_WHENCE_END; whstr = "END"; break;
    case 2: whence = UVWASI_WHENCE_SET; whstr = "SET"; break;
    }

    uvwasi_filesize_t pos;
    uvwasi_errno_t ret = uvwasi_fd_seek(_get_uvwasi_p(_ctx), fd, offset, whence, &pos);

    WASI_TRACE("fd:%d, offset:%ld, whence:%s | result:%ld", fd, offset, whstr, pos);

    m3ApiWriteMem64(result, pos);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_snapshot_preview1_fd_seek)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArg      (uvwasi_filedelta_t   , offset)
    m3ApiGetArg      (uint32_t             , wasi_whence)
    m3ApiGetArgMem   (uvwasi_filesize_t *  , result)

    m3ApiCheckMem(result, sizeof(uvwasi_filesize_t));

    uvwasi_whence_t whence = -1;
    const char* whstr = "???";

    switch (wasi_whence) {
    case 0: whence = UVWASI_WHENCE_SET; whstr = "SET"; break;
    case 1: whence = UVWASI_WHENCE_CUR; whstr = "CUR"; break;
    case 2: whence = UVWASI_WHENCE_END; whstr = "END"; break;
    }

    uvwasi_filesize_t pos;
    uvwasi_errno_t ret = uvwasi_fd_seek(_get_uvwasi_p(_ctx), fd, offset, whence, &pos);

    WASI_TRACE("fd:%d, offset:%ld, whence:%s | result:%ld", fd, offset, whstr, pos);

    m3ApiWriteMem64(result, pos);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_fd_renumber)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , from)
    m3ApiGetArg      (uvwasi_fd_t          , to)

    uvwasi_errno_t ret = uvwasi_fd_renumber(_get_uvwasi_p(_ctx), from, to);

    WASI_TRACE("from:%d, to:%d", from, to);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_fd_sync)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)

    uvwasi_errno_t ret = uvwasi_fd_sync(_get_uvwasi_p(_ctx), fd);

    WASI_TRACE("fd:%d", fd);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_fd_tell)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArgMem   (uvwasi_filesize_t *  , result)

    m3ApiCheckMem(result, sizeof(uvwasi_filesize_t));

    uvwasi_filesize_t pos;
    uvwasi_errno_t ret = uvwasi_fd_tell(_get_uvwasi_p(_ctx), fd, &pos);

    WASI_TRACE("fd:%d | result:%d", fd, *result);

    m3ApiWriteMem64(result, pos);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_path_create_directory)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArgMem   (const char *         , path)
    m3ApiGetArg      (uvwasi_size_t        , path_len)

    m3ApiCheckMem(path, path_len);

    uvwasi_errno_t ret = uvwasi_path_create_directory(_get_uvwasi_p(_ctx), fd, path, path_len);

    WASI_TRACE("fd:%d, path:%s", fd, path);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_path_readlink)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArgMem   (const char *         , path)
    m3ApiGetArg      (uvwasi_size_t        , path_len)
    m3ApiGetArgMem   (char *               , buf)
    m3ApiGetArg      (uvwasi_size_t        , buf_len)
    m3ApiGetArgMem   (uvwasi_size_t *      , bufused)

    m3ApiCheckMem(path, path_len);
    m3ApiCheckMem(buf, buf_len);
    m3ApiCheckMem(bufused, sizeof(uvwasi_size_t));

    uvwasi_size_t uvbufused;

    uvwasi_errno_t ret = uvwasi_path_readlink(_get_uvwasi_p(_ctx), fd, path, path_len, buf, buf_len, &uvbufused);

    WASI_TRACE("fd:%d, path:%s | buf:%s, bufused:%d", fd, path, buf, uvbufused);

    m3ApiWriteMem32(bufused, uvbufused);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_path_remove_directory)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArgMem   (const char *         , path)
    m3ApiGetArg      (uvwasi_size_t        , path_len)

    m3ApiCheckMem(path, path_len);

    uvwasi_errno_t ret = uvwasi_path_remove_directory(_get_uvwasi_p(_ctx), fd, path, path_len);

    WASI_TRACE("fd:%d, path:%s", fd, path);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_path_rename)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , old_fd)
    m3ApiGetArgMem   (const char *         , old_path)
    m3ApiGetArg      (uvwasi_size_t        , old_path_len)
    m3ApiGetArg      (uvwasi_fd_t          , new_fd)
    m3ApiGetArgMem   (const char *         , new_path)
    m3ApiGetArg      (uvwasi_size_t        , new_path_len)

    m3ApiCheckMem(old_path, old_path_len);
    m3ApiCheckMem(new_path, new_path_len);

    uvwasi_errno_t ret = uvwasi_path_rename(_get_uvwasi_p(_ctx), old_fd, old_path, old_path_len,
                                                     new_fd, new_path, new_path_len);

    WASI_TRACE("old_fd:%d, old_path:%s, new_fd:%d, new_path:%s", old_fd, old_path, new_fd, new_path);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_path_symlink)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArgMem   (const char *         , old_path)
    m3ApiGetArg      (uvwasi_size_t        , old_path_len)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArgMem   (const char *         , new_path)
    m3ApiGetArg      (uvwasi_size_t        , new_path_len)

    m3ApiCheckMem(old_path, old_path_len);
    m3ApiCheckMem(new_path, new_path_len);

    uvwasi_errno_t ret = uvwasi_path_symlink(_get_uvwasi_p(_ctx), old_path, old_path_len,
                                                  fd, new_path, new_path_len);

    WASI_TRACE("old_path:%s, fd:%d, new_path:%s", old_path, fd, new_path);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_path_unlink_file)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArgMem   (const char *         , path)
    m3ApiGetArg      (uvwasi_size_t        , path_len)

    m3ApiCheckMem(path, path_len);

    uvwasi_errno_t ret = uvwasi_path_unlink_file(_get_uvwasi_p(_ctx), fd, path, path_len);

    WASI_TRACE("fd:%d, path:%s", fd, path);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_path_open)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , dirfd)
    m3ApiGetArg      (uvwasi_lookupflags_t , dirflags)
    m3ApiGetArgMem   (const char *         , path)
    m3ApiGetArg      (uvwasi_size_t        , path_len)
    m3ApiGetArg      (uvwasi_oflags_t      , oflags)
    m3ApiGetArg      (uvwasi_rights_t      , fs_rights_base)
    m3ApiGetArg      (uvwasi_rights_t      , fs_rights_inheriting)
    m3ApiGetArg      (uvwasi_fdflags_t     , fs_flags)
    m3ApiGetArgMem   (uvwasi_fd_t *        , fd)

    m3ApiCheckMem(path, path_len);
    m3ApiCheckMem(fd,   sizeof(uvwasi_fd_t));

    uvwasi_fd_t uvfd;

    uvwasi_errno_t ret = uvwasi_path_open(_get_uvwasi_p(_ctx),
                                 dirfd,
                                 dirflags,
                                 path,
                                 path_len,
                                 oflags,
                                 fs_rights_base,
                                 fs_rights_inheriting,
                                 fs_flags,
                                 &uvfd);

    WASI_TRACE("dirfd:%d, dirflags:0x%x, path:%s, oflags:0x%x, fs_flags:0x%x | fd:%d", dirfd, dirflags, path, oflags, fs_flags, uvfd);

    m3ApiWriteMem32(fd, uvfd);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_unstable_path_filestat_get)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArg      (uvwasi_lookupflags_t , flags)
    m3ApiGetArgMem   (const char *         , path)
    m3ApiGetArg      (uint32_t             , path_len)
    m3ApiGetArgMem   (uint8_t *            , buf)

    m3ApiCheckMem(path, path_len);
    m3ApiCheckMem(buf,  56); // wasi_filestat_t

    uvwasi_filestat_t stat;

    uvwasi_errno_t ret = uvwasi_path_filestat_get(_get_uvwasi_p(_ctx), fd, flags, path, path_len, &stat);

    WASI_TRACE("fd:%d, flags:0x%x, path:%s | fs.size:%d", fd, flags, path, stat.st_size);

    if (ret != UVWASI_ESUCCESS) {
        m3ApiReturn(ret);
    }

    memset(buf, 0, 56);
    m3ApiWriteMem64(buf+0,  stat.st_dev);
    m3ApiWriteMem64(buf+8,  stat.st_ino);
    m3ApiWriteMem8 (buf+16, stat.st_filetype);
    m3ApiWriteMem32(buf+20, stat.st_nlink);
    m3ApiWriteMem64(buf+24, stat.st_size);
    m3ApiWriteMem64(buf+32, stat.st_atim);
    m3ApiWriteMem64(buf+40, stat.st_mtim);
    m3ApiWriteMem64(buf+48, stat.st_ctim);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_snapshot_preview1_path_filestat_get)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArg      (uvwasi_lookupflags_t , flags)
    m3ApiGetArgMem   (const char *         , path)
    m3ApiGetArg      (uint32_t             , path_len)
    m3ApiGetArgMem   (uint8_t *            , buf)

    m3ApiCheckMem(path, path_len);
    m3ApiCheckMem(buf,  64); // wasi_filestat_t

    uvwasi_filestat_t stat;

    uvwasi_errno_t ret = uvwasi_path_filestat_get(_get_uvwasi_p(_ctx), fd, flags, path, path_len, &stat);

    WASI_TRACE("fd:%d, flags:0x%x, path:%s | fs.size:%d", fd, flags, path, stat.st_size);

    if (ret != UVWASI_ESUCCESS) {
        m3ApiReturn(ret);
    }

    memset(buf, 0, 64);
    m3ApiWriteMem64(buf+0,  stat.st_dev);
    m3ApiWriteMem64(buf+8,  stat.st_ino);
    m3ApiWriteMem8 (buf+16, stat.st_filetype);
    m3ApiWriteMem64(buf+24, stat.st_nlink);
    m3ApiWriteMem64(buf+32, stat.st_size);
    m3ApiWriteMem64(buf+40, stat.st_atim);
    m3ApiWriteMem64(buf+48, stat.st_mtim);
    m3ApiWriteMem64(buf+56, stat.st_ctim);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_fd_pread)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArgMem   (wasi_iovec_t *       , wasi_iovs)
    m3ApiGetArg      (uvwasi_size_t        , iovs_len)
    m3ApiGetArg      (uvwasi_filesize_t    , offset)
    m3ApiGetArgMem   (uvwasi_size_t *      , nread)

    m3ApiCheckMem(wasi_iovs,    iovs_len * sizeof(wasi_iovec_t));
    m3ApiCheckMem(nread,        sizeof(uvwasi_size_t));

#if defined(M3_COMPILER_MSVC)
    if (iovs_len > 32) m3ApiReturn(UVWASI_EINVAL);
    uvwasi_ciovec_t  iovs[32];
#else
    if (iovs_len > 128) m3ApiReturn(UVWASI_EINVAL);
    uvwasi_ciovec_t  iovs[iovs_len];
#endif

    for (uvwasi_size_t i = 0; i < iovs_len; ++i) {
        iovs[i].buf = m3ApiOffsetToPtr(m3ApiReadMem32(&wasi_iovs[i].buf));
        iovs[i].buf_len = m3ApiReadMem32(&wasi_iovs[i].buf_len);
        m3ApiCheckMem(iovs[i].buf,     iovs[i].buf_len);
        //fprintf(stderr, "> fd_pread fd:%d iov%d.len:%d\n", fd, i, iovs[i].buf_len);
    }

    uvwasi_size_t num_read;

    uvwasi_errno_t ret = uvwasi_fd_pread(_get_uvwasi_p(_ctx), fd, (const uvwasi_iovec_t *) iovs, iovs_len, offset, &num_read);

    WASI_TRACE("fd:%d | nread:%d", fd, num_read);

    m3ApiWriteMem32(nread, num_read);
    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_fd_read)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArgMem   (wasi_iovec_t *       , wasi_iovs)
    m3ApiGetArg      (uvwasi_size_t        , iovs_len)
    m3ApiGetArgMem   (uvwasi_size_t *      , nread)

    m3ApiCheckMem(wasi_iovs,    iovs_len * sizeof(wasi_iovec_t));
    m3ApiCheckMem(nread,        sizeof(uvwasi_size_t));

#if defined(M3_COMPILER_MSVC)
    if (iovs_len > 32) m3ApiReturn(UVWASI_EINVAL);
    uvwasi_ciovec_t  iovs[32];
#else
    if (iovs_len > 128) m3ApiReturn(UVWASI_EINVAL);
    uvwasi_ciovec_t  iovs[iovs_len];
#endif
    uvwasi_size_t num_read;
    uvwasi_errno_t ret;

    for (uvwasi_size_t i = 0; i < iovs_len; ++i) {
        iovs[i].buf = m3ApiOffsetToPtr(m3ApiReadMem32(&wasi_iovs[i].buf));
        iovs[i].buf_len = m3ApiReadMem32(&wasi_iovs[i].buf_len);
        m3ApiCheckMem(iovs[i].buf,     iovs[i].buf_len);
        //fprintf(stderr, "> fd_read fd:%d iov%d.len:%d\n", fd, i, iovs[i].buf_len);
    }

    ret = uvwasi_fd_read(_get_uvwasi_p(_ctx), fd, (const uvwasi_iovec_t *) iovs, iovs_len, &num_read);

    WASI_TRACE("fd:%d | nread:%d", fd, num_read);

    m3ApiWriteMem32(nread, num_read);
    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_fd_write)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArgMem   (wasi_iovec_t *       , wasi_iovs)
    m3ApiGetArg      (uvwasi_size_t        , iovs_len)
    m3ApiGetArgMem   (uvwasi_size_t *      , nwritten)

    m3ApiCheckMem(wasi_iovs,    iovs_len * sizeof(wasi_iovec_t));
    m3ApiCheckMem(nwritten,     sizeof(uvwasi_size_t));

#if defined(M3_COMPILER_MSVC)
    if (iovs_len > 32) m3ApiReturn(UVWASI_EINVAL);
    uvwasi_ciovec_t  iovs[32];
#else
    if (iovs_len > 128) m3ApiReturn(UVWASI_EINVAL);
    uvwasi_ciovec_t  iovs[iovs_len];
#endif
    uvwasi_size_t num_written;
    uvwasi_errno_t ret;

    for (uvwasi_size_t i = 0; i < iovs_len; ++i) {
        iovs[i].buf = m3ApiOffsetToPtr(m3ApiReadMem32(&wasi_iovs[i].buf));
        iovs[i].buf_len = m3ApiReadMem32(&wasi_iovs[i].buf_len);
        m3ApiCheckMem(iovs[i].buf,     iovs[i].buf_len);
    }

    ret = uvwasi_fd_write(_get_uvwasi_p(_ctx), fd, iovs, iovs_len, &num_written);

    WASI_TRACE("fd:%d | nwritten:%d", fd, num_written);

    m3ApiWriteMem32(nwritten, num_written);
    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_fd_pwrite)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArgMem   (wasi_iovec_t *       , wasi_iovs)
    m3ApiGetArg      (uvwasi_size_t        , iovs_len)
    m3ApiGetArg      (uvwasi_filesize_t    , offset)
    m3ApiGetArgMem   (uvwasi_size_t *      , nwritten)

    m3ApiCheckMem(wasi_iovs,    iovs_len * sizeof(wasi_iovec_t));
    m3ApiCheckMem(nwritten,     sizeof(uvwasi_size_t));

#if defined(M3_COMPILER_MSVC)
    if (iovs_len > 32) m3ApiReturn(UVWASI_EINVAL);
    uvwasi_ciovec_t  iovs[32];
#else
    if (iovs_len > 128) m3ApiReturn(UVWASI_EINVAL);
    uvwasi_ciovec_t  iovs[iovs_len];
#endif
    uvwasi_size_t num_written;
    uvwasi_errno_t ret;

    for (uvwasi_size_t i = 0; i < iovs_len; ++i) {
        iovs[i].buf = m3ApiOffsetToPtr(m3ApiReadMem32(&wasi_iovs[i].buf));
        iovs[i].buf_len = m3ApiReadMem32(&wasi_iovs[i].buf_len);
        m3ApiCheckMem(iovs[i].buf,     iovs[i].buf_len);
    }

    ret = uvwasi_fd_pwrite(_get_uvwasi_p(_ctx), fd, iovs, iovs_len, offset, &num_written);

    WASI_TRACE("fd:%d | nwritten:%d", fd, num_written);

    m3ApiWriteMem32(nwritten, num_written);
    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_fd_readdir)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t          , fd)
    m3ApiGetArgMem   (void *               , buf)
    m3ApiGetArg      (uvwasi_size_t        , buf_len)
    m3ApiGetArg      (uvwasi_dircookie_t   , cookie)
    m3ApiGetArgMem   (uvwasi_size_t *      , bufused)

    m3ApiCheckMem(buf,      buf_len);
    m3ApiCheckMem(bufused,  sizeof(uvwasi_size_t));

    uvwasi_size_t uvbufused;
    uvwasi_errno_t ret = uvwasi_fd_readdir(_get_uvwasi_p(_ctx), fd, buf, buf_len, cookie, &uvbufused);

    WASI_TRACE("fd:%d | bufused:%d", fd, uvbufused);

    m3ApiWriteMem32(bufused, uvbufused);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_fd_close)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t, fd)

    uvwasi_errno_t ret = uvwasi_fd_close(_get_uvwasi_p(_ctx), fd);

    WASI_TRACE("fd:%d", fd);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_fd_datasync)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_fd_t, fd)

    uvwasi_errno_t ret = uvwasi_fd_datasync(_get_uvwasi_p(_ctx), fd);

    WASI_TRACE("fd:%d", fd);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_random_get)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArgMem   (uint8_t *            , buf)
    m3ApiGetArg      (uvwasi_size_t        , buf_len)

    m3ApiCheckMem(buf, buf_len);

    uvwasi_errno_t ret = uvwasi_random_get(_get_uvwasi_p(_ctx), buf, buf_len);

    WASI_TRACE("len:%d", buf_len);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_clock_res_get)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_clockid_t     , wasi_clk_id)
    m3ApiGetArgMem   (uvwasi_timestamp_t * , resolution)

    m3ApiCheckMem(resolution, sizeof(uvwasi_timestamp_t));

    uvwasi_timestamp_t t;
    uvwasi_errno_t ret = uvwasi_clock_res_get(_get_uvwasi_p(_ctx), wasi_clk_id, &t);

    WASI_TRACE("clk_id:%d", wasi_clk_id);

    m3ApiWriteMem64(resolution, t);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_clock_time_get)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_clockid_t     , wasi_clk_id)
    m3ApiGetArg      (uvwasi_timestamp_t   , precision)
    m3ApiGetArgMem   (uvwasi_timestamp_t * , time)

    m3ApiCheckMem(time, sizeof(uvwasi_timestamp_t));

    uvwasi_timestamp_t t;
    uvwasi_errno_t ret = uvwasi_clock_time_get(_get_uvwasi_p(_ctx), wasi_clk_id, precision, &t);

    WASI_TRACE("clk_id:%d", wasi_clk_id);

    m3ApiWriteMem64(time, t);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_poll_oneoff)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArgMem   (const uvwasi_subscription_t * , in)
    m3ApiGetArgMem   (uvwasi_event_t *              , out)
    m3ApiGetArg      (uvwasi_size_t                 , nsubscriptions)
    m3ApiGetArgMem   (uvwasi_size_t *               , nevents)

    m3ApiCheckMem(in,       nsubscriptions * sizeof(uvwasi_subscription_t));
    m3ApiCheckMem(out,      nsubscriptions * sizeof(uvwasi_event_t));
    m3ApiCheckMem(nevents,  sizeof(uvwasi_size_t));

    // TODO: unstable/snapshot_preview1 compatibility

    uvwasi_errno_t ret = uvwasi_poll_oneoff(_get_uvwasi_p(_ctx), in, out, nsubscriptions, nevents);

    WASI_TRACE("nsubscriptions:%d | nevents:%d", nsubscriptions, *nevents);

    //TODO: m3ApiWriteMem

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_proc_exit)
{
    m3ApiGetArg      (uint32_t, code)

    m3_wasi_context_t* context = (m3_wasi_context_t*)(_ctx->userdata);

    if (context) {
        context->exit_code = code;
    }

    //TODO: fprintf(stderr, "proc_exit code:%d\n", code);

    m3ApiTrap(m3Err_trapExit);
}

m3ApiRawFunction(m3_wasi_generic_proc_raise)
{
    m3ApiReturnType  (uint32_t)
    m3ApiGetArg      (uvwasi_signal_t, sig)

    uvwasi_errno_t ret = uvwasi_proc_raise(_get_uvwasi_p(_ctx), sig);

    WASI_TRACE("sig:%d", sig);

    m3ApiReturn(ret);
}

m3ApiRawFunction(m3_wasi_generic_sched_yield)
{
    m3ApiReturnType  (uint32_t)
    uvwasi_errno_t ret = uvwasi_sched_yield(_get_uvwasi_p(_ctx));

    WASI_TRACE("");

    m3ApiReturn(ret);
}


static
M3Result SuppressLookupFailure(M3Result i_result)
{
    if (i_result == m3Err_functionLookupFailed)
        return m3Err_none;
    else
        return i_result;
}

m3_wasi_context_t* m3_GetWasiContext()
{
    return wasi_context;
}

m3_wasi_context_t* m3_GetModuleWasiContext(IM3Module module) {
    return module->wasi;
}

void m3_FreeWasi(m3_wasi_context_t* wasi)
{
    uvwasi_destroy(&wasi->uvwasi);
    m3_Free(wasi);
}

static const char* const DEFAULT_ENVIRONMENT[] = {
    "TERM=xterm-256color",
    "COLORTERM=truecolor",
    "LANG=en_US.UTF-8",
    "PWD=/",
    "HOME=/",
    "PATH=/",
    "WASM3=1",
    "WASM3_ARCH=" M3_ARCH,
    NULL,
};

static const uvwasi_preopen_t const DEFAULT_PREOPENS[] = {
    {
        .mapped_path = "/",
        .real_path = ".",
    },
    {
        .mapped_path = "./",
        .real_path = ".",
    },
};

static inline
void _m3_set_up_default_uvwasi_opts(uvwasi_options_t* opts_p) {

    uvwasi_options_init(opts_p);
    opts_p->argc = 0;      // runtime->argc is not initialized at this point, so we implement args_get directly
    opts_p->envp = DEFAULT_ENVIRONMENT;
    opts_p->preopenc = sizeof(DEFAULT_PREOPENS) / sizeof(uvwasi_preopen_t);
    opts_p->preopens = DEFAULT_PREOPENS;
}

static
M3Result  _linkWASI (IM3Module module, uvwasi_options_t init_options, m3_wasi_context_t* wasi_context)
{
    M3Result result = m3Err_none;

    static const char* namespaces[2] = { "wasi_unstable", "wasi_snapshot_preview1" };

    // Some functions are incompatible between WASI versions
_   (SuppressLookupFailure (m3_LinkRawFunctionEx (module, "wasi_unstable",          "fd_seek",           "i(iIi*)",   &m3_wasi_unstable_fd_seek, wasi_context)));
_   (SuppressLookupFailure (m3_LinkRawFunctionEx (module, "wasi_snapshot_preview1", "fd_seek",           "i(iIi*)",   &m3_wasi_snapshot_preview1_fd_seek, wasi_context)));
_   (SuppressLookupFailure (m3_LinkRawFunctionEx (module, "wasi_unstable",          "fd_filestat_get",   "i(i*)",     &m3_wasi_unstable_fd_filestat_get, wasi_context)));
_   (SuppressLookupFailure (m3_LinkRawFunctionEx (module, "wasi_snapshot_preview1", "fd_filestat_get",   "i(i*)",     &m3_wasi_snapshot_preview1_fd_filestat_get, wasi_context)));
_   (SuppressLookupFailure (m3_LinkRawFunctionEx (module, "wasi_unstable",          "path_filestat_get", "i(ii*i*)",  &m3_wasi_unstable_path_filestat_get, wasi_context)));
_   (SuppressLookupFailure (m3_LinkRawFunctionEx (module, "wasi_snapshot_preview1", "path_filestat_get", "i(ii*i*)",  &m3_wasi_snapshot_preview1_path_filestat_get, wasi_context)));

    for (int i=0; i<2; i++)
    {
        const char* wasi = namespaces[i];

_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "args_get",           "i(**)",   &m3_wasi_generic_args_get, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "args_sizes_get",     "i(**)",   &m3_wasi_generic_args_sizes_get, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "clock_res_get",        "i(i*)",   &m3_wasi_generic_clock_res_get, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "clock_time_get",       "i(iI*)",  &m3_wasi_generic_clock_time_get, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "environ_get",          "i(**)",   &m3_wasi_generic_environ_get, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "environ_sizes_get",    "i(**)",   &m3_wasi_generic_environ_sizes_get, wasi_context)));

//_     (SuppressLookupFailure (m3_LinkRawFunction (module, wasi, "fd_advise",            "i(iIIi)", )));
//_     (SuppressLookupFailure (m3_LinkRawFunction (module, wasi, "fd_allocate",          "i(iII)",  )));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "fd_close",             "i(i)",    &m3_wasi_generic_fd_close, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "fd_datasync",          "i(i)",    &m3_wasi_generic_fd_datasync, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "fd_fdstat_get",        "i(i*)",   &m3_wasi_generic_fd_fdstat_get, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "fd_fdstat_set_flags",  "i(ii)",   &m3_wasi_generic_fd_fdstat_set_flags, wasi_context)));
//_     (SuppressLookupFailure (m3_LinkRawFunction (module, wasi, "fd_fdstat_set_rights", "i(iII)",  )));
//_     (SuppressLookupFailure (m3_LinkRawFunction (module, wasi, "fd_filestat_set_size", "i(iI)",   )));
//_     (SuppressLookupFailure (m3_LinkRawFunction (module, wasi, "fd_filestat_set_times","i(iIIi)", )));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "fd_pread",             "i(i*iI*)",&m3_wasi_generic_fd_pread, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "fd_prestat_get",       "i(i*)",   &m3_wasi_generic_fd_prestat_get, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "fd_prestat_dir_name",  "i(i*i)",  &m3_wasi_generic_fd_prestat_dir_name, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "fd_pwrite",            "i(i*iI*)",&m3_wasi_generic_fd_pwrite, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "fd_read",              "i(i*i*)", &m3_wasi_generic_fd_read, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "fd_readdir",           "i(i*iI*)",&m3_wasi_generic_fd_readdir, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "fd_renumber",          "i(ii)",   &m3_wasi_generic_fd_renumber, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "fd_sync",              "i(i)",    &m3_wasi_generic_fd_sync, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "fd_tell",              "i(i*)",   &m3_wasi_generic_fd_tell, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "fd_write",             "i(i*i*)", &m3_wasi_generic_fd_write, wasi_context)));

_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "path_create_directory",    "i(i*i)",       &m3_wasi_generic_path_create_directory, wasi_context)));
//_     (SuppressLookupFailure (m3_LinkRawFunction (module, wasi, "path_filestat_set_times",  "i(ii*iIIi)",   )));
//_     (SuppressLookupFailure (m3_LinkRawFunction (module, wasi, "path_link",                "i(ii*ii*i)",   )));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "path_open",                "i(ii*iiIIi*)", &m3_wasi_generic_path_open, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "path_readlink",            "i(i*i*i*)",    &m3_wasi_generic_path_readlink, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "path_remove_directory",    "i(i*i)",       &m3_wasi_generic_path_remove_directory, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "path_rename",              "i(i*ii*i)",    &m3_wasi_generic_path_rename, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "path_symlink",             "i(*ii*i)",     &m3_wasi_generic_path_symlink, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "path_unlink_file",         "i(i*i)",       &m3_wasi_generic_path_unlink_file, wasi_context)));

_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "poll_oneoff",          "i(**i*)", &m3_wasi_generic_poll_oneoff, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "proc_exit",          "v(i)",    &m3_wasi_generic_proc_exit, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "proc_raise",           "i(i)",    &m3_wasi_generic_proc_raise, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "random_get",           "i(*i)",   &m3_wasi_generic_random_get, wasi_context)));
_       (SuppressLookupFailure (m3_LinkRawFunctionEx (module, wasi, "sched_yield",          "i()",     &m3_wasi_generic_sched_yield, wasi_context)));

//_     (SuppressLookupFailure (m3_LinkRawFunction (module, wasi, "sock_recv",            "i(i*ii**)",        )));
//_     (SuppressLookupFailure (m3_LinkRawFunction (module, wasi, "sock_send",            "i(i*ii*)",         )));
//_     (SuppressLookupFailure (m3_LinkRawFunction (module, wasi, "sock_shutdown",        "i(ii)",            )));
    }

_catch:
    return result;
}

M3Result  m3_LinkWASI  (IM3Module module)
{
    uvwasi_options_t opts;
    _m3_set_up_default_uvwasi_opts(&opts);

    return m3_LinkWASIWithOptions(module, opts);
}

M3Result  m3_LinkModuleWASI  (IM3Module module)
{
    uvwasi_options_t opts;
    _m3_set_up_default_uvwasi_opts(&opts);

    return m3_LinkModuleWASIWithOptions(module, opts);
}

M3Result _create_wasi_ctx(m3_wasi_context_t** ctx_p, uvwasi_options_t init_options) {
    *ctx_p = m3_AllocStruct(m3_wasi_context_t);

    uvwasi_errno_t ret = uvwasi_init(&(*ctx_p)->uvwasi, &init_options);

    if (ret != UVWASI_ESUCCESS) {
        return "uvwasi_init failed";
    }

    return m3Err_none;
}

M3Result  m3_LinkWASIWithOptions  (IM3Module module, uvwasi_options_t init_options)
{
    if (NULL == wasi_context) {
        M3Result res = _create_wasi_ctx(&wasi_context, init_options);
        if (res) return res;
    }

    return _linkWASI(module, init_options, wasi_context);
}

M3Result  m3_LinkModuleWASIWithOptions  (IM3Module module, uvwasi_options_t init_options)
{
    if (NULL == module->wasi) {
        M3Result res = _create_wasi_ctx(&module->wasi, init_options);
        if (res) return res;
    }
    else {
        // TODO:  Need a new error code here.
    }

    return _linkWASI(module, init_options, module->wasi);
}

#endif // d_m3HasUVWASI

