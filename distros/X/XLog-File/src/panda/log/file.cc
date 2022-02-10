#include "file.h"
#include <iostream>
#include <panda/exception.h>
#include <panda/unievent/Fs.h>
#include <panda/unievent/util.h>

#include <string.h>
#include <stdio.h>
#ifdef __unix__
#include <unistd.h>
#include <fcntl.h>
#endif

namespace panda { namespace log {

#ifdef _WIN32
    static const char* EOL = "\r\n";
#else
    static const char* EOL = "\n";
#endif

using namespace unievent;

static string_view remove_filename (string_view path) {
    if (path.empty()) return path;
    auto s = path.data();
    size_t pos = path.length() - 1;
    auto is_slash = [](char c) { return c == '/' || c == '\\'; };
    while (!is_slash(s[pos]) && pos) --pos;
    if (!is_slash(s[pos])) return {};
    return path.substr(0, pos+1);
}

FileLogger::FileLogger (const Config& cfg) : file(cfg.file), buffered(cfg.buffered), check_freq(cfg.check_freq) {
    if (file.empty()) throw exception("file must be defined");
    reopen();
}

FileLogger::~FileLogger () {
    if (fh) {
        fclose(fh);
        fh = nullptr;
    }
}

bool FileLogger::reopen () {
    if (fh) {
        fclose(fh);
        fh = nullptr;
    }
    inode = 0;

    if (!Fs::exists(file)) {
        auto dir = remove_filename(file);
        if (!Fs::isdir(dir)) {
            auto ret = Fs::mkpath(dir);
            if (!ret) {
                std::cerr << "[FileLogger] logging disabled: could not create path '" << dir << "': " << ret.error().message() << std::endl;
                return false;
            }
        }
    }

    fh = fopen(file.c_str(), "a+b");
    if (!fh) {
        std::cerr << "[FileLogger] logging disabled: could not open log file '" << file << "': " << last_sys_error().message() << std::endl;
        return false;
    }

    auto fd = fileno(fh);
    if (fd < 0) {
        std::cerr << "[FileLogger] logging disabled: get file descriptor '" << file << "': " << strerror(errno) << std::endl;
        return false;
    }

    auto res = Fs::stat(fd);
    if (!res) {
        std::cerr << "[FileLogger] logging disabled: could not stat log file '" << file << "': " << strerror(errno) << std::endl;
        return false;
    }

#ifdef __unix__
    int flags = fcntl(fd, F_GETFD);
    if (flags < 0) {
        std::cerr << "[FileLogger] logging disabled: get file descriptor flags '" << file << "': " << strerror(errno) << std::endl;
        return false;
    }
    flags |= FD_CLOEXEC;
    if (fcntl(fd, F_SETFD, flags) < 0) {
        std::cerr << "[FileLogger] logging disabled: cannot apply FD_CLOEXEC '" << file << "': " << strerror(errno) << std::endl;
        return false;
    }
#endif

    inode = res.value().ino;
    return true;
}

void FileLogger::log (const string& msg, const Info& info) {
    uint64_t now = std::chrono::duration_cast<std::chrono::milliseconds>(info.time.time_since_epoch()).count();
    if (now >= last_check + check_freq) {
        last_check = now;
        auto res = Fs::stat(file);
        if (!res || res.value().type() != Fs::FileType::FILE || res.value().ino != inode) reopen();
    }

    if (!fh) return; // logging not available

    if (buffered) {
        buffered_log(msg);
    } else {
        unbuffered_log(msg);
    }
}

void FileLogger::flush() {
    if (!buffered || !fh) {
        return;
    }
    auto r = fflush(fh);
    if (r != 0) {
        std::cerr << "[FileLogger] flush message to '" << file << "': " << strerror(errno) << std::endl;
    }
}

void FileLogger::buffered_log(const string& msg) {
    auto items = fwrite(msg.data(), msg.size(), 1, fh);
    if (!items) {
        std::cerr << "[FileLogger] cannot write message to '" << file << "': " << strerror(errno) << ", message: " << msg << std::endl;
        return;
    }

#ifdef _WIN32
    items = fwrite("\r\n", 2, 1, fh);
#else
    items = fwrite("\n", 1, 1, fh);
#endif
    if (!items) {
        std::cerr << "[FileLogger] cannot write message to '" << file << "': " << strerror(errno) << std::endl;
        return;
    }
}

void FileLogger::unbuffered_log(const string& msg) {
    string full = msg + EOL;
    const char* ptr = full.data();
    const char* end = ptr + full.size();
    do {
        auto ret = write(fileno(fh),  ptr, end - ptr);
        if (ret <= 0) {
            std::cerr << "[FileLogger] cannot write message to '" << file << "': " << strerror(errno) << ", message: " << msg << std::endl;
            return;
        }
        ptr += ret;
    } while (ptr != end);
};

}}
