#pragma once
#include "Loop.h"
#include "Request.h"
#include <panda/excepted.h>
#include <panda/string_view.h>
#include <sys/stat.h>
#include <sys/types.h>

namespace panda { namespace unievent {

struct Fs {
    template <class T>
    using ex = excepted<T, std::error_code>;

    struct Request;
    using RequestSP = iptr<Request>;

    static const int DEFAULT_FILE_MODE = 0644;
    static const int DEFAULT_DIR_MODE  = 0755;

    struct OpenFlags {
        static const int APPEND;
        static const int CREAT;
        static const int DIRECT;
        static const int DIRECTORY;
        static const int DSYNC;
        static const int EXCL;
        static const int EXLOCK;
        static const int NOATIME;
        static const int NOCTTY;
        static const int NOFOLLOW;
        static const int NONBLOCK;
        static const int RANDOM;
        static const int RDONLY;
        static const int RDWR;
        static const int SEQUENTIAL;
        static const int SHORT_LIVED;
        static const int SYMLINK;
        static const int SYNC;
        static const int TEMPORARY;
        static const int TRUNC;
        static const int WRONLY;
    };

    struct SymlinkFlags {
        static const int DIR;
        static const int JUNCTION;
    };

    struct CopyFileFlags {
        static const int EXCL;
        static const int FICLONE;
        static const int FICLONE_FORCE;
    };

    enum class FileType {UNKNOWN, BLOCK, CHAR, DIR, FIFO, LINK, FILE, SOCKET};

    struct FStat {
        uint64_t dev;
        uint64_t mode;
        uint64_t nlink;
        uint64_t uid;
        uint64_t gid;
        uint64_t rdev;
        uint64_t ino;
        uint64_t size;
        uint64_t blksize;
        uint64_t blocks;
        uint64_t flags;
        uint64_t gen;
        TimeSpec atime;
        TimeSpec mtime;
        TimeSpec ctime;
        TimeSpec birthtime;

        FileType type  () const { return ftype(mode); }

        int perms () const {
          #ifdef _WIN32
            return mode & ~_S_IFMT;
          #else
            return mode & ~S_IFMT;
          #endif
        }

        bool operator== (const FStat&)     const;
        bool operator!= (const FStat& oth) const { return !operator==(oth); }
    };

    struct FsInfo {
        uint64_t type;
        uint64_t bsize;
        uint64_t blocks;
        uint64_t bfree;
        uint64_t bavail;
        uint64_t files;
        uint64_t ffree;
        uint64_t spare[4];
    };

    struct DirEntry {
        DirEntry (const string& name, FileType type) : _name(name), _type(type) {}

        const string& name () const { return _name; }
        FileType      type () const { return _type; }

    private:
        string   _name;
        FileType _type;
    };
    using DirEntries = std::vector<DirEntry>;

    struct _buf_t {
        const char* base;
        size_t      len;
    };

    struct path_fd_t {
        string path;
        fd_t   fd;
    };

    using fn          = function<void(const std::error_code&, const RequestSP&)>;
    using bool_fn     = function<void(bool, const std::error_code&, const RequestSP&)>;
    using open_fn     = function<void(fd_t, const std::error_code&, const RequestSP&)>;
    using scandir_fn  = function<void(const DirEntries&, const std::error_code&, const RequestSP&)>;
    using stat_fn     = function<void(const FStat&, const std::error_code&, const RequestSP&)>;
    using statfs_fn   = function<void(const FsInfo&, const std::error_code&, const RequestSP&)>;
    using string_fn   = function<void(string&, const std::error_code&, const RequestSP&)>;
    using path_fd_fn  = function<void(string&, fd_t fd, const std::error_code&, const RequestSP&)>;
    using sendfile_fn = function<void(size_t, const std::error_code&, const RequestSP&)>;

    static FileType ftype (uint64_t mode);

    // sync static methods
    static ex<void>       mkdir      (string_view, int mode = DEFAULT_DIR_MODE);
    static ex<void>       rmdir      (string_view);
    static ex<void>       remove     (string_view);
    static ex<void>       mkpath     (string_view, int mode = DEFAULT_DIR_MODE);
    static ex<DirEntries> scandir    (string_view);
    static ex<void>       remove_all (string_view);

