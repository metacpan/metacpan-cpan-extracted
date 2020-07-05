#pragma once
#include "log.h"
#include <vector>

namespace panda { namespace log {

struct MultiLogger : ILogger {
    struct Channel {
        Channel (const ILoggerSP& l, const IFormatterSP& f = {}, Level minl = DEBUG) : logger(l), formatter(f), min_level(minl) {}
        Channel (const ILoggerSP& l, Level minl)                                     : logger(l), min_level(minl) {}
        ILoggerSP    logger;
        IFormatterSP formatter;
        Level        min_level;
    };
    using Channels = std::vector<Channel>;

    MultiLogger  (const Channels&);
    ~MultiLogger ();

    void log_format (std::string&, const Info&, const IFormatter&) override;

private:
    const Channels channels; // could not be changed for thread-safety
};
using MultiLoggerSP = iptr<MultiLogger>;

}}
