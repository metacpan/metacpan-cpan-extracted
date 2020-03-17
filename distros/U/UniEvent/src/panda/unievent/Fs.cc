#include "Fs.h"
#include <uv.h>
#include "util.h"

using namespace panda::unievent;
using panda::string;
using panda::string_view;

template <class T>
using ex = Fs::ex<T>;

#ifdef _WIN32
    #define UE_SLASH '\\'
#else
    #define UE_SLASH '/'
#endif

const HandleType Fs::TYPE("fs");

const int Fs::OpenFlags::APPEND      = UV_FS_O_APPEND;
const int Fs::OpenFlags::CREAT       = UV_FS_O_CREAT;
const int Fs::OpenFlags::DIRECT      = UV_FS_O_DIRECT;
const int Fs::OpenFlags::DIRECTORY   = UV_FS_O_DIRECTORY;
const int Fs::OpenFlags::DSYNC       = UV_FS_O_DSYNC;
const int Fs::OpenFlags::EXCL        = UV_FS_O_EXCL;
const int Fs::OpenFlags::EXLOCK      = UV_FS_O_EXLOCK;
const int Fs::OpenFlags::NOATIME     = UV_FS_O_NOATIME;
const int Fs::OpenFlags::NOCTTY      = UV_FS_O_NOCTTY;
const int Fs::OpenFlags::NOFOLLOW    = UV_FS_O_NOFOLLOW;
const int Fs::OpenFlags::NONBLOCK    = UV_FS_O_NONBLOCK;
const int Fs::OpenFlags::RANDOM      = UV_FS_O_RANDOM;
const int Fs::OpenFlags::RDONLY      = UV_FS_O_RDONLY;
const int Fs::OpenFlags::RDWR        = UV_FS_O_RDWR;
const int Fs::OpenFlags::SEQUENTIAL  = UV_FS_O_SEQUENTIAL;
const int Fs::OpenFlags::SHORT_LIVED = UV_FS_O_SHORT_LIVED;
const int Fs::OpenFlags::SYMLINK     = UV_FS_O_SYMLINK;
const int Fs::OpenFlags::SYNC        = UV_FS_O_SYNC;
const int Fs::OpenFlags::TEMPORARY   = UV_FS_O_TEMPORARY;
const int Fs::OpenFlags::TRUNC       = UV_FS_O_TRUNC;
const int Fs::OpenFlags::WRONLY      = UV_FS_O_WRONLY;

const int Fs::SymlinkFlags::DIR      = UV_FS_SYMLINK_DIR;
const int Fs::SymlinkFlags::JUNCTION = UV_FS_SYMLINK_JUNCTION;

const int Fs::CopyFileFlags::EXCL          = UV_FS_COPYFILE_EXCL;
const int Fs::CopyFileFlags::FICLONE       = UV_FS_COPYFILE_FICLONE;
const int Fs::CopyFileFlags::FICLONE_FORCE = UV_FS_COPYFILE_FICLONE_FORCE;

static inline void uvx_ts2ue (const uv_timespec_t& from, TimeSpec& to) {
    to.sec  = from.tv_sec;
    to.nsec = from.tv_nsec;
}

static inline void uvx_stat2ue (const uv_stat_t* from, Fs::FStat& to) {
    to.dev     = from->st_dev;
    to.mode    = from->st_mode;
    to.nlink   = from->st_nlink;
    to.uid     = from->st_uid;
    to.gid     = from->st_gid;
    to.rdev    = from->st_rdev;
    to.ino     = from->st_ino;
    to.size    = from->st_size;
    to.blksize = from->st_blksize;
    to.blocks  = from->st_blocks;
    to.flags   = from->st_flags;
    to.gen     = from->st_gen;
    uvx_ts2ue(from->st_atim, to.atime);
    uvx_ts2ue(from->st_mtim, to.mtime);
    uvx_ts2ue(from->st_ctim, to.ctime);
    uvx_ts2ue(from->st_birthtim, to.birthtime);
}

Fs::FileType Fs::ftype (uint64_t mode) {
    #ifdef _WIN32
        switch (mode & _S_IFMT) {
            case _S_IFDIR: return FileType::DIR;
            case _S_IFCHR: return FileType::CHAR;
            case _S_IFREG: return FileType::FILE;
        }
    #else
        switch (mode & S_IFMT) {
            case S_IFBLK:  return FileType::BLOCK;
            case S_IFCHR:  return FileType::CHAR;
            case S_IFDIR:  return FileType::DIR;
            case S_IFIFO:  return FileType::FIFO;
            case S_IFLNK:  return FileType::LINK;
            case S_IFREG:  return FileType::FILE;
            case S_IFSOCK: return FileType::SOCKET;

        }
    #endif
    return FileType::UNKNOWN;
}

