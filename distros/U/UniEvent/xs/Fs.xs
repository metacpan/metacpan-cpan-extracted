#include <xs/export.h>
#include <xs/function.h>
#include <xs/unievent/Fs.h>
#include <xs/unievent/Loop.h>
#include <xs/unievent/util.h>
#include <xs/unievent/error.h>

using namespace xs;
using namespace xs::unievent;
using namespace panda::unievent;
using panda::string_view;

#define FSXS_FUNC(async, sync) {            \
    if (cb) {                               \
        if (!l) l = Loop::default_loop();   \
        mXPUSHs(xs::out(async).detach());   \
        XSRETURN(1);                        \
    } else sync;                            \
}

#define FSXS_FUNC_VOID(async, sync) FSXS_FUNC(async, {      \
    auto ret = sync;                                        \
    if (GIMME_V == G_VOID) {                                \
        if (!ret) throw ret.error();                        \
        XSRETURN_EMPTY;                                     \
    }                                                       \
    XPUSHs(boolSV(ret));                                    \
    if (GIMME_V == G_ARRAY) {                               \
        if (ret) XPUSHs(&PL_sv_undef);                      \
        else     mXPUSHs(xs::out(ret.error()).detach());    \
        XSRETURN(2);                                        \
    }                                                       \
    XSRETURN(1);                                            \
})
    
#define FSXS_FUNC_RET(async, sync) FSXS_FUNC(async, {   \
    auto ret = sync;                                    \
    if (ret) {                                          \
        mXPUSHs(xs::out(ret.value()).detach());         \
        if (GIMME_V == G_ARRAY) {                       \
            XPUSHs(&PL_sv_undef);                       \
            XSRETURN(2);                                \
        }                                               \
        XSRETURN(1);                                    \
    }                                                   \
    if (GIMME_V != G_ARRAY) throw ret.error();          \
    XPUSHs(&PL_sv_undef);                               \
    mXPUSHs(xs::out(ret.error()).detach());             \
    XSRETURN(2);                                        \
})

#define FSXS_FUNC_BOOL(async, sync) FSXS_FUNC(async, {  \
    auto ret = sync;                                    \
    XPUSHs(boolSV(ret));                                \
    XSRETURN(1);                                        \
})

MODULE = UniEvent::Fs                PACKAGE = UniEvent::Fs
PROTOTYPES: DISABLE

BOOT {
    Stash stash(__PACKAGE__, GV_ADD);
    
    exp::create_constants(stash, {
        {"DEFAULT_FILE_MODE",      Fs::DEFAULT_FILE_MODE},
        {"DEFAULT_DIR_MODE",       Fs::DEFAULT_DIR_MODE },
        
        {"OPEN_APPEND",            Fs::OpenFlags::APPEND     },
        {"OPEN_CREAT",             Fs::OpenFlags::CREAT      },
        {"OPEN_DIRECT",            Fs::OpenFlags::DIRECT     },
        {"OPEN_DIRECTORY",         Fs::OpenFlags::DIRECTORY  },
        {"OPEN_DSYNC",             Fs::OpenFlags::DSYNC      },
        {"OPEN_EXCL",              Fs::OpenFlags::EXCL       },
        {"OPEN_EXLOCK",            Fs::OpenFlags::EXLOCK     },
        {"OPEN_NOATIME",           Fs::OpenFlags::NOATIME    },
        {"OPEN_NOCTTY",            Fs::OpenFlags::NOCTTY     },
        {"OPEN_NOFOLLOW",          Fs::OpenFlags::NOFOLLOW   },
        {"OPEN_NONBLOCK",          Fs::OpenFlags::NONBLOCK   },
        {"OPEN_RANDOM",            Fs::OpenFlags::RANDOM     },
        {"OPEN_RDONLY",            Fs::OpenFlags::RDONLY     },
        {"OPEN_RDWR",              Fs::OpenFlags::RDWR       },
        {"OPEN_SEQUENTIAL",        Fs::OpenFlags::SEQUENTIAL },
        {"OPEN_SHORT_LIVED",       Fs::OpenFlags::SHORT_LIVED},
        {"OPEN_SYMLINK",           Fs::OpenFlags::SYMLINK    },
        {"OPEN_SYNC",              Fs::OpenFlags::SYNC       },
        {"OPEN_TEMPORARY",         Fs::OpenFlags::TEMPORARY  },
        {"OPEN_TRUNC",             Fs::OpenFlags::TRUNC      },
        {"OPEN_WRONLY",            Fs::OpenFlags::WRONLY     },

        {"SYMLINK_DIR",            Fs::SymlinkFlags::DIR     },
        {"SYMLINK_JUNCTION",       Fs::SymlinkFlags::JUNCTION},

        {"COPYFILE_EXCL",          Fs::CopyFileFlags::EXCL         },
        {"COPYFILE_FICLONE",       Fs::CopyFileFlags::FICLONE      },
        {"COPYFILE_FICLONE_FORCE", Fs::CopyFileFlags::FICLONE_FORCE},

        {"FTYPE_BLOCK",      (int)Fs::FileType::BLOCK  },
        {"FTYPE_CHAR",       (int)Fs::FileType::CHAR   },
        {"FTYPE_DIR",        (int)Fs::FileType::DIR    },
        {"FTYPE_FIFO",       (int)Fs::FileType::FIFO   },
        {"FTYPE_LINK",       (int)Fs::FileType::LINK   },
        {"FTYPE_FILE",       (int)Fs::FileType::FILE   },
        {"FTYPE_SOCKET",     (int)Fs::FileType::SOCKET },
        {"FTYPE_UNKNOWN",    (int)Fs::FileType::UNKNOWN},
        
        {"STAT_DEV",        0},
        {"STAT_INO",        1},
        {"STAT_MODE",       2},
        {"STAT_NLINK",      3},
        {"STAT_UID",        4},
        {"STAT_GID",        5},
        {"STAT_RDEV",       6},
        {"STAT_SIZE",       7},
        {"STAT_ATIME",      8},
        {"STAT_MTIME",      9},
        {"STAT_CTIME",     10},
        {"STAT_BLKSIZE",   11},
        {"STAT_BLOCKS",    12},
        {"STAT_FLAGS",     13},
        {"STAT_GEN",       14},
        {"STAT_BIRTHTIME", 15},
        {"STAT_TYPE",      16},
        {"STAT_PERMS",     17}
    });
    exp::autoexport(stash);
    stash.add_const_sub("TYPE", Simple(Fs::TYPE.name));
}

