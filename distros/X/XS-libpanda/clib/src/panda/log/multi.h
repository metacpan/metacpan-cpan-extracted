#pragma once
#include "log.h"
#include <vector>

namespace panda { namespace log {

struct MultiLogger : ILogger {
    struct Channel {
        Channel (ILoggerFromAny l, Level minl) : logger(std::move(l.value)), min_level(minl) {}
        Channel (ILoggerFromAny l, IFormatterFromAny f = {}, Level minl = Level::Debug)
            : logger(std::move(l.value)), formatter(std::move(f.value)), min_level(minl) {}

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