static inline Fs::FileType uvx_ftype (uv_dirent_type_t uvt) {
    switch (uvt) {
        case UV_DIRENT_UNKNOWN : return Fs::FileType::UNKNOWN;
        case UV_DIRENT_FILE    : return Fs::FileType::FILE;
        case UV_DIRENT_DIR     : return Fs::FileType::DIR;
        case UV_DIRENT_LINK    : return Fs::FileType::LINK;
        case UV_DIRENT_FIFO    : return Fs::FileType::FIFO;
        case UV_DIRENT_SOCKET  : return Fs::FileType::SOCKET;
        case UV_DIRENT_CHAR    : return Fs::FileType::CHAR;
        case UV_DIRENT_BLOCK   : return Fs::FileType::BLOCK;
    }
    abort(); // not reachable
}

bool Fs::FStat::operator== (const Fs::FStat& oth) const {
    return memcmp(this, &oth, sizeof(Fs::FStat)) == 0;
}

/* ===============================================================================================
   =================================== SYNC API ==================================================
   =============================================================================================== */

#define UEFS_SYNC(call_code, result_code) {                                 \
    uv_fs_t uvr;                                                            \
    uvr.loop = nullptr;                                                     \
    call_code                                                               \
    if (uvr.result < 0) return make_unexpected(uvx_code_error(uvr.result)); \
    result_code                                                             \
    uv_fs_req_cleanup(&uvr);                                                \
}

ex<void> Fs::mkdir (string_view path, int mode) {
    UE_NULL_TERMINATE(path, path_str);
    UEFS_SYNC({
        uv_fs_mkdir(nullptr, &uvr, path_str, mode, nullptr);
    }, {});
    return {};
}

ex<void> Fs::rmdir (string_view path) {
    UE_NULL_TERMINATE(path, path_str);
    UEFS_SYNC({
        uv_fs_rmdir(nullptr, &uvr, path_str, nullptr);
    }, {});
    return {};
}

ex<void> Fs::remove (string_view path) {
    return isdir(path) ? rmdir(path) : unlink(path);
}

ex<void> Fs::mkpath (string_view path, int mode) {
    auto len = path.length();
    if (!len) return {};
    size_t pos = 0;

    auto skip_slash = [&]() { while (pos < len && (path[pos] == '/' || path[pos] == '\\')) ++pos; };
    auto find_part  = [&]() { while (pos < len && path[pos] != '/' && path[pos] != '\\') ++pos; };

    #ifdef _WIN32
      auto dpos = path.find_first_of(':');
      if (dpos != string_view::npos) pos = dpos + 1;
    #endif
    skip_slash();

    // root folder ('/') or drives ('C:\') always exist
    while (pos < len) {
        find_part();
        auto ret = mkdir(path.substr(0, pos), mode);
        if (!ret && ret.error() != std::errc::file_exists) return ret;
        skip_slash();
    }

    return {};
}

ex<Fs::DirEntries> Fs::scandir (string_view path) {
    DirEntries ret;
    UE_NULL_TERMINATE(path, path_str);
    UEFS_SYNC({
        uv_fs_scandir(nullptr, &uvr, path_str, 0, nullptr);
    }, {
        size_t cnt = (size_t)uvr.result;
        if (cnt) {
            ret.reserve(cnt);
            uv_dirent_t uvent;
            while (uv_fs_scandir_next(&uvr, &uvent) == 0) ret.emplace(ret.cend(), string(uvent.name), uvx_ftype(uvent.type));
        }
    });
    return std::move(ret);
}

static inline ex<void> _rmtree (string_view path) {
    auto plen = path.length();
    return Fs::scandir(path).and_then([&](const Fs::DirEntries& entries) {
        for (const auto& entry : entries) {
            auto elen = entry.name().length();
            auto fnlen = plen + elen + 1;
            char _fn[fnlen];
            char* ptr = _fn;
            memcpy(ptr, path.data(), plen);
            ptr += plen;
            *ptr++ = UE_SLASH;
            memcpy(ptr, entry.name().data(), elen);

            string_view fname(_fn, fnlen);
            if (entry.type() == Fs::FileType::DIR) {
                auto ret = _rmtree(fname);
                if (!ret) return ret;
            } else {
                auto ret = Fs::unlink(fname);
                if (!ret) return ret;
            }
        }
        return Fs::rmdir(path);
    });
}

