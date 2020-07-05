#pragma once
#include "../log.h"

namespace panda { namespace log {

struct ConsoleLogger : ILogger {
    ConsoleLogger () {}

    void log (const string&, const Info&) override;
};

}}