    static ex<fd_t>       open     (string_view, int flags, int mode = DEFAULT_FILE_MODE);
    static ex<void>       close    (fd_t);
    static ex<FStat>      stat     (string_view);
    static ex<FStat>      stat     (fd_t);
    static ex<FStat>      lstat    (string_view);
    static ex<FsInfo>     statfs   (string_view);
    static bool           exists   (string_view);
    static bool           isfile   (string_view);
    static bool           isdir    (string_view);
    static ex<void>       access   (string_view, int mode = 0);
    static ex<void>       unlink   (string_view);
    static ex<void>       sync     (fd_t);
    static ex<void>       datasync (fd_t);
    static ex<void>       truncate (string_view, int64_t length = 0);
    static ex<void>       truncate (fd_t, int64_t length = 0);
    static ex<void>       chmod    (string_view, int mode);
    static ex<void>       chmod    (fd_t,        int mode);
    static ex<void>       touch    (string_view, int mode = DEFAULT_FILE_MODE);
    static ex<void>       utime    (string_view, double atime, double mtime);
    static ex<void>       utime    (fd_t,        double atime, double mtime);
    static ex<void>       lutime   (string_view, double atime, double mtime);
    static ex<void>       chown    (string_view, uid_t uid, gid_t gid);
    static ex<void>       lchown   (string_view, uid_t uid, gid_t gid);
    static ex<void>       chown    (fd_t,        uid_t uid, gid_t gid);
    static ex<void>       rename   (string_view src, string_view dst);
    static ex<size_t>     sendfile (fd_t out, fd_t in, int64_t offset, size_t length);
    static ex<void>       link     (string_view src, string_view dst);
    static ex<void>       symlink  (string_view src, string_view dst, int flags = 0);
    static ex<string>     readlink (string_view);
    static ex<string>     realpath (string_view);
    static ex<void>       copyfile (string_view src, string_view dst, int flags = 0);
    static ex<string>     mkdtemp  (string_view);
    static ex<path_fd_t>  mkstemp  (string_view);
    static ex<string>     read     (fd_t, size_t length, int64_t offset = -1);
    static ex<void>       write    (fd_t fd, const string_view& buf, int64_t offset = -1) { return write(fd, &buf, &buf+1, offset); }

    template <class It>
    static ex<void> write (fd_t fd, It begin, It end, int64_t offset = -1) {
        size_t nbufs = end - begin;
        _buf_t bufs[nbufs];
        _buf_t* ptr = bufs;
        for (; begin != end; ++begin) {
            auto& s = *begin;
            ptr->base = s.data();
            ptr->len  = s.length();
            ++ptr;
        }
        return _write(fd, bufs, nbufs, offset);
    }