ex<void> Fs::remove_all (string_view path) {
    return isdir(path) ? _rmtree(path) : unlink(path);
}

ex<fd_t> Fs::open (string_view path, int flags, int mode) {
    fd_t ret;
    UE_NULL_TERMINATE(path, path_str);
    UEFS_SYNC({
        uv_fs_open(nullptr, &uvr, path_str, flags, mode, nullptr);
    }, {
        ret = (fd_t)uvr.result;
    });
    return ret;
}

ex<void> Fs::close (fd_t fd) {
    UEFS_SYNC({
        uv_fs_close(nullptr, &uvr, fd, nullptr);
    }, {});
    return {};
}

ex<Fs::FStat> Fs::stat (string_view path) {
    FStat ret;
    UE_NULL_TERMINATE(path, path_str);
    UEFS_SYNC({
        uv_fs_stat(nullptr, &uvr, path_str, nullptr);
    }, {
        uvx_stat2ue(&uvr.statbuf, ret);
    });
    return ret;
}

ex<Fs::FStat> Fs::stat (fd_t fd) {
    FStat ret;
    UEFS_SYNC({
        uv_fs_fstat(nullptr, &uvr, fd, nullptr);
    }, {
        uvx_stat2ue(&uvr.statbuf, ret);
    });
    return ret;
}

ex<Fs::FStat> Fs::lstat (string_view path) {
    FStat ret;
    UE_NULL_TERMINATE(path, path_str);
    UEFS_SYNC({
        uv_fs_lstat(nullptr, &uvr, path_str, nullptr);
    }, {
        uvx_stat2ue(&uvr.statbuf, ret);
    });
    return ret;
}

bool Fs::exists (string_view file) {
    return (bool)stat(file);
}

bool Fs::isfile (string_view file) {
    return stat(file).map([](const FStat& s) {
        return s.type() == FileType::FILE;
    }).value_or(false);
}

bool Fs::isdir (string_view file) {
    return stat(file).map([](const FStat& s) {
        return s.type() == FileType::DIR;
    }).value_or(false);
}

ex<void> Fs::access (string_view path, int mode) {
    UE_NULL_TERMINATE(path, path_str);
    UEFS_SYNC({
        uv_fs_access(nullptr, &uvr, path_str, mode, nullptr);
    }, {});
    return {};
}

ex<void> Fs::unlink (string_view path) {
    UE_NULL_TERMINATE(path, path_str);
    UEFS_SYNC({
        uv_fs_unlink(nullptr, &uvr, path_str, nullptr);
    }, {});
    return {};
}

ex<void> Fs::sync (fd_t fd) {
    UEFS_SYNC({
        uv_fs_fsync(nullptr, &uvr, fd, nullptr);
    }, {});
    return {};
}

ex<void> Fs::datasync (fd_t fd) {
    UEFS_SYNC({
        uv_fs_fdatasync(nullptr, &uvr, fd, nullptr);
    }, {});
    return {};
}

ex<void> Fs::truncate (string_view file, int64_t length) {
    return open(file, OpenFlags::WRONLY).and_then([&](fd_t fd) {
        auto ret = truncate(fd, length);
        if (!ret) {
            close(fd).nevermind();
            return ret;
        }
        return close(fd);
    });
}

ex<void> Fs::truncate (fd_t fd, int64_t length) {
    UEFS_SYNC({
        uv_fs_ftruncate(nullptr, &uvr, fd, length, nullptr);
    }, {});
    return {};
}

ex<void> Fs::chmod (string_view path, int mode) {
    UE_NULL_TERMINATE(path, path_str);
    UEFS_SYNC({
        uv_fs_chmod(nullptr, &uvr, path_str, mode, nullptr);
    }, {});
    return {};
}

ex<void> Fs::chmod (fd_t fd, int mode) {
    UEFS_SYNC({
        uv_fs_fchmod(nullptr, &uvr, fd, mode, nullptr);
    }, {});
    return {};
}

