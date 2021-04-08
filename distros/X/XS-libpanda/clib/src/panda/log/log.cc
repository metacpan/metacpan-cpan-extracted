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
static bool destroy_flag = false;

ILogger::~ILogger () {}

namespace details {
    // panda-log is thread-safe and we use quite a tricky way to avoid mutexes on logging
    // and thus eliminating any perfomance penalties for thread-safety except only for a single access to a thread local variable

    using Modules = unordered_string_multimap<string, Module*>;

    struct ModuleData {
        ILoggerSP    effective_logger; // optimization to avoid traversing the parent-child tree
        ILoggerSP    logger;           // explicitly installed logger for this module
        IFormatterSP effective_formatter;
        IFormatterSP formatter;
    };

    struct Data {
        size_t rev = 0;
        std::ostringstream os;
        std::map<uintptr_t, ModuleData> map;
        string program_name;

        Data& operator= (const Data& oth) {
            // ostream is never changed
            rev = oth.rev;
            map = oth.map;
            program_name = oth.program_name;
            return *this;
        }

        ModuleData& get_module_data (const Module* module) {
            return map.at(reinterpret_cast<uintptr_t>(module));
        }
    };



    struct Instance {
        bool contains(const Module* module) {
            auto iter = std::find_if(modules.begin(), modules.end(), [module](const auto& m) {
                return m.second == module;
            });
            return iter != modules.end();
        }

        std::recursive_mutex mtx;

        Modules modules;                        // modules by name index
        Data src_data;                          // main container for modules data
        std::thread::id mt_id = std::this_thread::get_id();
        Data mt_data;                           // cached data for main thread, can't use TLS because it's destroyed much earlier

        ~Instance() {
            destroy_flag = true;
        }
    };

    Instance& inst() {
        static Instance d;
        return d;
    }

#define SYNC_LOCK std::lock_guard<decltype(inst().mtx)> guard(inst().mtx);

    inline Data& get_data () {
        if (std::this_thread::get_id() == inst().mt_id) {
            return inst().mt_data;
        }

        thread_local Data* ct_data = nullptr; // cached data for child threads
        if (!ct_data) { // TLS via pointers works 3x faster in GCC
            thread_local Data _ct_data;
            ct_data = &_ct_data;
        }

        return *ct_data;
    }

    inline Data& get_synced_data () {
        auto& data = get_data();

        if (data.rev != inst().src_data.rev) { // data changed by some thread
            SYNC_LOCK;
            data = inst().src_data;
        }

        return data;
    }

    std::ostream& get_os () { return get_data().os; }

    static string_view default_program_name = "<unknown>";

    bool do_log (std::ostream& _stream, Level level, const Module* module, const CodePoint& cp) {
        std::ostringstream& stream = static_cast<std::ostringstream&>(_stream);
        stream.flush();
        std::string s(stream.str());
        stream.str({});

        auto& lib_data = get_synced_data();
        auto& module_data = lib_data.get_module_data(module);

        if (module_data.effective_logger) {
            string_view program_name = lib_data.program_name ? lib_data.program_name : default_program_name;
            Info info(level, module, cp.file, cp.line, cp.func, program_name);
            int status = clock_gettime(CLOCK_REALTIME, &info.time);
            if (status != 0) info.time.tv_sec = info.time.tv_nsec = 0;
            module_data.effective_logger->log_format(s, info, *(module_data.effective_formatter));

            if (module->passthrough()) {
                while (1) {
                    module = module->parent();
                    if (!module) break;
                    auto& module_data = lib_data.get_module_data(module);
                    if (!module_data.effective_logger) break;
                    module_data.effective_logger->log_format(s, info, *(module_data.effective_formatter));
                    if (!module->passthrough()) break;
                }
            }
        }
        return true;
    }

    static std::vector<Module*>& wait_list() {
        static std::vector<Module*> inst;
        return inst;
    }

    bool try_init_waiting() {
        auto& list = wait_list();
        auto iter = std::find_if(list.begin(), list.end(), [](const auto& m) {
            return inst().contains(m->parent());
        });
        if (iter == list.end()) {
            return false;
        }

        (*iter)->init();
        wait_list().erase(iter);
        return true;
    }