    // async static methods
    static RequestSP mkdir      (string_view, int mode, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP rmdir      (string_view, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP remove     (string_view, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP mkpath     (string_view, int mode, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP scandir    (string_view, const scandir_fn&, const LoopSP& = Loop::default_loop());
    static RequestSP remove_all (string_view, const fn&, const LoopSP& = Loop::default_loop());

    static RequestSP open     (string_view, int flags, int mode, const open_fn&, const LoopSP& = Loop::default_loop());
    static RequestSP close    (fd_t, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP stat     (string_view, const stat_fn&, const LoopSP& = Loop::default_loop());
    static RequestSP stat     (fd_t, const stat_fn&, const LoopSP& = Loop::default_loop());
    static RequestSP lstat    (string_view, const stat_fn&, const LoopSP& = Loop::default_loop());
    static RequestSP statfs   (string_view, const statfs_fn&, const LoopSP& = Loop::default_loop());
    static RequestSP exists   (string_view, const bool_fn&, const LoopSP& = Loop::default_loop());
    static RequestSP isfile   (string_view, const bool_fn&, const LoopSP& = Loop::default_loop());
    static RequestSP isdir    (string_view, const bool_fn&, const LoopSP& = Loop::default_loop());
    static RequestSP access   (string_view, int mode, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP unlink   (string_view, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP sync     (fd_t, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP datasync (fd_t, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP truncate (string_view, int64_t offset, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP truncate (fd_t, int64_t offset, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP chmod    (string_view, int mode, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP chmod    (fd_t, int mode, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP touch    (string_view, int mode, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP utime    (string_view, double atime, double mtime, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP utime    (fd_t, double atime, double mtime, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP lutime   (string_view, double atime, double mtime, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP chown    (string_view, uid_t uid, gid_t gid, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP lchown   (string_view, uid_t uid, gid_t gid, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP chown    (fd_t, uid_t uid, gid_t gid, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP rename   (string_view src, string_view dst, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP sendfile (fd_t out, fd_t in, int64_t offset, size_t length, const sendfile_fn&, const LoopSP& = Loop::default_loop());
    static RequestSP link     (string_view src, string_view dst, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP symlink  (string_view src, string_view dst, int flags, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP readlink (string_view, const string_fn&, const LoopSP& = Loop::default_loop());
    static RequestSP realpath (string_view, const string_fn&, const LoopSP& = Loop::default_loop());
    static RequestSP copyfile (string_view src, string_view dst, int flags, const fn&, const LoopSP& = Loop::default_loop());
    static RequestSP mkdtemp  (string_view, const string_fn&, const LoopSP& = Loop::default_loop());
    static RequestSP mkstemp  (string_view, const path_fd_fn&, const LoopSP& = Loop::default_loop());
    static RequestSP read     (fd_t, size_t size, int64_t offset, const string_fn&, const LoopSP& = Loop::default_loop());
    static RequestSP write    (fd_t fd, const string_view& buf, int64_t offset, const fn& cb, const LoopSP& loop) { return _write(fd, {string(buf)}, offset, cb, loop); }

    template <class It>
    static RequestSP write (fd_t fd, It begin, It end, int64_t offset, const fn& cb, const LoopSP& loop) {
        std::vector<string> bufs;
        for (; begin != end; ++begin) bufs.emplace(bufs.end(), *begin);
        return _write(fd, std::move(bufs), offset, cb, loop);
    }

    // async object methods
    struct Request : Work, AllocatedObject<Request> {
        Request  (const LoopSP& loop = Loop::default_loop()) : Work(loop), _fd() {}

        using AllocatedObject<Request>::operator new;
        using AllocatedObject<Request>::operator delete;

        fd_t fd () const  { return _fd; }
        void fd (fd_t fd) { _fd = fd; }

        void mkdir      (string_view, int mode, const fn&);
        void rmdir      (string_view, const fn&);
        void remove     (string_view, const fn&);
        void mkpath     (string_view, int mode, const fn&);
        void scandir    (string_view, const scandir_fn&);
        void remove_all (string_view, const fn&);

        void open     (string_view, int flags, int mode, const open_fn&);
        void close    (const fn&);
        void stat     (string_view, const stat_fn&);
        void stat     (const stat_fn&);
        void lstat    (string_view, const stat_fn&);
        void statfs   (string_view, const statfs_fn&);
        void exists   (string_view, const bool_fn&);
        void isfile   (string_view, const bool_fn&);
        void isdir    (string_view, const bool_fn&);
        void access   (string_view, int mode, const fn&);
        void unlink   (string_view, const fn&);
        void sync     (const fn&);
        void datasync (const fn&);
        void truncate (string_view, int64_t offset, const fn&);
        void truncate (int64_t offset, const fn&);
        void chmod    (string_view, int mode, const fn&);
        void chmod    (int mode, const fn&);
        void touch    (string_view, int mode, const fn&);
        void utime    (string_view, double atime, double mtime, const fn&);
        void utime    (double atime, double mtime, const fn&);
        void lutime   (string_view, double atime, double mtime, const fn&);
        void chown    (string_view, uid_t uid, gid_t gid, const fn&);
        void lchown   (string_view, uid_t uid, gid_t gid, const fn&);
        void chown    (uid_t uid, gid_t gid, const fn&);
        void rename   (string_view src, string_view dst, const fn&);
        void sendfile (fd_t out, fd_t in, int64_t offset, size_t length, const sendfile_fn&);
        void link     (string_view src, string_view dst, const fn&);
        void symlink  (string_view src, string_view dst, int flags, const fn&);
        void readlink (string_view, const string_fn&);
        void realpath (string_view, const string_fn&);
        void copyfile (string_view src, string_view dst, int flags, const fn&);
        void mkdtemp  (string_view, const string_fn&);
        void mkstemp  (string_view, const path_fd_fn&);
        void read     (size_t size, int64_t offset, const string_fn&);

        void write (const string_view& buf, int64_t offset, const fn& cb) { _write({string(buf)}, offset, cb); }

        template <class It>
        void write (It begin, It end, int64_t offset, const fn& cb) {
            std::vector<string> bufs;
            for (; begin != end; ++begin) bufs.emplace(bufs.end(), *begin);
            _write(std::move(bufs), offset, cb);
        }

    private:
        friend Fs;
        bool            _bool;
        fd_t            _fd;
        std::error_code _err;
        DirEntries      _dir_entries;
        FStat           _stat;
        FsInfo          _fs_info;
        size_t          _size;
        string          _string;

        void _write (std::vector<string>&&, int64_t offset, const fn&);
    };

    static const HandleType TYPE;

private:
    static ex<void>  _write (fd_t file, _buf_t* bufs, size_t nbufs, int64_t offset);
    static RequestSP _write (fd_t, std::vector<string>&&, int64_t offset, const fn&, const LoopSP&);
};

}}