ex<void> Fs::touch (string_view file, int mode) {
    if (exists(file)) return utime(file, gettimeofday().get(), gettimeofday().get());
    else              return open(file, OpenFlags::RDWR | OpenFlags::CREAT, mode).and_then([](fd_t fd){ return close(fd); });
}

ex<void> Fs::utime (string_view path, double atime, double mtime) {
    UE_NULL_TERMINATE(path, path_str);
    UEFS_SYNC({
        uv_fs_utime(nullptr, &uvr, path_str, atime, mtime, nullptr);
    }, {});
    return {};
}

ex<void> Fs::utime (fd_t fd, double atime, double mtime) {
    UEFS_SYNC({
        uv_fs_futime(nullptr, &uvr, fd, atime, mtime, nullptr);
    }, {});
    return {};
}

ex<void> Fs::chown (string_view path, uid_t uid, gid_t gid) {
    UE_NULL_TERMINATE(path, path_str);
    UEFS_SYNC({
        uv_fs_chown(nullptr, &uvr, path_str, uid, gid, nullptr);
    }, {});
    return {};
}

ex<void> Fs::lchown (string_view path, uid_t uid, gid_t gid) {
    UE_NULL_TERMINATE(path, path_str);
    UEFS_SYNC({
        uv_fs_lchown(nullptr, &uvr, path_str, uid, gid, nullptr);
    }, {});
    return {};
}

ex<void> Fs::chown (fd_t fd, uid_t uid, gid_t gid) {
    UEFS_SYNC({
        uv_fs_fchown(nullptr, &uvr, fd, uid, gid, nullptr);
    }, {});
    return {};
}

ex<string> Fs::read (fd_t fd, size_t length, int64_t offset) {
    string ret;
    char* ptr = ret.reserve(length);
    uv_buf_t uvbuf;
    uvbuf.base = ptr;
    uvbuf.len  = length;
    UEFS_SYNC({
        uv_fs_read(nullptr, &uvr, fd, &uvbuf, 1, offset, nullptr);
    }, {
        ret.length(uvr.result);
    });
    return ret;
}

ex<void> Fs::_write (fd_t fd, _buf_t* bufs, size_t nbufs, int64_t offset) {
    uv_buf_t uvbufs[nbufs];
    for (size_t i = 0; i < nbufs; ++i) {
        uvbufs[i].base = const_cast<char*>(bufs[i].base); // libuv read-only access
        uvbufs[i].len  = bufs[i].len;
    }
    UEFS_SYNC({
        uv_fs_write(nullptr, &uvr, fd, uvbufs, nbufs, offset, nullptr);
    }, {});
    return {};
}

ex<void> Fs::rename (string_view src, string_view dst) {
    UE_NULL_TERMINATE(src, src_str);
    UE_NULL_TERMINATE(dst, dst_str);
    UEFS_SYNC({
        uv_fs_rename(nullptr, &uvr, src_str, dst_str, nullptr);
    }, {});
    return {};
}

ex<size_t> Fs::sendfile (fd_t out, fd_t in, int64_t offset, size_t length) {
    size_t ret;
    UEFS_SYNC({
        uv_fs_sendfile(nullptr, &uvr, out, in, offset, length, nullptr);
    }, {
        ret = (size_t)uvr.result;
    });
    return ret;
}

ex<void> Fs::link (string_view src, string_view dst) {
    UE_NULL_TERMINATE(src, src_str);
    UE_NULL_TERMINATE(dst, dst_str);
    UEFS_SYNC({
        uv_fs_link(nullptr, &uvr, src_str, dst_str, nullptr);
    }, {});
    return {};
}

ex<void> Fs::symlink (string_view src, string_view dst, int flags) {
    UE_NULL_TERMINATE(src, src_str);
    UE_NULL_TERMINATE(dst, dst_str);
    UEFS_SYNC({
        uv_fs_symlink(nullptr, &uvr, src_str, dst_str, flags, nullptr);
    }, {});
    return {};
}

ex<string> Fs::readlink (string_view path) {
    string ret;
    UE_NULL_TERMINATE(path, path_str);
    UEFS_SYNC({
        uv_fs_readlink(nullptr, &uvr, path_str, nullptr);
    }, {
        ret.assign((const char*)uvr.ptr, (size_t)uvr.result); // _uvr.ptr is not null-terminated
    });
    return ret;
}