    // https://stackoverflow.com/questions/9097201/how-to-get-current-process-name-in-linux
    // https://stackoverflow.com/questions/2471553/access-command-line-arguments-without-using-char-argv-in-main/24718544#24718544

    static void spy_$0(int argc, char** argv, char** /* envp */) {
        if (argc > 0) {
            if (argv[0]) {
                default_program_name = argv[0];
            }
        }
    }

    #ifdef __MACH__
    __attribute__((section("_DATA,.init_array"))) void (* p_my_cool_main)(int,char*[],char*[]) = spy_$0;
    #else
    __attribute__((section(".init_array"))) void (* p_my_cool_main)(int,char*[],char*[]) = spy_$0;
    #endif
}
using namespace details;

void ILogger::log_format (std::string& s, const Info& info, const IFormatter& fmt) {
    log(fmt.format(s, info), info);
}

void ILogger::log (const string&, const Info&) {
    assert(0 && "either ILogger::log or ILogger::log_format must be implemented");
}


ILoggerSP make_logger (const logger_fn& f) {
    struct Logger : ILogger {
        logger_fn f;
        Logger (const logger_fn& f) : f(f) {}
        void log (const string& s, const Info& i) override { f(s, i); }
    };
    return new Logger(f);
}

ILoggerSP make_logger (const logger_format_fn& f) {
    struct Logger : ILogger {
        logger_format_fn f;
        Logger (const logger_format_fn& f) : f(f) {}
        void log_format (std::string& s, const Info& i, const IFormatter& fmt) override { f(s, i, fmt); }
    };
    return new Logger(f);
}

IFormatterSP make_formatter (const format_fn& f) {
    struct Formatter : IFormatter {
        format_fn f;
        Formatter (const format_fn& f) : f(f) {}
        string format (std::string& s, const Info& i) const override { return f(s, i); }
    };
    return new Formatter(f);
}

IFormatterSP make_formatter (string_view pattern) {
    return new PatternFormatter(pattern);
}

const string& Module::name        () const { return _name; }
const Module* Module::parent      () const { return _parent; }
Level         Module::level       () const { return _level; }
bool          Module::passthrough () const { return _passthrough; }

const Module::Modules& Module::children () const {
    return _children;
}

void Module::set_level (Level level) {
    SYNC_LOCK;
    this->_level = level;
    for (auto& m : _children) m->set_level(level);
}

void Module::set_logger (ILoggerFromAny _l, bool passthrough) {
    SYNC_LOCK;
    auto l = std::move(_l.value);
    ++inst().src_data.rev;
    auto& data = inst().src_data.get_module_data(this);
    data.logger = l;
    if (!l && _parent) l = inst().src_data.get_module_data(_parent).effective_logger;
    data.effective_logger = l;
    for (auto& m : _children) m->_set_effective_logger(std::move(l));
    get_synced_data(); // reset any possible loggers for current thread
    _passthrough = passthrough;
}

void Module::_set_effective_logger (const ILoggerSP& l) {
    auto& data = inst().src_data.get_module_data(this);
    if (data.logger) return; // all children already have it as effective logger
    data.effective_logger = l;
    for (auto& m : _children) m->_set_effective_logger(l);
}

void Module::set_formatter (IFormatterFromAny _f) {
    SYNC_LOCK;
    auto f = std::move(_f.value);
    ++inst().src_data.rev;
    auto& data = inst().src_data.get_module_data(this);
    data.formatter = f;
    if (!f) {
        if (_parent) f = inst().src_data.get_module_data(_parent).effective_formatter;
        else         f = data.formatter = IFormatterSP(new PatternFormatter(default_format));
    }
    data.effective_formatter = f;
    for (auto& m : _children) m->_set_effective_formatter(std::move(f));
    get_synced_data(); // reset any possible loggers for current thread
}

void Module::_set_effective_formatter (const IFormatterSP& f) {
    auto& data = inst().src_data.get_module_data(this);
    if (data.formatter) return; // all children already have it as effective formatter
    data.effective_formatter = f;
    for (auto& m : _children) m->_set_effective_formatter(f);
}

