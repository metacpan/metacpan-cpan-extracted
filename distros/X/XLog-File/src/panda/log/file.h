#pragma once
#include <panda/log.h>
#include <stdio.h>


namespace panda { namespace log {

struct FileLogger : ILogger {
    struct Config {
        string   file;
        bool     buffered = false;
        uint32_t check_freq = 1000; // [ms]
    };

    FileLogger  (const Config&);
    ~FileLogger ();

    void log (const string&, const Info&) override;
    void flush(); // flush file if buffered io used, otherwize do nothing

protected:
    void buffered_log (const string&);
    void unbuffered_log (const string&);

private:
    string   file;
    bool     buffered;
    FILE*    fh = nullptr;
    uint64_t inode;
    uint32_t check_freq;
    uint64_t last_check = 0;

    bool reopen ();
};
using FileLoggerSP = iptr<FileLogger>;

}}