ex<string> Fs::realpath (string_view path) {
    string ret;
    UE_NULL_TERMINATE(path, path_str);
    UEFS_SYNC({
        uv_fs_realpath(nullptr, &uvr, path_str, nullptr);
    }, {
        ret.assign((const char*)uvr.ptr); // _uvr.ptr is null-terminated
    });
    return ret;
}

ex<void> Fs::copyfile (string_view src, string_view dst, int flags) {
    UE_NULL_TERMINATE(src, src_str);
    UE_NULL_TERMINATE(dst, dst_str);
    UEFS_SYNC({
        uv_fs_copyfile(nullptr, &uvr, src_str, dst_str, flags, nullptr);
    }, {});
    return {};
}

ex<string> Fs::mkdtemp (string_view path) {
    string ret;
    UE_NULL_TERMINATE(path, path_str);
    UEFS_SYNC({
        uv_fs_mkdtemp(nullptr, &uvr, path_str, nullptr);
    }, {
        ret.assign(uvr.path);
    });
    return ret;
}

/* ===============================================================================================
   =================================== ASYNC STATIC API ==========================================
   =============================================================================================== */

#define UEFS_ASYNC_S(call_code)             \
    Fs::RequestSP ret = new Fs::Request(l); \
    call_code;                              \
    return ret;

#define UEFS_ASYNC_SFD(call_code) UEFS_ASYNC_S({ ret->fd(f); call_code; })

Fs::RequestSP Fs::mkdir      (string_view path, int mode, const fn& cb, const LoopSP& l) { UEFS_ASYNC_S(ret->mkdir(path, mode, cb)); }
Fs::RequestSP Fs::rmdir      (string_view path, const fn& cb, const LoopSP& l)           { UEFS_ASYNC_S(ret->rmdir(path, cb)); }
Fs::RequestSP Fs::remove     (string_view path, const fn& cb, const LoopSP& l)           { UEFS_ASYNC_S(ret->remove(path, cb)); }
Fs::RequestSP Fs::mkpath     (string_view path, int mode, const fn& cb, const LoopSP& l) { UEFS_ASYNC_S(ret->mkpath(path, mode, cb)); }
Fs::RequestSP Fs::scandir    (string_view path, const scandir_fn& cb, const LoopSP& l)   { UEFS_ASYNC_S(ret->scandir(path, cb)); }
Fs::RequestSP Fs::remove_all (string_view path, const fn& cb, const LoopSP& l)           { UEFS_ASYNC_S(ret->remove_all(path, cb)); }

