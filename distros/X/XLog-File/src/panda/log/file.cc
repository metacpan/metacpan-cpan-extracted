#include "file.h"
#include <iostream>
#include <panda/exception.h>
#include <panda/unievent/Fs.h>
#include <panda/unievent/util.h>

namespace panda { namespace log {

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

FileLogger::FileLogger (const Config& cfg) : file(cfg.file), autoflush(cfg.autoflush), check_freq(cfg.check_freq) {
    if (file.empty()) throw exception("file must be defined");
    reopen();
}

FileLogger::~FileLogger () {}

bool FileLogger::reopen () {
    if (fh.is_open()) fh.close();
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

    fh.open(file.c_str(), std::ios_base::app | std::ios_base::out);
    if (!fh.good()) {
        std::cerr << "[FileLogger] logging disabled: could not open log file '" << file << "': " << last_sys_error().message() << std::endl;
        return false;
    }

    auto res = Fs::stat(file);
    if (!res) {
        std::cerr << "[FileLogger] logging disabled: could not stat log file '" << file << "': " << res.error() << std::endl;
        return false;
    }

    inode = res.value().ino;
    return true;
}

void FileLogger::log (const string& msg, const Info& info) {
    uint64_t now = (uint64_t)info.time.tv_sec + info.time.tv_nsec / 1000000;
    if (now >= last_check + check_freq) {
        last_check = now;
        auto res = Fs::stat(file);
        if (!res || res.value().type() != Fs::FileType::FILE || res.value().ino != inode) reopen();
    }

    if (!fh || !fh.is_open()) return; // logging not available

    fh << msg << std::endl;
    if (autoflush) fh.flush();
};

}}