Fs::Request* Fs::Request::new (LoopSP loop = Loop::default_loop()) {
    RETVAL = new Fs::Request(loop);
}

void mkdir (string_view path, int mode = Fs::DEFAULT_DIR_MODE, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_VOID(Fs::mkdir(path, mode, cb, l), Fs::mkdir(path, mode));
}

void rmdir (string_view path, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_VOID(Fs::rmdir(path, cb, l), Fs::rmdir(path));
}

void remove (string_view path, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_VOID(Fs::remove(path, cb, l), Fs::remove(path));
}

void mkpath (string_view path, int mode = Fs::DEFAULT_DIR_MODE, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_VOID(Fs::mkpath(path, mode, cb, l), Fs::mkpath(path, mode));
}

void scandir (string_view path, Fs::scandir_fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_RET(Fs::scandir(path, cb, l), Fs::scandir(path));
}

void remove_all (string_view path, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_VOID(Fs::remove_all(path, cb, l), Fs::remove_all(path));
}

void open (string_view path, int flags, int mode = Fs::DEFAULT_FILE_MODE, Fs::open_fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_RET(Fs::open(path, flags, mode, cb, l), Fs::open(path, flags, mode));
}

void close (Sv _fd, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    auto fd = sv2fd(_fd);
    FSXS_FUNC_VOID(Fs::close(fd, cb, l), Fs::close(fd));
}

void stat (Sv path_or_fd, Fs::stat_fn cb = nullptr, LoopSP l = nullptr) {
    if (path_or_fd.is_string()) {
        auto path = xs::in<string_view>(path_or_fd);
        FSXS_FUNC_RET(Fs::stat(path, cb, l), Fs::stat(path));
    } else {
        auto fd = sv2fd(path_or_fd);
        FSXS_FUNC_RET(Fs::stat(fd, cb, l), Fs::stat(fd));
    }
}

void lstat (string_view path, Fs::stat_fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_RET(Fs::lstat(path, cb, l), Fs::lstat(path));
}

void exists (string_view path, Fs::bool_fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_BOOL(Fs::exists(path, cb, l), Fs::exists(path));
}

void isfile (string_view path, Fs::bool_fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_BOOL(Fs::isfile(path, cb, l), Fs::isfile(path));
}

void isdir (string_view path, Fs::bool_fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_BOOL(Fs::isdir(path, cb, l), Fs::isdir(path));
}

void access (string_view path, int mode = 0, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_VOID(Fs::access(path, mode, cb, l), Fs::access(path, mode));
}

void unlink (string_view path, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_VOID(Fs::unlink(path, cb, l), Fs::unlink(path));
}

void sync (Sv _fd, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    auto fd = sv2fd(_fd);
    FSXS_FUNC_VOID(Fs::sync(fd, cb, l), Fs::sync(fd));
}