Fs::RequestSP Fs::open     (string_view path, int flags, int mode, const open_fn& cb, const LoopSP& l)          { UEFS_ASYNC_S(ret->open(path, flags, mode, cb)); }
Fs::RequestSP Fs::close    (fd_t f, const fn& cb, const LoopSP& l)                                              { UEFS_ASYNC_SFD(ret->close(cb)); }
Fs::RequestSP Fs::stat     (string_view path, const stat_fn& cb, const LoopSP& l)                               { UEFS_ASYNC_S(ret->stat(path, cb)); }
Fs::RequestSP Fs::stat     (fd_t f, const stat_fn& cb, const LoopSP& l)                                         { UEFS_ASYNC_SFD(ret->stat(cb)); }
Fs::RequestSP Fs::lstat    (string_view path, const stat_fn& cb, const LoopSP& l)                               { UEFS_ASYNC_S(ret->lstat(path, cb)); }
Fs::RequestSP Fs::exists   (string_view path, const bool_fn& cb, const LoopSP& l)                               { UEFS_ASYNC_S(ret->exists(path, cb)); }
Fs::RequestSP Fs::isfile   (string_view path, const bool_fn& cb, const LoopSP& l)                               { UEFS_ASYNC_S(ret->isfile(path, cb)); }
Fs::RequestSP Fs::isdir    (string_view path, const bool_fn& cb, const LoopSP& l)                               { UEFS_ASYNC_S(ret->isdir(path, cb)); }
Fs::RequestSP Fs::access   (string_view path, int mode, const fn& cb, const LoopSP& l)                          { UEFS_ASYNC_S(ret->access(path, mode, cb)); }
Fs::RequestSP Fs::unlink   (string_view path, const fn& cb, const LoopSP& l)                                    { UEFS_ASYNC_S(ret->unlink(path, cb)); }
Fs::RequestSP Fs::sync     (fd_t f, const fn& cb, const LoopSP& l)                                              { UEFS_ASYNC_SFD(ret->sync(cb)); }
Fs::RequestSP Fs::datasync (fd_t f, const fn& cb, const LoopSP& l)                                              { UEFS_ASYNC_SFD(ret->datasync(cb)); }
Fs::RequestSP Fs::truncate (string_view path, int64_t off, const fn& cb, const LoopSP& l)                       { UEFS_ASYNC_S(ret->truncate(path, off, cb)); }
Fs::RequestSP Fs::truncate (fd_t f, int64_t off, const fn& cb, const LoopSP& l)                                 { UEFS_ASYNC_SFD(ret->truncate(off, cb)); }
Fs::RequestSP Fs::chmod    (string_view path, int mode, const fn& cb, const LoopSP& l)                          { UEFS_ASYNC_S(ret->chmod(path, mode, cb)); }
Fs::RequestSP Fs::chmod    (fd_t f, int mode, const fn& cb, const LoopSP& l)                                    { UEFS_ASYNC_SFD(ret->chmod(mode, cb)); }
Fs::RequestSP Fs::touch    (string_view path, int mode, const fn& cb, const LoopSP& l)                          { UEFS_ASYNC_S(ret->touch(path, mode, cb)); }
Fs::RequestSP Fs::utime    (string_view path, double atime, double mtime, const fn& cb, const LoopSP& l)        { UEFS_ASYNC_S(ret->utime(path, atime, mtime, cb)); }
Fs::RequestSP Fs::utime    (fd_t f, double atime, double mtime, const fn& cb, const LoopSP& l)                  { UEFS_ASYNC_SFD(ret->utime(atime, mtime, cb)); }
Fs::RequestSP Fs::chown    (string_view path, uid_t uid, gid_t gid, const fn& cb, const LoopSP& l)              { UEFS_ASYNC_S(ret->chown(path, uid, gid, cb)); }
Fs::RequestSP Fs::lchown   (string_view path, uid_t uid, gid_t gid, const fn& cb, const LoopSP& l)              { UEFS_ASYNC_S(ret->lchown(path, uid, gid, cb)); }
Fs::RequestSP Fs::chown    (fd_t f, uid_t uid, gid_t gid, const fn& cb, const LoopSP& l)                        { UEFS_ASYNC_SFD(ret->chown(uid, gid, cb)); }
Fs::RequestSP Fs::rename   (string_view src, string_view dst, const fn& cb, const LoopSP& l)                    { UEFS_ASYNC_S(ret->rename(src, dst, cb)); }
Fs::RequestSP Fs::sendfile (fd_t out, fd_t in, int64_t off, size_t len, const sendfile_fn& cb, const LoopSP& l) { UEFS_ASYNC_S(ret->sendfile(out, in, off, len, cb)); }
Fs::RequestSP Fs::link     (string_view src, string_view dst, const fn& cb, const LoopSP& l)                    { UEFS_ASYNC_S(ret->link(src, dst, cb)); }
Fs::RequestSP Fs::symlink  (string_view src, string_view dst, int flags, const fn& cb, const LoopSP& l)         { UEFS_ASYNC_S(ret->symlink(src, dst, flags, cb)); }
Fs::RequestSP Fs::readlink (string_view path, const string_fn& cb, const LoopSP& l)                             { UEFS_ASYNC_S(ret->readlink(path, cb)); }
Fs::RequestSP Fs::realpath (string_view path, const string_fn& cb, const LoopSP& l)                             { UEFS_ASYNC_S(ret->realpath(path, cb)); }
Fs::RequestSP Fs::copyfile (string_view src, string_view dst, int flags, const fn& cb, const LoopSP& l)         { UEFS_ASYNC_S(ret->copyfile(src, dst, flags, cb)); }
Fs::RequestSP Fs::mkdtemp  (string_view path, const string_fn& cb, const LoopSP& l)                             { UEFS_ASYNC_S(ret->mkdtemp(path, cb)); }
Fs::RequestSP Fs::read     (fd_t f, size_t size, int64_t off, const string_fn& cb, const LoopSP& l)             { UEFS_ASYNC_SFD(ret->read(size, off, cb)); }
Fs::RequestSP Fs::_write   (fd_t f, std::vector<string>&& v, int64_t off, const fn& cb, const LoopSP& l)        { UEFS_ASYNC_SFD(ret->_write(std::move(v), off, cb)); }

