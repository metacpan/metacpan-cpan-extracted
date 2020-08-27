#pragma once
#include <fstream>
#include <panda/log.h>

namespace panda { namespace log {

struct FileLogger : ILogger {
    struct Config {
        string   file;
        bool     autoflush = false;
        uint32_t check_freq = 1000; // [ms]
    };

    FileLogger  (const Config&);
    ~FileLogger ();

    void log (const string&, const Info&) override;

private:
    string        file;
    bool          autoflush;
    std::ofstream fh;
    uint64_t      inode;
    uint32_t      check_freq;
    uint64_t      last_check = 0;

    bool reopen ();
};
using FileLoggerSP = iptr<FileLogger>;

}}