void datasync (Sv _fd, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    auto fd = sv2fd(_fd);
    FSXS_FUNC_VOID(Fs::datasync(fd, cb, l), Fs::datasync(fd));
}

void truncate (Sv path_or_fd, int64_t length = 0, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    if (path_or_fd.is_string()) {
        auto path = xs::in<string_view>(path_or_fd);
        FSXS_FUNC_VOID(Fs::truncate(path, length, cb, l), Fs::truncate(path, length));
    } else {
        auto fd = sv2fd(path_or_fd);
        FSXS_FUNC_VOID(Fs::truncate(fd, length, cb, l), Fs::truncate(fd, length));
    }
}

void chmod (Sv path_or_fd, int mode, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    if (path_or_fd.is_string()) {
        auto path = xs::in<string_view>(path_or_fd);
        FSXS_FUNC_VOID(Fs::chmod(path, mode, cb, l), Fs::chmod(path, mode));
    } else {
        auto fd = sv2fd(path_or_fd);
        FSXS_FUNC_VOID(Fs::chmod(fd, mode, cb, l), Fs::chmod(fd, mode));
    }
}

void touch (string_view path, int mode = Fs::DEFAULT_FILE_MODE, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_VOID(Fs::touch(path, mode, cb, l), Fs::touch(path, mode));
}

void utime (Sv path_or_fd, double atime, double mtime, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    if (path_or_fd.is_string()) {
        auto path = xs::in<string_view>(path_or_fd);
        FSXS_FUNC_VOID(Fs::utime(path, atime, mtime, cb, l), Fs::utime(path, atime, mtime));
    } else {
        auto fd = sv2fd(path_or_fd);
        FSXS_FUNC_VOID(Fs::utime(fd, atime, mtime, cb, l), Fs::utime(fd, atime, mtime));
    }
}

void chown (Sv path_or_fd, uid_t uid, gid_t gid, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    if (path_or_fd.is_string()) {
        auto path = xs::in<string_view>(path_or_fd);
        FSXS_FUNC_VOID(Fs::chown(path, uid, gid, cb, l), Fs::chown(path, uid, gid));
    } else {
        auto fd = sv2fd(path_or_fd);
        FSXS_FUNC_VOID(Fs::chown(fd, uid, gid, cb, l), Fs::chown(fd, uid, gid));
    }
}

void lchown (string_view path, uid_t uid, gid_t gid, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_VOID(Fs::lchown(path, uid, gid, cb, l), Fs::lchown(path, uid, gid));
}

void rename (string_view src, string_view dst, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_VOID(Fs::rename(src, dst, cb, l), Fs::rename(src, dst));
}

void sendfile (Sv _out, Sv _in, int64_t offset, size_t length, Fs::sendfile_fn cb = nullptr, LoopSP l = nullptr) {
    auto out = sv2fd(_out);
    auto in  = sv2fd(_in);
    FSXS_FUNC_RET(Fs::sendfile(out, in, offset, length, cb, l), Fs::sendfile(out, in, offset, length));
}

void link (string_view src, string_view dst, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_VOID(Fs::link(src, dst, cb, l), Fs::link(src, dst));
}

void symlink (string_view src, string_view dst, int flags = 0, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_VOID(Fs::symlink(src, dst, flags, cb, l), Fs::symlink(src, dst, flags));
}

void readlink (string_view path, Fs::string_fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_RET(Fs::readlink(path, cb, l), Fs::readlink(path));
}

void realpath (string_view path, Fs::string_fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_RET(Fs::realpath(path, cb, l), Fs::realpath(path));
}

void copyfile (string_view src, string_view dst, int flags, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_VOID(Fs::copyfile(src, dst, flags, cb, l), Fs::copyfile(src, dst, flags));
}

void mkdtemp (string_view path, Fs::string_fn cb = nullptr, LoopSP l = nullptr) {
    FSXS_FUNC_RET(Fs::mkdtemp(path, cb, l), Fs::mkdtemp(path));
}

void read (Sv _fd, size_t size, int64_t offset = -1, Fs::string_fn cb = nullptr, LoopSP l = nullptr) {
    auto fd = sv2fd(_fd);
    FSXS_FUNC_RET(Fs::read(fd, size, offset, cb, l), Fs::read(fd, size, offset));
}

void write (Sv _fd, Sv _buf, int64_t offset = -1, Fs::fn cb = nullptr, LoopSP l = nullptr) {
    auto fd = sv2fd(_fd);
    auto buf = sv2buf(_buf);
    FSXS_FUNC_VOID(Fs::write(fd, buf, offset, cb, l), Fs::write(fd, buf, offset));
}


MODULE = UniEvent::Fs                PACKAGE = UniEvent::Fs::Request
PROTOTYPES: DISABLE