/* ===============================================================================================
   =================================== ASYNC OBJECT API ==========================================
   =============================================================================================== */

#define UEFS_ASYNC_RAW(work_code, after_work_code) { \
    if (_busy) throw Error("cannot start request while processing another");    \
    _busy = true;                                    \
    work_cb = [=](auto) { work_code  };              \
    after_work_cb = [=](auto&, auto& err) {          \
        if (err) _err = err;                         \
        _busy = false;                               \
        after_work_code;                             \
        _err.clear();                                \
        _dir_entries.clear();                        \
        _string.clear();                             \
    };                                               \
    queue();                                         \
}

#define UEFS_ASYNC(call_expr, save_result_code, cb_code)        \
    UEFS_ASYNC_RAW({                                            \
        auto ret = call_expr;                                   \
        if (ret) {save_result_code;}                            \
        else     _err = ret.error();                            \
    }, cb_code);

#define UEFS_ASYNC_VOID(call_expr) UEFS_ASYNC(call_expr, {}, cb(_err, this))
#define UEFS_ASYNC_STAT(call_expr) UEFS_ASYNC(call_expr, (_stat = *std::move(ret)), cb(_stat, _err, this))
#define UEFS_ASYNC_BOOL(call_expr) UEFS_ASYNC_RAW( { _bool = call_expr; }, cb(_bool, _err, this))
#define UEFS_ASYNC_STR(call_expr)  UEFS_ASYNC(call_expr, (_string = *std::move(ret)), cb(_string, _err, this))

void Fs::Request::mkdir      (string_view _path, int mode, const fn& cb) { auto path = string(_path); UEFS_ASYNC_VOID(Fs::mkdir(path, mode)); }
void Fs::Request::rmdir      (string_view _path, const fn& cb)           { auto path = string(_path); UEFS_ASYNC_VOID(Fs::rmdir(path)); }
void Fs::Request::remove     (string_view _path, const fn& cb)           { auto path = string(_path); UEFS_ASYNC_VOID(Fs::remove(path)); }
void Fs::Request::mkpath     (string_view _path, int mode, const fn& cb) { auto path = string(_path); UEFS_ASYNC_VOID(Fs::mkpath(path, mode)); }
void Fs::Request::scandir    (string_view _path, const scandir_fn& cb)   { auto path = string(_path); UEFS_ASYNC(Fs::scandir(path), (_dir_entries = *std::move(ret)), cb(_dir_entries, _err, this)); }
void Fs::Request::remove_all (string_view _path, const fn& cb)           { auto path = string(_path); UEFS_ASYNC_VOID(Fs::remove_all(path)); }

