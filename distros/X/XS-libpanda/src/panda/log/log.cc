#include "log.h"
#include <mutex>
#include <math.h>
#include <time.h>
#include <memory>
#include <thread>
#include <iomanip>
#include <sstream>
#include <string.h>
#include <algorithm>
#include "../exception.h"
#include "../unordered_string_map.h"
#include "PatternFormatter.h"

namespace panda { namespace log {

string_view default_message = "==> MARK <==";

ILogger::~ILogger () {}

namespace details {
    using Modules = unordered_string_multimap<string, Module*>;

    struct Data {
        ILoggerSP          logger;
        IFormatterSP       formatter;
        std::ostringstream os;
    };

    ILoggerSP logger;

    static std::recursive_mutex mtx;
    #define LOG_LOCK std::lock_guard<decltype(mtx)> guard(mtx);
    #define MOD_LOCK std::lock_guard<decltype(mtx)> guard(mtx);

    static IFormatterSP formatter = IFormatterSP(new PatternFormatter(default_format));
    static Modules      modules;
    static auto         mt_id = std::this_thread::get_id();
    static Data         mt_data; // data for main thread, can't use TLS because it's destroyed much earlier

    static thread_local Data  _ct_data;            // data for child threads
    static thread_local auto* ct_data = &_ct_data; // TLS via pointers works 3x faster in GCC

    static Data& get_data () { return std::this_thread::get_id() == mt_id ? mt_data : *ct_data; }

    std::ostream& get_os () { return get_data().os; }

    bool do_log (std::ostream& _stream, Level level, const Module* module, const CodePoint& cp) {
        std::ostringstream& stream = static_cast<std::ostringstream&>(_stream);
        stream.flush();
        std::string s(stream.str());
        stream.str({});

        auto& data = get_data();

        if (data.logger != logger) {
            LOG_LOCK;
            data.logger = logger;
        }
        if (data.formatter != formatter) {
            LOG_LOCK;
            data.formatter = formatter;
        }

        if (data.logger) {
            Info info(level, module, cp.file, cp.line, cp.func);
            int status = clock_gettime(CLOCK_REALTIME, &info.time);
            if (status != 0) info.time.tv_sec = info.time.tv_nsec = 0;
            data.logger->log_format(s, info, *(data.formatter));
        }
        return true;
    }
}
using namespace details;

void ILogger::log_format (std::string& s, const Info& info, const IFormatter& fmt) {
    log(fmt.format(s, info), info);
}

void ILogger::log (const string&, const Info&) {
    assert(0 && "either ILogger::log or ILogger::log_format must be implemented");
}

ILoggerSP fn2logger (const logger_format_fn& f) {
    struct Logger : ILogger {
        logger_format_fn f;
        Logger (const logger_format_fn& f) : f(f) {}
        void log_format (std::string& s, const Info& i, const IFormatter& fmt) override { f(s, i, fmt); }
    };
    return new Logger(f);
}

ILoggerSP fn2logger (const logger_fn& f) {
    struct Logger : ILogger {
        logger_fn f;
        Logger (const logger_fn& f) : f(f) {}
        void log (const string& s, const Info& i) override { f(s, i); }
    };
    return new Logger(f);
}

IFormatterSP fn2formatter (const format_fn& f) {
    struct Formatter : IFormatter {
        format_fn f;
        Formatter (const format_fn& f) : f(f) {}
        string format (std::string& s, const Info& i) const override { return f(s, i); }
    };
    return new Formatter(f);
}

void set_logger (const ILoggerSP& l) {
    LOG_LOCK;
    logger = get_data().logger = l;
}

void set_formatter (const IFormatterSP& f) {
    if (!f) return set_format(default_format);
    LOG_LOCK;
    formatter = get_data().formatter = f;
}

ILoggerSP get_logger () {
    auto& data = get_data();
    if (data.logger != logger) {
        LOG_LOCK;
        data.logger = logger;
    }
    return data.logger;
}

IFormatterSP get_formatter () {
    auto& data = get_data();
    if (data.formatter != formatter) {
        LOG_LOCK;
        data.formatter = formatter;
    }
    return data.formatter;
}

Module::Module (const string& name, Level level) : Module(name, panda_log_module, level) {}

Module::Module (const string& name, Module* parent, Level level) : parent(parent), level(level), name(name) {
    MOD_LOCK;

    if (parent) {
        parent->children.push_back(this);
        if (parent->name) this->name = parent->name + "::" + name;
    }

    if (this->name) modules.emplace(this->name, this);
}

void Module::set_level (Level level) {
    MOD_LOCK;
    this->level = level;
    for (auto& m : children) m->set_level(level);
}

Module::~Module () {
    MOD_LOCK;
    for (auto& m : children) m->parent = nullptr;
    if (parent) {
        auto it = std::find(parent->children.begin(), parent->children.end(), this);
        if (it == parent->children.end()) {
            panda_log_warn(*this, "Wrong module destruction order for " << name);
        } else {
            parent->children.erase(it);
        }
    }

    if (name) {
        auto range = modules.equal_range(name);
        while (range.first != range.second) {
            if (range.first->second != this) {
                ++range.first;
                continue;
            }
            modules.erase(range.first);
            break;
        }
    }
}

void set_level (Level val, string_view modname) {
    MOD_LOCK;
    if (!modname.length()) return ::panda_log_module.set_level(val);

    auto range = modules.equal_range(modname);
    if (range.first == range.second) throw exception(string("unknown module: ") + modname);

    while (range.first != range.second) {
        range.first->second->set_level(val);
        ++range.first;
    }
}

std::ostream& operator<< (std::ostream& stream, const escaped& str) {
   for (auto c : str.src) {
       if (c > 31) {
           stream << c;
       } else {
           stream << "\\" << std::setfill('0') << std::setw(2) << uint32_t(uint8_t(c));
       }
   }
   return stream;
}

}}

panda::log::Module panda_log_module("", nullptr);

// compose small units
#include "PatternFormatter.icc"
#include "console.icc"
#include "multi.icc"
