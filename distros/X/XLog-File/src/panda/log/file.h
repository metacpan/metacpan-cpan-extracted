#pragma once
#include <panda/log.h>
#include <stdio.h>


namespace panda { namespace log {

struct FileLogger : ILogger {
    struct Config {
        string   file;
        bool     autoflush = true;
        uint32_t check_freq = 1000; // [ms]
    };

    FileLogger  (const Config&);
    ~FileLogger ();

    void log (const string&, const Info&) override;

private:
    string   file;
    bool     autoflush;
    FILE*    fh = nullptr;
    uint64_t inode;
    uint32_t check_freq;
    uint64_t last_check = 0;

    bool reopen ();
};
using FileLoggerSP = iptr<FileLogger>;

}}