void Fs::Request::open     (string_view _path, int flags, int mode, const open_fn& cb)         { auto path = string(_path); UEFS_ASYNC(Fs::open(path, flags, mode), (_fd = *ret), cb(_fd, _err, this)); }
void Fs::Request::close    (const fn& cb)                                                      { UEFS_ASYNC_VOID(Fs::close(_fd)); }
void Fs::Request::stat     (string_view _path, const stat_fn& cb)                              { auto path = string(_path); UEFS_ASYNC_STAT(Fs::stat(path)); }
void Fs::Request::stat     (const stat_fn& cb)                                                 { UEFS_ASYNC_STAT(Fs::stat(_fd)); }
void Fs::Request::lstat    (string_view _path, const stat_fn& cb)                              { auto path = string(_path); UEFS_ASYNC_STAT(Fs::lstat(path)); }
void Fs::Request::exists   (string_view _path, const bool_fn& cb)                              { auto path = string(_path); UEFS_ASYNC_BOOL(Fs::exists(path)); }
void Fs::Request::isfile   (string_view _path, const bool_fn& cb)                              { auto path = string(_path); UEFS_ASYNC_BOOL(Fs::isfile(path)); }
void Fs::Request::isdir    (string_view _path, const bool_fn& cb)                              { auto path = string(_path); UEFS_ASYNC_BOOL(Fs::isdir(path)); }
void Fs::Request::access   (string_view _path, int mode, const fn& cb)                         { auto path = string(_path); UEFS_ASYNC_VOID(Fs::access(path, mode)); }
void Fs::Request::unlink   (string_view _path, const fn& cb)                                   { auto path = string(_path); UEFS_ASYNC_VOID(Fs::unlink(path)); }
void Fs::Request::sync     (const fn& cb)                                                      { UEFS_ASYNC_VOID(Fs::sync(_fd)); }
void Fs::Request::datasync (const fn& cb)                                                      { UEFS_ASYNC_VOID(Fs::datasync(_fd)); }
void Fs::Request::truncate (string_view _path, int64_t off, const fn& cb)                      { auto path = string(_path); UEFS_ASYNC_VOID(Fs::truncate(path, off)); }
void Fs::Request::truncate (int64_t off, const fn& cb)                                         { UEFS_ASYNC_VOID(Fs::truncate(_fd, off)); }
void Fs::Request::chmod    (string_view _path, int mode, const fn& cb)                         { auto path = string(_path); UEFS_ASYNC_VOID(Fs::chmod(path, mode)); }
void Fs::Request::chmod    (int mode, const fn& cb)                                            { UEFS_ASYNC_VOID(Fs::chmod(_fd, mode)); }
void Fs::Request::touch    (string_view _path, int mode, const fn& cb)                         { auto path = string(_path); UEFS_ASYNC_VOID(Fs::touch(path, mode)); }
void Fs::Request::utime    (string_view _path, double atime, double mtime, const fn& cb)       { auto path = string(_path); UEFS_ASYNC_VOID(Fs::utime(path, atime, mtime)); }
void Fs::Request::utime    (double atime, double mtime, const fn& cb)                          { UEFS_ASYNC_VOID(Fs::utime(_fd, atime, mtime)); }
void Fs::Request::chown    (string_view _path, uid_t uid, gid_t gid, const fn& cb)             { auto path = string(_path); UEFS_ASYNC_VOID(Fs::chown(path, uid, gid)); }
void Fs::Request::lchown   (string_view _path, uid_t uid, gid_t gid, const fn& cb)             { auto path = string(_path); UEFS_ASYNC_VOID(Fs::lchown(path, uid, gid)); }
void Fs::Request::chown    (uid_t uid, gid_t gid, const fn& cb)                                { UEFS_ASYNC_VOID(Fs::chown(_fd, uid, gid)); }
void Fs::Request::rename   (string_view _src, string_view _dst, const fn& cb)                  { auto src = string(_src); auto dst = string(_dst); UEFS_ASYNC_VOID(Fs::rename(src, dst)); }
void Fs::Request::sendfile (fd_t out, fd_t in, int64_t off, size_t len, const sendfile_fn& cb) { UEFS_ASYNC(Fs::sendfile(out, in, off, len), (_size = *ret), cb(_size, _err, this)); }
void Fs::Request::link     (string_view _src, string_view _dst, const fn& cb)                  { auto src = string(_src); auto dst = string(_dst); UEFS_ASYNC_VOID(Fs::link(src, dst)); }
void Fs::Request::symlink  (string_view _src, string_view _dst, int flags, const fn& cb)       { auto src = string(_src); auto dst = string(_dst); UEFS_ASYNC_VOID(Fs::symlink(src, dst, flags)); }
void Fs::Request::readlink (string_view _path, const string_fn& cb)                            { auto path = string(_path); UEFS_ASYNC_STR(Fs::readlink(path)); }
void Fs::Request::realpath (string_view _path, const string_fn& cb)                            { auto path = string(_path); UEFS_ASYNC_STR(Fs::realpath(path)); }
void Fs::Request::copyfile (string_view _src, string_view _dst, int flags, const fn& cb)       { auto src = string(_src); auto dst = string(_dst); UEFS_ASYNC_VOID(Fs::copyfile(src, dst, flags)); }
void Fs::Request::mkdtemp  (string_view _path, const string_fn& cb)                            { auto path = string(_path); UEFS_ASYNC_STR(Fs::mkdtemp(path)); }
void Fs::Request::read     (size_t size, int64_t off, const string_fn& cb)                     { UEFS_ASYNC_STR(Fs::read(_fd, size, off)); }
void Fs::Request::_write   (std::vector<string>&& v, int64_t off, const fn& cb)                {
    UEFS_ASYNC_RAW({
        auto nbufs = v.size();
        _buf_t bufs[nbufs];
        _buf_t* ptr = bufs;
        for (const auto& s : v) {
            ptr->base = s.data();
            ptr->len  = s.length();
            ++ptr;
        }
        auto ret = Fs::_write(_fd, bufs, nbufs, off);
        if (!ret) _err = ret.error();
    }, {
        cb(_err, this);
    });
}