ILoggerSP Module::get_logger () {
    return get_synced_data().get_module_data(this).logger;
}

IFormatterSP Module::get_formatter () {
    return get_synced_data().get_module_data(this).formatter;
}

Module::Module (const string& name, Level level) : Module(name, panda_log_module, level) {}
Module::Module (const string& name, Module& parent, Level level) : Module(name, &parent, level) {}
Module::Module (const string& name, std::nullptr_t, Level level) : Module(name, (Module*)nullptr, level) {}

Module::Module (const string& name, Module* parent, Level level)
    : _parent(parent)
    , _level(level)
    , _name(name)
{
    if (parent && !inst().contains(parent)) {
        wait_list().push_back(this);
    } else {
        init();
        while(try_init_waiting()) {}
    }
}

void Module::init() {
    SYNC_LOCK;
    ++inst().src_data.rev;
    auto &data = inst().src_data.map[reinterpret_cast<uintptr_t>(this)]; // creates entry

    if (inst().contains(this)) {
        return;
    }

    if (_parent) {
        _parent->init();
        _parent->_children.push_back(this);
        if (!_parent->_name.empty()) {
            this->_name = _parent->_name + "::" + _name;
        }

        // inherit effective logger and formatter from parent module
        auto& parent_data = inst().src_data.get_module_data(_parent);
        data.effective_logger    = parent_data.effective_logger;
        data.effective_formatter = parent_data.effective_formatter;
    } else {
        // set default formatter for root module
        data.effective_formatter = data.formatter = IFormatterSP(new PatternFormatter(default_format));
    }

    inst().modules.emplace(this->_name, this);
}

Module::~Module () {
    SYNC_LOCK;
    if (destroy_flag) {
        return;
    }
    for (auto& m : _children) {
        m->_parent = nullptr;
        auto& data = inst().src_data.get_module_data(m);
        // we must set explicitly logger and formatter as these modules are now root modules
        data.logger = data.effective_logger;
        data.formatter = data.effective_formatter;
    }

    if (_parent) {
        auto it = std::find(_parent->_children.begin(), _parent->_children.end(), this);
        assert(it != _parent->_children.end());
        _parent->_children.erase(it);
    }

    auto range = inst().modules.equal_range(_name);
    while (range.first != range.second) {
        if (range.first->second != this) {
            ++range.first;
            continue;
        }
        inst().modules.erase(range.first);
        break;
    }

    inst().src_data.map.erase(reinterpret_cast<uintptr_t>(this));
}

void set_level (Level val, string_view modname) {
    SYNC_LOCK;
    if (!modname.length()) return ::panda_log_module.set_level(val);

    auto range = inst().modules.equal_range(modname);
    if (range.first == range.second) throw exception(string("unknown module: ") + modname);

    while (range.first != range.second) {
        range.first->second->set_level(val);
        ++range.first;
    }
}

void set_logger (ILoggerFromAny l) {
    panda_log_module.set_logger(std::move(l));
}

void set_formatter (IFormatterFromAny f) {
    panda_log_module.set_formatter(std::move(f));
}

ILoggerSP get_logger () {
    return panda_log_module.get_logger();
}

IFormatterSP get_formatter () {
    return panda_log_module.get_formatter();
}

Module* get_module (string_view name) {
    if (!name.length()) return &::panda_log_module;
    SYNC_LOCK;
    auto range = inst().modules.equal_range(name);
    if (range.first == range.second) return nullptr;
    return range.first->second;
}

std::vector<Module*> get_modules () {
    SYNC_LOCK;
    std::vector<Module*> ret;
    ret.reserve(inst().modules.size());
    for (auto& row : inst().modules) ret.push_back(row.second);
    return ret;
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

void set_program_name(const string& value) noexcept {
    SYNC_LOCK;
    ++inst().src_data.rev;
    inst().src_data.program_name = value;
}

}}

panda::log::Module panda_log_module("", nullptr);

// compose small units
#include "PatternFormatter.icc"
#include "console.icc"
#include "multi.icc"