Fs::Request* Fs::Request::new (LoopSP loop = Loop::default_loop()) {
    RETVAL = new Fs::Request(loop);
}

bool Fs::Request::busy ()

fd_t Fs::Request::fd (Sv fd = Sv()) {
    if (fd) {
        THIS->fd(sv2fd(fd));
        XSRETURN_UNDEF;
    }
    RETVAL = THIS->fd();
}

void Fs::Request::mkdir      (string_view path, int mode, Fs::fn cb)

void Fs::Request::rmdir      (string_view path, Fs::fn cb)

void Fs::Request::remove     (string_view path, Fs::fn cb)

void Fs::Request::mkpath     (string_view path, int mode, Fs::fn cb)

void Fs::Request::scandir    (string_view path, Fs::scandir_fn cb)

void Fs::Request::remove_all (string_view path, Fs::fn cb)


void Fs::Request::open     (string_view path, int flags, int mode, Fs::open_fn cb)

void Fs::Request::close    (Fs::fn cb)

void Fs::Request::stat     (Sv arg1, Sv arg2 = Sv()) {
    if (arg2) THIS->stat(xs::in<string_view>(arg1), xs::in<Fs::stat_fn>(arg2));
    else      THIS->stat(xs::in<Fs::stat_fn>(arg1));
}

void Fs::Request::lstat    (string_view path, Fs::stat_fn cb);

void Fs::Request::exists   (string_view path, Fs::bool_fn cb);

void Fs::Request::isfile   (string_view path, Fs::bool_fn cb);

void Fs::Request::isdir    (string_view path, Fs::bool_fn cb);

void Fs::Request::access   (string_view path, int mode, Fs::fn cb)

void Fs::Request::unlink   (string_view path, Fs::fn cb)

void Fs::Request::sync     (Fs::fn cb)

void Fs::Request::datasync (Fs::fn cb)

void Fs::Request::truncate (Sv arg1, Sv arg2, Sv arg3 = Sv()) {
    if (arg3) THIS->truncate(xs::in<string_view>(arg1), xs::in<int64_t>(arg2), xs::in<Fs::fn>(arg3));
    else      THIS->truncate(xs::in<int64_t>(arg1), xs::in<Fs::fn>(arg2));
}

void Fs::Request::chmod (Sv arg1, Sv arg2, Sv arg3 = Sv()) {
    if (arg3) THIS->chmod(xs::in<string_view>(arg1), xs::in<int>(arg2), xs::in<Fs::fn>(arg3));
    else      THIS->chmod(xs::in<int>(arg1), xs::in<Fs::fn>(arg2));
}

void Fs::Request::touch (string_view path, int mode, Fs::fn cb)

void Fs::Request::utime (Sv arg1, Sv arg2, Sv arg3, Sv arg4 = Sv()) {
    if (arg4) THIS->utime(xs::in<string_view>(arg1), xs::in<double>(arg2), xs::in<double>(arg3), xs::in<Fs::fn>(arg4));
    else      THIS->utime(xs::in<double>(arg1), xs::in<double>(arg2), xs::in<Fs::fn>(arg3));
}

void Fs::Request::chown (Sv arg1, Sv arg2, Sv arg3, Sv arg4 = Sv()) {
    if (arg4) THIS->chown(xs::in<string_view>(arg1), xs::in<uid_t>(arg2), xs::in<gid_t>(arg3), xs::in<Fs::fn>(arg4));
    else      THIS->chown(xs::in<uid_t>(arg1), xs::in<gid_t>(arg2), xs::in<Fs::fn>(arg3));
}

void Fs::Request::lchown   (string_view path, uid_t uid, gid_t gid, Fs::fn cb)

void Fs::Request::rename   (string_view src, string_view dst, Fs::fn cb)

void Fs::Request::sendfile (Sv out, Sv in, int64_t offset, size_t length, Fs::sendfile_fn cb) {
    THIS->sendfile(sv2fd(out), sv2fd(in), offset, length, cb);
}

void Fs::Request::link     (string_view src, string_view dst, Fs::fn cb)

void Fs::Request::symlink  (string_view src, string_view dst, int flags, Fs::fn cb)

void Fs::Request::readlink (string_view path, Fs::string_fn cb)

void Fs::Request::realpath (string_view path, Fs::string_fn cb)

void Fs::Request::copyfile (string_view src, string_view dst, int flags, Fs::fn cb)

void Fs::Request::mkdtemp  (string_view path, Fs::string_fn cb)

void Fs::Request::read     (size_t size, int64_t offset, Fs::string_fn cb)

void Fs::Request::write    (Sv buf, int64_t offset, Fs::fn cb) {
    THIS->write(sv2buf(buf), offset, cb);
}
